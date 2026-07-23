import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:http/http.dart' as http;
import 'offline_service.dart';
import 'api_service.dart';
import 'offline_queue_service.dart';

class SyncService {
  static Timer? _syncTimer;
  static bool _syncing = false;

  static void boshlash() {
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      final online = html.window.navigator.onLine ?? true;
      if (online) _syncQil();
    });
  }

  static void toxtatish() {
    _syncTimer?.cancel();
  }

  static Future<void> _syncQil() async {
    if (_syncing) return;
    _syncing = true;
    try {
      final navbatNatija = await OfflineQueueService.sinxronlash();
      if (navbatNatija.muvaffaqiyatli > 0 || navbatNatija.xato > 0) {
        print('Offline navbat sinxronizatsiyasi: $navbatNatija');
      }

      final kutayotganlar = await OfflineService.kutayotganlarOl();
     
      for (final op in kutayotganlar) {
        try {
          final tur = op['tur'];
          if (tur == 'olchov_saqlash') {
            await ApiService.olchovSaqlash(
              hujjatId: op['data']['hujjat_id'],
              aravaRaqam: op['data']['arava_raqam'],
              tara: op['data']['tara']?.toDouble(),
              brutto: op['data']['brutto']?.toDouble(),
              namlik: op['data']['namlik']?.toDouble(),
              ifloslik: op['data']['ifloslik']?.toDouble(),
            );
          }
        } catch (e) {}
      }
      await OfflineService.kutayotganlarTozala();

      // Nakladnoylarni sync qilish
      final nakladnoylar = await OfflineService.nakladnoylarOl();
      final qolganNakladnoylar = <dynamic>[];
      for (final n in nakladnoylar) {
        try {
          final res = await http.post(
            Uri.parse('${ApiService.baseUrl}/nakladnoy/saqlash'),
            headers: ApiService.authHeaders(),
            body: jsonEncode(n),
          );
          if (res.statusCode != 200) qolganNakladnoylar.add(n);
        } catch (e) {
          qolganNakladnoylar.add(n);
        }
      }
      if (qolganNakladnoylar.length != nakladnoylar.length) {
        html.window.localStorage['kutayotgan_nakladnoy'] = jsonEncode(qolganNakladnoylar);
      }
      // Rasmlarni sync qilish
      final rasmlar = await OfflineService.rasmlarOl();
      final qolganRasmlar = <dynamic>[];
      for (final r in rasmlar) {
        try {
          final res = await http.post(
            Uri.parse('${ApiService.baseUrl}/kamera/rasm'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(r),
          );
          if (res.statusCode != 200) qolganRasmlar.add(r);
        } catch (e) {
          qolganRasmlar.add(r);
        }
      }
      if (qolganRasmlar.length != rasmlar.length) {
        html.window.localStorage['kutayotgan_rasmlar'] = jsonEncode(qolganRasmlar);
      }
      print('✅ Sync tugadi');
    } catch (e) {
      print('❌ Sync xato: $e');
    }
    _syncing = false;
  }
}