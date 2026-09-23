// Bug: ApiService.getHujjatlar() boshqa 27 ta ApiService funksiyasidan
// farqli, HECH QANDAY try/catch ishlatmasdi - tarmoq xatosida (server
// javob bermasa) tarmoqXatosi() hech qachon chaqirilmasdi, shu sabab
// LAN fallback (avtomatik mahalliy tarmoqqa o'tish) admin panelidagi
// hujjatlar ro'yxati uchun ishga tushmasdi.
//
// Tuzatish: http.get() chaqiruvi endi try/catch bilan o'ralgan - tarmoq
// xatosida (boshqa 27 ta funksiyadagi bilan bir xil) tarmoqXatosi()
// chaqiriladi, so'ngra xato qayta uzatiladi.

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:frontend/services/api_service.dart';

void main() {
  setUp(ApiService.ulanishHolatiniTozala);
  tearDown(ApiService.ulanishHolatiniTozala);

  test(
      "getHujjatlar() tarmoq xatosida tarmoqXatosi()ni chaqiradi (LAN rejimiga o'tadi)",
      () async {
    // cloud (https) o'lik, LAN (http) tirik - tarmoqXatosi() shu holatni
    // ko'rib, LAN rejimiga o'tishi kerak (agar chindan chaqirilsa).
    ApiService.sogMiSinovOverride =
        (manzil) async => manzil.startsWith('http://');
    expect(ApiService.lanRejimi.value, isFalse);

    await http.runWithClient(() async {
      await expectLater(
        ApiService.getHujjatlar(),
        throwsA(isA<Exception>()),
      );
    }, () => MockClient((req) async => throw Exception('tarmoq xatosi (sinov)')));

    // tarmoqXatosi() ichidagi ulanishniTekshir() await QILINMAYDI
    // (fire-and-forget) - shu sabab tugashini biroz kutamiz.
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(ApiService.lanRejimi.value, isTrue,
        reason:
            "getHujjatlar() tarmoq xatosida tarmoqXatosi()ni chaqirib, LAN "
            "rejimiga o'tkazishi kerak edi");
  });

  test("getHujjatlar() muvaffaqiyatli javobda odatdagidek natija qaytaradi",
      () async {
    await http.runWithClient(() async {
      final natija = await ApiService.getHujjatlar();
      expect(natija, {'natijalar': [], 'jami': 0});
    }, () => MockClient(
        (req) async => http.Response('{"natijalar": [], "jami": 0}', 200)));

    expect(ApiService.lanRejimi.value, isFalse,
        reason: "Muvaffaqiyatli javobda LAN rejimiga o'tmasligi kerak");
  });
}
