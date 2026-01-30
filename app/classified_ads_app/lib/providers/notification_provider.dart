import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final ApiService _apiService = ApiService.instance;
  List<dynamic> _notifications = [];
  bool _isLoading = false;
  int _unreadCount = 0;

  List<dynamic> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _unreadCount;

  NotificationProvider() {
    _initStream();
  }

  void _initStream() {
    // Listen to real-time notifications
    NotificationService.notificationStream.listen((data) {
      // Refresh notifications when a new one arrives
      fetchNotifications();
      // Optionally play a sound or vibration here if not handled by system notification
    });
  }

  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.client.get('/notifications');
      if (response.data['status'] == 'success') {
        _notifications = response.data['data']['data'];
        _unreadCount = response.data['unread_count'] ?? 0;
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      // Optimistic update
      final index = _notifications.indexWhere((n) => n['id'] == id);
      if (index != -1 && !_notifications[index]['is_read']) {
        _notifications[index]['is_read'] = true;
        _unreadCount = (_unreadCount - 1).clamp(0, 999);
        notifyListeners();
      }

      await _apiService.client.post('/notifications/$id/read', data: {});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      // Revert if needed (omitted for simplicity)
    }
  }

  Future<void> markAllAsRead() async {
    try {
      // Optimistic update
      for (var n in _notifications) {
        n['is_read'] = true;
      }
      _unreadCount = 0;
      notifyListeners();

      await _apiService.client.post('/notifications/read-all', data: {});
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  Future<void> deleteNotification(int id) async {
    try {
        _notifications.removeWhere((n) => n['id'] == id);
        notifyListeners();
        await _apiService.client.delete('/notifications/$id');
    } catch (e) {
        debugPrint('Error deleting notification: $e');
    }
  }
}
