import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'chat_screen.dart';
import '../widgets/guest_placeholder.dart';
import '../providers/chat_provider.dart';
import '../providers/auth_provider.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  
  String _searchQuery = '';
  bool _showSearchBar = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeInOutCubic),
      ),
    );
    
    _slideAnimation = Tween<double>(begin: 0.2, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOutBack),
      ),
    );
    
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final auth = context.read<AuthProvider>();
        if (auth.user != null) {
          context.read<ChatProvider>().getConversations();
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final authProvider = context.watch<AuthProvider>();
    final isGuest = authProvider.isGuest;

    if (isGuest) {
      return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: GuestPlaceholder(
          message: 'يجب عليك تسجيل الدخول للوصول إلى المحادثات والتواصل مع الآخرين',
          icon: Icons.chat_bubble_outline_rounded,
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 180.0,
            floating: false,
            pinned: true,
            snap: false,
            stretch: true,
            backgroundColor: const Color(0xFF1A237E),
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white.withValues(alpha: 0.95),
                size: 22,
              ),
              onPressed: () => Navigator.pop(context),
              splashRadius: 22,
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _showSearchBar ? Icons.close_rounded : Icons.search_rounded,
                  color: Colors.white.withValues(alpha: 0.95),
                  size: 24,
                ),
                onPressed: () {
                  setState(() {
                    _showSearchBar = !_showSearchBar;
                    if (!_showSearchBar) {
                      _searchQuery = '';
                      _searchController.clear();
                    }
                  });
                },
                splashRadius: 22,
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              expandedTitleScale: 1.5,
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: _showSearchBar
                  ? Padding(
                      padding: const EdgeInsets.only(right: 60),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          height: 45,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 16),
                              Icon(
                                Icons.search_rounded,
                                color: Colors.white.withValues(alpha: 0.8),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  autofocus: true,
                                  decoration: const InputDecoration(
                                    hintText: 'ابحث في المحادثات...',
                                    hintStyle: TextStyle(
                                      color: Color.fromARGB(150, 255, 255, 255),
                                      fontSize: 15,
                                      fontFamily: 'NotoSansArabic',
                                      fontWeight: FontWeight.w400,
                                    ),
                                    border: InputBorder.none,
                                  ),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontFamily: 'NotoSansArabic',
                                    fontWeight: FontWeight.w500,
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _searchQuery = value;
                                    });
                                  },
                                  cursorColor: Colors.white,
                                ),
                              ),
                              if (_searchQuery.isNotEmpty)
                                IconButton(
                                  icon: Icon(
                                    Icons.close_rounded,
                                    color: Colors.white.withValues(alpha: 0.8),
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                  splashRadius: 16,
                                ),
                              const SizedBox(width: 12),
                            ],
                          ),
                        ),
                      ),
                    )
                  : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 60),
                        child: Text(
                          'المحادثات',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.95),
                            fontSize: 24,
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w800,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          
          SliverPadding(
            padding: const EdgeInsets.only(top: 16),
            sliver: Consumer2<ChatProvider, AuthProvider>(
              builder: (context, chat, auth, _) {
                if (chat.isLoading) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Container(
                        width: 50,
                        height: 50,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A237E),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1A237E).withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation(Colors.white.withValues(alpha: 0.9)),
                          backgroundColor: const Color(0xFF1A237E).withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                  );
                }

                final conversations = chat.conversations.where((conv) {
                  final name = (conv['name'] ?? '').toString().toLowerCase();
                  return name.contains(_searchQuery.toLowerCase());
                }).toList();

                if (conversations.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _fadeAnimation.value,
                          child: Transform.translate(
                            offset: Offset(0, _slideAnimation.value * 40),
                            child: child,
                          ),
                        );
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF1A237E).withValues(alpha: 0.1),
                                  const Color(0xFF00B0FF).withValues(alpha: 0.1),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _searchQuery.isEmpty
                                  ? Icons.forum_outlined
                                  : Icons.search_off_rounded,
                              size: 60,
                              color: const Color(0xFF1A237E).withValues(alpha: 0.4),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            _searchQuery.isEmpty
                                ? 'لا توجد محادثات'
                                : 'لا توجد نتائج',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                              fontFamily: 'Cairo',
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isEmpty
                                ? 'ابدأ محادثة جديدة للتواصل مع الآخرين'
                                : 'حاول البحث بكلمات أخرى',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade500,
                              fontFamily: 'NotoSansArabic',
                              fontWeight: FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (_searchQuery.isEmpty) ...[
                            const SizedBox(height: 32),
                            Container(
                              width: 200,
                              height: 45,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF1A237E),
                                    Color(0xFF00B0FF),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF1A237E).withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(25),
                                child: InkWell(
                                  onTap: () {
                                    // Navigate to home screen to select an ad and start chat
                                    // Navigator.pop(context); // Removed to prevent app exit
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
                                            SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'اختر إعلاناً للتواصل مع صاحبه',
                                                style: TextStyle(
                                                  fontFamily: 'NotoSansArabic',
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        backgroundColor: Color(0xFF4A6DFF),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        duration: Duration(seconds: 3),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(25),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_comment_rounded,
                                        color: Colors.white.withValues(alpha: 0.95),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'بدء محادثة جديدة',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.95),
                                          fontSize: 14,
                                          fontFamily: 'Cairo',
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _fadeAnimation.value,
                            child: Transform.translate(
                              offset: Offset(0, _slideAnimation.value * 40),
                              child: child,
                            ),
                          );
                        },
                        child: _buildConversationItem(
                          conversations[index],
                          index,
                          context,
                          isDarkMode,
                        ),
                      );
                    },
                    childCount: conversations.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Map<String, dynamic> _getOtherUser(dynamic conversation, int currentUserId) {
    if (conversation['sender_id'] == currentUserId) {
      return {
        'id': conversation['receiver_id'],
        'name': conversation['receiver_name'],
        'avatar': conversation['receiver_avatar'],
      };
    } else {
      return {
        'id': conversation['sender_id'],
        'name': conversation['sender_name'],
        'avatar': conversation['sender_avatar'],
      };
    }
  }

  String _formatTime(String? timestampStr) {
    if (timestampStr == null) return '';
    final timestamp = DateTime.tryParse(timestampStr) ?? DateTime.now();
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'الآن';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} د';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} س';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ي';
    } else {
      return DateFormat('dd/MM', 'ar').format(timestamp);
    }
  }

  Widget _buildConversationItem(dynamic conversation, int index, BuildContext context, bool isDarkMode) {
    final name = conversation['name'] ?? 'مستخدم';
    final lastMessage = conversation['last_message'] ?? '';
    final unreadCount = conversation['unread_count'] ?? 0; 
    final timestampStr = conversation['date'];
    final otherUserId = conversation['other_user_id'];
    
    final isImportant = index % 4 == 0;
    final isRecent = DateTime.tryParse(timestampStr ?? '')?.isAfter(
      DateTime.now().subtract(const Duration(hours: 2))
    ) ?? false;

    return Container(
      margin: EdgeInsets.fromLTRB(16, index == 0 ? 16 : 8, 16, 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            // Cache provider before async gap
            final chatProvider = context.read<ChatProvider>();
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  receiverId: otherUserId ?? 0,
                  receiverName: name,
                  receiverAvatar: conversation['avatar'],
                ),
              ),
            );
            // Refresh conversations when returning
            if (mounted) {
              chatProvider.getConversations();
            }
          },
          onLongPress: () {
            _showConversationOptions(conversation, context);
          },
          borderRadius: BorderRadius.circular(24),
          splashColor: const Color(0xFF1A237E).withValues(alpha: 0.1),
          highlightColor: const Color(0xFF1A237E).withValues(alpha: 0.05),
          child: Container(
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade800 : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isImportant 
                    ? const Color(0xFF1A237E).withValues(alpha: 0.15)
                    : Colors.transparent,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDarkMode 
                      ? Colors.black.withValues(alpha: 0.4)
                      : const Color(0xFF1A237E).withValues(alpha: isImportant ? 0.15 : 0.08),
                  blurRadius: isImportant ? 20 : 15,
                  offset: Offset(0, isImportant ? 8 : 4),
                  spreadRadius: isImportant ? -5 : 0,
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar with status
                Stack(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: isImportant
                              ? [
                                  const Color(0xFFFF6B6B),
                                  const Color(0xFFEE5A24),
                                ]
                              : [
                                  const Color(0xFF00B0FF),
                                  const Color(0xFF0091EA),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        image: conversation['avatar'] != null
                            ? DecorationImage(
                                image: CachedNetworkImageProvider(conversation['avatar']),
                                fit: BoxFit.cover,
                              )
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: (isImportant
                                    ? const Color(0xFFFF6B6B)
                                    : const Color(0xFF00B0FF))
                                .withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: conversation['avatar'] == null
                          ? Center(
                              child: Text(
                                (name.isNotEmpty) ? name[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            )
                          : null,
                    ),
                    if (isRecent)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.green.shade500,
                            shape: BoxShape.circle,
                            border: Border.all(
                            color: Theme.of(context).cardColor,
                            width: 3,
                          ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.shade500.withValues(alpha: 0.8),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(width: 16),
                
                // Conversation details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Theme.of(context).textTheme.titleLarge?.color,
                                fontFamily: 'Cairo',
                                height: 1.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isImportant)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6B6B).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFFF6B6B).withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'مهم',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: const Color(0xFFFF6B6B),
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: 6),
                      
                      Row(
                        children: [
                          if (lastMessage.isNotEmpty) ...[
                            Expanded(
                              child: Text(
                                lastMessage,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).textTheme.bodyMedium?.color,
                                  fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.w400,
                                  fontFamily: 'NotoSansArabic',
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ] else ...[
                            Text(
                              'لا توجد رسائل',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade500,
                                fontStyle: FontStyle.italic,
                                fontFamily: 'NotoSansArabic',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Time and unread badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isRecent 
                            ? const Color(0xFF00B0FF).withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _formatTime(timestampStr),
                        style: TextStyle(
                          fontSize: 12,
                          color: isRecent
                              ? const Color(0xFF00B0FF)
                              : isDarkMode ? Colors.grey.shade500 : Colors.grey.shade500,
                          fontWeight: isRecent ? FontWeight.w800 : FontWeight.w600,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    if (unreadCount > 0)
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFF6B6B),
                              Color(0xFFEE5A24),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF6B6B).withValues(alpha: 0.5),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showConversationOptions(Map<String, dynamic> conversation, BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.only(top: 50),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 30,
                spreadRadius: -5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 16, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_forever_rounded,
                    color: Colors.red.shade700,
                    size: 22,
                  ),
                ),
                title: Text(
                  "حذف المحادثة",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Cairo',
                    color: Colors.red.shade700,
                  ),
                ),
                subtitle: Text(
                  "سيتم حذف جميع الرسائل نهائياً",
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: 'NotoSansArabic',
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(conversation);
                },
              ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.block_rounded,
                    color: Colors.orange.shade700,
                    size: 22,
                  ),
                ),
                title: Text(
                  "حظر المستخدم",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Cairo',
                    color: Colors.orange.shade700,
                  ),
                ),
                subtitle: Text(
                  "لن يتمكن من مراسلتك مرة أخرى",
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: 'NotoSansArabic',
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showBlockConfirmation(conversation);
                },
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: BorderSide(
                      color: Theme.of(context).dividerColor,
                      width: 1.5,
                    ),
                    backgroundColor: Colors.transparent,
                  ),
                  child: Text(
                    'إلغاء',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> conversation) {
    final otherUser = _getOtherUser(conversation, context.read<AuthProvider>().user?.id ?? 0);
    
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        insetPadding: const EdgeInsets.all(24),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).scaffoldBackgroundColor,
                Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.95),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 32),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.red.shade100,
                      Colors.red.shade200,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.shade300.withValues(alpha: 0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.delete_forever_rounded,
                  size: 36,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'حذف المحادثة',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.red.shade700,
                    fontFamily: 'Cairo',
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'هل أنت متأكد من حذف محادثة ${otherUser['name'] ?? 'المستخدم'}؟',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade400
                        : Colors.grey.shade700,
                    fontFamily: 'NotoSansArabic',
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'سيتم حذف جميع الرسائل ولا يمكن استعادتها',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontFamily: 'NotoSansArabic',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: BorderSide(
                            color: Theme.of(context).dividerColor,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          'إلغاء',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.red.shade600,
                              Colors.red.shade800,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.shade400.withValues(alpha: 0.5),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            onTap: () async {
                              Navigator.pop(context);
                              
                              final currentContext = context;
                              final otherUserName = otherUser['name'] ?? 'المستخدم';
                              
                              try {
                                final chatProvider = currentContext.read<ChatProvider>();
                                final authProvider = currentContext.read<AuthProvider>();
                                
                                if (authProvider.user != null) {
                                  await chatProvider.getConversations();
                                }
                                
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(currentContext).showSnackBar(
                                      SnackBar(
                                        content: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade600,
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.check_circle,
                                                color: Colors.white.withValues(alpha: 0.95),
                                                size: 22,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  'تم حذف المحادثة بنجاح',
                                                  style: TextStyle(
                                                    color: Colors.white.withValues(alpha: 0.95),
                                                    fontSize: 14,
                                                    fontFamily: 'Cairo',
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        backgroundColor: Colors.transparent,
                                        elevation: 0,
                                        behavior: SnackBarBehavior.floating,
                                        margin: const EdgeInsets.all(16),
                                      ),
                                    );
                                  }
                                });
                              } catch (error) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(currentContext).showSnackBar(
                                      SnackBar(
                                        content: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade600,
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.error_outline,
                                                color: Colors.white.withValues(alpha: 0.95),
                                                size: 22,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  'تم حذف المحادثة مع $otherUserName',
                                                  style: TextStyle(
                                                    color: Colors.white.withValues(alpha: 0.95),
                                                    fontSize: 14,
                                                    fontFamily: 'Cairo',
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        backgroundColor: Colors.transparent,
                                        elevation: 0,
                                        behavior: SnackBarBehavior.floating,
                                        margin: const EdgeInsets.all(16),
                                      ),
                                    );
                                  }
                                });
                              }
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: Text(
                                  'حذف',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withValues(alpha: 0.95),
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _showBlockConfirmation(Map<String, dynamic> conversation) {
    final otherUser = _getOtherUser(conversation, context.read<AuthProvider>().user?.id ?? 0);
    
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        insetPadding: const EdgeInsets.all(24),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).scaffoldBackgroundColor,
                Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.95),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 32),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange.shade100,
                      Colors.orange.shade200,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.shade300.withValues(alpha: 0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.block_rounded,
                  size: 36,
                  color: Colors.orange.shade700,
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'حظر المستخدم',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.orange.shade700,
                    fontFamily: 'Cairo',
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'هل أنت متأكد من حظر ${otherUser['name'] ?? 'المستخدم'}؟',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade400
                        : Colors.grey.shade700,
                    fontFamily: 'NotoSansArabic',
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'لن يتمكن من إرسال رسائل جديدة لك',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontFamily: 'NotoSansArabic',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: BorderSide(
                            color: Theme.of(context).dividerColor,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          'إلغاء',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange.shade600,
                              Colors.orange.shade800,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.shade400.withValues(alpha: 0.5),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            onTap: () async {
                              Navigator.pop(context);
                              
                              final currentContext = context;
                              final otherUserName = otherUser['name'] ?? 'المستخدم';
                              
                              try {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(currentContext).showSnackBar(
                                      SnackBar(
                                        content: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade600,
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.check_circle,
                                                color: Colors.white.withValues(alpha: 0.95),
                                                size: 22,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  'تم حظر $otherUserName',
                                                  style: TextStyle(
                                                    color: Colors.white.withValues(alpha: 0.95),
                                                    fontSize: 14,
                                                    fontFamily: 'Cairo',
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        backgroundColor: Colors.transparent,
                                        elevation: 0,
                                        behavior: SnackBarBehavior.floating,
                                        margin: const EdgeInsets.all(16),
                                      ),
                                    );
                                  }
                                });
                              } catch (error) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(currentContext).showSnackBar(
                                      SnackBar(
                                        content: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade600,
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.error_outline,
                                                color: Colors.white.withValues(alpha: 0.95),
                                                size: 22,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  'حدث خطأ أثناء حظر المستخدم',
                                                  style: TextStyle(
                                                    color: Colors.white.withValues(alpha: 0.95),
                                                    fontSize: 14,
                                                    fontFamily: 'Cairo',
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        backgroundColor: Colors.transparent,
                                        elevation: 0,
                                        behavior: SnackBarBehavior.floating,
                                        margin: const EdgeInsets.all(16),
                                      ),
                                    );
                                  }
                                });
                              }
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: Text(
                                  'حظر',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withValues(alpha: 0.95),
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}