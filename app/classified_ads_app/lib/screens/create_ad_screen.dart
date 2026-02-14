import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/ad_provider.dart';
import '../widgets/featured_ad_info_dialog.dart';

class CreateAdScreen extends StatefulWidget {
  const CreateAdScreen({super.key});

  @override
  State<CreateAdScreen> createState() => _CreateAdScreenState();
}

class _CreateAdScreenState extends State<CreateAdScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();
  
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _images = [];
  final List<String> _uploadedImageUrls = [];
  bool _isLoading = false;
  bool _isCategoriesLoading = true;
  
  String? _selectedCategory;
  String? _selectedCondition;
  bool _isNegotiable = false;
  bool _allowPhoneCall = false;
  bool _allowWhatsApp = false;
  String _selectedCurrency = 'YER'; // Default to Yemeni Rial
  
  final List<Map<String, String>> _currencies = [
    {'code': 'YER', 'name': 'ريال يمني', 'symbol': '﷼'},
    {'code': 'SAR', 'name': 'ريال سعودي', 'symbol': 'ر.س'},
    {'code': 'USD', 'name': 'دولار', 'symbol': '\$'},
  ];
  
  // Hardcoded categories removed.
  List<dynamic> _apiCategories = [];
  Map<String, dynamic>? _selectedCategoryObject;

  
  final List<Map<String, String>> _conditions = [
    {'value': 'new', 'label': '🆕 جديد'},
    {'value': 'used', 'label': '🔄 مستعمل'},
    {'value': 'refurbished', 'label': '🔧 مجدد'},
  ];

  @override
  void initState() {
    super.initState();
    
    // Fetch categories
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategories();
    });
    
    // Set default condition
    if (_conditions.isNotEmpty) {
      _selectedCondition = _conditions[0]['value'];
    }
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

  Future<void> _loadCategories() async {
    if (mounted) setState(() => _isCategoriesLoading = true);
    await context.read<AdProvider>().fetchCategories();
    if (mounted) {
      setState(() {
        _apiCategories = context.read<AdProvider>().categories;
        _isCategoriesLoading = false;
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
            });
        },
      ),
    );
  }

  Widget _buildCategorySelector() {
      return InkWell(
        onTap: _isCategoriesLoading ? null : _showCategorySheet,
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
              if (_isCategoriesLoading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  _selectedCategoryObject != null 
                      ? (_iconMap[_selectedCategoryObject!['icon']] ?? Icons.category_rounded)
                      : Icons.category_outlined,
                  color: Theme.of(context).primaryColor,
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _isCategoriesLoading
                      ? 'جاري تحميل الأقسام...'
                      : (_selectedCategoryObject != null 
                          ? _selectedCategoryObject!['title'] 
                          : 'اختر القسم'),
                  style: TextStyle(
                    fontSize: 16,
                    color: _selectedCategoryObject != null 
                        ? Theme.of(context).textTheme.bodyLarge?.color 
                        : Theme.of(context).hintColor,
                    fontFamily: 'NotoSansArabic',
                  ),
                ),
              ),
              if (!_isCategoriesLoading)
                const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
            ],
          ),
        ),
      );
  }

  // Map string icon names to IconData
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

  Future<void> _pickImages() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage(
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 75,
    );
    if (pickedFiles.isNotEmpty) {
      if (_images.length + pickedFiles.length > 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الحد الأقصى 10 صور فقط')),
        );
        return;
      }
      setState(() {
        _images.addAll(pickedFiles);
      });
    }
  }

  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 75,
    );
    if (photo != null) {
      if (_images.length >= 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الحد الأقصى 10 صور فقط')),
        );
        return;
      }
      setState(() {
        _images.add(photo);
      });
    }
  }

  Future<void> _showImageSourceDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        backgroundColor: Theme.of(context).cardColor,
        surfaceTintColor: Theme.of(context).cardColor,
        title: Text(
          'إضافة صور',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            const Text(
              'اختر طريقة إضافة الصور',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey,
                fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageSourceButton(
                  icon: Icons.photo_library_rounded,
                  label: 'المعرض',
                  color: const Color(0xFF8B5CF6),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImages();
                  },
                ),
                _buildImageSourceButton(
                  icon: Icons.camera_alt_rounded,
                  label: 'الكاميرا',
                  color: const Color(0xFF10B981),
                  onTap: () {
                    Navigator.pop(context);
                    _takePhoto();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_images.isNotEmpty)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showDeleteAllImagesDialog();
                },
                child: const Text(
                  'حذف جميع الصور',
                  style: TextStyle(
                    color: Colors.red,
                    fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                  ),
                ),
              ),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'إلغاء',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSourceButton({
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
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              shape: BoxShape.circle,
              border: Border.all(color: color.withAlpha(77), width: 2),
            ),
            child: Icon(
              icon,
              size: 32,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
              fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllImagesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Theme.of(context).cardColor,
        surfaceTintColor: Theme.of(context).cardColor,
        title: Text(
          'حذف جميع الصور',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_forever_rounded,
                size: 30,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'هل أنت متأكد من حذف جميع الصور؟',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: const Text(
                    'إلغاء',
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
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _images.clear();
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: const Center(
                          child: Text(
                            'حذف',
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
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_images.isEmpty) {
        _showSnackBar('الرجاء إضافة صورة واحدة على الأقل');
        return;
      }

      if (_selectedCategory == null) {
        _showSnackBar('الرجاء اختيار القسم');
        return;
      }

      try {
        final adProvider = context.read<AdProvider>();
        
        setState(() => _isLoading = true);
        
        // 🚀 Speed Optimization: Parallel Uploads with error handling
        final List<String?> results = await Future.wait(
          _images.map((image) => adProvider.uploadImage(image).catchError((e) {
            debugPrint('Error uploading image: $e');
            return null; // Return null on error to keep other uploads moving
          }))
        );
        
        _uploadedImageUrls.clear();
        for (var path in results) {
          if (path != null) {
            _uploadedImageUrls.add(path);
          }
        }

        if (_uploadedImageUrls.isEmpty) {
          throw Exception('فشل رفع الصور');
        }

        final adData = {
          'category_id': _selectedCategory,
          'title': _titleController.text,
          'description': _descController.text,
          'price': _priceController.text,
          'currency': _selectedCurrency,
          'location': _locationController.text,
          'contact_phone': _allowPhoneCall && _phoneController.text.isNotEmpty ? _phoneController.text : null,
          'contact_whatsapp': _allowWhatsApp && _phoneController.text.isNotEmpty ? _phoneController.text : null,
          'condition': _selectedCondition,
          'is_negotiable': _isNegotiable,
          'images': _uploadedImageUrls,
        };

        await adProvider.createAd(adData);
        
        if (!mounted) return;
        
        // 🏠 Success UI & Navigation
        _showSnackBar('تم إضافة الإعلان بنجاح!', isError: false);
        
        // Return to home (usually index 0)
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
        
      } catch (e) {
        if (!mounted) return;
        _showSnackBar('فشل إنشاء الإعلان: $e', isError: true);
      } finally {
        if (mounted) setState(() => _isLoading = false);
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
              '🎉 تم نشر الإعلان بنجاح!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).textTheme.titleLarge?.color,
                fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'تم نشر إعلانك فوراً\nويمكن للجميع مشاهدته الآن',
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
                  onTap: () {
                    Navigator.pop(context); // Close dialog
                    // Reset form
                    setState(() {
                      _titleController.clear();
                      _descController.clear();
                      _priceController.clear();
                      _locationController.clear();
                      _phoneController.clear();
                      _images.clear();
                      _uploadedImageUrls.clear();
                      _selectedCategory = null;
                      _selectedCategoryObject = null;
                      _selectedCondition = _conditions.isNotEmpty ? _conditions[0]['value'] : null;
                      _isNegotiable = false;
                      _selectedCurrency = 'YER';
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
                    child: const Text(
                      'إضافة إعلان جديد',
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
                style: const TextStyle(fontFamily: 'NotoSansArabic'), // استخدام الخط المحلي
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
    return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        resizeToAvoidBottomInset: true,
        body: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 30),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF00B0FF),
                      Color(0xFF0091EA),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (Navigator.canPop(context))
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(50),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
                        ),
                      ),
                    const SizedBox(height: 20),
                    const Text(
                      'إضافة إعلان جديد',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        fontFamily: 'NotoSansArabic',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'بيع منتجك بسهولة وأمان',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withAlpha(230),
                        fontFamily: 'NotoSansArabic',
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
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
                              'أضف صور واضحة للمنتج (${_images.length}/10)',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                                fontFamily: 'NotoSansArabic', // استخدام الخط المحلي
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Image Grid
                            _images.isEmpty
                                ? GestureDetector(
                                    onTap: _showImageSourceDialog,
                                    child: Container(
                                      height: 150,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[900] : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800]! : Colors.grey.shade300,
                                          style: BorderStyle.solid,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.add_photo_alternate_rounded, size: 50, color: Colors.grey),
                                          SizedBox(height: 8),
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
                                            'انقر لإضافة صور للمنتج',
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
                                : Column(
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
                                        itemCount: _images.length + (_images.length < 10 ? 1 : 0),
                                        itemBuilder: (context, index) {
                                          if (index < _images.length) {
                                            return Stack(
                                              children: [
                                                Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(12),
                                                    image: DecorationImage(
                                                      image: kIsWeb 
                                                          ? NetworkImage(_images[index].path)
                                                          : FileImage(File(_images[index].path)) as ImageProvider,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                                Positioned(
                                                  top: 4,
                                                  right: 4,
                                                  child: GestureDetector(
                                                    onTap: () => _removeImage(index),
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
                                          } else {
                                            return GestureDetector(
                                              onTap: _showImageSourceDialog,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[900] : Colors.grey.shade100,
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800]! : Colors.grey.shade300,
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
                                        'اسحب الصور لترتيبها (الصورة الأولى ستكون الرئيسية)',
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
                            hintStyle: const TextStyle(fontFamily: 'NotoSansArabic'), // استخدام الخط المحلي
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
                      
                      // Price & Currency
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildSection(
                              title: 'السعر',
                              icon: Icons.attach_money_rounded,
                              child: TextFormField(
                                controller: _priceController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Cairo', // استخدام Cairo للأرقام
                                ),
                                decoration: InputDecoration(
                                  hintText: '0.00',
                                  hintStyle: const TextStyle(fontFamily: 'Cairo'), // استخدام Cairo للأرقام
                                  prefixText: '${_currencies.firstWhere((c) => c['code'] == _selectedCurrency)['symbol']} ',
                                  prefixStyle: const TextStyle(fontFamily: 'Cairo'), // استخدام Cairo للأرقام
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2C2C2C) : Colors.grey.shade100,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                ),
                                validator: (v) => v!.isEmpty ? 'السعر مطلوب' : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSection(
                              title: 'العملة',
                              icon: Icons.currency_exchange_rounded,
                              child: DropdownButtonFormField<String>(
                                value: _selectedCurrency,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2C2C2C) : Colors.grey.shade100,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                ),
                                isExpanded: true,
                                items: _currencies.map((currency) {
                                  return DropdownMenuItem(
                                    value: currency['code'],
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        currency['name']!,
                                        style: TextStyle(
                                          fontFamily: 'NotoSansArabic',
                                          fontSize: 14,
                                          color: Theme.of(context).brightness == Brightness.dark 
                                              ? Colors.white 
                                              : Colors.black,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedCurrency = value!;
                                  });
                                },
                                style: TextStyle(
                                  fontFamily: 'NotoSansArabic',
                                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Condition
                      _buildSection(
                        title: 'الحالة',
                        icon: Icons.verified_rounded,
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedCondition,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2C2C2C) : Colors.grey.shade100,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          items: _conditions.map((condition) {
                            return DropdownMenuItem(
                              value: condition['value'],
                              child: Text(
                                condition['label']!,
                                style: TextStyle(
                                  fontFamily: 'NotoSansArabic',
                                  color: Theme.of(context).brightness == Brightness.dark 
                                      ? Colors.white 
                                      : Colors.black,
                                ), // استخدام الخط المحلي
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCondition = value;
                            });
                          },
                          style: TextStyle(
                            fontFamily: 'NotoSansArabic',
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                          ), // استخدام الخط المحلي
                          validator: (v) => v == null ? 'الحالة مطلوبة' : null,
                        ),
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
                            hintStyle: const TextStyle(fontFamily: 'NotoSansArabic'), // استخدام الخط المحلي
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
                      
                      // Contact Phone (Optional)
                      _buildSection(
                        title: 'رقم التواصل (اختياري)',
                        icon: Icons.phone_rounded,
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: 'Cairo', // استخدام Cairo للأرقام
                          ),
                          decoration: InputDecoration(
                            hintText: '',
                            hintStyle: const TextStyle(fontFamily: 'Cairo'), // استخدام Cairo للأرقام
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2C2C2C) : Colors.grey.shade100,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return null; // Optional field
                            }
                            
                            final cleanValue = value.replaceAll(RegExp(r'\s+'), '');
                            
                            if (!RegExp(r'^[0-9]+$').hasMatch(cleanValue)) {
                              return 'يجب أن يحتوي على أرقام فقط';
                            }
                            
                            // Check if it's 9 digits
                            if (cleanValue.length != 9) {
                              return 'رقم الهاتف يجب أن يكون 9 أرقام';
                            }
                            
                            // Check if starts with valid prefix
                            if (!cleanValue.startsWith('7') && !cleanValue.startsWith('5')) {
                              return 'رقم يمني يبدأ بـ 7، رقم سعودي يبدأ بـ 5';
                            }
                            
                            return null;
                          },
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
                              title: const Text(
                                'قابل للتفاوض',
                                style: TextStyle(fontFamily: 'NotoSansArabic'),
                              ),
                              subtitle: const Text(
                                'تفعيل زر قابل للتفاوض في الإعلان',
                                style: TextStyle(fontFamily: 'NotoSansArabic', fontSize: 12),
                              ),
                              value: _isNegotiable,
                              onChanged: (value) {
                                setState(() {
                                  _isNegotiable = value;
                                });
                              },
                              activeTrackColor: const Color(0xFF10B981),
                              contentPadding: EdgeInsets.zero,
                            ),
                            const Divider(),
                            SwitchListTile.adaptive(
                              title: const Text(
                                'تفعيل الاتصال المباشر',
                                style: TextStyle(fontFamily: 'NotoSansArabic'),
                              ),
                              subtitle: const Text(
                                'السماح للمشترين بالاتصال بك هاتفياً',
                                style: TextStyle(fontFamily: 'NotoSansArabic', fontSize: 12),
                              ),
                              value: _allowPhoneCall,
                              onChanged: (value) {
                                setState(() {
                                  _allowPhoneCall = value;
                                });
                              },
                              activeTrackColor: const Color(0xFF10B981),
                              contentPadding: EdgeInsets.zero,
                            ),
                            const Divider(),
                            SwitchListTile.adaptive(
                              title: const Text(
                                'تفعيل الواتساب',
                                style: TextStyle(fontFamily: 'NotoSansArabic'),
                              ),
                              subtitle: const Text(
                                'السماح للمشترين بمراسلتك عبر الواتساب',
                                style: TextStyle(fontFamily: 'NotoSansArabic', fontSize: 12),
                              ),
                              value: _allowWhatsApp,
                              onChanged: (value) {
                                setState(() {
                                  _allowWhatsApp = value;
                                });
                              },
                              activeTrackColor: const Color(0xFF10B981),
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
                            hintStyle: const TextStyle(fontFamily: 'NotoSansArabic'), // استخدام الخط المحلي
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
                      
                      const SizedBox(height: 20),
                      
                      // Featured Ad Info Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFF3E5F5),
                              Color(0xFFE1BEE7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.purple.shade200,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purple.withAlpha(51),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.shade600,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.star_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'اجعل إعلانك مميزاً',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                      fontFamily: 'NotoSansArabic',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: const [
                                      Text(
                                        'السعر:',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                          fontFamily: 'NotoSansArabic',
                                        ),
                                      ),
                                      Text(
                                        '10,000 ريال يمني',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.purple,
                                          fontFamily: 'NotoSansArabic',
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: const [
                                      Text(
                                        'المدة:',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                          fontFamily: 'NotoSansArabic',
                                        ),
                                      ),
                                      Text(
                                        '7 أيام',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                          fontFamily: 'NotoSansArabic',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              '✓ ظهور في أعلى نتائج البحث\n✓ علامة مميزة تجذب المشترين\n✓ زيادة فرص البيع بشكل كبير',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                                height: 1.8,
                                fontFamily: 'NotoSansArabic',
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => const FeaturedAdInfoDialog(),
                                  );
                                },
                                icon: const Icon(Icons.info_outline, size: 20),
                                label: const Text(
                                  'معرفة المزيد',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'NotoSansArabic',
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple.shade600,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
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
                                        Color(0xFF10B981),
                                        Color(0xFF059669),
                                        Color(0xFF047857),
                                      ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: adProvider.isLoading
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: const Color(0xFF10B981).withAlpha(128),
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
                                        : const Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.add_circle_rounded,
                                                color: Colors.white,
                                                size: 24,
                                              ),
                                              SizedBox(width: 12),
                                              Text(
                                                'نشر الإعلان',
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

// Category Selection Sheet Widget
class CategorySelectionSheet extends StatefulWidget {
  final List<dynamic> categories;
  final Function(Map<String, dynamic>) onSelect;

  const CategorySelectionSheet({
    super.key,
    required this.categories,
    required this.onSelect,
  });

  @override
  State<CategorySelectionSheet> createState() => _CategorySelectionSheetState();
}

class _CategorySelectionSheetState extends State<CategorySelectionSheet> {
  final List<Map<String, dynamic>> _navigationStack = [];
  List<dynamic> _currentCategories = [];

  @override
  void initState() {
    super.initState();
    _currentCategories = widget.categories;
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
      // Leaf node - select this category
      widget.onSelect(category);
      Navigator.pop(context);
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
    if (_navigationStack.isEmpty) return 'اختر القسم';
    return _navigationStack.map((item) => item['category']['title']).join(' > ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4A6DFF), Color(0xFF7B9AFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    if (_navigationStack.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                        onPressed: _navigateBack,
                      ),
                    Expanded(
                      child: Text(
                        _getBreadcrumb(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontFamily: 'NotoSansArabic',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Category List
          Expanded(
            child: _currentCategories.isEmpty
                ? const Center(
                    child: Text(
                      'لا توجد تصنيفات',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        fontFamily: 'NotoSansArabic',
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _currentCategories.length,
                    itemBuilder: (context, index) {
                      final category = _currentCategories[index];
                      final hasChildren = category['children'] != null && 
                                        (category['children'] as List).isNotEmpty;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.grey[800]! 
                                : Colors.grey.shade200
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(13),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _navigateToChildren(category),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4A6DFF).withAlpha(26),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      hasChildren 
                                          ? Icons.folder_rounded 
                                          : Icons.label_rounded,
                                      color: const Color(0xFF4A6DFF),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      category['title'] ?? '',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).textTheme.bodyLarge?.color,
                                        fontFamily: 'NotoSansArabic',
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    hasChildren 
                                        ? Icons.arrow_forward_ios_rounded 
                                        : Icons.check_circle_outline_rounded,
                                    size: 20,
                                    color: hasChildren 
                                        ? Colors.grey.shade400 
                                        : const Color(0xFF10B981),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
