import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:html' as html;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/api_service.dart';
import '../services/offline_service.dart';

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
  double? _konditsion1;

  @override
  void initState() {
    super.initState();
    _konditsion1 = widget.konditsion1;
    if (widget.hujjatId != null) {
      _yuklaKonditsion();
    }
  }

  Future<void> _yuklaKonditsion() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/olchovlar/${widget.hujjatId}'),
      );
      if (response.statusCode == 200) {
        final olchovlar = jsonDecode(utf8.decode(response.bodyBytes)) as List;
        double jami = 0;
        for (var o in olchovlar) {
          if (o['konditsion'] != null) jami += o['konditsion'];
        }
        if (mounted) setState(() => _konditsion1 = jami);
      }
    } catch (e) {}
  }

  Future<void> _pdfSaqla() async {
    try {
      final htmlContent = _nakladnoyHtml();
      final now = DateTime.now();
      final sana = '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';
      
     try {
        // Backend endi hujjat_id orqali bazadan (Hujjat+Navbat+Olchov) hamma
        // narsani o'zi to'liq o'qiydi - shu sababli bu yerdan faqat hujjat_id
        // va sana yuboriladi, ekran holatidagi boshqa maydonlar yuborilmaydi.
        await html.HttpRequest.request(
          '${ApiService.baseUrl}/nakladnoy/saqlash',
          method: 'POST',
          requestHeaders: ApiService.authHeaders(),
          sendData: jsonEncode({
            'hujjat_id': widget.hujjatId,
            'sana': sana,
          }),
        );
      } catch (e) {
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
      }
      
      // Brauzerda ochish
      final blob = html.Blob([htmlContent], 'text/html');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.window.open(url, '_blank');
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Xato: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _nakladnoyHtml() {
    final t1 = widget.tara1 ?? 0;
    final b1 = widget.brutto1 ?? 0;
    final n1 = b1 - t1;
    final k1 = _konditsion1 ?? widget.konditsion1 ?? 0;
    final t2 = widget.tara2 ?? 0;
    final b2 = widget.brutto2 ?? 0;
    final n2 = b2 - t2;
    final k2 = widget.konditsion2 ?? 0;
    final t3 = widget.tara3 ?? 0;
    final b3 = widget.brutto3 ?? 0;
    final n3 = b3 - t3;
    final k3 = widget.konditsion3 ?? 0;
    final jamiT = t1 + (widget.tara2 != null ? t2 : 0) + (widget.tara3 != null ? t3 : 0);
    final jamiB = b1 + (widget.brutto2 != null ? b2 : 0) + (widget.brutto3 != null ? b3 : 0);
    final jamiN = jamiB - jamiT;
    final jamiK = k1 + (widget.konditsion2 != null ? k2 : 0) + (widget.konditsion3 != null ? k3 : 0);

    String qatorlar = '';
    if (widget.tara1 != null) {
      qatorlar += '''
        <tr>
          <td>${widget.yukNomi}<br><small>(1-arava)</small></td>
          <td>${t1.toStringAsFixed(0)}</td>
          <td>${b1.toStringAsFixed(0)}</td>
          <td>${n1.toStringAsFixed(0)}</td>
          <td>${k1 > 0 ? k1.toStringAsFixed(0) : '—'}</td>
        </tr>''';
    }
    if (widget.tara2 != null) {
      qatorlar += '''
        <tr>
          <td>${widget.yukNomi}<br><small>(2-arava)</small></td>
          <td>${t2.toStringAsFixed(0)}</td>
          <td>${b2.toStringAsFixed(0)}</td>
          <td>${n2.toStringAsFixed(0)}</td>
          <td>${k2 > 0 ? k2.toStringAsFixed(0) : '—'}</td>
        </tr>''';
    }
    if (widget.tara3 != null) {
      qatorlar += '''
        <tr>
          <td>${widget.yukNomi}<br><small>(3-arava)</small></td>
          <td>${t3.toStringAsFixed(0)}</td>
          <td>${b3.toStringAsFixed(0)}</td>
          <td>${n3.toStringAsFixed(0)}</td>
          <td>${k3 > 0 ? k3.toStringAsFixed(0) : '—'}</td>
        </tr>''';
    }

    return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { font-family: Arial, sans-serif; font-size: 11px; background: white; }
  .page { width: 210mm; min-height: 297mm; padding: 10mm; margin: 0 auto; background: white; }
  .header-green { background-color: #1A4A08; color: white; text-align: center; padding: 8px; font-size: 13px; font-weight: bold; border-radius: 4px 4px 0 0; }
  .title { text-align: center; font-size: 13px; font-weight: bold; margin: 8px 0 2px 0; }
  .subtitle { text-align: center; font-size: 11px; color: #333; margin-bottom: 10px; }
  .top-right { float: right; border: 1px solid #ccc; padding: 5px; font-size: 10px; margin-top: -60px; }
  .info-block { margin: 6px 0; font-size: 11px; }
  .divider { border: none; border-top: 1px solid #333; margin: 6px 0; }
  .info-grid { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 4px; margin: 6px 0; font-size: 11px; }
  table { width: 100%; border-collapse: collapse; margin: 8px 0; }
  th { background-color: #1A4A08; color: white; padding: 6px 4px; text-align: center; font-size: 11px; border: 1px solid #1A4A08; }
  td { border: 1px solid #ccc; padding: 6px 4px; text-align: center; font-size: 11px; }
  .jami td { font-weight: bold; background-color: #f5f5f5; }
  .dostaverna { background-color: #E8F5E0; border: 1px solid #B0D890; padding: 6px 10px; margin: 8px 0; font-size: 11px; border-radius: 4px; }
  .sign-block { border: 1px solid #ddd; padding: 8px; margin: 6px 0; border-radius: 4px; }
  .sign-grid { display: grid; grid-template-columns: 1fr 1fr 1fr 1fr; gap: 10px; margin-top: 20px; }
  .sign-item { text-align: center; font-size: 10px; }
  .sign-line { border-bottom: 1px solid #333; margin-bottom: 4px; height: 20px; }
  .sign-label { color: #666; font-size: 9px; }
  .muhur { border: 2px solid #ccc; border-radius: 50%; width: 60px; height: 60px; display: flex; align-items: center; justify-content: center; font-size: 9px; color: #999; margin: 0 auto; }
  @page { size: A4; margin: 0; }
  @media print {
    body { margin: 0; }
    .page { margin: 0; padding: 8mm; }
    * { -webkit-print-color-adjust: exact !important; print-color-adjust: exact !important; }
    th { background-color: #1A4A08 !important; color: white !important; }
    .header-green { background-color: #1A4A08 !important; color: white !important; }
  }
</style>
</head>
<body>
<div class="page">
  <div class="header-green">ЗАВОД НУСХАСИ</div>
  
  <div style="display: flex; justify-content: space-between; align-items: flex-start; margin-top: 8px;">
    <div style="flex: 1;">
      <div class="title">ТОВАР ТРАНСПОРТ НАКЛАДНОЙ № ${widget.hujjatRaqam.isNotEmpty ? widget.hujjatRaqam : widget.tiketRaqam}</div>
      <div class="subtitle">Ishlab chiqarishdan qabul qilingan mahsulotlarni tashish uchun<br>${widget.sana}</div>
    </div>
    <div style="border: 1px solid #ccc; padding: 6px 10px; font-size: 10px; min-width: 120px; text-align: center;">
      <div>Хусусий</div>
      <div>${widget.mashinaTuri}</div>
      <div>${widget.mashinaRaqami}</div>
    </div>
  </div>

  <div class="info-block"><b>Юк жўнатувчи:</b> "Ҳазорасп текстил" МЧЖга қарашли пахта тозалаш завод</div>
  <div class="info-block"><b>Юк олувчи:</b> ${widget.firma}</div>
  <hr class="divider">

  <div class="info-grid">
    <div><b>Тикет №:</b> ${widget.tiketRaqam}</div>
    <div><b>Сана:</b> ${widget.sana}</div>
    <div><b>Терим тури:</b> ${widget.terimTuri}</div>
    <div><b>Туда №:</b> ${widget.tudaRaqam}</div>
    <div><b>Класс:</b> ${widget.klass}</div>
    <div><b>Намлик %:</b> ${widget.namlik ?? '—'}</div>
    <div></div>
    <div></div>
    <div><b>Ифлослик %:</b> ${widget.ifloslik ?? '—'}</div>
  </div>
  <div class="info-block"><b>Селексия нави:</b> ${widget.seleksiyaNavi}</div>

  <table>
    <tr>
      <th>Юкнинг номи</th>
      <th>Тара (Урама), кг</th>
      <th>Брутто (Урама б/н), кг</th>
      <th>Нетто (Соф), кг</th>
      <th>Кондицион вазн, кг</th>
    </tr>
    $qatorlar
    <tr class="jami">
      <td><b>Жами:</b></td>
      <td><b>${jamiT.toStringAsFixed(0)}</b></td>
      <td><b>${jamiB.toStringAsFixed(0)}</b></td>
      <td><b>${jamiN.toStringAsFixed(0)}</b></td>
      <td><b>${jamiK > 0 ? jamiK.toStringAsFixed(0) : '—'}</b></td>
    </tr>
  </table>

  <div style="display: flex; justify-content: space-between;">
    <div class="dostaverna">Доставерна № ${widget.dostaverka}</div>
    <div style="font-size: 10px; padding: 6px;">Муддат: ${widget.dostaverkaVaqt}</div>
  </div>

  <div class="sign-block">
    <div style="font-size: 10px; color: #666;">Шофёр</div>
    <div style="display: flex; justify-content: space-between; margin-top: 4px;">
      <div style="font-size: 10px;">Қабул қилди: <b>${widget.qabulQildi}</b> ___________</div>
      <div style="font-size: 10px;">Юк олинди: <b>${widget.yukOlindi}</b> ___________</div>
    </div>
  </div>

  <div class="sign-grid">
    <div class="sign-item">
      <div class="sign-line"></div>
      <div>Раҳбар</div>
      <div class="sign-label">ИМЗО</div>
    </div>
    <div class="sign-item">
      <div class="sign-line"></div>
      <div>Шофёр</div>
      <div class="sign-label">ИМЗО</div>
    </div>
    <div class="sign-item">
      <div class="sign-line"></div>
      <div>Юк олиб кетувчи</div>
      <div class="sign-label">ИМЗО</div>
    </div>
    <div class="sign-item">
      <div class="muhur">М.Ў</div>
      <div>Таразбон</div>
      <div class="sign-label">ИМЗО</div>
    </div>
  </div>
</div>
</body>
</html>''';
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
            onPressed: () async {
              await _pdfSaqla();
            },
            icon: const Icon(Icons.print, size: 18, color: Color(0xFF1976D2)),
            label: const Text("Chop etish", style: TextStyle(color: Color(0xFF1976D2))),
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