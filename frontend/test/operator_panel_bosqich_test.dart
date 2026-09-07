// Operator panelidagi yangi "bosqichli" tartib:
//  - tara olgandan OLDIN faqat MASHINA kartasi (raqami/turi/shofyor)
//    ko'rinadi; firma, HUJJAT va DOSTAVERNA kartalari yashirin.
//  - TAROZI kartasida 1-Mashina -> ... -> 5-Nakladnoy bosqich indikatori.
//
// flutter test muhitida HTTP so'rovlar serverga yetmaydi (ApiService
// xatoni yutib, standart/bo'sh qiymat qaytaradi) - shu sabab ekran
// tarmoqsiz ham to'liq quriladi. Davriy Timer'lar tufayli pumpAndSettle
// ISHLATIB BO'LMAYDI; oxirida boshqa widget pump qilib dispose()
// ishga tushiriladi (Timer'lar bekor qilinadi).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/screens/operator_panel_screen.dart';

void main() {
  testWidgets('Tara olgandan oldin faqat MASHINA kartasi va bosqich indikatori',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    // Keng desktop viewport - flex Row'lar sig'ishi uchun (tor test
    // viewport'ida ekranning eski Row'lari "overflow" beradi; bu
    // o'zgarishlarga aloqasiz).
    tester.view.physicalSize = const Size(1800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(
      home: OperatorPanelScreen(
        username: 'test_operator',
        mahsulotId: 1, // Chigit - HUJJAT/DOSTAVERNA kartalari bor
        mahsulotNomi: 'Chigit',
        mahsulotRang: Colors.green,
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // MASHINA kartasi va uning tara-oldi maydonlari ko'rinadi.
    expect(find.text('MASHINA'), findsOneWidget);
    expect(find.text('Davlat raqami'), findsOneWidget);
    expect(find.text('Shofyor ismi'), findsOneWidget);

    // Firma / HUJJAT / DOSTAVERNA - hali YASHIRIN (bazagaSaqlandi == false).
    expect(find.text('Firma nomi'), findsNothing);
    expect(find.text('HUJJAT'), findsNothing);
    expect(find.text('DOSTAVERNA'), findsNothing);
    expect(find.text('Namlik %'), findsNothing);
    expect(find.text('Seleksiya navi'), findsNothing);

    // Bosqich indikatori: hammasi ko'rinadi, joriy = 1-Mashina.
    expect(find.text('1-Mashina'), findsOneWidget);
    expect(find.text('2-Tara'), findsOneWidget);
    expect(find.text("3-Ma'lumot"), findsOneWidget);
    expect(find.text('4-Brutto'), findsOneWidget);
    expect(find.text('5-Nakladnoy'), findsOneWidget);

    // dispose() -> Timer'lar bekor qilinadi.
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('Chiganoq (konditsiyasiz) uchun ham HUJJAT/DOSTAVERNA yo\'q',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    // Keng desktop viewport - flex Row'lar sig'ishi uchun (tor test
    // viewport'ida ekranning eski Row'lari "overflow" beradi; bu
    // o'zgarishlarga aloqasiz).
    tester.view.physicalSize = const Size(1800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(
      home: OperatorPanelScreen(
        username: 'test_operator',
        mahsulotId: 2, // Chiganoq - konditsiyasiz
        mahsulotNomi: 'Chiganoq',
        mahsulotRang: Colors.brown,
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('MASHINA'), findsOneWidget);
    expect(find.text('HUJJAT'), findsNothing);
    expect(find.text('DOSTAVERNA'), findsNothing);
    expect(find.text('1-Mashina'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
