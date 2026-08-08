// MUHIM: bu fayl Stage-0'dagi sof unit testlardan FARQLI - REAL backend
// ishlab turishini talab qiladi va bazaga HAQIQIY yozuv (mashina, hujjat)
// qo'shadi. ATAYLAB `package:frontend/services/api_service.dart`ni import
// QILMAYDI (u `dart:html`ga bog'liq `offline_service.dart`ni tortib
// keladi, bu Dart VM'da - ya'ni oddiy `flutter test`da - ishlamaydi).
// O'rniga to'g'ridan-to'g'ri, o'zining login so'rovini yuboradi.
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

  test('mashina + hujjat zanjiri REAL backendga mahalliy kalit orqali togri sinxronlanadi', () async {
    final soxtaSaqlash = <String, String>{};
    OfflineQueueService.storageOqi = (key) => soxtaSaqlash[key];
    OfflineQueueService.storageYoz = (key, value) => soxtaSaqlash[key] = value;

    final testDavlatRaqami =
        'TEST-OFFQ3B-${DateTime.now().microsecondsSinceEpoch}';
    final mashinaKaliti = OfflineQueueService.yangiMahalliyKalit();
    final hujjatKaliti = OfflineQueueService.yangiMahalliyKalit();

    await OfflineQueueService.qoshish(
      'mashina_yaratish',
      {
        'davlat_raqami': testDavlatRaqami,
        'turi': 'FAW',
        'shofyor': 'Integration Test',
        'firma': 'Test Firma',
        'viloyat': 'Xorazm',
      },
      yaratadiganKalit: mashinaKaliti,
      vaqt: 100,
    );

    await OfflineQueueService.qoshish(
      'hujjat_yaratish',
      {
        'mashina_id': mashinaKaliti,
        'mahsulot_id': 1,
        'mijoz_kaliti': hujjatKaliti,
      },
      yaratadiganKalit: hujjatKaliti,
      vaqt: 200,
    );

    final natija = await OfflineQueueService.sinxronlash();

    if (natija.xato > 0) {
      for (final x in OfflineQueueService.xatoliklar()) {
        // ignore: avoid_print
        print('XATO TAFSILOT: turi=${x.turi} malumot=${x.malumot} oxirgiXato=${x.oxirgiXato}');
      }
    }

    expect(natija.tarmoqYoq, false);
    expect(natija.xato, 0, reason: natija.toString());
    expect(natija.muvaffaqiyatli, 2);
    expect(OfflineQueueService.navbatdagilar().length, 0);
    expect(OfflineQueueService.xatoliklar().length, 0);

    final javob = await http.get(
      Uri.parse('$_baseUrl/mashinalar/qidiruv/$testDavlatRaqami'),
      headers: OfflineQueueExecutors.headerOluvchi(),
    );
    final qidiruv = jsonDecode(utf8.decode(javob.bodyBytes)) as List;
    expect(qidiruv.length, 1);
    // ignore: avoid_print
    print(
        'YARATILGAN TEST MASHINA ID: ${qidiruv.first['id']} (davlat_raqami=$testDavlatRaqami) - QOLDA TOZALANSIN');
  });

  test('hujjat yaratish real backendda idempotent - qayta urinish ikkilamchi hujjat yaratmaydi', () async {
    final hujjatKaliti = OfflineQueueService.yangiMahalliyKalit();
    final malumot = {
      'mashina_id': 1,
      'mahsulot_id': 1,
      'mijoz_kaliti': hujjatKaliti,
    };

    final natija1 = await OfflineQueueExecutors.hujjatYaratishBajaruvchisi(malumot);
    final natija2 = await OfflineQueueExecutors.hujjatYaratishBajaruvchisi(malumot);
    final natija3 = await OfflineQueueExecutors.hujjatYaratishBajaruvchisi(malumot);

    expect(natija1['id'], natija2['id']);
    expect(natija1['id'], natija3['id']);
    expect(natija1['raqam'], natija2['raqam']);
    // ignore: avoid_print
    print(
        'IDEMPOTENT TEST HUJJAT ID: ${natija1['id']} (raqam=${natija1['raqam']}) - QOLDA TOZALANSIN');
  });

  test('olchov (tara/brutto) navbatga qoyilib, REAL backendga togri sinxronlanadi', () async {
    // Avval haqiqiy test hujjat yaratamiz (4a - "tortish davomida
    // tarmoq uzilishi" stsenariysi - hujjat ALLAQACHON haqiqiy ID'ga
    // ega, faqat Olchov saqlash paytida aloqa yoqoladi).
    final hujjatMalumot = await OfflineQueueExecutors.hujjatYaratishBajaruvchisi({
      'mashina_id': 1,
      'mahsulot_id': 1,
      'mijoz_kaliti': OfflineQueueService.yangiMahalliyKalit(),
    });
    final hujjatId = hujjatMalumot['id'] as int;

    final soxtaSaqlash = <String, String>{};
    OfflineQueueService.storageOqi = (key) => soxtaSaqlash[key];
    OfflineQueueService.storageYoz = (key, value) => soxtaSaqlash[key] = value;

    await OfflineQueueService.qoshish('olchov_saqlash', {
      'hujjat_id': hujjatId,
      'arava_raqam': 1,
      'tara': 18400.0,
      'brutto': null,
      'namlik': 7.5,
      'ifloslik': 0.2,
    });

    final natija = await OfflineQueueService.sinxronlash();
    expect(natija.xato, 0, reason: natija.toString());
    expect(natija.muvaffaqiyatli, 1);
    expect(OfflineQueueService.navbatdagilar().length, 0);

    final javob = await http.get(
      Uri.parse('$_baseUrl/olchovlar/$hujjatId'),
      headers: OfflineQueueExecutors.headerOluvchi(),
    );
    final olchovlar = jsonDecode(utf8.decode(javob.bodyBytes)) as List;
    expect(olchovlar.length, 1);
    expect((olchovlar.first['tara'] as num).toDouble(), 18400.0);
    // ignore: avoid_print
    print('OLCHOV TEST HUJJAT ID: $hujjatId - QOLDA TOZALANSIN');
  });

  test('navbat_qosh va navbat_tugallandi navbatga qoyilib, REAL backendga togri sinxronlanadi', () async {
    final hujjatMalumot = await OfflineQueueExecutors.hujjatYaratishBajaruvchisi({
      'mashina_id': 1,
      'mahsulot_id': 1,
      'mijoz_kaliti': OfflineQueueService.yangiMahalliyKalit(),
    });
    final hujjatId = hujjatMalumot['id'] as int;

    final soxtaSaqlash = <String, String>{};
    OfflineQueueService.storageOqi = (key) => soxtaSaqlash[key];
    OfflineQueueService.storageYoz = (key, value) => soxtaSaqlash[key] = value;

    await OfflineQueueService.qoshish('navbat_qosh', {
      'hujjatId': hujjatId,
      'mashinaId': 1,
      'raqam': 'TEST-4B',
      'turi': 'FAW',
      'shofyor': 'Integration Test',
      'firma': 'Test Firma',
      'vaqt': DateTime.now().toIso8601String(),
      'mahsulotId': 1,
      'mahsulotNomi': 'Chigit',
      'kelganVaqt': DateTime.now().toIso8601String(),
      'tudaRaqam': '',
      'tiketRaqam': '',
      'seleksiyaNavi': '',
      'klass': '',
      'sinf': '',
      'terimTuri': '',
      'namlik': null,
      'ifloslik': null,
      'tugallandi': false,
      'aravalar': {},
    }, vaqt: 100);

    await OfflineQueueService.qoshish('navbat_tugallandi', {
      'hujjatId': hujjatId,
      'aravalar': {
        '1': {'tara': 18400.0, 'brutto': 25000.0, 'netto': 6600.0, 'konditsion': 92.0},
      },
    }, vaqt: 200);

    final natija = await OfflineQueueService.sinxronlash();
    expect(natija.xato, 0, reason: natija.toString());
    expect(natija.muvaffaqiyatli, 2);
    expect(OfflineQueueService.navbatdagilar().length, 0);

    final javob = await http.get(
      Uri.parse('$_baseUrl/navbat/tugallanganlar'),
      headers: OfflineQueueExecutors.headerOluvchi(),
    );
    final tugallanganlar = jsonDecode(utf8.decode(javob.bodyBytes)) as List;
    final topilgan = tugallanganlar.firstWhere(
      (t) => t['hujjatId'] == hujjatId,
      orElse: () => null,
    );
    expect(topilgan, isNotNull,
        reason: 'hujjatId=$hujjatId tugallanganlar royxatida topilmadi');
    // ignore: avoid_print
    print('NAVBAT TEST HUJJAT ID: $hujjatId - QOLDA TOZALANSIN');
  });

  test('tolik offlinedan boshlab (mashina kelishidan tortish yakunigacha) real backendga togri sinxronlanadi', () async {
    // Stage 4c: operator hech qanday tarmoq aloqasisiz mashina kiritadi,
    // tara/brutto o'lchaydi va tortishni yakunlaydi - hech narsa serverga
    // yetib bormaydi, faqat OFFLINE- mahalliy kalitlar orqali navbatga
    // qo'yiladi. Sinxronlash bir marta chaqirilganda hammasi ketma-ket,
    // to'g'ri tartibda haqiqiy backendga yetib borishi kerak.
    final soxtaSaqlash = <String, String>{};
    OfflineQueueService.storageOqi = (key) => soxtaSaqlash[key];
    OfflineQueueService.storageYoz = (key, value) => soxtaSaqlash[key] = value;

    final testDavlatRaqami = 'TEST-OFFQ4C-${DateTime.now().microsecondsSinceEpoch}';
    final mashinaKaliti = OfflineQueueService.yangiMahalliyKalit();
    final hujjatKaliti = OfflineQueueService.yangiMahalliyKalit();

    await OfflineQueueService.qoshish(
      'mashina_yaratish',
      {
        'davlat_raqami': testDavlatRaqami,
        'turi': 'FAW',
        'shofyor': '4c Test Shofyor',
        'firma': 'Test Firma',
        'viloyat': 'Xorazm',
      },
      yaratadiganKalit: mashinaKaliti,
      vaqt: 100,
    );

    await OfflineQueueService.qoshish(
      'hujjat_yaratish',
      {
        'mashina_id': mashinaKaliti,
        'mahsulot_id': 1,
        'mijoz_kaliti': hujjatKaliti,
      },
      yaratadiganKalit: hujjatKaliti,
      vaqt: 200,
    );

    await OfflineQueueService.qoshish('olchov_saqlash', {
      'hujjat_id': hujjatKaliti,
      'arava_raqam': 1,
      'tara': 18400.0,
      'brutto': null,
      'namlik': null,
      'ifloslik': null,
    }, vaqt: 300);

    await OfflineQueueService.qoshish('olchov_saqlash', {
      'hujjat_id': hujjatKaliti,
      'arava_raqam': 1,
      'tara': 18400.0,
      'brutto': 25600.0,
      'namlik': 7.5,
      'ifloslik': 0.2,
    }, vaqt: 400);

    // Haqiqiy ekranda tara saqlanganda (brutto hali yoq) mashina Navbat
    // navbatiga qoyiladi (navbat_qosh) - navbat_tugallandi FAQAT
    // ALLAQACHON mavjud Navbat qatorini yangilaydi, yangisini yaratmaydi.
    await OfflineQueueService.qoshish('navbat_qosh', {
      'hujjatId': hujjatKaliti,
      'mashinaId': mashinaKaliti,
      'raqam': testDavlatRaqami,
      'turi': 'FAW',
      'shofyor': '4c Test Shofyor',
      'firma': 'Test Firma',
      'vaqt': '10:00',
      'mahsulotId': 1,
      'mahsulotNomi': 'Chigit',
      'kelganVaqt': DateTime.now().toIso8601String(),
      'tudaRaqam': '',
      'tiketRaqam': '',
      'seleksiyaNavi': '',
      'klass': '',
      'sinf': '',
      'terimTuri': '',
      'namlik': null,
      'ifloslik': null,
      'tugallandi': false,
      'aravalar': {
        '1': {'tara': 18400.0, 'brutto': null, 'netto': null, 'konditsion': null},
      },
    }, vaqt: 450);

    await OfflineQueueService.qoshish('navbat_tugallandi', {
      'hujjatId': hujjatKaliti,
      'aravalar': {
        '1': {'tara': 18400.0, 'brutto': 25600.0, 'netto': 7200.0, 'konditsion': 92.0},
      },
    }, vaqt: 500);

    await OfflineQueueService.qoshish('hujjat_yangilash', {
      'hujjat_id': hujjatKaliti,
      'maydonlar': {
        'qabul_qildi': '4c Test Qabul',
        'yuk_olindi': '4c Test Yuk',
        'sabab': 'Integration test',
      },
    }, vaqt: 600);

    final natija = await OfflineQueueService.sinxronlash();
    if (natija.xato > 0) {
      for (final x in OfflineQueueService.xatoliklar()) {
        // ignore: avoid_print
        print('4C XATO TAFSILOT: turi=${x.turi} malumot=${x.malumot} oxirgiXato=${x.oxirgiXato}');
      }
    }
    expect(natija.tarmoqYoq, false);
    expect(natija.xato, 0, reason: natija.toString());
    expect(natija.muvaffaqiyatli, 7);
    expect(OfflineQueueService.navbatdagilar().length, 0);
    expect(OfflineQueueService.xatoliklar().length, 0);

    final mashinaJavob = await http.get(
      Uri.parse('$_baseUrl/mashinalar/qidiruv/$testDavlatRaqami'),
      headers: OfflineQueueExecutors.headerOluvchi(),
    );
    final qidiruv = jsonDecode(utf8.decode(mashinaJavob.bodyBytes)) as List;
    expect(qidiruv.length, 1);
    final mashinaId = qidiruv.first['id'] as int;

    final tugallanganlarJavob = await http.get(
      Uri.parse('$_baseUrl/navbat/tugallanganlar'),
      headers: OfflineQueueExecutors.headerOluvchi(),
    );
    final tugallanganlar = jsonDecode(utf8.decode(tugallanganlarJavob.bodyBytes)) as List;
    final topilganNavbat = tugallanganlar.firstWhere(
      (t) => t['mashinaId'] == mashinaId,
      orElse: () => null,
    );
    expect(topilganNavbat, isNotNull,
        reason: 'mashinaId=$mashinaId tugallanganlar royxatida topilmadi');
    final hujjatId = topilganNavbat['hujjatId'] as int;
    expect(topilganNavbat['aravalar']['1']['tara'], 18400.0);
    expect(topilganNavbat['aravalar']['1']['brutto'], 25600.0);

    final olchovJavob = await http.get(
      Uri.parse('$_baseUrl/olchovlar/$hujjatId'),
      headers: OfflineQueueExecutors.headerOluvchi(),
    );
    final olchovlar = jsonDecode(utf8.decode(olchovJavob.bodyBytes)) as List;
    expect(olchovlar.length, 2,
        reason: 'ikkita olchov_saqlash amali (birinchi faqat tara, keyin tara+brutto) ikkita qator yaratishi kerak');
    expect((olchovlar.last['brutto'] as num).toDouble(), 25600.0);

    final hujjatJavob = await http.get(
      Uri.parse('$_baseUrl/hujjatlar/$hujjatId'),
      headers: OfflineQueueExecutors.headerOluvchi(),
    );
    final hujjatDetal = jsonDecode(utf8.decode(hujjatJavob.bodyBytes)) as Map<String, dynamic>;
    expect(hujjatDetal['qabul_qildi'], '4c Test Qabul',
        reason: 'hujjat_yangilash (dostaverka/qabul_qildi/yuk_olindi) offline navbatdan togri sinxronlanmadi');
    expect(hujjatDetal['yuk_olindi'], '4c Test Yuk');

    // ignore: avoid_print
    print('4C: yaratilgan mashina ID=$mashinaId hujjat ID=$hujjatId davlat_raqami=$testDavlatRaqami - QOLDA TOZALANSIN');
  });

  test('server rad etsa (notogri mahsulot_id), OfflineServerXatosi otiladi', () async {
    final malumot = {
      'mashina_id': 1,
      'mahsulot_id': 999999, // mavjud bolmagan mahsulot
      'mijoz_kaliti': OfflineQueueService.yangiMahalliyKalit(),
    };

    expect(
      () => OfflineQueueExecutors.hujjatYaratishBajaruvchisi(malumot),
      throwsA(isA<OfflineServerXatosi>()),
    );
  });
}
