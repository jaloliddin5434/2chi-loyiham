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
  bool parolKorinsin = false;
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
    final rang = widget.mahsulotRang;
    return Scaffold(
      body: Stack(
        children: [
          // Fon gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFE8F5E9),
                  const Color(0xFFF0F7FF),
                  rang.withOpacity(0.05),
                ],
              ),
            ),
          ),
          // Fon doiralari
          Positioned(
            top: -60, right: -60,
            child: _fonDoira(250, rang.withOpacity(0.07)),
          ),
          Positioned(
            bottom: -80, left: -80,
            child: _fonDoira(280, const Color(0xFF1565C0).withOpacity(0.05)),
          ),
          // Kontent
          SafeArea(
            child: Column(
              children: [
                // AppBar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios, size: 20),
                        color: const Color(0xFF37474F),
                      ),
                    ],
                  ),
                ),
                // Login card
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Container(
                        width: 380,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: rang.withOpacity(0.1),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Rol badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: rang.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: rang.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    widget.rol == 'admin'
                                        ? Icons.admin_panel_settings_rounded
                                        : Icons.person_rounded,
                                    color: rang,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "${widget.mahsulotNomi} · ${widget.rolNomi}",
                                    style: TextStyle(
                                      color: rang,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Sarlavha
                            const Text(
                              "Tizimga kirish",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0D1B2A),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              "Login va parolingizni kiriting",
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF546E7A),
                              ),
                            ),
                            const SizedBox(height: 28),
                            // Login
                            TextField(
                              controller: loginController,
                              onSubmitted: (_) => kirish(),
                              decoration: InputDecoration(
                                labelText: "Login",
                                prefixIcon: Icon(Icons.person_outline, color: rang),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: rang, width: 2),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Parol
                            TextField(
                              controller: parolController,
                              obscureText: !parolKorinsin,
                              onSubmitted: (_) => kirish(),
                              decoration: InputDecoration(
                                labelText: "Parol",
                                prefixIcon: Icon(Icons.lock_outline, color: rang),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    parolKorinsin ? Icons.visibility_off : Icons.visibility,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () => setState(() => parolKorinsin = !parolKorinsin),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: rang, width: 2),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                              ),
                            ),
                            // Xato
                            if (xato != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.red.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline, color: Colors.red.shade400, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      xato!,
                                      style: TextStyle(color: Colors.red.shade600, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            // Kirish tugmasi
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: yuklanmoqda ? null : kirish,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: rang,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: yuklanmoqda
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : const Text(
                                        "Tizimga kirish",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fonDoira(double size, Color rang) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: rang, shape: BoxShape.circle),
    );
  }
}