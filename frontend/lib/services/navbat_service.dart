import 'package:flutter/material.dart';
import '../screens/operator_panel_screen.dart';

class NavbatService {
  // Navbatdagi mashinalar
  static final ValueNotifier<List<NavbatMashina>> navbat =
      ValueNotifier([]);

  // Tugallangan mashinalar
  static final ValueNotifier<List<NavbatMashina>> tugallanganlar =
      ValueNotifier([]);

  // Mahsulot bo'yicha navbat
  static List<NavbatMashina> navbatByMahsulot(int mahsulotId) {
    return navbat.value
        .where((m) => m.mahsulotId == mahsulotId)
        .toList();
  }

  // Mahsulot bo'yicha tugallanganlar
  static List<NavbatMashina> tugallanganlarByMahsulot(int mahsulotId) {
    return tugallanganlar.value
        .where((m) => m.mahsulotId == mahsulotId)
        .toList();
  }

  // Navbatga qo'shish
  static void navbatQosh(NavbatMashina mashina) {
    navbat.value = [...navbat.value, mashina];
  }

  // Navbatdan o'chirish + tugallanganlaraga qo'shish
  static void tugallandiQosh(NavbatMashina mashina) {
    navbat.value = navbat.value
        .where((m) => m.hujjatId != mashina.hujjatId)
        .toList();
    tugallanganlar.value = [mashina, ...tugallanganlar.value];
  }

  // Navbatdagi mavjud yozuvni backenddan kelgan yangi ma'lumot bilan
  // almashtirish (admin panelda firma, klass, sinf, namlik, ifloslik,
  // dostaverka va h.k. o'zgartirilganda). hujjatId bo'yicha topiladi;
  // topilmasa hech narsa qilinmaydi.
  static void navbatYangila(NavbatMashina yangi) {
    final royxat = navbat.value;
    final idx = royxat.indexWhere(
        (m) => m.hujjatId == yangi.hujjatId);
    if (idx < 0) return;
    final nusxa = [...royxat];
    nusxa[idx] = yangi;
    navbat.value = nusxa;
  }

  // Navbatdan o'chirish (bekor qilish)
  static void navbatdanOchir(int hujjatId) {
    navbat.value = navbat.value
        .where((m) => m.hujjatId != hujjatId)
        .toList();
  }

  // Hammasini tozalash
  static void tozala() {
    navbat.value = [];
    tugallanganlar.value = [];
  }
}