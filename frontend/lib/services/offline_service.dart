import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:convert';

class OfflineService {
  static const String _navbatKey = 'offline_navbat';
  static const String _mahsulotlarKey = 'offline_mahsulotlar';

  static Future<bool> internetBormi() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  static Future<void> navbatSaqla(List<dynamic> navbat) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_navbatKey, jsonEncode(navbat));
  }

  static Future<List<dynamic>> navbatOl() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_navbatKey);
    if (data == null) return [];
    return jsonDecode(data);
  }

  static Future<void> mahsulotlarSaqla(List<dynamic> mahsulotlar) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_mahsulotlarKey, jsonEncode(mahsulotlar));
  }

  static Future<List<dynamic>> mahsulotlarOl() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_mahsulotlarKey);
    if (data == null) return [];
    return jsonDecode(data);
  }
}