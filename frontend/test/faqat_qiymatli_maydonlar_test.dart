// faqatQiymatliMaydonlar(): brutto yakunlanganda hujjatYangilash chaqiruvi
// oldidan payloaddan bo'sh string/null qiymatli maydonlarni chiqarib
// tashlaydi - aks holda backend PUT /hujjatlar/{id} `exclude_unset=True`
// mantiqi bo'sh stringni "ataylab bo'shatildi" deb qabul qilib, bazadagi
// mavjud qiymatni o'chirib yuborardi.

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/screens/operator_panel_screen.dart';

void main() {
  group('faqatQiymatliMaydonlar', () {
    test('bo\'sh string qiymatli maydonlarni chiqarib tashlaydi', () {
      final natija = faqatQiymatliMaydonlar({
        'firma': '',
        'shofyor': 'Aziz Shofyorov',
      });
      expect(natija.containsKey('firma'), isFalse);
      expect(natija['shofyor'], 'Aziz Shofyorov');
    });

    test('null qiymatli maydonlarni ham chiqarib tashlaydi', () {
      final natija = faqatQiymatliMaydonlar({
        'namlik': null,
        'ifloslik': 5.0,
      });
      expect(natija.containsKey('namlik'), isFalse);
      expect(natija['ifloslik'], 5.0);
    });

    test('haqiqiy qiymatli maydonlarni saqlaydi', () {
      final natija = faqatQiymatliMaydonlar({
        'firma': 'Hazorasp Tekstil',
        'tiket_raqam': 'T-001',
        'klass': '1',
        'sabab': 'Operator tomonidan yangilandi',
      });
      expect(natija, {
        'firma': 'Hazorasp Tekstil',
        'tiket_raqam': 'T-001',
        'klass': '1',
        'sabab': 'Operator tomonidan yangilandi',
      });
    });

    test('0 qiymatini bo\'sh deb hisoblamaydi (haqiqiy namlik/ifloslik=0)', () {
      final natija = faqatQiymatliMaydonlar({
        'namlik': 0.0,
        'ifloslik': 0.0,
      });
      expect(natija['namlik'], 0.0);
      expect(natija['ifloslik'], 0.0);
    });

    test('false qiymatini bo\'sh deb hisoblamaydi', () {
      final natija = faqatQiymatliMaydonlar({'tugallandi': false});
      expect(natija.containsKey('tugallandi'), isTrue);
      expect(natija['tugallandi'], false);
    });

    test('faqat bo\'sh/null maydonlar bo\'lsa - bo\'sh Map qaytaradi', () {
      final natija = faqatQiymatliMaydonlar({
        'firma': '',
        'shofyor': '',
        'namlik': null,
      });
      expect(natija, isEmpty);
    });

    test('aralash holat: brutto yakuni payloadidagi haqiqiy stsenariy', () {
      // Operator faqat firma/shofyorni to'ldirgan, qolganini bo'sh
      // qoldirgan (masalan konditsiyasiz mahsulot - klass/sinf/seleksiya
      // yo'q, yoki hali kiritilmagan) - shu holatda ular umuman
      // yuborilmasligi kerak.
      final natija = faqatQiymatliMaydonlar({
        'firma': 'Real Firma',
        'shofyor': 'Real Shofyor',
        'tiket_raqam': '',
        'tuda_raqam': '',
        'klass': '',
        'sinf': '',
        'namlik': null,
        'ifloslik': null,
        'seleksiya_navi': '',
        'qabul_qildi': '',
        'yuk_olindi': '',
        'dostaverka': '',
        'dostaverka_vaqt': '',
        'sabab': 'Operator tomonidan yangilandi',
      });
      expect(natija, {
        'firma': 'Real Firma',
        'shofyor': 'Real Shofyor',
        'sabab': 'Operator tomonidan yangilandi',
      });
    });

    test('asl Map o\'zgartirilmaydi (yangi Map qaytariladi)', () {
      final asl = {'firma': '', 'shofyor': 'Aziz'};
      final natija = faqatQiymatliMaydonlar(asl);
      expect(asl.containsKey('firma'), isTrue,
          reason: 'chaqiruvchi tomonidagi asl Map o\'zgarmasligi kerak');
      expect(natija.containsKey('firma'), isFalse);
    });
  });
}
