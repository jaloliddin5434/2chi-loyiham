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
