import 'dart:convert';
import 'package:http/http.dart' as http;
import 'offline_queue_service.dart';

/// Har bir offline amal turi uchun haqiqiy backendga so'rov yuboruvchi
/// "bajaruvchi" funksiyalar.
///
/// MUHIM: bu fayl ATAYLAB `dart:html`GA HAM, `ApiService`GA HAM bog'liq
/// EMAS (faqat `package:http` ishlatadi) - `ApiService` o'zi
/// `offline_service.dart` orqali `dart:html`ni tortib keladi, bu esa
/// Dart VM'da (haqiqiy `flutter test`da) ishlashga xalaqit beradi.
/// Shuning uchun baseUrl va autentifikatsiya sarlavhalari IN'YEKSIYA
/// qilinadi - haqiqiy ilovada [ApiService]dan, testda esa alohida,
/// to'g'ridan-to'g'ri backendga kirish orqali.
class OfflineQueueExecutors {
  static String Function() baseUrlOluvchi = () => '';
  static Map<String, String> Function() headerOluvchi = () => {};

  /// Bitta joydan boshqariladigan xato-klassifikatsiya: status 401
  /// (avtorizatsiya tokeni muddati tugagan/notogri) DOIMIY server
  /// rad etishi (OfflineServerXatosi) EMAS - bu holatda ma'lumotning
  /// o'zi mutlaqo to'g'ri, faqat operator hozircha qayta login qilishi
  /// kerak. Shu sabab [OfflineTarmoqXatosi] sifatida qaraladi - bu
  /// amal "xato" deb belgilanib yo'qolib qolmaydi, operator qayta
  /// login qilgach keyingi sinxronizatsiya siklida avtomatik qayta
  /// urinilib, muvaffaqiyatli tugaydi.
  static Never _xatoOtish(http.Response javob, String xabar) {
    if (javob.statusCode == 401) {
      throw OfflineTarmoqXatosi(
          "Avtorizatsiya muddati tugagan (401) - qayta login qilingach avtomatik qayta urinilyapti");
    }
    throw OfflineServerXatosi("$xabar (status ${javob.statusCode})", javob.statusCode);
  }

  static void barchasiniRoyxatgaOl() {
    OfflineQueueService.turiniRoyxatgaOl('sozlama_saqlash', sozlamaBajaruvchisi);
    OfflineQueueService.turiniRoyxatgaOl('navbat_bekor', navbatBekorBajaruvchisi);
    OfflineQueueService.turiniRoyxatgaOl('mashina_yaratish', mashinaYaratishBajaruvchisi);
    OfflineQueueService.turiniRoyxatgaOl('hujjat_yaratish', hujjatYaratishBajaruvchisi);
    OfflineQueueService.turiniRoyxatgaOl('olchov_saqlash', olchovSaqlashBajaruvchisi);
    OfflineQueueService.turiniRoyxatgaOl('navbat_qosh', navbatQoshBajaruvchisi);
    OfflineQueueService.turiniRoyxatgaOl('navbat_tugallandi', navbatTugallandiBajaruvchisi);
    OfflineQueueService.turiniRoyxatgaOl('hujjat_yangilash', hujjatYangilashBajaruvchisi);
  }

  /// `malumot['hujjat_id']` (sinxronizatsiya vaqtida allaqachon haqiqiy
  /// ID'ga hal qilingan bo'ladi) URL yo'lida, `malumot['maydonlar']` esa
  /// PUT so'rov tanasida yuboriladi.
  static Future<Map<String, dynamic>> hujjatYangilashBajaruvchisi(
      Map<String, dynamic> malumot) async {
    final hujjatId = malumot['hujjat_id'];
    final maydonlar = Map<String, dynamic>.from(malumot['maydonlar'] as Map);
    http.Response javob;
    try {
      javob = await http.put(
        Uri.parse('${baseUrlOluvchi()}/hujjatlar/$hujjatId'),
        headers: headerOluvchi(),
        body: jsonEncode(maydonlar),
      );
    } catch (e) {
      throw OfflineTarmoqXatosi(e.toString());
    }
    if (javob.statusCode == 200) {
      return jsonDecode(utf8.decode(javob.bodyBytes)) as Map<String, dynamic>;
    }
    _xatoOtish(javob, "Hujjat yangilanmadi");
  }

  static Future<Map<String, dynamic>> navbatQoshBajaruvchisi(
      Map<String, dynamic> malumot) async {
    http.Response javob;
    try {
      javob = await http.post(
        Uri.parse('${baseUrlOluvchi()}/navbat/qosh'),
        headers: headerOluvchi(),
        body: jsonEncode(malumot),
      );
    } catch (e) {
      throw OfflineTarmoqXatosi(e.toString());
    }
    if (javob.statusCode == 200) {
      return jsonDecode(utf8.decode(javob.bodyBytes)) as Map<String, dynamic>;
    }
    _xatoOtish(javob, "Navbatga qo'shilmadi");
  }

  static Future<Map<String, dynamic>> navbatTugallandiBajaruvchisi(
      Map<String, dynamic> malumot) async {
    http.Response javob;
    try {
      javob = await http.post(
        Uri.parse('${baseUrlOluvchi()}/navbat/tugallandi'),
        headers: headerOluvchi(),
        body: jsonEncode(malumot),
      );
    } catch (e) {
      throw OfflineTarmoqXatosi(e.toString());
    }
    if (javob.statusCode == 200) {
      return jsonDecode(utf8.decode(javob.bodyBytes)) as Map<String, dynamic>;
    }
    _xatoOtish(javob, "Navbat tugallanmadi");
  }

  static Future<Map<String, dynamic>> olchovSaqlashBajaruvchisi(
      Map<String, dynamic> malumot) async {
    http.Response javob;
    try {
      javob = await http.post(
        Uri.parse('${baseUrlOluvchi()}/olchovlar'),
        headers: headerOluvchi(),
        body: jsonEncode(malumot),
      );
    } catch (e) {
      throw OfflineTarmoqXatosi(e.toString());
    }
    if (javob.statusCode == 200) {
      return jsonDecode(utf8.decode(javob.bodyBytes)) as Map<String, dynamic>;
    }
    _xatoOtish(javob, "Olchov saqlanmadi");
  }

  static Future<Map<String, dynamic>> sozlamaBajaruvchisi(
      Map<String, dynamic> malumot) async {
    http.Response javob;
    try {
      javob = await http.post(
        Uri.parse('${baseUrlOluvchi()}/sozlamalar'),
        headers: headerOluvchi(),
        body: jsonEncode(malumot),
      );
    } catch (e) {
      throw OfflineTarmoqXatosi(e.toString());
    }
    if (javob.statusCode == 200) {
      return {'status': 'ok'};
    }
    _xatoOtish(javob, "Sozlama saqlanmadi");
  }

  static Future<Map<String, dynamic>> navbatBekorBajaruvchisi(
      Map<String, dynamic> malumot) async {
    http.Response javob;
    try {
      javob = await http.post(
        Uri.parse('${baseUrlOluvchi()}/navbat/bekor'),
        headers: headerOluvchi(),
        body: jsonEncode(malumot),
      );
    } catch (e) {
      throw OfflineTarmoqXatosi(e.toString());
    }
    if (javob.statusCode == 200) {
      return {'status': 'ok'};
    }
    _xatoOtish(javob, "Navbatdan o'chirilmadi");
  }

  /// Mashina yaratish - backend `davlat_raqami` bo'yicha allaqachon
  /// tabiiy idempotent (mavjud bo'lsa, mavjudini qaytaradi), shuning
  /// uchun bu yerda alohida mijoz_kaliti kerak emas.
  static Future<Map<String, dynamic>> mashinaYaratishBajaruvchisi(
      Map<String, dynamic> malumot) async {
    http.Response javob;
    try {
      javob = await http.post(
        Uri.parse('${baseUrlOluvchi()}/mashinalar'),
        headers: headerOluvchi(),
        body: jsonEncode(malumot),
      );
    } catch (e) {
      throw OfflineTarmoqXatosi(e.toString());
    }
    if (javob.statusCode == 200) {
      return jsonDecode(utf8.decode(javob.bodyBytes)) as Map<String, dynamic>;
    }
    _xatoOtish(javob, "Mashina yaratilmadi");
  }

  /// Hujjat yaratish - `malumot['mijoz_kaliti']` (offline navbatga
  /// qo'shilgan shu amalning o'z mahalliy kaliti) backendga yuboriladi,
  /// shunda qayta urinish (retry) ikkilamchi hujjat yaratib qo'ymaydi
  /// (backend shu kalit bo'yicha avval tekshiradi - migratsiya_mijoz_kaliti.py).
  static Future<Map<String, dynamic>> hujjatYaratishBajaruvchisi(
      Map<String, dynamic> malumot) async {
    http.Response javob;
    try {
      javob = await http.post(
        Uri.parse('${baseUrlOluvchi()}/hujjatlar'),
        headers: headerOluvchi(),
        body: jsonEncode(malumot),
      );
    } catch (e) {
      throw OfflineTarmoqXatosi(e.toString());
    }
    if (javob.statusCode == 200) {
      return jsonDecode(utf8.decode(javob.bodyBytes)) as Map<String, dynamic>;
    }
    _xatoOtish(javob, "Hujjat yaratilmadi");
  }
}
