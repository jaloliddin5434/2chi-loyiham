// Admin panelining Hujjatlar va Statistika bo'limlariga qo'shilgan qisqa
// tushuntirish izohlarini tekshiradi:
//  - Hujjatlar: "Barcha hujjatlar ko'rsatiladi (jarayonda + bekor + tugallangan)"
//    (operator/admin hujjatlar ro'yxatida FAQAT tugallangan emas, barcha
//    holatdagi hujjatlar ko'rinishini eslatib turadi).
//  - Statistika: "Faqat tugallangan yuklar hisoblanadi (netto > 0)"
//    (statistika/moliyaviy hisobotlar faqat tugallangan, musbat nettoli
//    yuklarni hisobga olishini eslatib turadi).
//
// flutter test muhitida HTTP so'rovlar haqiqiy serverga yetmaydi -
// ApiService xatoni yutib, standart/bo'sh qiymat qaytaradi (xuddi
// operator_panel_bosqich_test.dart'dagi kabi) - shu sabab ekran
// tarmoqsiz ham to'liq quriladi. Davriy Timer'lar tufayli
// pumpAndSettle ISHLATIB BO'LMAYDI; oxirida boshqa widget pump qilib
// dispose() ishga tushiriladi (Timer'lar bekor qilinadi).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/screens/admin_panel_screen.dart';

const _hujjatlarIzohi =
    "Barcha hujjatlar ko'rsatiladi (jarayonda + bekor + tugallangan)";
const _statistikaIzohi = "Faqat tugallangan yuklar hisoblanadi (netto > 0)";

void main() {
  testWidgets(
      "Hujjatlar bo'limida 'barcha holatlar ko'rinadi' izohi chiqadi",
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(
      home: AdminPanelScreen(username: 'test_admin', rol: 'admin'),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Statistika izohi hali ko'rinmaydi (boshlang'ich sahifa - Dashboard).
    expect(find.text(_statistikaIzohi), findsNothing);

    await tester.tap(find.byTooltip('Hujjatlar'));
    await tester.pump();

    expect(find.text(_hujjatlarIzohi), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets(
      "Statistika bo'limida 'faqat tugallangan/netto>0' izohi chiqadi",
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(
      home: AdminPanelScreen(username: 'test_admin', rol: 'admin'),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byTooltip('Statistika'));
    await tester.pump();

    expect(find.text(_statistikaIzohi), findsOneWidget);
    // Hujjatlar izohi Statistika sahifasida ko'rinmasligi kerak.
    expect(find.text(_hujjatlarIzohi), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
