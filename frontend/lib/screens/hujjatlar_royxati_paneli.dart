import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/excel_export_service.dart';

/// Hujjatlar ro'yxatini FAQAT KO'RISH uchun (operator paneli ichida
/// ishlatiladi). Admin paneldagi to'liq boshqaruv jadvalidan farqli -
/// bu yerda Tuzat/O'chir/Tarix amallari yo'q, faqat mahsulot/sana
/// filtri, ro'yxat va Excel yuklab olish bor.
class HujjatlarRoyxatiPaneli extends StatefulWidget {
  const HujjatlarRoyxatiPaneli({super.key});

  @override
  State<HujjatlarRoyxatiPaneli> createState() =>
      _HujjatlarRoyxatiPaneliState();
}

class _HujjatlarRoyxatiPaneliState extends State<HujjatlarRoyxatiPaneli> {
  // Admin panelidagi Hujjatlar bo'limi bilan aniq bir xil (izchillik uchun)
  static const Color asosiyRang = Color(0xFF0F6E56);
  static const Color kartaBorder = Color(0xFFD8EDD0);
  static const Color muted = Color(0xFF9AC080);

  int tanlanganMahsulotId = 0;
  String sanadan = '';
  String sanagacha = '';

  List<dynamic> hujjatlar = [];
  int jamiHujjatlar = 0;
  int _joriySahifa = 1;
  bool yuklanmoqda = true;
  bool koproqYuklanmoqda = false;
  bool eksportQilinmoqda = false;
  String? xato;

  @override
  void initState() {
    super.initState();
    hujjatlarniYukla();
  }

  Future<void> hujjatlarniYukla() async {
    setState(() {
      yuklanmoqda = true;
      xato = null;
      _joriySahifa = 1;
    });
    try {
      final natija = await ApiService.getHujjatlar(
        mahsulotId: tanlanganMahsulotId == 0 ? null : tanlanganMahsulotId,
        sanaDan: sanadan.isEmpty ? null : sanadan,
        sanaGacha: sanagacha.isEmpty ? null : sanagacha,
        sahifa: 1,
        sahifaHajmi: 50,
      );
      if (!mounted) return;
      setState(() {
        hujjatlar = natija['natijalar'] ?? [];
        jamiHujjatlar = natija['jami'] ?? 0;
        yuklanmoqda = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        yuklanmoqda = false;
        xato = "Yuklanmadi: $e";
      });
    }
  }

  Future<void> koproqYukla() async {
    if (koproqYuklanmoqda || hujjatlar.length >= jamiHujjatlar) return;
    setState(() => koproqYuklanmoqda = true);
    final keyingiSahifa = _joriySahifa + 1;
    try {
      final natija = await ApiService.getHujjatlar(
        mahsulotId: tanlanganMahsulotId == 0 ? null : tanlanganMahsulotId,
        sanaDan: sanadan.isEmpty ? null : sanadan,
        sanaGacha: sanagacha.isEmpty ? null : sanagacha,
        sahifa: keyingiSahifa,
        sahifaHajmi: 50,
      );
      final yangilar = (natija['natijalar'] ?? []) as List<dynamic>;
      if (!mounted) return;
      setState(() {
        hujjatlar.addAll(yangilar);
        jamiHujjatlar = natija['jami'] ?? jamiHujjatlar;
        _joriySahifa = keyingiSahifa;
        koproqYuklanmoqda = false;
      });
    } catch (e) {
      if (mounted) setState(() => koproqYuklanmoqda = false);
    }
  }

  Future<void> excelYuklaOl() async {
    // DIQQAT: rasmiy hisobot (kun/oy/mavsum guruhlangan, har mahsulot
    // uchun alohida fayl) faqat SANA oralig'i bo'yicha filtrlanadi -
    // mahsulot-tab tanlovi bu hisobotga ta'sir qilmaydi, chunki u har
    // doim BARCHA 4 mahsulot uchun to'liq holda generatsiya qilinadi.
    setState(() => eksportQilinmoqda = true);
    try {
      final natija = await ExcelExportService.hisobotlarniYuklabOl(
        sanaDan: sanadan.isEmpty ? null : sanadan,
        sanaGacha: sanagacha.isEmpty ? null : sanagacha,
      );
      if (!mounted) return;
      final xato = natija.xatolar.isNotEmpty;
      String xabar;
      Color rang;
      if (xato) {
        xabar =
            "${natija.muvaffaqiyatli}/4 ta fayl yuklandi. Xato: ${natija.xatolar.join('; ')}";
        rang = Colors.orange;
      } else if (natija.jamiHujjatlar == 0) {
        xabar = "Tanlangan sana oralig'ida hujjat topilmadi (fayllar bo'sh)";
        rang = Colors.orange;
      } else {
        xabar =
            "4 ta Excel fayl yuklab olindi! (${natija.jamiHujjatlar} ta hujjat)";
        rang = Colors.green;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(xabar), backgroundColor: rang),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Xato: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => eksportQilinmoqda = false);
    }
  }

  Widget _mahsulotTab(int id, String nom) {
    final active = tanlanganMahsulotId == id;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => tanlanganMahsulotId = id);
          hujjatlarniYukla();
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? asosiyRang : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(nom,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : muted)),
        ),
      ),
    );
  }

  Widget _sanaMaydoni(String hint, String qiymat, ValueChanged<String> onChanged) {
    return SizedBox(
      width: 150,
      height: 36,
      child: TextField(
        controller: TextEditingController(text: qiymat)
          ..selection = TextSelection.collapsed(offset: qiymat.length),
        onChanged: onChanged,
        onSubmitted: (_) => hujjatlarniYukla(),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 11),
          prefixIcon: const Icon(Icons.calendar_today, size: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }

  Widget _td(String text, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Text(text,
          style: TextStyle(
              fontSize: 11,
              color: const Color(0xFF0D1B2A),
              fontWeight: bold ? FontWeight.w700 : FontWeight.normal)),
    );
  }

  Widget _tdHolat(String holat) {
    Color bg, border, matn;
    String label;
    switch (holat) {
      case 'bekor':
        bg = const Color(0xFFFFF0F0);
        border = const Color(0xFFF0B0A0);
        matn = const Color(0xFFC03030);
        label = 'Bekor';
        break;
      case 'tugallandi':
        bg = const Color(0xFFEAFADE);
        border = const Color(0xFFB0D890);
        matn = const Color(0xFF0F6E56);
        label = 'Tugallandi';
        break;
      default:
        bg = const Color(0xFFFFF8E0);
        border = const Color(0xFFF0D070);
        matn = const Color(0xFFC89020);
        label = 'Jarayon';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(8)),
        child: Text(label, style: TextStyle(fontSize: 10, color: matn)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: kartaBorder),
              borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            _mahsulotTab(0, 'Jami'),
            _mahsulotTab(1, 'Chigit'),
            _mahsulotTab(2, 'Chiganoq'),
            _mahsulotTab(3, "Chig. po'chog'i"),
            _mahsulotTab(4, 'Patoz'),
          ]),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: kartaBorder),
              borderRadius: BorderRadius.circular(12)),
          child: Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
            _sanaMaydoni("Dan: 2026-01-01", sanadan, (v) => sanadan = v),
            _sanaMaydoni("Gacha: 2026-12-31", sanagacha, (v) => sanagacha = v),
            ElevatedButton.icon(
              onPressed: hujjatlarniYukla,
              icon: const Icon(Icons.search, size: 14),
              label: const Text("Qidirish", style: TextStyle(fontSize: 11)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: asosiyRang,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            ),
            ElevatedButton.icon(
              onPressed: eksportQilinmoqda ? null : excelYuklaOl,
              icon: eksportQilinmoqda
                  ? const SizedBox(
                      width: 12, height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.table_chart, size: 14),
              label: const Text("Excel", style: TextStyle(fontSize: 11)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF217346),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            ),
          ]),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: kartaBorder),
              borderRadius: BorderRadius.circular(16)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Jami: $jamiHujjatlar ta hujjat",
                style: const TextStyle(fontSize: 11, color: muted)),
            const SizedBox(height: 10),
            if (yuklanmoqda)
              const Center(
                  child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(),
              ))
            else if (xato != null)
              Center(
                  child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Text(xato!, style: const TextStyle(color: Colors.red)),
              ))
            else if (hujjatlar.isEmpty)
              Center(
                  child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(children: [
                  Icon(Icons.inbox, size: 48, color: muted),
                  const SizedBox(height: 8),
                  Text("Hujjatlar yo'q", style: TextStyle(color: muted)),
                ]),
              ))
            else
              Table(
                border: TableBorder.all(color: const Color(0xFFE0F0D8)),
                columnWidths: const {
                  0: FlexColumnWidth(1),
                  1: FlexColumnWidth(0.9),
                  2: FlexColumnWidth(1.5),
                  3: FlexColumnWidth(1.2),
                  4: FlexColumnWidth(1),
                  5: FlexColumnWidth(0.8),
                  6: FlexColumnWidth(0.8),
                  7: FlexColumnWidth(0.8),
                  8: FlexColumnWidth(0.9),
                },
                children: [
                  TableRow(
                    decoration: const BoxDecoration(color: Color(0xFF0D1B2A)),
                    children: ['№', 'Sana', 'Firma', 'Mashina', 'Shofyor',
                      'Tara', 'Brutto', 'Netto', 'Holat']
                        .map((h) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                              child: Text(h,
                                  style: const TextStyle(
                                      fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600)),
                            ))
                        .toList(),
                  ),
                  ...hujjatlar.map((h) => TableRow(
                        decoration: BoxDecoration(
                            color: h['holat'] == 'bekor'
                                ? const Color(0xFFFFF0F0)
                                : Colors.white),
                        children: [
                          _td((h['raqam'] ?? '—').toString(), bold: true),
                          _td(h['created_at'] != null
                              ? (h['created_at'].toString().length >= 10
                                  ? h['created_at'].toString().substring(0, 10)
                                  : h['created_at'].toString())
                              : '—'),
                          _td((h['firma'] ?? '—').toString()),
                          _td((h['mashina_raqami'] ?? '—').toString()),
                          _td((h['shofyor'] ?? '—').toString()),
                          _td(h['tara'] != null
                              ? "${(h['tara'] as num).toStringAsFixed(0)} kg"
                              : '—'),
                          _td(h['brutto'] != null
                              ? "${(h['brutto'] as num).toStringAsFixed(0)} kg"
                              : '—'),
                          _td(h['netto'] != null
                              ? "${(h['netto'] as num).toStringAsFixed(0)} kg"
                              : '—'),
                          _tdHolat((h['holat'] ?? 'jarayon').toString()),
                        ],
                      )),
                ],
              ),
            const SizedBox(height: 14),
            if (!yuklanmoqda && hujjatlar.length < jamiHujjatlar)
              Center(
                child: koproqYuklanmoqda
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5)),
                      )
                    : ElevatedButton.icon(
                        onPressed: koproqYukla,
                        icon: const Icon(Icons.expand_more, size: 16),
                        label: Text(
                            "Ko'proq yuklash (${hujjatlar.length}/$jamiHujjatlar)",
                            style: const TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: asosiyRang,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8))),
                      ),
              ),
          ]),
        ),
      ]),
    );
  }
}
