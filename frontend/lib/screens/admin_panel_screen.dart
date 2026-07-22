import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:excel/excel.dart' hide Border;
import 'operator_panel_screen.dart';
import '../services/navbat_service.dart';
import '../services/api_service.dart';

class AdminPanelScreen extends StatefulWidget {
  final String username;
  const AdminPanelScreen({super.key, required this.username});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with TickerProviderStateMixin {

   int tanlanganTab = 0;
  int tanlanganStatTab = 0;
  List<dynamic> dashTonnajChigit = [];
  List<dynamic> dashTonnajChiganoq = [];
  bool dashTonnajYuklanmoqda = false;
  int tanlanganSidebar = 0;
  int tanlanganMahsulotId = 1;
  String sanadan = '';
  String sanagacha = '';
  String nakladnoyFilter = '';
  List<dynamic> backendNavbat = [];
  List<dynamic> backendTugallangan = [];
  Map<String, dynamic> kunlikStat = {};
  Map<String, dynamic> haftalikStat = {};
  Map<String, dynamic> oylikStat = {};
  Map<String, dynamic> mavsumStat = {};
  List<dynamic> kunlikGrafik = [];
  List<dynamic> oylikGrafik = [];
  List<dynamic> mavsumGrafik = [];
  String hozirgiSoat = '';
  Timer? soatTimer;
  Timer? yangilanishTimer;
  Timer? ekranQulfiTimer;
  bool kechagiRejim = false;
  bool serverUlangan = true;
  bool ekranQulflangan = false;
  final qulfParolCtrl = TextEditingController();
  List<dynamic> hujjatlar = [];
  int _joriySahifa = 1;
  int jamiHujjatlar = 0;
  bool koproqYuklanmoqda = false;
  List<dynamic> tahrirTarixiRoyxati = [];
  bool tahrirTarixiYuklanmoqda = false;
  String tanlanganStatMahsulot = 'Chigit';
  String tanlanganStatDavr = 'kunlik';
  List<dynamic> grafikDetalData = [];
  bool grafikDetalYuklanmoqda = false;
  bool yuklanmoqda = true;
  String qidiruv = '';
  String holatFilter = 'hammasi';
  String firmaFilter = 'hammasi';
  String sortTuri = 'raqam';
  bool sortOshib = false;


  final telegramTokenCtrl = TextEditingController();
  final zavodNomiCtrl = TextEditingController(
      text: '"Hazorasp tekstil" MChJ');
  final narxCtrl = TextEditingController();
  double konditsionNarx = 0;

  final yangiLoginCtrl = TextEditingController();
  final yangiParolCtrl = TextEditingController();
  String yangiRol = 'operator';

  List<Map<String, dynamic>> foydalanuvchilar = [
    {
      'login': 'admin',
      'rol': 'Admin',
      'oxirgiKirish': '04.07.2026 08:00',
    },
    {
      'login': 'operator',
      'rol': 'Operator',
      'oxirgiKirish': '04.07.2026 08:15',
    },
  ];

  Map<String, dynamic> serverHolati = {
    'cpu': 45,
    'ram': 62,
    'disk': 38,
    'uptime': '3 kun 14 soat',
  };

  static const Color green = Color(0xFF1565C0);
  static const Color greenLight = Color(0xFF1976D2);
  static const Color greenBg = Color(0xFFEAFADE);
  static const Color greenBorder = Color(0xFFB0D890);
  static const Color cardBorder = Color(0xFFD8EDD0);
  static const Color muted = Color(0xFF9AC080);
  static const Color mutedText = Color(0xFF7AAA5A);
  static const Color goldColor = Color(0xFFC89020);
  static const Color goldBg = Color(0xFFFFF8E0);
  static const Color goldBorder = Color(0xFFF0D070);
  static const Color blueColor = Color(0xFF2A6AB8);
  static const Color blueBg = Color(0xFFE8F0FC);
  static const Color blueBorder = Color(0xFFA0C0E8);
  static const Color redColor = Color(0xFFC03030);
  static const Color redBg = Color(0xFFFFE8E8);
  static const Color redBorder = Color(0xFFE8A0A0);
  static const Color bgPage = Color(0xFFF4F8F0);

  @override
  void initState() {
    super.initState();
    _soatniYanila();
    soatTimer = Timer.periodic(
        const Duration(seconds: 1), (_) => _soatniYanila());
    hujjatlarniYukla();
    _sozlamalarYukla();
    dashboardTonnajniYukla();
    yangilanishTimer = Timer.periodic(
        const Duration(seconds: 3), (_) {
      if (mounted) {
        hujjatlarniYukla();
        _navbatYangilash();
        setState(() {});
      }
    });
    _ekranQulfiTikladir();
    NavbatService.navbat.addListener(_yangilandi);
    NavbatService.tugallanganlar.addListener(_yangilandi);
  }

  void _yangilandi() {
    if (mounted) setState(() {});
  }

  void _soatniYanila() {
    final now = DateTime.now();
    setState(() {
      hozirgiSoat =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
    });
  }

  void _ekranQulfiTikladir() {
    ekranQulfiTimer?.cancel();
    ekranQulfiTimer = Timer(const Duration(hours: 1), () {
      if (mounted) setState(() => ekranQulflangan = true);
    });
  }

  void _faolatBildirildi() => _ekranQulfiTikladir();

  @override
  void dispose() {
    soatTimer?.cancel();
    yangilanishTimer?.cancel();
    ekranQulfiTimer?.cancel();
    qulfParolCtrl.dispose();
    telegramTokenCtrl.dispose();
    zavodNomiCtrl.dispose();
    narxCtrl.dispose();
    yangiLoginCtrl.dispose();
    yangiParolCtrl.dispose();
    NavbatService.navbat.removeListener(_yangilandi);
    NavbatService.tugallanganlar.removeListener(_yangilandi);
    super.dispose();
  }

 Future<void> _navbatYangilash() async {
    try {
      final navbatData = await ApiService.navbatOl();
      final tugallanganData = await ApiService.tugallanganlarOl();
      final kunlik = await http.get(Uri.parse('${ApiService.baseUrl}/statistika/kunlik'), headers: ApiService.authHeaders());
      final haftalik = await http.get(Uri.parse('${ApiService.baseUrl}/statistika/haftalik'), headers: ApiService.authHeaders());
      final oylik = await http.get(Uri.parse('${ApiService.baseUrl}/statistika/oylik'), headers: ApiService.authHeaders());
      final mavsum = await http.get(Uri.parse('${ApiService.baseUrl}/statistika/mavsum'), headers: ApiService.authHeaders());
      if (mounted) {
        setState(() {
          backendNavbat = navbatData;
          backendTugallangan = tugallanganData;
          if (kunlik.statusCode == 200)
            kunlikStat = jsonDecode(utf8.decode(kunlik.bodyBytes));
          if (haftalik.statusCode == 200)
            haftalikStat = jsonDecode(utf8.decode(haftalik.bodyBytes));
         if (oylik.statusCode == 200)
            oylikStat = jsonDecode(utf8.decode(oylik.bodyBytes));
          if (mavsum.statusCode == 200)
            mavsumStat = jsonDecode(utf8.decode(mavsum.bodyBytes));
        });
        final kunlikG = await http.get(Uri.parse('${ApiService.baseUrl}/statistika/grafik/kunlik'), headers: ApiService.authHeaders());
        if (kunlikG.statusCode == 200)
          setState(() => kunlikGrafik = jsonDecode(utf8.decode(kunlikG.bodyBytes)));

        final oylikG = await http.get(Uri.parse('${ApiService.baseUrl}/statistika/grafik/oylik'), headers: ApiService.authHeaders());
        if (oylikG.statusCode == 200)
          setState(() => oylikGrafik = jsonDecode(utf8.decode(oylikG.bodyBytes)));
        final mavsumG = await http.get(Uri.parse('${ApiService.baseUrl}/statistika/grafik/mavsum'), headers: ApiService.authHeaders());
        if (mavsumG.statusCode == 200)
          setState(() => mavsumGrafik = jsonDecode(utf8.decode(mavsumG.bodyBytes)));

        final serverH = await http.get(Uri.parse('${ApiService.baseUrl}/server/holat'), headers: ApiService.authHeaders());
        if (serverH.statusCode == 200)
          setState(() => serverHolati = jsonDecode(utf8.decode(serverH.bodyBytes)));
      }
    } catch (e) {
      print('navbatYangilash xato: $e');
    }
  }
Future<void> _sozlamalarYukla() async {
    try {
      final sozlamalar = await ApiService.sozlamalarOl();
      setState(() {
        if (sozlamalar['konditsion_narx'] != null) {
          konditsionNarx = double.tryParse(sozlamalar['konditsion_narx'].toString()) ?? 0;
          narxCtrl.text = sozlamalar['konditsion_narx'].toString();
        }
        if (sozlamalar['telegram_token'] != null) {
          telegramTokenCtrl.text = sozlamalar['telegram_token'].toString();
        }
      });
    } catch (e) {}
  }

Future<void> hujjatlarniYukla() async {
    try {
      // Davriy avtomatik yangilanish (har 3s) allaqachon "Ko'proq yuklash"
      // orqali ochilgan sahifalarni yo'qotmasligi uchun, hozirgача yuklangan
      // chuqurlikni bitta so'rovda qayta olamiz.
      final natija = await ApiService.getHujjatlar(
        mahsulotId: tanlanganMahsulotId == 0 ? null : tanlanganMahsulotId,
        sahifa: 1,
        sahifaHajmi: 50 * _joriySahifa,
      );
      setState(() {
        hujjatlar = natija['natijalar'] ?? [];
        jamiHujjatlar = natija['jami'] ?? 0;
        yuklanmoqda = false;
        serverUlangan = true;
      });
    } catch (e) {
      setState(() {
        yuklanmoqda = false;
        serverUlangan = false;
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
        sahifa: keyingiSahifa,
        sahifaHajmi: 50,
      );
      final yangilar = (natija['natijalar'] ?? []) as List<dynamic>;
      setState(() {
        hujjatlar.addAll(yangilar);
        jamiHujjatlar = natija['jami'] ?? jamiHujjatlar;
        _joriySahifa = keyingiSahifa;
        koproqYuklanmoqda = false;
      });
    } catch (e) {
      setState(() => koproqYuklanmoqda = false);
    }
  }

  List<dynamic> get filtrlangan {
    var ro = List<dynamic>.from(hujjatlar);
    if (tanlanganMahsulotId != 0) {
      ro = ro.where((h) => h['mahsulot_id'] == tanlanganMahsulotId).toList();
    }
    if (nakladnoyFilter.isNotEmpty) {
      ro = ro.where((h) =>
          (h['raqam'] ?? '').toString().toLowerCase()
              .contains(nakladnoyFilter.toLowerCase())).toList();
    }
    if (sanadan.isNotEmpty) {
      ro = ro.where((h) {
        final sana = (h['created_at'] ?? '').toString().substring(0, 10);
        return sana.compareTo(sanadan) >= 0;
      }).toList();
    }
    if (sanagacha.isNotEmpty) {
      ro = ro.where((h) {
        final sana = (h['created_at'] ?? '').toString().substring(0, 10);
        return sana.compareTo(sanagacha) <= 0;
      }).toList();
    }
    if (qidiruv.isNotEmpty) {
      ro = ro.where((h) {
        final raqam = (h['raqam'] ?? '').toString().toLowerCase();
        final firma = (h['firma'] ?? '').toString().toLowerCase();
        final mashina = (h['mashina_raqami'] ?? '').toString().toLowerCase();
        final shofyor = (h['shofyor'] ?? '').toString().toLowerCase();
        final q = qidiruv.toLowerCase();
        return raqam.contains(q) || firma.contains(q) ||
            mashina.contains(q) || shofyor.contains(q);
      }).toList();
    }
    if (holatFilter != 'hammasi') {
      ro = ro.where((h) => h['holat'] == holatFilter).toList();
    }
    if (firmaFilter != 'hammasi') {
      ro = ro.where((h) =>
          (h['firma'] ?? '').toString() == firmaFilter).toList();
    }
    ro.sort((a, b) {
      String av = '', bv = '';
      if (sortTuri == 'raqam') {
        av = (a['raqam'] ?? '').toString();
        bv = (b['raqam'] ?? '').toString();
      } else if (sortTuri == 'sana') {
        av = (a['created_at'] ?? '').toString();
        bv = (b['created_at'] ?? '').toString();
      } else if (sortTuri == 'firma') {
        av = (a['firma'] ?? '').toString();
        bv = (b['firma'] ?? '').toString();
      }
      return sortOshib ? av.compareTo(bv) : bv.compareTo(av);
    });
    return ro;
  }

  List<String> get firmaRoyxati {
    final firmalar = hujjatlar
        .map((h) => (h['firma'] ?? '').toString())
        .where((f) => f.isNotEmpty)
        .toSet()
        .toList();
    firmalar.sort();
    return firmalar;
  }

  // ============ HELPER WIDGETS ============

  Widget cardLabel(IconData icon, String text, {Color? color}) {
    return Row(children: [
      Icon(icon, size: 14, color: color ?? greenLight),
      const SizedBox(width: 6),
      Text(text, style: TextStyle(
          fontSize: 10,
          color: color ?? mutedText,
          letterSpacing: 1,
          fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _statCard(String label, String value, String sub,
      IconData icon, Color color) {
    final cardColor = kechagiRejim ? const Color(0xFF0F2A0F) : Colors.white;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border.all(color: cardBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Row(children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(child: Text(label,
              style: TextStyle(fontSize: 10,
                  color: kechagiRejim ? muted : Colors.grey),
              overflow: TextOverflow.ellipsis)),
        ]),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: color,
            fontFamily: 'monospace')),
        Text(sub, style: TextStyle(
            fontSize: 10,
            color: kechagiRejim ? muted : Colors.grey)),
      ]),
    );
  }

  Widget _solishtirmaKarta(String label, String bugun,
      String kecha, String hafta) {
    final cardColor = kechagiRejim ? const Color(0xFF0F2A0F) : Colors.white;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: cardColor,
          border: Border.all(color: cardBorder),
          borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Text(label, style: const TextStyle(fontSize: 10, color: muted)),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
          _solishtirmaItem("Bugun", bugun, greenLight),
          Container(width: 1, height: 30, color: cardBorder),
          _solishtirmaItem("Kecha", kecha, blueColor),
          Container(width: 1, height: 30, color: cardBorder),
          _solishtirmaItem("Hafta", hafta, goldColor),
        ]),
      ]),
    );
  }

  Widget _solishtirmaItem(String label, String value, Color color) {
    return Column(children: [
      Text(value, style: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w700, color: color)),
      Text(label, style: const TextStyle(fontSize: 9, color: muted)),
    ]);
  }

  Widget _legend(Color color, String label) {
    return Row(children: [
      Container(width: 10, height: 10,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
    ]);
  }

  Widget _td(String text, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Text(text, style: TextStyle(
          fontSize: 11,
          color: const Color(0xFF0D1B2A),
          fontWeight: bold ? FontWeight.w700 : FontWeight.normal)),
    );
  }

  Widget _tdStatus(String status) {
    Color bg, border, text;
    String label;
    switch (status) {
      case 'bekor':
        bg = const Color(0xFFFFF0F0);
        border = const Color(0xFFF0B0A0);
        text = redColor;
        label = 'Bekor';
        break;
      case 'tugallandi':
        bg = greenBg;
        border = greenBorder;
        text = greenLight;
        label = 'Tugallandi';
        break;
      default:
        bg = goldBg;
        border = goldBorder;
        text = goldColor;
        label = 'Jarayon';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(10)),
        child: Text(label, style: TextStyle(
            fontSize: 10, color: text, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _sortTugma(String turi, String label) {
    final active = sortTuri == turi;
    return GestureDetector(
      onTap: () {
        setState(() {
          if (sortTuri == turi) {
            sortOshib = !sortOshib;
          } else {
            sortTuri = turi;
            sortOshib = false;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? blueColor : Colors.white,
          border: Border.all(color: active ? blueColor : cardBorder),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: TextStyle(
              fontSize: 11,
              color: active ? Colors.white : mutedText,
              fontWeight: FontWeight.w600)),
          if (active) ...[
            const SizedBox(width: 4),
            Icon(sortOshib ? Icons.arrow_upward : Icons.arrow_downward,
                size: 12, color: Colors.white),
          ],
        ]),
      ),
    );
  }

  // ============ DASHBOARD ============
  Widget _dashboard() {
    final cardColor = kechagiRejim ? const Color(0xFF0F2A0F) : Colors.white;
    final navbat = backendNavbat;
    final tugallanganlar = backendTugallangan;
    final joriyStat = [kunlikStat, haftalikStat, oylikStat, mavsumStat][tanlanganTab];
    final davrSuffix = ['ta bugun', 'ta shu hafta', 'ta shu oy', 'ta shu mavsum'][tanlanganTab];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        // TAB BAR
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
              color: cardColor,
              border: Border.all(color: cardBorder),
              borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: ['Kunlik', 'Haftalik', 'Oylik', 'Mavsum']
                .asMap().entries.map((e) {
              final active = tanlanganTab == e.key;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => tanlanganTab = e.key);
                    dashboardTonnajniYukla();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                        color: active ? greenLight : Colors.transparent,
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(e.value,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: active ? Colors.white : mutedText)),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // STAT KARTALARI
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.6,
          children: [
           _statCard("Mashinalar", "${joriyStat['mashinalar_soni'] ?? 0}",
                davrSuffix, Icons.local_shipping, greenLight),
            _statCard("Navbatda", "${navbat.length}",
                "ta kutmoqda", Icons.hourglass_top, goldColor),
            _statCard("Tugallandi", "${joriyStat['tugallanganlar_soni'] ?? 0}",
                davrSuffix, Icons.check_circle, blueColor),
            _statCard("Bekor", "${joriyStat['bekor_soni'] ?? 0}",
                "ta yozuv", Icons.cancel, redColor),
          ],
        ),
        const SizedBox(height: 12),

        // SOLISHTIRMA
        Row(children: [
         Expanded(child: _solishtirmaKarta(
              "Tonnaj (t)",
              "${kunlikStat['jami_tonnaj'] ?? '—'}",
              "${haftalikStat['jami_tonnaj'] ?? '—'}",
              "${oylikStat['jami_tonnaj'] ?? '—'}")),
          const SizedBox(width: 10),
          Expanded(child: _solishtirmaKarta(
              "Konditsion (t)",
              "${kunlikStat['chigit']?['konditsion'] ?? '—'}",
              "${haftalikStat['chigit']?['konditsion'] ?? '—'}",
              "${oylikStat['chigit']?['konditsion'] ?? '—'}")),
        ]),
        const SizedBox(height: 12),

        // NAVBAT VA TUGALLANGAN
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: cardColor,
                  border: Border.all(color: cardBorder),
                  borderRadius: BorderRadius.circular(16)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                  cardLabel(Icons.hourglass_top,
                      "NAVBATDAGI MASHINALAR", color: goldColor),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: goldBg,
                        border: Border.all(color: goldBorder),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text("${navbat.length} ta",
                        style: const TextStyle(
                            fontSize: 11, color: goldColor)),
                  ),
                ]),
                const SizedBox(height: 10),
                if (navbat.isEmpty)
                  Center(child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(children: [
                      Icon(Icons.local_shipping_outlined,
                          size: 32, color: muted),
                      const SizedBox(height: 6),
                      Text("Navbat bo'sh",
                          style: TextStyle(fontSize: 12, color: muted)),
                    ]),
                  ))
                else
                  ...navbat.map((m) => _navbatDashboardItemJson(m)),
              ]),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: cardColor,
                  border: Border.all(color: cardBorder),
                  borderRadius: BorderRadius.circular(16)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                  cardLabel(Icons.check_circle,
                      "TUGALLANGAN MASHINALAR", color: greenLight),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: greenBg,
                        border: Border.all(color: greenBorder),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text("${tugallanganlar.length} ta",
                        style: const TextStyle(
                            fontSize: 11, color: greenLight)),
                  ),
                ]),
                const SizedBox(height: 10),
                if (tugallanganlar.isEmpty)
                  Center(child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(children: [
                      Icon(Icons.done_all, size: 32, color: muted),
                      const SizedBox(height: 6),
                      Text("Hali tugallanmagan",
                          style: TextStyle(fontSize: 12, color: muted)),
                    ]),
                  ))
                else
                  ...tugallanganlar.map(
                      (m) => _tugallanganDashboardItemJson(m)),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 12),

        // GRAFIKLAR
        Row(children: [
          Expanded(child: _mashinaGrafik()),
          const SizedBox(width: 12),
          Expanded(child: _tonnajGrafik()),
        ]),
      ]),
    );
  }

Future<void> _navbatOrqaliHujjatTuzat(Map<String, dynamic> m) async {
    final hujjatId = m['hujjatId'];
    if (hujjatId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Bu mashina uchun hali hujjat yaratilmagan"),
            backgroundColor: Colors.red),
      );
      return;
    }
    final hujjat = await ApiService.getHujjat(hujjatId as int);
    if (!mounted) return;
    if (hujjat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Hujjat ma'lumotini yuklab bo'lmadi"),
            backgroundColor: Colors.red),
      );
      return;
    }
    await hujjatTuzat(hujjat);
  }

void _jsonNavbatOchir(Map<String, dynamic> m) {
    final sababCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Navbatdan o'chirish",
            style: TextStyle(color: Colors.red, fontSize: 14)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text("${m['raqam']} mashinani o'chirasizmi?",
              style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 12),
          TextField(
            controller: sababCtrl,
            decoration: InputDecoration(
              labelText: "Sabab (majburiy) *",
              labelStyle: const TextStyle(color: Colors.red),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              isDense: true,
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Bekor")),
          ElevatedButton(
            onPressed: () async {
              if (sababCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              await ApiService.navbatBekor(m['hujjatId'] ?? 0);
              await _navbatYangilash();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("O'chirildi!"), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("O'chirish", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

 
  Widget _navbatDashboardItemJson(Map<String, dynamic> m) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: goldBg.withValues(alpha: 0.5),
        border: Border.all(color: goldBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        Container(
          width: 22, height: 22,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: goldColor, shape: BoxShape.circle),
          child: const Icon(Icons.local_shipping, size: 12, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(m['raqam'] ?? '—', style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0D1B2A))),
          Text("${m['firma'] ?? '—'} · ${m['vaqt'] ?? '—'}",
              style: const TextStyle(fontSize: 10, color: muted)),
        ])),
        GestureDetector(
          onTap: () => _navbatOrqaliHujjatTuzat(m),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
                color: blueBg,
                border: Border.all(color: blueBorder),
                borderRadius: BorderRadius.circular(6)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.edit, size: 11, color: blueColor),
              SizedBox(width: 3),
              Text("Tuzat", style: TextStyle(fontSize: 9, color: blueColor)),
            ]),
          ),
        ),
        GestureDetector(
          onTap: () => _jsonNavbatOchir(m),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: const Color(0xFFFFF0F0),
                border: Border.all(color: const Color(0xFFF0B0A0)),
                borderRadius: BorderRadius.circular(6)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.delete_outline, size: 11, color: redColor),
              SizedBox(width: 3),
              Text("O'chir", style: TextStyle(fontSize: 9, color: redColor)),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _tugallanganDashboardItemJson(Map<String, dynamic> m) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: greenBg.withValues(alpha: 0.5),
        border: Border.all(color: greenBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 22, height: 22,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: greenLight, shape: BoxShape.circle),
            child: const Icon(Icons.check, size: 12, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m['raqam'] ?? '—', style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0D1B2A))),
            Text("${m['firma'] ?? '—'} · ${m['vaqt'] ?? '—'}",
                style: const TextStyle(fontSize: 10, color: muted)),
          ])),
          GestureDetector(
            onTap: () => _navbatOrqaliHujjatTuzat(m),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                  color: blueBg,
                  border: Border.all(color: blueBorder),
                  borderRadius: BorderRadius.circular(6)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.edit, size: 11, color: blueColor),
                SizedBox(width: 3),
                Text("Tuzat", style: TextStyle(fontSize: 9, color: blueColor)),
              ]),
            ),
          ),
          GestureDetector(
            onTap: () => _jsonNavbatOchir(m),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F0),
                  border: Border.all(color: const Color(0xFFF0B0A0)),
                  borderRadius: BorderRadius.circular(6)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.delete_outline, size: 11, color: redColor),
                SizedBox(width: 3),
                Text("O'chir", style: TextStyle(fontSize: 9, color: redColor)),
              ]),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _navbatDashboardItem(NavbatMashina mashina) {
  return Container(
    margin: const EdgeInsets.only(bottom: 6),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: goldBg.withValues(alpha: 0.5),
      border: Border.all(color: goldBorder),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(children: [
      Container(
        width: 22, height: 22,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
            color: goldColor, shape: BoxShape.circle),
        child: const Icon(Icons.local_shipping,
            size: 12, color: Colors.white),
      ),
      const SizedBox(width: 8),
      Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Text(mashina.raqam, style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0D1B2A))),
        Text("${mashina.firma} · ${mashina.vaqt}",
            style: const TextStyle(fontSize: 10, color: muted)),
      ])),
      GestureDetector(
        onTap: () => _navbatMashinaTuzat(mashina),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(
              color: blueBg,
              border: Border.all(color: blueBorder),
              borderRadius: BorderRadius.circular(6)),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.edit, size: 11, color: blueColor),
            SizedBox(width: 3),
            Text("Tuzat", style: TextStyle(fontSize: 9, color: blueColor)),
          ]),
        ),
      ),
      GestureDetector(
        onTap: () => _navbatMashinaOchir(mashina),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
              color: const Color(0xFFFFF0F0),
              border: Border.all(color: const Color(0xFFF0B0A0)),
              borderRadius: BorderRadius.circular(6)),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.delete_outline, size: 11, color: redColor),
            SizedBox(width: 3),
            Text("O'chir", style: TextStyle(fontSize: 9, color: redColor)),
          ]),
        ),
      ),
    ]),
  );
}

Future<void> _navbatMashinaTuzat(NavbatMashina mashina) async {
  final raqamCtrl = TextEditingController(text: mashina.raqam);
  final firmaCtrl = TextEditingController(text: mashina.firma);
  final shofyorCtrl = TextEditingController(text: mashina.shofyor);
  final tiketCtrl = TextEditingController(text: mashina.tiketRaqam ?? '');
  final tudaCtrl = TextEditingController(text: mashina.tudaRaqam ?? '');
  final klassCtrl = TextEditingController(text: mashina.klass ?? '');
  final sinfCtrl = TextEditingController(text: mashina.sinf ?? '');
  final terimCtrl = TextEditingController(text: mashina.terimTuri ?? '');
  final seleksiyaCtrl = TextEditingController(text: mashina.seleksiyaNavi ?? '');
  final namlikCtrl = TextEditingController(text: mashina.namlik?.toString() ?? '');
  final ifloslikCtrl = TextEditingController(text: mashina.ifloslik?.toString() ?? '');
  final qabulCtrl = TextEditingController(text: mashina.qabulQildi ?? '');
  final yukCtrl = TextEditingController(text: mashina.yukOlindi ?? '');
  final sababCtrl = TextEditingController();

  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(children: [
        const Icon(Icons.edit, color: blueColor, size: 18),
        const SizedBox(width: 8),
        Text("${mashina.raqam} ni tuzatish",
            style: const TextStyle(color: Color(0xFF0D1B2A), fontSize: 14)),
      ]),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // MASHINA
            const Text("MASHINA MA'LUMOTLARI",
                style: TextStyle(fontSize: 9, color: Color(0xFF7AAA5A),
                    letterSpacing: 1, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(child: _tuzatField("Mashina raqami", raqamCtrl)),
              const SizedBox(width: 8),
              Expanded(child: _tuzatField("Shofyor", shofyorCtrl)),
            ]),
            const SizedBox(height: 8),
            _tuzatField("Firma nomi", firmaCtrl),
            const SizedBox(height: 12),

            // HUJJAT
            const Text("HUJJAT MA'LUMOTLARI",
                style: TextStyle(fontSize: 9, color: Color(0xFF7AAA5A),
                    letterSpacing: 1, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(child: _tuzatField("Tiket №", tiketCtrl)),
              const SizedBox(width: 8),
              Expanded(child: _tuzatField("Tuda №", tudaCtrl)),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _tuzatField("Klass", klassCtrl)),
              const SizedBox(width: 8),
              Expanded(child: _tuzatField("Sinf", sinfCtrl)),
            ]),
            const SizedBox(height: 8),
            _tuzatField("Terim turi", terimCtrl),
            const SizedBox(height: 8),
            _tuzatField("Seleksiya navi", seleksiyaCtrl),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _tuzatField("Namlik %", namlikCtrl)),
              const SizedBox(width: 8),
              Expanded(child: _tuzatField("Ifloslik %", ifloslikCtrl)),
            ]),
            const SizedBox(height: 12),

            // DOSTAVERNA
            const Text("DOSTAVERNA",
                style: TextStyle(fontSize: 9, color: Color(0xFF7AAA5A),
                    letterSpacing: 1, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(child: _tuzatField("Qabul qildi", qabulCtrl)),
              const SizedBox(width: 8),
              Expanded(child: _tuzatField("Yuk olindi", yukCtrl)),
            ]),
            const SizedBox(height: 12),

            // SABAB
            _tuzatField("O'zgartirish sababi (majburiy) *",
                sababCtrl, red: true),
          ]),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Bekor")),
        ElevatedButton.icon(
          onPressed: () {
            if (sababCtrl.text.trim().isEmpty) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(
                    content: Text("Sabab kiritish majburiy!"),
                    backgroundColor: Colors.red),
              );
              return;
            }
            NavbatService.navbat.value =
                NavbatService.navbat.value.map((m) {
              if (m.hujjatId == mashina.hujjatId) {
                return NavbatMashina(
                  raqam: raqamCtrl.text,
                  turi: m.turi,
                  shofyor: shofyorCtrl.text,
                  firma: firmaCtrl.text,
                  vaqt: m.vaqt,
                  mahsulotId: m.mahsulotId,
                  mahsulotNomi: m.mahsulotNomi,
                  aravalar: m.aravalar,
                  hujjatId: m.hujjatId,
                  mashinaId: m.mashinaId,
                  kelganVaqt: m.kelganVaqt,
                  tiketRaqam: tiketCtrl.text,
                  tudaRaqam: tudaCtrl.text,
                  klass: klassCtrl.text,
                  sinf: sinfCtrl.text,
                  terimTuri: terimCtrl.text,
                  seleksiyaNavi: seleksiyaCtrl.text,
                  namlik: double.tryParse(namlikCtrl.text),
                  ifloslik: double.tryParse(ifloslikCtrl.text),
                  qabulQildi: qabulCtrl.text,
                  yukOlindi: yukCtrl.text,
                );
              }
              return m;
            }).toList();
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text("Ma'lumotlar yangilandi!"),
                  backgroundColor: Colors.green),
            );
          },
          icon: const Icon(Icons.save, size: 16),
          label: const Text("Saqlash"),
          style: ElevatedButton.styleFrom(
              backgroundColor: greenLight,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8))),
        ),
      ],
    ),
  );
}

Future<void> _navbatMashinaOchir(NavbatMashina mashina) async {
  final sababCtrl = TextEditingController();
  final tasdiqlandi = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text("Mashinani o'chirish",
          style: TextStyle(color: Colors.red, fontSize: 14)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text("${mashina.raqam} mashinani navbatdan o'chirasizmi?",
            style: const TextStyle(fontSize: 13)),
        const SizedBox(height: 12),
        _tuzatField("Sabab (majburiy) *", sababCtrl, red: true),
      ]),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Bekor")),
        ElevatedButton(
          onPressed: () {
            if (sababCtrl.text.trim().isEmpty) return;
            Navigator.pop(ctx, true);
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text("O'chirish",
              style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
  if (tasdiqlandi == true) {
    NavbatService.navbatdanOchir(mashina.hujjatId);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text("Mashina navbatdan o'chirildi!"),
          backgroundColor: Colors.red),
    );
  }
}

Widget _tuzatField(String label, TextEditingController ctrl,
    {bool red = false}) {
  return TextField(
    controller: ctrl,
    style: const TextStyle(fontSize: 12),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
          fontSize: 11, color: red ? Colors.red : Colors.grey),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      isDense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    ),
  );
}

 Widget _tugallanganDashboardItem(NavbatMashina mashina) {
  double? jTara, jBrutto, jNetto, jKond;
  for (var a in mashina.aravalar.values) {
    if (a.tara != null) jTara = (jTara ?? 0) + a.tara!;
    if (a.brutto != null) jBrutto = (jBrutto ?? 0) + a.brutto!;
    if (a.netto != null) jNetto = (jNetto ?? 0) + a.netto!;
    if (a.konditsion != null) jKond = (jKond ?? 0) + a.konditsion!;
  }

  return Container(
    margin: const EdgeInsets.only(bottom: 6),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: greenBg.withValues(alpha: 0.5),
      border: Border.all(color: greenBorder),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          width: 22, height: 22,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
              color: greenLight, shape: BoxShape.circle),
          child: const Icon(Icons.check, size: 12, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text(mashina.raqam, style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0D1B2A))),
          Text("${mashina.firma} · ${mashina.vaqt}",
              style: const TextStyle(fontSize: 10, color: muted)),
        ])),
        // TUZAT TUGMASI
        GestureDetector(
          onTap: () => _navbatMashinaTuzat(mashina),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
                color: blueBg,
                border: Border.all(color: blueBorder),
                borderRadius: BorderRadius.circular(6)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.edit, size: 11, color: blueColor),
              SizedBox(width: 3),
              Text("Tuzat", style: TextStyle(fontSize: 9, color: blueColor)),
            ]),
          ),
        ),
        // O'CHIR TUGMASI
        GestureDetector(
          onTap: () => _navbatMashinaOchir(mashina),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: const Color(0xFFFFF0F0),
                border: Border.all(color: const Color(0xFFF0B0A0)),
                borderRadius: BorderRadius.circular(6)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.delete_outline, size: 11, color: redColor),
              SizedBox(width: 3),
              Text("O'chir", style: TextStyle(fontSize: 9, color: redColor)),
            ]),
          ),
        ),
      ]),
      const SizedBox(height: 6),
      // KG MA'LUMOTLARI
      Row(children: [
        _kgKarta("Tara", jTara, greenLight),
        const SizedBox(width: 4),
        _kgKarta("Brutto", jBrutto, blueColor),
        const SizedBox(width: 4),
        _kgKarta("Netto", jNetto, green),
        const SizedBox(width: 4),
        _kgKarta("Konditsion", jKond, goldColor),
      ]),
    ]),
  );
}

Widget _kgKarta(String label, double? value, Color color) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 9, color: color.withValues(alpha: 0.7))),
        Text(value != null ? "${value.toStringAsFixed(0)} kg" : "—",
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
      ]),
    ),
  );
}

  void _mashinaKor(NavbatMashina mashina) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.local_shipping, color: blueColor, size: 20),
          const SizedBox(width: 8),
          Text(mashina.raqam, style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF0D1B2A),
              fontWeight: FontWeight.w700)),
        ]),
        content: SizedBox(
          width: 400,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _korRow("Firma", mashina.firma),
            _korRow("Shofyor", mashina.shofyor),
            _korRow("Mahsulot", mashina.mahsulotNomi),
            _korRow("Kelgan vaqt", mashina.vaqt),
            _korRow("Holat",
                mashina.tugallandi ? "✅ Tugallandi" : "⏳ Navbatda"),
            const Divider(),
            for (int i = 1; i <= 3; i++)
              if (mashina.aravalar[i]?.tara != null)
                _korRow("$i-arava netto",
                    "${mashina.aravalar[i]?.netto?.toStringAsFixed(0) ?? '—'} kg"),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Yopish")),
        ],
      ),
    );
  }

  Widget _korRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        SizedBox(width: 120,
            child: Text(label, style: const TextStyle(
                fontSize: 12, color: Colors.grey))),
        Expanded(child: Text(value, style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0D1B2A)))),
      ]),
    );
  }
Widget _mashinaGrafik() {
    final cardColor = kechagiRejim ? const Color(0xFF0F2A0F) : Colors.white;
    
    List<dynamic> grafikData = tanlanganStatTab == 0
        ? kunlikGrafik
        : tanlanganStatTab == 1
            ? oylikGrafik
            : mavsumGrafik;

    if (grafikData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: cardColor,
            border: Border.all(color: cardBorder),
            borderRadius: BorderRadius.circular(16)),
        child: const Center(child: Text("Ma'lumot yo'q", style: TextStyle(color: Colors.grey))),
      );
    }

    final List<double> chigitData = grafikData.map((e) => (e['chigit'] as num).toDouble()).toList();
    final List<double> chiganoqData = grafikData.map((e) => (e['chiganoq'] as num).toDouble()).toList();
    final List<String> labellar = grafikData.map((e) {
      if (tanlanganStatTab == 2) {
        final oy = e['oy'].toString();
        return oy.length >= 7 ? oy.substring(5, 7) : oy;
      } else {
        final kun = e['kun'].toString();
        return kun.length >= 10 ? kun.substring(8, 10) : kun;
      }
    }).toList();

    final maxY = [...chigitData, ...chiganoqData].fold(0.0, (a, b) => a > b ? a : b) + 5;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: cardColor,
          border: Border.all(color: cardBorder),
          borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        cardLabel(Icons.bar_chart, "MASHINALAR SONI", color: blueColor),
        const SizedBox(height: 16),
        SizedBox(
          height: 150,
          child: BarChart(BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY,
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, reservedSize: 28,
                  getTitlesWidget: (v, m) => Text(v.toInt().toString(),
                      style: const TextStyle(fontSize: 10, color: Colors.grey)))),
              bottomTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, m) {
                    final i = v.toInt();
                    if (i < 0 || i >= labellar.length) return const Text('');
                    return Text(labellar[i],
                        style: const TextStyle(fontSize: 9, color: Colors.grey));
                  })),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(show: true,
                getDrawingHorizontalLine: (v) => FlLine(
                    color: const Color(0xFFE8F4E0), strokeWidth: 1)),
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
                      fontSize: 12),
                ),
              ),
            ),
            barGroups: chigitData.asMap().entries.map((e) =>
                BarChartGroupData(x: e.key, barRods: [
                  BarChartRodData(
                      toY: e.value,
                      color: greenLight,
                      width: 12,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
                  BarChartRodData(
                      toY: chiganoqData[e.key],
                      color: blueColor,
                      width: 12,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
                ])).toList(),
          )),
        ),
        const SizedBox(height: 8),
        Row(children: [
          Container(width: 10, height: 10, color: greenLight),
          const SizedBox(width: 4),
          const Text("Chigit", style: TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(width: 12),
          Container(width: 10, height: 10, color: blueColor),
          const SizedBox(width: 4),
          const Text("Chiganoq", style: TextStyle(fontSize: 10, color: Colors.grey)),
        ]),
      ]),
    );
  }

  Widget _tonnajGrafik() {
    final cardColor = kechagiRejim ? const Color(0xFF0F2A0F) : Colors.white;
    final davr = _dashDavrlar[tanlanganTab];

    if (dashTonnajYuklanmoqda) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: cardColor,
            border: Border.all(color: cardBorder),
            borderRadius: BorderRadius.circular(16)),
        child: const Center(
            child: Padding(
                padding: EdgeInsets.symmetric(vertical: 50),
                child: CircularProgressIndicator())),
      );
    }
    if (dashTonnajChigit.isEmpty && dashTonnajChiganoq.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: cardColor,
            border: Border.all(color: cardBorder),
            borderRadius: BorderRadius.circular(16)),
        child: const Center(
            child: Padding(
                padding: EdgeInsets.symmetric(vertical: 50),
                child: Text("Ma'lumot yo'q",
                    style: TextStyle(color: Colors.grey)))),
      );
    }

    final chigitData =
        dashTonnajChigit.map((e) => (e['tonnaj'] as num).toDouble()).toList();
    final chiganoqData = dashTonnajChiganoq
        .map((e) => (e['tonnaj'] as num).toDouble())
        .toList();
    final labellar = dashTonnajChigit
        .map((e) => _grafikDetalLabel(e as Map<String, dynamic>, davr))
        .toList();

    final barchaQiymatlar = [...chigitData, ...chiganoqData];
    final engKatta = barchaQiymatlar.fold(0.0, (a, b) => a > b ? a : b);
    final engKichik = barchaQiymatlar.fold(0.0, (a, b) => a < b ? a : b);
    final maxY = engKatta <= 0 ? 1.0 : engKatta * 1.2;
    final minY = engKichik >= 0 ? 0.0 : engKichik * 1.2;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: cardColor,
          border: Border.all(color: cardBorder),
          borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
          cardLabel(Icons.show_chart, "MAHSULOT TONNAJI (t)",
              color: blueColor),
          Row(children: [
            _legend(goldColor, "Chigit"),
            const SizedBox(width: 12),
            _legend(greenLight, "Chiganoq"),
          ]),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          height: 150,
          child: LineChart(LineChartData(
            minY: minY,
            maxY: maxY,
            gridData: FlGridData(show: true,
                getDrawingHorizontalLine: (v) => FlLine(
                    color: const Color(0xFFE8F4E0), strokeWidth: 1)),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, reservedSize: 36,
                  getTitlesWidget: (v, m) => Text(
                      v == v.roundToDouble()
                          ? v.toInt().toString()
                          : v.toStringAsFixed(1),
                      style: const TextStyle(
                          fontSize: 10, color: Colors.grey)))),
              bottomTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, reservedSize: 22,
                  getTitlesWidget: (v, m) {
                    final i = v.toInt();
                    if (i < 0 || i >= labellar.length) return const Text('');
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(labellar[i],
                          style: const TextStyle(fontSize: 9, color: Colors.grey)),
                    );
                  })),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (spot) => const Color(0xFF0D1B2A),
                getTooltipItems: (touchedSpots) => touchedSpots.map((s) =>
                    LineTooltipItem(
                      s.y == s.y.roundToDouble()
                          ? s.y.toInt().toString()
                          : s.y.toStringAsFixed(2),
                      const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    )).toList(),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: chigitData.asMap().entries
                    .map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                isCurved: true, color: goldColor, barWidth: 2,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(show: true,
                    color: goldColor.withValues(alpha: 0.1)),
              ),
              LineChartBarData(
                spots: chiganoqData.asMap().entries
                    .map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                isCurved: true, color: greenLight, barWidth: 2,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(show: true,
                    color: greenLight.withValues(alpha: 0.1)),
              ),
            ],
          )),
        ),
      ]),
    );
  }

  Widget _mahsulotTab(int id, String nom) {
    final active = tanlanganMahsulotId == id;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            tanlanganMahsulotId = id;
            _joriySahifa = 1;
          });
          hujjatlarniYukla();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
              color: active ? greenLight : Colors.transparent,
              borderRadius: BorderRadius.circular(8)),
          child: Text(nom, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                  color: active ? Colors.white : mutedText)),
        ),
      ),
    );
  }

  Future<void> excelYuklaOl() async {
    try {
      final ro = filtrlangan;
      final excel = Excel.createExcel();
      final sheet = excel['Hujjatlar'];
      sheet.appendRow([
        TextCellValue('№'), TextCellValue('Sana'),
        TextCellValue('Mashina'), TextCellValue('Shofyor'),
        TextCellValue('Firma'), TextCellValue('Mahsulot'),
        TextCellValue('Tara (kg)'), TextCellValue('Brutto (kg)'),
        TextCellValue('Netto (kg)'), TextCellValue('Konditsion (kg)'),
        TextCellValue('Holat'),
      ]);
      for (int i = 0; i < ro.length; i++) {
        final h = ro[i];
        sheet.appendRow([
          IntCellValue(i + 1),
          TextCellValue(h['created_at']?.toString().substring(0, 10) ?? '—'),
          TextCellValue(h['mashina_raqami'] ?? '—'),
          TextCellValue(h['shofyor'] ?? '—'),
          TextCellValue(h['firma'] ?? '—'),
          TextCellValue(h['mahsulot_id'] == 1 ? 'Chigit' : h['mahsulot_id'] == 2 ? 'Chiganoq' : "Chig. po'chog'i"),
          DoubleCellValue(h['tara']?.toDouble() ?? 0),
          DoubleCellValue(h['brutto']?.toDouble() ?? 0),
          DoubleCellValue(h['netto']?.toDouble() ?? 0),
          DoubleCellValue(h['konditsion']?.toDouble() ?? 0),
          TextCellValue(h['holat'] ?? '—'),
        ]);
      }
      final bytes = excel.encode()!;
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'hujjatlar.xlsx')
        ..click();
      html.Url.revokeObjectUrl(url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Excel yuklab olindi!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Xato: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ============ HUJJATLAR JADVALI ============
  Widget _hujjatlarJadvali() {
    final cardColor = kechagiRejim ? const Color(0xFF0F2A0F) : Colors.white;
    final ro = filtrlangan;

    return Column(children: [
      Container(
        margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: cardColor,
            border: Border.all(color: cardBorder),
            borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          _mahsulotTab(0, 'Jami'),
          _mahsulotTab(1, 'Chigit'),
          _mahsulotTab(2, 'Chiganoq'),
         _mahsulotTab(3, "Chiganoq po'chog'i"),
          _mahsulotTab(4, 'Patoz'),
        ]),
      ),
      Container(
        margin: const EdgeInsets.fromLTRB(14, 8, 14, 0),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: cardColor,
            border: Border.all(color: cardBorder),
            borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          SizedBox(width: 150, height: 36,
            child: TextField(
              onChanged: (v) => setState(() => nakladnoyFilter = v),
              decoration: InputDecoration(
                hintText: "Nakladnoy №...",
                hintStyle: const TextStyle(fontSize: 11),
                prefixIcon: const Icon(Icons.receipt, size: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 150, height: 36,
            child: TextField(
              onChanged: (v) => setState(() => qidiruv = v),
              decoration: InputDecoration(
                hintText: "Firma, mashina...",
                hintStyle: const TextStyle(fontSize: 11),
                prefixIcon: const Icon(Icons.search, size: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 130, height: 36,
            child: TextField(
              onChanged: (v) => setState(() => sanadan = v),
              decoration: InputDecoration(
                hintText: "Dan: 2026-01-01",
                hintStyle: const TextStyle(fontSize: 11),
                prefixIcon: const Icon(Icons.calendar_today, size: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 130, height: 36,
            child: TextField(
              onChanged: (v) => setState(() => sanagacha = v),
              decoration: InputDecoration(
                hintText: "Gacha: 2026-12-31",
                hintStyle: const TextStyle(fontSize: 11),
                prefixIcon: const Icon(Icons.calendar_today, size: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(border: Border.all(color: cardBorder),
                borderRadius: BorderRadius.circular(8)),
            child: DropdownButton<String>(
              value: firmaFilter, isDense: true, underline: const SizedBox(),
              items: [
                const DropdownMenuItem(value: 'hammasi',
                    child: Text("Barcha firmalar", style: TextStyle(fontSize: 11))),
                ...firmaRoyxati.map((f) => DropdownMenuItem(value: f,
                    child: Text(f, style: const TextStyle(fontSize: 11)))),
              ],
              onChanged: (v) => setState(() => firmaFilter = v ?? 'hammasi'),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(border: Border.all(color: cardBorder),
                borderRadius: BorderRadius.circular(8)),
            child: DropdownButton<String>(
              value: holatFilter, isDense: true, underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'hammasi', child: Text("Hammasi", style: TextStyle(fontSize: 11))),
                DropdownMenuItem(value: 'jarayon', child: Text("Jarayon", style: TextStyle(fontSize: 11))),
                DropdownMenuItem(value: 'tugallandi', child: Text("Tugallandi", style: TextStyle(fontSize: 11))),
                DropdownMenuItem(value: 'bekor', child: Text("Bekor", style: TextStyle(fontSize: 11))),
              ],
              onChanged: (v) => setState(() => holatFilter = v ?? 'hammasi'),
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: excelYuklaOl,
            icon: const Icon(Icons.table_chart, size: 14),
            label: const Text("Excel", style: TextStyle(fontSize: 11)),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF217346),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          ),
          const SizedBox(width: 6),
          ElevatedButton.icon(
            onPressed: hujjatlarniYukla,
            icon: const Icon(Icons.refresh, size: 14),
            label: const Text("Yangilash", style: TextStyle(fontSize: 11)),
            style: ElevatedButton.styleFrom(
                backgroundColor: greenLight,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          ),
        ]),
      ),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: cardColor,
                border: Border.all(color: cardBorder),
                borderRadius: BorderRadius.circular(16)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Jami: ${ro.length} ta hujjat",
                  style: const TextStyle(fontSize: 11, color: muted)),
              const SizedBox(height: 10),
              yuklanmoqda
                  ? const Center(child: CircularProgressIndicator())
                  : ro.isEmpty
                      ? Center(child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Column(children: [
                            Icon(Icons.inbox, size: 48, color: muted),
                            const SizedBox(height: 8),
                            Text("Hujjatlar yo'q", style: TextStyle(color: muted)),
                          ]),
                        ))
                      : Table(
                          border: TableBorder.all(color: const Color(0xFFE0F0D8)),
                          columnWidths: const {
                            0: FlexColumnWidth(0.8),
                            1: FlexColumnWidth(0.9),
                            2: FlexColumnWidth(1.5),
                            3: FlexColumnWidth(1.2),
                            4: FlexColumnWidth(1),
                            5: FlexColumnWidth(0.8),
                            6: FlexColumnWidth(0.8),
                            7: FlexColumnWidth(0.8),
                            8: FlexColumnWidth(1),
                            9: FlexColumnWidth(1.8),
                          },
                          children: [
                            TableRow(
                              decoration: const BoxDecoration(color: Color(0xFF0D1B2A)),
                              children: ['№', 'Sana', 'Firma', 'Mashina',
                                'Shofyor', 'Tara', 'Brutto', 'Netto', 'Holat', 'Amal']
                                  .map((h) => Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                        child: Text(h, style: const TextStyle(
                                            fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600)),
                                      )).toList(),
                            ),
                            ...ro.map((h) => TableRow(
                                  decoration: BoxDecoration(
                                      color: h['holat'] == 'bekor'
                                          ? const Color(0xFFFFF0F0) : Colors.white),
                                  children: [
                                    _td(h['raqam'] ?? '—', bold: true),
                                    _td(h['created_at'] != null
                                        ? h['created_at'].toString().length >= 10
                                            ? h['created_at'].toString().substring(0, 10)
                                            : h['created_at'].toString()
                                        : '—'),
                                    _td(h['firma'] ?? '—'),
                                    _td(h['mashina_raqami'] ?? '—'),
                                    _td(h['shofyor'] ?? '—'),
                                    _td(h['tara'] != null ? "${(h['tara'] as num).toStringAsFixed(0)} kg" : '—'),
                                    _td(h['brutto'] != null ? "${(h['brutto'] as num).toStringAsFixed(0)} kg" : '—'),
                                    _td(h['netto'] != null ? "${(h['netto'] as num).toStringAsFixed(0)} kg" : '—'),
                                    _tdStatus(h['holat'] ?? 'jarayon'),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                                      child: Row(children: [
                                        GestureDetector(
                                          onTap: () => hujjatTuzat(Map<String, dynamic>.from(h)),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                            decoration: BoxDecoration(color: blueBg,
                                                border: Border.all(color: blueBorder),
                                                borderRadius: BorderRadius.circular(6)),
                                            child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                              Icon(Icons.edit, size: 11, color: blueColor),
                                              SizedBox(width: 3),
                                              Text("Tuzat", style: TextStyle(fontSize: 9, color: blueColor)),
                                            ]),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        GestureDetector(
                                          onTap: () => hujjatOchir(h['id']),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                            decoration: BoxDecoration(color: const Color(0xFFFFF0F0),
                                                border: Border.all(color: const Color(0xFFF0B0A0)),
                                                borderRadius: BorderRadius.circular(6)),
                                            child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                              Icon(Icons.delete_outline, size: 11, color: redColor),
                                              SizedBox(width: 3),
                                              Text("O'chir", style: TextStyle(fontSize: 9, color: redColor)),
                                            ]),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        GestureDetector(
                                          onTap: () => hujjatTarixi(
                                              h['id'], h['raqam']?.toString() ?? ''),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                            decoration: BoxDecoration(color: const Color(0xFFF0F0F0),
                                                border: Border.all(color: const Color(0xFFC8C8C8)),
                                                borderRadius: BorderRadius.circular(6)),
                                            child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                              Icon(Icons.history, size: 11, color: Color(0xFF606060)),
                                              SizedBox(width: 3),
                                              Text("Tarix", style: TextStyle(fontSize: 9, color: Color(0xFF606060))),
                                            ]),
                                          ),
                                        ),
                                      ]),
                                    ),
                                  ],
                                )),
                          ],
                        ),
              const SizedBox(height: 14),
              if (hujjatlar.length < jamiHujjatlar)
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
                              backgroundColor: greenLight,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8))),
                        ),
                )
              else if (hujjatlar.isNotEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text("Barchasi yuklandi (${hujjatlar.length}/$jamiHujjatlar)",
                        style: TextStyle(color: muted, fontSize: 11)),
                  ),
                ),
            ]),
          ),
        ),
      ),
    ]);
  }
  Future<void> hujjatTuzat(Map<String, dynamic> hujjat) async {
    final mashinaRaqamiCtrl =
        TextEditingController(text: hujjat['mashina_raqami'] ?? '');
    final shofyorCtrl =
        TextEditingController(text: hujjat['shofyor'] ?? '');
    final firmaCtrl =
        TextEditingController(text: hujjat['firma'] ?? '');
    final tiketCtrl =
        TextEditingController(text: hujjat['tiket_raqam'] ?? '');
    final tudaCtrl =
        TextEditingController(text: hujjat['tuda_raqam'] ?? '');
    final klassCtrl =
        TextEditingController(text: hujjat['klass'] ?? '');
    final sinfCtrl =
        TextEditingController(text: hujjat['sinf'] ?? '');
    final seleksiyaCtrl =
        TextEditingController(text: hujjat['seleksiya_navi'] ?? '');
    final terimCtrl =
        TextEditingController(text: hujjat['terim_turi'] ?? '');
    final qabulCtrl =
        TextEditingController(text: hujjat['qabul_qildi'] ?? '');
    final yukCtrl =
        TextEditingController(text: hujjat['yuk_olindi'] ?? '');
    final namlikCtrl = TextEditingController();
    final ifloslikCtrl = TextEditingController();
    final sababCtrl = TextEditingController();
    String yangiHolat = hujjat['holat'] ?? 'jarayon';

    Widget field(String label, TextEditingController ctrl,
        {TextInputType? type}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TextField(
          controller: ctrl,
          keyboardType: type,
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(fontSize: 11, color: Colors.grey),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8)),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 8),
          ),
        ),
      );
    }

    Widget readOnly(String label, String value, Color color) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F8F0),
            border: Border.all(color: const Color(0xFFD8EDD0)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(children: [
            const Icon(Icons.lock_outline,
                size: 12, color: Colors.grey),
            const SizedBox(width: 6),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(label, style: const TextStyle(
                  fontSize: 9, color: Colors.grey)),
              Text(value, style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color)),
            ])),
          ]),
        ),
      );
    }

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Row(children: [
            const Icon(Icons.edit, color: blueColor, size: 18),
            const SizedBox(width: 8),
            Text("Hujjat ${hujjat['raqam']} ni tuzatish",
                style: const TextStyle(
                    color: Color(0xFF0D1B2A), fontSize: 14)),
          ]),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F8F0),
                    border: Border.all(
                        color: const Color(0xFFD8EDD0)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const Row(children: [
                      Icon(Icons.lock_outline,
                          size: 12, color: Colors.grey),
                      SizedBox(width: 4),
                      Text("O'ZGARTIRIB BO'LMAYDI",
                          style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey,
                              letterSpacing: 1)),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: readOnly("Tara",
                          "${hujjat['tara'] ?? '—'} kg", greenLight)),
                      const SizedBox(width: 8),
                      Expanded(child: readOnly("Brutto",
                          "${hujjat['brutto'] ?? '—'} kg", blueColor)),
                      const SizedBox(width: 8),
                      Expanded(child: readOnly("Netto",
                          "${hujjat['netto'] ?? '—'} kg", green)),
                      const SizedBox(width: 8),
                      Expanded(child: readOnly("Konditsion",
                          "${hujjat['konditsion'] ?? '—'} kg",
                          goldColor)),
                    ]),
                  ]),
                ),
                const Text("MASHINA MA'LUMOTLARI",
                    style: TextStyle(fontSize: 9,
                        color: Color(0xFF7AAA5A), letterSpacing: 1)),
                const SizedBox(height: 6),
                Row(children: [
                  Expanded(child: field("Mashina raqami",
                      mashinaRaqamiCtrl)),
                  const SizedBox(width: 8),
                  Expanded(child: field("Shofyor", shofyorCtrl)),
                ]),
                field("Firma nomi", firmaCtrl),
                const SizedBox(height: 4),
                const Text("HUJJAT MA'LUMOTLARI",
                    style: TextStyle(fontSize: 9,
                        color: Color(0xFF7AAA5A), letterSpacing: 1)),
                const SizedBox(height: 6),
                Row(children: [
                  Expanded(child: field("Tiket raqami", tiketCtrl)),
                  const SizedBox(width: 8),
                  Expanded(child: field("Tuda №", tudaCtrl)),
                ]),
                Row(children: [
                  Expanded(child: field("Klass", klassCtrl)),
                  const SizedBox(width: 8),
                  Expanded(child: field("Sinf", sinfCtrl)),
                ]),
                Row(children: [
                  Expanded(child: field("Seleksiya navi",
                      seleksiyaCtrl)),
                  const SizedBox(width: 8),
                  Expanded(child: field("Terim turi", terimCtrl)),
                ]),
                Row(children: [
                  Expanded(child: field("Qabul qildi", qabulCtrl)),
                  const SizedBox(width: 8),
                  Expanded(child: field("Yuk olindi", yukCtrl)),
                ]),
                const SizedBox(height: 4),
                const Text("SIFAT KO'RSATKICHLARI",
                    style: TextStyle(fontSize: 9,
                        color: Color(0xFF7AAA5A), letterSpacing: 1)),
                const SizedBox(height: 6),
                Row(children: [
                  Expanded(child: field("Namlik %", namlikCtrl,
                      type: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: field("Ifloslik %", ifloslikCtrl,
                      type: TextInputType.number)),
                ]),
                const Text(
                    "Bo'sh qoldirilsa o'zgartirilmaydi. To'ldirilsa, "
                    "bu qiymat hujjatdagi BARCHA aravalarga qo'llanadi.",
                    style: TextStyle(fontSize: 10, color: Colors.grey)),
                const SizedBox(height: 8),
                const Text("HOLAT",
                    style: TextStyle(fontSize: 9,
                        color: Color(0xFF7AAA5A), letterSpacing: 1)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: yangiHolat,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'jarayon',
                        child: Text("Jarayon")),
                    DropdownMenuItem(value: 'tugallandi',
                        child: Text("Tugallandi")),
                    DropdownMenuItem(value: 'bekor',
                        child: Text("Bekor qilindi")),
                  ],
                  onChanged: (v) => setDlgState(
                      () => yangiHolat = v ?? yangiHolat),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: sababCtrl,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    labelText: "O'zgartirish sababi (majburiy) *",
                    labelStyle: const TextStyle(
                        fontSize: 11, color: Colors.red),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                  ),
                ),
              ]),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Bekor qilish")),
            ElevatedButton.icon(
              onPressed: () async {
                final payload = <String, dynamic>{
                  'holat': yangiHolat,
                  'mashina_raqami': mashinaRaqamiCtrl.text,
                  'shofyor': shofyorCtrl.text,
                  'firma': firmaCtrl.text,
                  'tiket_raqam': tiketCtrl.text,
                  'tuda_raqam': tudaCtrl.text,
                  'klass': klassCtrl.text,
                  'sinf': sinfCtrl.text,
                  'seleksiya_navi': seleksiyaCtrl.text,
                  'terim_turi': terimCtrl.text,
                  'qabul_qildi': qabulCtrl.text,
                  'yuk_olindi': yukCtrl.text,
                  'sabab': sababCtrl.text.trim(),
                };
                final namlikQiymat =
                    double.tryParse(namlikCtrl.text.trim());
                if (namlikQiymat != null) {
                  payload['namlik'] = namlikQiymat;
                }
                final ifloslikQiymat =
                    double.tryParse(ifloslikCtrl.text.trim());
                if (ifloslikQiymat != null) {
                  payload['ifloslik'] = ifloslikQiymat;
                }
                if (yangiHolat == 'bekor') {
                  payload['bekor_sabab'] = sababCtrl.text.trim();
                }

                bool muvaffaqiyatli = false;
                String? xatoMatni;
                try {
                  final javob = await http.put(
                    Uri.parse(
                        '${ApiService.baseUrl}/hujjatlar/${hujjat['id']}'),
                    headers: ApiService.authHeaders(),
                    body: jsonEncode(payload),
                  );
                  muvaffaqiyatli = javob.statusCode == 200;
                  if (!muvaffaqiyatli) {
                    try {
                      final govda = jsonDecode(
                          utf8.decode(javob.bodyBytes));
                      final detail = govda['detail'];
                      if (detail is String) {
                        xatoMatni = detail;
                      } else if (detail is List &&
                          detail.isNotEmpty) {
                        xatoMatni = detail
                            .map((d) => d is Map
                                ? (d['msg'] ?? d.toString())
                                : d.toString())
                            .join(', ');
                      }
                    } catch (_) {}
                  }
                } catch (e) {}
                if (!muvaffaqiyatli) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                        content: Text(xatoMatni ??
                            "Saqlashda xatolik yuz berdi!"),
                        backgroundColor: Colors.red),
                  );
                  return;
                }
                setState(() {
                  final index = hujjatlar
                      .indexWhere((h) => h['id'] == hujjat['id']);
                  if (index != -1) {
                    hujjatlar[index]['holat'] = yangiHolat;
                    hujjatlar[index]['mashina_raqami'] =
                        mashinaRaqamiCtrl.text;
                    hujjatlar[index]['shofyor'] = shofyorCtrl.text;
                    hujjatlar[index]['firma'] = firmaCtrl.text;
                    hujjatlar[index]['tiket_raqam'] = tiketCtrl.text;
                    hujjatlar[index]['tuda_raqam'] = tudaCtrl.text;
                    hujjatlar[index]['klass'] = klassCtrl.text;
                    hujjatlar[index]['sinf'] = sinfCtrl.text;
                    hujjatlar[index]['seleksiya_navi'] =
                        seleksiyaCtrl.text;
                    hujjatlar[index]['terim_turi'] = terimCtrl.text;
                    hujjatlar[index]['qabul_qildi'] = qabulCtrl.text;
                    hujjatlar[index]['yuk_olindi'] = yukCtrl.text;
                  }
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Hujjat yangilandi!"),
                      backgroundColor: Colors.green),
                );
              },
              icon: const Icon(Icons.save, size: 16),
              label: const Text("Saqlash"),
              style: ElevatedButton.styleFrom(
                  backgroundColor: greenLight,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> hujjatOchir(int id) async {
    final sababCtrl2 = TextEditingController();
    final tasdiqlandi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text("O'chirishni tasdiqlang",
            style: TextStyle(color: Colors.red, fontSize: 14)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text("Bu hujjatni o'chirishni xohlaysizmi?",
              style: TextStyle(fontSize: 13)),
          const SizedBox(height: 12),
          TextField(
            controller: sababCtrl2,
            decoration: InputDecoration(
              labelText: "Sabab (majburiy)",
              labelStyle: const TextStyle(color: Colors.red),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8)),
              isDense: true,
            ),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Bekor")),
          ElevatedButton(
            onPressed: () {
              if (sababCtrl2.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red),
            child: const Text("O'chirish",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (tasdiqlandi == true) {
      bool muvaffaqiyatli = false;
      try {
        final javob = await http.put(
          Uri.parse('${ApiService.baseUrl}/hujjatlar/$id'),
          headers: ApiService.authHeaders(),
          body: jsonEncode({
            'holat': 'bekor',
            'bekor_sabab': sababCtrl2.text.trim(),
          }),
        );
        muvaffaqiyatli = javob.statusCode == 200;
      } catch (e) {}
      if (!mounted) return;
      if (muvaffaqiyatli) {
        setState(
            () => hujjatlar.removeWhere((h) => h['id'] == id));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Hujjat o'chirildi!"),
              backgroundColor: Colors.red),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("O'chirishda xatolik yuz berdi!"),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> hujjatTarixi(int hujjatId, String hujjatRaqam) async {
    final yozuvlar = await ApiService.getTahrirTarixi(hujjatId);
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.history, color: Color(0xFF606060), size: 18),
          const SizedBox(width: 8),
          Text("Hujjat $hujjatRaqam tarixi",
              style: const TextStyle(
                  color: Color(0xFF0D1B2A), fontSize: 14)),
        ]),
        content: SizedBox(
          width: 480,
          height: 400,
          child: yozuvlar.isEmpty
              ? const Center(
                  child: Text("Hali hech qanday o'zgarish yo'q",
                      style: TextStyle(
                          color: Colors.grey, fontSize: 12)))
              : ListView.separated(
                  itemCount: yozuvlar.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 16),
                  itemBuilder: (_, i) {
                    final y = yozuvlar[i] as Map<String, dynamic>;
                    final vaqtStr = y['vaqt']?.toString() ?? '';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(y['maydon']?.toString() ?? '',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0D1B2A))),
                          const Spacer(),
                          Text(
                              vaqtStr.length >= 16
                                  ? vaqtStr.substring(0, 16)
                                  : vaqtStr,
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.grey)),
                        ]),
                        const SizedBox(height: 3),
                        Row(children: [
                          Expanded(
                              child: Text(
                                  "${y['eski_qiymat'] ?? '—'}",
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.red,
                                      decoration:
                                          TextDecoration.lineThrough))),
                          const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6),
                              child: Icon(Icons.arrow_forward,
                                  size: 12, color: Colors.grey)),
                          Expanded(
                              child: Text(
                                  "${y['yangi_qiymat'] ?? '—'}",
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF1976D2),
                                      fontWeight: FontWeight.w600))),
                        ]),
                        if ((y['sabab'] ?? '')
                            .toString()
                            .isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text("Sabab: ${y['sabab']}",
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF444444))),
                        ],
                        const SizedBox(height: 3),
                        Text(
                            "${y['ozgartirgan_username'] ?? '—'} tomonidan",
                            style: const TextStyle(
                                fontSize: 10, color: Colors.grey)),
                      ],
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Yopish")),
        ],
      ),
    );
  }

  Future<void> tahrirTarixiniYukla() async {
    setState(() => tahrirTarixiYuklanmoqda = true);
    final natija = await ApiService.getBarchaTahrirTarixi(limit: 100);
    if (!mounted) return;
    setState(() {
      tahrirTarixiRoyxati = natija;
      tahrirTarixiYuklanmoqda = false;
    });
  }

// ============ TAHRIRLAR TARIXI ============
  Widget _tahrirlarTarixi() {
    final cardColor = kechagiRejim ? const Color(0xFF0F2A0F) : Colors.white;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.history, size: 16, color: Color(0xFF606060)),
            const SizedBox(width: 6),
            const Text("Tahrirlar tarixi (oxirgi 100 ta)",
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              onPressed: tahrirTarixiniYukla,
              tooltip: "Yangilash",
            ),
          ]),
          const SizedBox(height: 10),
          if (tahrirTarixiYuklanmoqda)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (tahrirTarixiRoyxati.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                  child: Text("Hali hech qanday o'zgarish yo'q",
                      style: TextStyle(
                          color: Colors.grey, fontSize: 13))),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cardBorder),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(12),
                itemCount: tahrirTarixiRoyxati.length,
                separatorBuilder: (_, __) => const Divider(height: 18),
                itemBuilder: (_, i) {
                  final y = tahrirTarixiRoyxati[i]
                      as Map<String, dynamic>;
                  final vaqtStr = y['vaqt']?.toString() ?? '';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: blueBg,
                              borderRadius:
                                  BorderRadius.circular(4)),
                          child: Text(
                              y['hujjat_raqam']?.toString() ?? '—',
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: blueColor,
                                  fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 8),
                        Text(y['maydon']?.toString() ?? '',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                        const Spacer(),
                        Text(
                            vaqtStr.length >= 16
                                ? vaqtStr.substring(0, 16)
                                : vaqtStr,
                            style: const TextStyle(
                                fontSize: 10, color: Colors.grey)),
                      ]),
                      const SizedBox(height: 3),
                      Row(children: [
                        Expanded(
                            child: Text(
                                "${y['eski_qiymat'] ?? '—'}",
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.red,
                                    decoration: TextDecoration
                                        .lineThrough))),
                        const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6),
                            child: Icon(Icons.arrow_forward,
                                size: 12, color: Colors.grey)),
                        Expanded(
                            child: Text(
                                "${y['yangi_qiymat'] ?? '—'}",
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF1976D2),
                                    fontWeight: FontWeight.w600))),
                      ]),
                      if ((y['sabab'] ?? '')
                          .toString()
                          .isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text("Sabab: ${y['sabab']}",
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF444444))),
                      ],
                      const SizedBox(height: 3),
                      Text(
                          "${y['ozgartirgan_username'] ?? '—'} tomonidan",
                          style: const TextStyle(
                              fontSize: 10, color: Colors.grey)),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

// ============ STATISTIKA ============
  static const List<String> _statMahsulotlar = [
    'Chigit', 'Chiganoq', "Chiganoq po'chog'i", 'Patoz'
  ];
  static const List<List<String>> _statDavrlar = [
    ['kunlik', 'Kunlik'],
    ['haftalik', 'Haftalik'],
    ['oylik', 'Oylik'],
    ['mavsum', 'Mavsum'],
  ];

  static const List<String> _dashDavrlar = ['kunlik', 'haftalik', 'oylik', 'mavsum'];

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
    setState(() => grafikDetalYuklanmoqda = true);
    final natija = await _grafikDetalChaqir(tanlanganStatDavr, tanlanganStatMahsulot);
    if (!mounted) return;
    setState(() {
      grafikDetalData = natija;
      grafikDetalYuklanmoqda = false;
    });
  }

  Future<void> dashboardTonnajniYukla() async {
    setState(() => dashTonnajYuklanmoqda = true);
    final davr = _dashDavrlar[tanlanganTab];
    final natijalar = await Future.wait([
      _grafikDetalChaqir(davr, 'Chigit'),
      _grafikDetalChaqir(davr, 'Chiganoq'),
    ]);
    if (!mounted) return;
    setState(() {
      dashTonnajChigit = natijalar[0];
      dashTonnajChiganoq = natijalar[1];
      dashTonnajYuklanmoqda = false;
    });
  }

  String _grafikDetalLabel(Map<String, dynamic> bucket, [String? davr]) {
    switch (davr ?? tanlanganStatDavr) {
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

  Widget _grafikDetalChart({
    required String sarlavha,
    required IconData ikonka,
    required Color rang,
    required List<double> qiymatlar,
    required List<String> labellar,
  }) {
    final cardColor = kechagiRejim ? const Color(0xFF0F2A0F) : Colors.white;
    final engKatta = qiymatlar.fold(0.0, (a, b) => a > b ? a : b);
    final maxY = engKatta <= 0 ? 1.0 : engKatta * 1.2;
    final tor = tanlanganStatDavr == 'kunlik' || tanlanganStatDavr == 'oylik';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: cardColor,
          border: Border.all(color: cardBorder),
          borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        cardLabel(ikonka, sarlavha, color: rang),
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
                      style: const TextStyle(fontSize: 9, color: Colors.grey)))),
              bottomTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, reservedSize: 22,
                  getTitlesWidget: (v, m) {
                    final i = v.toInt();
                    if (i < 0 || i >= labellar.length) return const Text('');
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(labellar[i],
                          style: const TextStyle(fontSize: 9, color: Colors.grey)),
                    );
                  })),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(show: true,
                getDrawingHorizontalLine: (v) => FlLine(
                    color: const Color(0xFFE8F4E0), strokeWidth: 1)),
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

  Widget _statistika() {
    final cardColor = kechagiRejim ? const Color(0xFF0F2A0F) : Colors.white;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(children: [
       // MAHSULOT TABLARI
        Row(children: [
          ..._statMahsulotlar.map((nom) {
            final active = tanlanganStatMahsulot == nom;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() => tanlanganStatMahsulot = nom);
                  grafikDetalniYukla();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: active ? blueColor : Colors.transparent,
                    border: Border.all(color: active ? blueColor : cardBorder),
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
          }),
        ]),
        const SizedBox(height: 8),
        // DAVR TABLARI
        Row(children: [
          ..._statDavrlar.map((d) {
            final active = tanlanganStatDavr == d[0];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() => tanlanganStatDavr = d[0]);
                  grafikDetalniYukla();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: active ? greenLight : Colors.transparent,
                    border: Border.all(color: active ? greenLight : cardBorder),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(d[1],
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                          color: active ? Colors.white : muted)),
                ),
              ),
            );
          }),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _statCard("Bugun mashinalar",
              "${kunlikStat['mashinalar_soni'] ?? 0}", "ta",
              Icons.local_shipping, greenLight)),
          const SizedBox(width: 10),
          Expanded(child: _statCard("Bugun tonnaj",
              "${kunlikStat['jami_tonnaj'] ?? 0}", "tonna",
              Icons.scale, goldColor)),
          const SizedBox(width: 10),
          Expanded(child: _statCard("Hafta mashinalar",
              "${haftalikStat['mashinalar_soni'] ?? 0}", "ta",
              Icons.local_shipping, blueColor)),
          const SizedBox(width: 10),
          Expanded(child: _statCard("Hafta tonnaj",
              "${haftalikStat['jami_tonnaj'] ?? 0}", "tonna",
              Icons.scale, redColor)),
        ]),
        const SizedBox(height: 12),
        if (grafikDetalYuklanmoqda)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: cardColor,
                border: Border.all(color: cardBorder),
                borderRadius: BorderRadius.circular(16)),
            child: const Center(
                child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 50),
                    child: CircularProgressIndicator())),
          )
        else if (grafikDetalData.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: cardColor,
                border: Border.all(color: cardBorder),
                borderRadius: BorderRadius.circular(16)),
            child: const Center(
                child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 50),
                    child: Text("Ma'lumot yo'q",
                        style: TextStyle(color: Colors.grey)))),
          )
        else ...[
          _grafikDetalChart(
            sarlavha: "MASHINALAR SONI",
            ikonka: Icons.local_shipping,
            rang: blueColor,
            qiymatlar: grafikDetalData
                .map((e) => (e['soni'] as num).toDouble())
                .toList(),
            labellar: grafikDetalData
                .map((e) => _grafikDetalLabel(e as Map<String, dynamic>))
                .toList(),
          ),
          const SizedBox(height: 12),
          _grafikDetalChart(
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

  // ============ FOYDALANUVCHILAR ============
  Widget _foydalanuvchilar() {
    final cardColor = kechagiRejim ? const Color(0xFF0F2A0F) : Colors.white;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: cardColor,
            border: Border.all(color: cardBorder),
            borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Row(children: [
            cardLabel(Icons.people_outline, "FOYDALANUVCHILAR",
                color: blueColor),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => _yangiiFoydalanuvchiQosh(),
              icon: const Icon(Icons.person_add, size: 14),
              label: const Text("Yangi qo'shish",
                  style: TextStyle(fontSize: 11)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: greenLight,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))),
            ),
          ]),
          const SizedBox(height: 14),
          ...foydalanuvchilar.map((f) => _foydalanuvchiKarta(f)),
        ]),
      ),
    );
  }

  Widget _foydalanuvchiKarta(Map<String, dynamic> f) {
    final parolCtrl2 = TextEditingController();
    final parol2Ctrl = TextEditingController();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: const Color(0xFFF4F8F0),
          border: Border.all(color: cardBorder),
          borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        CircleAvatar(
          radius: 22,
          backgroundColor:
              f['rol'] == 'Admin' ? blueColor : greenLight,
          child: Text(f['rol'] == 'Admin' ? "AD" : "OP",
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text(f['rol'], style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0D1B2A))),
          Text("Login: ${f['login']}",
              style: const TextStyle(fontSize: 11, color: muted)),
          Text("Oxirgi kirish: ${f['oxirgiKirish']}",
              style: const TextStyle(fontSize: 10, color: muted)),
        ])),
        ElevatedButton.icon(
          onPressed: () async {
            await showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: Text("${f['rol']} parolini o'zgartirish",
                    style: const TextStyle(
                        color: Color(0xFF0D1B2A), fontSize: 14)),
                content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                  TextField(
                    controller: parolCtrl2,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Yangi parol",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: parol2Ctrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Parolni tasdiqlang",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                  ),
                ]),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("Bekor")),
                  ElevatedButton(
                    onPressed: () {
                      if (parolCtrl2.text != parol2Ctrl.text) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                              content:
                                  Text("Parollar mos kelmaydi!"),
                              backgroundColor: Colors.red),
                        );
                        return;
                      }
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                "${f['rol']} paroli o'zgartirildi!"),
                            backgroundColor: Colors.green),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: greenLight),
                    child: const Text("Saqlash",
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          },
          icon: const Icon(Icons.lock_reset, size: 14),
          label: const Text("Parol o'zgartirish",
              style: TextStyle(fontSize: 11)),
          style: ElevatedButton.styleFrom(
              backgroundColor: blueColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8))),
        ),
      ]),
    );
  }

  void _yangiiFoydalanuvchiQosh() async {
    yangiLoginCtrl.clear();
    yangiParolCtrl.clear();
    yangiRol = 'operator';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Text("Yangi foydalanuvchi qo'shish",
              style: TextStyle(
                  color: Color(0xFF0D1B2A), fontSize: 14)),
          content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
            TextField(
              controller: yangiLoginCtrl,
              decoration: InputDecoration(
                labelText: "Login",
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: yangiParolCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Parol",
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: yangiRol,
              decoration: InputDecoration(
                labelText: "Rol",
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(
                    value: 'operator',
                    child: Text("Operator")),
                DropdownMenuItem(
                    value: 'admin',
                    child: Text("Admin")),
              ],
              onChanged: (v) =>
                  setDlgState(() => yangiRol = v ?? 'operator'),
            ),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Bekor")),
            ElevatedButton(
              onPressed: () {
                if (yangiLoginCtrl.text.trim().isEmpty ||
                    yangiParolCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                        content: Text(
                            "Login va parol kiritish majburiy!"),
                        backgroundColor: Colors.red),
                  );
                  return;
                }
                setState(() {
                  foydalanuvchilar.add({
                    'login': yangiLoginCtrl.text,
                    'rol': yangiRol == 'admin'
                        ? 'Admin'
                        : 'Operator',
                    'oxirgiKirish': '—',
                  });
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Foydalanuvchi qo'shildi!"),
                      backgroundColor: Colors.green),
                );
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: greenLight),
              child: const Text("Qo'shish",
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ============ SOZLAMALAR ============
  Widget _sozlamalar() {
    final cardColor = kechagiRejim ? const Color(0xFF0F2A0F) : Colors.white;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(children: [
        // TELEGRAM
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: cardColor,
              border: Border.all(color: cardBorder),
              borderRadius: BorderRadius.circular(16)),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            cardLabel(Icons.send, "TELEGRAM BOT SOZLAMALARI",
                color: blueColor),
            const SizedBox(height: 12),
            _sozlamaField("Bot Token", telegramTokenCtrl,
                hint: "1234567890:ABCdefGHI..."),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: blueBg,
                      border: Border.all(color: blueBorder),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text("Haftalik hisobot",
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: blueColor)),
                    Text("Har dushanba 08:00 da Telegram ga",
                        style: TextStyle(
                            fontSize: 10, color: muted)),
                  ]),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: greenBg,
                      border: Border.all(color: greenBorder),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text("Kunlik hisobot",
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: greenLight)),
                    Text("Har kuni 23:00 da Telegram ga",
                        style: TextStyle(
                            fontSize: 10, color: muted)),
                  ]),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.end,
                children: [
              ElevatedButton.icon(
                onPressed: () {
                  ApiService.sozlamaSaqla({
                    'telegram_token': telegramTokenCtrl.text,
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            "Telegram sozlamalari saqlandi!"),
                        backgroundColor: Colors.green),
                  );
                },
                icon: const Icon(Icons.save, size: 14),
                label: const Text("Saqlash",
                    style: TextStyle(fontSize: 11)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: blueColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
              ),
            ]),
          ]),
        ),
        const SizedBox(height: 12),

        // ZAVOD NOMI
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: cardColor,
              border: Border.all(color: cardBorder),
              borderRadius: BorderRadius.circular(16)),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            cardLabel(Icons.business, "ZAVOD SOZLAMALARI",
                color: greenLight),
            const SizedBox(height: 12),
            _sozlamaField(
                "Zavod nomi (nakladnoydagi)", zavodNomiCtrl),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.end,
                children: [
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Zavod nomi saqlandi!"),
                        backgroundColor: Colors.green),
                  );
                },
                icon: const Icon(Icons.save, size: 14),
                label: const Text("Saqlash",
                    style: TextStyle(fontSize: 11)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: greenLight,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
              ),
            ]),
          ]),
        ),
        const SizedBox(height: 12),

        // NARX TIZIMI
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: cardColor,
              border: Border.all(color: cardBorder),
              borderRadius: BorderRadius.circular(16)),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            cardLabel(Icons.attach_money, "NARX TIZIMI",
                color: goldColor),
            const SizedBox(height: 12),
            _sozlamaField(
                "1 tonna konditsion narxi (so'm)", narxCtrl,
                hint: "Masalan: 4500000",
                type: TextInputType.number),
            const SizedBox(height: 8),
            if (konditsionNarx > 0)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: goldBg,
                    border: Border.all(color: goldBorder),
                    borderRadius: BorderRadius.circular(8)),
                child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                  const Text("Joriy narx:",
                      style: TextStyle(
                          fontSize: 12, color: goldColor)),
                  Text(
                      "${konditsionNarx.toStringAsFixed(0)} so'm/t",
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: goldColor)),
                ]),
              ),
            Row(mainAxisAlignment: MainAxisAlignment.end,
                children: [
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    konditsionNarx =
                        double.tryParse(narxCtrl.text) ?? 0;
                 });
                  ApiService.sozlamaSaqla({
                    'konditsion_narx': narxCtrl.text,
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Narx saqlandi!"),
                        backgroundColor: Colors.green),
                  );
                },
                icon: const Icon(Icons.save, size: 14),
                label: const Text("Saqlash",
                    style: TextStyle(fontSize: 11)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: goldColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
              ),
            ]),
          ]),
        ),
        const SizedBox(height: 12),

        // BACKUP
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: cardColor,
              border: Border.all(color: cardBorder),
              borderRadius: BorderRadius.circular(16)),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            cardLabel(Icons.backup, "BACKUP TIZIMI",
                color: blueColor),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: blueBg,
                  border: Border.all(color: blueBorder),
                  borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                const Icon(Icons.info_outline,
                    color: blueColor, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text("Avtomatik backup",
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: blueColor)),
                    Text(
                        "Har kuni soat 23:00 da PostgreSQL bazasi "
                        "C:\\hazorasp_tarozi\\backup\\ papkasiga saqlanadi",
                        style: TextStyle(
                            fontSize: 11, color: muted)),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            "Backup yaratilmoqda... "
                            "C:\\hazorasp_tarozi\\backup\\"),
                        backgroundColor: Colors.green),
                  );
                },
                icon: const Icon(Icons.save_alt, size: 14),
                label: const Text("Hozir backup olish",
                    style: TextStyle(fontSize: 11)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: blueColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 12),

        // SERVER HOLATI
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: cardColor,
              border: Border.all(color: cardBorder),
              borderRadius: BorderRadius.circular(16)),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            cardLabel(Icons.monitor, "SERVER HOLATI",
                color: greenLight),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _serverKarta(
                  "CPU",
                  "${serverHolati['cpu']}%",
                  serverHolati['cpu'] > 80
                      ? Colors.red
                      : greenLight,
                  Icons.memory,
                  serverHolati['cpu'] / 100)),
              const SizedBox(width: 10),
              Expanded(child: _serverKarta(
                  "RAM",
                  "${serverHolati['ram']}%",
                  serverHolati['ram'] > 80
                      ? Colors.red
                      : blueColor,
                  Icons.storage,
                  serverHolati['ram'] / 100)),
              const SizedBox(width: 10),
              Expanded(child: _serverKarta(
                  "DISK",
                  "${serverHolati['disk']}%",
                  serverHolati['disk'] > 80
                      ? Colors.red
                      : goldColor,
                  Icons.disc_full,
                  serverHolati['disk'] / 100)),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: greenBg,
                      border: Border.all(color: greenBorder),
                      borderRadius: BorderRadius.circular(10)),
                  child: Column(children: [
                    const Icon(Icons.access_time,
                        color: greenLight, size: 20),
                    const SizedBox(height: 4),
                    const Text("Uptime",
                        style: TextStyle(
                            fontSize: 10, color: muted)),
                    Text(serverHolati['uptime'],
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: greenLight)),
                  ]),
                ),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _serverKarta(String label, String value, Color color,
      IconData icon, double foiz) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(fontSize: 10, color: muted)),
        Text(value, style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color)),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: foiz,
          backgroundColor: Colors.white,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ]),
    );
  }

  Widget _sozlamaField(String label, TextEditingController ctrl,
      {String? hint, TextInputType? type}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
      Text(label,
          style: const TextStyle(fontSize: 11, color: muted)),
      const SizedBox(height: 4),
      TextField(
        controller: ctrl,
        keyboardType: type,
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              const TextStyle(fontSize: 11, color: Colors.grey),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8)),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 8),
        ),
      ),
    ]);
  }

  // ============ EKRAN QULFI ============
  Widget _ekranQulfiWidget() {
    return GestureDetector(
      onTap: _faolatBildirildi,
      child: Container(
        color: Colors.black.withValues(alpha: 0.85),
        child: Center(
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF0F2A0F),
              border: Border.all(color: greenBorder),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(mainAxisSize: MainAxisSize.min,
                children: [
              const Icon(Icons.lock, color: greenLight, size: 48),
              const SizedBox(height: 16),
              const Text("Ekran qulflangan",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text("Davom etish uchun parol kiriting",
                  style: TextStyle(color: muted, fontSize: 12)),
              const SizedBox(height: 20),
              TextField(
                controller: qulfParolCtrl,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Parol...",
                  hintStyle: const TextStyle(color: muted),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: greenBorder)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: greenBorder)),
                  filled: true,
                  fillColor: Colors.black.withValues(alpha: 0.3),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (qulfParolCtrl.text == 'admin123' ||
                        qulfParolCtrl.text == 'operator123') {
                      setState(() {
                        ekranQulflangan = false;
                        qulfParolCtrl.clear();
                      });
                      _ekranQulfiTikladir();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Noto'g'ri parol!"),
                            backgroundColor: Colors.red),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: greenLight,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                  child: const Text("Kirish",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // ============ SIDEBAR ICON ============
  Widget _sidebarIcon(IconData icon, int index, String label,
      {VoidCallback? onExtraTap}) {
    final active = tanlanganSidebar == index;
    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: () {
          setState(() => tanlanganSidebar = index);
          _faolatBildirildi();
          onExtraTap?.call();
        },
        child: Container(
          width: 42,
          height: 42,
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            color: active
                ? (kechagiRejim
                    ? const Color(0xFF0F2A1A)
                    : blueBg)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon,
              color: active
                  ? (kechagiRejim ? greenLight : blueColor)
                  : muted,
              size: 20),
        ),
      ),
    );
  }

  // ============ BUILD ============
  @override
  Widget build(BuildContext context) {
    final bgColor =
        kechagiRejim ? const Color(0xFF0A1A0A) : bgPage;
    final topbarColor =
        kechagiRejim ? const Color(0xFF0A1F0A) : Colors.white;
    final sidebarColor =
        kechagiRejim ? const Color(0xFF0A1F0A) : Colors.white;

    Widget kontent = Scaffold(
      backgroundColor: bgColor,
      body: Column(children: [
        // TOPBAR
        Container(
          color: topbarColor,
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 8),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF1976D2)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                Icon(Icons.scale, size: 14, color: Colors.white),
                SizedBox(width: 6),
                Text("Hazorasp Tekstil",
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ]),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: blueBg,
                  border: Border.all(color: blueBorder),
                  borderRadius: BorderRadius.circular(20)),
              child: const Text("Admin boshqaruvi",
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: blueColor)),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: goldBg,
                  border: Border.all(color: goldBorder),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(
                  "⏳ ${NavbatService.navbat.value.length} navbatda",
                  style: const TextStyle(
                      fontSize: 11, color: goldColor)),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: greenBg,
                  border: Border.all(color: greenBorder),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(
                  "✅ ${NavbatService.tugallanganlar.value.length} tugallandi",
                  style: const TextStyle(
                      fontSize: 11, color: greenLight)),
            ),
            const Spacer(),
            Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                    color: serverUlangan
                        ? greenLight
                        : Colors.red,
                    shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text(serverUlangan ? "Online" : "Offline",
                style: TextStyle(
                    fontSize: 10,
                    color: serverUlangan
                        ? greenLight
                        : Colors.red)),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                  color: kechagiRejim
                      ? const Color(0xFF0F2A0F)
                      : greenBg,
                  border: Border.all(color: greenBorder),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(hozirgiSoat,
                  style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: kechagiRejim
                          ? greenLight
                          : mutedText)),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                setState(
                    () => kechagiRejim = !kechagiRejim);
                _faolatBildirildi();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                    color: kechagiRejim
                        ? const Color(0xFF1A3A1A)
                        : const Color(0xFFF0F8E8),
                    border: Border.all(
                        color: kechagiRejim
                            ? greenLight
                            : cardBorder),
                    borderRadius: BorderRadius.circular(8)),
                child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                  Icon(
                      kechagiRejim
                          ? Icons.nightlight_round
                          : Icons.wb_sunny,
                      size: 14,
                      color: kechagiRejim
                          ? greenLight
                          : goldColor),
                  const SizedBox(width: 3),
                  Text(
                      kechagiRejim ? "Kecha" : "Kunduz",
                      style: TextStyle(
                          fontSize: 10,
                          color: kechagiRejim
                              ? greenLight
                              : mutedText)),
                ]),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                  color: blueBg,
                  border: Border.all(color: blueBorder),
                  borderRadius: BorderRadius.circular(20)),
              child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                const CircleAvatar(
                    radius: 11,
                    backgroundColor: blueColor,
                    child: Text("AD",
                        style: TextStyle(
                            fontSize: 9,
                            color: Colors.white))),
                const SizedBox(width: 6),
                Text(widget.username,
                    style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF1A3A88))),
              ]),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.logout,
                  color: Colors.redAccent, size: 16),
              onPressed: () => Navigator.popUntil(
                  context, (route) => route.isFirst),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ]),
        ),

        // KONTENT
        Expanded(
          child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
            // SIDEBAR
            Container(
              width: 52,
              color: sidebarColor,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(children: [
                _sidebarIcon(Icons.dashboard, 0, "Dashboard",
                    onExtraTap: dashboardTonnajniYukla),
                _sidebarIcon(
                    Icons.description_outlined, 1, "Hujjatlar"),
                _sidebarIcon(Icons.bar_chart, 2, "Statistika",
                    onExtraTap: grafikDetalniYukla),
                _sidebarIcon(
                    Icons.people_outline, 3, "Foydalanuvchilar"),
                _sidebarIcon(Icons.settings, 4, "Sozlamalar"),
                _sidebarIcon(Icons.scale, 5, "Tarozi"),
                _sidebarIcon(Icons.history, 6, "Tahrirlar tarixi",
                    onExtraTap: tahrirTarixiniYukla),
              ]),
            ),

            // SAHIFA
            Expanded(
              child: GestureDetector(
                onTap: _faolatBildirildi,
                onPanUpdate: (_) => _faolatBildirildi(),
                child: tanlanganSidebar == 0
                    ? _dashboard()
                    : tanlanganSidebar == 1
                        ? _hujjatlarJadvali()
                        : tanlanganSidebar == 2
                            ? _statistika()
                            : tanlanganSidebar == 3
                                ? _foydalanuvchilar()
                                : tanlanganSidebar == 4
                                    ? _sozlamalar()
                                    : tanlanganSidebar == 5
                                        ? OperatorPanelScreen(
                                            username: widget.username,
                                            mahsulotId: 1,
                                            mahsulotNomi: "Chigit",
                                            mahsulotRang: greenLight,
                                            adminRejim: true,
                                          )
                                        : tanlanganSidebar == 6
                                            ? _tahrirlarTarixi()
                                            : _dashboard(),
              ),
            ),
          ]),
        ),
      ]),
    );

    if (ekranQulflangan) {
      return Stack(children: [
        kontent,
        Positioned.fill(child: _ekranQulfiWidget()),
      ]);
    }

    return kontent;
  }
} 