import 'package:flutter/material.dart';
import 'screens/mahsulot_tanlash_screen.dart';
import 'services/sync_service.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SyncService.boshlash();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: ApiService.navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Hazorasp Tekstil Tarozi Tizimi',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Roboto',
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const MahsulotTanlashScreen(),
      },
    );
  }
}