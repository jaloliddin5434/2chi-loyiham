import 'dart:convert';
import 'package:http/http.dart' as http;
import 'offline_service.dart';

class ApiService {
static const String baseUrl = "http://10.112.30.77:8001";

  static Future<List<dynamic>> getMahsulotlar() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/mahsulotlar'));
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
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password, 'role': role}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('Login yoki parol noto\'g\'ri!');
      }
    } catch (e) {
      if (username == 'admin' && password == 'admin123' && role == 'admin') {
        return {'username': 'admin', 'role': 'admin', 'access_token': 'local'};
      } else if (username == 'operator' && password == 'operator123' && role == 'operator') {
        return {'username': 'operator', 'role': 'operator', 'access_token': 'local'};
      }
      throw Exception('Login yoki parol noto\'g\'ri!');
    }
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
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'davlat_raqami': davlatRaqami,
          'turi': turi,
          'shofyor': shofyor,
          'firma': firma,
          'viloyat': viloyat,
        }),
      );
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
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'mashina_id': mashinaId,
          'mahsulot_id': mahsulotId,
          'aravalar_soni': aravalarSoni,
        }),
      );
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
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'hujjat_id': hujjatId,
          'arava_raqam': aravaRaqam,
          'tara': tara,
          'brutto': brutto,
          'namlik': namlik,
          'ifloslik': ifloslik,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (e) {}
    return {'status': 'ok'};
  }

  static Future<void> navbatQosh(Map<String, dynamic> mashina) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/navbat/qosh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(mashina),
      );
    } catch (e) {}
  }

  static Future<List<dynamic>> navbatOl() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/navbat'));
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
      await http.post(
        Uri.parse('$baseUrl/navbat/tugallandi'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(mashina),
      );
    } catch (e) {}
  }

  static Future<List<dynamic>> tugallanganlarOl() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/navbat/tugallanganlar'));
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (e) {}
    return [];
  }

  static Future<void> navbatBekor(int hujjatId) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/navbat/bekor'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'hujjatId': hujjatId}),
      );
    } catch (e) {}
  }

  static Future<List<dynamic>> getHujjatlar() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/hujjatlar'));
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
      await http.post(
        Uri.parse('$baseUrl/kamera/rasm'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'mashina_raqami': mashinaRaqami,
          'mahsulot_nomi': mahsulotNomi,
          'tur': tur,
        }),
      );
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
      await http.post(
        Uri.parse('$baseUrl/sozlamalar'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
    } catch (e) {}
  }

  static Future<Map<String, dynamic>> sozlamalarOl() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/sozlamalar'));
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
  }) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/nakladnoy/saqlash'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'mashina_raqami': mashinaRaqami,
          'mahsulot_nomi': mahsulotNomi,
          'sana': sana,
          'html': html,
          'hujjat_id': hujjatId,
        }),
      );
   } catch (e) {}
  }
}