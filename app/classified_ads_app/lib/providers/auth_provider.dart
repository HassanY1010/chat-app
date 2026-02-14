import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/session_service.dart';
import '../models/user.dart';

enum UserType { guest, registered }

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService.instance;
  final SessionService _sessionService = SessionService.instance;
  
  User? _user;
  bool _isLoading = false;
  bool _isCheckingAuth = true;
  String? _token;

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isCheckingAuth => _isCheckingAuth;
  bool get isAuthenticated => _user != null && _token != null;
  bool get isGuest => _user?.role.toLowerCase() == 'guest';
  
  UserType get currentUser => isGuest ? UserType.guest : UserType.registered;

  Future<void> loginWithPhone(String phone) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.client.post('/login', data: {
        'phone': phone,
      });

      _token = response.data['access_token'];
      _user = User.fromJson(response.data['data']);

      // ✅ واستخدام المهام الجديدة الموحدة لمدير الجلسة
      await _sessionService.saveToken(_token!);
      await _sessionService.saveUser(_user!);
      
      _apiService.setToken(_token!);
      NotificationService.connect(_user!.id, _token!);
      
      notifyListeners();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loginAsGuest() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.client.post('/guest-login');

      _token = response.data['access_token'];
      _user = User.fromJson(response.data['data']).copyWith(role: 'guest');

      // ✅ واستخدام المهام الجديدة الموحدة لمدير الجلسة
      await _sessionService.saveToken(_token!);
      await _sessionService.saveUser(_user!);
      
      _apiService.setToken(_token!);
      NotificationService.connect(_user!.id, _token!);
      
      notifyListeners();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loginAsAdmin(String phone, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.client.post('/admin/login', data: {
        'phone': phone,
        'password': password,
      });

      _token = response.data['access_token'];
      _user = User.fromJson(response.data['user']);

      await _sessionService.saveToken(_token!);
      await _sessionService.saveUser(_user!);
      
      _apiService.setToken(_token!);
      NotificationService.connect(_user!.id, _token!);
      
      notifyListeners();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendOtp(String phone) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.client.post('/auth/send-otp', data: {
        'phone': phone,
      });
    } catch (e) {
      if (e is DioException) {
        final message = e.response?.data['message'] ?? 'فشل إرسال الرمز';
        throw message;
      }
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyOtp(String phone, String code) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.client.post('/auth/verify-otp', data: {
        'phone': phone,
        'code': code,
      });

      if (response.data['valid'] == true) {
         _token = response.data['access_token'];
         _user = User.fromJson(response.data['data']);

         await _sessionService.saveToken(_token!);
         await _sessionService.saveUser(_user!);
         
         _apiService.setToken(_token!);
         NotificationService.connect(_user!.id, _token!);
         notifyListeners();
         return true;
      }
      return false;
    } catch (e) {
      if (e is DioException) {
        final message = e.response?.data['message'] ?? 'كود التحقق غير صحيح';
        throw message;
      }
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    String? name,
    String? phone,
    XFile? avatarFile,
    bool? acceptsNotifications,
    bool? showPhoneNumber,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final Map<String, dynamic> updateData = {};

      if (name != null) updateData['name'] = name;
      if (phone != null) updateData['phone'] = phone;
      if (acceptsNotifications != null) {
        updateData['accepts_notifications'] = acceptsNotifications ? 1 : 0;
      }
      if (showPhoneNumber != null) {
        updateData['show_phone_number'] = showPhoneNumber ? 1 : 0;
      }

      if (avatarFile != null) {
        if (kIsWeb) {
          final bytes = await avatarFile.readAsBytes();
          updateData['avatar'] = MultipartFile.fromBytes(
            bytes,
            filename: avatarFile.name,
            contentType: MediaType('image', 'jpeg'),
          );
        } else {
          updateData['avatar'] = await MultipartFile.fromFile(avatarFile.path);
        }
      }
      
      final response = await _apiService.client.post(
        '/profile/update',
        data: FormData.fromMap(updateData),
      );

      _user = User.fromJson(response.data['user'] ?? response.data['data']);
      
      // Update local storage
      if (_user != null) {
        await _sessionService.saveUser(_user!);
      }
      
      notifyListeners();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteAccount() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.client.delete('/profile');
      await logout();

    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> exportData() async {
    try {
      final response = await _apiService.client.get('/profile/export');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _apiService.client.post('/logout');
    } catch (e) {
      // Ignore logout errors
    } finally {
      _user = null;
      _token = null;
      await _sessionService.clearSession();
      _apiService.removeToken();
      NotificationService.disconnect();
      notifyListeners();
    }
  }

  Map<String, dynamic>? _dashboardStats;
  Map<String, dynamic>? get dashboardStats => _dashboardStats;

  Future<void> fetchDashboardStats() async {
    try {
      final response = await _apiService.client.get('/user/dashboard-stats');
      _dashboardStats = response.data;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching dashboard stats: $e');
    }
  }

  Future<void> submitAppReview(int rating, String? comment) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.client.post('/app-reviews', data: {
        'rating': rating,
        'comment': comment,
        'user_id': _user?.id,
      });
    } catch (e) {
      debugPrint('Error submitting review: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> checkAuth() async {
    if (_user != null && _token != null && !_isCheckingAuth) {
      return;
    }

    _isCheckingAuth = true;
    notifyListeners();
    
    // ✅ استرجاع البيانات الفوري من مدير الجلسة
    _token = _sessionService.getToken();
    _user = _sessionService.getUser();

    if (_token != null) {
      _apiService.setToken(_token!);
      
      if (_user != null) {
        // بمجرد استرجاع البيانات محلياً، نظهر الواجهة فوراً ثم نحدث البيانات في الخلفية
        _isCheckingAuth = false;
        notifyListeners();
        
        // ربط الإشعارات والبيانات فوراً
        NotificationService.connect(_user!.id, _token!);
        fetchDashboardStats();
      }
    }
      
    try {
      final response = await _apiService.client.get('/user').timeout(
        const Duration(seconds: 15),
      );
      
      final newUser = User.fromJson(response.data);
      
      if (newUser.id != 0) {
        _user = newUser;
        await _sessionService.saveUser(_user!);
      }
    } catch (e) {
      debugPrint('Auth check background refresh failed: $e');
      if (e is DioException && e.response?.statusCode == 401) {
        await logout();
      }
    } finally {
      _isCheckingAuth = false;
      notifyListeners();
    }
  }
}
