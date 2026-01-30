import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/guest_placeholder.dart';
import '../providers/notification_provider.dart';
import '../providers/auth_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<NotificationProvider>().fetchNotifications();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    if (authProvider.currentUser == UserType.guest) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFF),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF64748B)),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        body: const GuestPlaceholder(
          message: 'يجب عليك تسجيل الدخول لعرض الإشعارات',
          icon: Icons.notifications_off_outlined,
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'الإشعارات',
          style: TextStyle(
            fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
          ),
        ),
        centerTitle: true,
        surfaceTintColor: Colors.white,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded, color: Color(0xFF00B0FF)),
            onPressed: () {
              context.read<NotificationProvider>().markAllAsRead();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'تم تحديد الكل كمقروء',
                    style: TextStyle(
                      fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                    ),
                  ),
                ),
              );
            },
            tooltip: 'تحديد الكل كمقروء',
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_rounded, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد إشعارات حالياً',
                    style: TextStyle(
                      fontSize: 18, 
                      color: Colors.grey.shade500,
                      fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchNotifications(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.notifications.length,
              itemBuilder: (context, index) {
                final notification = provider.notifications[index];
                return Dismissible(
                  key: Key(notification['id'].toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.centerLeft,
                    child: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                  ),
                  onDismissed: (direction) {
                    provider.deleteNotification(notification['id']);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: notification['is_read'] ? Colors.white : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(13),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: notification['is_read'] 
                          ? null 
                          : Border.all(color: Colors.blue.withAlpha(50)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getIconColor(notification['type']).withAlpha(26),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getIcon(notification['type']),
                          color: _getIconColor(notification['type']),
                        ),
                      ),
                      title: Text(
                        notification['title'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A237E),
                          decoration: notification['is_read'] ? null : TextDecoration.none,
                          fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            notification['message'],
                            style: TextStyle(
                              color: Colors.grey.shade700, 
                              height: 1.5,
                              fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            notification['created_at'] ?? '',
                            style: TextStyle(
                              fontSize: 12, 
                              color: Colors.grey.shade500,
                              fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                         if (!notification['is_read']) {
                            provider.markAsRead(notification['id']);
                         }
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'success':
        return Colors.green;
      case 'follow':
        return Colors.purple;
      case 'comment':
        return Colors.orange;
      case 'alert':
        return Colors.orange;
      case 'error':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'success':
        return Icons.check_circle_rounded;
      case 'follow':
        return Icons.person_add_rounded;
      case 'comment':
        return Icons.comment_rounded;
      case 'alert':
        return Icons.notifications_active_rounded;
      case 'error':
        return Icons.error_rounded;
      default:
        return Icons.info_rounded;
    }
  }
}