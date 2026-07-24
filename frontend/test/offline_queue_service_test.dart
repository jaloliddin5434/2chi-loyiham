// Offline yozish navbati mexanizmining sof mantiq testlari.
// Bu fayl atayin brauzersiz (dart:html'siz) ishlaydi - shuning uchun
// oddiy `flutter test` bilan tekshiriladi, real ekran yoki backend
// kerak emas. Saqlash zaxirasi (storageOqi/storageYoz) shu yerda
// oddiy Map bilan simulyatsiya qilinadi.

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/offline_queue_service.dart';

void main() {
  // Har bir testdan oldin "localStorage"ni Map bilan simulyatsiya
  // qilamiz va navbatni tozalaymiz - testlar bir-biriga ta'sir
  // qilmasligi uchun.
  late Map<String, String> soxtaSaqlash;

  setUp(() {
    soxtaSaqlash = {};
    OfflineQueueService.storageOqi = (key) => soxtaSaqlash[key];
    OfflineQueueService.storageYoz = (key, value) => soxtaSaqlash[key] = value;
    OfflineQueueService.hammasiniTozalash();
    OfflineQueueService.bajaruvchilarniTozala();
  });

  test('navbat bosh holatda sinxronlash hech narsa qilmaydi', () async {
    final natija = await OfflineQueueService.sinxronlash();
    expect(natija.muvaffaqiyatli, 0);
    expect(natija.xato, 0);
    expect(natija.tarmoqYoq, false);
  });

  test('amallar YARATILGAN VAQTI boyicha ketma-ket ishlanadi, qoshilish tartibida emas', () async {
    final bajarilishTartibi = <String>[];
    OfflineQueueService.turiniRoyxatgaOl('test_amal', (malumot) async {
      bajarilishTartibi.add(malumot['belgi'] as String);
      return {'status': 'ok'};
    });

    // Ataylab teskari tartibda qoshamiz (C, keyin A, keyin B) - lekin
    // vaqt tamgalari A < B < C bolishi kerak.
    await OfflineQueueService.qoshish('test_amal', {'belgi': 'C'}, vaqt: 300);
    await OfflineQueueService.qoshish('test_amal', {'belgi': 'A'}, vaqt: 100);
    await OfflineQueueService.qoshish('test_amal', {'belgi': 'B'}, vaqt: 200);

    final natija = await OfflineQueueService.sinxronlash();

    expect(natija.muvaffaqiyatli, 3);
    expect(bajarilishTartibi, ['A', 'B', 'C']);
  });

  test('mahalliy kalit haqiqiy ID bilan togri almashtiriladi (mashina -> hujjat zanjiri)', () async {
    Map<String, dynamic>? hujjatGaYetibKelganMalumot;

    OfflineQueueService.turiniRoyxatgaOl('mashina_yaratish', (malumot) async {
      return {'id': 42, 'davlat_raqami': malumot['davlat_raqami']};
    });
    OfflineQueueService.turiniRoyxatgaOl('hujjat_yaratish', (malumot) async {
      hujjatGaYetibKelganMalumot = malumot;
      return {'id': 777, 'raqam': 'CHG-2026/005'};
    });

    final mashinaKaliti = OfflineQueueService.yangiMahalliyKalit();
    await OfflineQueueService.qoshish(
      'mashina_yaratish',
      {'davlat_raqami': '01 A 777 AA'},
      yaratadiganKalit: mashinaKaliti,
      vaqt: 100,
    );
    await OfflineQueueService.qoshish(
      'hujjat_yaratish',
      {'mashina_id': mashinaKaliti, 'mahsulot_id': 1},
      vaqt: 200,
    );

    final natija = await OfflineQueueService.sinxronlash();

    expect(natija.muvaffaqiyatli, 2);
    expect(natija.xato, 0);
    // Hujjat yaratish bajaruvchisiga mahalliy kalit EMAS, balki
    // mashinaning haqiqiy ID'si (42) yetib kelishi kerak.
    expect(hujjatGaYetibKelganMalumot, isNotNull);
    expect(hujjatGaYetibKelganMalumot!['mashina_id'], 42);
    expect(hujjatGaYetibKelganMalumot!['mahsulot_id'], 1);
  });

  test('ota amal server tomonidan rad etilsa, unga bogliq farzand amal chaqirilmasdan bloklanadi', () async {
    var hujjatBajaruvchisiChaqirildimi = false;

    OfflineQueueService.turiniRoyxatgaOl('mashina_yaratish', (malumot) async {
      throw OfflineServerXatosi("Validatsiya xatosi", 422);
    });
    OfflineQueueService.turiniRoyxatgaOl('hujjat_yaratish', (malumot) async {
      hujjatBajaruvchisiChaqirildimi = true;
      return {'id': 777};
    });

    final mashinaKaliti = OfflineQueueService.yangiMahalliyKalit();
    await OfflineQueueService.qoshish(
      'mashina_yaratish',
      {'davlat_raqami': "notogri"},
      yaratadiganKalit: mashinaKaliti,
      vaqt: 100,
    );
    await OfflineQueueService.qoshish(
      'hujjat_yaratish',
      {'mashina_id': mashinaKaliti},
      vaqt: 200,
    );

    final natija = await OfflineQueueService.sinxronlash();

    expect(natija.muvaffaqiyatli, 0);
    expect(natija.xato, 2); // ikkalasi ham xato - ota rad etilgan, farzand bloklangan
    expect(hujjatBajaruvchisiChaqirildimi, false);

    final xatoliklar = OfflineQueueService.xatoliklar();
    expect(xatoliklar.length, 2);
    expect(xatoliklar.any((o) => o.turi == 'mashina_yaratish' && o.oxirgiXato == "Validatsiya xatosi"), true);
    expect(
      xatoliklar.any((o) =>
          o.turi == 'hujjat_yaratish' &&
          o.oxirgiXato == "Bog'liq yozuv hali sinxronlanmagan yoki muvaffaqiyatsiz bo'lgan"),
      true,
    );
  });

  test('tarmoq xatosida qolgan navbat tegilmay saqlanadi, keyingi siklga qoladi', () async {
    var ikkinchiAmalChaqirildimi = false;

    OfflineQueueService.turiniRoyxatgaOl('birinchi', (malumot) async {
      throw OfflineTarmoqXatosi("Server javob bermadi");
    });
    OfflineQueueService.turiniRoyxatgaOl('ikkinchi', (malumot) async {
      ikkinchiAmalChaqirildimi = true;
      return {'id': 1};
    });

    await OfflineQueueService.qoshish('birinchi', {'a': 1}, vaqt: 100);
    await OfflineQueueService.qoshish('ikkinchi', {'b': 2}, vaqt: 200);

    final natija = await OfflineQueueService.sinxronlash();

    expect(natija.tarmoqYoq, true);
    expect(natija.muvaffaqiyatli, 0);
    expect(ikkinchiAmalChaqirildimi, false);

    // Ikkalasi ham hali "navbatda" holatida qolishi kerak.
    final navbatdagilar = OfflineQueueService.navbatdagilar();
    expect(navbatdagilar.length, 2);
    expect(navbatdagilar.firstWhere((o) => o.turi == 'birinchi').urinishSoni, 1);
  });

  test('tarmoq tiklangach, saqlanib qolgan navbat togri sinxronlanadi (ikkinchi sikl)', () async {
    var tarmoqBormi = false;
    OfflineQueueService.turiniRoyxatgaOl('amal', (malumot) async {
      if (!tarmoqBormi) throw OfflineTarmoqXatosi("Server javob bermadi");
      return {'id': malumot['raqam']};
    });

    await OfflineQueueService.qoshish('amal', {'raqam': 1}, vaqt: 100);
    await OfflineQueueService.qoshish('amal', {'raqam': 2}, vaqt: 200);

    final birinchiSikl = await OfflineQueueService.sinxronlash();
    expect(birinchiSikl.tarmoqYoq, true);
    expect(birinchiSikl.muvaffaqiyatli, 0);

    // Tarmoq tiklandi.
    tarmoqBormi = true;
    final ikkinchiSikl = await OfflineQueueService.sinxronlash();
    expect(ikkinchiSikl.tarmoqYoq, false);
    expect(ikkinchiSikl.muvaffaqiyatli, 2);
    expect(OfflineQueueService.navbatdagilar().length, 0);
  });

  test('muvaffaqiyatli amallar navbatdan olib tashlanadi, qayta ishga tushirishda qayta bajarilmaydi', () async {
    var chaqirilganSoni = 0;
    OfflineQueueService.turiniRoyxatgaOl('amal', (malumot) async {
      chaqirilganSoni++;
      return {'id': 1};
    });

    await OfflineQueueService.qoshish('amal', {'a': 1}, vaqt: 100);
    final birinchi = await OfflineQueueService.sinxronlash();
    final ikkinchi = await OfflineQueueService.sinxronlash();

    expect(birinchi.muvaffaqiyatli, 1);
    expect(ikkinchi.muvaffaqiyatli, 0);
    expect(chaqirilganSoni, 1);
  });

  test('saqlash/oqish JSON orqali togri aylanadi (sahifa qayta yuklanishini simulyatsiya)', () async {
    OfflineQueueService.turiniRoyxatgaOl('amal', (malumot) async => {'id': 9});

    await OfflineQueueService.qoshish('amal', {'matn': "o'zbekcha belgilar", 'son': 3.14},
        yaratadiganKalit: 'OFFLINE-test-1', vaqt: 555);

    // "Sahifa qayta yuklandi" - lekin soxtaSaqlash Map'i (localStorage
    // ornini bosuvchi) saqlanib qoladi, xuddi haqiqiy localStorage kabi.
    final navbatdagilar = OfflineQueueService.navbatdagilar();
    expect(navbatdagilar.length, 1);
    expect(navbatdagilar.first.malumot['matn'], "o'zbekcha belgilar");
    expect(navbatdagilar.first.malumot['son'], 3.14);
    expect(navbatdagilar.first.yaratadiganKalit, 'OFFLINE-test-1');
    expect(navbatdagilar.first.vaqt, 555);
  });

  test('nomalum amal turi xato deb belgilanadi, dastur qotib qolmaydi', () async {
    await OfflineQueueService.qoshish('royxatga_olinmagan_tur', {'a': 1}, vaqt: 100);
    final natija = await OfflineQueueService.sinxronlash();
    expect(natija.xato, 1);
    expect(OfflineQueueService.xatoliklar().first.oxirgiXato, contains('amal turi'));
  });

  test("amal o'z YARATADIGAN kalitini o'z malumotida yuborsa (masalan mijoz_kaliti), bloklanib qolmaydi", () async {
    // Hujjat yaratishda idempotentlik uchun backendga o'zining mahalliy
    // kalitini "mijoz_kaliti" sifatida ATAYLAB yuboramiz. Bu boshqa
    // amalga BOG'LIQLIK EMAS - resolver buni notogri "hali sinxronlanmagan
    // boglanish" deb hisoblab, cheksiz bloklab qoymasligi kerak.
    Map<String, dynamic>? bajaruvchigaYetibKelganMalumot;
    OfflineQueueService.turiniRoyxatgaOl('hujjat_yaratish', (malumot) async {
      bajaruvchigaYetibKelganMalumot = malumot;
      return {'id': 555};
    });

    final ozKaliti = OfflineQueueService.yangiMahalliyKalit();
    await OfflineQueueService.qoshish(
      'hujjat_yaratish',
      {'mahsulot_id': 1, 'mijoz_kaliti': ozKaliti},
      yaratadiganKalit: ozKaliti,
      vaqt: 100,
    );

    final natija = await OfflineQueueService.sinxronlash();

    expect(natija.muvaffaqiyatli, 1);
    expect(natija.xato, 0);
    expect(bajaruvchigaYetibKelganMalumot, isNotNull);
    // mijoz_kaliti resolvatsiya qilinmasdan, ozgarishsiz yuborilishi kerak.
    expect(bajaruvchigaYetibKelganMalumot!['mijoz_kaliti'], ozKaliti);
  });

  test('xatoniOchirish faqat xato holatidagi yozuvni olib tashlaydi', () async {
    OfflineQueueService.turiniRoyxatgaOl('amal', (malumot) async {
      throw OfflineServerXatosi("rad etildi");
    });
    await OfflineQueueService.qoshish('amal', {'a': 1}, vaqt: 100);
    await OfflineQueueService.sinxronlash();

    expect(OfflineQueueService.xatoliklar().length, 1);
    final opId = OfflineQueueService.xatoliklar().first.opId;
    OfflineQueueService.xatoniOchirish(opId);
    expect(OfflineQueueService.xatoliklar().length, 0);
  });

  test('REPRO: sinxronlash ishlab turganda qoshilgan yangi amal yoqolmasligi kerak', () async {
    // sinxronlash() birinchi amalni bajarishga urinib, "osilib qoladi"
    // (hali tarmoq javobini kutmoqda) - shu payt UI tomonidan yangi amal
    // navbatga qoshiladi. sinxronlash() keyinroq (tarmoq xatosi bilan)
    // davom etganda, navbatni saqlashda yangi qoshilgan amalni
    // O'CHIRIB YUBORMASLIGI kerak.
    final tugadiComp = Completer<void>();
    OfflineQueueService.turiniRoyxatgaOl('sekin_amal', (malumot) async {
      await tugadiComp.future; // sinxronlash shu yerda "osilib" turadi
      throw OfflineTarmoqXatosi("tarmoq yoq");
    });
    OfflineQueueService.turiniRoyxatgaOl('tez_amal', (malumot) async {
      return {'status': 'ok'};
    });

    await OfflineQueueService.qoshish('sekin_amal', {'a': 1}, vaqt: 100);

    final sinxronlashFuture = OfflineQueueService.sinxronlash();
    // sinxronlash() endi 'sekin_amal'ni bajarishga kirib, Completer
    // hal bo'lishini kutib "osilib" turibdi.

    await OfflineQueueService.qoshish('tez_amal', {'b': 2}, vaqt: 200);
    // Shu payt navbatda: [sekin_amal(navbatda), tez_amal(navbatda)]
    // localStorage'da ikkalasi ham yozilgan bo'lishi kerak.

    tugadiComp.complete();
    await sinxronlashFuture;

    // sinxronlash 'sekin_amal'ni tarmoq xatosi bilan tugatib, darhol
    // qaytdi (qolganlarini keyingi siklga qoldirib). 'tez_amal' hali
    // navbatda turishi SHART - yo'qolmasligi kerak.
    final qolganlar = OfflineQueueService.navbatdagilar();
    expect(qolganlar.any((o) => o.turi == 'tez_amal'), true,
        reason: "'tez_amal' sinxronlash bilan poyga (race)da yoqolib qoldi - navbat: ${qolganlar.map((o) => o.turi).toList()}");
  });
}
