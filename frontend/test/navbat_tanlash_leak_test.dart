// navbatdanTanlash() - operator navbatdan mashina tanlab BRUTTO o'lchashga
// o'tganda, kontrollerlar AVVAL tozalanadi (bo'sh string), KEYIN navbat
// qiymatiga o'rnatiladi.
//
// Avval `if (mashina.X != null)` sharti ishlatilardi: navbatda qiymat null
// bo'lsa, OLDINGI tanlangan mashinaning qiymati kontrollerda qolib ketardi
// va brutto yakunida PUT /hujjatlar orqali NOTO'G'RI hujjatga yozilardi.
//
// Test State usulini to'g'ridan-to'g'ri chaqiradi. setState() closure'i
// SINXRON bajarilгani uchun kontroller qiymatlari darhol yangilanadi -
// keyingi qayta qurish (rebuild) KUTILMAYDI (ekranning to'liq HUJJAT
// kartasini bu Flutter versiyasида render qilish alohida, aloqasiz
// Autocomplete muammosini keltirib chiqaradi).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/screens/operator_panel_screen.dart';
import 'package:frontend/services/navbat_service.dart';

NavbatMashina _mashina({
  required String raqam,
  String? tudaRaqam,
  String? tiketRaqam,
  String? klass,
  String? sinf,
  String? seleksiyaNavi,
  double? namlik,
  double? ifloslik,
}) =>
    NavbatMashina(
      raqam: raqam,
      turi: 'FAW',
      shofyor: 'Shofyor',
      firma: 'Firma $raqam',
      vaqt: '09:00',
      mahsulotId: 1,
      mahsulotNomi: 'Chigit',
      aravalar: {1: AravaData()..tara = 5000, 2: AravaData(), 3: AravaData()},
      hujjatId: raqam.hashCode & 0x7fffff,
      mashinaId: 7,
      hujjatRaqam: 'CHG-$raqam',
      kelganVaqt: DateTime(2026, 9, 7, 9, 0),
      tudaRaqam: tudaRaqam,
      tiketRaqam: tiketRaqam,
      klass: klass,
      sinf: sinf,
      seleksiyaNavi: seleksiyaNavi,
      namlik: namlik,
      ifloslik: ifloslik,
    );

void main() {
  testWidgets(
      "navbatdanTanlash: oldingi mashina qiymatlari keyingisiga o'tib ketmaydi",
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    // Keng desktop viewport - ekranning mavjud flex Row'lari tor test
    // viewport'ida "overflow" beradi (bu o'zgarishga aloqasiz).
    tester.view.physicalSize = const Size(1800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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

    // Kontrollerlar `_OperatorPanelScreenState` da OCHIQ (underscore'siz)
    // maydonlar - `as dynamic` orqali to'g'ridan-to'g'ri o'qiladi.
    final state = tester.state(find.byType(OperatorPanelScreen)) as dynamic;
    String t(TextEditingController c) => c.text;

    // 1) Barcha ma'lumot maydonlari to'ldirilgan A mashinasi tanlanadi.
    state.navbatdanTanlash(_mashina(
      raqam: '01AAA',
      tudaRaqam: 'TUDA-A',
      tiketRaqam: 'TIK-A',
      klass: '7',
      sinf: 'X',
      seleksiyaNavi: 'Sel-A',
      namlik: 9.5,
      ifloslik: 3.5,
    ));

    expect(t(state.tiketRaqamCtrl), 'TIK-A');
    expect(t(state.tudaRaqamCtrl), 'TUDA-A');
    expect(t(state.klassCtrl), '7');
    expect(t(state.sinfCtrl), 'X');
    expect(t(state.seleksiyaNaviCtrl), 'Sel-A');
    expect(t(state.namlikCtrl), '9.5');
    expect(t(state.ifloslikCtrl), '3.5');

    // 2) Hech qanday ma'lumot maydoni bo'lmagan B mashinasi tanlanadi.
    state.navbatdanTanlash(_mashina(raqam: '02BBB'));

    // A ning qiymatlari B ga O'TMASLIGI kerak - hammasi tozalangan.
    expect(t(state.tiketRaqamCtrl), '');
    expect(t(state.tudaRaqamCtrl), '');
    expect(t(state.klassCtrl), '');
    expect(t(state.sinfCtrl), '');
    expect(t(state.seleksiyaNaviCtrl), '');
    expect(t(state.namlikCtrl), '');
    expect(t(state.ifloslikCtrl), '');
    expect(t(state.qabulQildiCtrl), '');
    expect(t(state.yukOlindiCtrl), '');
    expect(t(state.dostaverkaCtrl), '');

    // Shartsiz (har doim o'rnatiladigan) maydonlar B ga yangilanadi.
    expect(t(state.raqamiCtrl), '02BBB');
    expect(t(state.firmaCtrl), 'Firma 02BBB');

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets(
      "navbatdanTanlash'dan keyin HUJJAT kartasi (firma Autocomplete) xatosiz render bo'ladi",
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    // Juda katta viewport - post-tara holatida ko'p karta ochiladi,
    // kichik viewport'da flex Row'lar overflow beradi (bu tekshiruvga
    // aloqasiz kosmetik ogohlantirish).
    tester.view.physicalSize = const Size(2400, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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

    // Tara'dan keyingi holat -> HUJJAT kartasi ochiladi, u firma uchun
    // Autocomplete ishlatadi. Avval bu yerda RawAutocomplete assert xatosi
    // bo'lardi: `(focusNode == null) == (textEditingController == null)`.
    state.navbatdanTanlash(_mashina(raqam: '01AAA', tiketRaqam: 'TIK'));
    await tester.pump();

    expect(find.text('Firma nomi'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
