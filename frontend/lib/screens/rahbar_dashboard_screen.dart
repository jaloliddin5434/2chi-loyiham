import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// "rahbar" roli uchun - faqat o'qish uchun mo'ljallangan, mobil-birinchi
/// umumiy ko'rinish. Boshqa admin bo'limlariga (foydalanuvchilar,
/// sozlamalar, backup) kirish yo'q - shu sabab bu Admin panelning
/// sidebar qobig'idan TASHQARIDA, alohida to'liq ekran sifatida ochiladi
/// (qarang: login_screen.dart, rol == "rahbar" bo'limi).
class RahbarDashboardScreen extends StatefulWidget {
  final String username;
  const RahbarDashboardScreen({super.key, required this.username});

  @override
  State<RahbarDashboardScreen> createState() => _RahbarDashboardScreenState();
}

class _RahbarDashboardScreenState extends State<RahbarDashboardScreen> {
  static const Color brandGreen = Color(0xFF0F6E56);
  static const Color bgPage = Color(0xFFF4F8F0);
  static const Color cardBorder = Color(0xFFD8EDD0);
  static const Color mutedText = Color(0xFF7AAA5A);
  static const Color goldColor = Color(0xFFC89020);
  static const Color redColor = Color(0xFFC03030);
  static const Color rahbarRang = Color(0xFF7B5EA7);
  static const Color darkText = Color(0xFF0D1B2A);

  bool yuklanmoqda = true;
  String? xato;
  Map<String, dynamic> kunlikStat = {};
  List<dynamic> navbat = [];
  List<dynamic> firmalar = [];

  final pinCtrl = TextEditingController();
  bool pinYuklanmoqda = false;
  String? pinXato;
  Map<String, dynamic>? moliyaviyKunlik;
  Map<String, dynamic>? moliyaviyOylik;
  bool moliyaviyYuklanmoqda = false;

  @override
  void initState() {
    super.initState();
    _malumotlarniYukla();
  }

  @override
  void dispose() {
    pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _malumotlarniYukla() async {
    setState(() {
      yuklanmoqda = true;
      xato = null;
    });
    try {
      final natijalar = await Future.wait([
        ApiService.getKunlikStat(),
        ApiService.navbatOl(),
        ApiService.getFirmalarStat('kunlik'),
      ]);
      if (!mounted) return;
      setState(() {
        kunlikStat = natijalar[0] as Map<String, dynamic>;
        navbat = natijalar[1] as List<dynamic>;
        firmalar = natijalar[2] as List<dynamic>;
        yuklanmoqda = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        yuklanmoqda = false;
        xato = "Ma'lumotlarni yuklab bo'lmadi - internetni tekshiring.";
      });
      return;
    }
    if (ApiService.moliyaviyOchiqmi) {
      await _moliyaviyHisobotniYukla();
    }
  }

  Future<void> _pinniTekshir() async {
    setState(() {
      pinYuklanmoqda = true;
      pinXato = null;
    });
    final xatoMatn = await ApiService.moliyaviyPinTekshir(pinCtrl.text.trim());
    if (!mounted) return;
    setState(() => pinYuklanmoqda = false);
    if (xatoMatn != null) {
      setState(() => pinXato = xatoMatn);
      return;
    }
    pinCtrl.clear();
    await _moliyaviyHisobotniYukla();
  }

  Future<void> _moliyaviyHisobotniYukla() async {
    setState(() => moliyaviyYuklanmoqda = true);
    final kunlik = await ApiService.moliyaviyHisobotOl('kunlik');
    final oylik = await ApiService.moliyaviyHisobotOl('oylik');
    if (!mounted) return;
    setState(() {
      moliyaviyKunlik = kunlik;
      moliyaviyOylik = oylik;
      moliyaviyYuklanmoqda = false;
    });
  }

  String _sonniFormatla(num son) {
    final str = son.round().toString();
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write(' ');
      buf.write(str[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgPage,
      appBar: _appBar(),
      body: yuklanmoqda
          ? const Center(child: CircularProgressIndicator(color: brandGreen))
          : xato != null
              ? _xatoHolati()
              : RefreshIndicator(
                  color: brandGreen,
                  onRefresh: _malumotlarniYukla,
                  child: ListView(
                    padding: const EdgeInsets.all(14),
                    children: [
                      _bugungiKartalar(),
                      const SizedBox(height: 14),
                      _navbatKartasi(),
                      const SizedBox(height: 14),
                      _firmalarKartasi(),
                      const SizedBox(height: 14),
                      _moliyaviyKartasi(),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
    );
  }

  PreferredSizeWidget _appBar() {
    return AppBar(
      backgroundColor: brandGreen,
      elevation: 0,
      titleSpacing: 12,
      title: Row(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.insights_rounded, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 8),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Smart Tarozi",
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, height: 1.1, color: Colors.white)),
            Text("Rahbar paneli",
                style: TextStyle(fontSize: 9, height: 1.1, color: Color(0xFFDCEFE6))),
          ],
        ),
      ]),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white70, size: 20),
          tooltip: "Chiqish",
          onPressed: () {
            ApiService.chiqish();
            Navigator.popUntil(context, (route) => route.isFirst);
          },
        ),
      ],
    );
  }

  Widget _xatoHolati() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off, color: redColor, size: 40),
          const SizedBox(height: 12),
          Text(xato!, textAlign: TextAlign.center, style: const TextStyle(color: redColor)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _malumotlarniYukla, child: const Text("Qayta urinish")),
        ]),
      ),
    );
  }

  Widget _kartaKonteyner({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }

  Widget _bugungiKartalar() {
    final tonnaj = "${kunlikStat['jami_tonnaj'] ?? 0}";
    final mashinaSoni = "${kunlikStat['mashinalar_soni'] ?? 0}";
    return Row(children: [
      Expanded(child: _heroStat("Bugungi netto", "$tonnaj t", Icons.scale, brandGreen)),
      const SizedBox(width: 10),
      Expanded(
          child: _heroStat("Mashinalar", mashinaSoni, Icons.local_shipping, const Color(0xFF1976D2))),
    ]);
  }

  Widget _heroStat(String label, String value, IconData icon, Color rang) {
    return _kartaKonteyner(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: rang, size: 20),
        const SizedBox(height: 10),
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: rang)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: mutedText)),
      ]),
    );
  }

  Widget _navbatKartasi() {
    return _kartaKonteyner(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.pending_actions, color: Color(0xFF1976D2), size: 18),
          const SizedBox(width: 6),
          const Text("Jarayondagi navbat",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: darkText)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: brandGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text("${navbat.length} ta",
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: brandGreen)),
          ),
        ]),
        const SizedBox(height: 10),
        if (navbat.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text("Hozircha navbatda mashina yo'q",
                style: TextStyle(fontSize: 12, color: mutedText)),
          )
        else
          ...navbat.take(8).map((n) => _navbatQatori(n)),
        if (navbat.length > 8)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text("+ yana ${navbat.length - 8} ta",
                style: const TextStyle(fontSize: 11, color: mutedText)),
          ),
      ]),
    );
  }

  Widget _navbatQatori(dynamic n) {
    final tortilmoqda = n['hujjatId'] != null;
    final holat = tortilmoqda ? "Tortilmoqda" : "Navbatda";
    final holatRang = tortilmoqda ? goldColor : mutedText;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: bgPage, borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.local_shipping_outlined, size: 16, color: Color(0xFF546E7A)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("${n['raqam'] ?? '—'}",
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: darkText)),
            Text("${n['mahsulotNomi'] ?? '—'}",
                style: const TextStyle(fontSize: 11, color: mutedText)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration:
              BoxDecoration(color: holatRang.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
          child: Text(holat, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: holatRang)),
        ),
      ]),
    );
  }

  Widget _firmalarKartasi() {
    final maxTonnaj = firmalar.isNotEmpty ? ((firmalar[0]['jami_tonnaj'] as num?) ?? 0).toDouble() : 0.0;
    return _kartaKonteyner(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.groups_outlined, color: rahbarRang, size: 18),
          SizedBox(width: 6),
          Text("Firma bo'yicha bugungi taqsimot",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: darkText)),
        ]),
        const SizedBox(height: 12),
        if (firmalar.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text("Bugun hali tugallangan hujjat yo'q",
                style: TextStyle(fontSize: 12, color: mutedText)),
          )
        else
          ...firmalar.take(6).map((f) => _firmaQatori(f, maxTonnaj)),
      ]),
    );
  }

  Widget _firmaQatori(dynamic f, double maxTonnaj) {
    final tonnaj = ((f['jami_tonnaj'] as num?) ?? 0).toDouble();
    final nisbat = maxTonnaj > 0 ? (tonnaj / maxTonnaj).clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text("${f['nom'] ?? '—'}",
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: darkText),
                overflow: TextOverflow.ellipsis),
          ),
          Text("$tonnaj t",
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: rahbarRang)),
        ]),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: nisbat,
            minHeight: 7,
            backgroundColor: bgPage,
            valueColor: const AlwaysStoppedAnimation(rahbarRang),
          ),
        ),
      ]),
    );
  }

  Widget _moliyaviyKartasi() {
    if (!ApiService.moliyaviyOchiqmi) {
      return _kartaKonteyner(child: _pinKirish());
    }
    return _kartaKonteyner(child: _moliyaviyIchki());
  }

  Widget _pinKirish() {
    return Column(children: [
      const Icon(Icons.lock_outline, color: goldColor, size: 34),
      const SizedBox(height: 10),
      const Text("Moliyaviy xulosa",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: darkText)),
      const SizedBox(height: 4),
      const Text("Ko'rish uchun 4 xonali PIN kiriting",
          style: TextStyle(fontSize: 11, color: mutedText)),
      const SizedBox(height: 14),
      TextField(
        controller: pinCtrl,
        obscureText: true,
        maxLength: 4,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 20, letterSpacing: 8),
        onSubmitted: (_) => _pinniTekshir(),
        decoration: InputDecoration(
          counterText: "",
          hintText: "••••",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          isDense: true,
        ),
      ),
      if (pinXato != null) ...[
        const SizedBox(height: 6),
        Text(pinXato!, style: const TextStyle(color: redColor, fontSize: 12)),
      ],
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: pinYuklanmoqda ? null : _pinniTekshir,
          style: ElevatedButton.styleFrom(
              backgroundColor: goldColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: pinYuklanmoqda
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : const Text("Ko'rish", style: TextStyle(color: Colors.white)),
        ),
      ),
    ]);
  }

  Widget _moliyaviyIchki() {
    if (moliyaviyYuklanmoqda) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 30),
        child: Center(child: CircularProgressIndicator(color: goldColor)),
      );
    }
    final kunlikDaromad = moliyaviyKunlik?['jami_daromad'] as num?;
    final oylikDaromad = moliyaviyOylik?['jami_daromad'] as num?;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(children: [
        Icon(Icons.attach_money, color: goldColor, size: 18),
        SizedBox(width: 6),
        Text("Moliyaviy xulosa",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: darkText)),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _moliyaviyStat("Bugungi daromad", kunlikDaromad)),
        const SizedBox(width: 10),
        Expanded(child: _moliyaviyStat("Oylik daromad", oylikDaromad)),
      ]),
    ]);
  }

  Widget _moliyaviyStat(String label, num? qiymat) {
    final matn = qiymat != null ? "${_sonniFormatla(qiymat)} so'm" : "—";
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: goldColor.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11, color: mutedText)),
        const SizedBox(height: 4),
        Text(matn,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: goldColor)),
      ]),
    );
  }
}
