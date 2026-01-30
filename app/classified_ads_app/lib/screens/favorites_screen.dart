import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import '../widgets/guest_placeholder.dart';
import '../providers/favorites_provider.dart';
import '../providers/ad_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import 'package:classified_ads_app/utils/app_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;
  
  bool _isLoading = true;
  bool _showGrid = true;
  String _searchQuery = '';
  String _filterCategory = 'all';
  String _sortBy = 'newest';

  final List<Map<String, dynamic>> _categories = [
    {'id': 'all', 'name': 'الكل', 'icon': Icons.all_inclusive_rounded, 'color': Colors.blue},
    {'id': 'cars', 'name': '🚗 سيارات', 'icon': Icons.directions_car_rounded, 'color': Colors.blue},
    {'id': 'real_estate', 'name': '🏠 عقارات', 'icon': Icons.home_work_rounded, 'color': Colors.green},
    {'id': 'electronics', 'name': '📱 أجهزة', 'icon': Icons.phone_iphone_rounded, 'color': Colors.orange},
    {'id': 'furniture', 'name': '🛋 أثاث', 'icon': Icons.chair_rounded, 'color': Colors.purple},
    {'id': 'other', 'name': '📦 أخرى', 'icon': Icons.category_rounded, 'color': Colors.grey},
  ];

  @override
  void initState() {
    super.initState();
    
    // Fetch favorites
    Future.microtask(() {
       if (mounted) {
         context.read<FavoritesProvider>().fetchFavorites();
       }
    });
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
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
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _removeFavorite(int id) {
    context.read<FavoritesProvider>().toggleFavorite(id.toString());
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.favorite_border_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              'تم إزالة الإعلان من المفضلة',
              style: TextStyle(
                fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade500,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'تراجع',
          textColor: Colors.white,
          onPressed: () {
            // In real app, you would restore the favorite
          },
        ),
      ),
    );
  }

  void _clearAllFavorites(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'سيتم تنفيذ مسح الكل قريباً',
          style: TextStyle(
            fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
          ),
        ),
      ),
    );
  }

  List<dynamic> _getFilteredFavorites(List<dynamic> favorites) {
    var filtered = List<dynamic>.from(favorites);

    // Filter by category
    if (_filterCategory != 'all') {
      filtered = filtered.where((fav) {
        final category = fav['category'].toLowerCase();
        switch (_filterCategory) {
          case 'cars':
            return category.contains('سيار');
          case 'real_estate':
            return category.contains('عقار');
          case 'electronics':
            return category.contains('جهاز');
          case 'furniture':
            return category.contains('أثاث');
          case 'other':
            return true;
          default:
            return true;
        }
      }).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((fav) {
        final title = fav['title'].toString().toLowerCase();
        final description = fav['description']?.toString().toLowerCase() ?? '';
        final location = fav['location'].toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        
        return title.contains(query) || 
               description.contains(query) || 
               location.contains(query);
      }).toList();
    }

    // Sort by selected option
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'newest':
          return (b['created_at'] as String).compareTo(a['created_at'] as String);
        case 'oldest':
          return (a['created_at'] as String).compareTo(b['created_at'] as String);
        case 'price_low':
          return (int.parse(a['price'])).compareTo(int.parse(b['price']));
        case 'price_high':
          return (int.parse(b['price'])).compareTo(int.parse(a['price']));
        case 'featured':
          if (a['isFeatured'] && !b['isFeatured']) return -1;
          if (!a['isFeatured'] && b['isFeatured']) return 1;
          return 0;
        default:
          return 0;
      }
    });

    return filtered;
  }

  Widget _buildShimmerGrid() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16,
                        width: double.infinity,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: 120,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 32,
                        width: double.infinity,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16,
                        width: double.infinity,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 14,
                        width: 100,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: 80,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    if (authProvider.currentUser == UserType.guest) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
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
          message: 'يجب عليك تسجيل الدخول لعرض الإعلانات المفضلة لديك',
          icon: Icons.favorite_border_rounded,
        ),
      );
    }
    
    final favoritesProvider = context.watch<FavoritesProvider>();
    final favorites = favoritesProvider.favorites;
    final filteredFavorites = _getFilteredFavorites(favorites);
    _isLoading = favoritesProvider.isLoading;
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 100),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: child,
            ),
          ),
        );
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 160,
              pinned: true,
              floating: true,
              backgroundColor: Theme.of(context).cardColor,
              surfaceTintColor: Theme.of(context).cardColor,
              elevation: 0,
              leading: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor.withAlpha(230),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(26),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor.withAlpha(230),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(26),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(_showGrid ? Icons.list_rounded : Icons.grid_view_rounded),
                    onPressed: () {
                      setState(() {
                        _showGrid = !_showGrid;
                      });
                    },
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.pink.shade400,
                        Colors.pink.shade600,
                        Colors.pink.shade800,
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'المفضلة',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                            fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${favoritesProvider.favorites.length} إعلان محفوظ',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white.withAlpha(230),
                            fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(13),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    style: const TextStyle(
                      fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                    ),
                    decoration: InputDecoration(
                      hintText: '🔍 ابحث في المفضلة...',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 15,
                        fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      prefixIcon: Container(
                        padding: const EdgeInsets.all(12),
                        child: SvgPicture.asset(
                          AppIcons.search,
                          colorFilter: const ColorFilter.mode(Colors.pink, BlendMode.srcIn),
                        ),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: SvgPicture.asset(AppIcons.close, colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn)),
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
            
            // Category Chips
            SliverToBoxAdapter(
              child: SizedBox(
                height: 70,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = _filterCategory == category['id'];
                    
                    return Padding(
                      padding: EdgeInsets.only(
                        left: index == 0 ? 0 : 8,
                        right: index == _categories.length - 1 ? 16 : 0,
                      ),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _filterCategory = category['id'];
                          });
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(
                                    colors: [
                                      Colors.pink.shade400,
                                      Colors.pink.shade600,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: isSelected ? null : (Theme.of(context).brightness == Brightness.dark ? Colors.grey[900] : Colors.grey.shade100),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.pink.shade300.withAlpha(77),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : null,
                            border: isSelected ? null : Border.all(color: Theme.of(context).dividerColor, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                category['icon'],
                                size: 18,
                                color: isSelected ? Colors.white : Colors.grey.shade700,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                category['name'],
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : Colors.grey.shade700,
                                  fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            
            // Sort Options
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.sort_rounded, size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'ترتيب حسب:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).dividerColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(8),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _sortBy,
                          icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.grey),
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                          ),
                          borderRadius: BorderRadius.circular(12),
                          onChanged: (value) {
                            setState(() {
                              _sortBy = value!;
                            });
                          },
                          items: [
                            DropdownMenuItem(
                              value: 'newest',
                              child: Row(
                                children: [
                                  const Icon(Icons.new_releases_rounded, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    'الأحدث',
                                    style: TextStyle(
                                      fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'oldest',
                              child: Row(
                                children: [
                                  const Icon(Icons.history_rounded, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    'الأقدم',
                                    style: TextStyle(
                                      fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'price_low',
                              child: Row(
                                children: [
                                  const Icon(Icons.arrow_upward_rounded, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    'السعر من الأقل',
                                    style: TextStyle(
                                      fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'price_high',
                              child: Row(
                                children: [
                                  const Icon(Icons.arrow_downward_rounded, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    'السعر من الأعلى',
                                    style: TextStyle(
                                      fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'featured',
                              child: Row(
                                children: [
                                  const Icon(Icons.star_rounded, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    'المميز أولاً',
                                    style: TextStyle(
                                      fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (favoritesProvider.favorites.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.delete_sweep_rounded, color: Colors.red),
                        onPressed: () => _clearAllFavorites(context),
                        tooltip: 'مسح الكل',
                      ),
                  ],
                ),
              ),
            ),
            
            // Favorites List/Grid
            if (_isLoading)
              SliverFillRemaining(
                child: _showGrid ? _buildShimmerGrid() : _buildShimmerList(),
              )
            else if (filteredFavorites.isEmpty)
              SliverFillRemaining(
                child: _buildEmptyState(),
              )
            else if (_showGrid)
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final favorite = filteredFavorites[index];
                      return _buildFavoriteGridCard(favorite);
                    },
                    childCount: filteredFavorites.length,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final favorite = filteredFavorites[index];
                      return _buildFavoriteListCard(favorite);
                    },
                    childCount: filteredFavorites.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteGridCard(Map<String, dynamic> favorite) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to ad details
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(13),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  Container(
                    height: 140,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      image: DecorationImage(
                        image: NetworkImage(
                          favorite['main_image'] != null && favorite['main_image']['image_url'] != null
                              ? favorite['main_image']['image_url']
                              : 'https://via.placeholder.com/150',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Gradient overlay
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withAlpha(77),
                                Colors.transparent,
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        // Status badge
                        if (favorite['status'] == 'sold')
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.shade500,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(51),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Text(
                                'مباع',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                                ),
                              ),
                            ),
                          ),
                        // Featured badge
                        if (favorite['isFeatured'])
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade500,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(51),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_rounded, size: 12, color: Colors.white),
                                  const SizedBox(width: 2),
                                  Text(
                                    'مميز',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Details
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          favorite['title'],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).textTheme.titleLarge?.color,
                            height: 1.3,
                            fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 12,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                favorite['location'],
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                  fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF8B5CF6),
                                Color(0xFF4F46E5),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${favorite['price']} ${favorite['currency']}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Favorite Button
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(26),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.favorite_rounded,
                      color: Colors.pink,
                      size: 20,
                    ),
                    onPressed: () => _removeFavorite(favorite['id']),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFavoriteListCard(Map<String, dynamic> favorite) {
    final formattedDate = DateFormat('dd MMMM', 'ar').format(
      DateTime.parse(favorite['created_at']),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to ad details
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(13),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Image
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        image: DecorationImage(
                          image: NetworkImage(
                            favorite['main_image'] != null && favorite['main_image']['image_url'] != null
                                ? favorite['main_image']['image_url']
                                : 'https://via.placeholder.com/150',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Status overlay
                          if (favorite['status'] == 'sold')
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.red.withAlpha(179),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text(
                                  'مباع',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  favorite['title'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context).textTheme.titleLarge?.color,
                                    fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (favorite['isFeatured'])
                                const Icon(
                                  Icons.star_rounded,
                                  size: 16,
                                  color: Colors.amber,
                                ),
                            ],
                          ),
                          
                          const SizedBox(height: 8),
                          
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: 14,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  favorite['location'],
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                    fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 8),
                          
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF8B5CF6),
                                      Color(0xFF4F46E5),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF8B5CF6).withAlpha(77),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  '${favorite['price']} ${favorite['currency']}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                                  ),
                                ),
                              ),
                              
                              const Spacer(),
                              
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  formattedDate,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                                  ),
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
              
              // Favorite Button
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(26),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.favorite_rounded,
                      color: Colors.pink,
                      size: 20,
                    ),
                    onPressed: () => _removeFavorite(favorite['id']),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: Colors.pink.shade100,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.pink.withAlpha(51),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.favorite_border_rounded,
              size: 70,
              color: Colors.pink,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'قائمة المفضلة فارغة',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF1A237E),
              fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'يمكنك حفظ الإعلانات التي تعجبك\nبالضغط على زر القلب في أي إعلان',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.5,
                fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
              ),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.pink.shade400,
                  Colors.pink.shade600,
                  Colors.pink.shade800,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.pink.shade400.withAlpha(102),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  context.read<AdProvider>().setCategory(null);
                  Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 40),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.explore_rounded, color: Colors.white, size: 22),
                      const SizedBox(width: 12),
                      Text(
                        'تصفح الإعلانات',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                        ),
                      ),
                    ],
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
}