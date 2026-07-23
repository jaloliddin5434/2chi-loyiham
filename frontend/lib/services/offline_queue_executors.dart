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

  static void barchasiniRoyxatgaOl() {
    OfflineQueueService.turiniRoyxatgaOl('sozlama_saqlash', sozlamaBajaruvchisi);
    OfflineQueueService.turiniRoyxatgaOl('navbat_bekor', navbatBekorBajaruvchisi);
    OfflineQueueService.turiniRoyxatgaOl('mashina_yaratish', mashinaYaratishBajaruvchisi);
    OfflineQueueService.turiniRoyxatgaOl('hujjat_yaratish', hujjatYaratishBajaruvchisi);
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
    throw OfflineServerXatosi(
        "Sozlama saqlanmadi (status ${javob.statusCode})", javob.statusCode);
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
    throw OfflineServerXatosi(
        "Navbatdan o'chirilmadi (status ${javob.statusCode})", javob.statusCode);
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
    throw OfflineServerXatosi(
        "Mashina yaratilmadi (status ${javob.statusCode})", javob.statusCode);
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
    throw OfflineServerXatosi(
        "Hujjat yaratilmadi (status ${javob.statusCode})", javob.statusCode);
  }
}
