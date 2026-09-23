// Bug: navbatdanTanlash() operator ekranining taraSaqlangan/
// bruttoSaqlangan bayroqlarini Navbat.aravalar_json'dan (NavbatMashina.
// aravalar) o'rnatadi - bu mashina navbatga QO'YILGAN paytdagi
// "muzlatilgan" holat, undan keyin HECH QACHON yangilanmaydi (brutto/
// tara alohida Olchov jadvaliga yoziladi, Navbat qatoriga qaytib
// tegmaydi). Ikki kompyuterli sxemada (1-kompyuterdan tara, 2-
// kompyuterdan brutto o'lchansa) 2-kompyuter ba'zi aravalarning tarasini
// "ko'rmasligi" mumkin edi - natijada 1-arava bruttosi saqlangach, 2-
// arava hali tara OLMAGAN deb (demak "brutto shart emas" deb) noto'g'ri
// hisoblanib, hujjat vaqtidan oldin tugallanib qolardi.
//
// Tuzatish: navbatdanTanlash() endi HAQIQIY (eng so'nggi) holatni har
// arava bo'yicha alohida GET /olchovlar/{hujjat_id} orqali backenddan
// qayta tekshiradi va taraSaqlangan/bruttoSaqlangan bayroqlarini shunga
// mos yangilaydi.
//
// Tarmoq (HTTP) chaqiruvlari http.runWithClient() orqali MockClient
// bilan almashtiriladi - haqiqiy (production) backendga hech qanday
// so'rov ketmaydi.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:frontend/screens/operator_panel_screen.dart';

/// 2 aravali mashina - "muzlatilgan" Navbat.aravalar_json faqat 1-arava
/// tarasini ko'rsatadi (2-arava tarasi navbatga qo'yilgandan KEYIN,
/// boshqa vaqtda/kompyuterdan o'lchangan deb faraz qilinadi - shu sabab
/// bu yerda YO'Q).
NavbatMashina _muzlatilganIkkiAravaliMashina() => NavbatMashina(
      raqam: '01A777KAM',
      turi: 'Kamaz',
      shofyor: 'Shofyor',
      firma: 'Test Firma',
      vaqt: '09:00',
      mahsulotId: 1,
      mahsulotNomi: 'Chigit',
      aravalar: {
        1: AravaData()..tara = 5000,
        2: AravaData(), // muzlatilgan holatda tara YO'Q
        3: AravaData(),
      },
      hujjatId: 555,
      mashinaId: 9,
      hujjatRaqam: 'CHG-555',
      aravalarSoni: 2,
      kelganVaqt: DateTime(2026, 9, 17, 9, 0),
      tiketRaqam: 'TIK-555',
    );

http.Response _olchovlarJavobi(List<Map<String, dynamic>> qatorlar) =>
    http.Response(jsonEncode(qatorlar), 200);

/// Ekranni quradi va TOPBAR'dagi "Hujjat: ..." chipi (mashina navbatdan
/// tanlanganda ko'rinadi) sabab bo'ladigan, bu o'zgarishlarga aloqasiz
/// mavjud RenderFlex overflow'ni filtrlaydi - xuddi
/// operator_kop_arava_brutto_test.dart'dagi kabi.
Future<dynamic> _ekranniQurVaHolatniOl(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1800, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

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

  return tester.state(find.byType(OperatorPanelScreen));
}

void main() {
  testWidgets(
      "navbatdanTanlash(): muzlatilgan ma'lumotda yo'q 2-arava tarasi "
      "HAQIQIY olchovlardan (GET /olchovlar) tiklanadi",
      (WidgetTester tester) async {
    final state = await _ekranniQurVaHolatniOl(tester);

    await http.runWithClient(() async {
      // HAQIQIY backend: 2-arava tarasi (4800 kg) BOR - faqat
      // "muzlatilgan" navbat yozuvida yo'q edi.
      await state.navbatdanTanlash(_muzlatilganIkkiAravaliMashina());
    }, () => MockClient((req) async {
          if (req.url.path.endsWith('/olchovlar/555')) {
            return _olchovlarJavobi([
              {'arava_raqam': 1, 'tara': 5000, 'brutto': null, 'konditsion': null},
              {'arava_raqam': 2, 'tara': 4800, 'brutto': null, 'konditsion': null},
            ]);
          }
          return http.Response('{}', 404);
        }));
    await tester.pump();

    expect(state.taraSaqlangan1, isTrue);
    expect(state.taraSaqlangan2, isTrue,
        reason:
            "HAQIQIY olchov ma'lumoti 2-arava tarasi borligini ko'rsatadi - "
            "muzlatilgan holat buni yashirgan edi");
    expect(state.aravalar[2].tara, 4800);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets(
      "navbatdanTanlash(): tarmoq xatosida ESKI (muzlatilgan) holat "
      "saqlanib qoladi, hech narsa tozalanmaydi",
      (WidgetTester tester) async {
    final state = await _ekranniQurVaHolatniOl(tester);

    await http.runWithClient(() async {
      await state.navbatdanTanlash(_muzlatilganIkkiAravaliMashina());
    }, () => MockClient((req) async => throw Exception('tarmoq xatosi (sinov)')));
    await tester.pump();

    // Tarmoq ishlamadi - eski (muzlatilgan) qiymatlar o'zgarishsiz
    // qolishi kerak (yo'qolib/noto'g'ri tozalanib qolmasligi kerak).
    expect(state.taraSaqlangan1, isTrue);
    expect(state.taraSaqlangan2, isFalse);
    expect(state.aravalarSoni, 2);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets(
      "navbatdanTanlash(): yerli (hali sinxronlanmagan) hujjat uchun "
      "HTTP so'rov yuborilmaydi",
      (WidgetTester tester) async {
    final state = await _ekranniQurVaHolatniOl(tester);

    final yerliMashina = NavbatMashina(
      raqam: '01A000YY',
      turi: 'Kamaz',
      shofyor: 'Shofyor',
      firma: 'Test Firma',
      vaqt: '09:00',
      mahsulotId: 1,
      mahsulotNomi: 'Chigit',
      aravalar: {1: AravaData()..tara = 3000, 2: AravaData(), 3: AravaData()},
      hujjatId: -1, // yerli (offline) ID - backendda hali mavjud emas
      mashinaId: -1,
      hujjatRaqam: '',
      aravalarSoni: 2,
      kelganVaqt: DateTime(2026, 9, 17, 9, 0),
    );

    var sorovlarSoni = 0;
    await http.runWithClient(() async {
      await state.navbatdanTanlash(yerliMashina);
    }, () => MockClient((req) async {
          sorovlarSoni++;
          return http.Response('{}', 200);
        }));
    await tester.pump();

    expect(sorovlarSoni, 0,
        reason: "yerli (manfiy) hujjat_id uchun backendga so'rov "
            "yuborilmasligi kerak");
    expect(state.taraSaqlangan1, isTrue);
    expect(state.taraSaqlangan2, isFalse);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
