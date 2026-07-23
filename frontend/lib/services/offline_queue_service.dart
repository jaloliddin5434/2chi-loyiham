import 'dart:convert';
import 'dart:math';

/// Offlineda yozish amallari uchun umumiy, bog'liqlikka sezgir navbat
/// mexanizmi.
///
/// MUHIM: bu fayl ATAYLAB `dart:html` import qilmaydi - shunda uni
/// brauzersiz, oddiy `flutter test` bilan sinash mumkin. Haqiqiy
/// `localStorage`ga ulash uchun ilova ishga tushganda [storageOqi] va
/// [storageYoz] funksiyalarini almashtirish kerak (bu keyingi bosqichda
/// qilinadi - hozircha bu fayl hech qanday ekran amaliga ulanmagan).
///
/// Asosiy g'oya:
/// - Har bir offline amal (`OfflineOperation`) YARATILGAN VAQTI bilan
///   navbatga qo'yiladi va sinxronlashda shu vaqt bo'yicha KETMA-KET
///   (parallel emas) ishlanadi - bu haqiqiy foydalanishdagi tabiiy
///   bog'liqlik tartibini (mashina -> hujjat -> olchov/navbat) saqlaydi.
/// - Agar amal yangi obyekt yaratsa (masalan mashina yoki hujjat) va
///   serverga ulanmaguncha uning haqiqiy ID'si noma'lum bo'lsa, o'sha
///   amalga MAHALLIY KALIT (masalan "OFFLINE-...") beriladi. Shu kalitga
///   bog'liq keyingi amallar o'z ma'lumotida shu KALITNI (haqiqiy ID
///   o'rniga) saqlaydi. Sinxronlashda kalit haqiqiy ID'ga almashtiriladi.
/// - Agar "ota" amal serverdan rad etilsa (4xx), unga bog'liq barcha
///   "farzand" amallar avtomatik "bloklangan" deb belgilanadi - ular
///   hech qachon noto'g'ri ID bilan yuborilmaydi.

/// Tarmoq bilan bog'liq xato (server umuman javob bermadi) - bu amal
/// keyingi sinxronizatsiya siklida QAYTA URINILISHI kerak.
class OfflineTarmoqXatosi implements Exception {
  final String xabar;
  OfflineTarmoqXatosi(this.xabar);
  @override
  String toString() => 'OfflineTarmoqXatosi: $xabar';
}

/// Server so'rovni ko'rib chiqib RAD ETDI (validatsiya, 4xx va h.k.) - bu
/// amalni qayta urinishning FOYDASI YO'Q, darhol xato deb belgilanadi.
class OfflineServerXatosi implements Exception {
  final String xabar;
  final int? statusKod;
  OfflineServerXatosi(this.xabar, [this.statusKod]);
  @override
  String toString() => 'OfflineServerXatosi($statusKod): $xabar';
}

enum OfflineOpHolati { navbatda, muvaffaqiyatli, xato }

String _holatMatni(OfflineOpHolati h) => h.name;

OfflineOpHolati _holatDan(String s) => OfflineOpHolati.values.firstWhere(
      (h) => h.name == s,
      orElse: () => OfflineOpHolati.navbatda,
    );

class OfflineOperation {
  final String opId;
  final String turi;
  final int vaqt;
  final Map<String, dynamic> malumot;
  final String? yaratadiganKalit;
  OfflineOpHolati holati;
  int urinishSoni;
  String? oxirgiXato;

  OfflineOperation({
    required this.opId,
    required this.turi,
    required this.vaqt,
    required this.malumot,
    this.yaratadiganKalit,
    this.holati = OfflineOpHolati.navbatda,
    this.urinishSoni = 0,
    this.oxirgiXato,
  });

  Map<String, dynamic> toJson() => {
        'opId': opId,
        'turi': turi,
        'vaqt': vaqt,
        'malumot': malumot,
        'yaratadiganKalit': yaratadiganKalit,
        'holati': _holatMatni(holati),
        'urinishSoni': urinishSoni,
        'oxirgiXato': oxirgiXato,
      };

  factory OfflineOperation.fromJson(Map<String, dynamic> j) => OfflineOperation(
        opId: j['opId'] as String,
        turi: j['turi'] as String,
        vaqt: j['vaqt'] as int,
        malumot: Map<String, dynamic>.from(j['malumot'] as Map),
        yaratadiganKalit: j['yaratadiganKalit'] as String?,
        holati: _holatDan(j['holati'] as String? ?? 'navbatda'),
        urinishSoni: j['urinishSoni'] as int? ?? 0,
        oxirgiXato: j['oxirgiXato'] as String?,
      );
}

/// Bitta amalni haqiqiy backendga yuborishga urinuvchi funksiya turi.
/// Muvaffaqiyatli bo'lsa server javobini (masalan {'id': 42, ...})
/// qaytaradi. Tarmoq xatosida [OfflineTarmoqXatosi], server rad etsa
/// [OfflineServerXatosi] otishi kerak.
typedef OfflineOpBajaruvchi = Future<Map<String, dynamic>> Function(
    Map<String, dynamic> ochirilganMalumot);

class SinxronizatsiyaNatijasi {
  final int muvaffaqiyatli;
  final int xato;
  final bool tarmoqYoq;
  const SinxronizatsiyaNatijasi({
    required this.muvaffaqiyatli,
    required this.xato,
    required this.tarmoqYoq,
  });

  @override
  String toString() =>
      'SinxronizatsiyaNatijasi(muvaffaqiyatli: $muvaffaqiyatli, xato: $xato, tarmoqYoq: $tarmoqYoq)';
}

class OfflineQueueService {
  static const String _navbatKaliti = 'offline_yozish_navbati_v1';
  static const String _xaritaKaliti = 'offline_kalitlar_xaritasi_v1';

  /// Haqiqiy saqlash zaxirasi (localStorage) - ilova ishga tushganda
  /// almashtiriladi. Standart holatda hech narsa saqlamaydigan
  /// "no-op" - shuning uchun bu fayl hozircha hech qanday real
  /// ma'lumotga ta'sir qilmaydi.
  static String? Function(String key) storageOqi = (_) => null;
  static void Function(String key, String value) storageYoz = (_, __) {};

  static final Map<String, OfflineOpBajaruvchi> _bajaruvchilar = {};
  static bool _ishlamoqda = false;

  static final _tasodifiy = Random();

  /// Har bir amal turi (masalan "mashina_yaratish") uchun uni haqiqiy
  /// backendga yuboradigan funksiyani ro'yxatga oladi. Ilova boshlanishida
  /// bir marta chaqiriladi (hozircha hech kim chaqirmaydi - keyingi
  /// bosqichlarda ulanadi).
  static void turiniRoyxatgaOl(String turi, OfflineOpBajaruvchi bajaruvchi) {
    _bajaruvchilar[turi] = bajaruvchi;
  }

  /// Faqat sinov/qayta ishga tushirish uchun - ro'yxatga olingan
  /// bajaruvchilarni tozalaydi.
  static void bajaruvchilarniTozala() => _bajaruvchilar.clear();

  static String yangiMahalliyKalit() {
    final vaqt = DateTime.now().microsecondsSinceEpoch;
    // DIQQAT: "1 << 32" ifodasi ishlatilmasin - Dart Web (dart2js)da
    // bitli surish 32-bitli JS semantikasiga ega bo'lib, "1 << 32" VM'da
    // 4294967296 bersa-da, Web'da 0 bo'lib chiqadi (Random.nextInt(0)
    // RangeError otadi). Shu sabab tayyor sonli literal ishlatiladi.
    final tasodifiyQism = _tasodifiy.nextInt(2147483647);
    return 'OFFLINE-$vaqt-$tasodifiyQism';
  }

  static bool mahalliyKalitmi(dynamic qiymat) =>
      qiymat is String && qiymat.startsWith('OFFLINE-');

  static List<OfflineOperation> _navbatniOqish() {
    final xom = storageOqi(_navbatKaliti);
    if (xom == null || xom.isEmpty) return [];
    try {
      final royxat = jsonDecode(xom) as List;
      return royxat
          .map((e) => OfflineOperation.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static void _navbatniSaqlash(List<OfflineOperation> royxat) {
    storageYoz(_navbatKaliti, jsonEncode(royxat.map((o) => o.toJson()).toList()));
  }

  static Map<String, dynamic> _xaritaniOqish() {
    final xom = storageOqi(_xaritaKaliti);
    if (xom == null || xom.isEmpty) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(xom) as Map);
    } catch (_) {
      return {};
    }
  }

  static void _xaritaniSaqlash(Map<String, dynamic> xarita) {
    storageYoz(_xaritaKaliti, jsonEncode(xarita));
  }

  /// Yangi offline amalni navbatga qo'shadi. [vaqt] faqat sinov uchun
  /// qo'lda berilishi mumkin - haqiqiy ishlatishda har doim hozirgi
  /// vaqt ishlatiladi.
  static Future<void> qoshish(
    String turi,
    Map<String, dynamic> malumot, {
    String? yaratadiganKalit,
    int? vaqt,
  }) async {
    final royxat = _navbatniOqish();
    royxat.add(OfflineOperation(
      opId: yangiMahalliyKalit(),
      turi: turi,
      vaqt: vaqt ?? DateTime.now().microsecondsSinceEpoch,
      malumot: malumot,
      yaratadiganKalit: yaratadiganKalit,
    ));
    _navbatniSaqlash(royxat);
  }

  static List<OfflineOperation> navbatdagilar() =>
      _navbatniOqish().where((o) => o.holati == OfflineOpHolati.navbatda).toList()
        ..sort((a, b) => a.vaqt.compareTo(b.vaqt));

  static List<OfflineOperation> xatoliklar() =>
      _navbatniOqish().where((o) => o.holati == OfflineOpHolati.xato).toList()
        ..sort((a, b) => a.vaqt.compareTo(b.vaqt));

  /// Muvaffaqiyatsiz (xato) deb belgilangan bitta yozuvni navbatdan
  /// butunlay olib tashlaydi (masalan admin/operator uni qo'lda ko'rib
  /// chiqib, kerak emas deb topganda). Hozircha hech qanday ekrandan
  /// chaqirilmaydi.
  static void xatoniOchirish(String opId) {
    final royxat = _navbatniOqish();
    royxat.removeWhere((o) => o.opId == opId && o.holati == OfflineOpHolati.xato);
    _navbatniSaqlash(royxat);
  }

  /// Faqat sinov uchun - butun navbat va kalitlar xaritasini tozalaydi.
  static void hammasiniTozalash() {
    storageYoz(_navbatKaliti, jsonEncode(<dynamic>[]));
    storageYoz(_xaritaKaliti, jsonEncode(<String, dynamic>{}));
  }

  /// Navbatdagi amallarni YARATILGAN VAQTI bo'yicha ketma-ket (parallel
  /// emas) serverga yuborishga urinadi. Har bir amaldan oldin uning
  /// ma'lumotidagi mahalliy kalitlarni (agar ular allaqachon hal
  /// qilingan bo'lsa) haqiqiy qiymat bilan almashtiradi.
  static Future<SinxronizatsiyaNatijasi> sinxronlash() async {
    if (_ishlamoqda) {
      return const SinxronizatsiyaNatijasi(muvaffaqiyatli: 0, xato: 0, tarmoqYoq: false);
    }
    _ishlamoqda = true;
    try {
      final royxat = _navbatniOqish()..sort((a, b) => a.vaqt.compareTo(b.vaqt));
      final xarita = _xaritaniOqish();
      int muvaffaqiyatli = 0;
      int xato = 0;

      for (final op in royxat) {
        if (op.holati != OfflineOpHolati.navbatda) continue;

        // Mahalliy kalitlarni hal qilingan qiymatlar bilan almashtirish.
        // DIQQAT: agar qiymat AYNAN shu amalning O'Z yaratadiganKaliti
        // bo'lsa (masalan hujjat_yaratish'ning mijoz_kaliti maydoni -
        // idempotentlik uchun backendga ATAYLAB O'ZINING kalitini
        // yuboradi), bu boshqa amalga BOG'LIQLIK EMAS - o'z-o'ziga
        // ishora, o'zgarishsiz (string sifatida) yuboriladi.
        final ochirilganMalumot = <String, dynamic>{};
        var bloklangan = false;
        for (final e in op.malumot.entries) {
          if (mahalliyKalitmi(e.value) && e.value != op.yaratadiganKalit) {
            if (xarita.containsKey(e.value)) {
              ochirilganMalumot[e.key] = xarita[e.value];
            } else {
              bloklangan = true;
              break;
            }
          } else {
            ochirilganMalumot[e.key] = e.value;
          }
        }

        if (bloklangan) {
          op.holati = OfflineOpHolati.xato;
          op.oxirgiXato = "Bog'liq yozuv hali sinxronlanmagan yoki muvaffaqiyatsiz bo'lgan";
          xato++;
          continue;
        }

        final bajaruvchi = _bajaruvchilar[op.turi];
        if (bajaruvchi == null) {
          op.holati = OfflineOpHolati.xato;
          op.oxirgiXato = "Noma'lum amal turi: ${op.turi}";
          xato++;
          continue;
        }

        try {
          final natija = await bajaruvchi(ochirilganMalumot);
          op.holati = OfflineOpHolati.muvaffaqiyatli;
          muvaffaqiyatli++;
          if (op.yaratadiganKalit != null && natija['id'] != null) {
            xarita[op.yaratadiganKalit!] = natija['id'];
          }
        } on OfflineServerXatosi catch (e) {
          op.holati = OfflineOpHolati.xato;
          op.oxirgiXato = e.xabar;
          xato++;
        } on OfflineTarmoqXatosi catch (e) {
          op.urinishSoni++;
          op.oxirgiXato = e.xabar;
          // Tarmoq o'zi ishlamayapti - qolgan yozuvlarni ham urinib
          // ko'rishning ma'nosi yo'q, keyingi siklga qoldiramiz.
          _navbatniSaqlash(
              royxat.where((o) => o.holati != OfflineOpHolati.muvaffaqiyatli).toList());
          _xaritaniSaqlash(xarita);
          return SinxronizatsiyaNatijasi(
              muvaffaqiyatli: muvaffaqiyatli, xato: xato, tarmoqYoq: true);
        }
      }

      _navbatniSaqlash(
          royxat.where((o) => o.holati != OfflineOpHolati.muvaffaqiyatli).toList());
      _xaritaniSaqlash(xarita);
      return SinxronizatsiyaNatijasi(muvaffaqiyatli: muvaffaqiyatli, xato: xato, tarmoqYoq: false);
    } finally {
      _ishlamoqda = false;
    }
  }
}
