// Bug: 2 (yoki 3) pritsepli mashina navbatdan BRUTTO uchun tanlanganda,
// operator ekrani nechta arava borligini (aravalarSoni) bilmasdi -
// navbatdanTanlash() bu qiymatni hech qachon tiklamasdi, standart 1
// qiymatida qolib ketardi. Natijada _keyingiBruttoSizArava() 1..1
// oralig'ida qidirib, 1-arava bruttosi saqlangandan KEYIN darhol "barcha
// aravalar tugadi" deb hisoblab, hujjatni tugallar va nakladnoy chiqarardi
// - 2-pritsep bruttosi hech qachon o'lchanmay qolardi.
//
// Bu test: 2 aravali mashina uchun 1-arava bruttosi saqlangach hali
// TUGALLANMASLIGINI (operator "2-aravani qo'ying" deb ogohlantirilishini),
// faqat 2-arava ham saqlangandan KEYIN tugallanishini tekshiradi.
//
// Tarmoq (HTTP) chaqiruvlari http.runWithClient() orqali MockClient bilan
// almashtiriladi - haqiqiy (production) backendga hech qanday so'rov
// ketmaydi.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/screens/operator_panel_screen.dart';
import 'package:frontend/services/navbat_service.dart';

NavbatMashina _ikkiAravaliMashina() => NavbatMashina(
      raqam: '01A777KAM',
      turi: 'Kamaz',
      shofyor: 'Shofyor',
      firma: 'Test Firma',
      vaqt: '09:00',
      mahsulotId: 1,
      mahsulotNomi: 'Chigit',
      aravalar: {
        1: AravaData()..tara = 5000,
        2: AravaData()..tara = 4800,
        3: AravaData(),
      },
      hujjatId: 555,
      mashinaId: 9,
      hujjatRaqam: 'CHG-555',
      aravalarSoni: 2,
      kelganVaqt: DateTime(2026, 9, 17, 9, 0),
      tiketRaqam: 'TIK-555',
    );

/// Dialog tasdiqlanguncha kutib, "Saqlash" ni bosib, saqlash() Future'i
/// tugaguncha kutadi - haqiqiy operator bosishini simulyatsiya qiladi.
Future<void> _bruttoniTasdiqlabSaqla(WidgetTester tester, dynamic state) async {
  final future = state.saqlash();
  await tester.pump();
  await tester.tap(find.text('Saqlash'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await future;
}

void main() {
  testWidgets(
      "2 aravali mashina: 1-arava bruttosi saqlangach hali tugallanmaydi, "
      "faqat 2-arava ham saqlangach tugallanadi",
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    // 1800x1400 - boshqa operator panel testlarida ishlatilgan o'lcham
    // (operator_panel_bosqich_test.dart).
    tester.view.physicalSize = const Size(1800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // TOPBAR'dagi "Hujjat: ..." / faqatBrutto chiplari (mashina navbatdan
    // tanlanganda ko'rinadi) o'zgarishlarga aloqasiz, mavjud 5px RenderFlex
    // overflow'ga sabab bo'ladi (operator_panel_bosqich_test.dart bunga hech
    // qachon duch kelmaydi, chunki u yerda mashina hech qachon tanlanmaydi).
    // Shu bitta, ma'lum overflow xabari filtrlanadi - boshqa har qanday
    // xato odatdagidek testni yiqitadi.
    final asliyOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exception.toString().contains('RenderFlex overflowed')) {
        return;
      }
      asliyOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = asliyOnError);

    NavbatService.tozala();
    addTearDown(NavbatService.tozala);

    await tester.pumpWidget(const MaterialApp(
      home: OperatorPanelScreen(
        username: 'test_operator',
        mahsulotId: 1,
        mahsulotNomi: 'Chigit',
        mahsulotRang: Colors.green,
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final state = tester.state(find.byType(OperatorPanelScreen)) as dynamic;

    state.navbatdanTanlash(_ikkiAravaliMashina());
    await tester.pump();

    // Asosiy tuzatish: navbatdan tanlangan mashinaning aravalarSoni
    // ekranga to'g'ri o'tishi kerak (avval doim 1 bo'lib qolardi).
    expect(state.aravalarSoni, 2);

    await http.runWithClient(() async {
      // 1-arava BRUTTO o'lchanadi va saqlanadi.
      state.taroziKg = 9000.0;
      expect(state.tanlanganArava, 1);
      await _bruttoniTasdiqlabSaqla(tester, state);

      expect(state.bruttoSaqlangan1, isTrue);
      expect(state.bruttoSaqlangan2, isFalse);
      // HALI tugallanmagan - navbatdagi mashina hamon tanlangan holatda
      // turishi kerak (2-arava kutilyapti).
      expect(state.tanlanganNavbat, isNotNull,
          reason:
              '1/2 arava o\'lchangandan keyin hujjat vaqtidan oldin tugallanib ketdi!');
      expect(state.xabarMatni, contains('2-aravani'));
      expect(state.xabarMatni, isNot(contains('Tugallandi')));

      // Har bir saqlashdan keyin 10 soniyalik "qayta bosishdan himoya"
      // qulfi (saqlanmoqda=true) ishga tushadi - shu muddat o'tmaguncha
      // saqlash() darhol qaytadi (dialog ochilmaydi). testWidgets fake
      // async zonasida dart:async Timer ham soxtalashtirilgani uchun bu
      // pump haqiqiy 11 soniya kutmasdan Timer'ni haydab o'tkazadi.
      await tester.pump(const Duration(seconds: 11));

      // 2-arava BRUTTO o'lchanadi va saqlanadi.
      state.tanlanganArava = 2;
      state.taroziKg = 8700.0;
      await _bruttoniTasdiqlabSaqla(tester, state);

      expect(state.bruttoSaqlangan2, isTrue);
      // Endi ikkalasi ham o'lchandi - hujjat tugallanishi kerak.
      expect(state.tanlanganNavbat, isNull);
      expect(state.xabarMatni, contains('Tugallandi'));
    }, () => MockClient((req) async => http.Response('{}', 200)));

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
