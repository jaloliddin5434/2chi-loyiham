import 'package:flutter/material.dart';
import 'login_screen.dart';

class RolTanlashScreen extends StatelessWidget {
  final int mahsulotId;
  final String mahsulotNomi;
  final Color rang;

  const RolTanlashScreen({
    super.key,
    required this.mahsulotId,
    required this.mahsulotNomi,
    required this.rang,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F8F0),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF3A8A1A)),
        title: Text(
          mahsulotNomi,
          style: const TextStyle(color: Color(0xFF1A4A08)),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Kim sifatida kirasiz?",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A4A08),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _rolKartasi(
                      context,
                      icon: Icons.person,
                      nom: "Operator",
                      tavsif: "O'lchov va hujjat",
                      rang: const Color(0xFF3AAA1A),
                      rol: "operator",
                    ),
                    const SizedBox(width: 16),
                    _rolKartasi(
                      context,
                      icon: Icons.admin_panel_settings,
                      nom: "Admin",
                      tavsif: "To'liq boshqaruv",
                      rang: const Color(0xFF2A6AB8),
                      rol: "admin",
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _rolKartasi(
    BuildContext context, {
    required IconData icon,
    required String nom,
    required String tavsif,
    required Color rang,
    required String rol,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LoginScreen(
              mahsulotId: mahsulotId,
              mahsulotNomi: mahsulotNomi,
              mahsulotRang: rang,
              rol: rol,
              rolNomi: nom,
            ),
          ),
        );
      },
      child: Container(
        width: 150,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: rang, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: rang),
            const SizedBox(height: 12),
            Text(
              nom,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: rang,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              tavsif,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}