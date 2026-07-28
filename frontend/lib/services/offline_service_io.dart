import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineService {
  static Future<void> _saqlash(String key, dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(data));
      print('✅ Saqlandi: $key');
    } catch (e) {
      print('❌ Saqlash xato: $e');
    }
  }

  static Future<dynamic> _olish(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(key);
    print('📖 O\'qildi: $key = ${data != null ? data.substring(0, data.length < 50 ? data.length : 50) : null}');
    if (data == null) return null;
    return jsonDecode(data);
  }

  static Future<bool> internetBormi() async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  static Future<void> mahsulotlarSaqla(List<dynamic> mahsulotlar) async {
    await _saqlash('mahsulotlar', mahsulotlar);
  }

  static Future<List<dynamic>> mahsulotlarOl() async {
    return ((await _olish('mahsulotlar')) as List?)?.cast<dynamic>() ?? [];
  }

  static Future<void> navbatSaqla(List<dynamic> navbat) async {
    await _saqlash('navbat', navbat);
  }

  static Future<List<dynamic>> navbatOl() async {
    return ((await _olish('navbat')) as List?)?.cast<dynamic>() ?? [];
  }

  static Future<void> operatsiyaQosh(Map<String, dynamic> operatsiya) async {
    final list = ((await _olish('kutayotgan')) as List?)?.cast<dynamic>() ?? [];
    list.add(operatsiya);
    await _saqlash('kutayotgan', list);
  }

  static Future<List<dynamic>> kutayotganlarOl() async {
    return ((await _olish('kutayotgan')) as List?)?.cast<dynamic>() ?? [];
  }

  static Future<void> tugallanganlarSaqla(List<dynamic> tugallanganlar) async {
    await _saqlash('tugallanganlar', tugallanganlar);
  }

  static Future<List<dynamic>> tugallanganlarOl() async {
    return ((await _olish('tugallanganlar')) as List?)?.cast<dynamic>() ?? [];
  }

  static Future<void> kutayotganlarTozala() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('kutayotgan');
  }

  static Future<void> nakladnoyQosh(Map<String, dynamic> nakladnoy) async {
    final list = ((await _olish('kutayotgan_nakladnoy')) as List?)?.cast<dynamic>() ?? [];
    list.add(nakladnoy);
    await _saqlash('kutayotgan_nakladnoy', list);
  }

  static Future<List<dynamic>> nakladnoylarOl() async {
    return ((await _olish('kutayotgan_nakladnoy')) as List?)?.cast<dynamic>() ?? [];
  }

  static Future<void> nakladnoylarSaqla(List<dynamic> nakladnoylar) async {
    await _saqlash('kutayotgan_nakladnoy', nakladnoylar);
  }

  static Future<void> nakladnoylarTozala() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('kutayotgan_nakladnoy');
  }

  static Future<void> rasmQosh(Map<String, dynamic> rasm) async {
    final list = ((await _olish('kutayotgan_rasmlar')) as List?)?.cast<dynamic>() ?? [];
    list.add(rasm);
    await _saqlash('kutayotgan_rasmlar', list);
  }

  static Future<List<dynamic>> rasmlarOl() async {
    return ((await _olish('kutayotgan_rasmlar')) as List?)?.cast<dynamic>() ?? [];
  }

  static Future<void> rasmlarSaqla(List<dynamic> rasmlar) async {
    await _saqlash('kutayotgan_rasmlar', rasmlar);
  }

  static Future<void> rasmlarTozala() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('kutayotgan_rasmlar');
  }
}
