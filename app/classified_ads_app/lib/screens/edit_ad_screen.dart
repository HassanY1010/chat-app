import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/ad_provider.dart';
import '../utils/constants.dart';
import 'create_ad_screen.dart'; // For CategorySelectionSheet

class EditAdScreen extends StatefulWidget {
  final Map<String, dynamic> ad;
  const EditAdScreen({super.key, required this.ad});

  @override
  State<EditAdScreen> createState() => _EditAdScreenState();
}

class _EditAdScreenState extends State<EditAdScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();
  
  final ImagePicker _picker = ImagePicker();
  final List<String> _existingImages = [];
  final List<XFile> _newImages = [];
  final List<String> _removedImages = [];
  
  String? _selectedCategory;
  String? _selectedCondition;
  bool _isNegotiable = false;
  bool _isFeatured = false;
  bool _hasChanges = false;
  
  // Dynamic categories from API
  List<dynamic> _apiCategories = [];
  Map<String, dynamic>? _selectedCategoryObject;
  
  // Icon mapping
  final Map<String, IconData> _iconMap = {
    'directions_car_rounded': Icons.directions_car_rounded,
    'home_work_rounded': Icons.home_work_rounded,
    'devices_other_rounded': Icons.devices_other_rounded,
    'chair_rounded': Icons.chair_rounded,
    'checkroom_rounded': Icons.checkroom_rounded,
    'kitchen_rounded': Icons.kitchen_rounded,
    'pets_rounded': Icons.pets_rounded,
    'sports_esports_rounded': Icons.sports_esports_rounded,
    'construction_rounded': Icons.construction_rounded,
    'brush_rounded': Icons.brush_rounded,
    'child_care_rounded': Icons.child_care_rounded,
    'menu_book_rounded': Icons.menu_book_rounded,
  };
  
  final List<Map<String, String>> _conditions = [
    {'value': 'new', 'label': '🆕 جديد'},
    {'value': 'used', 'label': '🔄 مستعمل'},
    {'value': 'refurbished', 'label': '🔧 مجدد'},
  ];

  @override
  void initState() {
    super.initState();
    
    // Load existing ad data
    _titleController.text = widget.ad['title'] ?? '';
    _descController.text = widget.ad['description'] ?? '';
    _priceController.text = widget.ad['price']?.toString() ?? '';
    _locationController.text = widget.ad['location'] ?? '';
    _phoneController.text = widget.ad['contact_phone'] ?? '';
    _selectedCategory = widget.ad['category_id']?.toString();
    _selectedCondition = widget.ad['condition'] ?? 'used';
    _isNegotiable = widget.ad['is_negotiable'] ?? false;
    _isFeatured = widget.ad['is_featured'] ?? false;
    
    // Load existing images
    if (widget.ad['main_image'] != null) {
      _existingImages.add(widget.ad['main_image']['image_path']);
    }
    if (widget.ad['images'] != null && widget.ad['images'] is List) {
      for (var image in widget.ad['images']) {
        if (image['image_path'] != null && 
            !_existingImages.contains(image['image_path'])) {
          _existingImages.add(image['image_path']);
        }
      }
    }
    
    // Listen for changes
    _titleController.addListener(_checkForChanges);
    _descController.addListener(_checkForChanges);
    _priceController.addListener(_checkForChanges);
    _locationController.addListener(_checkForChanges);
    _phoneController.addListener(_checkForChanges);
    
    // Load categories
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategories();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  int get totalImages => _existingImages.length + _newImages.length;

  void _checkForChanges() {
    final hasTextChanges = 
        _titleController.text != (widget.ad['title'] ?? '') ||
        _descController.text != (widget.ad['description'] ?? '') ||
        _priceController.text != (widget.ad['price']?.toString() ?? '') ||
        _locationController.text != (widget.ad['location'] ?? '') ||
        _phoneController.text != (widget.ad['contact_phone'] ?? '');
    
    final hasSelectionChanges = 
        _selectedCategory != widget.ad['category_id']?.toString() ||
        _selectedCondition != widget.ad['condition'] ||
        _isNegotiable != (widget.ad['is_negotiable'] ?? false) ||
        _isFeatured != (widget.ad['is_featured'] ?? false);
    
    final hasImageChanges = 
        _newImages.isNotEmpty || _removedImages.isNotEmpty;
    
    setState(() {
      _hasChanges = hasTextChanges || hasSelectionChanges || hasImageChanges;
    });
  }

  Future<void> _pickImages() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage(
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _newImages.addAll(pickedFiles);
        _checkForChanges();
      });
    }
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
      _checkForChanges();
    });
  }

  void _removeExistingImage(String imageUrl) {
    setState(() {
      _existingImages.remove(imageUrl);
      _removedImages.add(imageUrl);
      _checkForChanges();
    });
  }

  void _restoreExistingImage(String imageUrl) {
    setState(() {
      _removedImages.remove(imageUrl);
      _existingImages.add(imageUrl);
      _checkForChanges();
    });
  }

  Future<void> _loadCategories() async {
    await context.read<AdProvider>().fetchCategories();
    if (mounted) {
      setState(() {
        _apiCategories = context.read<AdProvider>().categories;
      });
    }
  }

  void _showCategorySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CategorySelectionSheet(
        categories: _apiCategories,
        onSelect: (category) {
          setState(() {
            _selectedCategory = category['id'].toString();
            _selectedCategoryObject = category;
            _checkForChanges();
          });
        },
      ),
    );
  }

  Widget _buildCategorySelector() {
    return InkWell(
      onTap: _showCategorySheet,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[900] : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800]! : Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(
              _selectedCategoryObject != null 
                  ? (_iconMap[_selectedCategoryObject!['icon']] ?? Icons.category_rounded)
                  : Icons.category_outlined,
              color: const Color(0xFF1A237E),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedCategoryObject != null 
                    ? _selectedCategoryObject!['title'] 
                    : 'اختر القسم',
                style: TextStyle(
                  fontSize: 16,
                  color: _selectedCategoryObject != null 
                      ? Theme.of(context).textTheme.bodyLarge?.color 
                      : Theme.of(context).hintColor,
                  fontFamily: 'NotoSansArabic',
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_existingImages.isEmpty && _newImages.isEmpty) {
        _showSnackBar('الرجاء إضافة صورة واحدة على الأقل', isError: true);
        return;
      }

      try {
        final adProvider = context.read<AdProvider>();
        
        // Upload new images
        final List<String> uploadedImageUrls = [];
        for (var image in _newImages) {
          final path = await adProvider.uploadImage(image);
          if (path != null) {
            uploadedImageUrls.add(path);
          }
        }

        // Combine existing (not removed) and new images
        final allImages = [
          ..._existingImages,
          ...uploadedImageUrls,
        ];

        if (allImages.isEmpty) {
          throw Exception('يجب أن يحتوي الإعلان على صورة واحدة على الأقل');
        }

        final adData = {
          'category_id': _selectedCategory,
          'title': _titleController.text,
          'description': _descController.text,
          'price': _priceController.text,
          'location': _locationController.text,
          'contact_phone': _phoneController.text.isNotEmpty ? _phoneController.text : null,
          'condition': _selectedCondition,
          'is_negotiable': _isNegotiable,
          'is_featured': _isFeatured,
          'images': allImages,
          'removed_images': _removedImages,
        };

        await adProvider.updateAd(widget.ad['id'].toString(), adData);
        if (!mounted) return;
        
        // Show success dialog
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => _buildSuccessDialog(),
        );
        
        if (mounted) Navigator.pop(context);
        
      } catch (e) {
        if (!mounted) return;
        _showSnackBar('فشل تحديث الإعلان: $e', isError: true);
      }
    }
  }

  Widget _buildSuccessDialog() {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(32),
      ),
      backgroundColor: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withAlpha(102),
                    blurRadius: 15,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '🎉 تم تحديث الإعلان بنجاح!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).textTheme.titleLarge?.color,
                fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'تم حفظ جميع التعديلات على إعلانك',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                height: 1.5,
                fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
              ),
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF4F46E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withAlpha(102),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
                    child: Text(
                      'متابعة',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
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

  Future<bool> _showExitConfirmation() async {
    if (!_hasChanges) return true;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Theme.of(context).cardColor,
        surfaceTintColor: Theme.of(context).cardColor,
        title: Text(
          'هل تريد الخروج؟',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
          ),
        ),
        content: Text(
          'لديك تغييرات غير محفوظة، إذا خرجت الآن سيتم فقدان جميع التغييرات.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
            fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    'البقاء',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.red.shade500,
                        Colors.red.shade700,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.shade300.withAlpha(102),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.pop(context, true),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Center(
                          child: Text(
                            'خروج',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
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
        ],
      ),
    );
    
    return result ?? false;
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade500 : Colors.green.shade500,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final canExit = await _showExitConfirmation();
        if (canExit && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text(
            'تعديل الإعلان',
            style: TextStyle(
              fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
            ),
          ),
          centerTitle: true,
          backgroundColor: Theme.of(context).cardColor,
          elevation: 0,
          surfaceTintColor: Theme.of(context).cardColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () async {
              final canExit = await _showExitConfirmation();
              if (canExit && context.mounted) Navigator.pop(context);
            },
          ),
          actions: [
            if (_hasChanges)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            // Changes Indicator
            if (_hasChanges)
              Container(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.amber.withAlpha(50) : Colors.amber.shade50,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.info_rounded, size: 16, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'يوجد تغييرات غير محفوظة',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.amber,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _submit,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                      ),
                      child: Text(
                        'حفظ الآن',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Images Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(13),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.photo_library_rounded, color: Color(0xFF00B0FF), size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'صور الإعلان',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context).textTheme.titleLarge?.color,
                                    fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'الصور المتوفرة ($totalImages/10)',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Images Grid
                            if (totalImages == 0)
                              GestureDetector(
                                onTap: _pickImages,
                                child: Container(
                                  height: 150,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                      style: BorderStyle.solid,
                                      width: 2,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.add_photo_alternate_rounded, size: 50, color: Colors.grey),
                                      const SizedBox(height: 8),
                                      Text(
                                        'إضافة صور',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                                        ),
                                      ),
                                      Text(
                                        'انقر لإضافة صور جديدة',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey,
                                          fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              Column(
                                children: [
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      mainAxisSpacing: 8,
                                      crossAxisSpacing: 8,
                                      childAspectRatio: 1,
                                    ),
                                    itemCount: totalImages + (totalImages < 10 ? 1 : 0),
                                    itemBuilder: (context, index) {
                                      if (index < _existingImages.length) {
                                        final imageUrl = _existingImages[index];
                                        final isRemoved = _removedImages.contains(imageUrl);
                                        
                                        return Stack(
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(12),
                                                color: Colors.grey.shade200,
                                                image: DecorationImage(
                                                  image: NetworkImage(
                                                    imageUrl.startsWith('http') 
                                                      ? imageUrl 
                                                      : '${AppConstants.assetBaseUrl}/$imageUrl'
                                                  ),
                                                  fit: BoxFit.cover,
                                                  colorFilter: isRemoved
                                                      ? ColorFilter.mode(
                                                          Colors.black.withAlpha(128),
                                                          BlendMode.darken,
                                                        )
                                                      : null,
                                                ),
                                              ),
                                            ),
                                            if (isRemoved)
                                              Positioned.fill(
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.black.withAlpha(128),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Center(
                                                    child: IconButton(
                                                      icon: const Icon(Icons.restore_rounded, color: Colors.white),
                                                      onPressed: () => _restoreExistingImage(imageUrl),
                                                    ),
                                                  ),
                                                ),
                                              )
                                            else
                                              Positioned(
                                                top: 4,
                                                right: 4,
                                                child: GestureDetector(
                                                  onTap: () => _removeExistingImage(imageUrl),
                                                  child: Container(
                                                    padding: const EdgeInsets.all(4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.red,
                                                      shape: BoxShape.circle,
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black.withAlpha(51),
                                                          blurRadius: 4,
                                                        ),
                                                      ],
                                                    ),
                                                    child: const Icon(
                                                      Icons.close_rounded,
                                                      size: 16,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        );
                                      } else if (index < totalImages) {
                                        final newIndex = index - _existingImages.length;
                                        return Stack(
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(12),
                                                image: DecorationImage(
                                                  image: kIsWeb 
                                                      ? NetworkImage(_newImages[newIndex].path)
                                                      : FileImage(File(_newImages[newIndex].path)) as ImageProvider,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              top: 4,
                                              right: 4,
                                              child: GestureDetector(
                                                onTap: () => _removeNewImage(newIndex),
                                                child: Container(
                                                  padding: const EdgeInsets.all(4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red,
                                                    shape: BoxShape.circle,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black.withAlpha(51),
                                                        blurRadius: 4,
                                                      ),
                                                    ],
                                                  ),
                                                  child: const Icon(
                                                    Icons.close_rounded,
                                                    size: 16,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              bottom: 4,
                                              left: 4,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.green,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  'جديد',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w700,
                                                    fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      } else {
                                        return GestureDetector(
                                          onTap: _pickImages,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[900] : Colors.grey.shade100,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.grey.shade300,
                                                style: BorderStyle.solid,
                                              ),
                                            ),
                                            child: const Center(
                                              child: Icon(
                                                Icons.add_rounded,
                                                size: 30,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'الصور الملونة بالرمادي سيتم حذفها. الصور الجديدة مميزة باللون الأخضر.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                      fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Title Field
                      _buildSection(
                        title: 'عنوان الإعلان',
                        icon: Icons.title_rounded,
                        child: TextFormField(
                          controller: _titleController,
                          maxLength: 100,
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                          ),
                          decoration: InputDecoration(
                            hintText: 'مثال: سيارة تويوتا كامري 2022 نظيفة جداً',
                            hintStyle: const TextStyle(
                              fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2C2C2C) : Colors.grey.shade100,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          validator: (v) {
                            if (v!.isEmpty) return 'عنوان الإعلان مطلوب';
                            if (v.length < 10) return 'العنوان قصير جداً';
                            return null;
                          },
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Category Selection
                      _buildSection(
                        title: 'اختر القسم',
                        icon: Icons.category_rounded,
                        child: _buildCategorySelector(),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Price & Condition
                      Row(
                        children: [
                          Expanded(
                            child: _buildSection(
                              title: 'السعر',
                              icon: Icons.attach_money_rounded,
                              child: TextFormField(
                                controller: _priceController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                                ),
                                decoration: InputDecoration(
                                  hintText: 'مثال: 50000',
                                  hintStyle: const TextStyle(
                                    fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                                  ),
                                  prefixText: '﷼ ',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2C2C2C) : Colors.grey.shade100,
                                  contentPadding: const EdgeInsets.all(16),
                                ),
                                validator: (v) => v!.isEmpty ? 'السعر مطلوب' : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSection(
                              title: 'الحالة',
                              icon: Icons.verified_rounded,
                              child: DropdownButtonFormField<String>(
                                initialValue: _selectedCondition,
                                style: const TextStyle(
                                  fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                                ),
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade100,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                                items: _conditions.map((condition) {
                                  return DropdownMenuItem(
                                    value: condition['value'],
                                    child: Text(
                                      condition['label']!,
                                      style: const TextStyle(
                                        fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedCondition = value;
                                    _checkForChanges();
                                  });
                                },
                                validator: (v) => v == null ? 'الحالة مطلوبة' : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Location Field
                      _buildSection(
                        title: 'الموقع',
                        icon: Icons.location_on_rounded,
                        child: TextFormField(
                          controller: _locationController,
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                          ),
                          decoration: InputDecoration(
                            hintText: 'مثال: الرياض، حي العليا',
                            hintStyle: const TextStyle(
                              fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2C2C2C) : Colors.grey.shade100,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          validator: (v) => v!.isEmpty ? 'الموقع مطلوب' : null,
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Contact Phone
                      _buildSection(
                        title: 'رقم التواصل',
                        icon: Icons.phone_rounded,
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                          ),
                          decoration: InputDecoration(
                            hintText: 'مثال: 0501234567',
                            hintStyle: const TextStyle(
                              fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Additional Options
                      Container(
                        padding: const EdgeInsets.all(20),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'خيارات إضافية',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).textTheme.titleLarge?.color,
                                fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                              ),
                            ),
                            const SizedBox(height: 16),
                            SwitchListTile.adaptive(
                              title: Text(
                                'السعر قابل للتفاوض',
                                style: TextStyle(
                                  fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                                ),
                              ),
                              subtitle: Text(
                                'سيظهر رمز التفاوض في الإعلان',
                                style: TextStyle(
                                  fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                                ),
                              ),
                              value: _isNegotiable,
                              onChanged: (value) {
                                setState(() {
                                  _isNegotiable = value;
                                  _checkForChanges();
                                });
                              },
                              activeTrackColor: const Color(0xFF00B0FF),
                              contentPadding: EdgeInsets.zero,
                            ),
                            const Divider(height: 20),
                            SwitchListTile.adaptive(
                              title: Text(
                                'إعلان مميز',
                                style: TextStyle(
                                  fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                                ),
                              ),
                              subtitle: Text(
                                'سيظهر الإعلان في المقدمة لمدة 7 أيام',
                                style: TextStyle(
                                  fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                                ),
                              ),
                              value: _isFeatured,
                              onChanged: (value) {
                                setState(() {
                                  _isFeatured = value;
                                  _checkForChanges();
                                });
                              },
                              activeTrackColor: const Color(0xFF8B5CF6),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Description Field
                      _buildSection(
                        title: 'وصف الإعلان',
                        icon: Icons.description_rounded,
                        child: TextFormField(
                          controller: _descController,
                          maxLines: 6,
                          maxLength: 1000,
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                          ),
                          decoration: InputDecoration(
                            hintText: 'صف منتجك بالتفصيل...\n• الحالة\n• المواصفات\n• الملحقات\n• سبب البيع',
                            hintStyle: const TextStyle(
                              fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2C2C2C) : Colors.grey.shade100,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          validator: (v) {
                            if (v!.isEmpty) return 'وصف الإعلان مطلوب';
                            if (v.length < 50) return 'الوصف قصير جداً';
                            return null;
                          },
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Submit Button
                      Consumer<AdProvider>(
                        builder: (context, adProvider, _) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: adProvider.isLoading
                                    ? [Colors.grey.shade400, Colors.grey.shade500]
                                    : const [
                                        Color(0xFF00B0FF),
                                        Color(0xFF0091EA),
                                      ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                            ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: adProvider.isLoading
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: const Color(0xFF00B0FF).withAlpha(128),
                                        blurRadius: 16,
                                        offset: const Offset(0, 8),
                                        spreadRadius: -2,
                                      ),
                                      BoxShadow(
                                        color: Colors.black.withAlpha(26),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: adProvider.isLoading ? null : _submit,
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  child: Center(
                                    child: adProvider.isLoading
                                        ? const SizedBox(
                                            width: 26,
                                            height: 26,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 3,
                                              strokeCap: StrokeCap.round,
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                Icons.save_rounded,
                                                color: Colors.white,
                                                size: 24,
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                'حفظ التعديلات',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: 0.5,
                                                  fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF00B0FF), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                  fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}