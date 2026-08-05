import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'offline_service.dart';
import 'offline_queue_service.dart';
import 'navbat_service.dart';

class ApiService {
static const String baseUrl = "http://10.112.30.77:8001";
  static String? _token;
  // Moliyaviy hisobot uchun ALOHIDA, qisqa muddatli (20 daqiqalik) token -
  // oddiy login tokenidan MUSTAQIL. Faqat to'g'ri PIN kiritilgandan
  // keyin (moliyaviyPinTekshir()) olinadi, 20 daqiqadan keyin backend
  // tomonidan avtomatik yaroqsiz bo'ladi.
  static String? _moliyaviyToken;
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static Map<String, String> _headers() {
    final headers = {'Content-Type': 'application/json'};
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  static Map<String, String> _moliyaviyHeaders() {
    final headers = {'Content-Type': 'application/json'};
    if (_moliyaviyToken != null) {
      headers['Authorization'] = 'Bearer $_moliyaviyToken';
    }
    return headers;
  }

  /// Foydalanuvchi bo'limdan chiqganda yoki qulflanganda chaqiriladi -
  /// keyingi safar PIN qayta so'raladi.
  static void moliyaviyChiqish() {
    _moliyaviyToken = null;
  }

  static bool get moliyaviyOchiqmi => _moliyaviyToken != null;

  /// [maydonlar]dagi har bir maydon hali sinxronlanmagan "yerli ID"
  /// (manfiy int, [OfflineQueueService.yerliIdBiriktir] orqali berilgan)
  /// bo'lsa, uni navbat mexanizmi tushunadigan mahalliy kalit satriga
  /// almashtiradi. Agar biror maydon hali hal qilinmagan bo'lsa,
  /// `kutilmoqda: true` qaytaradi - bu holda HTTP urinishning ma'nosi
  /// yo'q, to'g'ridan-to'g'ri offline navbatga qo'yish kerak.
  static ({Map<String, dynamic> malumot, bool kutilmoqda}) _yerliIdlarniOchir(
      Map<String, dynamic> asl, List<String> maydonlar) {
    final natija = Map<String, dynamic>.from(asl);
    var kutilmoqda = false;
    for (final maydon in maydonlar) {
      final qiymat = natija[maydon];
      if (qiymat is int && OfflineQueueService.yerliIdmi(qiymat)) {
        final kalit = OfflineQueueService.yerliIdKalitiniOl(qiymat);
        natija[maydon] = kalit;
        kutilmoqda = true;
      }
    }
    return (malumot: natija, kutilmoqda: kutilmoqda);
  }

  // Boshqa fayllardagi to'g'ridan-to'g'ri http.get()/http.post() chaqiruvlari
  // uchun (masalan admin_panel_screen.dart), autentifikatsiya headerini
  // qo'shish uchun ochiq yordamchi.
  static Map<String, String> authHeaders() => _headers();

  static void _tokenTugadi() {
    _token = null;
    navigatorKey.currentState?.pushNamedAndRemoveUntil('/', (route) => false);
  }

  /// Foydalanuvchi "Chiqish"ni bosganda chaqiriladi - saqlangan tokenni
  /// tozalaydi, shunda login ekraniga qaytilgandan keyin ham eski token
  /// bilan so'rovlar yubormaydi (avval faqat ekran almashtirilar edi,
  /// token xotirada saqlanib qolardi). NavbatService.navbat/tugallanganlar
  /// ham shu yerda tozalanadi - ular butun ilova umri davomida yashaydigan
  /// statik ro'yxatlar, aks holda bir operator chiqib, boshqasi (yoki
  /// o'shaning o'zi boshqa mahsulot bilan) kirsa, eski sessiyaning
  /// navbat/tugallangan ma'lumoti yangisiga "meros" bo'lib qolardi (sahifa
  /// to'liq qayta yuklanmagani uchun). moliyaviyChiqish() ham shu yerda
  /// chaqiriladi - aks holda admin Moliyaviy Hisobotni ochib, "Bo'limni
  /// qulflash"ni bosmasdan oddiy "Chiqish"ni bossa, _moliyaviyToken
  /// (20 daqiqagacha) tirik qolib, keyingi admin PIN so'ralmasdan
  /// moliyaviy ma'lumotlarga kirib qolishi mumkin edi - audit orqali
  /// topilgan xavfsizlik teshigi.
  static void chiqish() {
    _token = null;
    NavbatService.tozala();
    moliyaviyChiqish();
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

  /// Mavjud firma nomlari ro'yxati (operator ekranidagi autocomplete
  /// uchun). Bo'sh ro'yxat qaytsa ham xato emas - operator baribir
  /// erkin matn kiritishda davom eta oladi.
  static Future<List<String>> getFirmalar() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/firmalar'), headers: _headers());
      _check401(response);
      if (response.statusCode == 200) {
        final List natija = jsonDecode(utf8.decode(response.bodyBytes));
        return natija.map((f) => f['nom'].toString()).toList();
      }
    } catch (e) {}
    return [];
  }

  /// Tarozidan joriy og'irlikni o'qiydi. Backend fon oqimda COM portni
  /// doim tinglab turadi - bu chaqiruv shunchaki so'nggi o'qilgan
  /// qiymatni qaytaradi (portning o'zini ochmaydi). Xato yoki aloqa
  /// yo'qligida `null` qaytadi - chaqiruvchi bu holatda ekranda
  /// "Uzilgan" ko'rsatishi va oxirgi (eskirgan) qiymatga ishonmasligi
  /// kerak.
  static Future<({double ogirlikKg, bool ulangan})?> joriyOgirlikOl() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/tarozi/joriy'), headers: _headers());
      _check401(response);
      if (response.statusCode == 200) {
        final natija = jsonDecode(utf8.decode(response.bodyBytes));
        return (
          ogirlikKg: (natija['ogirlik_kg'] as num).toDouble(),
          ulangan: natija['ulangan'] as bool,
        );
      }
    } catch (e) {}
    return null;
  }

  /// PIN to'g'ri kiritilsa - moliyaviy token ichki holatga saqlanadi va
  /// `null` qaytadi (muvaffaqiyat). Xato bo'lsa - foydalanuvchiga
  /// ko'rsatiladigan xabar (masalan "PIN noto'g'ri!") qaytadi.
  static Future<String?> moliyaviyPinTekshir(String pin) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/moliyaviy/pin-tekshir'),
        headers: _headers(),
        body: jsonEncode({'pin': pin}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        _moliyaviyToken = data['moliyaviy_token'];
        return null;
      }
      final govda = jsonDecode(utf8.decode(response.bodyBytes));
      return govda['detail']?.toString() ?? "PIN tekshirishda xatolik yuz berdi!";
    } catch (e) {
      return "Serverga ulanishda xatolik yuz berdi!";
    }
  }

  /// [eskiPin] faqat PIN allaqachon o'rnatilgan bo'lsa kerak - birinchi
  /// marta o'rnatishda `null` qoldiriladi.
  static Future<String?> moliyaviyPinOrnatish({String? eskiPin, required String yangiPin}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/moliyaviy/pin'),
        headers: _headers(),
        body: jsonEncode({'eski_pin': eskiPin, 'yangi_pin': yangiPin}),
      );
      if (response.statusCode == 200) return null;
      final govda = jsonDecode(utf8.decode(response.bodyBytes));
      return govda['detail']?.toString() ?? "PIN o'rnatishda xatolik yuz berdi!";
    } catch (e) {
      return "Serverga ulanishda xatolik yuz berdi!";
    }
  }

  /// `davr`: "kunlik" | "haftalik" | "oylik" | "mavsum". Moliyaviy token
  /// yaroqsiz/yo'q bo'lsa `null` qaytadi - chaqiruvchi PIN oynasini
  /// qayta ko'rsatishi kerak.
  static Future<Map<String, dynamic>?> moliyaviyHisobotOl(String davr) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/moliyaviy/hisobot?davr=$davr'),
        headers: _moliyaviyHeaders(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
      if (response.statusCode == 403) {
        moliyaviyChiqish();
      }
    } catch (e) {}
    return null;
  }

  static Future<List<dynamic>> moliyaviyNarxlarniOl() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/mahsulotlar/narxlar'),
        headers: _moliyaviyHeaders(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
      if (response.statusCode == 403) {
        moliyaviyChiqish();
      }
    } catch (e) {}
    return [];
  }

  static Future<String?> moliyaviyNarxQoshish(int mahsulotId, double narx) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/mahsulotlar/$mahsulotId/narx'),
        headers: _moliyaviyHeaders(),
        body: jsonEncode({'narx': narx}),
      );
      if (response.statusCode == 200) return null;
      if (response.statusCode == 403) moliyaviyChiqish();
      final govda = jsonDecode(utf8.decode(response.bodyBytes));
      return govda['detail']?.toString() ?? "Narx qo'shishda xatolik yuz berdi!";
    } catch (e) {
      return "Serverga ulanishda xatolik yuz berdi!";
    }
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
    final yerli = OfflineQueueService.yerliIdmi(hujjatId);
    if (!yerli) {
      try {
        final response = await http.put(
          Uri.parse('$baseUrl/hujjatlar/$hujjatId'),
          headers: _headers(),
          body: jsonEncode(maydonlar),
        );
        _check401(response);
        if (response.statusCode == 200) return;
      } catch (e) {}
    }
    // Server bilan aloqa bo'lmadi (yoki hujjat hali sinxronlanmagan) -
    // dostaverka/qabul_qildi/yuk_olindi kabi maydonlar YO'QOLMASIN uchun
    // offline navbatga qo'yamiz.
    final hujjatIdYokiKalit = yerli
        ? OfflineQueueService.yerliIdKalitiniOl(hujjatId)
        : hujjatId;
    await OfflineQueueService.qoshish('hujjat_yangilash', {
      'hujjat_id': hujjatIdYokiKalit,
      'maydonlar': maydonlar,
    });
  }

  static Future<Map<String, dynamic>> olchovSaqlash({
    required int hujjatId,
    required int aravaRaqam,
    double? tara,
    double? brutto,
    double? namlik,
    double? ifloslik,
  }) async {
    final asl = {
      'hujjat_id': hujjatId,
      'arava_raqam': aravaRaqam,
      'tara': tara,
      'brutto': brutto,
      'namlik': namlik,
      'ifloslik': ifloslik,
    };
    final ochirilgan = _yerliIdlarniOchir(asl, ['hujjat_id']);
    if (!ochirilgan.kutilmoqda) {
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/olchovlar'),
          headers: _headers(),
          body: jsonEncode(asl),
        );
        _check401(response);
        if (response.statusCode == 200) {
          return jsonDecode(utf8.decode(response.bodyBytes));
        }
      } catch (e) {}
    }
    // Server bilan aloqa bo'lmadi (yoki hujjat hali sinxronlanmagan) -
    // o'lchov (tara/brutto) YO'QOLMASIN uchun offline navbatga qo'yamiz.
    await OfflineQueueService.qoshish('olchov_saqlash', ochirilgan.malumot);
    return {'status': 'queued'};
  }

  static Future<void> navbatQosh(Map<String, dynamic> mashina) async {
    final ochirilgan = _yerliIdlarniOchir(mashina, ['hujjatId', 'mashinaId']);
    if (!ochirilgan.kutilmoqda) {
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/navbat/qosh'),
          headers: _headers(),
          body: jsonEncode(mashina),
        );
        _check401(response);
        if (response.statusCode == 200) return;
      } catch (e) {}
    }
    // Server bilan aloqa bo'lmadi (yoki hujjat/mashina hali
    // sinxronlanmagan) - navbatga qo'shish YO'QOLMASIN uchun offline
    // navbatga qo'yamiz.
    await OfflineQueueService.qoshish('navbat_qosh', ochirilgan.malumot);
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
    final ochirilgan = _yerliIdlarniOchir(mashina, ['hujjatId', 'mashinaId']);
    if (!ochirilgan.kutilmoqda) {
      http.Response? response;
      try {
        response = await http.post(
          Uri.parse('$baseUrl/navbat/tugallandi'),
          headers: _headers(),
          body: jsonEncode(mashina),
        );
      } catch (e) {
        response = null;
      }
      if (response != null) {
        _check401(response);
        if (response.statusCode == 200) return;
        if (response.statusCode != 401) {
          // Server javob berdi, lekin rad etdi (masalan 404 - navbat
          // topilmadi, 409 - hujjat holati mos kelmadi). Qayta urinish
          // bu holatni o'zgartirmaydi, shu sabab offline navbatga
          // QO'YILMAYDI - xato to'g'ridan-to'g'ri chaqiruvchiga
          // uzatiladi (operator to'xtatilishi kerak).
          String xabar = "Navbat tugallanmadi (status ${response.statusCode})";
          try {
            final tanasi = jsonDecode(utf8.decode(response.bodyBytes));
            if (tanasi is Map && tanasi['detail'] != null) {
              xabar = tanasi['detail'].toString();
            }
          } catch (_) {}
          throw Exception(xabar);
        }
        // 401 - token tugagan; pastdagi offline navbatga tushadi, qayta
        // login qilingach keyingi sinxronizatsiyada avtomatik qayta uriniladi.
      }
    }
    // Server bilan aloqa bo'lmadi, token tugagan (401) yoki hujjat/mashina
    // hali sinxronlanmagan - tortish yakunlanganini bildiruvchi yozuv
    // YO'QOLMASIN uchun offline navbatga qo'yamiz.
    await OfflineQueueService.qoshish('navbat_tugallandi', ochirilgan.malumot);
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

  static Future<Map<String, dynamic>> _statistikaOl(String davr) async {
    final response = await http.get(
        Uri.parse('$baseUrl/statistika/$davr'), headers: _headers());
    _check401(response);
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
    throw Exception('Statistika ($davr) yuklanmadi (status ${response.statusCode})');
  }

  static Future<Map<String, dynamic>> getKunlikStat() => _statistikaOl('kunlik');

  static Future<Map<String, dynamic>> getHaftalikStat() => _statistikaOl('haftalik');

  static Future<Map<String, dynamic>> getOylikStat() => _statistikaOl('oylik');

  static Future<Map<String, dynamic>> getMavsumStat() => _statistikaOl('mavsum');

  /// Muvaffaqiyatli bo'lsa backend javobini (kamera1/kamera2 ichida
  /// operator ekranida DARHOL ko'rsatish uchun kichik "rasm_base64"
  /// bilan) qaytaradi; aks holda `null`. Chaqiruvchi buni `await`
  /// QILMASLIGI kerak (fire-and-forget, `.then()` bilan) - aks holda
  /// kamera sekin javob bersa (5 soniyagacha) operator ekrani shuncha
  /// vaqt kutib qolar edi.
  static Future<Map<String, dynamic>?> rasmOl({
    required String mashinaRaqami,
    required String mahsulotNomi,
    required String tur,
  }) async {
    http.Response? response;
    try {
      response = await http.post(
        Uri.parse('$baseUrl/kamera/rasm'),
        headers: _headers(),
        body: jsonEncode({
          'mashina_raqami': mashinaRaqami,
          'mahsulot_nomi': mahsulotNomi,
          'tur': tur,
        }),
      );
    } catch (e) {
      response = null;
    }
    if (response != null) {
      _check401(response);
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
      if (response.statusCode != 401) {
        // Server javob berdi, lekin rad etdi (masalan 502 - ikkala
        // kamera ham javob bermadi). Qayta urinish kamera holatini
        // o'zgartirmaydi, shu sabab offline navbatga QO'YILMAYDI -
        // backend allaqachon tizim_xatolari jadvaliga yozgan.
        return null;
      }
      // 401 - token tugagan; pastdagi offline navbatga tushadi, qayta
      // login qilingach keyingi sinxronizatsiyada avtomatik qayta uriniladi.
    }
    // Server bilan aloqa bo'lmadi yoki token tugagan (401) - offline
    // navbatga qo'yamiz. Bu holatda rasm ko'rsatib bo'lmaydi (hali
    // olinmagan), shuning uchun `null` qaytariladi.
    await OfflineService.rasmQosh({
      'mashina_raqami': mashinaRaqami,
      'mahsulot_nomi': mahsulotNomi,
      'tur': tur,
    });
    return null;
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

  /// Bazaning haqiqiy zaxira nusxasini (pg_dump) HOZIR yaratadi.
  /// Muvaffaqiyatli bo'lsa {'status': 'ok', 'fayl', 'vaqt', 'hajm'},
  /// aks holda {'status': 'error', 'message'} qaytaradi.
  static Future<Map<String, dynamic>> backupOl() async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/backup'), headers: _headers());
      _check401(response);
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
      return {'status': 'error', 'message': "Server xatosi (${response.statusCode})"};
    } catch (e) {
      return {'status': 'error', 'message': "Serverga ulanishda xatolik yuz berdi!"};
    }
  }

  static Future<List<dynamic>> backupRoyxatOl() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/backup/royxat'), headers: _headers());
      _check401(response);
      if (response.statusCode == 200) {
        final govda = jsonDecode(utf8.decode(response.bodyBytes));
        return govda['fayllar'] ?? [];
      }
    } catch (e) {}
    return [];
  }

  static Future<List<dynamic>> tizimXatolariOl() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/tizim-xatolari'), headers: _headers());
      _check401(response);
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (e) {}
    return [];
  }

  static Future<bool> xatoniKorildiBelgila(int xatoId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/tizim-xatolari/$xatoId/korildi'),
        headers: _headers(),
      );
      _check401(response);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Telegram bot ulanishini sinash uchun qisqa test xabari yuboradi.
  static Future<bool> telegramTest() async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/telegram/test'), headers: _headers());
      _check401(response);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Kunlik hisobotni ("bugun allaqachon yuborilganmi" tekshiruvidan
  /// qat'i nazar) DARHOL Telegram'ga yuboradi. Muvaffaqiyatli bo'lsa
  /// yuborilgan xabar matnini (tasdiqlash uchun) qaytaradi, aks holda
  /// null.
  static Future<String?> telegramKunlikYubor() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/telegram/kunlik'), headers: _headers());
      _check401(response);
      if (response.statusCode == 200) {
        final govda = jsonDecode(utf8.decode(response.bodyBytes));
        return govda['xabar']?.toString();
      }
    } catch (e) {}
    return null;
  }
}