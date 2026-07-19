import 'package:flutter/material.dart';
import 'login_screen.dart';

class RolTanlashScreen extends StatefulWidget {
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
  State<RolTanlashScreen> createState() => _RolTanlashScreenState();
}

class _RolTanlashScreenState extends State<RolTanlashScreen> {
  int? hoverIndex;

  @override
  Widget build(BuildContext context) {
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
                  widget.rang.withOpacity(0.05),
                ],
              ),
            ),
          ),
          // Fon doiralari
          Positioned(
            top: -50, left: -50,
            child: _fonDoira(220, widget.rang.withOpacity(0.06)),
          ),
          Positioned(
            bottom: -60, right: -60,
            child: _fonDoira(260, const Color(0xFF1565C0).withOpacity(0.05)),
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
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: widget.rang.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: widget.rang.withOpacity(0.3)),
                        ),
                        child: Text(
                          widget.mahsulotNomi,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: widget.rang,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Asosiy kontent
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Icon
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: widget.rang.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: widget.rang.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              Icons.how_to_reg_rounded,
                              color: widget.rang,
                              size: 36,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Kim sifatida kirasiz?",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0D1B2A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Rolingizni tanlang",
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF546E7A),
                            ),
                          ),
                          const SizedBox(height: 36),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _rolKartasi(
                                context,
                                index: 0,
                                icon: Icons.person_rounded,
                                nom: "Operator",
                                tavsif: "O'lchov va hujjat",
                                rang: const Color(0xFF2E7D32),
                                rol: "operator",
                              ),
                              const SizedBox(width: 16),
                              _rolKartasi(
                                context,
                                index: 1,
                                icon: Icons.admin_panel_settings_rounded,
                                nom: "Admin",
                                tavsif: "To'liq boshqaruv",
                                rang: const Color(0xFF1565C0),
                                rol: "admin",
                              ),
                            ],
                          ),
                        ],
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

  Widget _rolKartasi(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String nom,
    required String tavsif,
    required Color rang,
    required String rol,
  }) {
    final isHover = hoverIndex == index;
    return MouseRegion(
      onEnter: (_) => setState(() => hoverIndex = index),
      onExit: (_) => setState(() => hoverIndex = null),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LoginScreen(
                mahsulotId: widget.mahsulotId,
                mahsulotNomi: widget.mahsulotNomi,
                mahsulotRang: rang,
                rol: rol,
                rolNomi: nom,
              ),
            ),
          );
        },
        child: AnimatedScale(
          scale: isHover ? 1.07 : 1.0,
          duration: const Duration(milliseconds: 180),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 150,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isHover ? rang : rang.withOpacity(0.25),
                width: isHover ? 2 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isHover
                      ? rang.withOpacity(0.2)
                      : Colors.black.withOpacity(0.06),
                  blurRadius: isHover ? 20 : 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isHover ? rang : rang.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: isHover ? Colors.white : rang,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  nom,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isHover ? rang : const Color(0xFF0D1B2A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  tavsif,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ),
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