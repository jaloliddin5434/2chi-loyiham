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

/// Excel eksport (brauzerga fayl yuklab berish) faqat veb'da mavjud -
/// mobil/desktop ekranlarida "Excel" tugmasi ko'rsatilmaydi (qarang:
/// hujjatlar_royxati_paneli.dart va admin_panel_screen.dart'dagi
/// `kIsWeb` tekshiruvi). Bu fayl faqat mobil build'ning kompilyatsiya
/// bo'lishi uchun xavfsiz zaxira (fallback) - amalda chaqirilmasligi
/// kerak.
class ExcelExportService {
  static Future<EksportNatijasi> hisobotlarniYuklabOl({
    String? sanaDan,
    String? sanaGacha,
  }) async {
    return const EksportNatijasi(
      muvaffaqiyatli: 0,
      xatolar: ["Excel eksport faqat veb versiyasida mavjud"],
      jamiHujjatlar: 0,
    );
  }
}
