// Bug: "Aravalar:" selektoridagi 1/2/3 tugmalari tara SAQLANGANDAN
// KEYIN ham (bazagaSaqlandi == true) bosilishi mumkin edi. Operator
// hujjat allaqachon serverga yozilgandan keyin ham mahalliy
// aravalarSoni'ni o'zgartira olardi - bu holatda ekrandagi qiymat
// serverdagi hujjat.aravalar_soni'dan chetlashib qolardi (masalan
// _keyingiBruttoSizArava() 1..aravalarSoni oralig'ida noto'g'ri
// qidiradi).
//
// Tuzatish: bazagaSaqlandi == true bo'lsa, tugmalar disabled (onTap:
// null) va ustiga Tooltip("Tara saqlangandan keyin o'zgartirib
// bo'lmaydi") chiqadi.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/screens/operator_panel_screen.dart';
import 'package:frontend/services/navbat_service.dart';

const _disabledXabar = "Tara saqlangandan keyin o'zgartirib bo'lmaydi";

NavbatMashina _bitAravaliMashina() => NavbatMashina(
      raqam: '01A777KAM',
      turi: 'Kamaz',
      shofyor: 'Shofyor',
      firma: 'Test Firma',
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

/// "Aravalar:" tugmalari qatoridagi berilgan raqamga mos GestureDetector'ni
/// topadi - shu raqamning Tooltip xabari orqali (bir nechta "1"/"2"/"3"
/// matnli widget ekranda bo'lishi mumkinligi uchun aniq topish kerak).
Finder _aravaTugmasi(int i) {
  final tooltiplar = find.byWidgetPredicate((w) => w is Tooltip);
  return find.descendant(
    of: tooltiplar,
    matching: find.text('$i'),
  );
}

void main() {
  testWidgets(
      'bazagaSaqlandi=false bo\'lsa arava tugmalari ishlaydi, tooltip bo\'sh',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
    expect(state.bazagaSaqlandi, isFalse);
    expect(state.aravalarSoni, 1);

    // Hali saqlanmagan - tugma bosilsa aravalarSoni o'zgaradi.
    await tester.tap(_aravaTugmasi(3));
    await tester.pump();
    expect(state.aravalarSoni, 3);

    // Faol holatda tooltip xabari bo'sh (disabled ogohlantirishi yo'q).
    final tooltip = tester.widget<Tooltip>(find
        .ancestor(of: _aravaTugmasi(1), matching: find.byType(Tooltip))
        .first);
    expect(tooltip.message, isEmpty);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets(
      'bazagaSaqlandi=true bo\'lsa arava tugmalari disabled va tooltip chiqadi',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // TOPBAR'dagi "Hujjat: ..." chipi (mashina navbatdan tanlanganda
    // ko'rinadi) o'zgarishlarga aloqasiz, mavjud RenderFlex overflow'ga
    // sabab bo'ladi (operator_kop_arava_brutto_test.dart'dagi kabi).
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

    // Tara(lar) saqlangan holatni simulyatsiya qiladi - navbatdanTanlash()
    // bazagaSaqlandi'ni true'ga o'rnatadi (haqiqiy HTTP so'rovsiz).
    state.navbatdanTanlash(_bitAravaliMashina());
    await tester.pump();
    expect(state.bazagaSaqlandi, isTrue);
    expect(state.aravalarSoni, 1);

    // GestureDetector.onTap null - dastur darajasida bosish imkonsiz.
    final gd = tester.widget<GestureDetector>(find.ancestor(
        of: _aravaTugmasi(2), matching: find.byType(GestureDetector)).first);
    expect(gd.onTap, isNull);

    // Har ehtimolga qarshi "bossak ham" qiymat o'zgarmasligini tekshiradi.
    await tester.tap(_aravaTugmasi(2), warnIfMissed: false);
    await tester.pump();
    expect(state.aravalarSoni, 1,
        reason: 'Tara saqlangandan keyin arava soni o\'zgarmasligi kerak');

    // Tooltip ogohlantirish xabarini ko'rsatadi.
    final tooltip = tester.widget<Tooltip>(find
        .ancestor(of: _aravaTugmasi(2), matching: find.byType(Tooltip))
        .first);
    expect(tooltip.message, _disabledXabar);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
