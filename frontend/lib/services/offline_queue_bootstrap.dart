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

  static void ishgaTushirish() {
    if (_ishgaTushirilgan) return;
    _ishgaTushirilgan = true;

    OfflineQueueService.storageOqi = (key) => html.window.localStorage[key];
    OfflineQueueService.storageYoz =
        (key, value) => html.window.localStorage[key] = value;

    OfflineQueueExecutors.baseUrlOluvchi = () => ApiService.baseUrl;
    OfflineQueueExecutors.headerOluvchi = () => ApiService.authHeaders();

    OfflineQueueExecutors.barchasiniRoyxatgaOl();
  }
}
