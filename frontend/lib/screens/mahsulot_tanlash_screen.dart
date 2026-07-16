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
      setState(() {
        yuklanmoqda = false;
        mahsulotlar = [
          {"id": 1, "nom": "Chigit", "konditsiya_bor": true},
          {"id": 2, "nom": "Chiganoq", "konditsiya_bor": false},
        {"id": 3, "nom": "Chiganoq po'chog'i", "konditsiya_bor": false},
          {"id": 4, "nom": "Patoz", "konditsiya_bor": false},
        ];
      });
    }
  }

  Color rangOl(int index) {
    final ranglar = [Colors.amber, Colors.green, Colors.deepOrange, Colors.red];
    return ranglar[index % ranglar.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F0),
      body: SafeArea(
        child: Center(
          child: yuklanmoqda
              ? const CircularProgressIndicator()
              : Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Hazorasp Tekstil",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1A4A08),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "TAROZI NAZORAT TIZIMI",
                        style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 2,
                          color: Color(0xFF5AAA2A),
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        "Mahsulot turini tanlang",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1A4A08),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        alignment: WrapAlignment.center,
                        children: List.generate(mahsulotlar.length, (index) {
                          final m = mahsulotlar[index];
                          final rang = rangOl(index);
                          return GestureDetector(
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
                            child: Container(
                              width: 160,
                              padding: const EdgeInsets.all(20),
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
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: rang.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: rang),
                                    ),
                                    child: Center(
                                      child: Text(
                                        "${index + 1}",
                                        style: TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w600,
                                          color: rang,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    m['nom'],
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF1A3A08),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}