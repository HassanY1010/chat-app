class Message {
  final int id;
  final String senderId;
  final String receiverId;
  final String message;
  final String messageType;
  final String? fileUrl;

  final DateTime createdAt;

  Message({
    required this.id, 
    required this.senderId, 
    required this.receiverId, 
    required this.message,
    this.messageType = 'text',
    this.fileUrl,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      senderId: json['sender_id'].toString(),
      receiverId: json['receiver_id'].toString(),
      message: json['message'] ?? '',
      messageType: json['message_type'] ?? 'text',
      fileUrl: json['file_url'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }
}
