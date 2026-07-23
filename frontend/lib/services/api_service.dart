import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'offline_service.dart';
import 'offline_queue_service.dart';

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

  /// Mashina yaratish/olish. Onlayn muvaffaqiyatli bo'lsa, haqiqiy
  /// serverdan qaytgan obyektni ('id' - int) qaytaradi. Server bilan
  /// aloqa bo'lmasa - ENDI SOXTA ID QAYTARILMAYDI. Buning o'rniga
  /// offline navbatga (mahalliy kalit bilan) qo'yiladi va natijada
  /// 'id': null, 'mahalliyKalit': <kalit> qaytadi - chaqiruvchi shu
  /// ikkalasini FARQLASHI SHART (id==null bo'lsa - offline).
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

    final mahalliyKalit = OfflineQueueService.yangiMahalliyKalit();
    await OfflineQueueService.qoshish(
      'mashina_yaratish',
      {
        'davlat_raqami': davlatRaqami,
        'turi': turi,
        'shofyor': shofyor,
        'firma': firma,
        'viloyat': viloyat,
      },
      yaratadiganKalit: mahalliyKalit,
    );
    return {
      'id': null,
      'mahalliyKalit': mahalliyKalit,
      'davlat_raqami': davlatRaqami,
      'turi': turi,
      'shofyor': shofyor,
      'firma': firma,
    };
  }

  /// Hujjat yaratish/olish. [mashinaIdYokiKalit] mashina HAQIQIY ID'si
  /// (int, mashina onlayn yaratilgan bo'lsa) YOKI uning mahalliy kaliti
  /// (String, mashina hali offline navbatda bo'lsa) bo'lishi mumkin.
  /// Ikkinchi holatda hujjat ham to'g'ridan-to'g'ri navbatga qo'yiladi
  /// (mashina hali haqiqiy ID olmagani uchun serverga urinishning
  /// ma'nosi yo'q). Natija shakli [mashinaQoshish] bilan bir xil -
  /// 'id': null bo'lsa, offline.
  ///
  /// [mavjudMijozKaliti] - agar chaqiruvchi BIR MARTA allaqachon
  /// navbatga qo'yishga urinib ko'rgan bo'lsa (masalan operator
  /// "TARA SAQLASH"ni offlineda ikkinchi marta bossa), o'sha SAFAR
  /// generatsiya qilingan kalitni shu yerga uzatish SHART - aks holda
  /// har chaqiruvda YANGI mijoz_kaliti yaratilib, orqa fonda avtomatik
  /// sinxronlangan hujjat bilan QATOR (ikkilamchi hujjat) yaratilib
  /// qolishi mumkin.
  static Future<Map<String, dynamic>> hujjatYaratish({
    required dynamic mashinaIdYokiKalit,
    required int mahsulotId,
    required int aravalarSoni,
    String? mavjudMijozKaliti,
  }) async {
    final mijozKaliti = mavjudMijozKaliti ?? OfflineQueueService.yangiMahalliyKalit();

    if (mashinaIdYokiKalit is int) {
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/hujjatlar'),
          headers: _headers(),
          body: jsonEncode({
            'mashina_id': mashinaIdYokiKalit,
            'mahsulot_id': mahsulotId,
            'aravalar_soni': aravalarSoni,
            'mijoz_kaliti': mijozKaliti,
          }),
        );
        _check401(response);
        if (response.statusCode == 200) {
          return jsonDecode(utf8.decode(response.bodyBytes));
        }
      } catch (e) {}
    }

    await OfflineQueueService.qoshish(
      'hujjat_yaratish',
      {
        'mashina_id': mashinaIdYokiKalit,
        'mahsulot_id': mahsulotId,
        'aravalar_soni': aravalarSoni,
        'mijoz_kaliti': mijozKaliti,
      },
      yaratadiganKalit: mijozKaliti,
    );
    return {
      'id': null,
      'raqam': '',
      'mahalliyKalit': mijozKaliti,
    };
  }

  static Future<void> hujjatYangilash(int hujjatId, Map<String, dynamic> maydonlar) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/hujjatlar/$hujjatId'),
        headers: _headers(),
        body: jsonEncode(maydonlar),
      );
      _check401(response);
    } catch (e) {}
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
    final response = await http.get(Uri.parse('$baseUrl/navbat/tugallanganlar'), headers: _headers());
    _check401(response);
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
    throw Exception('Tugallanganlar yuklanmadi (status ${response.statusCode})');
  }

  static Future<void> navbatBekor(int hujjatId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/navbat/bekor'),
        headers: _headers(),
        body: jsonEncode({'hujjatId': hujjatId}),
      );
      _check401(response);
      if (response.statusCode == 200) return;
    } catch (e) {}
    // Server bilan aloqa bo'lmadi - keyinroq avtomatik qayta yuborish
    // uchun offline navbatga qo'yamiz. hujjatId bu yerda ALLAQACHON
    // haqiqiy (mahalliy kalit emas) - chunki bekor qilinayotgan mashina
    // navbatda turgan, ya'ni allaqachon serverda mavjud yozuv.
    await OfflineQueueService.qoshish('navbat_bekor', {'hujjatId': hujjatId});
  }

  static Future<Map<String, dynamic>> getHujjatlar({
    int sahifa = 1,
    int sahifaHajmi = 50,
    int? mahsulotId,
    String? sanaDan,
    String? sanaGacha,
  }) async {
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
    throw Exception('Hujjatlar yuklanmadi (status ${response.statusCode})');
  }

  static Future<Map<String, dynamic>?> getHujjat(int hujjatId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/hujjatlar/$hujjatId'),
        headers: _headers(),
      );
      _check401(response);
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (e) {}
    return null;
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

  static Future<List<dynamic>> _grafikDetalOl(String davr, String mahsulot) async {
    final uri = Uri.parse('$baseUrl/statistika/grafik-detal/$davr')
        .replace(queryParameters: {'mahsulot': mahsulot});
    final response = await http.get(uri, headers: _headers());
    _check401(response);
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
    throw Exception('Grafik-detal yuklanmadi (status ${response.statusCode})');
  }

  static Future<List<dynamic>> getGrafikDetalKunlik(String mahsulot) =>
      _grafikDetalOl('kunlik', mahsulot);

  static Future<List<dynamic>> getGrafikDetalHaftalik(String mahsulot) =>
      _grafikDetalOl('haftalik', mahsulot);

  static Future<List<dynamic>> getGrafikDetalOylik(String mahsulot) =>
      _grafikDetalOl('oylik', mahsulot);

  static Future<List<dynamic>> getGrafikDetalMavsum(String mahsulot) =>
      _grafikDetalOl('mavsum', mahsulot);

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
      if (response.statusCode == 200) return;
    } catch (e) {}
    // Server bilan aloqa bo'lmadi (yoki xato qaytardi) - keyinroq
    // avtomatik qayta yuborish uchun offline navbatga qo'yamiz.
    await OfflineQueueService.qoshish('sozlama_saqlash', data);
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