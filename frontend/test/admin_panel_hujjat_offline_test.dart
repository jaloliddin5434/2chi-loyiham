// Bug: admin panelida hujjat TAHRIRLASH (hujjatTuzat) va O'CHIRISH
// (hujjatOchir) tarmoq uzilganda tahrirni JIMGINA yo'qotardi - xom
// http.put() chaqirilib, muvaffaqiyatsiz bo'lsa faqat "xatolik yuz
// berdi!" SnackBar ko'rsatilardi, hech qanday offline navbatga
// qo'yish (operator panelidagi ApiService.hujjatYangilash() bilan bir
// xil yondashuv) yo'q edi.
//
// Tuzatish: endi tarmoq xatosida (http.put() istisno otsa) o'zgarish
// OfflineQueueService.qoshish('hujjat_yangilash', ...) orqali navbatga
// qo'yiladi - xuddi operator panelidagi ApiService.hujjatYangilash()
// bilan bir xil operatsiya turi/format ishlatiladi, shu sabab bir xil
// executor (hujjatYangilashBajaruvchisi) va sinxronizatsiya keyinroq
// buni avtomatik yuboradi.
//
// Tarmoq (HTTP) chaqiruvlari http.runWithClient() orqali MockClient
// bilan almashtiriladi - haqiqiy (production) backendga hech qanday
// so'rov ketmaydi. Saqlash zaxirasi (storageOqi/storageYoz) oddiy Map
// bilan simulyatsiya qilinadi (xuddi offline_queue_service_test.dart
// dagi kabi) - shu bilan qoshish() orqali yozilgan yozuv
// navbatdagilar() orqali HAQIQATAN qayta o'qib bo'ladi.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:frontend/screens/admin_panel_screen.dart';
import 'package:frontend/services/offline_queue_service.dart';

Map<String, dynamic> _sinovHujjati({int id = 777}) => {
      'id': id,
      'raqam': 'CHG-$id',
      'holat': 'jarayon',
      'mashina_raqami': '01A777AA',
      'shofyor': 'Test Shofyor',
      'firma': 'Test Firma',
      'tiket_raqam': 'TIK-1',
      'tuda_raqam': '',
      'klass': '',
      'sinf': '',
      'seleksiya_navi': '',
      'terim_turi': '',
      'qabul_qildi': '',
      'yuk_olindi': '',
      'namlik': null,
      'ifloslik': null,
    };

Future<dynamic> _ekranniQur(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1800, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(const MaterialApp(
    home: AdminPanelScreen(username: 'test_admin', rol: 'admin'),
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));

  return tester.state(find.byType(AdminPanelScreen));
}

void main() {
  late Map<String, String> soxtaSaqlash;

  setUp(() {
    soxtaSaqlash = {};
    OfflineQueueService.storageOqi = (key) => soxtaSaqlash[key];
    OfflineQueueService.storageYoz = (key, value) async => soxtaSaqlash[key] = value;
    OfflineQueueService.hammasiniTozalash();
    OfflineQueueService.bajaruvchilarniTozala();
  });

  testWidgets(
      "hujjatTuzat(): tarmoq xatosida o'zgarish offline navbatga qo'yiladi, yo'qolmaydi",
      (WidgetTester tester) async {
    final state = await _ekranniQur(tester);

    await http.runWithClient(() async {
      final future = state.hujjatTuzat(_sinovHujjati(id: 777)) as Future;
      await tester.pump();

      final dialog = find.byType(AlertDialog);
      expect(dialog, findsOneWidget);
      await tester.tap(find.descendant(
          of: dialog, matching: find.widgetWithText(ElevatedButton, 'Saqlash')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await future;
    }, () => MockClient((req) async => throw Exception('tarmoq xatosi (sinov)')));

    final navbatdagilar = OfflineQueueService.navbatdagilar();
    expect(navbatdagilar.length, 1,
        reason: "o'zgarish offline navbatga qo'yilishi kerak edi");
    expect(navbatdagilar.first.turi, 'hujjat_yangilash');
    expect(navbatdagilar.first.malumot['hujjat_id'], 777);
    expect(
        (navbatdagilar.first.malumot['maydonlar']
            as Map)['mashina_raqami'],
        '01A777AA');

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets(
      "hujjatOchir(): tarmoq xatosida o'chirish offline navbatga qo'yiladi, yo'qolmaydi",
      (WidgetTester tester) async {
    final state = await _ekranniQur(tester);

    await http.runWithClient(() async {
      final future = state.hujjatOchir(555) as Future;
      await tester.pump();

      final dialog = find.byType(AlertDialog);
      expect(dialog, findsOneWidget);
      await tester.enterText(
          find.descendant(of: dialog, matching: find.byType(TextField)),
          "Noto'g'ri kiritilgan");
      await tester.pump();
      await tester.tap(find.descendant(
          of: dialog, matching: find.widgetWithText(ElevatedButton, "O'chirish")));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await future;
    }, () => MockClient((req) async => throw Exception('tarmoq xatosi (sinov)')));

    final navbatdagilar = OfflineQueueService.navbatdagilar();
    expect(navbatdagilar.length, 1,
        reason: "o'chirish (bekor qilish) offline navbatga qo'yilishi kerak edi");
    expect(navbatdagilar.first.turi, 'hujjat_yangilash');
    expect(navbatdagilar.first.malumot['hujjat_id'], 555);
    expect(
        (navbatdagilar.first.malumot['maydonlar'] as Map)['holat'], 'bekor');
    expect(
        (navbatdagilar.first.malumot['maydonlar'] as Map)['bekor_sabab'],
        "Noto'g'ri kiritilgan");

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
