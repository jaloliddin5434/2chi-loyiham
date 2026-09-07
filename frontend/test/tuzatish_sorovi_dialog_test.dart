// Operator panelidagi "Tuzatish so'rovi" dialogi:
//  - navbatdagi mashinaga bosilganda ma'lumot dialogi ochiladi
//  - "Tuzatish so'rovi yuborish" tugmasi bor
//  - tugma bosilganda maydonlar tahrirlanadigan bo'ladi va MAJBURIY
//    sabab maydoni chiqadi
//
// flutter test muhitida HTTP serverga yetmaydi (getHujjat null qaytaradi,
// dialog baribir NavbatMashina ma'lumoti bilan ochiladi). Davriy Timer'lar
// tufayli pumpAndSettle YO'Q; oxirida boshqa widget pump qilib dispose.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/screens/operator_panel_screen.dart';
import 'package:frontend/services/navbat_service.dart';

NavbatMashina _mashina() => NavbatMashina(
      raqam: '01A777AA',
      turi: 'FAW',
      shofyor: 'Aliyev A',
      firma: 'Test MChJ',
      vaqt: '09:15',
      mahsulotId: 1,
      mahsulotNomi: 'Chigit',
      aravalar: {1: AravaData()..tara = 5000, 2: AravaData(), 3: AravaData()},
      hujjatId: 4242,
      mashinaId: 11,
      hujjatRaqam: 'CHG-2026/042',
      kelganVaqt: DateTime(2026, 9, 7, 9, 15),
      tiketRaqam: '1112223',
      klass: '1',
      seleksiyaNavi: 'Xorazm-150',
    );

void main() {
  testWidgets('Navbat mashinasi dialogi + Tuzatish so\'rovi tahrir rejimi',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    NavbatService.tozala();
    NavbatService.navbatQosh(_mashina());
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

    // Navbat ro'yxatida mashina ko'rinadi.
    expect(find.text('01A777AA'), findsWidgets);

    // Mashinaga bosish -> dialog ochilishi uchun getHujjat (null) kutiladi.
    await tester.tap(find.text('01A777AA').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Dialog ochildi.
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.textContaining("HUJJAT MA'LUMOTLARI"), findsOneWidget);
    expect(find.text("Tuzatish so'rovi yuborish"), findsOneWidget);

    // Tuzatish rejimiga o'tish.
    await tester.tap(find.text("Tuzatish so'rovi yuborish"));
    await tester.pump();

    expect(find.textContaining("TUZATISH SO'ROVI"), findsOneWidget);
    expect(find.text("Sabab (MAJBURIY) *"), findsOneWidget);
    expect(find.text("Yuborish"), findsOneWidget);

    // Tozalash: dialogni yopib, ekranni almashtirish -> Timer'lar bekor.
    await tester.tap(find.text("Orqaga"));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
