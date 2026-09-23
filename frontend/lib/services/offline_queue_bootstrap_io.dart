import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'offline_queue_service.dart';
import 'offline_queue_executors.dart';

/// [OfflineQueueService] va [OfflineQueueExecutors] ATAYLAB `dart:html`dan
/// (va bir-biridan) mustaqil (sinov uchun), shuning uchun ularni haqiqiy
/// zaxiraga va [ApiService]ga ulash shu faylda, ilova ishga tushganda
/// BIR MARTA bajariladi.
///
/// DIQQAT: [OfflineQueueService.storageOqi] SINXRON chaqiriladi, lekin
/// `shared_preferences` o'zi asinxron - shu sabab qiymatlar ishga
/// tushishda xotiraga (`xotira`) oldindan yuklab olinadi, o'qish shu
/// xotiradan sinxron amalga oshiriladi. [storageYoz] esa endi
/// `Future<void>` qaytaradi - xotira darhol (sinxron) yangilanadi,
/// haqiqiy zaxiraga (`SharedPreferences`) yozish esa AWAIT qilinadi
/// (chaqiruvchi xohlasa kutishi mumkin - qarang: [OfflineQueueService.qoshish]).
class OfflineQueueBootstrap {
  static bool _ishgaTushirilgan = false;

  static Future<void> ishgaTushirish() async {
    if (_ishgaTushirilgan) return;
    _ishgaTushirilgan = true;

    final prefs = await SharedPreferences.getInstance();
    final xotira = <String, String?>{};

    OfflineQueueService.storageOqi =
        (key) => xotira[key] ?? prefs.getString(key);
    OfflineQueueService.storageYoz = (key, value) async {
      // `xotira` YANGILANISHI await'dan OLDIN, sinxron sodir bo'ladi
      // (Dart async funksiya birinchi await'gacha sinxron ishlaydi) -
      // shu sabab darhol keyingi o'qishlar (storageOqi) hamon eng so'nggi
      // qiymatni ko'radi, diskka yozish tugashini kutish shart emas.
      // Haqiqiy diskka yozish esa endi AWAIT qilinadi - avval bu
      // Future'ni hech kim kutmasdi, ilova shu yozuv platforma kanaliga
      // yetib bormasdan o'chirilsa, amal yo'qolib qolishi mumkin edi.
      xotira[key] = value;
      await prefs.setString(key, value);
    };

    OfflineQueueExecutors.baseUrlOluvchi = () => ApiService.baseUrl;
    OfflineQueueExecutors.headerOluvchi = () => ApiService.authHeaders();

    OfflineQueueExecutors.barchasiniRoyxatgaOl();
  }
}
