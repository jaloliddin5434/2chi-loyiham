import 'package:flutter/material.dart';
import 'screens/admin_login_screen.dart';
import 'services/api_service.dart';

/// Admin-only ko'rish ilovasining kirish nuqtasi. Oddiy `main.dart`dan
/// farqli - mahsulot/rol tanlash ekranlari va operator oqimi (offline
/// yozish navbati, sinxronizatsiya) yo'q, chunki bu ilova FAQAT ko'rish
/// uchun (Statistika/Hujjatlar/Joriy holat). Qurish:
/// `flutter build apk --target=lib/main_admin.dart`.
void main() {
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: ApiService.navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Hazorasp Tekstil — Admin',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      home: const AdminLoginScreen(),
    );
  }
}
