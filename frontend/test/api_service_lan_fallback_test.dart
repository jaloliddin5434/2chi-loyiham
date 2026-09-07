// ApiService LAN fallback: standart holatda so'rovlar internet (Cloudflare
// domeni) orqali ketadi; internet/Tunnel javob bermasa ilova avtomatik
// mahalliy tarmoq (LAN) manziliga o'tadi; har 30s da internet qayta
// tekshiriladi va tiklansa internet rejimiga qaytiladi. Ikkala manzil ham
// o'lik bo'lsa rejim saqlanadi (mavjud offline navbat mexanizmi ishlaydi).
//
// Health probasi `sogMiSinovOverride` orqali almashtiriladi - haqiqiy HTTP
// so'rovi yuborilmaydi.

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/api_service.dart';

void main() {
  const cloud = 'https://api.smart-tarozi.uz';
  const lan = 'http://10.112.21.54:47001';

  setUp(ApiService.ulanishHolatiniTozala);
  tearDown(ApiService.ulanishHolatiniTozala);

  test("boshlang'ich holat - internet (cloud) rejimi", () {
    expect(ApiService.baseUrl, cloud);
    expect(ApiService.lanRejimi.value, false);
  });

  test("internet javob bermasa - LAN rejimiga o'tadi", () async {
    // cloud (https) o'lik, LAN (http) tirik
    ApiService.sogMiSinovOverride = (manzil) async => manzil.startsWith('http://');

    await ApiService.ulanishniTekshir();

    expect(ApiService.baseUrl, lan);
    expect(ApiService.lanRejimi.value, true);
  });

  test("baseUrlniAniqlash - internet yo'q bo'lsa LAN'da boshlanadi", () async {
    ApiService.sogMiSinovOverride = (manzil) async => manzil.startsWith('http://');

    await ApiService.baseUrlniAniqlash();

    expect(ApiService.baseUrl, lan);
    expect(ApiService.lanRejimi.value, true);
  });

  test("internet tiklansa - avtomatik internet rejimiga qaytadi", () async {
    ApiService.sogMiSinovOverride = (m) async => m.startsWith('http://');
    await ApiService.ulanishniTekshir();
    expect(ApiService.lanRejimi.value, true);

    // internet qaytdi (hammasi tirik) - keyingi 30s tekshiruvi cloud'ni topadi
    ApiService.sogMiSinovOverride = (m) async => true;
    await ApiService.ulanishniTekshir();

    expect(ApiService.baseUrl, cloud);
    expect(ApiService.lanRejimi.value, false);
  });

  test("ikkala manzil ham o'lik - rejim o'zgarmaydi (offline)", () async {
    ApiService.sogMiSinovOverride = (m) async => m.startsWith('http://');
    await ApiService.ulanishniTekshir();
    expect(ApiService.lanRejimi.value, true);

    // internet ham, LAN ham javob bermayapti
    ApiService.sogMiSinovOverride = (m) async => false;
    await ApiService.ulanishniTekshir();

    // LAN rejimida qoladi - so'rovlar avvalgidek xato beradi va offline
    // navbatga tushadi (failover offline mexanizmga tegmaydi).
    expect(ApiService.lanRejimi.value, true);
    expect(ApiService.baseUrl, lan);
  });

  test("lanRejimi ValueNotifier rejim o'zgarishida xabar beradi (UI ko'rsatkichi)",
      () async {
    final ozgarishlar = <bool>[];
    void tinglovchi() => ozgarishlar.add(ApiService.lanRejimi.value);
    ApiService.lanRejimi.addListener(tinglovchi);
    addTearDown(() => ApiService.lanRejimi.removeListener(tinglovchi));

    ApiService.sogMiSinovOverride = (m) async => m.startsWith('http://');
    await ApiService.ulanishniTekshir(); // -> true
    ApiService.sogMiSinovOverride = (m) async => true;
    await ApiService.ulanishniTekshir(); // -> false

    expect(ozgarishlar, [true, false]);
  });

  test("tarmoqXatosi() - 5 soniya ichida qayta tekshirmaydi (debounce)",
      () async {
    var probaSoni = 0;
    ApiService.sogMiSinovOverride = (m) async {
      probaSoni++;
      return true;
    };
    await ApiService.ulanishniTekshir(); // 1 ta cloud probasi
    final avvalgi = probaSoni;

    ApiService.tarmoqXatosi(); // hozirgina tekshirildi -> o'tkazib yuboriladi
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(probaSoni, avvalgi,
        reason: "5s ichida takroriy tekshiruv bo'lmasligi kerak");
  });
}
