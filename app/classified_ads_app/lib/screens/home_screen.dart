import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/ad_provider.dart';
import '../providers/notification_provider.dart';
import '../widgets/ad_card.dart';
import 'ad_details_screen.dart';
import 'conversations_screen.dart';
import '../providers/auth_provider.dart';
import 'create_ad_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import '../utils/constants.dart';
import 'package:classified_ads_app/utils/app_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:timeago/timeago.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    /* _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward(); */
    
    _screens = [
      const AdsListScreen(),
      CategoriesScreen(onCategorySelected: (id) {
        setState(() => _currentIndex = 0);
        final provider = context.read<AdProvider>();
        provider.setCategory(id);
        provider.fetchAds(categoryId: id);
      }),
      const CreateAdScreen(),
      const ConversationsScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  void dispose() {
    // _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isGuest = authProvider.isGuest;
    
    return WillPopScope(
      onWillPop: () async {
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          return false;
        }
        return true;
      },
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
        floatingActionButton: (_currentIndex == 2) ? null : _buildFloatingActionButton(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: (Theme.of(context).brightness == Brightness.dark 
                ? Colors.black 
                : const Color(0xFF1A237E)).withValues(alpha: 0.1),
            blurRadius: 40,
            spreadRadius: 0,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            elevation: 0,
            backgroundColor: Theme.of(context).cardColor,
            indicatorColor: Colors.transparent,
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
               if (states.contains(WidgetState.selected)) {
                 return const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'NotoSansArabic',
                  color: Color(0xFF4A6DFF),
                 );
               }
               return const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'NotoSansArabic',
                color: Color(0xFF94A3B8),
               );
            }),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Theme.of(context).cardColor,
            elevation: 0,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            selectedItemColor: const Color(0xFF4A6DFF),
            unselectedItemColor: Theme.of(context).brightness == Brightness.dark 
                ? Colors.grey[600] 
                : const Color(0xFF94A3B8),
            onTap: (index) {
              final authProvider = context.read<AuthProvider>();
              final isGuest = authProvider.isGuest;
              
              if (authProvider.currentUser == UserType.guest && index == 3) {
                _showGuestRestrictionDialog(context, 'المراسلات');
                return;
              }
              
              if (authProvider.currentUser == UserType.guest && index == 2) {
                _showGuestRestrictionDialog(context, 'إنشاء إعلان');
                return;
              }
              
              setState(() => _currentIndex = index);
            },
            items: [
              BottomNavigationBarItem(
                icon: _buildNavIcon(
                  AppIcons.homeFilled, 
                  AppIcons.home, 
                  0
                ),
                label: 'الرئيسية',
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon(
                  AppIcons.categoriesFilled, 
                  AppIcons.categories, 
                  1
                ),
                label: 'الأقسام',
              ),
              const BottomNavigationBarItem(
                icon: SizedBox.shrink(),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _buildNavIcon(
                      AppIcons.chatFilled, 
                      AppIcons.chat, 
                      3
                    ),
                    Consumer<NotificationProvider>(
                      builder: (context, provider, _) => provider.unreadCount > 0 
                      ? Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF4757),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF4757).withValues(alpha: 0.4),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                    ),
                  ],
                ),
                label: 'المراسلات',
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon(
                  AppIcons.profileFilled, 
                  AppIcons.profile, 
                  4
                ),
                label: 'حسابي',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavIcon(String activeIcon, String inactiveIcon, int index) {
    final isSelected = _currentIndex == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      padding: EdgeInsets.all(isSelected ? 12 : 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF4A6DFF).withValues(alpha: 0.1) : Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: SvgPicture.asset(
        isSelected ? activeIcon : inactiveIcon,
        width: 24,
        height: 24,
        colorFilter: ColorFilter.mode(
          isSelected 
              ? const Color(0xFF4A6DFF) 
              : (Theme.of(context).brightness == Brightness.dark 
                  ? Colors.grey[500]! 
                  : const Color(0xFF94A3B8)),
          BlendMode.srcIn,
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
      height: 72,
      width: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF4A6DFF), Color(0xFF7B9AFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4A6DFF).withValues(alpha: 0.5),
              blurRadius: 20,
              spreadRadius: 4,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: const Color(0xFF7B9AFF).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
          border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 4),
        ),
        child: FloatingActionButton(
          onPressed: () {
            final authProvider = context.read<AuthProvider>();
            if (authProvider.currentUser == UserType.guest) {
              _showGuestRestrictionDialog(context, 'إنشاء إعلان');
              return;
            }
            setState(() => _currentIndex = 2);
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          shape: const CircleBorder(),
          child: SvgPicture.asset(
            AppIcons.plus,
            width: 32,
            height: 32,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
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
                  color: const Color(0xFF4A6DFF).withValues(alpha: 0.3),
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
}

class AdsListScreen extends StatefulWidget {
  const AdsListScreen({super.key});

  @override
  State<AdsListScreen> createState() => _AdsListScreenState();
}

class _AdsListScreenState extends State<AdsListScreen> with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  late ScrollController _scrollController;
  
  String? _selectedCategory;
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();
  String? _selectedCurrency;
  
  bool _showSearchBar = false;
  late AnimationController _searchAnimationController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    Future.microtask(() {
      if (!mounted) return;
      final provider = context.read<AdProvider>();
      if (provider.currentCategory != null) {
        setState(() {
          _selectedCategory = provider.currentCategory;
        });
      }
      
      _fetchAds();
      context.read<NotificationProvider>().fetchNotifications();
    });
    
    _scrollController.addListener(() {
      if (_scrollController.offset > 100 && _showSearchBar) {
        _toggleSearchBar(false);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.watch<AdProvider>();
    if (provider.currentCategory != _selectedCategory) {
       if (provider.currentCategory != null) {
          _selectedCategory = provider.currentCategory;
       }
    }
  }

  void _toggleSearchBar(bool show) {
    setState(() => _showSearchBar = show);
    if (show) {
      _searchAnimationController.forward();
    } else {
      _searchAnimationController.reverse();
    }
  }

  Future<void> _fetchAds() async {
    await context.read<AdProvider>().fetchAds(
      search: _searchController.text.isEmpty ? null : _searchController.text,
      categoryId: _selectedCategory,
      minPrice: _minPriceController.text.isEmpty ? null : _minPriceController.text,
      maxPrice: _maxPriceController.text.isEmpty ? null : _maxPriceController.text,
      currency: _selectedCurrency,
    );
  }

  void _showFilterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 32,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Indicator
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'تصفية النتائج',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Theme.of(context).textTheme.titleLarge?.color,
                              fontFamily: 'Cairo',
                              letterSpacing: -0.5,
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark 
                                  ? Colors.grey[900] 
                                  : const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Icon(Icons.close_rounded, size: 24, color: Theme.of(context).textTheme.bodySmall?.color),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Category Filter
                      _buildFilterSection(
                        context: context,
                        icon: Icons.category_rounded,
                        title: 'القسم',
                        child: Consumer<AdProvider>(
                          builder: (context, adProvider, child) {
                            if (adProvider.categories.isEmpty) {
                              adProvider.fetchCategories();
                              return const Center(child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: LinearProgressIndicator(),
                              ));
                            }
                            // Safety check: ensure _selectedCategory exists in the items list
                            final dropdownValue = adProvider.categories.any((c) => c['id'].toString() == _selectedCategory)
                                ? _selectedCategory
                                : null;

                            return DropdownButtonFormField<String>(
                              value: dropdownValue,
                              dropdownColor: Theme.of(context).cardColor,
                              decoration: _getInputDecoration(context, 'اختر القسم'),
                              items: [
                                DropdownMenuItem(
                                  value: null,
                                  child: Text(
                                    'جميع الأقسام',
                                    style: TextStyle(
                                      color: Theme.of(context).textTheme.bodyMedium?.color,
                                      fontFamily: 'NotoSansArabic',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                ...adProvider.categories.map((category) {
                                  return DropdownMenuItem(
                                    value: category['id'].toString(),
                                    child: Text(
                                      category['name'],
                                      style: TextStyle(
                                        fontFamily: 'NotoSansArabic',
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).textTheme.bodyMedium?.color,
                                      ),
                                    ),
                                  );
                                }),
                              ],
                              onChanged: (v) {
                                setModalState(() => _selectedCategory = v);
                                setState(() => _selectedCategory = v);
                              },
                              borderRadius: BorderRadius.circular(16),
                            );
                          },
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Price Range Filter
                      _buildFilterSection(
                        context: context,
                        icon: Icons.attach_money_rounded,
                        title: 'نطاق السعر',
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _minPriceController,
                                keyboardType: TextInputType.number,
                                decoration: _getInputDecoration(context, 'الحد الأدنى').copyWith(
                                  prefixText: '﷼ ',
                                ),
                                style: _getInputTextStyle(context),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Icon(Icons.remove_rounded, color: Color(0xFF4A6DFF), size: 20),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _maxPriceController,
                                keyboardType: TextInputType.number,
                                decoration: _getInputDecoration(context, 'الحد الأقصى').copyWith(
                                  prefixText: '﷼ ',
                                ),
                                style: _getInputTextStyle(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Currency Filter
                      _buildFilterSection(
                        context: context,
                        icon: Icons.monetization_on_rounded,
                        title: 'العملة',
                        child: DropdownButtonFormField<String>(
                          value: _selectedCurrency,
                          decoration: _getInputDecoration(context, 'اختر العملة'),
                          items: const [
                            DropdownMenuItem(
                              value: null,
                              child: Text(
                                'جميع العملات',
                                style: TextStyle(
                                  color: Color(0xFF475569),
                                  fontFamily: 'NotoSansArabic',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'YER',
                              child: Text('﷼ ريال يمني'),
                            ),
                            DropdownMenuItem(
                              value: 'SAR',
                              child: Text('ر.س ريال سعودي'),
                            ),
                            DropdownMenuItem(
                              value: 'USD',
                              child: Text('\$ دولار أمريكي'),
                            ),
                          ],
                          onChanged: (v) {
                            setModalState(() => _selectedCurrency = v);
                            setState(() => _selectedCurrency = v);
                          },
                          borderRadius: BorderRadius.circular(16),
                          style: _getInputTextStyle(context),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              context: context,
                              label: 'مسح الفلاتر',
                              icon: Icons.refresh_rounded,
                              isPrimary: false,
                              onTap: () {
                                setModalState(() {
                                  _selectedCategory = null;
                                  _selectedCurrency = null;
                                  _minPriceController.clear();
                                  _maxPriceController.clear();
                                });
                                setState(() {
                                  _selectedCategory = null;
                                  _selectedCurrency = null;
                                  _minPriceController.clear();
                                  _maxPriceController.clear();
                                });
                                context.read<AdProvider>().setCategory(null);
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildActionButton(
                              context: context,
                              label: 'تطبيق الفلاتر',
                              icon: Icons.filter_alt_rounded,
                              isPrimary: true,
                              onTap: () {
                                Navigator.pop(context);
                                context.read<AdProvider>().setCategory(_selectedCategory);
                                _fetchAds();
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24), // Bottom breathing room
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF4A6DFF).withValues(alpha: 0.1),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A6DFF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  InputDecoration _getInputDecoration(BuildContext context, String hint) {
    return InputDecoration(
      filled: true,
      fillColor: Theme.of(context).cardColor,
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF94A3B8),
        fontFamily: 'Cairo',
        fontSize: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF4A6DFF), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  TextStyle _getInputTextStyle(BuildContext context) {
    return TextStyle(
      fontFamily: 'Cairo',
      fontWeight: FontWeight.w700,
      color: Theme.of(context).textTheme.bodyLarge?.color,
      fontSize: 15,
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: isPrimary ? const LinearGradient(
          colors: [Color(0xFF4A6DFF), Color(0xFF7B9AFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ) : null,
        color: isPrimary ? null : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: isPrimary ? null : Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: isPrimary ? [
          BoxShadow(
            color: const Color(0xFF4A6DFF).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isPrimary ? Colors.white : const Color(0xFF64748B),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    color: isPrimary ? Colors.white : const Color(0xFF64748B),
                    fontWeight: isPrimary ? FontWeight.w900 : FontWeight.w800,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 140,
              floating: true,
              pinned: true,
              snap: true,
              backgroundColor: Colors.white,
              elevation: 0,
              surfaceTintColor: Colors.white,
              shadowColor: Colors.transparent,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 16),
                  child: Consumer<NotificationProvider>(
                    builder: (context, notificationProvider, _) => Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4A6DFF), Color(0xFF7B9AFF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF4A6DFF).withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.notifications_rounded, color: Colors.white, size: 24),
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                              },
                              tooltip: 'الإشعارات',
                            ),
                          ),
                          if (notificationProvider.unreadCount > 0)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF4757),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFFFF4757),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 20,
                                  minHeight: 20,
                                ),
                                child: Text(
                                  '${notificationProvider.unreadCount}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'Cairo',
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF4A6DFF),
                        Color(0xFF7B9AFF),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF4A6DFF),
                        blurRadius: 32,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 70, left: 24, right: 24, bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'لقطة',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            fontFamily: 'Cairo',
                            letterSpacing: -1,
                            shadows: [
                              const Shadow(
                                color: Colors.black26,
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'اشتري وبيع بكل سهولة وأمان',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withValues(alpha: 0.95),
                            fontFamily: 'NotoSansArabic',
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(80),
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: '🔍 ابحث عن سيارة، عقار، جهاز...',
                          hintStyle: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontFamily: 'NotoSansArabic',
                            fontWeight: FontWeight.w500,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2C2C2C) : Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                          suffixIcon: Container(
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4A6DFF), Color(0xFF7B9AFF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF4A6DFF).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: SvgPicture.asset(AppIcons.filter, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn), width: 24),
                              onPressed: () => _showFilterModal(context),
                            ),
                          ),
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () => _fetchAds(),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    child: SvgPicture.asset(AppIcons.search, width: 24, colorFilter: const ColorFilter.mode(Color(0xFF4A6DFF), BlendMode.srcIn)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        style: TextStyle(
                          fontFamily: 'NotoSansArabic',
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          fontSize: 16,
                        ),
                        onSubmitted: (_) => _fetchAds(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ];
        },
        body: _buildBody(),
      ),
    );
  }
  
  Widget _buildBody() {
    return Column(
      children: [
        Expanded(
          child: Consumer<AdProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading && provider.ads.isEmpty) {
                return _buildShimmerList(count: 6);
              }
              
              return RefreshIndicator(
                onRefresh: _fetchAds,
                color: const Color(0xFF4A6DFF),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
                  itemCount: provider.ads.length + 1, // +1 for the header
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildHeaderSection(provider);
                    }
                    
                    final ad = provider.ads[index - 1];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      child: AdCard(ad: ad),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderSection(AdProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
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
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'أحدث الإعلانات',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1A237E),
                  fontFamily: 'Cairo',
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (provider.currentCategory != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF4A6DFF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF4A6DFF).withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SvgPicture.asset(AppIcons.filter, width: 20, colorFilter: const ColorFilter.mode(Color(0xFF4A6DFF), BlendMode.srcIn)),
                      const SizedBox(width: 12),
                      const Text(
                        'تصفية حسب القسم',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A237E),
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () {
                      provider.setCategory(null);
                      _fetchAds();
                    },
                    icon: SvgPicture.asset(AppIcons.close, width: 18, colorFilter: const ColorFilter.mode(Color(0xFFEF4444), BlendMode.srcIn)),
                    label: const Text(
                      'إلغاء التصفية',
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (provider.ads.isEmpty && !provider.isLoading)
          _buildEmptyState(provider),
      ],
    );
  }

  Widget _buildEmptyState(AdProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 48,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "لا توجد إعلانات مطابقة",
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFF64748B),
                fontFamily: 'NotoSansArabic',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                provider.setCategory(null);
                _fetchAds();
              },
              child: const Text('العودة للرئيسية'),
            ),
          ],
        ),
      ),
    );
  }
  

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      timeago.setLocaleMessages('ar', ArMessages());
      return timeago.format(date, locale: 'ar');
    } catch (_) {
      return dateStr;
    }
  }

  Widget _buildShimmerList({int count = 6}) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      itemCount: count,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Shimmer.fromColors(
          baseColor: const Color(0xFFF1F5F9),
          highlightColor: Colors.white,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchAnimationController.dispose();
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }
}

class CategoriesScreen extends StatefulWidget {
  final Function(String) onCategorySelected;

  const CategoriesScreen({super.key, required this.onCategorySelected});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<dynamic> _categories = [];
  List<dynamic> _currentCategories = [];
  final List<Map<String, dynamic>> _navigationStack = [];
  bool _isLoading = true;

  // Image mapping
  final Map<String, String> _imageMap = {
    'directions_car_rounded': 'https://images.unsplash.com/photo-1492144534655-ae79c964c9d7?auto=format&fit=crop&w=500&q=80',
    'home_work_rounded': 'https://images.unsplash.com/photo-1560518883-ce09059eeffa?auto=format&fit=crop&w=500&q=80',
    'devices_other_rounded': 'https://images.unsplash.com/photo-1519389950473-47ba0277781c?auto=format&fit=crop&w=500&q=80',
    'chair_rounded': 'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?auto=format&fit=crop&w=500&q=80',
    'checkroom_rounded': 'https://images.unsplash.com/photo-1483985988355-763728e1935b?auto=format&fit=crop&w=500&q=80',
    'kitchen_rounded': 'https://images.unsplash.com/photo-1556911220-bff31c812dba?auto=format&fit=crop&w=500&q=80',
    'pets_rounded': 'https://images.unsplash.com/photo-1543466835-00a7907e9de1?auto=format&fit=crop&w=500&q=80',
    'sports_esports_rounded': 'https://images.unsplash.com/photo-1542751371-adc38448a05e?auto=format&fit=crop&w=500&q=80',
    'construction_rounded': 'https://plus.unsplash.com/premium_photo-1663090072552-46099749ab96?q=80&w=836&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
    'brush_rounded': 'https://images.unsplash.com/photo-1513364776144-60967b0f800f?auto=format&fit=crop&w=500&q=80',
    'child_care_rounded': 'https://img.freepik.com/free-vector/cartoon-girl-birthday-objects-collection_52683-66244.jpg?t=st=1769575290~exp=1769578890~hmac=8111646279d45dbd967147f5c8a1ad7fa0dadff2228def1c674afe4b09549495',
  };

  // Smart Keyword Image mapping (for subcategories)
  final Map<String, String> _keywordImageMap = {
    // Electronics & Phones
    'جوال': 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?auto=format&fit=crop&w=500&q=80',
    'هاتف': 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?auto=format&fit=crop&w=500&q=80',
    'موبايل': 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?auto=format&fit=crop&w=500&q=80',
    'iphone': 'https://images.unsplash.com/photo-1510557880182-3d4d3cba35a5?auto=format&fit=crop&w=500&q=80',
    'ايفون': 'https://images.unsplash.com/photo-1510557880182-3d4d3cba35a5?auto=format&fit=crop&w=500&q=80',
    'سامسونج': 'https://images.unsplash.com/photo-1610945415295-d9bbf067e59c?auto=format&fit=crop&w=500&q=80',
    'لابتوب': 'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?auto=format&fit=crop&w=500&q=80',
    'كمبيوتر': 'https://images.unsplash.com/photo-1547082299-bb196bcce49c?auto=format&fit=crop&w=500&q=80',
    'كاميرا': 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?auto=format&fit=crop&w=500&q=80',
    'تلفزيون': 'https://images.unsplash.com/photo-1593359677879-a4bb92f829d1?auto=format&fit=crop&w=500&q=80',
    'شاشة': 'https://images.unsplash.com/photo-1593359677879-a4bb92f829d1?auto=format&fit=crop&w=500&q=80',
    'تابلت': 'https://images.unsplash.com/photo-1544244015-0df4b3ffc6b0?auto=format&fit=crop&w=500&q=80',
    
    // Cars
    'سيارة': 'https://images.unsplash.com/photo-1503376763036-066120622c74?auto=format&fit=crop&w=500&q=80',
    'مركبة': 'https://images.unsplash.com/photo-1503376763036-066120622c74?auto=format&fit=crop&w=500&q=80',
    'تويوتا': 'https://images.unsplash.com/photo-1590362891991-f776e747a588?auto=format&fit=crop&w=500&q=80',
    'هونداي': 'https://images.unsplash.com/photo-1623916947700-60b6d917f692?auto=format&fit=crop&w=500&q=80',
    'مرسيدس': 'https://images.unsplash.com/photo-1617788138017-80ad40651399?auto=format&fit=crop&w=500&q=80',
    
    // Real Estate
    'شقة': 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=500&q=80',
    'فيلا': 'https://images.unsplash.com/photo-1613977257363-707ba9348227?auto=format&fit=crop&w=500&q=80',
    'بيت': 'https://images.unsplash.com/photo-1580587771525-78b9dba3b91d?auto=format&fit=crop&w=500&q=80',
    'عمارة': 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&w=500&q=80',
    'ارض': 'https://images.unsplash.com/photo-1500382017468-9049fed747ef?auto=format&fit=crop&w=500&q=80',
    
    // Furniture
    'كنب': 'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?auto=format&fit=crop&w=500&q=80',
    'سرير': 'https://images.unsplash.com/photo-1505693416388-c03dc069d53b?auto=format&fit=crop&w=500&q=80',
    'طاولة': 'https://images.unsplash.com/photo-1577140917170-285929fb55b7?auto=format&fit=crop&w=500&q=80',
    'دولاب': 'https://images.unsplash.com/photo-1595428774223-ef52624120d2?auto=format&fit=crop&w=500&q=80',
    
    // Personal Stuff
    'ملابس': 'https://images.unsplash.com/photo-1523381210434-271e8be1f52b?auto=format&fit=crop&w=500&q=80',
    'ساعة': 'https://images.unsplash.com/photo-1524592094714-0f0654e20314?auto=format&fit=crop&w=500&q=80',
    'فستان': 'https://images.unsplash.com/photo-1515372039744-b8f02a3a4462?auto=format&fit=crop&w=500&q=80',
    'حذاء': 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=500&q=80',
    
    // Animals
    'قطة': 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?auto=format&fit=crop&w=500&q=80',
    'كلب': 'https://images.unsplash.com/photo-1543466835-00a7907e9de1?auto=format&fit=crop&w=500&q=80',
    'طير': 'https://images.unsplash.com/photo-1522926193341-e9ffd686c60f?auto=format&fit=crop&w=500&q=80',
    'غنم': 'https://images.unsplash.com/photo-1484557985045-edf25e08da73?auto=format&fit=crop&w=500&q=80',
    
    // Jobs & Services
    'وظيفة': 'https://images.unsplash.com/photo-1486312338219-ce68d2c6f44d?auto=format&fit=crop&w=500&q=80',
    'خدمة': 'https://images.unsplash.com/photo-1581094794329-cd1096a78438?auto=format&fit=crop&w=500&q=80',

    // Tools & Equipment
    'معدات': 'https://plus.unsplash.com/premium_photo-1663090072552-46099749ab96?q=80&w=836&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
    'ادوات': 'https://plus.unsplash.com/premium_photo-1663090072552-46099749ab96?q=80&w=836&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
    'أدوات': 'https://plus.unsplash.com/premium_photo-1663090072552-46099749ab96?q=80&w=836&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
    'اطفال': 'https://img.freepik.com/free-vector/cartoon-girl-birthday-objects-collection_52683-66244.jpg?t=st=1769575290~exp=1769578890~hmac=8111646279d45dbd967147f5c8a1ad7fa0dadff2228def1c674afe4b09549495',
    'أطفال': 'https://img.freepik.com/free-vector/cartoon-girl-birthday-objects-collection_52683-66244.jpg?t=st=1769575290~exp=1769578890~hmac=8111646279d45dbd967147f5c8a1ad7fa0dadff2228def1c674afe4b09549495',
    'صناعة': 'https://images.unsplash.com/photo-1504917595217-d4dc5ebe6122?auto=format&fit=crop&w=500&q=80',

    // Baby & Kids
    'اطفال': 'https://plus.unsplash.com/premium_photo-1663954644290-349f997931b7?auto=format&fit=crop&w=500&q=80',
    'أطفال': 'https://plus.unsplash.com/premium_photo-1663954644290-349f997931b7?auto=format&fit=crop&w=500&q=80',
    'مستلزمات الأطفال': 'https://images.unsplash.com/photo-1515488042361-ee00e0ddd4e4?auto=format&fit=crop&w=500&q=80',
    'مستلزمات اطفال': 'https://images.unsplash.com/photo-1515488042361-ee00e0ddd4e4?auto=format&fit=crop&w=500&q=80',
    'رضيع': 'https://images.unsplash.com/photo-1555252333-9f8e92e65df9?auto=format&fit=crop&w=500&q=80',
    'العاب': 'https://images.unsplash.com/photo-1566576912902-1d6db6b769bd?auto=format&fit=crop&w=500&q=80',
  };

  String? _getImageForCategory(Map<String, dynamic> category) {
    
    // 1. Try explicit icon mapping
    if (category['icon'] != null && _imageMap.containsKey(category['icon'])) {
      return _imageMap[category['icon']];
    }

    // 2. Try smart keyword matching on title
    final title = (category['title'] as String? ?? '').toLowerCase();
    for (final entry in _keywordImageMap.entries) {
      if (title.contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }

    // 3. Try to inherit from parent if possible (not implemented here, but good idea)
    
    return null; // Fallback to icon
  }

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    await context.read<AdProvider>().fetchCategories();
    if (mounted) {
      setState(() {
        _categories = context.read<AdProvider>().categories;
        _currentCategories = _categories;
        _isLoading = false;
      });
    }
  }

  void _navigateToChildren(Map<String, dynamic> category) {
    if (category['children'] != null && (category['children'] as List).isNotEmpty) {
      setState(() {
        _navigationStack.add({
          'category': category,
          'categories': _currentCategories,
        });
        _currentCategories = category['children'];
      });
    } else {
      // Leaf category - select and navigate to ads
      widget.onCategorySelected(category['id'].toString());
    }
  }

  void _navigateBack() {
    if (_navigationStack.isNotEmpty) {
      setState(() {
        final previous = _navigationStack.removeLast();
        _currentCategories = previous['categories'];
      });
    }
  }

  String _getBreadcrumb() {
    if (_navigationStack.isEmpty) return 'الأقسام';
    return _navigationStack.map((item) => item['category']['title']).join(' > ');
  }

  Color _parseColor(String? colorHex) {
    if (colorHex == null) return const Color(0xFF64748B);
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: _navigationStack.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: Theme.of(context).textTheme.titleLarge?.color),
                onPressed: _navigateBack,
              )
            : null,
        title: Text(
          _getBreadcrumb(),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontFamily: 'Cairo',
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        bottom: false,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A6DFF)),
                ),
              )
            : _currentCategories.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[900] : const Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.category_outlined,
                            size: 48,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'لا توجد تصنيفات',
                          style: TextStyle(
                            fontSize: 18,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                            fontFamily: 'NotoSansArabic',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: _loadCategories,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('تحديث القائمة'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A6DFF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                      ],
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      int crossAxisCount = constraints.maxWidth > 1200 ? 4 : (constraints.maxWidth > 600 ? 3 : 2);
                      final maxWidth = constraints.maxWidth > 1200 ? 1000.0 : double.infinity;

                      return Center(
                        child: Container(
                          constraints: BoxConstraints(maxWidth: maxWidth),
                          child: GridView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120), // ✅ زيادة المسافة السفلية للزر العائم
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16, // ✅ موازنة المسافات بين الأعمدة
                              childAspectRatio: 0.82, // ✅ تعديل التناسب لتحسين المظهر
                            ),
                            itemCount: _currentCategories.length,
                            itemBuilder: (context, index) {
                              final category = _currentCategories[index];
                              final hasChildren = category['children'] != null && (category['children'] as List).isNotEmpty;
                              final categoryColor = _parseColor(category['color']);
                              final imageUrl = _getImageForCategory(category);
                              
                              return Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: Stack(
                                    children: [
                                      // 1. Image or Color Background
                                      if (imageUrl != null)
                                        Positioned.fill(
                                          child: Image.network(
                                            imageUrl,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return Container(
                                                color: categoryColor.withOpacity(0.1),
                                                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                              );
                                            },
                                            errorBuilder: (context, error, stackTrace) => Container(
                                              color: categoryColor.withOpacity(0.1),
                                              child: Icon(Icons.image_not_supported_rounded, color: categoryColor),
                                            ),
                                          ),
                                        )
                                      else
                                        Positioned.fill(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  categoryColor.withOpacity(0.15),
                                                  categoryColor.withOpacity(0.05),
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                            ),
                                          ),
                                        ),

                                      // 2. Overlay for Text Contrast ✅ (تراكب أسود خفيف للقراءة)
                                      if (imageUrl != null)
                                        Positioned.fill(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.black.withOpacity(0.85),
                                                  Colors.black.withOpacity(0.3),
                                                  Colors.transparent,
                                                ],
                                                begin: Alignment.bottomCenter,
                                                end: Alignment.center,
                                              ),
                                            ),
                                          ),
                                        ),

                                      // 3. Content
                                      Positioned.fill(
                                        child: Column(
                                          mainAxisAlignment: imageUrl != null ? MainAxisAlignment.end : MainAxisAlignment.center,
                                          children: [
                                            if (imageUrl == null)
                                              Container(
                                                padding: const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  color: categoryColor.withOpacity(0.15),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  hasChildren ? Icons.folder_rounded : Icons.label_rounded,
                                                  size: 32,
                                                  color: categoryColor,
                                                ),
                                              ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                              child: Text(
                                                category['title'] ?? '',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w900,
                                                  color: imageUrl != null ? Colors.white : Theme.of(context).textTheme.titleLarge?.color,
                                                  fontFamily: 'Cairo',
                                                  height: 1.1,
                                                  shadows: imageUrl != null ? [
                                                    Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 4, offset: const Offset(0, 2))
                                                  ] : null,
                                                ),
                                                textAlign: TextAlign.center,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // 4. Interaction Overlay ✅ (ضمان ظهور الـ Ripple)
                                      Positioned.fill(
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () => _navigateToChildren(category),
                                            splashColor: Colors.white.withOpacity(0.2),
                                            highlightColor: Colors.white.withOpacity(0.1),
                                          ),
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
                  ),
      ),
    );
  }
}

