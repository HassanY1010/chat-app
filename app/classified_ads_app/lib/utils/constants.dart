import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:shared_preferences/shared_preferences.dart';

class AppConstants {
  // 🟢 PRODUCTION URL (Railway)
  static const String _productionUrl = 'https://backendapp-production-878a.up.railway.app/api/v1';

  static String _detectedUrl = _productionUrl;
  
  // Initialize simply returns the prod URL
  static Future<void> init({bool force = false}) async {
      _detectedUrl = _productionUrl;
      // Clear legacy cache to avoid issues
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_working_api_url');
      if (kDebugMode) {
        print('🚀 App Initialized in Production Mode: $_detectedUrl');
      }
  }

  static String get baseUrl => _detectedUrl;
  static String get assetBaseUrl => 'https://backendapp-production-878a.up.railway.app';
  
  static const String appName = 'لقطة';
  static const String appLink = 'https://laqta.app/download';
}
