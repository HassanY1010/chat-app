import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import '../models/message_model.dart';
import '../services/api_service.dart';
import 'dart:io' as io;
import 'package:dio/dio.dart' as dio;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ChatProvider with ChangeNotifier {
  List<Message> messages = [];
  List<dynamic> conversations = [];
  bool isLoading = false;
  
  final ApiService _apiService = ApiService.instance;
  late socket_io.Socket socket;

  String? currentActiveReceiverId;

  void enterChat(String receiverId) {
    currentActiveReceiverId = receiverId;
  }

  void leaveChat() {
    currentActiveReceiverId = null;
  }

  void init(String userId, String token) {
    if (userId == '0') return; // Invalid user
    
    // Use the appropriate URL based on environment (assuming socket runs on port 3000 relative to backend IP)
    // Simple logic: replace 8000/api with 3000
    String socketUrl = _apiService.client.options.baseUrl.replaceAll(':8000/api', ':3000');
    if (socketUrl.endsWith('/api')) socketUrl = socketUrl.replaceAll('/api', ':3000'); // Fallback

    socket = socket_io.io(socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'auth': {
        'token': token,
      },
    });

    socket.connect();

    socket.onConnect((_) {
      debugPrint("Connected to Socket.IO server at $socketUrl");
      socket.emit("join", userId);
    });

    socket.on("receive_message", (data) {
      debugPrint("Received message: $data");
      
      final newMessage = Message.fromJson(data);
      final senderId = newMessage.senderId;
      
      // 1. If chat with this sender is open, add message to list
      if (currentActiveReceiverId == senderId) {
        messages.add(newMessage);
      }
      
      // 2. Always update conversations list
      final index = conversations.indexWhere((c) => c['other_user_id'].toString() == senderId);
      
      if (index != -1) {
        // Update existing conversation
        final updatedConv = Map<String, dynamic>.from(conversations[index]);
        updatedConv['last_message'] = newMessage.message;
        updatedConv['date'] = newMessage.createdAt.toIso8601String();
        
        // Increment unread count if not in active chat
        if (currentActiveReceiverId != senderId) {
           updatedConv['unread_count'] = (updatedConv['unread_count'] ?? 0) + 1;
        } else {
           // If we are in the chat, we can assume it's read (or we need a read event)
           updatedConv['unread_count'] = 0;
        }
        
        conversations.removeAt(index);
        conversations.insert(0, updatedConv); // Move to top
        
      } else {
        // New conversation (we might need to fetch full details, but for now we wait for refresh)
        // Ideally we would trigger getConversations() here
        getConversations(); 
      }
      
      notifyListeners();
    });
    
    socket.onDisconnect((_) => debugPrint('Disconnected from Socket.IO'));
  }
  
  Future<void> getConversations() async {
    isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.client.get('/messages/conversations');
      conversations = response.data;
    } catch (e) {
      debugPrint("Error fetching conversations: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendMessage(String senderId, String receiverId, String text, {XFile? imageFile}) async {
    try {
      dynamic response;
      
      if (imageFile != null) {
        // Send as multipart/form-data
        final formData = dio.FormData.fromMap({
          'receiver_id': receiverId,
          'message': text,
        });

        if (imageFile != null) {
          final bytes = await imageFile.readAsBytes();
          formData.files.add(MapEntry(
            'image',
            dio.MultipartFile.fromBytes(
              bytes,
              filename: imageFile.name,
            ),
          ));
        }
        
        response = await _apiService.client.post('/messages/send', data: formData);
      } else {
        // Send as standard JSON
        response = await _apiService.client.post('/messages/send', data: {
          'receiver_id': receiverId,
          'message': text,
        });
      }

      final message = Message.fromJson(response.data);
      messages.add(message);
      notifyListeners();

      // إرسال الرسالة مباشرة عبر Socket.IO
      socket.emit("send_message", {
        'senderId': senderId,
        'receiverId': receiverId,
        'message': text,
        'id': message.id,
        'message_type': message.messageType,
        'file_url': message.fileUrl,
      });
      return true;
    } catch (e) {
      debugPrint("Error sending message: $e");
      return false;
    }
  }

  Future<void> fetchMessages(String userId, String otherUserId) async {
    isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.client.get('/messages/fetch/$userId/$otherUserId');
      messages = (response.data as List).map((e) => Message.fromJson(e)).toList();
    } catch (e) {
      debugPrint("Error fetching messages: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
