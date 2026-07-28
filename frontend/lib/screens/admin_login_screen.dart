import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'admin_ana_ekran.dart';

/// Admin-only ko'rish ilovasining (main_admin.dart) kirish nuqtasi -
/// oddiy ilovadagi kabi mahsulot/rol tanlash bosqichlari yo'q, to'g'ridan
/// -to'g'ri login formasi ko'rsatiladi, rol har doim "admin".
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  static const Color rang = Color(0xFF1565C0);

  final TextEditingController loginController = TextEditingController();
  final TextEditingController parolController = TextEditingController();
  bool yuklanmoqda = false;
  bool parolKorinsin = false;
  String? xato;

  @override
  void dispose() {
    loginController.dispose();
    parolController.dispose();
    super.dispose();
  }

  Future<void> kirish() async {
    setState(() {
      yuklanmoqda = true;
      xato = null;
    });
    try {
      final natija = await ApiService.login(
        loginController.text.trim(),
        parolController.text.trim(),
        'admin',
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AdminAnaEkran(username: natija['username']),
        ),
      );
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
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFE8F0FC),
                  const Color(0xFFF0F7FF),
                  rang.withOpacity(0.05),
                ],
              ),
            ),
          ),
          Positioned(
            top: -60, right: -60,
            child: _fonDoira(250, rang.withOpacity(0.07)),
          ),
          Positioned(
            bottom: -80, left: -80,
            child: _fonDoira(280, const Color(0xFF0F6E56).withOpacity(0.05)),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Container(
                  width: 380,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
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
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [rang, const Color(0xFF1976D2)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: rang.withOpacity(0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.admin_panel_settings_rounded,
                            color: Colors.white, size: 32),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Hazorasp Tekstil",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0D1B2A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "BOSHQARUV PANELI",
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 2.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF546E7A),
                        ),
                      ),
                      const SizedBox(height: 28),
                      TextField(
                        controller: loginController,
                        onSubmitted: (_) => kirish(),
                        decoration: InputDecoration(
                          labelText: "Login",
                          prefixIcon: Icon(Icons.person_outline, color: rang),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: rang, width: 2),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                        ),
                      ),
                      const SizedBox(height: 16),
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
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: rang, width: 2),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                        ),
                      ),
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
                              borderRadius: BorderRadius.circular(16),
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
