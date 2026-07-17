import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'offline_service.dart';
import 'api_service.dart';

class SyncService {
  static Timer? _syncTimer;
  static bool _syncing = false;

  // Internet monitoring boshlash
  static void boshlash() {
    Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        _syncQil();
      }
    });
    // Har 30 soniyada tekshirish
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      final online = await OfflineService.internetBormi();
      if (online) _syncQil();
    });
  }

  static void toxtatish() {
    _syncTimer?.cancel();
  }

  // Kutayotgan operatsiyalarni backend ga yuborish
  static Future<void> _syncQil() async {
    if (_syncing) return;
    _syncing = true;
    try {
      final kutayotganlar = await OfflineService.kutayotganlarOl();
      if (kutayotganlar.isEmpty) {
        _syncing = false;
        return;
      }
      for (final op in kutayotganlar) {
        try {
          final tur = op['tur'];
          if (tur == 'navbat_qosh') {
            await ApiService.navbatQosh(Map<String, dynamic>.from(op['data']));
          } else if (tur == 'olchov_saqlash') {
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
      print('✅ Sync tugadi');
    } catch (e) {
      print('❌ Sync xato: $e');
    }
    _syncing = false;
  }
}