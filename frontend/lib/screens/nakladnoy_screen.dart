import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../services/offline_service.dart';
import '../services/offline_queue_service.dart';
import '../services/fayl_yuklab_olish.dart';

class NakladnoyScreen extends StatefulWidget {
  final String mashinaRaqami;
  final String mashinaTuri;
  final String shofyor;
  final String firma;
  final String mahsulotNomi;
  final String yukNomi;
  final double? tara1;
  final double? brutto1;
  final double? tara2;
  final double? brutto2;
  final double? tara3;
  final double? brutto3;
  final int aravalarSoni;
  final int? hujjatId;
  final String tudaRaqam;
  final String tiketRaqam;
  final String hujjatRaqam;
  final String seleksiyaNavi;
  final String klass;
  final String terimTuri;
  final double? ifloslik;
  final double? namlik;
  final String qabulQildi;
  final String yukOlindi;
  final String dostaverka;
  final String dostaverkaVaqt;
  final double? konditsion1;
  final double? konditsion2;
  final double? konditsion3;
  final String sana;

  const NakladnoyScreen({
    super.key,
    required this.mashinaRaqami,
    required this.mashinaTuri,
    required this.shofyor,
    required this.firma,
    required this.mahsulotNomi,
    this.yukNomi = 'Техник чигит',
    this.tara1,
    this.brutto1,
    this.tara2,
    this.brutto2,
    this.tara3,
    this.brutto3,
    this.aravalarSoni = 1,
    this.hujjatId,
    this.tudaRaqam = '',
    this.tiketRaqam = '',
    this.hujjatRaqam = '',
    this.seleksiyaNavi = 'Xorazm-150',
    this.klass = '1',
    this.terimTuri = 'Kul terim',
    this.ifloslik,
    this.namlik,
    this.qabulQildi = '',
    this.yukOlindi = '',
    this.dostaverka = '',
    this.dostaverkaVaqt = '',
    this.konditsion1,
    this.konditsion2,
    this.konditsion3,
    this.sana = '',
  });

  @override
  State<NakladnoyScreen> createState() => _NakladnoyScreenState();
}

class _NakladnoyScreenState extends State<NakladnoyScreen> {
  bool _yuklanmoqda = false;

  Future<void> _pdfYuklab() async {
    // Ikkinchi-qatlam himoya: odatda operator_panel_screen.dart'dagi
    // hujjatOch() bu ekranga hujjatId hali mahalliy (manfiy, serverga
    // sinxronlanmagan) bo'lganda umuman o'tkazmaydi - lekin kelajakda
    // boshqa chaqiruv joyi qo'shilsa ham, offline navbatga hujjat hali
    // mavjud bo'lmagan ID bilan yozilib qolmasligi uchun shu yerda ham
    // tekshiriladi.
    if (widget.hujjatId != null &&
        OfflineQueueService.yerliIdmi(widget.hujjatId!)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                "⏳ Hujjat hali serverga sinxronlanmagan — aloqa tiklanguncha kuting."),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    setState(() => _yuklanmoqda = true);
    final now = DateTime.now();
    final sana = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    try {
      // Backend endi hujjat_id orqali bazadan (Hujjat+Navbat+Olchov) hamma
      // narsani o'zi to'liq o'qiydi VA javob sifatida tayyor PDF baytlarini
      // qaytaradi - shu sababli bu yerdan faqat hujjat_id va sana
      // yuboriladi, ekran holatidagi boshqa maydonlar yuborilmaydi.
      http.Response? javob;
      try {
        javob = await http.post(
          Uri.parse('${ApiService.baseUrl}/nakladnoy/saqlash'),
          headers: ApiService.authHeaders(),
          body: jsonEncode({
            'hujjat_id': widget.hujjatId,
            'sana': sana,
          }),
        );
      } catch (e) {
        javob = null;
      }

      if (javob != null && javob.statusCode == 200) {
        final raqamQismi =
            (widget.hujjatRaqam.isNotEmpty ? widget.hujjatRaqam : widget.tiketRaqam)
                .replaceAll('/', '-');
        faylniYuklabOl(javob.bodyBytes, 'Nakladnoy_$raqamQismi.pdf', 'application/pdf');
        return;
      }

      if (javob != null && (javob.statusCode == 400 || javob.statusCode == 404)) {
        // Doimiy xato (hujjat_id yo'q/topilmadi) - vaqt o'tishi bilan
        // o'zgarmaydi, offline navbatga qo'yish foydasiz - operatorga
        // to'g'ridan-to'g'ri, aniq xato ko'rsatiladi.
        String xabar = "Hujjat topilmadi — administratorga murojaat qiling";
        try {
          final tanasi = jsonDecode(utf8.decode(javob.bodyBytes));
          if (tanasi is Map && tanasi['detail'] != null) {
            xabar = tanasi['detail'].toString();
          }
        } catch (_) {}
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("❌ $xabar"), backgroundColor: Colors.red),
          );
        }
        return;
      }

      // Bu yergacha yetib kelsa: haqiqiy tarmoq xatosi, 401 (token
      // tugagan) yoki 500 (PDF generatsiya - vaqtinchalik bo'lishi
      // mumkin) - offline navbatga qo'yiladi, fon-sinxronizatsiya
      // keyinroq avtomatik qayta uradi.
      await OfflineService.nakladnoyQosh({
        'mashina_raqami': widget.mashinaRaqami,
        'mahsulot_nomi': widget.mahsulotNomi,
        'sana': sana,
        'tara1': widget.tara1 ?? 0,
        'brutto1': widget.brutto1 ?? 0,
        'hujjat_id': widget.hujjatId,
        'nakladnoy_raqam': widget.hujjatRaqam,
        'firma': widget.firma,
        'mashina_turi': widget.mashinaTuri,
      });
      if (mounted) {
        final xabar = (javob != null && javob.statusCode == 500)
            ? "⚠️ Nakladnoy yaratishda serverda xatolik — birozdan so'ng avtomatik qayta urinilyapti."
            : "⏳ Internet aloqasi yo'q — hujjat navbatga qo'yildi, aloqa tiklangach avtomatik yaratiladi.";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(xabar), backgroundColor: Colors.orange),
        );
      }
    } finally {
      if (mounted) setState(() => _yuklanmoqda = false);
    }
  }

  int tanlanganNusxa = 0;

  double? netto(double? tara, double? brutto) =>
      (tara != null && brutto != null) ? brutto - tara : null;

  String fmt(double? v) => v == null ? "—" : v.toStringAsFixed(0);
  String fmtP(double? v) => v == null ? "—" : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final jamiTara = [widget.tara1, widget.tara2, widget.tara3]
        .take(widget.aravalarSoni)
        .whereType<double>()
        .fold(0.0, (a, b) => a + b);
    final jamiBrutto = [widget.brutto1, widget.brutto2, widget.brutto3]
        .take(widget.aravalarSoni)
        .whereType<double>()
        .fold(0.0, (a, b) => a + b);
    final jamiNetto = jamiBrutto - jamiTara;
    final jamiKonditsion = [widget.konditsion1, widget.konditsion2, widget.konditsion3]
        .take(widget.aravalarSoni)
        .whereType<double>()
        .fold(0.0, (a, b) => a + b);

    final nusxaNomi = ['ЗАВОД НУСХАСИ', 'ШОФЁР НУСХАСИ', 'ОХРАНА НУСХАСИ'];

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4EC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF3A8A1A)),
        title: Text(
          "Tovar Transport Nakladnoy — ${widget.tiketRaqam}",
          style: const TextStyle(color: Color(0xFF0D1B2A), fontSize: 14),
        ),
        actions: [
          ...['Zavod', 'Shofyor', 'Ohrana'].asMap().entries.map((e) {
            final active = tanlanganNusxa == e.key;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: GestureDetector(
                onTap: () => setState(() => tanlanganNusxa = e.key),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: active ? const Color(0xFF1976D2) : const Color(0xFFE3F2FD),
                    border: Border.all(color: const Color(0xFF90CAF9)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(e.value,
                      style: TextStyle(
                          fontSize: 11,
                          color: active ? Colors.white : const Color(0xFF1976D2))),
                ),
              ),
            );
          }),
          const SizedBox(width: 8),
         TextButton.icon(
            onPressed: _yuklanmoqda ? null : _pdfYuklab,
            icon: _yuklanmoqda
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1976D2)))
                : const Icon(Icons.download, size: 18, color: Color(0xFF1976D2)),
            label: const Text("Yuklab olish", style: TextStyle(color: Color(0xFF1976D2))),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            width: 780,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFD0E0C8)),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // NUSXA BELGISI
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1B2A),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    nusxaNomi[tanlanganNusxa],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1),
                  ),
                ),

                // SARLAVHA
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "ТОВАР ТРАНСПОРТ НАКЛАДНОЙ № ${widget.hujjatRaqam.isNotEmpty ? widget.hujjatRaqam : widget.tiketRaqam}",
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0D1B2A)),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Ишлаб чиқаришдан қабул қилинган маҳсулотларни ташиш учун\n${widget.sana}",
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFF3A6A28)),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 160,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFD0E0C8)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Table(
                        border: TableBorder.all(color: const Color(0xFFD0E0C8)),
                        children: [
                          _tableRow("Хусусий", ""),
                          _tableRow(widget.mashinaTuri, ""),
                          _tableRow(widget.mashinaRaqami, ""),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _infoRow("Юк жунатувчи:",
                    "\"Ҳазорасп текстил\" МЧЖга қарашли пахта тозалаш заводи"),
                _infoRow("Юк олувчи:", widget.firma),
                const SizedBox(height: 10),
                const Divider(color: Color(0xFF0D1B2A), thickness: 1),
                const SizedBox(height: 8),

                // TIKET MA'LUMOTLARI
                Row(children: [
                  Expanded(child: _labelVal("Тикет №:", widget.tiketRaqam)),
                  Expanded(child: _labelVal("Сана:", widget.sana)),
                  Expanded(child: _labelVal("Терим тури:", widget.terimTuri)),
                  Expanded(child: _labelVal("Селекция нави:", widget.seleksiyaNavi)),
                ]),
                const SizedBox(height: 6),
                Row(children: [
                  Expanded(child: _labelVal("Туда №:", widget.tudaRaqam)),
                  Expanded(child: _labelVal("Клас:", widget.klass)),
                  Expanded(child: _labelVal("Намлик %:", fmtP(widget.namlik))),
                  Expanded(child: _labelVal("Ифлослик %:", fmtP(widget.ifloslik))),
                ]),
                const SizedBox(height: 12),

                // ASOSIY JADVAL
                Table(
                  border: TableBorder.all(color: const Color(0xFF90CAF9)),
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(1.5),
                    2: FlexColumnWidth(1.5),
                    3: FlexColumnWidth(1.5),
                    4: FlexColumnWidth(1.5),
                  },
                  children: [
                    // HEADER
                    TableRow(
                      decoration: const BoxDecoration(color: Color(0xFF0D1B2A)),
                      children: [
                        _th("Юкнинг номи"),
                        _th("Тара (Урама), кг"),
                        _th("Брутто (Урама б/н), кг"),
                        _th("Нетто (Соф), кг"),
                        _th("Кондицион вазн, кг"),
                      ],
                    ),
                    // 1-ARAVA
                    if (widget.aravalarSoni >= 1)
                      TableRow(children: [
                        _td("${widget.yukNomi}\n(1-арава)"),
                        _td(fmt(widget.tara1)),
                        _td(fmt(widget.brutto1)),
                        _td(fmt(netto(widget.tara1, widget.brutto1))),
                        _td(fmt(widget.konditsion1)),
                      ]),
                    // 2-ARAVA
                    if (widget.aravalarSoni >= 2)
                      TableRow(children: [
                        _td("${widget.yukNomi}\n(2-арава)"),
                        _td(fmt(widget.tara2)),
                        _td(fmt(widget.brutto2)),
                        _td(fmt(netto(widget.tara2, widget.brutto2))),
                        _td(fmt(widget.konditsion2)),
                      ]),
                    // JAMI
                    TableRow(
                      decoration: const BoxDecoration(color: Color(0xFFE3F2FD)),
                      children: [
                        _td("Жами:", bold: true),
                        _td(jamiTara.toStringAsFixed(0), bold: true),
                        _td(jamiBrutto.toStringAsFixed(0), bold: true),
                        _td(jamiNetto.toStringAsFixed(0), bold: true),
                        _td(jamiKonditsion > 0
                            ? jamiKonditsion.toStringAsFixed(0)
                            : "—", bold: true),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // DOSTAVERNA
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    border: Border.all(color: const Color(0xFF90CAF9)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Доставерна № ${widget.dostaverka}",
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1A5A08))),
                      Text("Муддат: ${widget.dostaverkaVaqt}",
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF3A8A1A))),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // SHOFYOR MA'LUMOTLARI
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F8F0),
                    border: Border.all(color: const Color(0xFFD0E0C8)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    Expanded(child: _labelVal("Шофёр:", widget.shofyor)),
                    Expanded(child: _labelVal("Қабул қилди:", widget.qabulQildi)),
                    Expanded(child: _labelVal("Юк олинди:", widget.yukOlindi)),
                  ]),
                ),
                const SizedBox(height: 20),

                // 4 TA IMZO
                Row(children: [
                  Expanded(child: _imzo("Раҳбар")),
                  const SizedBox(width: 16),
                  Expanded(child: _imzo("Шофёр")),
                  const SizedBox(width: 16),
                  Expanded(child: _imzo("Юк олиб кетувчи")),
                  const SizedBox(width: 16),
                  Expanded(child: _imzo("Тарзибон")),
                  const SizedBox(width: 16),
                  // MUHR
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: const Color(0xFF90CAF9), width: 1.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text("М.У.",
                          style: TextStyle(
                              fontSize: 11, color: Color(0xFF90CAF9))),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TableRow _tableRow(String left, String right) {
    return TableRow(children: [
      Padding(
        padding: const EdgeInsets.all(6),
        child: Text(left,
            style: const TextStyle(fontSize: 11, color: Color(0xFF0D1B2A))),
      ),
      Padding(
        padding: const EdgeInsets.all(6),
        child: Text(right,
            style: const TextStyle(fontSize: 11, color: Color(0xFF0D1B2A))),
      ),
    ]);
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0D1B2A))),
        ),
      ]),
    );
  }

  Widget _labelVal(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 4),
      child: Row(children: [
        Text(label,
            style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(width: 4),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0D1B2A))),
        ),
      ]),
    );
  }

  Widget _th(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
        child: Text(text,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.w500)),
      );

  Widget _td(String text, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
        child: Text(text,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 11,
                fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
                color: const Color(0xFF1A3A08))),
      );

  Widget _imzo(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 20),
        Container(height: 1, color: const Color(0xFF0D1B2A)),
        const Text("имзо",
            style: TextStyle(fontSize: 9, color: Colors.grey)),
      ],
    );
  }
}