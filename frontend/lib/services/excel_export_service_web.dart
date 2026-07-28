import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'fayl_yuklab_olish.dart';

/// Har bir mahsulot bo'yicha alohida, kun/oy/mavsum guruhlangan rasmiy
/// Excel hisobotini yuklab olish natijasi.
class EksportNatijasi {
  final int muvaffaqiyatli;
  final List<String> xatolar;
  final int jamiHujjatlar;
  const EksportNatijasi({
    required this.muvaffaqiyatli,
    required this.xatolar,
    required this.jamiHujjatlar,
  });
}

/// Hujjatlar bo'limidagi "Excel" tugmasi - admin va operator panellari
/// tomonidan birgalikda ishlatiladi.
///
/// MUHIM: hisobotning o'zi (kun/oy/mavsum guruhlash, Жами qatorlari)
/// to'liq BACKENDDA generatsiya qilinadi (`GET /hujjatlar/eksport`) va
/// u yerda RASMLAR papkasiga ham saqlanadi - bu yerda faqat 4 ta so'rov
/// (har mahsulot uchun bittadan) yuborilib, natija baytlari brauzerda
/// yuklab olishga uzatiladi. Faqat SANA oralig'i bo'yicha filtrlanadi -
/// ekrandagi boshqa (matnli qidiruv, holat, firma) filtrlar bu rasmiy
/// hisobotga ta'sir qilmaydi (backend bekor qilingan hujjatlarni allaqachon
/// o'zi chiqarib tashlaydi).
class ExcelExportService {
  static const Map<int, String> _mahsulotlar = {
    1: 'Chigit',
    2: 'Chiganoq',
    3: "Chiganoq po'chog'i",
    4: 'Patoz',
  };

  static Future<EksportNatijasi> hisobotlarniYuklabOl({
    String? sanaDan,
    String? sanaGacha,
  }) async {
    int muvaffaqiyatli = 0;
    int jamiHujjatlar = 0;
    final xatolar = <String>[];

    for (final mahsulot in _mahsulotlar.entries) {
      try {
        final uri = Uri.parse('${ApiService.baseUrl}/hujjatlar/eksport')
            .replace(queryParameters: {
          'mahsulot_id': mahsulot.key.toString(),
          if (sanaDan != null && sanaDan.isNotEmpty) 'sana_dan': sanaDan,
          if (sanaGacha != null && sanaGacha.isNotEmpty) 'sana_gacha': sanaGacha,
        });
        final response = await http.get(uri, headers: ApiService.authHeaders());
        if (response.statusCode != 200) {
          xatolar.add('${mahsulot.value}: server xatosi (${response.statusCode})');
          continue;
        }

        jamiHujjatlar +=
            int.tryParse(response.headers['x-hujjatlar-soni'] ?? '') ?? 0;

        faylniYuklabOl(
          response.bodyBytes,
          '${mahsulot.value}.xlsx',
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        );
        muvaffaqiyatli++;
      } catch (e) {
        xatolar.add('${mahsulot.value}: $e');
      }
      // Ketma-ket, bitta amaldan (tugma bosilishidan) kelib chiquvchi
      // avtomatik yuklab olishlar orasida kichik kechikish - brauzer
      // buni "ko'p fayl birdaniga yuklanmoqda" deb bloklamasligi uchun.
      await Future.delayed(const Duration(milliseconds: 400));
    }

    return EksportNatijasi(
      muvaffaqiyatli: muvaffaqiyatli,
      xatolar: xatolar,
      jamiHujjatlar: jamiHujjatlar,
    );
  }
}
