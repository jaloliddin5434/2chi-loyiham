// Mobil (isMobile, eni < 700) operator panelida sahifa pastga surilgandan
// keyin yuqoriga qayta surilishi kerak. Shikoyat: "telefonda pastga
// scroll qilingach, yuqoriga qaytmayapti". Bu test widget darajasida
// ikki holatda (bo'sh panel va tara saqlangan + firma avto-to'ldirish
// ochiq) ikki yo'nalishda ham touch-drag ishlashini qayd etadi.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/screens/operator_panel_screen.dart';
import 'package:frontend/services/navbat_service.dart';

NavbatMashina _taraSaqlanganMashina() => NavbatMashina(
      raqam: '01A777KAM',
      turi: 'Kamaz',
      shofyor: 'Shofyor',
      firma: '',
      vaqt: '09:00',
      mahsulotId: 1,
      mahsulotNomi: 'Chigit',
      aravalar: {
        1: AravaData()..tara = 5000,
        2: AravaData(),
        3: AravaData(),
      },
      hujjatId: 555,
      mashinaId: 9,
      hujjatRaqam: 'CHG-555',
      aravalarSoni: 1,
      kelganVaqt: DateTime(2026, 9, 23, 9, 0),
      tiketRaqam: 'TIK-555',
    );

Future<void> _mobildaOch(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(400, 850);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  // Mobil o'lchamda boshqa kartalarda scroll'ga aloqasiz GORIZONTAL
  // RenderFlex overflow bor (operator_kamera_tori_olcham_test.dart'ga
  // qarang) - e'tiborsiz qoldiriladi.
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
}

/// Mobil sahifaning asosiy (vertikal) scroll pozitsiyasi.
ScrollPosition _pozitsiya(WidgetTester tester) => tester
    .stateList<ScrollableState>(find.byType(Scrollable))
    .firstWhere((s) => s.axisDirection == AxisDirection.down)
    .position;

/// Barmoq bilan surish + inersiya tugashini kutish (800ms tarozi
/// taymeri tufayli pumpAndSettle ishlatib bo'lmaydi).
Future<void> _sur(WidgetTester tester, Offset boshi, double dy) async {
  await tester.dragFrom(boshi, Offset(0, dy));
  for (int i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _yop(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
}

void main() {
  testWidgets('mobil: pastga surilgach yuqoriga qaytadi (ekranning har joyidan)',
      (WidgetTester tester) async {
    await _mobildaOch(tester);
    expect(_pozitsiya(tester).maxScrollExtent, greaterThan(300),
        reason: 'sahifa surish uchun yetarlicha uzun bo\'lishi kerak');

    for (final boshi in const [
      Offset(200, 200),
      Offset(200, 400),
      Offset(200, 700),
      Offset(60, 500),
      Offset(340, 500),
    ]) {
      await _sur(tester, boshi, -600);
      expect(_pozitsiya(tester).pixels, greaterThan(300),
          reason: '$boshi dan pastga surilmadi');
      await _sur(tester, boshi, 600);
      expect(_pozitsiya(tester).pixels, 0,
          reason: '$boshi dan yuqoriga qaytmadi');
    }

    await _yop(tester);
  });

  testWidgets(
      'mobil: tara saqlangan, firma maydoni fokusda (avto-to\'ldirish ochiq) - '
      'yuqoriga surish ishlaydi', (WidgetTester tester) async {
    await _mobildaOch(tester);
    final state = tester.state(find.byType(OperatorPanelScreen)) as dynamic;
    state.navbatdanTanlash(_taraSaqlanganMashina());
    state.setState(() {
      state.firmaRoyxati = List<String>.generate(20, (i) => 'Firma $i');
    });
    await tester.pump();

    final firma = find.widgetWithText(TextField, 'Firma nomi');
    await tester.ensureVisible(firma);
    await tester.pump();
    await tester.tap(firma);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Firma 0'), findsOneWidget,
        reason: 'avto-to\'ldirish ro\'yxati ochiq bo\'lishi kerak');

    await _sur(tester, const Offset(200, 700), -400);
    final pastda = _pozitsiya(tester).pixels;

    for (final y in const [150.0, 350.0, 600.0]) {
      await _sur(tester, Offset(200, y), 150);
      expect(_pozitsiya(tester).pixels, lessThan(pastda),
          reason: 'y=$y dan yuqoriga surilmadi');
      _pozitsiya(tester).jumpTo(pastda);
      await tester.pump();
    }

    await _yop(tester);
  });
}
