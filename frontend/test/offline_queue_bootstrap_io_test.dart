// OfflineQueueBootstrap.ishgaTushirish() (offline_queue_bootstrap_io.dart)
// endi storageYoz'ni async qilib, SharedPreferences.setString()ni AWAIT
// qiladi. Bu test haqiqiy (mock) SharedPreferences bilan uchidan-uchigacha
// tekshiradi: OfflineQueueService.qoshish() tugagach, yozuv shunchaki
// jarayon-ichi xotirada (`xotira` map) emas, balki HAQIQIY
// SharedPreferences saqlashida ham (mustaqil o'qish orqali) mavjud
// bo'lishi kerak.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/services/offline_queue_bootstrap_io.dart';
import 'package:frontend/services/offline_queue_service.dart';

void main() {
  test(
      "OfflineQueueBootstrap: qoshish() dan keyin yozuv HAQIQATAN SharedPreferences'ga yetib boradi",
      () async {
    SharedPreferences.setMockInitialValues({});
    await OfflineQueueBootstrap.ishgaTushirish();

    await OfflineQueueService.qoshish('mashina_yaratish', {
      'davlat_raqami': 'BOOTSTRAP-SINOV-01',
    });

    // Mustaqil o'qish - shu chaqiruv jarayon-ichi `xotira` xaritasidan
    // emas, balki HAQIQIY (mock) SharedPreferences zaxirasidan o'qiydi.
    final prefs = await SharedPreferences.getInstance();
    final saqlangan = prefs.getString('offline_yozish_navbati_v1');

    expect(saqlangan, isNotNull,
        reason:
            "qoshish() tugagandan keyin yozuv SharedPreferences'da HAQIQATAN "
            "bo'lishi kerak edi - avval bu await qilinmasdi (fire-and-forget)");
    expect(saqlangan, contains('BOOTSTRAP-SINOV-01'));
  });
}
