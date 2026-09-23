// Bug: navbatTugallandiBajaruvchisi() va navbatBekorBajaruvchisi()
// POST /navbat/tugallandi va POST /navbat/bekor 404 qaytarganda ham
// _xatoOtish() orqali DOIMIY xato (OfflineServerXatosi) deb
// belgilardi. Lekin 404 aslida "navbat allaqachon topilmadi" degani -
// odatda bu amal ALLAQACHON muvaffaqiyatli bajarilgan (masalan avvalgi
// urinish serverga yetib borgan, javobi esa yo'qolgan/aloqa uzilgan)
// degan ma'noni bildiradi, doimiy rad etish emas.
//
// Tuzatish: 404 endi shu ikkala executor'da IDEMPOTENT MUVAFFAQIYAT
// sifatida qaraladi (xato emas).

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:frontend/services/offline_queue_executors.dart';
import 'package:frontend/services/offline_queue_service.dart';

void main() {
  setUp(() {
    OfflineQueueExecutors.baseUrlOluvchi = () => 'http://sinov.local';
    OfflineQueueExecutors.headerOluvchi = () => {'Content-Type': 'application/json'};
  });

  group('navbatTugallandiBajaruvchisi', () {
    test('404 - xato EMAS, idempotent muvaffaqiyat deb hisoblanadi', () async {
      await http.runWithClient(() async {
        final natija = await OfflineQueueExecutors.navbatTugallandiBajaruvchisi(
            {'hujjatId': 555});
        expect(natija, {'status': 'ok'});
      }, () => MockClient((req) async => http.Response(
          jsonEncode({'detail': 'Navbat topilmadi'}), 404)));
    });

    test('200 - odatdagidek serverdan qaytgan Map qaytariladi', () async {
      await http.runWithClient(() async {
        final natija = await OfflineQueueExecutors.navbatTugallandiBajaruvchisi(
            {'hujjatId': 555});
        expect(natija, {'hujjatId': 555, 'holat': 'tugallandi'});
      }, () => MockClient((req) async => http.Response(
          jsonEncode({'hujjatId': 555, 'holat': 'tugallandi'}), 200)));
    });

    test('409 - boshqa xato kodlari hamon DOIMIY xato deb belgilanadi', () async {
      await http.runWithClient(() async {
        await expectLater(
          OfflineQueueExecutors.navbatTugallandiBajaruvchisi({'hujjatId': 555}),
          throwsA(isA<OfflineServerXatosi>()),
        );
      }, () => MockClient((req) async => http.Response('{}', 409)));
    });

    test('401 - hamon qayta uriniladigan (OfflineTarmoqXatosi) deb qoladi', () async {
      await http.runWithClient(() async {
        await expectLater(
          OfflineQueueExecutors.navbatTugallandiBajaruvchisi({'hujjatId': 555}),
          throwsA(isA<OfflineTarmoqXatosi>()),
        );
      }, () => MockClient((req) async => http.Response('{}', 401)));
    });
  });

  group('navbatBekorBajaruvchisi', () {
    test('404 - xato EMAS, idempotent muvaffaqiyat deb hisoblanadi', () async {
      await http.runWithClient(() async {
        final natija = await OfflineQueueExecutors.navbatBekorBajaruvchisi(
            {'hujjatId': 555});
        expect(natija, {'status': 'ok'});
      }, () => MockClient((req) async => http.Response(
          jsonEncode({'detail': 'Navbat topilmadi'}), 404)));
    });

    test('200 - odatdagidek muvaffaqiyat qaytariladi', () async {
      await http.runWithClient(() async {
        final natija = await OfflineQueueExecutors.navbatBekorBajaruvchisi(
            {'hujjatId': 555});
        expect(natija, {'status': 'ok'});
      }, () => MockClient((req) async => http.Response('{}', 200)));
    });

    test('500 - boshqa xato kodlari hamon DOIMIY xato deb belgilanadi', () async {
      await http.runWithClient(() async {
        await expectLater(
          OfflineQueueExecutors.navbatBekorBajaruvchisi({'hujjatId': 555}),
          throwsA(isA<OfflineServerXatosi>()),
        );
      }, () => MockClient((req) async => http.Response('{}', 500)));
    });
  });
}
