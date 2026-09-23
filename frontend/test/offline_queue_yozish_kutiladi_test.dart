// Bug: OfflineQueueService.storageYoz (va shu orqali qoshish()) ilgari
// diskka yozish TUGASHINI kutmasdi - `storageYoz` turi oddiy `void
// Function(...)` edi, shu sabab uni async qilib await qilishning ILOJI
// YO'Q edi (chaqiruvchi tomondan). Agar ilova shu yozuv platforma
// kanaliga (masalan SharedPreferences) yetib bormasdan o'chirilsa, yangi
// qo'shilgan offline amal butunlay yo'qolib qolishi mumkin edi.
//
// Tuzatish: storageYoz endi Future<void> qaytaradi, qoshish() esa uni
// AWAIT qiladi - chaqiruvchi (masalan ApiService) bu amal HAQIQATAN
// saqlangandan keyingina davom etadi.
//
// Bu test storageYoz'ni QO'LDA (Completer bilan) boshqariladigan
// kechikish bilan almashtiradi - shu orqali qoshish()ning HAQIQATAN
// yozish tugashini kutishini (vaqt/tasodifga tayanmasdan) deterministik
// isbotlaydi.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/offline_queue_service.dart';

void main() {
  setUp(() {
    OfflineQueueService.storageOqi = (_) => null;
    OfflineQueueService.storageYoz = (_, __) async {};
    OfflineQueueService.hammasiniTozalash();
    OfflineQueueService.bajaruvchilarniTozala();
  });

  test(
      "qoshish() diskka yozish TUGAGUNICHA kutadi (storageYoz Future'i haqiqatan await qilinadi)",
      () async {
    final soxtaSaqlash = <String, String>{};
    final yozishRuxsat = Completer<void>();
    var yozishBoshlandimi = false;
    var yozishTugadimi = false;

    OfflineQueueService.storageOqi = (key) => soxtaSaqlash[key];
    OfflineQueueService.storageYoz = (key, value) async {
      yozishBoshlandimi = true;
      // Test o'zi qachon "diskka yozish tugadi" deyishini boshqaradi -
      // haqiqiy SharedPreferences.setString()ning asinxron tabiatini
      // deterministik simulyatsiya qiladi.
      await yozishRuxsat.future;
      soxtaSaqlash[key] = value;
      yozishTugadimi = true;
    };

    final qoshishFuture = OfflineQueueService.qoshish('test_amal', {'x': 1});

    await Future<void>.delayed(Duration.zero);
    expect(yozishBoshlandimi, isTrue,
        reason: "qoshish() storageYoz()ni chaqirishi kerak edi");
    expect(yozishTugadimi, isFalse,
        reason: "yozish hali 'ruxsat' kutayotgan bo'lishi kerak");

    var qoshishTugadimi = false;
    unawaited(qoshishFuture.then((_) => qoshishTugadimi = true));
    // Yozish hali tugamagan (Completer resolve qilinmagan) - shu holatda
    // qoshish() ham HALI tugamagan bo'lishi SHART, aks holda await
    // haqiqatan ishlatilmayapti degani.
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(qoshishTugadimi, isFalse,
        reason:
            "qoshish() yozish TUGAMASDAN turib tugadi - bu storageYoz "
            "Future'i AWAIT qilinmayotganini bildiradi (tuzatilmagan xato)");

    // Endi yozishga ruxsat beramiz - shundan keyingina qoshish() tugashi kerak.
    yozishRuxsat.complete();
    await qoshishFuture;

    expect(yozishTugadimi, isTrue);
    expect(qoshishTugadimi, isTrue);
    expect(soxtaSaqlash, isNotEmpty);
  });
}
