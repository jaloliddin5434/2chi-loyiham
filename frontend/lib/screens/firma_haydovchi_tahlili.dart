import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';

/// Firma va haydovchi bo'yicha tahlil - Admin panelidagi Statistika
/// bo'limiga qo'shimcha, mustaqil bo'lim. StatistikaPaneli bilan bir
/// xil andoza (o'z rang o'zgarmaslari, backend'dan davr bo'yicha
/// so'rov) - izchillik uchun.
class FirmaHaydovchiTahlili extends StatefulWidget {
  final bool kechagiRejim;

  const FirmaHaydovchiTahlili({super.key, this.kechagiRejim = false});

  @override
  State<FirmaHaydovchiTahlili> createState() => _FirmaHaydovchiTahliliState();
}

class _FirmaHaydovchiTahliliState extends State<FirmaHaydovchiTahlili> {
  static const Color brandGreen = Color(0xFF0F6E56);
  static const Color kartaBorder = Color(0xFFD8EDD0);
  static const Color muted = Color(0xFF9AC080);
  static const Color goldColor = Color(0xFFC89020);

  static const List<List<String>> _davrlar = [
    ['kunlik', 'Kunlik'],
    ['haftalik', 'Haftalik'],
    ['oylik', 'Oylik'],
    ['mavsum', 'Mavsum'],
  ];
  static const List<String> _turlar = ['Firmalar', 'Haydovchilar'];

  String tanlanganDavr = 'oylik';
  String tanlanganTur = 'Firmalar';

  List<dynamic> royxat = [];
  bool yuklanmoqda = true;
  String? xato;

  @override
  void initState() {
    super.initState();
    _yukla();
  }

  Future<void> _yukla() async {
    setState(() {
      yuklanmoqda = true;
      xato = null;
    });
    try {
      final natija = tanlanganTur == 'Firmalar'
          ? await ApiService.getFirmalarStat(tanlanganDavr)
          : await ApiService.getHaydovchilarStat(tanlanganDavr);
      if (!mounted) return;
      setState(() {
        royxat = natija;
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

  Widget _tanlovTugmasi(String label, bool active, VoidCallback onTap,
      {double fontSize = 12}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: active ? brandGreen : Colors.transparent,
            border: Border.all(color: active ? brandGreen : kartaBorder),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  color: active ? Colors.white : muted)),
        ),
      ),
    );
  }

  Widget _jadval() {
    final cardColor = widget.kechagiRejim ? const Color(0xFF0F2A0F) : Colors.white;
    final matnRang = widget.kechagiRejim ? Colors.white : const Color(0xFF0D1B2A);
    final nomUstuni = tanlanganTur == 'Firmalar' ? 'Firma' : 'Haydovchi';

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        border: Border.all(color: kartaBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
              widget.kechagiRejim ? const Color(0xFF1E3A1E) : const Color(0xFFF3FAF0)),
          columns: [
            DataColumn(label: Text(nomUstuni,
                style: TextStyle(fontWeight: FontWeight.w700, color: matnRang))),
            DataColumn(label: Text('Soni',
                style: TextStyle(fontWeight: FontWeight.w700, color: matnRang)), numeric: true),
            DataColumn(label: Text('Jami tonnaj',
                style: TextStyle(fontWeight: FontWeight.w700, color: matnRang)), numeric: true),
            DataColumn(label: Text('Jami kondicion',
                style: TextStyle(fontWeight: FontWeight.w700, color: matnRang)), numeric: true),
            DataColumn(label: Text("O'rtacha kondicion",
                style: TextStyle(fontWeight: FontWeight.w700, color: matnRang)), numeric: true),
          ],
          rows: royxat.map((r) {
            final m = r as Map<String, dynamic>;
            return DataRow(cells: [
              DataCell(Text(m['nom']?.toString() ?? '', style: TextStyle(color: matnRang))),
              DataCell(Text('${m['soni']}', style: TextStyle(color: matnRang))),
              DataCell(Text('${m['jami_tonnaj']}', style: TextStyle(color: matnRang))),
              DataCell(Text('${m['jami_konditsion']}', style: TextStyle(color: matnRang))),
              DataCell(Text('${m['ortacha_konditsion']}', style: TextStyle(color: matnRang))),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _grafik() {
    final top10 = royxat.take(10).toList();
    final qiymatlar = top10.map((r) => ((r as Map)['jami_tonnaj'] as num).toDouble()).toList();
    final labellar = top10.map((r) {
      final nom = (r as Map)['nom']?.toString() ?? '';
      return nom.length > 10 ? '${nom.substring(0, 10)}…' : nom;
    }).toList();
    final engKatta = qiymatlar.fold(0.0, (a, b) => a > b ? a : b);
    final maxY = engKatta <= 0 ? 1.0 : engKatta * 1.2;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: widget.kechagiRejim ? const Color(0xFF0F2A0F) : Colors.white,
          border: Border.all(color: kartaBorder),
          borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.leaderboard, size: 14, color: goldColor),
          const SizedBox(width: 6),
          Text("TOP 10 — TONNAJ (t)",
              style: TextStyle(
                  fontSize: 10, color: goldColor, letterSpacing: 1, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: BarChart(BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY,
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, reservedSize: 34,
                  getTitlesWidget: (v, m) => Text(
                      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1),
                      style: TextStyle(fontSize: 9, color: widget.kechagiRejim ? muted : Colors.grey)))),
              bottomTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, reservedSize: 46,
                  getTitlesWidget: (v, m) {
                    final i = v.toInt();
                    if (i < 0 || i >= labellar.length) return const Text('');
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Transform.rotate(
                        angle: -0.6,
                        child: Text(labellar[i],
                            style: TextStyle(fontSize: 9, color: widget.kechagiRejim ? muted : Colors.grey)),
                      ),
                    );
                  })),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(show: true,
                getDrawingHorizontalLine: (v) => FlLine(
                    color: widget.kechagiRejim ? const Color(0xFF1E3A1E) : const Color(0xFFE8F4E0),
                    strokeWidth: 1)),
            borderData: FlBorderData(show: false),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (group) => const Color(0xFF0D1B2A),
                getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
                  rod.toY.toStringAsFixed(2),
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
            barGroups: qiymatlar.asMap().entries.map((e) =>
                BarChartGroupData(x: e.key, barRods: [
                  BarChartRodData(
                      toY: e.value, color: goldColor, width: 16,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(3))),
                ])).toList(),
          )),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
              color: widget.kechagiRejim ? const Color(0xFF0F2A0F) : Colors.white,
              border: Border.all(color: kartaBorder),
              borderRadius: BorderRadius.circular(12)),
          child: Row(
              children: _turlar
                  .map((t) => _tanlovTugmasi(t, tanlanganTur == t, () {
                        setState(() => tanlanganTur = t);
                        _yukla();
                      }))
                  .toList()),
        ),
        const SizedBox(height: 8),
        Row(
            children: _davrlar
                .map((d) => _tanlovTugmasi(d[1], tanlanganDavr == d[0], () {
                      setState(() => tanlanganDavr = d[0]);
                      _yukla();
                    }, fontSize: 11))
                .toList()),
        const SizedBox(height: 12),
        if (yuklanmoqda)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (xato != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(child: Text(xato!, style: const TextStyle(color: Colors.red))),
          )
        else if (royxat.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: widget.kechagiRejim ? const Color(0xFF0F2A0F) : Colors.white,
                border: Border.all(color: kartaBorder),
                borderRadius: BorderRadius.circular(16)),
            child: Center(
                child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(children: [
                Icon(Icons.inbox_outlined, size: 48, color: muted),
                const SizedBox(height: 8),
                Text("Ma'lumot yo'q", style: TextStyle(color: muted)),
              ]),
            )),
          )
        else ...[
          _grafik(),
          const SizedBox(height: 12),
          _jadval(),
        ],
      ]),
    );
  }
}
