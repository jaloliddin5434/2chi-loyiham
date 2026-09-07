// Offline "Chop etish": internet yo'q bo'lganda Nakladnoy ekrandagi
// ma'lumotlardan to'g'ridan-to'g'ri HTML yasab, brauzer print oynasida
// chop etadi (server so'rovi va PDF baytlarisiz). Server navbati (arxiv
// uchun) baribir saqlanadi - internet kelganda hozirgidek PDF yasaladi.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/screens/nakladnoy_screen.dart';
import 'package:frontend/services/offline_service.dart';

NakladnoyScreen _ekran({int? hujjatId}) => NakladnoyScreen(
      mashinaRaqami: '01A777AA',
      mashinaTuri: 'FAW',
      shofyor: 'Aliyev A',
      firma: 'Test Firma MChJ',
      mahsulotNomi: 'Chigit',
      aravalarSoni: 1,
      tara1: 12000,
      brutto1: 30000,
      konditsion1: 17500,
      hujjatId: hujjatId,
      tiketRaqam: '1112223',
      tudaRaqam: '77',
      klass: '2',
      seleksiyaNavi: 'Xorazm-150',
      hujjatRaqam: 'CHG-2026/042',
      namlik: 8.5,
      ifloslik: 2.0,
      dostaverka: 'D-500',
      dostaverkaVaqt: '10.04.2026 - 30.06.2026',
      sana: '2026-09-07',
    );

void main() {
  // ---------- Unit: HTML yasash ----------
  group('nakladnoyChopHtml', () {
    test("asosiy maydonlar, JAMI/netto va 3 nusxa bo'ladi", () {
      final h = nakladnoyChopHtml(_ekran());

      expect(h, contains('<!DOCTYPE html>'));
      expect(h, contains('Test Firma MChJ'));
      expect(h, contains('CHG-2026/042'));
      expect(h, contains('1112223')); // tiket
      expect(h, contains('Xorazm-150'));
      expect(h, contains('12000')); // tara
      expect(h, contains('30000')); // brutto
      expect(h, contains('18000')); // netto = 30000 - 12000
      expect(h, contains('D-500')); // dostaverna
      expect(h, contains('ЗАВОД НУСХАСИ'));
      expect(h, contains('ШОФЁР НУСХАСИ'));
      expect(h, contains('ОХРАНА НУСХАСИ'));
      // 3 nusxa -> 2 ta sahifa uzilishi (1-nusxa uzilishsiz)
      expect('page-break-before'.allMatches(h).length, 2);
    });

    test("bo'sh maydonlar '—', HTML injeksiyasi ekranlanadi", () {
      final h = nakladnoyChopHtml(const NakladnoyScreen(
        mashinaRaqami: '01A',
        mashinaTuri: 'FAW',
        shofyor: '',
        firma: 'A & B <script>',
        mahsulotNomi: 'Chigit',
        aravalarSoni: 1,
      ));
      expect(h, contains('A &amp; B &lt;script&gt;'));
      expect(h, isNot(contains('B <script>')));
      expect(h, contains('—')); // bo'sh shofyor/tiket/... uchun
    });
  });

  // ---------- Widget: offline chop etish ----------
  group('offline "Chop etish"', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      NakladnoyScreen.chopEtishOverride = null;
    });
    tearDown(() => NakladnoyScreen.chopEtishOverride = null);

    testWidgets("mahalliy (sinxronlanmagan) hujjat - HTML chop etiladi, HTTP yo'q",
        (tester) async {
      tester.view.physicalSize = const Size(1500, 1100);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      String? chopEtilgan;
      NakladnoyScreen.chopEtishOverride = (h) => chopEtilgan = h;

      await tester.pumpWidget(MaterialApp(home: _ekran(hujjatId: -5)));
      await tester.pump();

      await tester.tap(find.text('Chop etish'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(chopEtilgan, isNotNull);
      expect(chopEtilgan, contains('CHG-2026/042'));
      expect(find.textContaining('Offline chop etildi'), findsOneWidget);
    });

    testWidgets(
        "internet yo'q (tarmoq xatosi) - HTML chop etiladi + server navbatiga saqlanadi",
        (tester) async {
      tester.view.physicalSize = const Size(1500, 1100);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      String? chopEtilgan;
      NakladnoyScreen.chopEtishOverride = (h) => chopEtilgan = h;

      await http.runWithClient(() async {
        await tester.pumpWidget(MaterialApp(home: _ekran(hujjatId: 42)));
        await tester.pump();
        await tester.tap(find.text('Chop etish'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
      }, () => MockClient((req) async => throw http.ClientException('offline')));

      expect(chopEtilgan, isNotNull, reason: 'offline HTML chop etilishi kerak');
      expect(find.textContaining('Offline chop etildi'), findsOneWidget);
      // Arxiv uchun server navbatiga qo'yilgan (hozirgi sync xatti-harakati)
      expect(await OfflineService.nakladnoylarOl(), hasLength(1));
    });

    testWidgets(
        "ONLINE - hozirgi xatti-harakat: server POST bo'ladi, offline chop YO'Q",
        (tester) async {
      tester.view.physicalSize = const Size(1500, 1100);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      String? chopEtilgan;
      NakladnoyScreen.chopEtishOverride = (h) => chopEtilgan = h;
      final sorovlar = <String>[];

      await http.runWithClient(() async {
        await tester.pumpWidget(MaterialApp(home: _ekran(hujjatId: 42)));
        await tester.pump();
        await tester.tap(find.text('Chop etish'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
      }, () => MockClient((req) async {
        sorovlar.add('${req.method} ${req.url.path}');
        return http.Response.bytes([37, 80, 68, 70], 200); // "%PDF" soxta baytlar
      }));

      expect(sorovlar, contains('POST /nakladnoy/saqlash'));
      expect(chopEtilgan, isNull,
          reason: "online'da offline HTML chop etilmasligi kerak");
      expect(find.textContaining('Offline'), findsNothing);
      expect(await OfflineService.nakladnoylarOl(), isEmpty,
          reason: "online muvaffaqiyat -> server navbatiga qo'yilmaydi");
    });
  });
}
