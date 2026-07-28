import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'offline_queue_service.dart';
import 'offline_queue_executors.dart';

/// [OfflineQueueService] va [OfflineQueueExecutors] ATAYLAB `dart:html`dan
/// (va bir-biridan) mustaqil (sinov uchun), shuning uchun ularni haqiqiy
/// zaxiraga va [ApiService]ga ulash shu faylda, ilova ishga tushganda
/// BIR MARTA bajariladi.
///
/// DIQQAT: [OfflineQueueService.storageOqi]/[storageYoz] SINXRON
/// chaqiriladi, lekin `shared_preferences` o'zi asinxron - shu sabab
/// qiymatlar ishga tushishda xotiraga (`_xotira`) oldindan yuklab
/// olinadi, o'qish shu xotiradan sinxron amalga oshiriladi, yozishda esa
/// ham xotira, ham haqiqiy zaxira (`SharedPreferences`) yangilanadi.
class OfflineQueueBootstrap {
  static bool _ishgaTushirilgan = false;

  static Future<void> ishgaTushirish() async {
    if (_ishgaTushirilgan) return;
    _ishgaTushirilgan = true;

    final prefs = await SharedPreferences.getInstance();
    final xotira = <String, String?>{};

    OfflineQueueService.storageOqi =
        (key) => xotira[key] ?? prefs.getString(key);
    OfflineQueueService.storageYoz = (key, value) {
      xotira[key] = value;
      prefs.setString(key, value);
    };

    OfflineQueueExecutors.baseUrlOluvchi = () => ApiService.baseUrl;
    OfflineQueueExecutors.headerOluvchi = () => ApiService.authHeaders();

    OfflineQueueExecutors.barchasiniRoyxatgaOl();
  }
}
