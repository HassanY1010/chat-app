import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import 'ad_details_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'chat_screen.dart';


class PublicProfileScreen extends StatefulWidget {
  final String userId;

  const PublicProfileScreen({super.key, required this.userId});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  List<dynamic> _ads = [];
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final apiService = ApiService();
      final response = await apiService.client.get('/users/${widget.userId}/profile');
      
      setState(() {
        _userData = response.data['user'];
        _ads = response.data['ads'];
        _isFollowing = _userData?['is_following'] ?? false;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFollow() async {
    try {
      final apiService = ApiService();
      // Assume separate endpoints for follow/unfollow based on standard practices
      // and analogy with like/unlike in AdProvider.
      if (_isFollowing) {
        await apiService.client.post('/users/${widget.userId}/unfollow');
      } else {
        await apiService.client.post('/users/${widget.userId}/follow');
      }
      
      setState(() {
        _isFollowing = !_isFollowing;
        if (_isFollowing) {
           _userData!['followers_count'] = (_userData!['followers_count'] ?? 0) + 1;
        } else {
           _userData!['followers_count'] = (_userData!['followers_count'] ?? 1) - 1;
        }
      });
    } catch (e) {
      debugPrint('Error toggling follow: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    }
  }

  Future<void> _shareProfile() async {
    if (_userData == null) return;
    try {
      final name = _userData!['name'] ?? 'مستخدم';
      final followers = _userData!['followers_count'] ?? 0;
      final ads = _userData!['ads_count'] ?? 0;
      
      await Share.share(
        'الملف الشخصي للمعلن: $name\n'
        'عدد المتابعين: $followers\n'
        'عدد الإعلانات: $ads\n'
        'تواصل معه عبر تطبيق حراج!',
        subject: 'مشاركة ملف شخصي: $name',
      );
    } catch (e) {
      debugPrint('Error sharing profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_userData == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'المستخدم غير موجود',
            style: TextStyle(
              fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
            ),
          ),
        ),
      );
    }

    final currentUserId = context.read<AuthProvider>().user?.id;
    final isOwnProfile = currentUserId != null && currentUserId.toString() == widget.userId.toString();

    return Scaffold(

      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF00B0FF), Color(0xFF0091EA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Theme.of(context).cardColor,
                      backgroundImage: _userData!['avatar_url'] != null && _userData!['avatar_url'].isNotEmpty
                          ? CachedNetworkImageProvider(_userData!['avatar_url']) 
                          : (_userData!['avatar'] != null && _userData!['avatar'].isNotEmpty 
                              ? CachedNetworkImageProvider(_userData!['avatar']) 
                              : null),
                      child: _userData!['avatar'] == null && _userData!['avatar_url'] == null
                          ? Text(
                              _userData!['name'] != null && _userData!['name'].isNotEmpty 
                                ? _userData!['name'][0].toUpperCase() 
                                : 'U', 
                              style: const TextStyle(
                                fontSize: 40,
                                fontFamily: 'NotoSansArabic',
                              ),
                            ) 
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _userData!['name'],
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStat('${_userData!['followers_count'] ?? 0}', 'متابع'),
                        const SizedBox(width: 24),
                        _buildStat('${_userData!['following_count'] ?? 0}', 'يتابع'),
                        const SizedBox(width: 24),
                        _buildStat('${_userData!['ads_count'] ?? _ads.length}', 'إعلان'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: _shareProfile,
              )
            ],
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isOwnProfile) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _toggleFollow,
                          style: ElevatedButton.styleFrom(
                          backgroundColor: _isFollowing ? Colors.grey : Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(
                            _isFollowing ? 'إلغاء المتابعة' : 'متابعة',
                            style: const TextStyle(
                              fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  receiverId: int.parse(widget.userId),
                                  receiverName: _userData!['name'],
                                  receiverAvatar: _userData!['avatar_url'],
                                ),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text(
                            'مراسلة',
                            style: TextStyle(
                              fontFamily: 'NotoSansArabic', 
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  ],
                  const SizedBox(height: 24),
                  const Text(
                    'الإعلانات',
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold,
                      fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final ad = _ads[index];
                  return GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (_) => AdDetailsScreen(ad: ad))
                      );
                      // Refresh profile data when returning
                      if (mounted) {
                        _fetchProfile();
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 5),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                              child: ad['main_image'] != null
                                    ? CachedNetworkImage(
                                        imageUrl: ad['main_image']['image_url'] ?? '',
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      )
                                  : Container(
                                      color: Colors.grey.shade200, 
                                      child: const Icon(Icons.image)
                                    ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ad['title'] ?? '', 
                                  maxLines: 1, 
                                  overflow: TextOverflow.ellipsis, 
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                                  ),
                                ),
                                Text(
                                  '${ad['price']} SAR', 
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor, 
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: _ads.length,
              ),
            ),
          ),
          
          const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(
          value, 
          style: const TextStyle(
            color: Colors.white, 
            fontWeight: FontWeight.bold, 
            fontSize: 18,
            fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
          ),
        ),
        Text(
          label, 
          style: const TextStyle(
            color: Colors.white70, 
            fontSize: 12,
            fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
          ),
        ),
      ],
    );
  }
}