import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'offline_service.dart';
import 'api_service.dart';
import 'offline_queue_service.dart';

class SyncService {
  static Timer? _syncTimer;
  static bool _syncing = false;

  static void boshlash() {
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      final online = await OfflineService.internetBormi();
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
      final qolganKutayotganlar = <dynamic>[];
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
        } catch (e) {
          // Muvaffaqiyatsiz bo'lgan amal navbatda QOLDIRILADI (keyingi
          // siklda qayta urinish uchun) - avval bu yerda xato yutilib,
          // pastda BUTUN navbat shartsiz tozalanardi: bitta
          // muvaffaqiyatsizlik boshqa, muvaffaqiyatli saqlanishi mumkin
          // bo'lgan o'lchovlarni ham butunlay yo'qotib qo'yardi.
          qolganKutayotganlar.add(op);
        }
      }
      if (qolganKutayotganlar.length != kutayotganlar.length) {
        await OfflineService.kutayotganlarSaqla(qolganKutayotganlar);
      }

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
          if (res.statusCode == 200) continue;
          if (res.statusCode == 400 || res.statusCode == 404) {
            // Hujjat_id noto'g'ri/topilmadi - vaqt o'tishi bilan
            // o'zgarmaydi, qayta urinish foydasiz - navbatdan olib
            // tashlanadi (faqat konsolga log qilinadi).
            print('❌ Nakladnoy sync: doimiy xato (status ${res.statusCode}), navbatdan olib tashlandi: $n');
            continue;
          }
          // 401 (token tugagan) yoki 500 (PDF generatsiya - vaqtinchalik
          // bo'lishi mumkin) - qayta urinishga arziydi.
          qolganNakladnoylar.add(n);
        } catch (e) {
          qolganNakladnoylar.add(n);
        }
      }
      if (qolganNakladnoylar.length != nakladnoylar.length) {
        await OfflineService.nakladnoylarSaqla(qolganNakladnoylar);
      }
      // Rasmlarni sync qilish
      final rasmlar = await OfflineService.rasmlarOl();
      final qolganRasmlar = <dynamic>[];
      for (final r in rasmlar) {
        try {
          final res = await http.post(
            Uri.parse('${ApiService.baseUrl}/kamera/rasm'),
            headers: ApiService.authHeaders(),
            body: jsonEncode(r),
          );
          if (res.statusCode == 200) continue;
          if (res.statusCode != 401) {
            // Server javob berdi, lekin rad etdi (masalan 502 - ikkala
            // kamera ham javob bermadi). Qayta urinish kamera holatini
            // o'zgartirmaydi - navbatdan olib tashlanadi (faqat
            // konsolga log qilinadi; backend allaqachon tizim_xatolari
            // jadvaliga yozgan).
            print('❌ Rasm sync: doimiy xato (status ${res.statusCode}), navbatdan olib tashlandi: $r');
            continue;
          }
          // 401 - token tugagan, qayta urinishga arziydi.
          qolganRasmlar.add(r);
        } catch (e) {
          qolganRasmlar.add(r);
        }
      }
      if (qolganRasmlar.length != rasmlar.length) {
        await OfflineService.rasmlarSaqla(qolganRasmlar);
      }
      print('✅ Sync tugadi');
    } catch (e) {
      print('❌ Sync xato: $e');
    }
    _syncing = false;
  }
}