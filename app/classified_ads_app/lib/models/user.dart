import '../utils/constants.dart';

class User {
  final int id;
  final String name;
  final String phone;
  final String? avatar;
  final String role;
  final bool isActive;
  final String? createdAt;
  final String? qrCode;
  final bool acceptsNotifications;
  final bool showPhoneNumber;
  User({
    required this.id,
    required this.name,
    required this.phone,
    this.avatar,
    required this.role,
    required this.isActive,
    this.createdAt,
    this.qrCode,
    this.acceptsNotifications = true,
    this.showPhoneNumber = true,
  });

  /// إنشاء User من JSON
  factory User.fromJson(Map<String, dynamic> json) {
    // ✅ التعرف على البيانات سواء كانت مغلفة بكلمة 'data' أو لا
    final Map<String, dynamic> data = json.containsKey('data') 
        ? Map<String, dynamic>.from(json['data']) 
        : json;

    return User(
      id: data['id'] ?? 0,
      name: data['name'] ?? 'User',
      phone: data['phone'] ?? '',
      avatar: _fixUrl(data['avatar_url'] ?? data['avatar']),
      role: data['role'] ?? 'user',
      isActive: data['is_active'] == 1 || data['is_active'] == true,
      createdAt: data['created_at'],
      qrCode: data['qr_code'],
      acceptsNotifications:
          data['accepts_notifications'] == 1 || data['accepts_notifications'] == true,
      showPhoneNumber:
          data['show_phone_number'] == 1 || data['show_phone_number'] == true,
    );
  }

  static String? _fixUrl(String? url) {
    if (url == null) return null;
    
    String fixedUrl = url;
    
    // If it's a relative path (doesn't start with http)
    if (!fixedUrl.startsWith('http')) {
      // Remove 'public/' if present (sometimes stored in DB)
      if (fixedUrl.startsWith('public/')) {
        fixedUrl = fixedUrl.replaceFirst('public/', '');
      }

      // Instead of 'storage/', use 'local-cdn/' for proxying
      if (fixedUrl.startsWith('storage/')) {
        fixedUrl = fixedUrl.replaceFirst('storage/', 'local-cdn/');
      } else if (!fixedUrl.startsWith('local-cdn/')) {
        fixedUrl = 'local-cdn/$fixedUrl';
      }
      
      fixedUrl = '${AppConstants.assetBaseUrl}/$fixedUrl';
    } else {
      // If it's an absolute URL but points to storage/, replace with local-cdn/
      if (fixedUrl.contains('/storage/')) {
        fixedUrl = fixedUrl.replaceAll('/storage/', '/local-cdn/');
      }
    }

    if (fixedUrl.contains('localhost') && AppConstants.baseUrl.contains('192.168.0.198')) {
      fixedUrl = fixedUrl.replaceFirst('localhost', '192.168.0.198');
    }

    // Cache busting for avatars
    if (fixedUrl.contains('avatar') || fixedUrl.contains('profile')) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      fixedUrl = fixedUrl.contains('?') ? '$fixedUrl&t=$timestamp' : '$fixedUrl?t=$timestamp';
    }

    return fixedUrl;
  }

  /// تحويل User إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'avatar': avatar,
      'role': role,
      'is_active': isActive,
      'created_at': createdAt,
      'qr_code': qrCode,
      'accepts_notifications': acceptsNotifications,
      'show_phone_number': showPhoneNumber,
    };
  }

  /// إنشاء نسخة من User مع إمكانية تعديل بعض القيم
  User copyWith({
    int? id,
    String? name,
    String? phone,
    String? avatar,
    String? role,
    bool? isActive,
    String? createdAt,
    String? qrCode,
    bool? acceptsNotifications,
    bool? showPhoneNumber,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      qrCode: qrCode ?? this.qrCode,
      acceptsNotifications: acceptsNotifications ?? this.acceptsNotifications,
      showPhoneNumber: showPhoneNumber ?? this.showPhoneNumber,
    );
  }
}
