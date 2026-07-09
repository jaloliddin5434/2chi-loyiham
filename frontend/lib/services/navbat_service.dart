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