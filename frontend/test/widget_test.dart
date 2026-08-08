// Ilova asosiy ekrani (mahsulot tanlash) to'g'ri yuklanishini tekshiradi -
// hatto tarmoq/backend mavjud bo'lmagan holatda ham (flutter test
// muhitida haqiqiy HTTP so'rovlar hech qachon serverga yetmaydi).
// ApiService.getMahsulotlar() bunday holatda o'zining ichki standart
// mahsulotlar ro'yxatini qaytaradi - shu sabab ekran baribir to'liq,
// brendlangan holatda ochilishi kerak.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/main.dart';

void main() {
  testWidgets('Mahsulot tanlash ekrani tarmoqsiz holatda ham togri ochiladi',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyApp());

    // Birinchi frame'da yuklanish indikatori korinishi kerak.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('Hazorasp Tekstil'), findsOneWidget);
    expect(find.text('SMART TAROZI'), findsOneWidget);
    expect(find.text('Mahsulot turini tanlang'), findsOneWidget);
    expect(find.text('Chigit'), findsOneWidget);
    expect(find.text('BU_MATN_HECH_QACHON_TOPILMAYDI_CI_SINOVI'), findsOneWidget);
  });
}
