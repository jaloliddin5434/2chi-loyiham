import 'dart:convert';
import 'dart:html' as html;

class OfflineService {
  static void _saqlash(String key, dynamic data) {
    try {
      html.window.localStorage[key] = jsonEncode(data);
      print('✅ Saqlandi: $key');
    } catch (e) {
      print('❌ Saqlash xato: $e');
    }
  }

static dynamic _olish(String key) {
    final data = html.window.localStorage[key];
   print('📖 O\'qildi: $key = ${data != null ? data.substring(0, data.length < 50 ? data.length : 50) : null}');
    if (data == null) return null;
    return jsonDecode(data);
  }

  static Future<bool> internetBormi() async {
    return html.window.navigator.onLine ?? true;
  }

  static Future<void> mahsulotlarSaqla(List<dynamic> mahsulotlar) async {
    _saqlash('mahsulotlar', mahsulotlar);
  }

  static Future<List<dynamic>> mahsulotlarOl() async {
    return (_olish('mahsulotlar') as List?)?.cast<dynamic>() ?? [];
  }

  static Future<void> navbatSaqla(List<dynamic> navbat) async {
    _saqlash('navbat', navbat);
  }

  static Future<List<dynamic>> navbatOl() async {
    return (_olish('navbat') as List?)?.cast<dynamic>() ?? [];
  }

  static Future<void> operatsiyaQosh(Map<String, dynamic> operatsiya) async {
    final list = (_olish('kutayotgan') as List?)?.cast<dynamic>() ?? [];
    list.add(operatsiya);
    _saqlash('kutayotgan', list);
  }

  static Future<List<dynamic>> kutayotganlarOl() async {
    return (_olish('kutayotgan') as List?)?.cast<dynamic>() ?? [];
  }

  static Future<void> tugallanganlarSaqla(List<dynamic> tugallanganlar) async {
    _saqlash('tugallanganlar', tugallanganlar);
  }

  static Future<List<dynamic>> tugallanganlarOl() async {
    return (_olish('tugallanganlar') as List?)?.cast<dynamic>() ?? [];
  }

  static Future<void> kutayotganlarTozala() async {
    html.window.localStorage.remove('kutayotgan');
  }
}