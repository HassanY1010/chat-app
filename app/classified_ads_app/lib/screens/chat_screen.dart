import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  final int receiverId;
  final String? receiverName;
  final String? receiverAvatar;

  const ChatScreen({
    super.key, 
    required this.receiverId,
    this.receiverName,
    this.receiverAvatar,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  final _messageController = TextEditingController();
  late ScrollController _scrollController;
  final ImagePicker _picker = ImagePicker();
  bool _isSending = false;
  bool _isLoadingReceiver = true;
  bool _receiverOnline = false;
  DateTime? _receiverLastActivity;
  final ApiService _apiService = ApiService();
  
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _fetchReceiverStatus();
    
    // Prevent self-messaging
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUserId = context.read<AuthProvider>().user?.id;
      if (currentUserId != null && currentUserId.toString() == widget.receiverId.toString()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا يمكنك مراسلة نفسك')),
        );
        Navigator.pop(context);
        return;
      }
    });

    // Enter chat room for notifications context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ChatProvider>().enterChat(widget.receiverId.toString());
      }
    });
    
    // Fetch messages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final auth = context.read<AuthProvider>();
        final chatProvider = context.read<ChatProvider>();
        if (auth.user != null && auth.token != null) {
            chatProvider.init(auth.user!.id.toString(), auth.token!);
            chatProvider.fetchMessages(
                auth.user!.id.toString(), 
                widget.receiverId.toString()
            ).then((_) {
               if (mounted) _scrollToBottom();
            });
        }
      }
    });

  }

  @override
  void dispose() {
    context.read<ChatProvider>().leaveChat();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchReceiverStatus() async {
    try {
      final response = await _apiService.client.get('/users/${widget.receiverId}/profile');
      final userData = response.data['user'];
      if (mounted) {
        setState(() {
          _receiverOnline = userData['is_online'] ?? false;
          if (userData['last_activity_at'] != null) {
            _receiverLastActivity = DateTime.parse(userData['last_activity_at']);
          }
          _isLoadingReceiver = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching receiver status: $e');
      if (mounted) {
        setState(() => _isLoadingReceiver = false);
      }
    }
  }

  String _getStatusText() {
    if (_isLoadingReceiver) return 'جاري التحميل...';
    if (_receiverOnline) return 'متصل الآن';
    if (_receiverLastActivity == null) return 'غير متصل';
    
    final diff = DateTime.now().difference(_receiverLastActivity!);
    if (diff.inMinutes < 1) return 'نشط منذ قليل';
    if (diff.inMinutes < 60) return 'نشط منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'نشط منذ ${diff.inHours} ساعة';
    return 'نشط منذ ${diff.inDays} يوم';
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1200,
      );
      
      if (pickedFile != null) {
        _sendImageMessage(pickedFile);
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  Future<void> _sendImageMessage(XFile imageFile) async {
    final auth = context.read<AuthProvider>();
    if (auth.user == null) return;

    setState(() => _isSending = true);

    final success = await context.read<ChatProvider>().sendMessage(
      auth.user!.id.toString(),
      widget.receiverId.toString(),
      '',
      imageFile: imageFile,
    );

    if (!mounted) return;
    setState(() => _isSending = false);

    if (success) {
      _scrollToBottom();
    } else {
      _showError('فشل إرسال الصورة');
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final auth = context.read<AuthProvider>();
    if (auth.user == null) return;

    _messageController.clear();

    final success = await context.read<ChatProvider>().sendMessage(
      auth.user!.id.toString(),
      widget.receiverId.toString(),
      text,
    );

    if (!mounted) return;

    if (success) {
      _scrollToBottom();
    } else {
      _showError('فشل إرسال الرسالة');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'NotoSansArabic')),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showImagePreview(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: url,
                  placeholder: (context, url) => const CircularProgressIndicator(color: Colors.white),
                  errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white),
                ),
              ),
            ),
            PositionBag(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(dynamic message, int currentUserId) {
    final isMe = message.senderId == currentUserId.toString();
    final time = DateFormat('hh:mm a', 'ar').format(message.createdAt);
    final isImage = message.messageType == 'image';
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) ...[
                CircleAvatar(
                  radius: 16,
                  backgroundImage: widget.receiverAvatar != null 
                    ? CachedNetworkImageProvider(widget.receiverAvatar!)
                    : null,
                  backgroundColor: Colors.blue.shade100,
                  child: widget.receiverAvatar == null ? const Icon(Icons.person, size: 20, color: Colors.blue) : null,
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                  decoration: BoxDecoration(
                    color: isMe ? const Color(0xFF00B0FF) : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isMe ? 20 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isImage && message.fileUrl != null) 
                          GestureDetector(
                            onTap: () => _showImagePreview(message.fileUrl!),
                            child: Hero(
                              tag: message.id,
                              child: CachedNetworkImage(
                                imageUrl: message.fileUrl!,
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  height: 200,
                                  color: Colors.grey.shade200,
                                  child: const Center(child: CircularProgressIndicator()),
                                ),
                                errorWidget: (context, url, error) => const Icon(Icons.error),
                              ),
                            ),
                          ),
                        if (message.message.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Text(
                              message.message,
                              style: TextStyle(
                                fontSize: 15,
                                color: isMe ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                                fontFamily: 'NotoSansArabic',
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
              top: 4, 
              right: isMe ? 4 : 0, 
              left: !isMe ? 40 : 0
            ),
            child: Text(
              time,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isGuest = auth.currentUser == UserType.guest;

    if (isGuest) {
      return _buildGuestScreen();
    }

    final currentUserId = auth.user?.id ?? 0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          // Background Pattern
          Opacity(
            opacity: 0.05,
            child: Image.asset(
              'assets/chat_pattern.png',
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          
          Column(
            children: [
              Expanded(
                child: Consumer<ChatProvider>(
                  builder: (context, chat, _) {
                    if (chat.isLoading && chat.messages.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      itemCount: chat.messages.length,
                      itemBuilder: (context, index) {
                        return _buildMessageBubble(chat.messages[index], currentUserId);
                      },
                    );
                  },
                ),
              ),
              if (_isSending)
                const LinearProgressIndicator(backgroundColor: Colors.transparent),
              _buildInputArea(),
            ],
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00B0FF), Color(0xFF0091EA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white.withOpacity(0.3),
            backgroundImage: widget.receiverAvatar != null 
              ? CachedNetworkImageProvider(widget.receiverAvatar!) 
              : null,
            child: widget.receiverAvatar == null ? const Icon(Icons.person, color: Colors.white) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.receiverName ?? 'محادثة',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'NotoSansArabic',
                  ),
                ),
                Text(
                  _getStatusText(),
                  style: TextStyle(
                    fontSize: 11,
                    color: _receiverOnline ? Colors.greenAccent : Colors.white70,
                    fontWeight: _receiverOnline ? FontWeight.bold : FontWeight.normal,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline_rounded, color: Colors.white),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF0091EA), size: 28),
              onPressed: () => _showAttachmentMenu(),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[900] : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: null,
                  decoration: const InputDecoration(
                    hintText: 'اكتب رسالة...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(fontFamily: 'NotoSansArabic', fontSize: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF00B0FF), Color(0xFF0091EA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'إرسال محتوى',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  icon: Icons.image_rounded,
                  label: 'المعرض',
                  color: Colors.purple,
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  }
                ),
                _buildAttachmentOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'الكاميرا',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  }
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildGuestScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل الدخول مطلوب')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_rounded, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            const Text('يرجى تسجيل الدخول لبدء المحادثة', style: TextStyle(fontFamily: 'Cairo')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
              child: const Text('تسجيل الدخول'),
            ),
          ],
        ),
      ),
    );
  }
}

class PositionBag extends StatelessWidget {
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final Widget child;

  const PositionBag({super.key, this.top, this.bottom, this.left, this.right, required this.child});

  @override
  Widget build(BuildContext context) {
    return Positioned(top: top, bottom: bottom, left: left, right: right, child: child);
  }
}
