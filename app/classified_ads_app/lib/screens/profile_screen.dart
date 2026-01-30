import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/auth_provider.dart';
import '../widgets/guest_placeholder.dart';
import 'favorites_screen.dart';
import 'my_ads_screen.dart';
import 'delete_ad_screen.dart';
import 'edit_profile_screen.dart';
import 'privacy_settings_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/settings_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../utils/pdf_generator.dart';
import 'help_center_screen.dart';
import 'terms_screen.dart';
import 'terms_screen.dart';
import 'notifications_screen.dart';
import 'package:classified_ads_app/utils/app_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  
  int _selectedTab = 0;
  bool _isLoading = false;
  
  final List<String> _tabs = ['عام', 'إحصائيات', 'إعدادات', 'المساعدة'];

  @override
  void initState() {
    super.initState();
    
    // Load user data if not already loaded
    Future.microtask(() {
      if (mounted) {
        final authProvider = context.read<AuthProvider>();
        if (authProvider.user == null) {
          authProvider.checkAuth().then((_) {
            if (mounted) {
              final updatedAuth = context.read<AuthProvider>();
              if (updatedAuth.user != null && !updatedAuth.isGuest) {
                updatedAuth.fetchDashboardStats();
              }
            }
          });
        } else if (!authProvider.isGuest) {
           authProvider.fetchDashboardStats();
        }
      }
    });
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );
    
    _slideAnimation = Tween<double>(begin: 0.1, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutBack),
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
      ),
    );
    
    _rotateAnimation = Tween<double>(begin: -0.1, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _updateNotificationPreference(bool value) async {
    try {
      await context.read<AuthProvider>().updateProfile(acceptsNotifications: value);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value ? 'تم تفعيل الإشعارات' : 'تم إيقاف الإشعارات'),
            backgroundColor: value ? Colors.green : Colors.grey,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل تحديث الإعدادات: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _shareApp() async {
    const String message = 'حمل تطبيق لقطة الآن، طريقك الأسرع لأفضل الصفقات في منطقتك!\n\n${AppConstants.appLink}';
    try {
      await Share.share(message, subject: 'تطبيق لقطة');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل المشاركة: $e')),
        );
      }
    }
  }

  Future<void> _showRatingDialog() async {
    int selectedRating = 5;
    final commentController = TextEditingController();

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'RatingDialog',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: FadeTransition(
            opacity: anim1,
            child: StatefulBuilder(
              builder: (context, setDialogState) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  backgroundColor: Theme.of(context).cardColor,
                  contentPadding: EdgeInsets.zero,
                  content: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF4A6DFF), Color(0xFF7B9AFF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.star_rounded, color: Colors.white, size: 48),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'قيم تجربتك مع لقطة',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              const Text(
                                'رأيك يهمنا ويساعدنا على التحسن المستمر لتقديم أفضل خدمة لك.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF64748B),
                                  fontFamily: 'NotoSansArabic',
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(5, (index) {
                                  return IconButton(
                                    icon: Icon(
                                      index < selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                                      size: 40,
                                      color: const Color(0xFFF59E0B),
                                    ),
                                    onPressed: () => setDialogState(() => selectedRating = index + 1),
                                  );
                                }),
                              ),
                              const SizedBox(height: 20),
                              TextField(
                                controller: commentController,
                                maxLines: 3,
                                textAlign: TextAlign.right,
                                decoration: AppTheme.inputDecoration(
                                  hintText: 'اكتب رأيك هنا (اختياري)...',
                                ).copyWith(
                                  fillColor: const Color(0xFFF8FAFF),
                                ),
                                style: const TextStyle(fontFamily: 'NotoSansArabic'),
                              ),
                              const SizedBox(height: 32),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text(
                                        'إلغاء',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF64748B),
                                          fontFamily: 'Cairo',
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        try {
                                          await context.read<AuthProvider>().submitAppReview(
                                            selectedRating,
                                            commentController.text,
                                          );
                                          if (context.mounted) {
                                            Navigator.pop(context);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: const Text('شكراً لتقييمك! تم الحفظ بنجاح'),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('فشل حفظ التقييم: $e')),
                                            );
                                          }
                                        }
                                      },
                                      style: AppTheme.primaryButtonStyle.copyWith(
                                        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 16)),
                                      ),
                                      child: const Text('إرسال التقييم'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _exportUserData() async {
    setState(() => _isLoading = true);
    try {
      final data = await context.read<AuthProvider>().exportData();
      await PdfGenerator.generateAndDownload(data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل تصدير البيانات: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الحساب نهائياً'),
        content: const Text(
          'هل أنت متأكد أنك تريد حذف حسابك؟ هذا الإجراء لا يمكن التراجع عنه وسيتم حذف جميع بياناتك وإعلاناتك.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف الحساب'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await context.read<AuthProvider>().deleteAccount();
        if (mounted) {
           Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('فشل حذف الحساب: $e')),
          );
        }
      }
    }
  }

  Future<void> _showLogoutConfirmation() async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      backgroundColor: Theme.of(context).cardColor,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).cardColor,
              Theme.of(context).brightness == Brightness.dark 
                  ? Colors.black.withOpacity(0.2) 
                  : const Color(0xFFF8FAFF)
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFF6B6B),
                      const Color(0xFFEF4444),
                      const Color(0xFFDC2626),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                  child: SvgPicture.asset(
                    AppIcons.logout,
                    width: 48,
                    height: 48,
                    colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                  ),
              ),
              const SizedBox(height: 24),
              Text(
                'تسجيل الخروج',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                  fontFamily: 'Cairo',
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'هل أنت متأكد من تسجيل الخروج؟',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.8),
                  height: 1.6,
                  fontFamily: 'NotoSansArabic',
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'ستحتاج إلى إعادة تسجيل الدخول لاستخدام التطبيق',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontFamily: 'NotoSansArabic',
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.pop(ctx, false),
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            child: Center(
                              child: Text(
                                'إلغاء',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: const Color(0xFF64748B),
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
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFFF6B6B),
                            const Color(0xFFEF4444),
                            const Color(0xFFDC2626),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEF4444).withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.pop(ctx, true),
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SvgPicture.asset(AppIcons.logout, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn), width: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'تسجيل الخروج',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontFamily: 'Cairo',
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
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
    ),
  );
  
  if (confirm == true) {
    setState(() => _isLoading = true);
    
    try {
      if (!mounted) return;
      final authProvider = context.read<AuthProvider>();
      await authProvider.logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            elevation: 8,
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.error_outline_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'فشل تسجيل الخروج: $e',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontFamily: 'NotoSansArabic',
                    ),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

Widget _buildProfileHeader() {
  final authProvider = context.watch<AuthProvider>();
  final user = authProvider.user;

  return Container(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF4A6DFF),
          Color(0xFF7B9AFF),
          Color(0xFF3730A3),
        ],
      ),
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(32),
        bottomRight: Radius.circular(32),
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF4A6DFF).withOpacity(0.4),
          blurRadius: 32,
          offset: const Offset(0, 12),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF10B981),
                      Color(0xFF059669),
                      Color(0xFF047857),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withOpacity(0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
              ),
              Container(
                width: 130,
                height: 130,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: ClipOval(
                  child: user?.avatar != null && user!.avatar!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: user.avatar!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => Center(
                            child: Text(
                              user.name != null && user.name.isNotEmpty ? user.name[0] : 'U',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF10B981),
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            user?.name != null && user!.name.isNotEmpty ? user.name[0] : 'U',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF10B981),
                              fontFamily: 'Cairo',
                              shadows: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4A6DFF), Color(0xFF3B82F6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4A6DFF).withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        if (user == null) {
                          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditProfileScreen(),
                          ),
                        ).then((_) {
                          if (mounted) setState(() {});
                        });
                      },
                      borderRadius: BorderRadius.circular(22),
                      child: Icon(
                        user == null ? Icons.login_rounded : Icons.camera_alt_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          Text(
            user?.name ?? 'زائر',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
              fontFamily: 'Cairo',
              shadows: [
                const Shadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
          ),
          

          const SizedBox(height: 16),
          
          if (user?.phone != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: SvgPicture.asset(AppIcons.phone, width: 16, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    user!.phone,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.95),
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 16),
          
          if (user?.createdAt != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: SvgPicture.asset(AppIcons.calendar, width: 16, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'عضو منذ ${DateFormat('dd MMMM yyyy', 'ar').format(DateTime.parse(user!.createdAt!).toLocal())}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontFamily: 'NotoSansArabic',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 100),
        ],
      ),
    ),
  );
}

Widget _buildTabBar() {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: Theme.of(context).brightness == Brightness.dark 
          ? Colors.grey[900] 
          : const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: List.generate(_tabs.length, (index) {
        final isSelected = _selectedTab == index;
        return Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedTab = index;
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFF4A6DFF), Color(0xFF7B9AFF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF4A6DFF).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    _tabs[index],
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isSelected 
                          ? Colors.white 
                          : (Theme.of(context).brightness == Brightness.dark 
                              ? Colors.grey[400] 
                              : const Color(0xFF64748B)),
                      fontFamily: 'Cairo',
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    ),
  );
}

Widget _buildGeneralTab() {
  final authProvider = context.watch<AuthProvider>();
  return SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: SvgPicture.asset(AppIcons.arrowRight, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn), width: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'إجراءات سريعة',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                      fontFamily: 'Cairo',
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _buildQuickAction(
                    iconPath: AppIcons.plus,
                    label: 'إعلان جديد',
                    color: const Color(0xFF10B981),
                  ),
                  _buildQuickAction(
                    iconPath: AppIcons.categories,
                    label: 'إعلاناتي',
                    color: const Color(0xFF4A6DFF),
                  ),
                  _buildQuickAction(
                    iconPath: AppIcons.heart,
                    label: 'المفضلة',
                    color: const Color(0xFFEC4899),
                  ),
                  _buildQuickAction(
                    iconPath: AppIcons.delete,
                    label: 'حذف إعلانات',
                    color: const Color(0xFFEF4444),
                  ),
                  _buildQuickAction(
                    iconPath: AppIcons.camera,
                    label: 'الباركود',
                    color: const Color(0xFF8B5CF6),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
       child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF06B6D4).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.history_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'النشاط الأخير',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                      fontFamily: 'Cairo',
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Consumer<AuthProvider>(
                builder: (context, auth, child) {
                  if (auth.isGuest) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.grey.withOpacity(0.1) 
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.lock_outline_rounded, size: 40, color: Color(0xFF94A3B8)),
                          const SizedBox(height: 12),
                          Text(
                            'سجل دخولك لمشاهدة نشاطك',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final stats = auth.dashboardStats;
                  if (stats == null || stats['activities'] == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  final activities = stats['activities'] as List;
                  if (activities.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'لا يوجد نشاط حديث',
                          style: TextStyle(
                             color: Colors.grey[500],
                             fontFamily: 'NotoSansArabic',
                          ),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: activities.map((activity) {
                      return _buildActivityItem({
                        'title': activity['title'],
                        'description': activity['description'],
                        'time': activity['time'],
                        'icon': _getIconFromCode(activity['icon_code']),
                        'color': Color(int.parse(activity['color_hex'].replaceAll('#', '0xFF'))),
                      });
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
        
        if (!authProvider.isGuest) ...[
          const SizedBox(height: 20),
          
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF64748B), Color(0xFF475569)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF64748B).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: SvgPicture.asset(AppIcons.settings, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn), width: 22),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'إعدادات الحساب',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                        fontFamily: 'Cairo',
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSettingItem(
                  iconPath: AppIcons.profile,
                  title: 'تعديل الملف الشخصي',
                  subtitle: 'تغيير الاسم، الصورة، والمعلومات',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProfileScreen(),
                      ),
                    ).then((_) {
                      if (mounted) setState(() {});
                    });
                  }
                ),
                const SizedBox(height: 16),
                _buildSettingItem(
                  iconPath: AppIcons.notification,
                  title: 'الإشعارات',
                  subtitle: 'إدارة إشعارات التطبيق',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationsScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildSettingItem(
                  iconPath: AppIcons.lock,
                  title: 'الخصوصية',
                  subtitle: 'إعدادات الخصوصية والأمان',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PrivacySettingsScreen(),
                      ),
                    ).then((_) {
                       if (mounted) setState(() {});
                    });
                  },
                ),
              ],
            ),
          ),
        ],
        
        const SizedBox(height: 100),
      ],
    ),
  );
}

Widget _buildStatsTab() {
  final authProvider = context.watch<AuthProvider>();

  if (authProvider.isGuest) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_person_rounded,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'الإحصائيات غير متاحة',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'لاستخدام التطبيق بشكل كامل والوصول إلى إحصائياتك الخاصة، يرجى تسجيل الدخول بحسابك.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  fontFamily: 'NotoSansArabic',
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await authProvider.logout();
                    if (mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                    }
                  },
                  icon: const Icon(Icons.login_rounded, color: Colors.white),
                  label: const Text(
                    'تسجيل الدخول الآن',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      ),
                    elevation: 8,
                    shadowColor: Theme.of(context).primaryColor.withOpacity(0.4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  return SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Column(
      children: [
        const SizedBox(height: 20),
        
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.trending_up_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'أداء الحساب',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                      fontFamily: 'Cairo',
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (authProvider.dashboardStats == null)
                const Center(child: CircularProgressIndicator())
              else
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.1,
                  children: [
                    _buildStatCard(
                      'الإعلانات',
                      authProvider.dashboardStats!['stats']['total_ads'].toString(),
                      Icons.campaign_rounded,
                      const Color(0xFF3B82F6), // Vibrant Blue
                    ),
                    _buildStatCard(
                      'المبيعات',
                      authProvider.dashboardStats!['stats']['total_sold'].toString(),
                      Icons.sell_rounded,
                      const Color(0xFF10B981), // Vibrant Green
                    ),
                    _buildStatCard(
                      'التقييم',
                      authProvider.dashboardStats!['stats']['rating'].toString(),
                      Icons.star_rounded,
                      const Color(0xFFF59E0B), // Vibrant Amber
                    ),
                    _buildStatCard(
                      'العملاء',
                      authProvider.dashboardStats!['stats']['total_buyers'].toString(),
                      Icons.group_rounded,
                      const Color(0xFF8B5CF6), // Vibrant Purple
                    ),
                  ],
                ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'الإنجازات',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                      fontFamily: 'Cairo',
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (authProvider.dashboardStats?['achievements'] != null)
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: (authProvider.dashboardStats!['achievements'] as List).map<Widget>((achievement) {
                    return _buildAchievement(
                      icon: _getIconFromName(achievement['icon']),
                      label: achievement['label'],
                      achieved: achievement['achieved'] == true,
                    );
                  }).toList(),
                )
              else
                const Center(child: Text('لا توجد إنجازات حتى الآن')),
            ],
          ),
        ),
        
        const SizedBox(height: 40),
      ],
    ),
  );
}

IconData _getIconFromName(String name) {
  switch (name) {
    case 'star_rounded': return Icons.star_rounded;
    case 'thumb_up_rounded': return Icons.thumb_up_rounded;
    case 'bolt_rounded': return Icons.bolt_rounded;
    case 'diamond_rounded': return Icons.diamond_rounded;
    default: return Icons.emoji_events_rounded;
  }
}

// Map icon codes to const Icons to avoid tree shaking warnings
IconData _getIconFromCode(int? iconCode) {
  // Common Material Icons codes mapping
  switch (iconCode) {
    case 57415: return Icons.add_circle_outline; // default
    case 57686: return Icons.shopping_cart;
    case 57688: return Icons.favorite;
    case 57415: return Icons.add;
    case 58727: return Icons.sell;
    case 59574: return Icons.trending_up;
    case 58837: return Icons.star;
    case 58826: return Icons.notifications;
    case 58727: return Icons.campaign;
    case 59574: return Icons.analytics;
    case 57785: return Icons.check_circle;
    case 57686: return Icons.shopping_bag;
    case 58835: return Icons.local_offer;
    case 58727: return Icons.monetization_on;
    default: return Icons.info_outline; // fallback
  }
}

Widget _buildStatCard(String title, String value, IconData icon, Color color) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  
  return Container(
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: color.withAlpha(isDark ? 30 : 60),
          blurRadius: 15,
          offset: const Offset(0, 8),
        ),
      ],
      border: Border.all(
        color: color.withAlpha(isDark ? 40 : 20),
        width: 1.5,
      ),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              icon,
              size: 80,
              color: color.withAlpha(isDark ? 5 : 10),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withAlpha(200),
                        color,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: color.withAlpha(100),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                    fontFamily: 'Cairo',
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withAlpha(180),
                    fontFamily: 'NotoSansArabic',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildSettingsTab() {
  final authProvider = context.watch<AuthProvider>();
  final user = authProvider.user;

  return SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4A6DFF), Color(0xFF7B9AFF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4A6DFF).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.settings_applications_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'إعدادات التطبيق',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                      fontFamily: 'Cairo',
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSettingSwitch(
                icon: Icons.notifications_active_rounded,
                title: 'إشعارات التطبيق',
                subtitle: 'تلقي إشعارات عن الأنشطة',
                value: user?.acceptsNotifications ?? true,
                onChanged: (value) => _updateNotificationPreference(value),
              ),
              const SizedBox(height: 16),
              Consumer<SettingsProvider>(
                builder: (context, settings, _) {
                  return Column(
                    children: [
                      _buildSettingSwitch(
                        icon: Icons.language_rounded,
                        title: settings.locale.languageCode == 'ar' ? 'اللغة العربية' : 'English Language',
                        subtitle: settings.locale.languageCode == 'ar' ? 'عرض التطبيق باللغة العربية' : 'Display app in English',
                        value: settings.locale.languageCode == 'ar',
                        onChanged: (value) => settings.toggleLanguage(),
                      ),
                      const SizedBox(height: 16),
                      _buildSettingSwitch(
                        icon: Icons.dark_mode_rounded,
                        title: 'الوضع المظلم',
                        subtitle: 'تغيير مظهر التطبيق',
                        value: settings.isDarkMode,
                        onChanged: (value) => settings.toggleTheme(value),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        
        if (!authProvider.isGuest) ...[
          const SizedBox(height: 20),
          
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8B5CF6).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.manage_accounts_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'إدارة الحساب',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                        fontFamily: 'Cairo',
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSettingItem(
                  iconPath: AppIcons.delete,
                  title: 'حذف الحساب',
                  subtitle: 'حذف جميع البيانات بشكل نهائي',
                  color: const Color(0xFFEF4444),
                  onTap: () => _confirmDeleteAccount(),
                ),
                const SizedBox(height: 16),
                _buildSettingItem(
                  iconPath: AppIcons.arrowRight,
                  title: 'تصدير البيانات',
                  subtitle: 'تحميل نسخة من جميع بياناتك',
                  onTap: () => _exportUserData(),
                ),
              ],
            ),
          ),
        ],
        
        const SizedBox(height: 20),
        
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (user != null) {
                _showLogoutConfirmation();
              } else {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
            borderRadius: BorderRadius.circular(24),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: user != null
                      ? [
                          const Color(0xFFFF6B6B),
                          const Color(0xFFEF4444),
                          const Color(0xFFDC2626),
                        ]
                      : [
                          const Color(0xFF34D399),
                          const Color(0xFF10B981),
                          const Color(0xFF059669),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: (user != null ? const Color(0xFFEF4444) : const Color(0xFF10B981)).withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: _isLoading
                    ? const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              user != null ? Icons.logout_rounded : Icons.login_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            user != null ? 'تسجيل الخروج' : 'تسجيل الدخول / إنشاء حساب',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Cairo',
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 40),
      ],
    ),
  );
}

Widget _buildHelpTab() {
  return SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.help_center_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'مركز المساعدة',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF1A237E),
                      fontFamily: 'Cairo',
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildHelpItem(
                icon: Icons.question_answer_rounded,
                title: 'الأسئلة الشائعة',
                subtitle: 'إجابات على الأسئلة الأكثر شيوعاً',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HelpCenterScreen()),
                ),
              ),
              const SizedBox(height: 16),
              _buildHelpItem(
                icon: Icons.contact_support_rounded,
                title: 'اتصل بنا',
                subtitle: 'تواصل مع فريق الدعم',
                onTap: () => _showContactOptions(context),
              ),
              const SizedBox(height: 16),
              _buildHelpItem(
                icon: Icons.privacy_tip_rounded,
                title: 'سياسة الخصوصية',
                subtitle: 'كيف نحمي بياناتك',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TermsScreen(type: TermsType.privacy)),
                ),
              ),
              const SizedBox(height: 16),
              _buildHelpItem(
                icon: Icons.description_rounded,
                title: 'شروط الاستخدام',
                subtitle: 'الشروط والأحكام',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TermsScreen(type: TermsType.terms)),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4A6DFF), Color(0xFF7B9AFF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4A6DFF).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.info_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'عن التطبيق',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                      fontFamily: 'Cairo',
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'لقطة',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                  fontFamily: 'Cairo',
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'الإصدار 1.0',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'طريقك الأسرع للعثور على أفضل الصفقات والفرص (اللقطات) في منطقتك.',
                style: TextStyle(
                  fontSize: 15,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  height: 1.6,
                  fontFamily: 'NotoSansArabic',
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.star_rounded, color: Color(0xFFF59E0B)),
                      onPressed: () => _showRatingDialog(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.share_rounded, color: Color(0xFF4A6DFF)),
                      onPressed: () => _shareApp(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.update_rounded, color: Color(0xFF10B981)),
                      onPressed: () {},
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '© 2026',
                    style: TextStyle(
                      color: const Color(0xFF94A3B8),
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 40),
      ],
    ),
  );
}

Widget _buildQuickAction({
  required String iconPath,
  required String label,
  required Color color,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () {
        final authProvider = context.read<AuthProvider>();
        if (authProvider.isGuest && (label == 'إعلان جديد' || label == 'إعلاناتي' || label == 'المفضلة' || label == 'حذف إعلانات')) {
          _showGuestRestrictionDialog(context, label);
          return;
        }

        // Handle quick action tap
        if (label == 'إعلان جديد') {
          Navigator.pushNamed(context, '/create-ad');
        } else if (label == 'إعلاناتي') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MyAdsScreen(),
            ),
          );
        } else if (label == 'المفضلة') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FavoritesScreen(),
            ),
          );
        } else if (label == 'حذف إعلانات') {
          Navigator.pushNamed(context, '/delete-ads');
        } else if (label == 'الباركود') {
          _showQRCode();
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.15), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SvgPicture.asset(iconPath, width: 28, height: 28, colorFilter: ColorFilter.mode(color, BlendMode.srcIn)),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildActivityItem(Map<String, dynamic> activity) {
  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.grey[900] 
                : const Color(0xFFF8FAFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: activity['color'].withOpacity(0.1), width: 2),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      activity['color'].withOpacity(0.2),
                      activity['color'].withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: activity['color'].withOpacity(0.2), width: 2),
                ),
                child: Icon(
                  activity['icon'],
                  size: 24,
                  color: activity['color'],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity['title'],
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A237E),
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activity['description'],
                      style: TextStyle(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                        fontFamily: 'NotoSansArabic',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: activity['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: activity['color'].withOpacity(0.2)),
                ),
                child: Text(
                  activity['time'],
                  style: TextStyle(
                    fontSize: 12,
                    color: activity['color'],
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _buildSettingItem({
  required String iconPath,
  required String title,
  required String subtitle,
  Color? color,
  VoidCallback? onTap,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap ?? () {
        if (title == 'تعديل الملف الشخصي') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditProfileScreen(),
            ),
          ).then((_) {
             if (mounted) setState(() {});
          });
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    (color ?? const Color(0xFF4A6DFF)),
                    (color ?? const Color(0xFF4A6DFF)).withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (color ?? const Color(0xFF4A6DFF)).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SvgPicture.asset(
                iconPath,
                width: 24,
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).textTheme.titleMedium?.color,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontFamily: 'NotoSansArabic',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.grey.withOpacity(0.1) 
                    : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildSettingSwitch({
  required IconData icon,
  required String title,
  required String subtitle,
  required bool value,
  ValueChanged<bool>? onChanged,
}) {
  return Row(
    children: [
      Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.2),
              Theme.of(context).primaryColor.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.2), width: 2),
        ),
        child: Icon(
          icon,
          size: 24,
          color: Theme.of(context).primaryColor,
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).textTheme.titleMedium?.color,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontFamily: 'NotoSansArabic',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeTrackColor: const Color(0xFF4A6DFF),
        thumbColor: WidgetStateProperty.all(Colors.white),
      ),
    ],
  );
}



Widget _buildAchievement({
  required IconData icon,
  required String label,
  required bool achieved,
}) {
  return Column(
    children: [
      Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: achieved
              ? const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [
                    const Color(0xFFF1F5F9),
                    const Color(0xFFE2E8F0),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          shape: BoxShape.circle,
          boxShadow: achieved
              ? [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          size: 30,
          color: achieved ? Colors.white : const Color(0xFF94A3B8),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: achieved ? const Color(0xFFD97706) : Theme.of(context).textTheme.bodySmall?.color,
          fontWeight: FontWeight.w800,
          fontFamily: 'Cairo',
        ),
      ),
    ],
  );
}

  Widget _buildContactOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
    bool hasWhatsApp = false,
    String? phoneNumber,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.grey.withOpacity(0.2) 
              : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'NotoSansArabic',
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                 textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
          if (hasWhatsApp && phoneNumber != null) ...[
            InkWell(
              onTap: () async {
                final Uri launchUri = Uri(
                  scheme: 'tel',
                  path: phoneNumber,
                );
                if (await canLaunchUrl(launchUri)) {
                  await launchUrl(launchUri);
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.phone,
                  color: Colors.green,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () async {
                var whatsappUrl = "whatsapp://send?phone=$phoneNumber";
                var uri = Uri.parse(whatsappUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                } else {
                  // Fallback for web or if app not installed
                  whatsappUrl = "https://wa.me/$phoneNumber";
                  uri = Uri.parse(whatsappUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.chat,
                  color: Color(0xFF25D366),
                  size: 24,
                ),
              ),
            ),
          ] else
            IconButton(
              onPressed: onTap,
              icon: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
        ],
      ),
    );
  }

Widget _buildHelpItem({
  required IconData icon,
  required String title,
  required String subtitle,
  VoidCallback? onTap,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap ?? () {
        if (title == 'اتصل بنا') {
          _showContactOptions(context);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFF59E0B).withOpacity(0.2),
                    const Color(0xFFF59E0B).withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.2), width: 2),
              ),
              child: Icon(
                icon,
                size: 24,
                color: const Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).textTheme.titleMedium?.color,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontFamily: 'NotoSansArabic',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.grey.withOpacity(0.1) 
                    : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

@override
Widget build(BuildContext context) {
  final authProvider = context.watch<AuthProvider>();
  final user = authProvider.user;
  final isGuest = authProvider.isGuest;



  return AnimatedBuilder(
    animation: _animationController,
    builder: (context, child) {
      return Transform.translate(
        offset: Offset(0, _slideAnimation.value * 100),
        child: Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotateAnimation.value,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: child,
            ),
          ),
        ),
      );
    },
    child: Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: _buildProfileHeader(),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverTabBarDelegate(
                child: _buildTabBar(),
              ),
            ),
          ];
        },
        body: IndexedStack(
          index: _selectedTab,
          children: [
            _buildGeneralTab(),
            _buildStatsTab(),
            _buildSettingsTab(),
            _buildHelpTab(),
          ],
        ),
      ),
    ),
  );
}

Future<void> _showQRCode() async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    if (user == null) return;
    
    final qrData = user.qrCode ?? user.id.toString(); 
    final qrUrl = 'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=$qrData';

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        backgroundColor: Colors.white,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.white, Color(0xFFF8FAFF)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.qr_code_rounded,
                    size: 48,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'رمز QR الخاص بك',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1A237E),
                    fontFamily: 'Cairo',
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 2,
                    ),
                  ),
                  child: Image.network(
                    qrUrl,
                    width: 200,
                    height: 200,
                    loadingBuilder: (ctx, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF4A6DFF),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (ctx, err, stack) => Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.broken_image_rounded,
                        size: 50,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Scan to view profile',
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                    fontFamily: 'NotoSansArabic',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4A6DFF), Color(0xFF7B9AFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4A6DFF).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text(
                            'إغلاق',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Cairo',
                              letterSpacing: -0.2,
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
        ),
      ),
    );
  }
  void _showContactOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'تواصل معنا',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1A237E),
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'نحن هنا لمساعدتك، اختر الطريقة المناسبة للتواصل',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                fontFamily: 'NotoSansArabic',
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            
            _buildNewContactRow('782305677', isPhone: true),
            _buildNewContactRow('738606622', isPhone: true),
            _buildNewContactRow('738606699', isPhone: true),
            const Divider(height: 32),
            _buildNewContactRow('mn9048930@gmail.com', isEmail: true),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildNewContactRow(String contact, {bool isPhone = false, bool isEmail = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? Colors.grey.withOpacity(0.1) 
            : const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              isEmail ? Icons.email_rounded : Icons.phone_android_rounded,
              color: const Color(0xFF4A6DFF),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              contact,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                fontFamily: 'Cairo',
              ),
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.left,
            ),
          ),
          if (isPhone) ...[
            _buildActionButton(
              icon: Icons.call_rounded,
              color: const Color(0xFF10B981),
              onTap: () => launchUrl(Uri.parse('tel:$contact')),
            ),
            const SizedBox(width: 8),
            _buildActionButton(
              icon: Icons.chat_bubble_rounded,
              color: const Color(0xFF25D366), // WhatsApp Color
              onTap: () => launchUrl(Uri.parse('whatsapp://send?phone=967$contact')), // Assuming Yemen +967
            ),
          ],
          if (isEmail)
            _buildActionButton(
              icon: Icons.send_rounded,
              color: const Color(0xFF4A6DFF),
              onTap: () => launchUrl(Uri.parse('mailto:$contact')),
            ),
        ],
      ),
    );
  }

  void _showGuestRestrictionDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        backgroundColor: Theme.of(context).cardColor,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).cardColor,
                Theme.of(context).brightness == Brightness.dark 
                    ? Colors.black.withOpacity(0.2) 
                    : const Color(0xFFF8FAFF)
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD166), Color(0xFFFFB347)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFB347).withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    size: 48,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'ميزة محدودة',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                    fontFamily: 'Cairo',
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'للوصول إلى $feature، يجب عليك تسجيل الدخول برقم هاتفك',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.8),
                    height: 1.6,
                    fontFamily: 'NotoSansArabic',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor.withOpacity(0.1),
                        Theme.of(context).primaryColor.withOpacity(0.05)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مميزات الحساب المسجل:',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                          fontFamily: 'Cairo',
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildFeatureItem('إنشاء وإدارة الإعلانات', Icons.add_circle),
                      _buildFeatureItem('إضافة إعلانات للمفضلة', Icons.favorite),
                      _buildFeatureItem('التواصل مع البائعين', Icons.chat),
                      _buildFeatureItem('إدارة ملفك الشخصي', Icons.person),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 2,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.pop(ctx),
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              child: Center(
                                child: Text(
                                  'إلغاء',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Theme.of(context).textTheme.bodySmall?.color,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4A6DFF), Color(0xFF7B9AFF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4A6DFF).withOpacity(0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () async {
                              Navigator.pop(ctx);
                              await context.read<AuthProvider>().logout();
                              if (context.mounted) {
                                Navigator.pushReplacementNamed(context, '/login');
                              }
                            },
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.login_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'تسجيل الدخول',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontFamily: 'Cairo',
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
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

  Widget _buildFeatureItem(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF4A6DFF),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4A6DFF).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontFamily: 'NotoSansArabic',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color,
                color.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SliverTabBarDelegate({required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  double get maxExtent => 80;

  @override
  double get minExtent => 80;

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return child != oldDelegate.child;
  }
}