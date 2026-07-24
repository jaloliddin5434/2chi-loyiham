// Stage 6: offline-yozish rejasining YAKUNIY bosqichi - ko'p-stsenariyli
// chekka-holat sinovlari. Bu fayl ATAYLAB offline_queue_integration_test.dart
// bilan bir xil naqshda - REAL backendga to'g'ridan-to'g'ri ulanadi (dart:html
// yo'q, o'zining login so'rovi bor).
//
// DIQQAT: bu test tugagach, yaratilgan test mashina/hujjat yozuvlari
// bazada QOLADI - ular qo'lda (SQL orqali) tozalanishi kerak. Konsolga
// chop etilgan ID'larga qarang.

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/services/offline_queue_service.dart';
import 'package:frontend/services/offline_queue_executors.dart';

const String _baseUrl = 'http://10.112.30.77:8001';

Future<String> _login() async {
  final javob = await http.post(
    Uri.parse('$_baseUrl/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'username': 'admin', 'password': 'admin123', 'role': 'admin'}),
  );
  final govda = jsonDecode(utf8.decode(javob.bodyBytes)) as Map<String, dynamic>;
  return govda['access_token'] as String;
}

void main() {
  late String token;

  setUp(() async {
    OfflineQueueService.storageOqi = (_) => null;
    OfflineQueueService.storageYoz = (_, __) {};
    OfflineQueueService.hammasiniTozalash();
    OfflineQueueService.bajaruvchilarniTozala();
    OfflineQueueExecutors.barchasiniRoyxatgaOl();

    token = await _login();
    OfflineQueueExecutors.baseUrlOluvchi = () => _baseUrl;
    OfflineQueueExecutors.headerOluvchi = () => {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        };
  });

  // ================= STSENARIY 1 =================
  // Sinxronizatsiya O'RTASIDA yana offline bo'lib qolish: mashina_yaratish
  // REAL backendga muvaffaqiyatli yetib boradi, lekin hujjat_yaratish'dan
  // OLDIN aloqa yana uzilib qoladi. Keyingi sinxronizatsiya siklida esa
  // aloqa tiklangan bo'lib, hujjat_yaratish muvaffaqiyatli tugashi kerak -
  // va MUHIMI, mashina IKKINCHI marta yaratilmasligi kerak.
  test('1-STSENARIY: sinxronizatsiya ortasida qayta offline bolib qolish - keyingi siklda togri davom etadi', () async {
    final soxtaSaqlash = <String, String>{};
    OfflineQueueService.storageOqi = (key) => soxtaSaqlash[key];
    OfflineQueueService.storageYoz = (key, value) => soxtaSaqlash[key] = value;

    final testDavlatRaqami = 'TEST-OFFQ6-1-${DateTime.now().microsecondsSinceEpoch}';
    final mashinaKaliti = OfflineQueueService.yangiMahalliyKalit();
    final hujjatKaliti = OfflineQueueService.yangiMahalliyKalit();

    await OfflineQueueService.qoshish('mashina_yaratish', {
      'davlat_raqami': testDavlatRaqami,
      'turi': 'FAW',
      'shofyor': 'Stsenariy1 Shofyor',
      'firma': 'Test Firma',
      'viloyat': 'Xorazm',
    }, yaratadiganKalit: mashinaKaliti, vaqt: 100);

    await OfflineQueueService.qoshish('hujjat_yaratish', {
      'mashina_id': mashinaKaliti,
      'mahsulot_id': 1,
      'mijoz_kaliti': hujjatKaliti,
    }, yaratadiganKalit: hujjatKaliti, vaqt: 200);

    // Birinchi urinishda hujjat_yaratish uchun ATAYLAB tarmoq xatosini
    // simulyatsiya qiluvchi soxta bajaruvchi ro'yxatga olinadi - real
    // mashinaYaratishBajaruvchisi esa haqiqiy ishlaydi.
    var hujjatUrinish = 0;
    OfflineQueueService.turiniRoyxatgaOl('hujjat_yaratish', (malumot) async {
      hujjatUrinish++;
      if (hujjatUrinish == 1) {
        throw OfflineTarmoqXatosi("simulyatsiya: aloqa yana uzildi");
      }
      return OfflineQueueExecutors.hujjatYaratishBajaruvchisi(malumot);
    });

    final natija1 = await OfflineQueueService.sinxronlash();
    expect(natija1.tarmoqYoq, true, reason: 'birinchi siklda tarmoq xatosi kutilgan edi');
    expect(natija1.muvaffaqiyatli, 1, reason: 'faqat mashina_yaratish muvaffaqiyatli bolishi kerak');
    expect(OfflineQueueService.navbatdagilar().length, 1,
        reason: 'hujjat_yaratish hali navbatda qolishi kerak (yoqolmasligi kerak)');
    expect(OfflineQueueService.navbatdagilar().first.turi, 'hujjat_yaratish');

    final mashinaJavob1 = await http.get(
      Uri.parse('$_baseUrl/mashinalar/qidiruv/$testDavlatRaqami'),
      headers: OfflineQueueExecutors.headerOluvchi(),
    );
    final qidiruv1 = jsonDecode(utf8.decode(mashinaJavob1.bodyBytes)) as List;
    expect(qidiruv1.length, 1, reason: 'mashina REAL backendda birinchi siklda yaratilgan bolishi kerak');

    // Aloqa tiklandi - ikkinchi sikl.
    final natija2 = await OfflineQueueService.sinxronlash();
    expect(natija2.tarmoqYoq, false);
    expect(natija2.xato, 0, reason: natija2.toString());
    expect(natija2.muvaffaqiyatli, 1, reason: 'hujjat_yaratish endi muvaffaqiyatli bolishi kerak');
    expect(OfflineQueueService.navbatdagilar().length, 0);
    expect(hujjatUrinish, 2);

    // Mashina IKKINCHI marta yaratilmaganini tekshiramiz.
    final mashinaJavob2 = await http.get(
      Uri.parse('$_baseUrl/mashinalar/qidiruv/$testDavlatRaqami'),
      headers: OfflineQueueExecutors.headerOluvchi(),
    );
    final qidiruv2 = jsonDecode(utf8.decode(mashinaJavob2.bodyBytes)) as List;
    expect(qidiruv2.length, 1, reason: 'mashina IKKILAMCHI yaratilmagan bolishi kerak');

    final hujjatJavob = await http.get(
      Uri.parse('$_baseUrl/hujjatlar?mahsulot_id=1&sahifa=1&sahifa_hajmi=1'),
      headers: OfflineQueueExecutors.headerOluvchi(),
    );
    // ignore: avoid_print
    print('1-STSENARIY: mashina ID=${qidiruv2.first["id"]} davlat_raqami=$testDavlatRaqami - QOLDA TOZALANSIN (hujjat javobi: ${hujjatJavob.statusCode})');
  });

  // ================= STSENARIY 3 =================
  // Uzoq vaqt offlineda qolib, KO'P sonli amal (8 ta mashina - har biri
  // mashina+hujjat+olchov zanjiri bilan, jami 24 ta amal) to'plangandan
  // keyin BITTA sinxronlash chaqiruvi bilan hammasi to'g'ri TARTIBDA,
  // xatosiz yuborilishini tekshiramiz.
  test('3-STSENARIY: uzoq offline - 8 ta mashina (24 ta amal) togri tartibda, xatosiz sinxronlanadi', () async {
    final soxtaSaqlash = <String, String>{};
    OfflineQueueService.storageOqi = (key) => soxtaSaqlash[key];
    OfflineQueueService.storageYoz = (key, value) => soxtaSaqlash[key] = value;

    const mashinaSoni = 8;
    final davlatRaqamlari = <String>[];
    final bajarilishTartibi = <String>[];

    // Har bir amal turi uchun ORIGINAL bajaruvchini o'raymiz - shunda
    // HAQIQIY backendga yuboriladi, lekin bajarilish tartibini ham
    // kuzatib boramiz.
    OfflineQueueService.turiniRoyxatgaOl('mashina_yaratish', (m) async {
      bajarilishTartibi.add('mashina:${m['davlat_raqami']}');
      return OfflineQueueExecutors.mashinaYaratishBajaruvchisi(m);
    });
    OfflineQueueService.turiniRoyxatgaOl('hujjat_yaratish', (m) async {
      bajarilishTartibi.add('hujjat:${m['mijoz_kaliti']}');
      return OfflineQueueExecutors.hujjatYaratishBajaruvchisi(m);
    });
    OfflineQueueService.turiniRoyxatgaOl('olchov_saqlash', (m) async {
      bajarilishTartibi.add('olchov:${m['hujjat_id']}');
      return OfflineQueueExecutors.olchovSaqlashBajaruvchisi(m);
    });

    var vaqt = 1000;
    for (var i = 0; i < mashinaSoni; i++) {
      final raqam = 'TEST-OFFQ6-3-$i-${DateTime.now().microsecondsSinceEpoch}';
      davlatRaqamlari.add(raqam);
      final mashinaKaliti = OfflineQueueService.yangiMahalliyKalit();
      final hujjatKaliti = OfflineQueueService.yangiMahalliyKalit();

      await OfflineQueueService.qoshish('mashina_yaratish', {
        'davlat_raqami': raqam,
        'turi': 'FAW',
        'shofyor': 'Stsenariy3 Shofyor $i',
        'firma': 'Test Firma',
        'viloyat': 'Xorazm',
      }, yaratadiganKalit: mashinaKaliti, vaqt: vaqt++);

      await OfflineQueueService.qoshish('hujjat_yaratish', {
        'mashina_id': mashinaKaliti,
        'mahsulot_id': 1,
        'mijoz_kaliti': hujjatKaliti,
      }, yaratadiganKalit: hujjatKaliti, vaqt: vaqt++);

      await OfflineQueueService.qoshish('olchov_saqlash', {
        'hujjat_id': hujjatKaliti,
        'arava_raqam': 1,
        'tara': 18000.0 + i,
        'brutto': null,
        'namlik': null,
        'ifloslik': null,
      }, vaqt: vaqt++);
    }

    expect(OfflineQueueService.navbatdagilar().length, mashinaSoni * 3);

    final natija = await OfflineQueueService.sinxronlash();
    expect(natija.tarmoqYoq, false);
    expect(natija.xato, 0, reason: natija.toString());
    expect(natija.muvaffaqiyatli, mashinaSoni * 3);
    expect(OfflineQueueService.navbatdagilar().length, 0);
    expect(OfflineQueueService.xatoliklar().length, 0);

    // Bajarilish tartibi: har bir mashina uchun mashina -> hujjat -> olchov
    // ketma-ketligi buzilmagan bolishi kerak (garchi turli mashinalar
    // o'zaro aralashib ketishi mumkin bo'lmasa ham - chunki vaqt tamg'alari
    // ketma-ket berilgan).
    expect(bajarilishTartibi.length, mashinaSoni * 3);
    for (var i = 0; i < mashinaSoni; i++) {
      final mIdx = bajarilishTartibi.indexWhere((s) => s.startsWith('mashina:${davlatRaqamlari[i]}'));
      expect(mIdx, i * 3, reason: '$i-mashina notogri tartibda bajarildi');
    }

    // Barcha 8 ta mashina REAL backendda mavjudligini tekshiramiz.
    final yaratilganIdlar = <int>[];
    for (final raqam in davlatRaqamlari) {
      final javob = await http.get(
        Uri.parse('$_baseUrl/mashinalar/qidiruv/$raqam'),
        headers: OfflineQueueExecutors.headerOluvchi(),
      );
      final qidiruv = jsonDecode(utf8.decode(javob.bodyBytes)) as List;
      expect(qidiruv.length, 1, reason: '$raqam backendda topilmadi');
      yaratilganIdlar.add(qidiruv.first['id'] as int);
    }

    // ignore: avoid_print
    print('3-STSENARIY: yaratilgan mashina ID lari=$yaratilganIdlar - QOLDA TOZALANSIN');
  });

  // ============= QOSHIMCHA: 401 QAYTA URINILADIGAN XATO =============
  // Stage 6 sinovlari paytida topilgan chekka holat: agar avtorizatsiya
  // tokeni muddati tugagan bo'lsa (masalan uzoq vaqt offlineda qolib,
  // token 8 soatlik muddatidan o'tib ketsa), sinxronizatsiya urinishi
  // 401 status bilan qaytadi. Bu DOIMIY server rad etishi (xato) EMAS -
  // operator qayta login qilgach xuddi shu amal muvaffaqiyatli
  // bo'lishi kerak. Shu sabab 401 OfflineTarmoqXatosi (qayta
  // uriniladigan) sifatida ishlanishi kerak, OfflineServerXatosi
  // (doimiy, "xato" deb belgilanadigan) emas.
  test('QOSHIMCHA: 401 (token muddati tugashi) DOIMIY xato emas, qayta uriniladigan holat deb belgilanadi', () async {
    OfflineQueueExecutors.headerOluvchi = () => {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer NOTOGRI-YOKI-ESKIRGAN-TOKEN',
        };
    expect(
      () => OfflineQueueExecutors.mashinaYaratishBajaruvchisi({
        'davlat_raqami': 'TEST-401-${DateTime.now().microsecondsSinceEpoch}',
        'turi': 'FAW',
        'shofyor': 'x',
        'firma': 'x',
        'viloyat': 'Xorazm',
      }),
      throwsA(isA<OfflineTarmoqXatosi>()),
      reason: '401 OfflineServerXatosi emas, OfflineTarmoqXatosi (qayta uriniladigan) bolishi kerak',
    );
  });
}
