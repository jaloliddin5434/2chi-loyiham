// Bug: brutto o'lchash jarayonida (faqatBrutto == true, ya'ni mashina
// navbatdan BRUTTO uchun tanlangan) "Keyingi mashina" tugmasi bosilishi
// mumkin edi - bu keyingiMashina() ni chaqirib, mashinani navbatdan
// o'chirib qayta qo'shar (yoki navbatdan butunlay olib tashlar) edi va
// hali o'lchanmagan aravalar (masalan 2-arava bruttosi) haqidagi
// ma'lumot yo'qolib qolishi mumkin edi.
//
// Shuningdek, ko'p aravali mashinada TARA bosqichida ham (faqatBrutto
// emas) barcha aravalar tara olmasdan "Keyingi mashina" bosilsa, hali
// tara o'lchanmagan arava(lar)ning ma'lumoti YO'Q holda navbatga
// qo'yilib yuborilardi.
//
// Tuzatish: 1) faqatBrutto == true bo'lsa tugma UI'da disabled; 2)
// keyingiMashina() ichida ham faqatBrutto va _keyingiTaraSizArava() !=
// null holatlari uchun alohida bloklovchi tekshiruvlar qo'shildi -
// tugma dasturiy ravishda (masalan test yoki kelajakdagi boshqa chaqiruv
// yo'li orqali) chaqirilsa ham himoyalangan.

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
      kelganVaqt: DateTime(2026, 9, 25, 9, 0),
      tiketRaqam: 'TIK-555',
    );

Future<dynamic> _ekranniQur(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(1800, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  // TOPBAR'dagi "Hujjat: ..." chipi (faqatBrutto holatida ko'rinadi)
  // mavjud RenderFlex overflow'ga sabab bo'ladi - boshqa operator panel
  // testlarida (operator_kop_arava_brutto_test.dart,
  // arava_soni_selektor_disabled_test.dart) bo'lgani kabi filtrlanadi.
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

  return tester.state(find.byType(OperatorPanelScreen));
}

Finder _keyingiMashinaTugmasi() =>
    find.widgetWithText(OutlinedButton, "Keyingi mashina");

void main() {
  testWidgets(
      "faqatBrutto=true bo'lganda 'Keyingi mashina' tugmasi UI'da disabled",
      (WidgetTester tester) async {
    final state = await _ekranniQur(tester);

    state.navbatdanTanlash(_ikkiAravaliMashina());
    await tester.pump();
    expect(state.faqatBrutto, isTrue);

    final tugma = tester.widget<OutlinedButton>(_keyingiMashinaTugmasi());
    expect(tugma.onPressed, isNull,
        reason: "brutto o'lchash jarayonida tugma bosilmasligi kerak");

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets(
      "faqatBrutto=true bo'lganda keyingiMashina() to'g'ridan chaqirilsa "
      "ham bloklanadi, mashina navbatdan yo'qolmaydi",
      (WidgetTester tester) async {
    final state = await _ekranniQur(tester);

    state.navbatdanTanlash(_ikkiAravaliMashina());
    await tester.pump();
    expect(state.faqatBrutto, isTrue);

    await http.runWithClient(() async {
      await state.keyingiMashina() as dynamic;
    }, () => MockClient((req) async =>
        throw Exception("brutto jarayonida HECH QANDAY so'rov ketmasligi kerak")));

    expect(state.tanlanganNavbat, isNotNull,
        reason: "mashina hali navbatdan tanlangan holatda qolishi kerak");
    expect(NavbatService.navbat.value, isEmpty,
        reason:
            "keyingiMashina() bloklanganda NavbatService.navbatQosh() "
            "chaqirilmasligi kerak (mashina qayta navbatga qo'yilmasligi)");
    expect(state.xabarMatni, contains('Brutto'));

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets(
      "ko'p aravali mashinada barcha aravalar tara olmasdan "
      "keyingiMashina() bloklanadi", (WidgetTester tester) async {
    final state = await _ekranniQur(tester);

    // TARA bosqichi (faqatBrutto EMAS) - 2 aravali mashina, faqat
    // 1-arava tara olgan, 2-arava hali kutilyapti.
    state.aravalarSoni = 2;
    state.bazagaSaqlandi = true;
    state.hujjatId = 555;
    state.mashinaId = 9;
    state.taraSaqlangan1 = true;
    state.taraSaqlangan2 = false;
    expect(state.faqatBrutto, isFalse);
    expect(state.tanlanganNavbat, isNull);

    await http.runWithClient(() async {
      await state.keyingiMashina() as dynamic;
    }, () => MockClient((req) async => throw Exception(
        "barcha aravalar tara olmasdan HECH QANDAY so'rov ketmasligi kerak")));

    expect(NavbatService.navbat.value, isEmpty,
        reason: "to'liq bo'lmagan arava ma'lumoti navbatga qo'yilmasligi kerak");
    expect(state.xabarMatni, contains('aravalar'));

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
