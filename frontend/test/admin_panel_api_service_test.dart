// Bug: admin_panel_screen.dart 15+ joyda http.get()/post()/put() ni
// to'g'ridan (ApiService orqali EMAS) chaqirardi - statistika/kunlik,
// statistika/grafik/*, server/holat, users (GET/POST), users/{id}/parol,
// users/{id}/holat, hujjatlar/{id} (tahrirlash/o'chirish). Bu joylar
// ApiService ichidagi try/catch + tarmoqXatosi() (LAN fallback) ni
// chetlab o'tardi - tarmoq uzilganda admin panel abadiy "internet"
// rejimida qolib ketardi, LAN'ga hech qachon o'tmasdi.
//
// Tuzatish: barcha shu joylar endi ApiService dagi (kerak bo'lsa yangi
// qo'shilgan) funksiyalarga almashtirildi. Bu test har biri tarmoq
// xatosida haqiqatan tarmoqXatosi()ni (demak LAN rejimiga o'tishni)
// chaqirishini tekshiradi.

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/offline_queue_service.dart';

void main() {
  setUp(ApiService.ulanishHolatiniTozala);
  tearDown(ApiService.ulanishHolatiniTozala);

  Future<void> lanGaOtishiniTekshir(Future<void> Function() amal) async {
    ApiService.sogMiSinovOverride =
        (manzil) async => manzil.startsWith('http://');
    expect(ApiService.lanRejimi.value, isFalse);

    await http.runWithClient(() async {
      await amal();
    }, () => MockClient((req) async => throw Exception('tarmoq xatosi (sinov)')));

    // tarmoqXatosi() ichidagi ulanishniTekshir() fire-and-forget.
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(ApiService.lanRejimi.value, isTrue,
        reason: "tarmoq xatosida tarmoqXatosi() chaqirilib, LAN rejimiga "
            "o'tkazishi kerak edi");
  }

  group('statistika (kunlik/haftalik/oylik/mavsum)', () {
    test("getKunlikStat() tarmoq xatosida LAN rejimiga o'tadi", () async {
      await lanGaOtishiniTekshir(() async {
        await expectLater(
            ApiService.getKunlikStat(), throwsA(isA<Exception>()));
      });
    });

    test("getKunlikStat() muvaffaqiyatli javobda natija qaytaradi",
        () async {
      await http.runWithClient(() async {
        final natija = await ApiService.getKunlikStat();
        expect(natija, {'soni': 3});
      }, () => MockClient((req) async => http.Response('{"soni": 3}', 200)));
      expect(ApiService.lanRejimi.value, isFalse);
    });
  });

  group('statistika/grafik/{davr}', () {
    test("getGrafikKunlik() tarmoq xatosida LAN rejimiga o'tadi", () async {
      await lanGaOtishiniTekshir(() async {
        await expectLater(
            ApiService.getGrafikKunlik(), throwsA(isA<Exception>()));
      });
    });

    test("getGrafikKunlik() muvaffaqiyatli javobda natija qaytaradi",
        () async {
      await http.runWithClient(() async {
        final natija = await ApiService.getGrafikKunlik();
        expect(natija, [1, 2, 3]);
      }, () => MockClient((req) async => http.Response('[1,2,3]', 200)));
      expect(ApiService.lanRejimi.value, isFalse);
    });
  });

  group('server/holat', () {
    test("getServerHolat() tarmoq xatosida LAN rejimiga o'tadi", () async {
      await lanGaOtishiniTekshir(() async {
        await expectLater(
            ApiService.getServerHolat(), throwsA(isA<Exception>()));
      });
    });
  });

  group('users (ro\'yxat)', () {
    test("getFoydalanuvchilar() tarmoq xatosida LAN rejimiga o'tadi",
        () async {
      await lanGaOtishiniTekshir(() async {
        await expectLater(
            ApiService.getFoydalanuvchilar(), throwsA(isA<Exception>()));
      });
    });

    test("getFoydalanuvchilar() muvaffaqiyatli javobda natija qaytaradi",
        () async {
      await http.runWithClient(() async {
        final natija = await ApiService.getFoydalanuvchilar();
        expect(natija, [
          {'id': 1, 'username': 'op1'}
        ]);
      }, () => MockClient((req) async =>
          http.Response('[{"id": 1, "username": "op1"}]', 200)));
      expect(ApiService.lanRejimi.value, isFalse);
    });
  });

  group('foydalanuvchiQoshish (POST /users)', () {
    test("tarmoq xatosida LAN rejimiga o'tadi va xato matni qaytaradi",
        () async {
      ApiService.sogMiSinovOverride =
          (manzil) async => manzil.startsWith('http://');
      expect(ApiService.lanRejimi.value, isFalse);

      String? xato;
      await http.runWithClient(() async {
        xato = await ApiService.foydalanuvchiQoshish('op2', 'parol123', 'operator');
      }, () => MockClient((req) async => throw Exception('tarmoq xatosi (sinov)')));

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(ApiService.lanRejimi.value, isTrue);
      expect(xato, isNotNull);
    });

    test("muvaffaqiyatli bo'lsa null qaytaradi", () async {
      String? xato;
      await http.runWithClient(() async {
        xato = await ApiService.foydalanuvchiQoshish('op2', 'parol123', 'operator');
      }, () => MockClient((req) async => http.Response('{}', 200)));
      expect(xato, isNull);
      expect(ApiService.lanRejimi.value, isFalse);
    });

    test("server rad etsa (masalan login band) ANIQ xato matnini qaytaradi, "
        "LAN rejimiga O'TMAYDI", () async {
      String? xato;
      await http.runWithClient(() async {
        xato = await ApiService.foydalanuvchiQoshish('op2', 'parol123', 'operator');
      }, () => MockClient((req) async => http.Response(
          '{"detail": "Bu login band"}', 400)));
      expect(xato, 'Bu login band');
      expect(ApiService.lanRejimi.value, isFalse,
          reason: "server yetib bordi, shuning uchun LAN'ga o'tmasligi kerak");
    });
  });

  group('foydalanuvchiParolOzgartir (PUT /users/{id}/parol)', () {
    test("tarmoq xatosida LAN rejimiga o'tadi", () async {
      ApiService.sogMiSinovOverride =
          (manzil) async => manzil.startsWith('http://');
      String? xato;
      await http.runWithClient(() async {
        xato = await ApiService.foydalanuvchiParolOzgartir(5, 'yangiParol1');
      }, () => MockClient((req) async => throw Exception('tarmoq xatosi (sinov)')));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(ApiService.lanRejimi.value, isTrue);
      expect(xato, isNotNull);
    });
  });

  group('foydalanuvchiHolatiniOzgartir (PUT /users/{id}/holat)', () {
    test("tarmoq xatosida LAN rejimiga o'tadi", () async {
      ApiService.sogMiSinovOverride =
          (manzil) async => manzil.startsWith('http://');
      String? xato;
      await http.runWithClient(() async {
        xato = await ApiService.foydalanuvchiHolatiniOzgartir(5, false);
      }, () => MockClient((req) async => throw Exception('tarmoq xatosi (sinov)')));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(ApiService.lanRejimi.value, isTrue);
      expect(xato, isNotNull);
    });
  });

  group('adminHujjatTahrirlash (PUT /hujjatlar/{id})', () {
    late Map<String, String> soxtaSaqlash;

    setUp(() {
      soxtaSaqlash = {};
      OfflineQueueService.storageOqi = (key) => soxtaSaqlash[key];
      OfflineQueueService.storageYoz =
          (key, value) async => soxtaSaqlash[key] = value;
      OfflineQueueService.hammasiniTozalash();
      OfflineQueueService.bajaruvchilarniTozala();
    });

    test(
        "tarmoq xatosida LAN rejimiga o'tadi, `false` qaytaradi va offline "
        "navbatga qo'yadi (yo'qolmaydi)", () async {
      ApiService.sogMiSinovOverride =
          (manzil) async => manzil.startsWith('http://');
      bool? darholYuborildi;
      await http.runWithClient(() async {
        darholYuborildi =
            await ApiService.adminHujjatTahrirlash(42, {'shofyor': 'X'});
      }, () => MockClient((req) async => throw Exception('tarmoq xatosi (sinov)')));

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(ApiService.lanRejimi.value, isTrue);
      expect(darholYuborildi, isFalse);

      final navbatdagilar = OfflineQueueService.navbatdagilar();
      expect(navbatdagilar.length, 1);
      expect(navbatdagilar.first.turi, 'hujjat_yangilash');
      expect(navbatdagilar.first.malumot['hujjat_id'], 42);
    });

    test("muvaffaqiyatli bo'lsa `true` qaytaradi, navbatga qo'ymaydi",
        () async {
      bool? darholYuborildi;
      await http.runWithClient(() async {
        darholYuborildi =
            await ApiService.adminHujjatTahrirlash(42, {'shofyor': 'X'});
      }, () => MockClient((req) async => http.Response('{}', 200)));

      expect(darholYuborildi, isTrue);
      expect(OfflineQueueService.navbatdagilar(), isEmpty);
      expect(ApiService.lanRejimi.value, isFalse);
    });

    test(
        "server YETIB BORIB rad etsa (masalan 404) - ANIQ xato bilan "
        "chaqiruvchiga otiladi, JIMGINA offline navbatga QO'YILMAYDI, "
        "LAN rejimiga ham O'TMAYDI", () async {
      Object? xato;
      await http.runWithClient(() async {
        try {
          await ApiService.adminHujjatTahrirlash(999, {'shofyor': 'X'});
        } catch (e) {
          xato = e;
        }
      }, () => MockClient((req) async =>
          http.Response('{"detail": "Hujjat topilmadi"}', 404)));

      expect(xato, isNotNull);
      expect(xato.toString(), contains('Hujjat topilmadi'));
      expect(OfflineQueueService.navbatdagilar(), isEmpty,
          reason: "haqiqiy rad etish offline navbatga tushmasligi kerak");
      expect(ApiService.lanRejimi.value, isFalse,
          reason: "server yetib bordi, LAN'ga o'tmasligi kerak");
    });
  });
}
