import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'statistika_paneli.dart';
import 'hujjatlar_royxati_paneli.dart';
import 'joriy_holat_paneli.dart';
import 'admin_login_screen.dart';

/// Admin-only ko'rish ilovasining (main_admin.dart) asosiy ekrani - 3
/// bo'lim (Statistika/Hujjatlar/Joriy holat), pastki navigatsiya bilan.
/// Har bir bo'lim allaqachon mustaqil, faqat-ko'rish widget
/// ([StatistikaPaneli], [HujjatlarRoyxatiPaneli], [JoriyHolatPaneli]) -
/// bu ekran ularni faqat pastki navigatsiya ichiga joylashtiradi.
class AdminAnaEkran extends StatefulWidget {
  final String username;
  const AdminAnaEkran({super.key, required this.username});

  @override
  State<AdminAnaEkran> createState() => _AdminAnaEkranState();
}

class _AdminAnaEkranState extends State<AdminAnaEkran> {
  static const Color rang = Color(0xFF1565C0);

  int tanlanganBolim = 0;

  static const _bolimlar = [
    StatistikaPaneli(),
    HujjatlarRoyxatiPaneli(),
    JoriyHolatPaneli(),
  ];

  void chiqish() {
    ApiService.chiqish();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F0),
      appBar: AppBar(
        backgroundColor: rang,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Smart Tarozi · Admin",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, height: 1.1)),
            Text("Hazorasp Tekstil",
                style: TextStyle(fontSize: 10, color: Colors.white70, height: 1.1)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: Text(widget.username,
                  style: const TextStyle(fontSize: 12, color: Colors.white70)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, size: 20),
            tooltip: "Chiqish",
            onPressed: chiqish,
          ),
        ],
      ),
      body: IndexedStack(index: tanlanganBolim, children: _bolimlar),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tanlanganBolim,
        onDestinationSelected: (i) => setState(() => tanlanganBolim = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: "Statistika",
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
            label: "Hujjatlar",
          ),
          NavigationDestination(
            icon: Icon(Icons.hourglass_top_outlined),
            selectedIcon: Icon(Icons.hourglass_top),
            label: "Joriy holat",
          ),
        ],
      ),
    );
  }
}
