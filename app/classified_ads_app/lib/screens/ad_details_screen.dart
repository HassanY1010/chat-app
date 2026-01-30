import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../providers/ad_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/favorites_provider.dart';
import 'edit_ad_screen.dart';
import 'chat_screen.dart';
import 'public_profile_screen.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../utils/constants.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:timeago/timeago.dart';


class AdDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> ad;

  const AdDetailsScreen({super.key, required this.ad});

  @override
  State<AdDetailsScreen> createState() => _AdDetailsScreenState();
}

class _AdDetailsScreenState extends State<AdDetailsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<Color?> _gradientAnimation;
  
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  
  bool _isExpanded = false;
  bool _isLiked = false;
  int _likeCount = 0;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeInOutCubic),
      ),
    );
    
    _slideAnimation = Tween<double>(begin: 0.3, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOutBack),
      ),
    );
    
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _animationController.forward();
      }
    });
    
    _likeCount = widget.ad['likes_count'] ?? 0;
    _isLiked = widget.ad['is_liked'] ?? false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Initialize or update theme-dependent animations
    _gradientAnimation = ColorTween(
      begin: Theme.of(context).primaryColor.withAlpha(0),
      end: Theme.of(context).primaryColor,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  String _getCurrencySymbol(String? currency) {
    switch (currency?.toUpperCase()) {
      case 'YER':
        return '﷼';
      case 'SAR':
        return 'ر.س';
      case 'USD':
        return '\$';
      default:
        return '﷼';
    }
  }

  String _getCategoryName() {
    if (widget.ad['category'] != null && widget.ad['category']['name'] != null) {
      return widget.ad['category']['name'];
    }
    
    final categoryId = widget.ad['category_id']?.toString();
    if (categoryId != null) {
      // Use read instead of watch/select inside a method called by build (indirectly) or just read
      // Since this is called in build via _buildDetailCard, context.read is safe if not reacting.
      // Actually, if categories change, we might want to rebuild. But Provider is usually at top.
      // Better to use context.read as categories are likely loaded. 
      // However, to be reactive to categories loading, we might need Consumer or context.watch in build.
      // But let's stick to context.read for now as categories are usually pre-loaded.
      try {
         final categories = context.read<AdProvider>().categories;
         final category = categories.firstWhere(
           (c) => c['id'].toString() == categoryId,
           orElse: () => null,
         );
         if (category != null) return category['name'];
      } catch (e) {
        return 'غير محدد';
      }
    }
    
    return 'غير محدد';
  }

  Future<void> _makePhoneCall(String? phoneNumber) async {
    if (phoneNumber == null) {
      _showSnackBar('رقم الهاتف غير متوفر', isError: true);
      return;
    }
    
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isGuest) {
      _showGuestRestrictionDialog(context, 'الاطلاع على رقم الهاتف');
      return;
    }
    
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      _showSnackBar('تعذر الاتصال بالرقم', isError: true);
    }
  }

  Future<void> _shareAd() async {
    final adId = widget.ad['id'].toString();
    final adUrl = '${AppConstants.assetBaseUrl}/ad/$adId';
    final adTitle = widget.ad['title'] ?? 'إعلان';
    final adPrice = '${widget.ad['price'] ?? '0'} ${_getCurrencySymbol(widget.ad['currency'])}';
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(50),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(100),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'خيارات المشاركة',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: adUrl));
                  Navigator.pop(context);
                  _showSnackBar('تم نسخ الرابط بنجاح', isError: false);
                },
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00B0FF).withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.copy_rounded, color: Color(0xFF00B0FF)),
                ),
                title: const Text(
                  'نسخ الرابط',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Cairo',
                  ),
                ),
                subtitle: Text(
                  adUrl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontFamily: 'NotoSansArabic',
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Divider(height: 1),
              ),
              ListTile(
                onTap: () {
                  Navigator.pop(context);
                  Share.share(
                    '$adTitle\nالسعر: $adPrice\n\nشاهد هذا الإعلان على تطبيق حراج:\n$adUrl',
                    subject: adTitle,
                  );
                },
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.share_rounded, color: Color(0xFF8B5CF6)),
                ),
                title: const Text(
                  'مشاركة الرابط',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Cairo',
                  ),
                ),
                subtitle: Text(
                  'عبر تطبيقات التواصل الاجتماعي',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontFamily: 'NotoSansArabic',
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleLike() async {
    try {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.isGuest) {
        _showGuestRestrictionDialog(context, 'إضافة للمفضلة');
        return;
      }

      final adId = widget.ad['id'].toString();
      final adProvider = context.read<AdProvider>();
      
      setState(() {
        _isLiked = !_isLiked;
        _likeCount += _isLiked ? 1 : -1;
      });
      
      if (_isLiked) {
        await adProvider.likeAd(adId);
      } else {
        await adProvider.unlikeAd(adId);
      }
    } catch (e) {
      setState(() {
        _isLiked = !_isLiked;
        _likeCount += _isLiked ? -1 : 1;
      });
      _showSnackBar('حدث خطأ أثناء تحديث الإعجاب', isError: true);
    }
  }

  Future<void> _deleteAd() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withAlpha((0.85 * 255).toInt()),
      builder: (ctx) => Dialog(
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
                Theme.of(ctx).scaffoldBackgroundColor,
                Theme.of(ctx).scaffoldBackgroundColor.withAlpha((0.95 * 255).toInt()),
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
                      color: Colors.red.shade300.withAlpha((0.5 * 255).toInt()),
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
                  'حذف الإعلان',
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
                  'هل أنت متأكد من حذف هذا الإعلان؟',
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
                  'لا يمكن التراجع عن هذه العملية',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
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
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: BorderSide(
                            color: Colors.grey.shade400,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          'إلغاء',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade700,
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
                              color: Colors.red.shade400.withAlpha((0.5 * 255).toInt()),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            onTap: () => Navigator.pop(ctx, true),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: Text(
                                  'حذف',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withAlpha((0.95 * 255).toInt()),
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

if (confirm == true) {
  final adId = widget.ad['id'].toString();

  try {
    // Check if mounted before using context
    if (!mounted) return;

    await context.read<AdProvider>().deleteAd(adId);

    if (!mounted) return;

    _showSuccessDialog(
      context: context,
      message: 'تم حذف الإعلان بنجاح',
      icon: Icons.check_circle_rounded,
      onConfirm: () {
        if (!mounted) return;
        Navigator.pop(context);
        Navigator.pop(context);
      },
    );
  } catch (e) {
    if (!mounted) return;
    _showSnackBar('فشل حذف الإعلان', isError: true);
  }
}
  }



  void _reportAd() {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isGuest) {
      _showGuestRestrictionDialog(context, 'الإبلاغ عن إعلان');
      return;
    }
    final reasonController = TextEditingController();
    String? selectedReason;
    
    final reasons = [
      {'value': 'spam', 'label': 'إعلان مزعج أو spam'},
      {'value': 'inappropriate', 'label': 'محتوى غير لائق'},
      {'value': 'fraud', 'label': 'احتيال أو نصب'},
      {'value': 'wrong_category', 'label': 'قسم خاطئ'},
      {'value': 'duplicate', 'label': 'إعلان مكرر'},
      {'value': 'offensive', 'label': 'محتوى مسيء'},
      {'value': 'other', 'label': 'سبب آخر'},
    ];
    
    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha((0.85 * 255).toInt()),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          insetPadding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(ctx).scaffoldBackgroundColor,
                    Theme.of(ctx).scaffoldBackgroundColor.withAlpha((0.95 * 255).toInt()),
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
                          color: Colors.orange.shade300.withAlpha((0.5 * 255).toInt()),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.flag_rounded,
                      size: 36,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'إبلاغ عن مخالفة',
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
                      'اختر سبب الإبلاغ عن هذا الإعلان',
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
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: reasons.map((reason) {
                        return RadioListTile<String>(
                          title: Text(
                            reason['label']!,
                            style: TextStyle(
                              fontFamily: 'NotoSansArabic',
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey.shade300
                                  : Colors.grey.shade800,
                            ),
                          ),
                          value: reason['value']!,
                          // ignore: deprecated_member_use
                          groupValue: selectedReason,
                          activeColor: Colors.orange.shade700,
                          // ignore: deprecated_member_use
                          onChanged: (value) {
                            setState(() {
                              selectedReason = value;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                        );
                      }).toList(),
                    ),
                  ),
                  if (selectedReason == 'other') ...[
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade800
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TextField(
                          controller: reasonController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'اكتب سبب الإبلاغ هنا...',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade500,
                              fontFamily: 'NotoSansArabic',
                              fontWeight: FontWeight.w400,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade300
                                : Colors.grey.shade800,
                            fontFamily: 'NotoSansArabic',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              side: BorderSide(
                                color: Colors.grey.shade400,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              'إلغاء',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade700,
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
                                  color: Colors.orange.shade400.withAlpha((0.5 * 255).toInt()),
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
                                  if (selectedReason != null) {
                                    if (selectedReason == 'other' && reasonController.text.isEmpty) {
                                      _showSnackBar('يرجى كتابة سبب الإبلاغ', isError: true);
                                      return;
                                    }
                                    try {
                                      final adId = widget.ad['id'].toString();
                                      final description = selectedReason == 'other' 
                                          ? reasonController.text 
                                          : reasons.firstWhere((r) => r['value'] == selectedReason)['label']!;
                                      await context.read<AdProvider>().reportAd(adId, description);
                                      if (ctx.mounted) Navigator.pop(ctx);
                                      _showSnackBar('تم إرسال البلاغ بنجاح', isError: false);
                                    } catch (e) {
                                      _showSnackBar('فشل إرسال البلاغ', isError: true);
                                    }
                                  } else {
                                    _showSnackBar('يرجى اختيار سبب الإبلاغ', isError: true);
                                  }
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: Text(
                                      'إرسال',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white.withAlpha((0.95 * 255).toInt()),
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
        ),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isError ? Colors.red.shade600 : Colors.green.shade600,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
                color: Colors.white.withAlpha((0.95 * 255).toInt()),
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: Colors.white.withAlpha((0.95 * 255).toInt()),
                    fontSize: 14,
                    fontFamily: 'NotoSansArabic',
                    fontWeight: FontWeight.w500,
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

  void _showSuccessDialog({
    required BuildContext context,
    required String message,
    required IconData icon,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha((0.85 * 255).toInt()),
      builder: (ctx) => Dialog(
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
                Theme.of(ctx).scaffoldBackgroundColor,
                Theme.of(ctx).scaffoldBackgroundColor.withAlpha((0.95 * 255).toInt()),
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
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF10B981),
                      Color(0xFF059669),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withAlpha((0.5 * 255).toInt()),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  size: 36,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : const Color(0xFF1A237E),
                    fontFamily: 'Cairo',
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF1A237E),
                        Color(0xFF00B0FF),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1A237E).withAlpha((0.4 * 255).toInt()),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: onConfirm,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text(
                            'تم',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withAlpha((0.95 * 255).toInt()),
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
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _getImageWidgets() {
    final images = [];
    if (widget.ad['main_image'] != null) {
      images.add(widget.ad['main_image']);
    }
    
    if (widget.ad['images'] != null && widget.ad['images'] is List) {
      images.addAll(widget.ad['images']);
    }
    
    if (images.isEmpty) {
      return [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1A237E),
                const Color(0xFF1A237E).withAlpha((0.8 * 255).toInt()),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.photo_camera_back_rounded,
              size: 80,
              color: Colors.white,
            ),
          ),
        ),
      ];
    }
    
    return images.map((image) {
      final imageUrl = image['image_url'] ?? '';
          
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade200,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(Color(0xFF1A237E)),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade200,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.broken_image_rounded,
              size: 60,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final currentUserId = context.read<AuthProvider>().user?.id;
    final adUserId = widget.ad['user']?['id'] ?? widget.ad['user_id'];
    final isOwner = currentUserId != null && adUserId != null &&
                    (currentUserId.toString() == adUserId.toString());

    
    final images = _getImageWidgets();
    final formattedDate = widget.ad['created_at'] != null 
        ? () {
            timeago.setLocaleMessages('ar', ArMessages());
            return timeago.format(DateTime.parse(widget.ad['created_at']), locale: 'ar');
          }()
        : 'غير معروف';

    return Scaffold(
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Transform.translate(
              offset: Offset(0, _slideAnimation.value * 100),
              child: child,
            ),
          );
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 360,
              pinned: true,
              floating: false,
              snap: false,
              stretch: true,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              leading: Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor.withAlpha(240),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(30),
                      blurRadius: 15,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 20,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  onPressed: () => Navigator.pop(context),
                  splashRadius: 20,
                ),
              ),
              actions: [
                Consumer<FavoritesProvider>(
                  builder: (context, favorites, _) {
                    final isFav = favorites.isFavorite(int.tryParse(widget.ad['id'].toString()) ?? 0);
                    return Container(
                      margin: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(240),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(30),
                            blurRadius: 15,
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(
                          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isFav ? Colors.red : null,
                          size: 22,
                        ),
                        onPressed: () {
                          final authProvider = context.read<AuthProvider>();
                          if (authProvider.currentUser == UserType.guest) {
                            _showGuestRestrictionDialog(context, 'المفضلة');
                            return;
                          }
                          context.read<FavoritesProvider>().toggleFavorite(widget.ad['id'].toString());
                          _showSnackBar(
                            isFav ? 'تمت الإزالة من المفضلة' : 'تمت الإضافة إلى المفضلة',
                            isError: false,
                          );
                        },
                        splashRadius: 20,
                      ),
                    );
                  },
                ),
                Container(
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(240),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(30),
                        blurRadius: 15,
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.share_rounded, size: 22),
                    onPressed: _shareAd,
                    splashRadius: 20,
                  ),
                ),
                if (!isOwner) ...[
                  Container(
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(240),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(30),
                          blurRadius: 15,
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        _isLiked ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
                        color: _isLiked ? const Color(0xFF00B0FF) : null,
                        size: 22,
                      ),
                      onPressed: () async {
                        final authProvider = context.read<AuthProvider>();
                        if (authProvider.currentUser == UserType.guest) {
                          _showGuestRestrictionDialog(context, 'الإعجاب');
                          return;
                        }
                        await _toggleLike();
                      },
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(240),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(30),
                          blurRadius: 15,
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.flag_rounded, size: 22),
                      onPressed: () {
                        final authProvider = context.read<AuthProvider>();
                        if (authProvider.currentUser == UserType.guest) {
                          _showGuestRestrictionDialog(context, 'الإبلاغ');
                          return;
                        }
                        _reportAd();
                      },
                    ),
                  ),
                ] else ...[
                  Container(
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(240),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(30),
                          blurRadius: 15,
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.edit_rounded, size: 22),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditAdScreen(ad: widget.ad),
                          ),
                        );
                      },
                      splashRadius: 20,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(240),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(30),
                          blurRadius: 15,
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.delete_rounded, size: 22, color: Colors.red),
                      onPressed: _deleteAd,
                      splashRadius: 20,
                    ),
                  ),
                ],
              ],
              flexibleSpace: FlexibleSpaceBar(
                expandedTitleScale: 1.2,
                titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    PageView(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentImageIndex = index;
                        });
                      },
                      children: images,
                    ),
                    
                    // Gradient overlay
                    AnimatedBuilder(
                      animation: _gradientAnimation,
                      builder: (context, child) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                _gradientAnimation.value!.withAlpha((0.8 * 255).toInt()),
                                Colors.transparent,
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.6, 1.0],
                            ),
                          ),
                        );
                      },
                    ),
                    
                    if (images.length > 1)
                      Positioned(
                        bottom: 40,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(images.length, (index) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: _currentImageIndex == index ? 24 : 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: _currentImageIndex == index
                                    ? Colors.white
                                    : Colors.white.withAlpha(150),
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(30),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                      ),
                    
                    // Like count
                    if (!isOwner && _likeCount > 0)
                      Positioned(
                        right: 20,
                        bottom: 100,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor.withAlpha(220),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(20),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.thumb_up_rounded,
                                size: 16,
                                color: const Color(0xFF00B0FF),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _likeCount.toString(),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1A237E),
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Price
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: isDarkMode
                                ? Colors.black.withAlpha((0.4 * 255).toInt())
                                : Theme.of(context).primaryColor.withAlpha((0.1 * 255).toInt()),
                            blurRadius: 25,
                            offset: const Offset(0, 10),
                            spreadRadius: -10,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.ad['title'] ?? 'بدون عنوان',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        color: isDarkMode ? Colors.white : const Color(0xFF1A237E),
                                        height: 1.3,
                                        fontFamily: 'Cairo',
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on_rounded,
                                          size: 18,
                                          color: const Color(0xFF00B0FF),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            widget.ad['location'] ?? 'غير محدد',
                                            style: TextStyle(
                                              fontSize: 16,
                                          color: Theme.of(context).textTheme.bodySmall?.color,
                                              fontFamily: 'NotoSansArabic',
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF1A237E),
                                          Color(0xFF00B0FF),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF1A237E).withAlpha((0.4 * 255).toInt()),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      '${widget.ad['price'] ?? '0'} ${_getCurrencySymbol(widget.ad['currency'])}',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        fontFamily: 'Cairo',
                                      ),
                                    ),
                                  ),
                                  if (widget.ad['is_negotiable'] == true || widget.ad['is_negotiable'] == 1) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.orange.shade300,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.handshake_rounded,
                                            size: 16,
                                            color: Colors.orange.shade700,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'قابل للتفاوض',
                                            style: TextStyle(
                                              color: Colors.orange.shade700,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                              fontFamily: 'NotoSansArabic',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Ad Details Cards
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.6,
                      children: [
                        _buildDetailCard(
                          icon: Icons.category_rounded,
                          title: 'القسم',
                          value: _getCategoryName(),
                          color: const Color(0xFF8B5CF6),
                          isDarkMode: isDarkMode,
                        ),
                        _buildDetailCard(
                          icon: Icons.date_range_rounded,
                          title: 'تاريخ النشر',
                          value: formattedDate,
                          color: const Color(0xFF10B981),
                          isDarkMode: isDarkMode,
                        ),
                        _buildDetailCard(
                          icon: Icons.remove_red_eye_rounded,
                          title: 'المشاهدات',
                          value: '${widget.ad['views'] ?? 0}',
                          color: const Color(0xFF00B0FF),
                          isDarkMode: isDarkMode,
                        ),
                        _buildDetailCard(
                          icon: Icons.verified_rounded,
                          title: 'الحالة',
                          value: widget.ad['status'] == 'active' ? 'نشط' : 'مغلق',
                          color: widget.ad['status'] == 'active' ? const Color(0xFF10B981) : Colors.red,
                          isDarkMode: isDarkMode,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Description
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: isDarkMode
                                ? Colors.black.withAlpha((0.4 * 255).toInt())
                                : Theme.of(context).primaryColor.withAlpha((0.1 * 255).toInt()),
                            blurRadius: 25,
                            offset: const Offset(0, 10),
                            spreadRadius: -10,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00B0FF).withAlpha((0.15 * 255).toInt()),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF00B0FF).withAlpha((0.3 * 255).toInt()),
                                  ),
                                ),
                                child: Text(
                                  'وصف الإعلان',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF00B0FF),
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.description_rounded,
                                color: const Color(0xFF00B0FF),
                                size: 24,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _isExpanded
                              ? Container(
                                  height: 250,
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Theme.of(context).dividerColor.withOpacity(0.5),
                                    ),
                                  ),
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: Text(
                                      widget.ad['description'] ?? 'لا يوجد وصف',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Theme.of(context).textTheme.bodyMedium?.color,
                                        height: 1.7,
                                        fontFamily: 'NotoSansArabic',
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                )
                              : Text(
                                  widget.ad['description'] ?? 'لا يوجد وصف',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Theme.of(context).textTheme.bodyMedium?.color,
                                    height: 1.7,
                                    fontFamily: 'NotoSansArabic',
                                    fontWeight: FontWeight.w400,
                                  ),
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                ),
                          if ((widget.ad['description'] ?? '').length > 200)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isExpanded = !_isExpanded;
                                  });
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Container(
                                  margin: const EdgeInsets.only(top: 12),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A237E).withAlpha((0.1 * 255).toInt()),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _isExpanded ? 'عرض أقل' : 'عرض المزيد',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1A237E),
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Seller Info
                    GestureDetector(
                      onTap: () {
                        if (widget.ad['user'] != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PublicProfileScreen(
                                userId: widget.ad['user']['id'].toString(),
                              ),
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey.shade800 : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: isDarkMode
                                  ? Colors.black.withAlpha((0.4 * 255).toInt())
                                  : const Color(0xFF1A237E).withAlpha((0.1 * 255).toInt()),
                              blurRadius: 25,
                              offset: const Offset(0, 10),
                              spreadRadius: -10,
                            ),
                          ],
                          border: Border.all(
                            color: const Color(0xFF1A237E).withAlpha((0.1 * 255).toInt()),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF8B5CF6).withAlpha((0.15 * 255).toInt()),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFF8B5CF6).withAlpha((0.3 * 255).toInt()),
                                    ),
                                  ),
                                  child: Text(
                                    'معلومات البائع',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF8B5CF6),
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.person_rounded,
                                  color: const Color(0xFF8B5CF6),
                                  size: 24,
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF8B5CF6),
                                        Color(0xFF4F46E5),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF8B5CF6).withAlpha((0.4 * 255).toInt()),
                                        blurRadius: 15,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                  child: ClipOval(
                                    child: widget.ad['user'] != null && 
                                           widget.ad['user']['avatar'] != null && 
                                           widget.ad['user']['avatar'].toString().isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: widget.ad['user']['avatar_url'],
                                            fit: BoxFit.cover,
                                            width: 70,
                                            height: 70,
                                            placeholder: (context, url) => Container(
                                              color: Colors.grey.shade200,
                                              child: const Center(
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              ),
                                            ),
                                            errorWidget: (context, url, error) => Center(
                                              child: Text(
                                                widget.ad['user']?['name']?[0] ?? 'U',
                                                style: const TextStyle(
                                                  fontSize: 26,
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.white,
                                                  fontFamily: 'Cairo',
                                                ),
                                              ),
                                            ),
                                          )
                                        : Center(
                                            child: Text(
                                              widget.ad['user']?['name']?[0] ?? 'U',
                                              style: const TextStyle(
                                                fontSize: 26,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                                fontFamily: 'Cairo',
                                              ),
                                            ),
                                          ),
                                  ),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.ad['user']?['name'] ?? 'مستخدم',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          color: isDarkMode ? Colors.white : const Color(0xFF1A237E),
                                          fontFamily: 'Cairo',
                                          height: 1.3,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'عضو منذ ${widget.ad['user']?['created_at']?.split('T')[0] ?? "تاريخ غير معروف"}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Theme.of(context).textTheme.bodySmall?.color,
                                          fontFamily: 'NotoSansArabic',
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          RatingBar.builder(
                                            initialRating: double.tryParse(widget.ad['user']?['rating']?.toString() ?? '0') ?? 0.0,
                                            minRating: 1,
                                            direction: Axis.horizontal,
                                            allowHalfRating: true,
                                            ignoreGestures: true, // Read-only
                                            itemCount: 5,
                                            itemSize: 18,
                                            itemBuilder: (context, _) => const Icon(
                                              Icons.star_rounded,
                                              color: Colors.amber,
                                            ),
                                            onRatingUpdate: (rating) {},
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            '${double.tryParse(widget.ad['user']?['rating']?.toString() ?? '0')?.toStringAsFixed(1) ?? "0.0"} (${widget.ad['user']?['ratings_count'] ?? 0} تقييم)',
                                            style: TextStyle(
                                              fontSize: 13,
                                          color: Theme.of(context).textTheme.bodySmall?.color,
                                              fontFamily: 'Cairo',
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 18,
                                  color: const Color(0xFF00B0FF),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Comments Section
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: isDarkMode
                                ? Colors.black.withAlpha((0.4 * 255).toInt())
                                : Theme.of(context).primaryColor.withAlpha((0.1 * 255).toInt()),
                            blurRadius: 25,
                            offset: const Offset(0, 10),
                            spreadRadius: -10,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withAlpha((0.15 * 255).toInt()),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF10B981).withAlpha((0.3 * 255).toInt()),
                                  ),
                                ),
                                child: Text(
                                  'التعليقات',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF10B981),
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.comment_rounded,
                                color: const Color(0xFF10B981),
                                size: 24,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildCommentsSection(isDarkMode),
                          const SizedBox(height: 16),
                          _buildCommentInput(isDarkMode),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      
      bottomSheet: _buildBottomContactBar(context, isOwner, isDarkMode),
    );
  }

  Widget _buildBottomContactBar(BuildContext context, bool isOwner, bool isDarkMode) {
    if (isOwner) return const SizedBox();

    final contactPhone = widget.ad['contact_phone'];
    final contactWhatsapp = widget.ad['contact_whatsapp'];

    final hasCall = contactPhone != null && contactPhone.toString().isNotEmpty;
    final hasWhatsapp = contactWhatsapp != null && contactWhatsapp.toString().isNotEmpty;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.25 * 255).toInt()),
            blurRadius: 30,
            spreadRadius: -5,
          ),
        ],
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1.5,
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (hasCall) ...[
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.shade600,
                        Colors.green.shade800,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.shade400.withAlpha((0.4 * 255).toInt()),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      onTap: () {
                        final authProvider = context.read<AuthProvider>();
                        if (authProvider.currentUser == UserType.guest) {
                          _showGuestRestrictionDialog(context, 'الاتصال');
                          return;
                        }
                        _makePhoneCall(contactPhone.toString());
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.phone_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'اتصال',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],

            if (hasWhatsapp) ...[
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF25D366),
                        Color(0xFF128C7E),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF25D366).withAlpha((0.4 * 255).toInt()),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      onTap: () {
                        final authProvider = context.read<AuthProvider>();
                        if (authProvider.currentUser == UserType.guest) {
                          _showGuestRestrictionDialog(context, 'واتساب');
                          return;
                        }
                        launchUrl(Uri.parse("https://wa.me/${contactWhatsapp.toString().replaceAll('+', '')}"));
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.chat_bubble_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'واتساب',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF1A237E),
                      Color(0xFF00B0FF),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1A237E).withAlpha((0.4 * 255).toInt()),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    onTap: () {
                      final authProvider = context.read<AuthProvider>();
                      if (authProvider.currentUser == UserType.guest) {
                        _showGuestRestrictionDialog(context, 'المراسلة');
                        return;
                      }
                      final userId = int.tryParse((widget.ad['user']?['id'] ?? widget.ad['user_id'])?.toString() ?? '');
                      if (userId == null) {
                        _showSnackBar('تعذر معرفة معرف المستخدم', isError: true);
                        return;
                      }
                      
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            receiverId: userId,
                            receiverName: widget.ad['user']?['name'] ?? 'المعلن',
                            receiverAvatar: widget.ad['user']?['avatar_url'],
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.forum_rounded,
                            color: Colors.white.withAlpha((0.95 * 255).toInt()),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'مراسلة',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white.withAlpha((0.95 * 255).toInt()),
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required bool isDarkMode,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withAlpha((0.3 * 255).toInt())
                : color.withAlpha((0.15 * 255).toInt()),
            blurRadius: 15,
            offset: const Offset(0, 6),
            spreadRadius: -5,
          ),
        ],
        border: Border.all(
          color: color.withAlpha((0.1 * 255).toInt()),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withAlpha((0.15 * 255).toInt()),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                fontFamily: 'NotoSansArabic',
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection(bool isDarkMode) {
    if (widget.ad['id'] == null) return const SizedBox();
    
    return Column(
      children: [
        FutureBuilder<List<dynamic>>(
          future: context.read<AdProvider>().fetchComments(widget.ad['id'].toString()),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(const Color(0xFF00B0FF)),
                  ),
                ),
              );
            }
            
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Icon(
                      Icons.comment_outlined,
                      size: 60,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'لا توجد تعليقات بعد',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade500,
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'كن أول من يعلق على هذا الإعلان',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                        fontFamily: 'NotoSansArabic',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              );
            }
            
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: snapshot.data!.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final comment = snapshot.data![index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey.withAlpha((0.1 * 255).toInt()),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF8B5CF6),
                                  Color(0xFF4F46E5),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                (comment['user']['name']?[0] ?? 'م').toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  comment['user']['name'] ?? 'مستخدم',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: isDarkMode ? Colors.white : const Color(0xFF1A237E),
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                                Text(
                                  _formatDate(comment['created_at']),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                    fontFamily: 'NotoSansArabic',
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        comment['content'] ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          fontFamily: 'NotoSansArabic',
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildCommentInput(bool isDarkMode) {
    // Check for guest user
    final authProvider = context.watch<AuthProvider>();
    if (authProvider.currentUser == UserType.guest) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: ElevatedButton.icon(
          onPressed: () => _showGuestRestrictionDialog(context, 'التعليقات'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A237E),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
          ),
          icon: const Icon(Icons.login_rounded, size: 20),
          label: const Text(
            'سجل دخولك لإضافة تعليق',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'Cairo',
            ),
          ),
        ),
      );
    }

    // final commentController = TextEditingController();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[900] : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              maxLines: 1,
              decoration: InputDecoration(
                hintText: 'اكتب تعليقك هنا...',
                hintStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontFamily: 'NotoSansArabic',
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontFamily: 'NotoSansArabic',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF00B0FF),
                  Color(0xFF0091EA),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00B0FF).withAlpha((0.4 * 255).toInt()),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: () async {
                  if (_commentController.text.isNotEmpty) {
                    try {
                      await context.read<AdProvider>().addComment(
                        widget.ad['id'].toString(), 
                        _commentController.text
                      );
                      _commentController.clear();
                      setState(() {}); 
                      _showSnackBar('تم إضافة التعليق', isError: false);
                    } catch (e) {
                      _showSnackBar('فشل إضافة التعليق: ${e.toString()}', isError: true);
                    }
                  } else {
                    _showSnackBar('يرجى كتابة تعليق', isError: true);
                  }
                },
                borderRadius: BorderRadius.circular(22),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      
      if (diff.inMinutes < 1) return 'الآن';
      if (diff.inHours < 1) return 'قبل ${diff.inMinutes} دقيقة';
      if (diff.inDays < 1) return 'قبل ${diff.inHours} ساعة';
      if (diff.inDays == 1) return 'أمس';
      if (diff.inDays < 7) return 'قبل ${diff.inDays} يوم';
      
      return DateFormat('yyyy/MM/dd', 'ar').format(date);
    } catch (_) {
      return '';
    }
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
                Theme.of(context).brightness == Brightness.dark ? Colors.grey[900]! : const Color(0xFFF8FAFF)
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
                        color: const Color(0xFFFFB347).withValues(alpha: 0.4),
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
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    height: 1.6,
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
                              color: const Color(0xFF4A6DFF).withValues(alpha: 0.4),
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
}