 import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'operator_panel_screen.dart';
import 'admin_panel_screen.dart';

class LoginScreen extends StatefulWidget {
  final int mahsulotId;
  final String mahsulotNomi;
  final Color mahsulotRang;
  final String rol;
  final String rolNomi;

  const LoginScreen({
    super.key,
    required this.mahsulotId,
    required this.mahsulotNomi,
    required this.mahsulotRang,
    required this.rol,
    required this.rolNomi,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController loginController = TextEditingController();
  final TextEditingController parolController = TextEditingController();
  bool yuklanmoqda = false;
  String? xato;

  Future<void> kirish() async {
    setState(() {
      yuklanmoqda = true;
      xato = null;
    });
    try {
      final natija = await ApiService.login(
        loginController.text.trim(),
        parolController.text.trim(),
        widget.rol,
      );
      setState(() => yuklanmoqda = false);
      if (!mounted) return;
      if (widget.rol == "operator") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OperatorPanelScreen(
              username: natija['username'],
              mahsulotId: widget.mahsulotId,
              mahsulotNomi: widget.mahsulotNomi,
              mahsulotRang: widget.mahsulotRang,
            ),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AdminPanelScreen(
              username: natija['username'],
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        yuklanmoqda = false;
        xato = "Login yoki parol noto'g'ri!";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F8F0),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF3A8A1A)),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              width: 360,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: widget.mahsulotRang.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: widget.mahsulotRang),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle,
                          color: widget.mahsulotRang, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        "${widget.mahsulotNomi} · ${widget.rolNomi}",
                        style: TextStyle(
                          color: widget.mahsulotRang,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: loginController,
                  decoration: InputDecoration(
                    labelText: "Login",
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: parolController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Parol",
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                if (xato != null) ...[
                  const SizedBox(height: 12),
                  Text(xato!,
                      style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: yuklanmoqda ? null : kirish,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3AAA1A),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: yuklanmoqda
                        ? const CircularProgressIndicator(
                            color: Colors.white)
                        : const Text("Tizimga kirish",
                            style: TextStyle(
                                color: Colors.white, fontSize: 16)),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}