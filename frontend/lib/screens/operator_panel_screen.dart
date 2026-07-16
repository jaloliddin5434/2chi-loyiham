import 'dart:async';
import 'package:flutter/material.dart';
import 'nakladnoy_screen.dart';
import '../services/api_service.dart';
import '../services/navbat_service.dart';

class AravaData {
  double? tara;
  double? brutto;
  String? taraVaqt;
  String? bruttoVaqt;
  double? get netto =>
      (tara != null && brutto != null) ? brutto! - tara! : null;
  double? konditsion;
}

class NavbatMashina {
  final String raqam;
  final String turi;
  final String shofyor;
  final String firma;
  final String vaqt;
  final int mahsulotId;
  final String mahsulotNomi;
  final Map<int, AravaData> aravalar;
  final int hujjatId;
  final int mashinaId;
  final DateTime kelganVaqt;
  bool tugallandi;
  DateTime? tugallanganVaqt;
  String? tudaRaqam;
  String? tiketRaqam;
  String? seleksiyaNavi;
  String? klass;
  String? sinf;
  String? terimTuri;
  double? namlik;
  double? ifloslik;
  String? qabulQildi;
  String? yukOlindi;
  String? bekorSababi;

  NavbatMashina({
    required this.raqam,
    required this.turi,
    required this.shofyor,
    required this.firma,
    required this.vaqt,
    required this.mahsulotId,
    required this.mahsulotNomi,
    required this.aravalar,
    required this.hujjatId,
    required this.mashinaId,
    required this.kelganVaqt,
    this.tugallandi = false,
    this.tugallanganVaqt,
    this.tudaRaqam,
    this.tiketRaqam,
    this.seleksiyaNavi,
    this.klass,
    this.sinf,
    this.terimTuri,
    this.namlik,
    this.ifloslik,
    this.qabulQildi,
    this.yukOlindi,
    this.bekorSababi,
  });
}

class OperatorPanelScreen extends StatefulWidget {
  final String username;
  final int mahsulotId;
  final String mahsulotNomi;
  final Color mahsulotRang;
  final bool adminRejim;

  const OperatorPanelScreen({
    super.key,
    required this.username,
    required this.mahsulotId,
    required this.mahsulotNomi,
    required this.mahsulotRang,
    this.adminRejim = false,
  });

  @override
  State<OperatorPanelScreen> createState() =>
      _OperatorPanelScreenState();
}

class _OperatorPanelScreenState extends State<OperatorPanelScreen>
    with TickerProviderStateMixin {
  double taroziKg = 18450;
  double _oldingiTaroziKg = 18450;
  int _barqarorSoniya = 0;
  bool taroziBarqaror = false;

  Timer? timer;
  Timer? soatTimer;
  Timer? xabarTimer;
  Timer? tugallanganTimer;
  Timer? navbatYangilashTimer;

  bool saqlanmoqda = false;
  int qoldiqSoniya = 0;
  int tanlanganArava = 1;
  int aravalarSoni = 1;
  bool kechagiRejim = false;
  String hozirgiSoat = '';
  String xabarMatni = '';
  bool serverUlangan = true;
  bool tugallanganlarKorinsin = false;

  int bugunMashinalar = 0;
  double bugunTonnaj = 0;

  int? mashinaId;
  int? hujjatId;
  bool bazagaSaqlandi = false;
  DateTime? mashinaKelganVaqt;

  bool taraSaqlangan1 = false;
  bool taraSaqlangan2 = false;
  bool taraSaqlangan3 = false;
  bool bruttoSaqlangan1 = false;
  bool bruttoSaqlangan2 = false;
  bool bruttoSaqlangan3 = false;

  NavbatMashina? tanlanganNavbat;

  late AnimationController _aravaAnimCtrl;
  late Animation<double> _aravaAnim;

  final Map<int, AravaData> aravalar = {
    1: AravaData(),
    2: AravaData(),
    3: AravaData(),
  };

  final raqamiCtrl = TextEditingController();
  final turiCtrl = TextEditingController(text: "FAW");
  final shofyorCtrl = TextEditingController();
  final firmaCtrl =
      TextEditingController(text: "SABZAVOTNAVURUG'LARI MChJ");
  final tudaRaqamCtrl = TextEditingController();
  final tiketRaqamCtrl = TextEditingController();
  final seleksiyaNaviCtrl =
      TextEditingController(text: "Xorazm-150");
  final klassCtrl = TextEditingController(text: "1");
  final sinfCtrl = TextEditingController();
  final terimTuriCtrl =
      TextEditingController(text: "Kul terim");
  final ifloslikCtrl = TextEditingController();
  final namlikCtrl = TextEditingController();
  final qabulQildiCtrl =
      TextEditingController(text: "Abdullaev B");
  final yukOlindiCtrl =
      TextEditingController(text: "Hashimov Ravshan");
  final dostaverkaCtrl = TextEditingController(text: "60");
  final dostaverkaVaqtCtrl =
      TextEditingController(text: "10.04.2026 - 30.06.2026");

  static const Color green = Color(0xFF1A7A08);
  static const Color greenLight = Color(0xFF3AAA1A);
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

  bool get konditsionBor => widget.mahsulotId == 1;
  bool get dostavernaBor => widget.mahsulotId == 1;
  bool get faqatBrutto => tanlanganNavbat != null;

 List<NavbatMashina> get navbat =>
      NavbatService.navbatByMahsulot(widget.mahsulotId);
  List<NavbatMashina> get tugallanganlar =>
      NavbatService.tugallanganlarByMahsulot(widget.mahsulotId);
      
  String get mahsulotYukNomi {
    switch (widget.mahsulotId) {
      case 1:
        return "Техник чигит";
      case 2:
        return "Чигanoq";
      case 3:
        return "Чигanoq по'чоғи";
      default:
        return widget.mahsulotNomi;
    }
  }

  String get avtomatikSana {
    final now = DateTime.now();
    const oylar = [
      'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
      'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'
    ];
    return '"${now.day}" ${oylar[now.month - 1]} ${now.year} йил';
  }

  String _vaqtStr() {
    final now = DateTime.now();
    return "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
  }

  String _davomiylik(DateTime boshlanish) {
    final diff = DateTime.now().difference(boshlanish);
    return "${diff.inMinutes}m ${diff.inSeconds % 60}s";
  }

  NavbatMashina _mapDanMashina(Map<String, dynamic> m) {
    final aravalarMap = <int, AravaData>{
      1: AravaData(),
      2: AravaData(),
      3: AravaData(),
    };
    if (m['aravalar'] != null) {
      final raw = m['aravalar'] as Map<String, dynamic>;
      raw.forEach((key, value) {
        final n = int.tryParse(key) ?? 0;
        if (n >= 1 && n <= 3 && value != null) {
          aravalarMap[n] = AravaData()
            ..tara = (value['tara'] as num?)?.toDouble()
            ..brutto =
                (value['brutto'] as num?)?.toDouble()
            ..konditsion =
                (value['konditsion'] as num?)?.toDouble();
        }
      });
    }
    return NavbatMashina(
      raqam: m['raqam'] ?? '—',
      turi: m['turi'] ?? '—',
      shofyor: m['shofyor'] ?? '—',
      firma: m['firma'] ?? '—',
      vaqt: m['vaqt'] ?? '—',
      mahsulotId: m['mahsulotId'] ?? 1,
      mahsulotNomi: m['mahsulotNomi'] ?? '—',
      aravalar: aravalarMap,
      hujjatId: m['hujjatId'] ?? 0,
      mashinaId: m['mashinaId'] ?? 0,
      kelganVaqt:
          DateTime.tryParse(m['kelganVaqt'] ?? '') ??
              DateTime.now(),
      tugallandi: m['tugallandi'] ?? false,
      tugallanganVaqt: m['tugallanganVaqt'] != null
          ? DateTime.tryParse(
              m['tugallanganVaqt'].toString())
          : null,
      tudaRaqam: m['tudaRaqam'],
      tiketRaqam: m['tiketRaqam'],
      seleksiyaNavi: m['seleksiyaNavi'],
      klass: m['klass'],
      sinf: m['sinf'],
      terimTuri: m['terimTuri'],
      namlik: (m['namlik'] as num?)?.toDouble(),
      ifloslik: (m['ifloslik'] as num?)?.toDouble(),
      qabulQildi: m['qabulQildi'],
      yukOlindi: m['yukOlindi'],
    );
  }

  Future<void> _backendDanYukla() async {
    try {
      final navbatData = await ApiService.navbatOl();
      final tugallanganData =
          await ApiService.tugallanganlarOl();

      // Mavjud id lar
      final mavjudNavbatIds = NavbatService.navbat.value
          .map((m) => m.hujjatId)
          .toSet();
      final mavjudTugIds =
          NavbatService.tugallanganlar.value
              .map((m) => m.hujjatId)
              .toSet();

      // Faqat yangilarini qo'shish
      for (final m in navbatData) {
        final id = (m['hujjatId'] ?? 0) as int;
        if (!mavjudNavbatIds.contains(id) &&
            !mavjudTugIds.contains(id)) {
          NavbatService.navbatQosh(_mapDanMashina(
              Map<String, dynamic>.from(m)));
        }
      }

      for (final m in tugallanganData) {
        final id = (m['hujjatId'] ?? 0) as int;
        if (!mavjudTugIds.contains(id)) {
          final mashina = _mapDanMashina(
              Map<String, dynamic>.from(m));
          NavbatService.tugallanganlar.value = [
            mashina,
            ...NavbatService.tugallanganlar.value
                .where((x) => x.hujjatId != id)
          ];
        }
      }

      if (mounted) setState(() => serverUlangan = true);
    } catch (e) {
      if (mounted) setState(() => serverUlangan = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _aravaAnimCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300));
    _aravaAnim = Tween<double>(begin: 1.0, end: 1.05)
        .animate(CurvedAnimation(
            parent: _aravaAnimCtrl,
            curve: Curves.easeInOut));

    _soatniYanila();
    soatTimer = Timer.periodic(
        const Duration(seconds: 1), (_) => _soatniYanila());
    tiketRaqamCtrl.text = DateTime.now()
        .millisecondsSinceEpoch
        .toString()
        .substring(5, 12);

    timer =
        Timer.periodic(const Duration(milliseconds: 800), (t) {
      final yangi =
          taroziKg + (DateTime.now().millisecond % 10) - 5;
      setState(() {
        if ((yangi - _oldingiTaroziKg).abs() < 2) {
          _barqarorSoniya++;
          if (_barqarorSoniya >= 4) taroziBarqaror = true;
        } else {
          _barqarorSoniya = 0;
          taroziBarqaror = false;
        }
        _oldingiTaroziKg = taroziKg;
        taroziKg = yangi;
      });
    });

    tugallanganTimer =
        Timer.periodic(const Duration(minutes: 10), (_) {
      final chegara =
          DateTime.now().subtract(const Duration(hours: 12));
      final yangi = NavbatService.tugallanganlar.value
          .where((m) =>
              m.tugallanganVaqt == null ||
              m.tugallanganVaqt!.isAfter(chegara))
          .toList();
      NavbatService.tugallanganlar.value = yangi;
    });

    // Backend dan yuklash
    _backendDanYukla();
    navbatYangilashTimer = Timer.periodic(
        const Duration(seconds: 5),
        (_) => _backendDanYukla());

    NavbatService.navbat.addListener(_navbatYangilandi);
    NavbatService.tugallanganlar
        .addListener(_navbatYangilandi);

    ifloslikCtrl.addListener(_konditsionHisobla);
    namlikCtrl.addListener(_konditsionHisobla);
  }

  void _navbatYangilandi() {
    if (mounted) setState(() {});
  }

  void _soatniYanila() {
    final now = DateTime.now();
    setState(() {
      hozirgiSoat =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
    });
  }

  void _xabar(String matn) {
    xabarTimer?.cancel();
    setState(() => xabarMatni = matn);
    xabarTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => xabarMatni = '');
    });
  }

  void _konditsionHisobla() {
    if (!konditsionBor) return;
    final namlik = double.tryParse(namlikCtrl.text) ?? 0;
    final ifloslik =
        double.tryParse(ifloslikCtrl.text) ?? 0;
    for (final arava in aravalar.values) {
      if (arava.netto != null) {
      arava.konditsion = arava.netto! *
            (100 - (ifloslik + namlik)) / 89.5;
      }
    }
    setState(() {});
  }

  @override
  void dispose() {
    timer?.cancel();
    soatTimer?.cancel();
    xabarTimer?.cancel();
    tugallanganTimer?.cancel();
    navbatYangilashTimer?.cancel();
    _aravaAnimCtrl.dispose();
    NavbatService.navbat.removeListener(_navbatYangilandi);
    NavbatService.tugallanganlar
        .removeListener(_navbatYangilandi);
    raqamiCtrl.dispose();
    turiCtrl.dispose();
    shofyorCtrl.dispose();
    firmaCtrl.dispose();
    tudaRaqamCtrl.dispose();
    tiketRaqamCtrl.dispose();
    seleksiyaNaviCtrl.dispose();
    klassCtrl.dispose();
    sinfCtrl.dispose();
    terimTuriCtrl.dispose();
    ifloslikCtrl.dispose();
    namlikCtrl.dispose();
    qabulQildiCtrl.dispose();
    yukOlindiCtrl.dispose();
    dostaverkaCtrl.dispose();
    dostaverkaVaqtCtrl.dispose();
    super.dispose();
  }

  void _aravaTanlash(int n) {
    setState(() => tanlanganArava = n);
    _aravaAnimCtrl.forward(from: 0);
  }

  void keyingiMashina() {
    if (!bazagaSaqlandi) {
      _xabar("❌ Avval tara o'lchang!");
      return;
    }
    final Map<int, AravaData> saqlangan = {};
    for (var e in aravalar.entries) {
      final a = AravaData();
      a.tara = e.value.tara;
      a.brutto = e.value.brutto;
      a.taraVaqt = e.value.taraVaqt;
      a.bruttoVaqt = e.value.bruttoVaqt;
      a.konditsion = e.value.konditsion;
      saqlangan[e.key] = a;
    }

    final mashina = NavbatMashina(
      raqam: raqamiCtrl.text,
      turi: turiCtrl.text,
      shofyor: shofyorCtrl.text,
      firma: firmaCtrl.text,
      vaqt: _vaqtStr(),
      mahsulotId: widget.mahsulotId,
      mahsulotNomi: widget.mahsulotNomi,
      aravalar: saqlangan,
      hujjatId: hujjatId!,
      mashinaId: mashinaId!,
      kelganVaqt: mashinaKelganVaqt ?? DateTime.now(),
      tudaRaqam: tudaRaqamCtrl.text,
      tiketRaqam: tiketRaqamCtrl.text,
      seleksiyaNavi: seleksiyaNaviCtrl.text,
      klass: klassCtrl.text,
      sinf: sinfCtrl.text,
      terimTuri: terimTuriCtrl.text,
      namlik: double.tryParse(namlikCtrl.text),
      ifloslik: double.tryParse(ifloslikCtrl.text),
      qabulQildi: qabulQildiCtrl.text,
      yukOlindi: yukOlindiCtrl.text,
    );
    final bruttoOlchandi = aravalar.values.any((a) => a.brutto != null) ||
        (tanlanganNavbat?.aravalar.values.any((a) => a.brutto != null) ?? false);
    if (bruttoOlchandi) {
      NavbatService.navbatdanOchir(hujjatId!);
      ApiService.navbatBekor(hujjatId!);
    } else {
      NavbatService.navbatQosh(mashina);
    }

    ApiService.navbatQosh({
      'hujjatId': mashina.hujjatId,
      'mashinaId': mashina.mashinaId,
      'raqam': mashina.raqam,
      'turi': mashina.turi,
      'shofyor': mashina.shofyor,
      'firma': mashina.firma,
      'vaqt': mashina.vaqt,
      'mahsulotId': mashina.mahsulotId,
      'mahsulotNomi': mashina.mahsulotNomi,
      'kelganVaqt': mashina.kelganVaqt.toIso8601String(),
      'tudaRaqam': mashina.tudaRaqam,
      'tiketRaqam': mashina.tiketRaqam,
      'seleksiyaNavi': mashina.seleksiyaNavi,
      'klass': mashina.klass,
      'sinf': mashina.sinf,
      'terimTuri': mashina.terimTuri,
      'namlik': mashina.namlik,
      'ifloslik': mashina.ifloslik,
      'tugallandi': false,
      'aravalar': {
        '1': {
          'tara': saqlangan[1]?.tara,
          'brutto': saqlangan[1]?.brutto,
          'netto': saqlangan[1]?.netto,
          'konditsion': saqlangan[1]?.konditsion,
        },
        '2': {
          'tara': saqlangan[2]?.tara,
          'brutto': saqlangan[2]?.brutto,
          'netto': saqlangan[2]?.netto,
          'konditsion': saqlangan[2]?.konditsion,
        },
        '3': {
          'tara': saqlangan[3]?.tara,
          'brutto': saqlangan[3]?.brutto,
          'netto': saqlangan[3]?.netto,
          'konditsion': saqlangan[3]?.konditsion,
        },
      },
    });

    _tozala();
    _xabar("✅ Mashina navbatga qo'shildi!");
  }

  void mashinaBekorQil(NavbatMashina mashina) async {
    final sababCtrl = TextEditingController();
    final tasdiqlandi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text("Mashinani bekor qilish",
            style: TextStyle(
                color: Colors.red, fontSize: 14)),
        content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
          Text(
              "${mashina.raqam} mashinani bekor qilmoqchimisiz?",
              style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 12),
          TextField(
            controller: sababCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: "Sabab (majburiy)",
              labelStyle:
                  const TextStyle(color: Colors.red),
              border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(8)),
              isDense: true,
            ),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () =>
                  Navigator.pop(ctx, false),
              child: const Text("Orqaga")),
          ElevatedButton(
            onPressed: () {
              if (sababCtrl.text.trim().isEmpty)
                return;
              Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red),
            child: const Text("Bekor qilish",
                style:
                    TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (tasdiqlandi == true) {
      mashina.bekorSababi = sababCtrl.text;
      NavbatService.navbatdanOchir(mashina.hujjatId);
      ApiService.navbatBekor(mashina.hujjatId);
      _xabar("✅ Mashina bekor qilindi!");
      if (tanlanganNavbat?.hujjatId ==
          mashina.hujjatId) {
        setState(() => tanlanganNavbat = null);
        _tozala();
      }
    }
  }

  void _tozala() {
    raqamiCtrl.clear();
    turiCtrl.text = "FAW";
    shofyorCtrl.clear();
    tudaRaqamCtrl.clear();
    tiketRaqamCtrl.text = DateTime.now()
        .millisecondsSinceEpoch
        .toString()
        .substring(5, 12);
    ifloslikCtrl.clear();
    namlikCtrl.clear();
    aravalar[1] = AravaData();
    aravalar[2] = AravaData();
    aravalar[3] = AravaData();
    taraSaqlangan1 =
        taraSaqlangan2 = taraSaqlangan3 = false;
    bruttoSaqlangan1 =
        bruttoSaqlangan2 = bruttoSaqlangan3 = false;
    mashinaId = null;
    
    bazagaSaqlandi = false;
    tanlanganArava = 1;
    tanlanganNavbat = null;
    saqlanmoqda = false;
    qoldiqSoniya = 0;
    mashinaKelganVaqt = null;
  }

  void navbatdanTanlash(NavbatMashina mashina) {
    setState(() {
      tanlanganNavbat = mashina;
      raqamiCtrl.text = mashina.raqam;
      turiCtrl.text = mashina.turi;
      shofyorCtrl.text = mashina.shofyor;
      firmaCtrl.text = mashina.firma;
      hujjatId = mashina.hujjatId;
      mashinaId = mashina.mashinaId;
      bazagaSaqlandi = true;
      mashinaKelganVaqt = mashina.kelganVaqt;
      if (mashina.tudaRaqam != null)
        tudaRaqamCtrl.text = mashina.tudaRaqam!;
      if (mashina.tiketRaqam != null)
        tiketRaqamCtrl.text = mashina.tiketRaqam!;
      if (mashina.seleksiyaNavi != null)
        seleksiyaNaviCtrl.text = mashina.seleksiyaNavi!;
      if (mashina.klass != null)
        klassCtrl.text = mashina.klass!;
      if (mashina.sinf != null)
        sinfCtrl.text = mashina.sinf!;
      if (mashina.terimTuri != null)
        terimTuriCtrl.text = mashina.terimTuri!;
      if (mashina.namlik != null)
        namlikCtrl.text = mashina.namlik.toString();
      if (mashina.ifloslik != null)
        ifloslikCtrl.text = mashina.ifloslik.toString();
      if (mashina.qabulQildi != null)
        qabulQildiCtrl.text = mashina.qabulQildi!;
      if (mashina.yukOlindi != null)
        yukOlindiCtrl.text = mashina.yukOlindi!;
      for (var e in mashina.aravalar.entries) {
        aravalar[e.key]!.tara = e.value.tara;
        aravalar[e.key]!.brutto = e.value.brutto;
        aravalar[e.key]!.taraVaqt = e.value.taraVaqt;
        aravalar[e.key]!.bruttoVaqt =
            e.value.bruttoVaqt;
        aravalar[e.key]!.konditsion =
            e.value.konditsion;
      }
      taraSaqlangan1 =
          mashina.aravalar[1]?.tara != null;
      taraSaqlangan2 =
          mashina.aravalar[2]?.tara != null;
      taraSaqlangan3 =
          mashina.aravalar[3]?.tara != null;
      bruttoSaqlangan1 =
          mashina.aravalar[1]?.brutto != null;
      bruttoSaqlangan2 =
          mashina.aravalar[2]?.brutto != null;
      bruttoSaqlangan3 =
          mashina.aravalar[3]?.brutto != null;
      tanlanganArava = 1;
    });
    _xabar("🚛 ${mashina.raqam} — BRUTTO o'lchang!");
  }

  void mashinaKor(NavbatMashina mashina) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.local_shipping,
              color: Color(0xFF2A6AB8), size: 20),
          const SizedBox(width: 8),
          Expanded(
              child: Text(mashina.raqam,
                  style: const TextStyle(
                      color: Color(0xFF1A4A08),
                      fontSize: 15,
                      fontWeight: FontWeight.w700))),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: mashina.tugallandi
                  ? greenBg
                  : goldBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
                mashina.tugallandi
                    ? "✅ Tugallandi"
                    : "⏳ Navbatda",
                style: TextStyle(
                    fontSize: 11,
                    color: mashina.tugallandi
                        ? greenLight
                        : goldColor)),
          ),
        ]),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
              _korSection("🚛 MASHINA", [
                _korRow(
                    "Davlat raqami", mashina.raqam),
                _korRow("Turi", mashina.turi),
                _korRow("Shofyor", mashina.shofyor),
                _korRow("Firma", mashina.firma),
                _korRow("Kelgan vaqt", mashina.vaqt),
                if (mashina.tugallanganVaqt != null)
                  _korRow(
                      "Tugallangan",
                      "${mashina.tugallanganVaqt!.hour.toString().padLeft(2, '0')}:${mashina.tugallanganVaqt!.minute.toString().padLeft(2, '0')}"),
                if (mashina.bekorSababi != null)
                  _korRow("Bekor sababi",
                      mashina.bekorSababi!),
              ]),
              const SizedBox(height: 10),
              _korSection("📋 HUJJAT", [
                _korRow("Tiket №",
                    mashina.tiketRaqam ?? '—'),
                _korRow("Tuda №",
                    mashina.tudaRaqam ?? '—'),
                _korRow(
                    "Klass", mashina.klass ?? '—'),
                _korRow("Sinf", mashina.sinf ?? '—'),
                _korRow("Terim turi",
                    mashina.terimTuri ?? '—'),
                _korRow("Seleksiya navi",
                    mashina.seleksiyaNavi ?? '—'),
                if (konditsionBor) ...[
                  _korRow(
                      "Namlik %",
                      mashina.namlik
                              ?.toStringAsFixed(1) ??
                          '—'),
                  _korRow(
                      "Ifloslik %",
                      mashina.ifloslik
                              ?.toStringAsFixed(1) ??
                          '—'),
                ],
              ]),
              const SizedBox(height: 10),
              _korSection("⚖️ O'LCHOVLAR", [
                for (int i = 1; i <= 3; i++)
                  if (mashina.aravalar[i]?.tara !=
                      null)
                    _olchovRow(
                        i, mashina.aravalar[i]!),
                if (!mashina.aravalar.values
                    .any((a) => a.tara != null))
                  _korRow("Ma'lumot",
                      "Hali o'lchanmagan"),
              ]),
            ]),
          ),
        ),
        actions: [
          if (!mashina.tugallandi) ...[
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                mashinaBekorQil(mashina);
              },
              icon: const Icon(Icons.cancel, size: 14),
              label: const Text("Bekor qilish",
                  style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(8))),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                navbatdanTanlash(mashina);
              },
              icon: const Icon(Icons.arrow_upward,
                  size: 14),
              label: const Text("Brutto o'lchash",
                  style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: blueColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(8))),
            ),
          ],
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Yopish")),
        ],
      ),
    );
  }

  Widget _korSection(
      String title, List<Widget> rows) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
      Text(title,
          style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF7AAA5A),
              letterSpacing: 1,
              fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F8F0),
          border: Border.all(
              color: const Color(0xFFD8EDD0)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(children: rows),
      ),
    ]);
  }

  Widget _korRow(String label, String value) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        SizedBox(
            width: 130,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey))),
        Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A4A08)))),
      ]),
    );
  }

  Widget _olchovRow(int n, AravaData arava) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color:
            arava.brutto != null ? greenBg : goldBg,
        border: Border.all(
            color: arava.brutto != null
                ? greenBorder
                : goldBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
        Text("$n-arava",
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A4A08))),
        const SizedBox(height: 6),
        Row(children: [
          _olchovKarta("Tara", arava.tara,
              arava.taraVaqt, greenLight),
          const SizedBox(width: 8),
          _olchovKarta("Brutto", arava.brutto,
              arava.bruttoVaqt, blueColor),
          const SizedBox(width: 8),
          _olchovKarta(
              "Netto", arava.netto, null, green),
          if (konditsionBor) ...[
            const SizedBox(width: 8),
            _olchovKarta("Konditsion",
                arava.konditsion, null, goldColor),
          ],
        ]),
      ]),
    );
  }

  Widget _olchovKarta(String label, double? value,
      String? vaqt, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
              color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color:
                      color.withValues(alpha: 0.7))),
          Text(
              value != null
                  ? "${value.toStringAsFixed(0)} kg"
                  : "—",
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color)),
          if (vaqt != null)
            Text(vaqt,
                style: TextStyle(
                    fontSize: 9,
                    color: color
                        .withValues(alpha: 0.6))),
        ]),
      ),
    );
  }

  Future<void> saqlash() async {
    if (saqlanmoqda || tanlanganArava == 0) return;

    final taraS = tanlanganArava == 1
        ? taraSaqlangan1
        : tanlanganArava == 2
            ? taraSaqlangan2
            : taraSaqlangan3;
    final bruttoS = tanlanganArava == 1
        ? bruttoSaqlangan1
        : tanlanganArava == 2
            ? bruttoSaqlangan2
            : bruttoSaqlangan3;

    if (faqatBrutto) {
      if (bruttoS) {
        _xabar(
            "❌ $tanlanganArava-arava bruttosi saqlangan!");
        return;
      }

      final tasdiqlandi = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(16)),
          title: const Text("Bruttoni saqlash",
              style: TextStyle(
                  color: Color(0xFF1A4A08),
                  fontSize: 15)),
          content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
            Text("$tanlanganArava-arava BRUTTO:",
                style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13)),
            const SizedBox(height: 8),
            Text(
                "${taroziKg.toStringAsFixed(0)} kg",
                style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2A6AB8))),
            const SizedBox(height: 4),
            Text(
                "Netto: ${(taroziKg - (aravalar[tanlanganArava]?.tara ?? 0)).toStringAsFixed(0)} kg",
                style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1A7A08))),
          ]),
          actions: [
            TextButton(
                onPressed: () =>
                    Navigator.pop(ctx, false),
                child: const Text("Bekor")),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: blueColor),
              child: const Text("Saqlash",
                  style: TextStyle(
                      color: Colors.white)),
            ),
          ],
        ),
      );
      if (tasdiqlandi != true) return;

      final arava = aravalar[tanlanganArava]!;
      setState(() {
        arava.brutto = taroziKg;
        arava.bruttoVaqt = _vaqtStr();
        if (tanlanganArava == 1)
          bruttoSaqlangan1 = true;
        if (tanlanganArava == 2)
          bruttoSaqlangan2 = true;
        if (tanlanganArava == 3)
          bruttoSaqlangan3 = true;
        saqlanmoqda = true;
        qoldiqSoniya = 10;
      });
      _konditsionHisobla();

      // Kamera rasm olish
      ApiService.rasmOl(
        mashinaRaqami: raqamiCtrl.text,
        mahsulotNomi: widget.mahsulotNomi,
        tur: 'brutto',
      );

      // Nakladnoy PDF saqlash
      ApiService.nakladnoySaqla(
        mashinaRaqami: raqamiCtrl.text,
        mahsulotNomi: widget.mahsulotNomi,
        sana: DateTime.now().toString().substring(0, 10),
        html: '<p>nakladnoy</p>',
      );

    try {
        print('hujjatId: $hujjatId, navbat: ${tanlanganNavbat?.hujjatId}');
        final result = await ApiService.olchovSaqlash(
          hujjatId: tanlanganNavbat?.hujjatId ?? hujjatId ?? 0,
          aravaRaqam: tanlanganArava,
          tara: arava.tara,
          brutto: taroziKg,
          namlik: double.tryParse(namlikCtrl.text),
          ifloslik: double.tryParse(ifloslikCtrl.text),
        );
        if (result['konditsion'] != null) {
          arava.konditsion = (result['konditsion'] as num).toDouble();
        }
      } catch (e) {
        print('olchovSaqlash xato: $e');
      }
      final keyingi = _keyingiBruttoSizArava();
      if (keyingi != null) {
        _xabar(
            "✅ $tanlanganArava-arava BRUTTO — ${keyingi}-aravani qo'ying!");
      } else {
        final tug = tanlanganNavbat!;
        tug.tugallandi = true;
        tug.tugallanganVaqt = DateTime.now();

        for (var e in aravalar.entries) {
          if (tug.aravalar[e.key] != null) {
            tug.aravalar[e.key]!.brutto =
                e.value.brutto;
            tug.aravalar[e.key]!.bruttoVaqt =
                e.value.bruttoVaqt;
            tug.aravalar[e.key]!.konditsion =
                e.value.konditsion;
          }
        }

        ApiService.navbatTugallandi({
          'hujjatId': tug.hujjatId,
          'mashinaId': tug.mashinaId,
          'raqam': tug.raqam,
          'turi': tug.turi,
          'shofyor': tug.shofyor,
          'firma': tug.firma,
          'vaqt': tug.vaqt,
          'mahsulotId': tug.mahsulotId,
          'mahsulotNomi': tug.mahsulotNomi,
          'kelganVaqt':
              tug.kelganVaqt.toIso8601String(),
          'tudaRaqam': tug.tudaRaqam,
          'tiketRaqam': tug.tiketRaqam,
          'seleksiyaNavi': tug.seleksiyaNavi,
          'klass': tug.klass,
          'sinf': tug.sinf,
          'terimTuri': tug.terimTuri,
          'namlik': tug.namlik,
          'ifloslik': tug.ifloslik,
          'tugallandi': true,
          'aravalar': {
            '1': {
              'tara': tug.aravalar[1]?.tara,
              'brutto': tug.aravalar[1]?.brutto,
              'netto': tug.aravalar[1]?.netto,
              'konditsion':
                  tug.aravalar[1]?.konditsion,
            },
            '2': {
              'tara': tug.aravalar[2]?.tara,
              'brutto': tug.aravalar[2]?.brutto,
              'netto': tug.aravalar[2]?.netto,
              'konditsion':
                  tug.aravalar[2]?.konditsion,
            },
            '3': {
              'tara': tug.aravalar[3]?.tara,
              'brutto': tug.aravalar[3]?.brutto,
              'netto': tug.aravalar[3]?.netto,
              'konditsion':
                  tug.aravalar[3]?.konditsion,
            },
          },
        });

        
NavbatService.tugallandiQosh(tug);
        try {
         await ApiService.navbatTugallandi({
            'hujjatId': tug.hujjatId,
            'aravalar': {
              '1': {
                'tara': tug.aravalar[1]?.tara,
                'brutto': tug.aravalar[1]?.brutto,
                'netto': tug.aravalar[1]?.netto,
                'konditsion': tug.aravalar[1]?.konditsion,
              },
              '2': {
                'tara': tug.aravalar[2]?.tara,
                'brutto': tug.aravalar[2]?.brutto,
                'netto': tug.aravalar[2]?.netto,
                'konditsion': tug.aravalar[2]?.konditsion,
              },
              '3': {
                'tara': tug.aravalar[3]?.tara,
                'brutto': tug.aravalar[3]?.brutto,
                'netto': tug.aravalar[3]?.netto,
                'konditsion': tug.aravalar[3]?.konditsion,
              },
            },
          });
        } catch (e) {}
        setState(() {
          bugunMashinalar++;
          final netto = jamiNetto();
          if (netto != null)
            bugunTonnaj += netto / 1000;
          tanlanganNavbat = null;
        });
        _xabar("✅ Tugallandi — Nakladnoy bering!");
      }
      _qoldiqTimer();
      return;
    }

    if (taraS) {
      _xabar(
          "❌ $tanlanganArava-arava tarasi saqlangan!");
      return;
    }
    await _bazagaSaqla();
    if (!bazagaSaqlandi) return;
    if (mashinaKelganVaqt == null)
      mashinaKelganVaqt = DateTime.now();

    final arava = aravalar[tanlanganArava]!;
    setState(() {
      arava.tara = taroziKg;
      arava.taraVaqt = _vaqtStr();
      if (tanlanganArava == 1) taraSaqlangan1 = true;
      if (tanlanganArava == 2) taraSaqlangan2 = true;
      if (tanlanganArava == 3) taraSaqlangan3 = true;
      saqlanmoqda = true;
      qoldiqSoniya = 10;
    });
try {
      await ApiService.olchovSaqlash(
        hujjatId: tanlanganNavbat?.hujjatId ?? hujjatId ?? 0,
        aravaRaqam: tanlanganArava,
        tara: taroziKg,
        namlik: double.tryParse(namlikCtrl.text),
        ifloslik:
            double.tryParse(ifloslikCtrl.text),
      );
   } catch (e) {
     print('tara olchovSaqlash xato: $e');
   }

    // Kamera rasm olish
    ApiService.rasmOl(
      mashinaRaqami: raqamiCtrl.text,
      mahsulotNomi: widget.mahsulotNomi,
      tur: 'tara',
    );

    final keyingi = _keyingiTaraSizArava();
    _xabar(keyingi != null
        ? "✅ $tanlanganArava-arava TARA — ${keyingi}-aravani qo'ying!"
        : "✅ Barcha tara saqlandi — Keyingi mashinani bosing!");
    _qoldiqTimer();
  }

  int? _keyingiBruttoSizArava() {
    for (int i = 1; i <= aravalarSoni; i++) {
      final ts = i == 1
          ? taraSaqlangan1
          : i == 2
              ? taraSaqlangan2
              : taraSaqlangan3;
      final bs = i == 1
          ? bruttoSaqlangan1
          : i == 2
              ? bruttoSaqlangan2
              : bruttoSaqlangan3;
      if (ts && !bs) return i;
    }
    return null;
  }

  int? _keyingiTaraSizArava() {
    for (int i = 1; i <= aravalarSoni; i++) {
      final ts = i == 1
          ? taraSaqlangan1
          : i == 2
              ? taraSaqlangan2
              : taraSaqlangan3;
      if (!ts) return i;
    }
    return null;
  }

  Future<void> _bazagaSaqla() async {
    if (bazagaSaqlandi) return;
    if (raqamiCtrl.text.trim().isEmpty) {
      _xabar("❌ Mashina raqamini kiriting!");
      return;
    }
    try {
      final mashina = await ApiService.mashinaQoshish(
        davlatRaqami: raqamiCtrl.text.trim(),
        turi: turiCtrl.text.trim(),
        shofyor: shofyorCtrl.text.trim(),
        firma: firmaCtrl.text.trim(),
      );
      mashinaId = mashina['id'];
      final hujjat = await ApiService.hujjatYaratish(
        mashinaId: mashinaId!,
        mahsulotId: widget.mahsulotId,
        aravalarSoni: aravalarSoni,
      );
      hujjatId = hujjat['id'];
      setState(() => bazagaSaqlandi = true);
    } catch (e) {
      _xabar("❌ Xato: $e");
    }
  }

  void _qoldiqTimer() {
    Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => qoldiqSoniya--);
      if (qoldiqSoniya <= 0) {
        t.cancel();
        setState(() => saqlanmoqda = false);
      }
    });
  }

  void hujjatOch() {
    final _tara1 = aravalar[1]?.tara ?? tanlanganNavbat?.aravalar[1]?.tara;
    final _brutto1 = aravalar[1]?.brutto ?? tanlanganNavbat?.aravalar[1]?.brutto;
    final _konditsion1 = aravalar[1]?.konditsion ?? tanlanganNavbat?.aravalar[1]?.konditsion;
    final _tara2 = aravalar[2]?.tara ?? tanlanganNavbat?.aravalar[2]?.tara;
    final _brutto2 = aravalar[2]?.brutto ?? tanlanganNavbat?.aravalar[2]?.brutto;
    final _konditsion2 = aravalar[2]?.konditsion ?? tanlanganNavbat?.aravalar[2]?.konditsion;
    final _tara3 = aravalar[3]?.tara ?? tanlanganNavbat?.aravalar[3]?.tara;
    final _brutto3 = aravalar[3]?.brutto ?? tanlanganNavbat?.aravalar[3]?.brutto;
    final _konditsion3 = aravalar[3]?.konditsion ?? tanlanganNavbat?.aravalar[3]?.konditsion;
    final _mashinaRaqami = raqamiCtrl.text;
    final _firma = firmaCtrl.text;
    final _tiketRaqam = tiketRaqamCtrl.text;
    final _hujjatId = hujjatId ?? tanlanganNavbat?.hujjatId;
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NakladnoyScreen(
            mashinaRaqami: _mashinaRaqami,
            mashinaTuri: turiCtrl.text,
            shofyor: shofyorCtrl.text,
           firma: _firma,
            mahsulotNomi: widget.mahsulotNomi,
            yukNomi: mahsulotYukNomi,
            aravalarSoni: aravalarSoni,
            tara1: _tara1,
            brutto1: _brutto1,
            tara2: _tara2,
            brutto2: _brutto2,
            tara3: _tara3,
            brutto3: _brutto3,
            tudaRaqam: tudaRaqamCtrl.text,
            tiketRaqam: _tiketRaqam,
            seleksiyaNavi: seleksiyaNaviCtrl.text,
            klass: klassCtrl.text,
            terimTuri: terimTuriCtrl.text,
            ifloslik:
                double.tryParse(ifloslikCtrl.text),
            namlik:
                double.tryParse(namlikCtrl.text),
            qabulQildi: qabulQildiCtrl.text,
            yukOlindi: yukOlindiCtrl.text,
            dostaverka: dostaverkaCtrl.text,
            dostaverkaVaqt: dostaverkaVaqtCtrl.text,
            konditsion1: _konditsion1,
            konditsion2: _konditsion2,
            konditsion3: _konditsion3,
            sana: avtomatikSana,
            hujjatId: _hujjatId,
            hujjatRaqam: _hujjatId?.toString() ?? '',
          ),
        ));
  }

  String fmt(double? v) =>
      v == null ? "—" : "${v.toStringAsFixed(0)} kg";

  double? jamiTara() {
    final v = aravalar.entries
        .where((e) => e.key <= aravalarSoni)
        .map((e) => e.value.tara)
        .whereType<double>();
    return v.isEmpty ? null : v.reduce((a, b) => a + b);
  }

  double? jamiBrutto() {
    final v = aravalar.entries
        .where((e) => e.key <= aravalarSoni)
        .map((e) => e.value.brutto)
        .whereType<double>();
    return v.isEmpty ? null : v.reduce((a, b) => a + b);
  }

  double? jamiNetto() {
    final t = jamiTara();
    final b = jamiBrutto();
    return (t != null && b != null) ? b - t : null;
  }

  double? jamiKonditsion() {
    if (!konditsionBor) return null;
    final v = aravalar.entries
        .where((e) => e.key <= aravalarSoni)
        .map((e) => e.value.konditsion)
        .whereType<double>();
    return v.isEmpty ? null : v.reduce((a, b) => a + b);
  }

  Widget _karta({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kechagiRejim
            ? Colors.black.withValues(alpha: 0.35)
            : Colors.white.withValues(alpha: 0.82),
        border: Border.all(
            color: kechagiRejim
                ? const Color(0xFF2A4A2A)
                : cardBorder),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color:
                  Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: child,
    );
  }

  Widget cardLabel(IconData icon, String text,
      {Color? color}) {
    return Row(children: [
      Icon(icon, size: 15, color: color ?? greenLight),
      const SizedBox(width: 6),
      Text(text,
          style: TextStyle(
              fontSize: 11,
              color: color ?? mutedText,
              letterSpacing: 1,
              fontWeight: FontWeight.w600)),
    ]);
  }

  Widget infoField(
      String label, TextEditingController controller,
      {bool enabled = true,
      TextInputType? keyboardType}) {
    return Container(
      decoration: BoxDecoration(
        color: enabled
            ? Colors.white.withValues(alpha: 0.9)
            : const Color(0xFFEEEEEE),
        border: Border.all(
            color: enabled
                ? cardBorder
                : Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      padding:
          const EdgeInsets.symmetric(horizontal: 10),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: enabled
                ? const Color(0xFF1A4A08)
                : Colors.grey),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
              fontSize: 10, color: muted),
          border: InputBorder.none,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 9),
        ),
      ),
    );
  }

  Widget mrow(String label, String value,
      {bool special = false,
      bool gold = false,
      bool blue = false}) {
    Color bg = Colors.white.withValues(alpha: 0.8),
        border = cardBorder,
        textColor = const Color(0xFF1A4A08);
    if (special) {
      bg = greenBg;
      border = greenBorder;
      textColor = green;
    }
    if (gold) {
      bg = goldBg;
      border = goldBorder;
      textColor = goldColor;
    }
    if (blue) {
      bg = blueBg;
      border = const Color(0xFFA0C0E8);
      textColor = blueColor;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(8)),
      child: Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
          children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color:
                    textColor.withValues(alpha: 0.7))),
        Text(value,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: textColor)),
      ]),
    );
  }

  Widget aravaKarta(int n) {
    if (n > aravalarSoni) {
      return Container(
        padding: const EdgeInsets.symmetric(
            vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.4),
          border:
              Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
          Text("$n-arava",
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade400)),
          const SizedBox(height: 8),
          Icon(Icons.lock_outline,
              size: 20, color: Colors.grey.shade400),
          const SizedBox(height: 4),
          Text("Faol emas",
              style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade400)),
        ]),
      );
    }
    final taraS = n == 1
        ? taraSaqlangan1
        : n == 2
            ? taraSaqlangan2
            : taraSaqlangan3;
    final bruttoS = n == 1
        ? bruttoSaqlangan1
        : n == 2
            ? bruttoSaqlangan2
            : bruttoSaqlangan3;
    final tanlangan = tanlanganArava == n;
    final arava = aravalar[n]!;

    return GestureDetector(
      onTap: () => _aravaTanlash(n),
      child: AnimatedBuilder(
        animation: _aravaAnim,
        builder: (context, child) => Transform.scale(
          scale: tanlangan ? _aravaAnim.value : 1.0,
          child: AnimatedContainer(
            duration:
                const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
                vertical: 10, horizontal: 6),
            decoration: BoxDecoration(
              color: bruttoS
                  ? greenBg
                  : taraS
                      ? goldBg
                      : tanlangan
                          ? blueBg
                          : Colors.white
                              .withValues(alpha: 0.85),
              border: Border.all(
                color: tanlangan
                    ? blueColor
                    : bruttoS
                        ? greenBorder
                        : taraS
                            ? goldBorder
                            : cardBorder,
                width: tanlangan ? 2 : 1,
              ),
              borderRadius:
                  BorderRadius.circular(10),
              boxShadow: tanlangan
                  ? [
                      BoxShadow(
                          color: blueColor
                              .withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2))
                    ]
                  : [],
            ),
            child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
              Text("$n-arava",
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: tanlangan
                          ? blueColor
                          : const Color(
                              0xFF1A4A08))),
              const SizedBox(height: 6),
              Icon(
                bruttoS
                    ? Icons.check_circle
                    : taraS
                        ? Icons.timelapse
                        : Icons.radio_button_unchecked,
                size: 24,
                color: bruttoS
                    ? greenLight
                    : taraS
                        ? goldColor
                        : muted,
              ),
              const SizedBox(height: 3),
              Text(
                bruttoS
                    ? "Tugallandi"
                    : taraS
                        ? "Tara ✅"
                        : "Bo'sh",
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: bruttoS
                        ? greenLight
                        : taraS
                            ? goldColor
                            : muted),
              ),
              if (taraS &&
                  arava.taraVaqt != null) ...[
                const SizedBox(height: 2),
                Text(arava.taraVaqt!,
                    style: const TextStyle(
                        fontSize: 9, color: muted)),
              ],
            ]),
          ),
        ),
      ),
    );
  }

  Widget camFrame(String label) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: kechagiRejim
              ? Colors.black.withValues(alpha: 0.5)
              : Colors.black.withValues(alpha: 0.06),
          border: Border.all(
              color: kechagiRejim
                  ? greenLight.withValues(alpha: 0.4)
                  : const Color(0xFFB0D890),
              width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(children: [
          Center(
              child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
            Icon(Icons.camera_alt_outlined,
                size: 32,
                color: kechagiRejim
                    ? greenLight
                        .withValues(alpha: 0.6)
                    : const Color(0xFFA0C0A0)),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color: kechagiRejim
                        ? greenLight
                            .withValues(alpha: 0.6)
                        : mutedText)),
          ])),
          Positioned(
              top: 8,
              right: 8,
              child: Row(children: [
                Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle)),
                const SizedBox(width: 4),
                const Text("REC",
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.red,
                        fontWeight:
                            FontWeight.w700)),
              ])),
        ]),
      ),
    );
  }

  Widget _sidebarIcon(IconData icon, bool active) {
    return Container(
      width: 38,
      height: 38,
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: active
            ? (kechagiRejim
                ? Colors.black.withValues(alpha: 0.3)
                : greenBg)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon,
          color: active
              ? (kechagiRejim ? greenLight : green)
              : muted,
          size: 18),
    );
  }

  Widget navbatItem(NavbatMashina mashina) {
    final tanlangan =
        tanlanganNavbat?.hujjatId == mashina.hujjatId;
    return GestureDetector(
      onTap: () => mashinaKor(mashina),
      child: Container(
        margin: const EdgeInsets.only(bottom: 5),
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: tanlangan
              ? blueBg.withValues(alpha: 0.9)
              : Colors.white.withValues(alpha: 0.7),
          border: Border.all(
              color:
                  tanlangan ? blueColor : cardBorder,
              width: tanlangan ? 2 : 1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tanlangan ? blueColor : goldBg,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.local_shipping,
                size: 11,
                color: tanlangan
                    ? Colors.white
                    : goldColor),
          ),
          const SizedBox(width: 8),
          Expanded(
              child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
            Text(mashina.raqam,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: tanlangan
                        ? blueColor
                        : const Color(0xFF1A4A08))),
            Text(
                "${mashina.vaqt} · ${mashina.mahsulotNomi}",
                style: const TextStyle(
                    fontSize: 10, color: muted)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: tanlangan ? blueColor : goldBg,
              borderRadius:
                  BorderRadius.circular(6),
            ),
            child: Text(
                tanlangan ? "Brutto" : "Kutmoqda",
                style: TextStyle(
                    fontSize: 10,
                    color: tanlangan
                        ? Colors.white
                        : goldColor)),
          ),
        ]),
      ),
    );
  }

  Widget tugallanganItem(NavbatMashina mashina) {
    return GestureDetector(
      onTap: () => mashinaKor(mashina),
      child: Container(
        margin: const EdgeInsets.only(bottom: 5),
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          border: Border.all(color: greenBorder),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
                color: greenLight,
                shape: BoxShape.circle),
            child: const Icon(Icons.check,
                size: 12, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Expanded(
              child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
            Text(mashina.raqam,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A4A08))),
            Row(children: [
              Text(mashina.vaqt,
                  style: const TextStyle(
                      fontSize: 10, color: muted)),
              if (mashina.tugallanganVaqt !=
                  null) ...[
                const Text(" → ",
                    style: TextStyle(
                        fontSize: 10, color: muted)),
                Text(
                  "${mashina.tugallanganVaqt!.hour.toString().padLeft(2, '0')}:${mashina.tugallanganVaqt!.minute.toString().padLeft(2, '0')}",
                  style: const TextStyle(
                      fontSize: 10, color: muted),
                ),
              ],
            ]),
          ])),
          const Icon(Icons.done_all,
              size: 16, color: greenLight),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
   final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;
    final jami = tanlanganArava == 0;
    final arava =
        jami ? null : aravalar[tanlanganArava];
    final tara = jami ? jamiTara() : arava?.tara;
    final brutto =
        jami ? jamiBrutto() : arava?.brutto;
    final netto = jami ? jamiNetto() : arava?.netto;
    final konditsion = konditsionBor
        ? (jami ? jamiKonditsion() : arava?.konditsion)
        : null;

    Widget kontent = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: kechagiRejim
              ? [
                  const Color(0xFF0A1A0A),
                  const Color(0xFF0D2A10),
                  const Color(0xFF0A1A0A)
                ]
              : [
                  const Color(0xFFE8F5E0),
                  const Color(0xFFF0F8E8),
                  const Color(0xFFE0F0D4)
                ],
        ),
      ),
     child: isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              // Mobile uchun vertikal
            ])
            : Row(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
        // SIDEBAR — faqat operator rejimda
        if (!widget.adminRejim)
          Container(
            width: 52,
            decoration: BoxDecoration(
              color: kechagiRejim
                  ? Colors.black
                      .withValues(alpha: 0.4)
                  : Colors.white
                      .withValues(alpha: 0.7),
              border: Border(
                  right:
                      BorderSide(color: cardBorder)),
            ),
            padding: const EdgeInsets.symmetric(
                vertical: 12),
            child: Column(children: [
              _sidebarIcon(Icons.scale, true),
              _sidebarIcon(
                  Icons.description_outlined, false),
              _sidebarIcon(
                  Icons.format_list_numbered, false),
              _sidebarIcon(
                  Icons.camera_alt_outlined, false),
            ]),
          ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(children: [
              IntrinsicHeight(
                child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                  // TAROZI
                  Expanded(
                    flex: 13,
                    child: _karta(
                        child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                      Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .spaceBetween,
                          children: [
                        cardLabel(
                            Icons
                                .settings_input_antenna,
                            "TAROZI — JONLI"),
                        Row(children: [
                          const Text("Aravalar:",
                              style: TextStyle(
                                  fontSize: 11,
                                  color: muted)),
                          const SizedBox(width: 6),
                          for (int i = 1; i <= 3; i++)
                            GestureDetector(
                              onTap: () => setState(
                                  () =>
                                      aravalarSoni =
                                          i),
                              child: Container(
                                width: 28,
                                height: 28,
                                margin: const EdgeInsets
                                    .only(left: 4),
                                alignment:
                                    Alignment.center,
                                decoration:
                                    BoxDecoration(
                                  color: aravalarSoni ==
                                          i
                                      ? greenLight
                                      : Colors.white
                                          .withValues(
                                              alpha:
                                                  0.7),
                                  border: Border.all(
                                      color:
                                          aravalarSoni ==
                                                  i
                                              ? greenLight
                                              : cardBorder),
                                  borderRadius:
                                      BorderRadius
                                          .circular(6),
                                ),
                                child: Text("$i",
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight:
                                            FontWeight
                                                .w700,
                                        color: aravalarSoni ==
                                                i
                                            ? Colors
                                                .white
                                            : mutedText)),
                              ),
                            ),
                        ]),
                      ]),
                      const SizedBox(height: 8),
                      Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.end,
                          children: [
                        Text(
                            taroziKg
                                .toStringAsFixed(0),
                            style: TextStyle(
                                fontSize: 52,
                                fontWeight:
                                    FontWeight.w700,
                                color: kechagiRejim
                                    ? greenLight
                                    : green,
                                letterSpacing: -1)),
                        const SizedBox(width: 8),
                        Padding(
                          padding:
                              const EdgeInsets.only(
                                  bottom: 8),
                          child: Text("kg",
                              style: TextStyle(
                                  fontSize: 17,
                                  color: mutedText)),
                        ),
                        const SizedBox(width: 12),
                        Padding(
                          padding:
                              const EdgeInsets.only(
                                  bottom: 10),
                          child: Container(
                            padding: const EdgeInsets
                                .symmetric(
                                horizontal: 10,
                                vertical: 4),
                            decoration: BoxDecoration(
                                color: taroziBarqaror
                                    ? greenBg
                                    : const Color(
                                        0xFFFFF0F0),
                                border: Border.all(
                                    color:
                                        taroziBarqaror
                                            ? greenBorder
                                            : const Color(
                                                0xFFF0B0A0)),
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                            20)),
                            child: Row(
                                mainAxisSize:
                                    MainAxisSize.min,
                                children: [
                              Icon(Icons.circle,
                                  size: 8,
                                  color:
                                      taroziBarqaror
                                          ? greenLight
                                          : Colors
                                              .red),
                              const SizedBox(width: 5),
                              Text(
                                  taroziBarqaror
                                      ? "Barqaror"
                                      : "Harakatda",
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: taroziBarqaror
                                          ? const Color(
                                              0xFF2A8A1A)
                                          : Colors
                                              .red)),
                            ]),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                            child: aravaKarta(1)),
                        const SizedBox(width: 6),
                        Expanded(
                            child: aravaKarta(2)),
                        const SizedBox(width: 6),
                        Expanded(
                            child: aravaKarta(3)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() =>
                                tanlanganArava = 0),
                            child: Container(
                              padding: const EdgeInsets
                                  .symmetric(
                                  horizontal: 6,
                                  vertical: 8),
                              decoration:
                                  BoxDecoration(
                                color:
                                    tanlanganArava ==
                                            0
                                        ? goldBg
                                        : Colors.white
                                            .withValues(
                                                alpha:
                                                    0.7),
                                border: Border.all(
                                    color: tanlanganArava ==
                                            0
                                        ? goldBorder
                                        : cardBorder,
                                    width:
                                        tanlanganArava ==
                                                0
                                            ? 2
                                            : 1),
                                borderRadius:
                                    BorderRadius
                                        .circular(10),
                              ),
                              child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment
                                          .center,
                                  children: [
                                Text("Jami",
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight:
                                            FontWeight
                                                .w700,
                                        color: tanlanganArava ==
                                                0
                                            ? goldColor
                                            : mutedText)),
                                const SizedBox(
                                    height: 3),
                                Text(
                                    fmt(jamiNetto()),
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight:
                                            FontWeight
                                                .w700,
                                        color: Color(
                                            0xFF1A7A08))),
                              ]),
                            ),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: (saqlanmoqda ||
                                  tanlanganArava == 0)
                              ? null
                              : saqlash,
                          icon: Icon(
                              saqlanmoqda
                                  ? Icons.hourglass_top
                                  : Icons.save,
                              size: 20),
                          label: Text(
                            saqlanmoqda
                                ? "$qoldiqSoniya soniya..."
                                : faqatBrutto
                                    ? "BRUTTO SAQLASH"
                                    : "TARA SAQLASH",
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight:
                                    FontWeight.w700),
                          ),
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                saqlanmoqda
                                    ? Colors.red
                                    : faqatBrutto
                                        ? blueColor
                                        : greenLight,
                            foregroundColor:
                                Colors.white,
                            padding: const EdgeInsets
                                .symmetric(
                                vertical: 14),
                            shape:
                                RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                                12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: keyingiMashina,
                          icon: const Icon(
                              Icons.arrow_forward,
                              size: 16,
                              color: blueColor),
                          label: const Text(
                              "Keyingi mashina",
                              style: TextStyle(
                                  fontSize: 13,
                                  color: blueColor,
                                  fontWeight:
                                      FontWeight
                                          .w700)),
                          style:
                              OutlinedButton.styleFrom(
                            backgroundColor: blueBg
                                .withValues(alpha: 0.7),
                            side: const BorderSide(
                                color: blueColor),
                            padding: const EdgeInsets
                                .symmetric(
                                vertical: 10),
                            shape:
                                RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                                10)),
                          ),
                        ),
                      ),
                      if (mashinaKelganVaqt !=
                          null) ...[
                        const SizedBox(height: 4),
                        Center(
                            child: Text(
                                "Mashina vaqti: ${_davomiylik(mashinaKelganVaqt!)}",
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: muted))),
                      ],
                    ])),
                  ),
                  const SizedBox(width: 12),
                  // MASHINA
                  Expanded(
                    flex: 8,
                    child: _karta(
                        child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                      cardLabel(Icons.local_shipping,
                          "MASHINA"),
                      const SizedBox(height: 8),
                      infoField("Davlat raqami",
                          raqamiCtrl,
                          enabled: !bazagaSaqlandi),
                      const SizedBox(height: 6),
                      infoField("Turi", turiCtrl,
                          enabled: !bazagaSaqlandi),
                      const SizedBox(height: 6),
                      infoField("Shofyor ismi",
                          shofyorCtrl,
                          enabled: !bazagaSaqlandi),
                      const SizedBox(height: 6),
                      infoField(
                          "Firma nomi", firmaCtrl),
                    ])),
                  ),
                  const SizedBox(width: 12),
                  // HUJJAT — faqat Chigit uchun
                  if (konditsionBor)
                    Expanded(
                      flex: 10,
                      child: _karta(
                          child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                        cardLabel(
                            Icons.article_outlined,
                            "HUJJAT"),
                        const SizedBox(height: 8),
                        Row(children: [
                          Expanded(
                              child: infoField(
                                  "Tiket №",
                                  tiketRaqamCtrl)),
                          const SizedBox(width: 6),
                          Expanded(
                              child: infoField(
                                  "Tuda №",
                                  tudaRaqamCtrl)),
                        ]),
                        const SizedBox(height: 6),
                        Row(children: [
                          Expanded(
                              child: infoField(
                                  "Klass", klassCtrl)),
                          const SizedBox(width: 6),
                          Expanded(
                              child: infoField(
                                  "Sinf", sinfCtrl)),
                        ]),
                        const SizedBox(height: 6),
                        infoField("Terim turi",
                            terimTuriCtrl),
                        const SizedBox(height: 6),
                        infoField("Seleksiya navi",
                            seleksiyaNaviCtrl),
                        const SizedBox(height: 6),
                        Row(children: [
                          Expanded(
                              child: infoField(
                                  "Namlik %",
                                  namlikCtrl,
                                  keyboardType:
                                      TextInputType
                                          .number)),
                          const SizedBox(width: 6),
                          Expanded(
                              child: infoField(
                                  "Ifloslik %",
                                  ifloslikCtrl,
                                  keyboardType:
                                      TextInputType
                                          .number)),
                        ]),
                      ])),
                    ),
                
                  const SizedBox(width: 12),
                  // NATIJALAR
                  Expanded(
                    flex: 7,
                    child: _karta(
                        child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                      cardLabel(
                          Icons.list_alt, "NATIJALAR"),
                      const SizedBox(height: 8),
                      mrow("Tara", fmt(tara)),
                      mrow("Brutto", fmt(brutto),
                          blue: true),
                      mrow("Netto", fmt(netto),
                          special: true),
                      if (konditsionBor)
                        mrow("Konditsion",
                            fmt(konditsion),
                            gold: true),
                    ])),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              IntrinsicHeight(
                child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                  // KAMERA
                  Expanded(
                    flex: 2,
                    child: _karta(
                        child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                      Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .spaceBetween,
                          children: [
                        cardLabel(Icons.videocam,
                            "KAMERALAR"),
                        Container(
                          padding: const EdgeInsets
                              .symmetric(
                              horizontal: 8,
                              vertical: 2),
                          decoration: BoxDecoration(
                              color: greenBg,
                              border: Border.all(
                                  color: greenBorder),
                              borderRadius:
                                  BorderRadius
                                      .circular(10)),
                          child: const Text("2 faol",
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Color(
                                      0xFF2A8A1A))),
                        ),
                      ]),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(
                            child:
                                camFrame("CAM-01")),
                        const SizedBox(width: 10),
                        Expanded(
                            child:
                                camFrame("CAM-02")),
                      ]),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: hujjatOch,
                          icon: const Icon(
                              Icons.print,
                              size: 16,
                              color:
                                  Color(0xFF8A6010)),
                          label: const Text(
                              "Nakladnoy chop etish",
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Color(
                                      0xFF8A6010))),
                          style:
                              OutlinedButton.styleFrom(
                                  backgroundColor:
                                      goldBg.withValues(
                                          alpha: 0.8),
                                  side: const BorderSide(
                                      color: Color(
                                          0xFFE8C878)),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                                  10))),
                        ),
                      ),
                    ])),
                  ),
                  const SizedBox(width: 12),
                  // DOSTAVERNA — faqat Chigit uchun
                  if (dostavernaBor) ...[
                    Expanded(
                      flex: 1,
                      child: _karta(
                          child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                        cardLabel(Icons.assignment,
                            "DOSTAVERNA"),
                        const SizedBox(height: 8),
                        infoField("№", dostaverkaCtrl),
                        const SizedBox(height: 6),
                        infoField("Muddat",
                            dostaverkaVaqtCtrl),
                        const SizedBox(height: 6),
                        infoField("Qabul qildi",
                            qabulQildiCtrl),
                        const SizedBox(height: 6),
                        infoField("Yuk olindi",
                            yukOlindiCtrl),
                      ])),
                    ),
                    const SizedBox(width: 12),
                  ],
                  // NAVBAT
                  Expanded(
                    flex: 1,
                    child: _karta(
                        child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                      Row(children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() =>
                                tugallanganlarKorinsin =
                                    false),
                            child: Container(
                              padding: const EdgeInsets
                                  .symmetric(
                                  vertical: 6),
                              decoration:
                                  BoxDecoration(
                                color:
                                    !tugallanganlarKorinsin
                                        ? goldBg
                                        : Colors
                                            .transparent,
                                border: Border.all(
                                    color: !tugallanganlarKorinsin
                                        ? goldBorder
                                        : Colors
                                            .transparent),
                                borderRadius:
                                    BorderRadius
                                        .circular(8),
                              ),
                              child: Text(
                                  "⏳ Navbat (${navbat.length})",
                                  textAlign:
                                      TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight:
                                          FontWeight
                                              .w700,
                                      color: !tugallanganlarKorinsin
                                          ? goldColor
                                          : muted)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() =>
                                tugallanganlarKorinsin =
                                    true),
                            child: Container(
                              padding: const EdgeInsets
                                  .symmetric(
                                  vertical: 6),
                              decoration:
                                  BoxDecoration(
                                color:
                                    tugallanganlarKorinsin
                                        ? greenBg
                                        : Colors
                                            .transparent,
                                border: Border.all(
                                    color: tugallanganlarKorinsin
                                        ? greenBorder
                                        : Colors
                                            .transparent),
                                borderRadius:
                                    BorderRadius
                                        .circular(8),
                              ),
                              child: Text(
                                  "✅ Tugallandi (${tugallanganlar.length})",
                                  textAlign:
                                      TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight:
                                          FontWeight
                                              .w700,
                                      color: tugallanganlarKorinsin
                                          ? greenLight
                                          : muted)),
                            ),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      if (!tugallanganlarKorinsin) ...[
                        if (navbat.isEmpty)
                          Center(
                              child: Padding(
                            padding: const EdgeInsets
                                .symmetric(
                                vertical: 16),
                            child: Column(children: [
                              Icon(
                                  Icons
                                      .local_shipping_outlined,
                                  size: 30,
                                  color: muted),
                              const SizedBox(height: 6),
                              Text("Navbat bo'sh",
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: muted)),
                            ]),
                          ))
                        else
                          ...navbat.map(
                              (m) => navbatItem(m)),
                      ] else ...[
                        if (tugallanganlar.isEmpty)
                          Center(
                              child: Padding(
                            padding: const EdgeInsets
                                .symmetric(
                                vertical: 16),
                            child: Column(children: [
                              Icon(Icons.done_all,
                                  size: 30,
                                  color: muted),
                              const SizedBox(height: 6),
                              Text(
                                  "Hali tugallanmagan",
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: muted)),
                            ]),
                          ))
                        else
                          ...tugallanganlar.map((m) =>
                              tugallanganItem(m)),
                      ],
                    ])),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ]),
    );

    if (widget.adminRejim) {
      return kontent;
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: kechagiRejim
                ? [
                    const Color(0xFF0A1A0A),
                    const Color(0xFF0D2A10),
                    const Color(0xFF0A1A0A)
                  ]
                : [
                    const Color(0xFFE8F5E0),
                    const Color(0xFFF0F8E8),
                    const Color(0xFFE0F0D4)
                  ],
          ),
        ),
        child: Column(children: [
          // TOPBAR
          Container(
            decoration: BoxDecoration(
              color: kechagiRejim
                  ? Colors.black
                      .withValues(alpha: 0.5)
                  : Colors.white
                      .withValues(alpha: 0.88),
              boxShadow: [
                BoxShadow(
                    color: Colors.black
                        .withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [
                        Color(0xFF1A7A08),
                        Color(0xFF3AAA1A)
                      ]),
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                  Icon(Icons.scale,
                      size: 14,
                      color: Colors.white),
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
                    color: goldBg,
                    border:
                        Border.all(color: goldBorder),
                    borderRadius:
                        BorderRadius.circular(20)),
                child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                  Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                          color: goldColor,
                          shape: BoxShape.circle)),
                  const SizedBox(width: 5),
                  Text(widget.mahsulotNomi,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF8A6010))),
                ]),
              ),
              if (bazagaSaqlandi) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: greenBg,
                      border: Border.all(
                          color: greenBorder),
                      borderRadius:
                          BorderRadius.circular(8)),
                  child: Text(
                      "Hujjat: ${hujjatId != null ? '2026/${hujjatId.toString().padLeft(3, '0')}' : '—'}",
                      style: const TextStyle(
                          fontSize: 11,
                          color: mutedText)),
                ),
              ],
              if (faqatBrutto) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: blueBg,
                      border: Border.all(
                          color: const Color(
                              0xFFA0C0E8)),
                      borderRadius:
                          BorderRadius.circular(8)),
                  child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                    const Icon(Icons.arrow_upward,
                        size: 11, color: blueColor),
                    const SizedBox(width: 3),
                    Text(
                        "BRUTTO — ${tanlanganNavbat!.raqam}",
                        style: const TextStyle(
                            fontSize: 11,
                            color: blueColor,
                            fontWeight:
                                FontWeight.w700)),
                  ]),
                ),
              ],
              if (xabarMatni.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: xabarMatni.startsWith('❌')
                        ? const Color(0xFFFFF0F0)
                        : greenBg,
                    border: Border.all(
                        color:
                            xabarMatni.startsWith('❌')
                                ? const Color(
                                    0xFFF0B0A0)
                                : greenBorder),
                    borderRadius:
                        BorderRadius.circular(8),
                  ),
                  child: Text(xabarMatni,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: xabarMatni
                                  .startsWith('❌')
                              ? const Color(0xFFC03030)
                              : greenLight)),
                ),
              ],
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: blueBg,
                    border: Border.all(
                        color:
                            const Color(0xFFA0C0E8)),
                    borderRadius:
                        BorderRadius.circular(8)),
                child: Text(
                    "Bugun: $bugunMashinalar ta · ${bugunTonnaj.toStringAsFixed(1)} t",
                    style: const TextStyle(
                        fontSize: 11,
                        color: blueColor)),
              ),
              const Spacer(),
              Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                      color: serverUlangan
                          ? greenLight
                          : Colors.red,
                      shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text(
                  serverUlangan
                      ? "Online"
                      : "Offline",
                  style: TextStyle(
                      fontSize: 11,
                      color: serverUlangan
                          ? greenLight
                          : Colors.red)),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                    color: kechagiRejim
                        ? Colors.black
                            .withValues(alpha: 0.3)
                        : greenBg,
                    border: Border.all(
                        color: greenBorder),
                    borderRadius:
                        BorderRadius.circular(8)),
                child: Text(hozirgiSoat,
                    style: TextStyle(
                        fontSize: 13,
                        fontFamily: 'monospace',
                        color: kechagiRejim
                            ? greenLight
                            : mutedText)),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() =>
                    kechagiRejim = !kechagiRejim),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                      color: kechagiRejim
                          ? Colors.black
                              .withValues(alpha: 0.3)
                          : Colors.white
                              .withValues(alpha: 0.7),
                      border: Border.all(
                          color: kechagiRejim
                              ? greenLight
                              : cardBorder),
                      borderRadius:
                          BorderRadius.circular(8)),
                  child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                    Icon(
                        kechagiRejim
                            ? Icons.nightlight_round
                            : Icons.wb_sunny,
                        size: 15,
                        color: kechagiRejim
                            ? greenLight
                            : goldColor),
                    const SizedBox(width: 3),
                    Text(
                        kechagiRejim
                            ? "Kecha"
                            : "Kunduz",
                        style: TextStyle(
                            fontSize: 11,
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
                    color: kechagiRejim
                        ? Colors.black
                            .withValues(alpha: 0.3)
                        : greenBg,
                    border: Border.all(
                        color: greenBorder),
                    borderRadius:
                        BorderRadius.circular(20)),
                child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                  const CircleAvatar(
                      radius: 12,
                      backgroundColor: greenLight,
                      child: Text("OP",
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.white))),
                  const SizedBox(width: 6),
                  Text(widget.username,
                      style: TextStyle(
                          fontSize: 11,
                          color: kechagiRejim
                              ? greenLight
                              : const Color(
                                  0xFF2A7A1A))),
                ]),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.logout,
                    color: Colors.redAccent, size: 17),
                onPressed: () =>
                    Navigator.popUntil(context,
                        (route) => route.isFirst),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ]),
          ),
          Expanded(child: kontent),
        ]),
      ),
    );
  }
}