// Bug: operator "Saqlash" tugmasini TEZ ikki marta bossa (masalan
// birinchi Tara saqlashda), ikkita mashina/hujjat yaratilishi mumkin
// edi. Sabab: qayta-bosishdan himoya bayrog'i (saqlanmoqda) faqat
// _bazagaSaqla() (mashina+hujjat yaratuvchi tarmoq so'rovi) TUGAGANDAN
// KEYIN true qilinardi - ikkinchi bosish shu oraliqda hali
// saqlanmoqda=false ko'rib, yana bir marta _bazagaSaqla()ni chaqirar
// edi.
//
// Tuzatish: saqlanmoqda ENDI saqlash() funksiyasining eng boshida,
// har qanday await'dan OLDIN, darhol true qilinadi. Dart'da async
// funksiya BIRINCHI await'gacha SINXRON ishlaydi - shu sabab ikkinchi
// chaqiruv birinchisi hali _bazagaSaqla()ni kutayotgan bo'lsa ham,
// yuqoridagi "if (saqlanmoqda...) return;" tekshiruvidan darhol
// qaytadi (vaqt/tasodifga bog'liq emas, har doim shunday ishlaydi).
//
// Har bir "haqiqiy saqlashgacha" bo'lgan erta qaytish (validatsiya
// xatosi, dialog bekor qilinishi, _bazagaSaqla() muvaffaqiyatsiz
// bo'lishi) saqlanmoqda'ni QAYTA false qilishi ham tekshiriladi - aks
// holda tugma sababsiz 10 soniyaga qulflanib qolardi.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/screens/operator_panel_screen.dart';

Future<void> _ekranniQur(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(1800, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  // Ekrandagi (bu o'zgarishlarga aloqasiz) mavjud RenderFlex overflow -
  // xuddi operator_kop_arava_brutto_test.dart'dagi kabi filtrlanadi.
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
      mahsulotId: 1, // Chigit - konditsionBor=true (namlik/ifloslik testi uchun)
      mahsulotNomi: 'Chigit',
      mahsulotRang: Colors.green,
    ),
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets(
      'Tara saqlash tugmasi ikki marta tez bosilsa faqat BITTA mashina/hujjat yaratiladi',
      (WidgetTester tester) async {
    await _ekranniQur(tester);
    final state = tester.state(find.byType(OperatorPanelScreen)) as dynamic;

    state.raqamiCtrl.text = '01A777AA';
    state.turiCtrl.text = 'Kamaz';
    state.shofyorCtrl.text = 'Test Shofyor';
    state.taroziKg = 5000.0;

    int mashinalarSorovlari = 0;
    int hujjatlarSorovlari = 0;

    await http.runWithClient(() async {
      // Ikkalasini ham KETMA-KET, BIRINCHISINI KUTMASDAN chaqiramiz -
      // haqiqiy "tugmani ikki marta tez bosish"ni aynan shunday
      // simulyatsiya qilish mumkin (Dart async funksiya birinchi
      // await'gacha sinxron ishlaydi, shu sabab bu ikkinchi chaqiruv
      // birinchisi hali _bazagaSaqla()ni kutayotgan payti bilan bir xil).
      final f1 = state.saqlash() as Future;
      final f2 = state.saqlash() as Future;
      await f1;
      await f2;
      await tester.pump();
    }, () => MockClient((req) async {
          if (req.method == 'POST' && req.url.path.endsWith('/mashinalar')) {
            mashinalarSorovlari++;
            return http.Response(
                '{"id": 555, "davlat_raqami": "01A777AA", "turi": "Kamaz", '
                '"shofyor": "Test Shofyor", "firma": ""}',
                200);
          }
          if (req.method == 'POST' && req.url.path.endsWith('/hujjatlar')) {
            hujjatlarSorovlari++;
            return http.Response('{"id": 999, "raqam": "CHG-2026/001"}', 200);
          }
          return http.Response('{}', 200);
        }));

    expect(mashinalarSorovlari, 1,
        reason:
            'Ikki marta tez bosilganda faqat BITTA mashina yaratilishi kerak edi!');
    expect(hujjatlarSorovlari, 1,
        reason:
            'Ikki marta tez bosilganda faqat BITTA hujjat yaratilishi kerak edi!');

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets(
      "Noto'g'ri namlik kiritilsa, saqlanmoqda darhol false ga qaytadi (tugma qulflanib qolmaydi)",
      (WidgetTester tester) async {
    await _ekranniQur(tester);
    final state = tester.state(find.byType(OperatorPanelScreen)) as dynamic;

    state.raqamiCtrl.text = '01A777AA';
    state.namlikCtrl.text = 'abc'; // son emas - validatsiya rad etishi kerak
    state.taroziKg = 5000.0;

    expect(state.saqlanmoqda, isFalse);
    await (state.saqlash() as Future);
    await tester.pump();

    expect(state.saqlanmoqda, isFalse,
        reason:
            "Validatsiya xatosidan keyin ham saqlanmoqda darhol false bo'lishi kerak "
            "(10 soniyalik qulf faqat HAQIQIY saqlashdan keyin ishga tushishi kerak)");

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets(
      'Arava allaqachon tara olingan bo\'lsa, saqlanmoqda darhol false ga qaytadi',
      (WidgetTester tester) async {
    await _ekranniQur(tester);
    final state = tester.state(find.byType(OperatorPanelScreen)) as dynamic;

    state.raqamiCtrl.text = '01A777AA';
    state.taraSaqlangan1 = true; // 1-arava tarasi allaqachon saqlangan
    state.taroziKg = 5000.0;

    await (state.saqlash() as Future);
    await tester.pump();

    expect(state.saqlanmoqda, isFalse);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
