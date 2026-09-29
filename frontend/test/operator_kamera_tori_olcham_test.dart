// Bug: operator panelidagi kamera rasmlari (2x2 to'r) juda katta edi -
// har bir kadr AspectRatio(1) kvadrat bo'lib, kengligi bilan birga
// o'sardi. Keng ekranda to'r ekranga sig'mas, rasmlarni ko'rish uchun
// sahifani pastga surish kerak bo'lardi.
//
// Tuzatish: to'r ekran balandligining ~32% iga teng qat'iy balandlikka
// joylashtirildi, kadrlar shu joyni to'ldiradi.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/screens/operator_panel_screen.dart';

final _tor = find.byKey(const ValueKey('kamera_rasmlar_tori'));

Future<void> _ekranniOch(WidgetTester tester, Size olcham) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = olcham;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  // 1366x768 va mobil o'lchamda boshqa kartalarda (kamera to'riga
  // aloqasiz) GORIZONTAL RenderFlex overflow bor - bu o'zgarishdan oldin
  // ham xuddi shunday edi (arava_soni_selektor_disabled_test.dart'dagi
  // kabi e'tiborsiz qoldiriladi).
  final asliyOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exception.toString().contains('RenderFlex overflowed')) {
      return;
    }
    asliyOnError?.call(details);
  };
  addTearDown(() => FlutterError.onError = asliyOnError);

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

Future<void> _yop(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
}

void main() {
  for (final olcham in const [
    Size(1920, 1080),
    Size(1366, 768),
    Size(1800, 1400),
    Size(400, 850), // mobil
  ]) {
    testWidgets(
        'kamera to\'ri ekran balandligining 30-35% ini oladi '
        '(${olcham.width.toInt()}x${olcham.height.toInt()})',
        (WidgetTester tester) async {
      await _ekranniOch(tester, olcham);

      expect(_tor, findsOneWidget);
      final torBalandligi = tester.getSize(_tor).height;
      final ulush = torBalandligi / olcham.height;
      expect(ulush, inInclusiveRange(0.30, 0.35),
          reason: 'to\'r balandligi $torBalandligi px = '
              '${(ulush * 100).toStringAsFixed(1)}% ekran');

      // 4 ta kadr ham to'r ichida to'liq joylashadi (hech biri chiqib
      // ketmaydi) va ko'rinarli o'lchamda.
      final torRect = tester.getRect(_tor);
      for (final label in const [
        'Tara CAM-1',
        'Tara CAM-2',
        'Brutto CAM-1',
        'Brutto CAM-2',
      ]) {
        final kadr = find.ancestor(
            of: find.text(label), matching: find.byType(Container)).first;
        final r = tester.getRect(kadr);
        expect(torRect.contains(r.topLeft) && torRect.contains(r.bottomRight - const Offset(0.01, 0.01)),
            isTrue,
            reason: '$label kadri to\'rdan chiqib ketdi: $r / $torRect');
        expect(r.height, greaterThan(torBalandligi * 0.4));
      }

      await _yop(tester);
    });
  }

  testWidgets(
      'desktop (1920x1080): kamera to\'ri pastga surmasdan to\'liq ko\'rinadi',
      (WidgetTester tester) async {
    await _ekranniOch(tester, const Size(1920, 1080));

    final torRect = tester.getRect(_tor);
    expect(torRect.bottom, lessThanOrEqualTo(1080),
        reason: 'kamera to\'rining pasti ekrandan tashqarida: $torRect');

    await _yop(tester);
  });
}
