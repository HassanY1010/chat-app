import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../utils/constants.dart';

class ApiService {
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  static ApiService get instance => _instance;

  late final Dio _dio;

  // Private constructor
  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // ✅ Token interceptor - يعمل في جميع الأوضاع (debug & release)
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
          if (kDebugMode) {
            debugPrint('🔑 Added auth token to ${options.uri}');
          }
        } else {
          if (kDebugMode) {
            debugPrint('⚠️ No token found for ${options.uri}');
          }
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          debugPrint('✅ Response ${response.statusCode}: ${response.requestOptions.uri}');
        }
        return handler.next(response);
      },
      onError: (DioException e, handler) async {
        if (kDebugMode) {
          debugPrint('❌ API Error: ${e.type} for ${e.requestOptions.uri}');
        }

        final isNetworkError = e.type == DioExceptionType.connectionTimeout ||
                              e.type == DioExceptionType.connectionError ||
                              e.type == DioExceptionType.sendTimeout;

        // ✅ حل جذري ودائم: إذا فشل الاتصال، نقوم بإعادة البحث عن السيرفر وتكرار الطلب تلقائياً
        if (isNetworkError) {
          final options = e.requestOptions;
          
          // 🛑 منع حلقات التكرار اللانهائية
          if (options.headers.containsKey('x-retry-attempt')) {
            if (kDebugMode) {
              debugPrint('🛑 Request already retried once. Stopping to prevent infinite loop.');
            }
            return handler.next(e);
          }

          if (kDebugMode) {
            debugPrint('🔄 Connection failed. Retrying IP discovery...');
          }
          
          try {
            // 1. إعادة تشغيل البحث عن السيرفر
            await AppConstants.init(force: true); 
            final newUrl = AppConstants.baseUrl;
            
            if (kDebugMode) {
              debugPrint('🌐 Discovery finished. New URL: $newUrl');
            }

            // 2. تحديث الرابط في Dio للطلبات القادمة
            ApiService.instance.setBaseUrl(newUrl);

            // 3. إضافة علامة "تكرار" للطلب الحالي لمنع اللوب
            options.headers['x-retry-attempt'] = '1';
            
            // 4. تأخير بسيط قبل إعادة المحاولة لضمان استقرار الشبكة
            await Future.delayed(const Duration(milliseconds: 500));

            // تحديث الرابط في خيارات الطلب الحالي
            String path = options.path;
            if (path.startsWith('http')) {
              final uri = Uri.parse(newUrl);
              final oldUri = Uri.parse(path);
              path = oldUri.replace(
                scheme: uri.scheme,
                host: uri.host,
                port: uri.port,
              ).toString();
            }

            final retryResponse = await _dio.request(
              path,
              data: options.data,
              queryParameters: options.queryParameters,
              options: Options(
                method: options.method,
                headers: options.headers,
              ),
            );

            return handler.resolve(retryResponse);
          } catch (retryError) {
            if (kDebugMode) {
              debugPrint('❌ Retry failed: $retryError');
            }
          }
        }

        // Global 401 handling
        if (e.response?.statusCode == 401) {
          debugPrint('🔑 Session expired or invalid (401)');
        }

        return handler.next(e);
      },
    ));
    
    // Logging interceptor - فقط في debug mode
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
        logPrint: (obj) {
          debugPrint('🌐 API: $obj');
        },
      ));
    }
  }

  /// Set token immediately without waiting for SharedPreferences
  void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
    if (kDebugMode) {
      debugPrint('🔑 Token set immediately on singleton instance');
    }
  }

  /// Remove token
  void removeToken() {
    _dio.options.headers.remove('Authorization');
    if (kDebugMode) {
      debugPrint('🔓 Token removed from singleton instance');
    }
  }

  /// Update base URL dynamically
  void setBaseUrl(String newUrl) {
    _dio.options.baseUrl = newUrl;
    if (kDebugMode) {
      debugPrint('🌐 API BaseURL updated to: $newUrl');
    }
  }

  Dio get client => _dio;
}
