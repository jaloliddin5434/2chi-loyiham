import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// "Joriy holat" bo'limi - admin-only ko'rish ilovasida (main_admin.dart)
/// ishlatiladi. Hozir navbatda turgan va so'nggi 24 soatda tugallangan
/// mashinalarni FAQAT KO'RSATADI (Tuzat/O'chir yo'q - bu ilova butunlay
/// ko'rish uchun, operatorning yozish amallariga ehtiyoj yo'q).
class JoriyHolatPaneli extends StatefulWidget {
  const JoriyHolatPaneli({super.key});

  @override
  State<JoriyHolatPaneli> createState() => _JoriyHolatPaneliState();
}

class _JoriyHolatPaneliState extends State<JoriyHolatPaneli> {
  static const Color asosiyRang = Color(0xFF2A6AB8);
  static const Color kartaBorder = Color(0xFFD8EDD0);
  static const Color muted = Color(0xFF9AC080);
  static const Color goldColor = Color(0xFFC89020);
  static const Color greenColor = Color(0xFF0F6E56);

  List<dynamic> navbat = [];
  List<dynamic> tugallanganlar = [];
  bool yuklanmoqda = true;
  String? xato;
  Timer? _yangilanishTimer;

  @override
  void initState() {
    super.initState();
    _yukla();
    _yangilanishTimer = Timer.periodic(const Duration(seconds: 5), (_) => _yukla(sokin: true));
  }

  @override
  void dispose() {
    _yangilanishTimer?.cancel();
    super.dispose();
  }

  Future<void> _yukla({bool sokin = false}) async {
    if (!sokin) setState(() => yuklanmoqda = true);
    try {
      final n = await ApiService.navbatOl();
      final t = await ApiService.tugallanganlarOl();
      if (!mounted) return;
      setState(() {
        navbat = n;
        tugallanganlar = t;
        yuklanmoqda = false;
        xato = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        yuklanmoqda = false;
        if (!sokin) xato = "Ma'lumot yuklanmadi: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (yuklanmoqda) {
      return const Center(child: CircularProgressIndicator(color: asosiyRang));
    }
    return RefreshIndicator(
      color: asosiyRang,
      onRefresh: _yukla,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (xato != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(10)),
              child: Text(xato!, style: TextStyle(color: Colors.red.shade600, fontSize: 12)),
            ),
          Row(children: [
            Expanded(child: _statKartasi("Navbatda", "${navbat.length}", Icons.hourglass_top, goldColor)),
            const SizedBox(width: 10),
            Expanded(child: _statKartasi("Tugallandi (24s)", "${tugallanganlar.length}", Icons.check_circle, greenColor)),
          ]),
          const SizedBox(height: 14),
          _bolim("NAVBATDAGI MASHINALAR", Icons.hourglass_top, goldColor,
              navbat, "Navbat bo'sh", Icons.local_shipping_outlined),
          const SizedBox(height: 14),
          _bolim("SO'NGGI 24 SOATDA TUGALLANGAN", Icons.check_circle, greenColor,
              tugallanganlar, "Hali hech narsa tugallanmagan", Icons.inbox_outlined),
        ],
      ),
    );
  }

  Widget _statKartasi(String sarlavha, String qiymat, IconData ikon, Color rang) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: kartaBorder),
          borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: rang.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(ikon, color: rang, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(qiymat, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0D1B2A))),
            Text(sarlavha, style: TextStyle(fontSize: 10, color: muted)),
          ]),
        ),
      ]),
    );
  }

  Widget _bolim(String sarlavha, IconData ikon, Color rang, List<dynamic> royxat,
      String boshMatn, IconData boshIkon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: kartaBorder),
          borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(ikon, size: 15, color: rang),
          const SizedBox(width: 6),
          Text(sarlavha, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: rang, letterSpacing: 0.5)),
        ]),
        const SizedBox(height: 10),
        if (royxat.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(children: [
                Icon(boshIkon, size: 30, color: muted),
                const SizedBox(height: 6),
                Text(boshMatn, style: TextStyle(fontSize: 12, color: muted)),
              ]),
            ),
          )
        else
          ...royxat.map((m) => _mashinaQatori(m, rang)),
      ]),
    );
  }

  Widget _mashinaQatori(Map<String, dynamic> m, Color rang) {
    final vaqt = m['tugallanganVaqt'] ?? m['vaqt'] ?? '—';
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
          color: rang.withOpacity(0.05),
          border: Border.all(color: rang.withOpacity(0.25)),
          borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Container(
          width: 22, height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: rang, shape: BoxShape.circle),
          child: const Icon(Icons.local_shipping, size: 12, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m['raqam'] ?? '—',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0D1B2A))),
            Text("${m['mahsulotNomi'] ?? '—'} · ${m['firma'] ?? '—'} · $vaqt",
                style: TextStyle(fontSize: 10, color: muted)),
          ]),
        ),
      ]),
    );
  }
}
