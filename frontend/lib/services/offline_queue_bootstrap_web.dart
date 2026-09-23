import 'dart:html' as html;
import 'api_service.dart';
import 'offline_queue_service.dart';
import 'offline_queue_executors.dart';

/// [OfflineQueueService] va [OfflineQueueExecutors] ATAYLAB `dart:html`dan
/// (va bir-biridan) mustaqil (sinov uchun), shuning uchun ularni haqiqiy
/// `localStorage`ga va [ApiService]ga ulash shu faylda, ilova ishga
/// tushganda BIR MARTA bajariladi.
class OfflineQueueBootstrap {
  static bool _ishgaTushirilgan = false;

  static Future<void> ishgaTushirish() async {
    if (_ishgaTushirilgan) return;
    _ishgaTushirilgan = true;

    OfflineQueueService.storageOqi = (key) => html.window.localStorage[key];
    // `localStorage` yozuvi o'zi sinxron - `async` faqat [storageYoz]ning
    // (endi `Future<void>` qaytaradigan) turiga mos kelishi uchun kerak.
    OfflineQueueService.storageYoz = (key, value) async {
      html.window.localStorage[key] = value;
    };

    OfflineQueueExecutors.baseUrlOluvchi = () => ApiService.baseUrl;
    OfflineQueueExecutors.headerOluvchi = () => ApiService.authHeaders();

    OfflineQueueExecutors.barchasiniRoyxatgaOl();
  }
}
