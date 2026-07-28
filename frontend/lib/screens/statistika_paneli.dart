import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';

/// Statistika bo'limi - operator paneli ichida ishlatiladi. Admin
/// paneldagi Statistika bo'limi bilan bir xil ko'rinish/mantiq, lekin
/// MUSTAQIL widget (admin ekranining State'iga bog'liq emas) - operator
/// har doim BARCHA 4 mahsulotni ko'ra oladi, o'zi ishlayotgan mahsulot
/// bilan cheklanmaydi.
class StatistikaPaneli extends StatefulWidget {
  final bool kechagiRejim;

  const StatistikaPaneli({super.key, this.kechagiRejim = false});

  @override
  State<StatistikaPaneli> createState() => _StatistikaPaneliState();
}

class _StatistikaPaneliState extends State<StatistikaPaneli> {
  // Admin panelidagi _statistika() bilan aniq bir xil (izchillik uchun)
  static const Color asosiyRang = Color(0xFF2A6AB8);
  static const Color kartaBorder = Color(0xFFD8EDD0);
  static const Color muted = Color(0xFF9AC080);
  static const Color goldColor = Color(0xFFC89020);
  // Brend rangi (kirish oqimi, operator va admin paneli bilan izchil)
  static const Color brandGreen = Color(0xFF0F6E56);
  // "Oylik" xulosa kartasi uchun (admin_panel_screen.dart bilan bir xil)
  static const Color oylikRang = Color(0xFF7B5EA7);

  static const List<String> _mahsulotlar = [
    'Chigit', 'Chiganoq', "Chiganoq po'chog'i", 'Patoz'
  ];
  static const List<List<String>> _davrlar = [
    ['kunlik', 'Kunlik'],
    ['haftalik', 'Haftalik'],
    ['oylik', 'Oylik'],
    ['mavsum', 'Mavsum'],
  ];

  String tanlanganMahsulot = 'Chigit';
  String tanlanganDavr = 'kunlik';

  Map<String, dynamic> kunlikStat = {};
  Map<String, dynamic> haftalikStat = {};
  Map<String, dynamic> oylikStat = {};
  Map<String, dynamic> mavsumStat = {};

  List<dynamic> grafikDetalData = [];
  bool statYuklanmoqda = true;
  bool grafikYuklanmoqda = true;
  String? xato;

  @override
  void initState() {
    super.initState();
    statlarniYukla();
    grafikDetalniYukla();
  }

  String _statMahsulotKaliti(String nom) {
    switch (nom) {
      case 'Chigit':
        return 'chigit';
      case 'Chiganoq':
        return 'chiganoq';
      case "Chiganoq po'chog'i":
        return 'pochog';
      case 'Patoz':
        return 'patoz';
      default:
        return 'chigit';
    }
  }

  Future<void> statlarniYukla() async {
    setState(() {
      statYuklanmoqda = true;
      xato = null;
    });
    try {
      final natijalar = await Future.wait([
        ApiService.getKunlikStat(),
        ApiService.getHaftalikStat(),
        ApiService.getOylikStat(),
        ApiService.getMavsumStat(),
      ]);
      if (!mounted) return;
      setState(() {
        kunlikStat = natijalar[0];
        haftalikStat = natijalar[1];
        oylikStat = natijalar[2];
        mavsumStat = natijalar[3];
        statYuklanmoqda = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        statYuklanmoqda = false;
        xato = "Statistika yuklanmadi: $e";
      });
    }
  }

  Future<List<dynamic>> _grafikDetalChaqir(String davr, String mahsulot) {
    switch (davr) {
      case 'haftalik':
        return ApiService.getGrafikDetalHaftalik(mahsulot);
      case 'oylik':
        return ApiService.getGrafikDetalOylik(mahsulot);
      case 'mavsum':
        return ApiService.getGrafikDetalMavsum(mahsulot);
      default:
        return ApiService.getGrafikDetalKunlik(mahsulot);
    }
  }

  Future<void> grafikDetalniYukla() async {
    setState(() => grafikYuklanmoqda = true);
    try {
      final natija = await _grafikDetalChaqir(tanlanganDavr, tanlanganMahsulot);
      if (!mounted) return;
      setState(() {
        grafikDetalData = natija;
        grafikYuklanmoqda = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => grafikYuklanmoqda = false);
    }
  }

  String _grafikDetalLabel(Map<String, dynamic> bucket) {
    switch (tanlanganDavr) {
      case 'haftalik':
        const kunlar = ['', 'Dush', 'Sesh', 'Chor', 'Pay', 'Jum', 'Shan', 'Yak'];
        return kunlar[bucket['kun_raqami'] as int];
      case 'oylik':
        return bucket['kun'].toString();
      case 'mavsum':
        const oylar = ['', 'Yan', 'Fev', 'Mar', 'Apr', 'May', 'Iyun',
          'Iyul', 'Avg', 'Sen', 'Okt', 'Noy', 'Dek'];
        return oylar[bucket['oy'] as int];
      default:
        return bucket['soat'].toString();
    }
  }

  Widget _mahsulotTab(String nom) {
    final active = tanlanganMahsulot == nom;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          setState(() => tanlanganMahsulot = nom);
          grafikDetalniYukla();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: active ? brandGreen : Colors.transparent,
            border: Border.all(color: active ? brandGreen : kartaBorder),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(nom,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  color: active ? Colors.white : muted)),
        ),
      ),
    );
  }

  Widget _davrTab(String kalit, String label) {
    final active = tanlanganDavr == kalit;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          setState(() => tanlanganDavr = kalit);
          grafikDetalniYukla();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: active ? brandGreen : Colors.transparent,
            border: Border.all(color: active ? brandGreen : kartaBorder),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  color: active ? Colors.white : muted)),
        ),
      ),
    );
  }

  Widget _xulosaQatori(String label, String qiymat) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: widget.kechagiRejim ? muted : Colors.grey)),
            Text(qiymat,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: widget.kechagiRejim
                        ? Colors.white
                        : const Color(0xFF0D1B2A))),
          ]),
    );
  }

  Widget _xulosaKartasi(
      String sarlavha, IconData icon, Color rang, Map<String, dynamic> stat) {
    final soni = stat['soni'] ?? 0;
    final tonnaj = stat['tonnaj'] ?? 0;
    final kondicionBormi = stat.containsKey('konditsion');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: widget.kechagiRejim ? const Color(0xFF0F2A0F) : Colors.white,
        border: Border.all(color: kartaBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 16, color: rang),
              const SizedBox(width: 6),
              Expanded(
                  child: Text(sarlavha,
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700, color: rang),
                      overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 10),
            _xulosaQatori("Mashinalar", "$soni ta"),
            _xulosaQatori("Netto", "$tonnaj tonna"),
            if (kondicionBormi)
              _xulosaQatori("Kondicion", "${stat['konditsion']} tonna"),
          ]),
    );
  }

  Widget _grafikChart({
    required String sarlavha,
    required IconData ikonka,
    required Color rang,
    required List<double> qiymatlar,
    required List<String> labellar,
  }) {
    final engKatta = qiymatlar.fold(0.0, (a, b) => a > b ? a : b);
    final maxY = engKatta <= 0 ? 1.0 : engKatta * 1.2;
    final tor = tanlanganDavr == 'kunlik' || tanlanganDavr == 'oylik';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: widget.kechagiRejim ? const Color(0xFF0F2A0F) : Colors.white,
          border: Border.all(color: kartaBorder),
          borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(ikonka, size: 14, color: rang),
          const SizedBox(width: 6),
          Text(sarlavha,
              style: TextStyle(
                  fontSize: 10,
                  color: rang,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: BarChart(BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY,
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, reservedSize: 34,
                  getTitlesWidget: (v, m) => Text(
                      v == v.roundToDouble()
                          ? v.toInt().toString()
                          : v.toStringAsFixed(1),
                      style: TextStyle(
                          fontSize: 9,
                          color: widget.kechagiRejim ? muted : Colors.grey)))),
              bottomTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, reservedSize: 22,
                  getTitlesWidget: (v, m) {
                    final i = v.toInt();
                    if (i < 0 || i >= labellar.length) return const Text('');
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(labellar[i],
                          style: TextStyle(
                              fontSize: 9,
                              color: widget.kechagiRejim ? muted : Colors.grey)),
                    );
                  })),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(show: true,
                getDrawingHorizontalLine: (v) => FlLine(
                    color: widget.kechagiRejim
                        ? const Color(0xFF1E3A1E)
                        : const Color(0xFFE8F4E0),
                    strokeWidth: 1)),
            borderData: FlBorderData(show: false),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (group) => const Color(0xFF0D1B2A),
                getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                    BarTooltipItem(
                  rod.toY == rod.toY.roundToDouble()
                      ? rod.toY.toInt().toString()
                      : rod.toY.toStringAsFixed(2),
                  const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
              ),
            ),
            barGroups: qiymatlar.asMap().entries.map((e) =>
                BarChartGroupData(x: e.key, barRods: [
                  BarChartRodData(
                      toY: e.value,
                      color: rang,
                      width: tor ? 6 : 16,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(3))),
                ])).toList(),
          )),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final joriyKalit = _statMahsulotKaliti(tanlanganMahsulot);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
              color: widget.kechagiRejim
                  ? const Color(0xFF0F2A0F)
                  : Colors.white,
              border: Border.all(color: kartaBorder),
              borderRadius: BorderRadius.circular(12)),
          child: Row(children: _mahsulotlar.map(_mahsulotTab).toList()),
        ),
        const SizedBox(height: 8),
        Row(children: _davrlar.map((d) => _davrTab(d[0], d[1])).toList()),
        const SizedBox(height: 12),
        if (statYuklanmoqda)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (xato != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(child: Text(xato!, style: const TextStyle(color: Colors.red))),
          )
        else
          Column(children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                  child: _xulosaKartasi("Bugun — $tanlanganMahsulot",
                      Icons.today, brandGreen,
                      (kunlikStat[joriyKalit] as Map<String, dynamic>?) ?? {})),
              const SizedBox(width: 10),
              Expanded(
                  child: _xulosaKartasi("Haftalik — $tanlanganMahsulot",
                      Icons.date_range, goldColor,
                      (haftalikStat[joriyKalit] as Map<String, dynamic>?) ?? {})),
            ]),
            const SizedBox(height: 10),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                  child: _xulosaKartasi("Oylik — $tanlanganMahsulot",
                      Icons.calendar_view_month, oylikRang,
                      (oylikStat[joriyKalit] as Map<String, dynamic>?) ?? {})),
              const SizedBox(width: 10),
              Expanded(
                  child: _xulosaKartasi("Mavsum — $tanlanganMahsulot",
                      Icons.calendar_month, asosiyRang,
                      (mavsumStat[joriyKalit] as Map<String, dynamic>?) ?? {})),
            ]),
          ]),
        const SizedBox(height: 12),
        if (grafikYuklanmoqda)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: widget.kechagiRejim
                    ? const Color(0xFF0F2A0F)
                    : Colors.white,
                border: Border.all(color: kartaBorder),
                borderRadius: BorderRadius.circular(16)),
            child: const Center(
                child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 50),
                    child: CircularProgressIndicator())),
          )
        else if (grafikDetalData.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: widget.kechagiRejim
                    ? const Color(0xFF0F2A0F)
                    : Colors.white,
                border: Border.all(color: kartaBorder),
                borderRadius: BorderRadius.circular(16)),
            child: Center(
                child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(children: [
                Icon(Icons.bar_chart, size: 48, color: muted),
                const SizedBox(height: 8),
                Text("Ma'lumot yo'q", style: TextStyle(color: muted)),
              ]),
            )),
          )
        else ...[
          _grafikChart(
            sarlavha: "MASHINALAR SONI",
            ikonka: Icons.local_shipping,
            rang: brandGreen,
            qiymatlar: grafikDetalData
                .map((e) => (e['soni'] as num).toDouble())
                .toList(),
            labellar: grafikDetalData
                .map((e) => _grafikDetalLabel(e as Map<String, dynamic>))
                .toList(),
          ),
          const SizedBox(height: 12),
          _grafikChart(
            sarlavha: "TONNAJ (t)",
            ikonka: Icons.scale,
            rang: goldColor,
            qiymatlar: grafikDetalData
                .map((e) => (e['tonnaj'] as num).toDouble())
                .toList(),
            labellar: grafikDetalData
                .map((e) => _grafikDetalLabel(e as Map<String, dynamic>))
                .toList(),
          ),
        ],
      ]),
    );
  }
}
