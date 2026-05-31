import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class ApiEndpoints {
  // Production URL (Hostinger)
  static const String baseUrl = 'https://pencatatan.nipinata.com/api';

  // Untuk testing lokal, silakan gunakan konfigurasi di bawah ini:
  /*
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api';
    } else if (Platform.isAndroid || Platform.isIOS) {
      return 'http://10.5.50.8:8000/api';
    } else {
      return 'http://127.0.0.1:8000/api';
    }
  }
  */
  static String get login => '$baseUrl/login';
  static String get register => '$baseUrl/register';
  static String get logout => '$baseUrl/logout';

  static String get dashboard => '$baseUrl/dashboard';
  static String get products => '$baseUrl/products';
  static String get sales => '$baseUrl/sales';
  static String get saleSuggestions => '$sales/suggestions';
  static String get expenses => '$baseUrl/expenses';
}
