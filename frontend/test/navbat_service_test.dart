// NavbatService.navbatYangila() sof mantiq testi - admin panelda
// mashina ma'lumotlari o'zgartirilganda navbatdagi yozuv backenddan
// kelgan yangi nusxa bilan almashtirilishini tekshiradi.

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/navbat_service.dart';
import 'package:frontend/screens/operator_panel_screen.dart';

NavbatMashina _mashina({
  required int hujjatId,
  String firma = 'Firma A',
  String? klass = '1',
  double? namlik = 10.0,
}) {
  return NavbatMashina(
    raqam: '01A111AA',
    turi: 'ZIL',
    shofyor: 'Aliyev',
    firma: firma,
    vaqt: '08:00',
    mahsulotId: 1,
    mahsulotNomi: 'Paxta',
    aravalar: {},
    hujjatId: hujjatId,
    mashinaId: hujjatId,
    kelganVaqt: DateTime(2026, 9, 7, 8),
    klass: klass,
    namlik: namlik,
  );
}

void main() {
  setUp(() {
    NavbatService.tozala();
  });

  test('navbatYangila mavjud yozuvni hujjatId bo\'yicha almashtiradi', () {
    NavbatService.navbatQosh(_mashina(hujjatId: 5, firma: 'Eski', klass: '1'));
    NavbatService.navbatQosh(_mashina(hujjatId: 6, firma: 'Boshqa'));

    final yangi = _mashina(hujjatId: 5, firma: 'Yangi', klass: '2', namlik: 12.5);
    NavbatService.navbatYangila(yangi);

    final topilgan =
        NavbatService.navbat.value.firstWhere((m) => m.hujjatId == 5);
    expect(topilgan.firma, 'Yangi');
    expect(topilgan.klass, '2');
    expect(topilgan.namlik, 12.5);
    // Boshqa yozuvga tegilmagan.
    expect(
        NavbatService.navbat.value.firstWhere((m) => m.hujjatId == 6).firma,
        'Boshqa');
    // Ro'yxat uzunligi o'zgarmagan (dublikat qo'shilmagan).
    expect(NavbatService.navbat.value.length, 2);
  });

  test('navbatYangila topilmaydigan hujjatId uchun hech narsa qilmaydi', () {
    NavbatService.navbatQosh(_mashina(hujjatId: 5));
    final oldin = NavbatService.navbat.value;

    NavbatService.navbatYangila(_mashina(hujjatId: 999, firma: 'Yo\'q'));

    expect(NavbatService.navbat.value.length, 1);
    expect(NavbatService.navbat.value.first.hujjatId, 5);
    // Yangi ro'yxat obyekti yaratilmagan (keraksiz notify bo'lmagan).
    expect(identical(NavbatService.navbat.value, oldin), true);
  });

  test('navbatYangila yangi ro\'yxat obyekti bilan listenerlarni ogohlantiradi',
      () {
    NavbatService.navbatQosh(_mashina(hujjatId: 5, firma: 'Eski'));
    var xabar = 0;
    void tinglovchi() => xabar++;
    NavbatService.navbat.addListener(tinglovchi);

    NavbatService.navbatYangila(_mashina(hujjatId: 5, firma: 'Yangi'));

    NavbatService.navbat.removeListener(tinglovchi);
    expect(xabar, 1);
  });
}
