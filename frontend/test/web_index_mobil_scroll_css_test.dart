// Bug: iPhone Chrome (WebKit) va Android'da operator/admin panelida
// pastga scroll qilingach, yuqoriga qayta scroll ishlamasdi. Sabab -
// web/index.html'da html/body uchun overscroll-behavior "auto" edi:
// barmoq PASTGA surilganda (yuqoriga scroll) brauzer imo-ishorani
// pull-to-refresh (Android) / elastik bounce (iOS) sifatida o'zi ushlab,
// Flutter'ga pointercancel yuborardi.
//
// Bu CSS Flutter widget testlarida ko'rinmaydi (index.html faqat
// brauzerda yuklanadi), shu sabab fayl matni to'g'ridan-to'g'ri
// tekshiriladi - kimdir index.html'ni qayta generatsiya qilsa (masalan
// `flutter create .`) sozlama jimgina yo'qolmasin.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final html = File('web/index.html').readAsStringSync();

  String htmlBodyQoidasi() {
    final m = RegExp(r'html\s*,\s*body\s*\{([^}]*)\}').firstMatch(html);
    expect(m, isNotNull,
        reason: 'index.html <style> ichida "html, body { ... }" qoidasi yo\'q');
    return m!.group(1)!;
  }

  test('html, body: overscroll-behavior none (pull-to-refresh/bounce o\'chiq)',
      () {
    expect(htmlBodyQoidasi(),
        matches(RegExp(r'overscroll-behavior\s*:\s*none\s*;')));
  });

  test('html, body: touch-action none va overflow hidden', () {
    final qoida = htmlBodyQoidasi();
    expect(qoida, matches(RegExp(r'touch-action\s*:\s*none\s*;')));
    expect(qoida, matches(RegExp(r'overflow\s*:\s*hidden\s*;')));
  });

  test('qoida <head> ichidagi <style> da - Flutter yuklanishidan oldin', () {
    final head = html.substring(0, html.indexOf('</head>'));
    expect(head, contains('<style>'));
    expect(head, contains('overscroll-behavior: none'));
  });
}
