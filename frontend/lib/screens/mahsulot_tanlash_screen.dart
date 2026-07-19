import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/offline_service.dart';
import 'rol_tanlash_screen.dart';

class MahsulotTanlashScreen extends StatefulWidget {
  const MahsulotTanlashScreen({super.key});

  @override
  State<MahsulotTanlashScreen> createState() => _MahsulotTanlashScreenState();
}

class _MahsulotTanlashScreenState extends State<MahsulotTanlashScreen> {
  List<dynamic> mahsulotlar = [];
  bool yuklanmoqda = true;
  int? hoverIndex;

  @override
  void initState() {
    super.initState();
    mahsulotlarniYuklash();
  }

  Future<void> mahsulotlarniYuklash() async {
    try {
      final data = await ApiService.getMahsulotlar();
      await OfflineService.mahsulotlarSaqla(data);
      setState(() {
        mahsulotlar = data;
        yuklanmoqda = false;
      });
    } catch (e) {
      final localMahsulotlar = await OfflineService.mahsulotlarOl();
      setState(() {
        yuklanmoqda = false;
        mahsulotlar = localMahsulotlar.isNotEmpty ? localMahsulotlar : [
          {"id": 1, "nom": "Chigit", "konditsiya_bor": true},
          {"id": 2, "nom": "Chiganoq", "konditsiya_bor": false},
          {"id": 3, "nom": "Chiganoq po'chog'i", "konditsiya_bor": false},
          {"id": 4, "nom": "Patoz", "konditsiya_bor": false},
        ];
      });
    }
  }

  final List<Map<String, dynamic>> _config = [
    {'rang': const Color(0xFFD97706), 'fon': const Color(0xFFFEF3E2)},
    {'rang': const Color(0xFF0F9D6C), 'fon': const Color(0xFFE7F7F1)},
    {'rang': const Color(0xFFC2461A), 'fon': const Color(0xFFFDEDE7)},
    {'rang': const Color(0xFF1D62D6), 'fon': const Color(0xFFEAF1FD)},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fon
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE8F5E9),
                  Color(0xFFF0F7FF),
                  Color(0xFFFFFDE7),
                ],
              ),
            ),
          ),
          // Fon paxta naqshlari
          Positioned(top: -40, left: -40,
            child: _fonDoira(200, const Color(0xFF4CAF50).withOpacity(0.07))),
          Positioned(bottom: -60, right: -60,
            child: _fonDoira(250, const Color(0xFF1565C0).withOpacity(0.06))),
          Positioned(top: 100, right: 30,
            child: _fonDoira(100, const Color(0xFFFF8F00).withOpacity(0.07))),
          Positioned(bottom: 100, left: 30,
            child: _fonDoira(120, const Color(0xFFD32F2F).withOpacity(0.05))),
          // Asosiy kontent
          SafeArea(
            child: Center(
              child: yuklanmoqda
                  ? const CircularProgressIndicator(color: Color(0xFF1565C0))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF1565C0).withOpacity(0.35),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.scale, color: Colors.white, size: 40),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Hazorasp Tekstil",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0D1B2A),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "PAXTA TAROZI NAZORAT TIZIMI",
                            style: TextStyle(
                              fontSize: 11,
                              letterSpacing: 2.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF546E7A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 2,
                            width: 60,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4CAF50), Color(0xFF1565C0)],
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 28),
                          const Text(
                            "Mahsulot turini tanlang",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF37474F),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            alignment: WrapAlignment.center,
                            children: List.generate(mahsulotlar.length, (index) {
                              final m = mahsulotlar[index];
                              final config = _config[index % _config.length];
                              final rang = config['rang'] as Color;
                              final fon = config['fon'] as Color;
                              final isHover = hoverIndex == index;
                              return MouseRegion(
                                onEnter: (_) => setState(() => hoverIndex = index),
                                onExit: (_) => setState(() => hoverIndex = null),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => RolTanlashScreen(
                                          mahsulotId: m['id'],
                                          mahsulotNomi: m['nom'],
                                          rang: rang,
                                        ),
                                      ),
                                    );
                                  },
                                  child: AnimatedScale(
                                    scale: isHover ? 1.07 : 1.0,
                                    duration: const Duration(milliseconds: 180),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 180),
                                      width: 155,
                                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
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
                                            width: 64,
                                            height: 64,
                                            decoration: BoxDecoration(
                                              color: isHover ? rang : fon,
                                              borderRadius: BorderRadius.circular(18),
                                            ),
                                            child: Center(
                                              child: Text(
                                                "${index + 1}",
                                                style: TextStyle(
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.w800,
                                                  color: isHover ? Colors.white : rang,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 14),
                                          Text(
                                            m['nom'],
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF0D1B2A),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 36),
                          Text(
                            "© 2026 Hazorasp Tekstil MChJ",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
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
      decoration: BoxDecoration(
        color: rang,
        shape: BoxShape.circle,
      ),
    );
  }
}