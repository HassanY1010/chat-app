import 'package:flutter/foundation.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import 'dart:async';


class NotificationService {
  static PusherChannelsFlutter? _pusher;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  // Stream controller to broadcast notifications to the app
  static final StreamController<Map<String, dynamic>> _notificationStreamController = StreamController.broadcast();
  static Stream<Map<String, dynamic>> get notificationStream => _notificationStreamController.stream;

  // Initialize Local Notifications
  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Notification clicked: ${details.payload}');
      },
    );
  }

  // Connect to Pusher
  static Future<void> connect(int userId, String token) async {
    if (_pusher != null) return; // Already connected

    debugPrint('🔌 Connecting to Pusher for User: $userId');

    try {
      _pusher = PusherChannelsFlutter.getInstance();
      
      await _pusher!.init(
        apiKey: 'e4d91eea6f30eee94550',
        cluster: 'ap2',
        onConnectionStateChange: (currentState, previousState) {
          debugPrint("🔌 Pusher Connection State: $currentState");
        },
        onError: (message, code, error) {
          debugPrint("❌ Pusher Error: $message (code: $code)");
        },
        onSubscriptionSucceeded: (String? channelName, dynamic data) {
          debugPrint("✅ Subscribed to: ${channelName ?? 'unknown'}");
        },
        onEvent: (event) {
          // Ignore internal Pusher events
          if (event is PusherEvent) {
            final eventName = event.eventName;
            if (eventName?.startsWith("pusher:") ?? false) {
              debugPrint("⏭️ Ignoring internal Pusher event: $eventName");
              return;
            }
          }
          debugPrint("🔔 Pusher Event: ${event is PusherEvent ? event.eventName : 'unknown'} on ${event is PusherEvent ? event.channelName : 'unknown'}");
          _handleEvent(event);
        },
        onSubscriptionError: (message, error) {
          debugPrint("❌ Subscription Error: $message");
        },
        onDecryptionFailure: (event, reason) {
          debugPrint("❌ Decryption Failure: $reason");
        },
        onMemberAdded: (String? channelName, dynamic member) {
          debugPrint("👤 Member added to ${channelName ?? 'unknown'}");
        },
        onMemberRemoved: (String? channelName, dynamic member) {
          debugPrint("👤 Member removed from ${channelName ?? 'unknown'}");
        },
      );

      await _pusher!.connect();

      // Subscribe to Private Channel
      String channelName = "private-App.Models.User.$userId";
      await _pusher!.subscribe(
        channelName: channelName,
        onEvent: (event) {
          _handleEvent(event);
        },
      );

      debugPrint("✅ Pusher initialized and subscribed to $channelName");
    } catch (e) {
      debugPrint("❌ Error connecting to Pusher: $e");
    }
  }

  static void _handleEvent(dynamic event) {
    try {
      debugPrint("🔔 Received Event: $event");
      
      // Extract event name and check if it's an internal Pusher event
      String? eventName;
      if (event is PusherEvent) {
        eventName = event.eventName;
      } else if (event is Map) {
        eventName = event['eventName']?.toString();
      }
      
      // Ignore internal Pusher events (pusher:pong, pusher:ping, etc.)
      if (eventName?.startsWith("pusher:") ?? false) {
        debugPrint("⏭️ Ignoring internal Pusher event: $eventName");
        return;
      }
      
      dynamic eventData;
      if (event is PusherEvent) {
        eventData = event.data;
      } else if (event is Map) {
        eventData = event['data'];
      }

      // Handle if eventData is already a Map (common in some Pusher implementations on Web)
      Map<String, dynamic> data = {};
      
      if (eventData is Map) {
         data = Map<String, dynamic>.from(eventData);
      } else if (eventData is String) {
        try {
           data = jsonDecode(eventData);
        } catch (e) {
           debugPrint("Error decoding JSON string: $e");
           return; 
        }
      } else {
         debugPrint("Unknown eventData type: ${eventData?.runtimeType ?? 'null'}");
         return;
      }
      
      // ✅ Add data to stream for in-app updates
      _notificationStreamController.add(data);

      String? messageText;
      
      // Navigate through the data structure to find the message
      if (data.containsKey('message')) {
         var msg = data['message'];
         if (msg is String) {
            messageText = msg;
         } else if (msg is Map) {
            // Nested message object?
            if (msg.containsKey('message')) {
               messageText = msg['message']?.toString();
            }
         }
      }
      
      // Fallback: check if 'data' key exists inside the data map
      if (messageText == null && data.containsKey('data')) {
         var innerData = data['data'];
         if (innerData is Map && innerData.containsKey('message')) {
             messageText = innerData['message']?.toString();
         }
      }
      
      if (messageText != null && messageText.isNotEmpty) {
        showNotification(messageText);
      } else {
        debugPrint("⚠️ No message text found in event data");
      }
    } catch (e, stackTrace) {
      debugPrint("❌ Error parsing pusher event: $e");
      debugPrint("Stack trace: $stackTrace");
    }
  }

  static Future<void> disconnect() async {
    if (_pusher != null) {
      try {
        await _pusher!.disconnect();
        _pusher = null;
        debugPrint('🔌 Pusher Disconnected');
      } catch (e) {
        debugPrint("❌ Error disconnecting from Pusher: $e");
      }
    }
  }

  static Future<void> showNotification(String message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'channel_id_messages',
      'Messages',
      channelDescription: 'Notifications for new messages',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    
    const NotificationDetails generalNotificationDetails =
        NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      DateTime.now().millisecond,
      'رسالة جديدة',
      message,
      generalNotificationDetails,
    );
  }
}
