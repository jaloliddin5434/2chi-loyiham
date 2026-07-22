import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'offline_service.dart';

class ApiService {
static const String baseUrl = "http://10.112.30.77:8001";
  static String? _token;
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static Map<String, String> _headers() {
    final headers = {'Content-Type': 'application/json'};
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // Boshqa fayllardagi to'g'ridan-to'g'ri http.get()/http.post() chaqiruvlari
  // uchun (masalan admin_panel_screen.dart), autentifikatsiya headerini
  // qo'shish uchun ochiq yordamchi.
  static Map<String, String> authHeaders() => _headers();

  static void _tokenTugadi() {
    _token = null;
    navigatorKey.currentState?.pushNamedAndRemoveUntil('/', (route) => false);
  }

  static void _check401(http.Response response) {
    if (response.statusCode == 401) {
      _tokenTugadi();
    }
  }

  static Future<List<dynamic>> getMahsulotlar() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/mahsulotlar'), headers: _headers());
      _check401(response);
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (e) {}
    return [
      {"id": 1, "nom": "Chigit", "konditsiya_bor": true},
      {"id": 2, "nom": "Chiganoq", "konditsiya_bor": false},
      {"id": 3, "nom": "Chiganoq po'chog'i", "konditsiya_bor": false},
      {"id": 4, "nom": "Patoz", "konditsiya_bor": false},
    ];
  }

  static Future<Map<String, dynamic>> login(
      String username, String password, String role) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password, 'role': role}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      _token = data['access_token'];
      return data;
    }
    throw Exception('Login yoki parol noto\'g\'ri!');
  }

  static Future<Map<String, dynamic>> mashinaQoshish({
    required String davlatRaqami,
    required String turi,
    required String shofyor,
    required String firma,
    String viloyat = "Xorazm",
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/mashinalar'),
        headers: _headers(),
        body: jsonEncode({
          'davlat_raqami': davlatRaqami,
          'turi': turi,
          'shofyor': shofyor,
          'firma': firma,
          'viloyat': viloyat,
        }),
      );
      _check401(response);
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (e) {}
    return {
      'id': DateTime.now().millisecondsSinceEpoch,
      'davlat_raqami': davlatRaqami,
      'turi': turi,
      'shofyor': shofyor,
      'firma': firma,
    };
  }

  static Future<Map<String, dynamic>> hujjatYaratish({
    required int mashinaId,
    required int mahsulotId,
    required int aravalarSoni,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/hujjatlar'),
        headers: _headers(),
        body: jsonEncode({
          'mashina_id': mashinaId,
          'mahsulot_id': mahsulotId,
          'aravalar_soni': aravalarSoni,
        }),
      );
      _check401(response);
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (e) {}
    return {
      'id': DateTime.now().millisecondsSinceEpoch % 10000,
      'raqam': '2026/${(DateTime.now().millisecondsSinceEpoch % 1000).toString().padLeft(3, '0')}',
      'mashina_id': mashinaId,
      'mahsulot_id': mahsulotId,
      'aravalar_soni': aravalarSoni,
    };
  }

  static Future<Map<String, dynamic>> olchovSaqlash({
    required int hujjatId,
    required int aravaRaqam,
    double? tara,
    double? brutto,
    double? namlik,
    double? ifloslik,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/olchovlar'),
        headers: _headers(),
        body: jsonEncode({
          'hujjat_id': hujjatId,
          'arava_raqam': aravaRaqam,
          'tara': tara,
          'brutto': brutto,
          'namlik': namlik,
          'ifloslik': ifloslik,
        }),
      );
      _check401(response);
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (e) {}
    return {'status': 'ok'};
  }

  static Future<void> navbatQosh(Map<String, dynamic> mashina) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/navbat/qosh'),
        headers: _headers(),
        body: jsonEncode(mashina),
      );
      _check401(response);
    } catch (e) {}
  }

  static Future<List<dynamic>> navbatOl() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/navbat'), headers: _headers());
      _check401(response);
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (e) {
      throw Exception('Navbat yuklanmadi');
    }
    throw Exception('Navbat yuklanmadi');
  }

  static Future<void> navbatTugallandi(Map<String, dynamic> mashina) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/navbat/tugallandi'),
        headers: _headers(),
        body: jsonEncode(mashina),
      );
      _check401(response);
    } catch (e) {}
  }

  static Future<List<dynamic>> tugallanganlarOl() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/navbat/tugallanganlar'), headers: _headers());
      _check401(response);
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (e) {}
    return [];
  }

  static Future<void> navbatBekor(int hujjatId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/navbat/bekor'),
        headers: _headers(),
        body: jsonEncode({'hujjatId': hujjatId}),
      );
      _check401(response);
    } catch (e) {}
  }

  static Future<Map<String, dynamic>> getHujjatlar({
    int sahifa = 1,
    int sahifaHajmi = 50,
    int? mahsulotId,
    String? sanaDan,
    String? sanaGacha,
  }) async {
    try {
      final params = {
        'sahifa': sahifa.toString(),
        'sahifa_hajmi': sahifaHajmi.toString(),
        if (mahsulotId != null) 'mahsulot_id': mahsulotId.toString(),
        if (sanaDan != null) 'sana_dan': sanaDan,
        if (sanaGacha != null) 'sana_gacha': sanaGacha,
      };
      final uri = Uri.parse('$baseUrl/hujjatlar').replace(queryParameters: params);
      final response = await http.get(uri, headers: _headers());
      _check401(response);
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (e) {}
    return {"natijalar": [], "jami": 0, "sahifa": sahifa, "sahifa_hajmi": sahifaHajmi};
  }

  static Future<List<dynamic>> getTahrirTarixi(int hujjatId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tahrirlar-tarixi/$hujjatId'),
        headers: _headers(),
      );
      _check401(response);
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (e) {}
    return [];
  }

  static Future<List<dynamic>> getBarchaTahrirTarixi({int limit = 100}) async {
    try {
      final uri = Uri.parse('$baseUrl/tahrirlar-tarixi')
          .replace(queryParameters: {'limit': limit.toString()});
      final response = await http.get(uri, headers: _headers());
      _check401(response);
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (e) {}
    return [];
  }

  static Future<void> rasmOl({
    required String mashinaRaqami,
    required String mahsulotNomi,
    required String tur,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/kamera/rasm'),
        headers: _headers(),
        body: jsonEncode({
          'mashina_raqami': mashinaRaqami,
          'mahsulot_nomi': mahsulotNomi,
          'tur': tur,
        }),
      );
      _check401(response);
   } catch (e) {
      await OfflineService.rasmQosh({
        'mashina_raqami': mashinaRaqami,
        'mahsulot_nomi': mahsulotNomi,
        'tur': tur,
      });
    }
  }

 static Future<void> sozlamaSaqla(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/sozlamalar'),
        headers: _headers(),
        body: jsonEncode(data),
      );
      _check401(response);
    } catch (e) {}
  }

  static Future<Map<String, dynamic>> sozlamalarOl() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/sozlamalar'), headers: _headers());
      _check401(response);
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (e) {}
    return {};
  }

  static Future<void> nakladnoySaqla({
    required String mashinaRaqami,
    required String mahsulotNomi,
    required String sana,
    String html = '',
    int? hujjatId,
    String nakladnoyRaqam = '',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/nakladnoy/saqlash'),
        headers: _headers(),
        body: jsonEncode({
          'mashina_raqami': mashinaRaqami,
          'mahsulot_nomi': mahsulotNomi,
          'sana': sana,
          'html': html,
          'hujjat_id': hujjatId,
          'nakladnoy_raqam': nakladnoyRaqam,
        }),
      );
      _check401(response);
   } catch (e) {}
  }
}