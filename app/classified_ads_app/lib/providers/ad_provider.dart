import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';

class AdProvider with ChangeNotifier {
  final ApiService _apiService = ApiService.instance;
  List<dynamic> _ads = [];
  List<dynamic>? _myAds;
  bool _isLoading = false;
  int _currentPage = 1;
  bool _hasMore = true;
  String? _lastSearch;
  String? _lastCategoryId;

  List<dynamic> get ads => _ads;
  List<dynamic>? get myAds => _myAds;
  List<dynamic> _categories = [];
  List<dynamic> get categories => _categories;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;

  // Featured Ads State
  List<dynamic> _featuredAds = [];
  List<dynamic> get featuredAds => _featuredAds;
  bool _isFeaturedLoading = false;
  bool get isFeaturedLoading => _isFeaturedLoading;

  Future<void> fetchCategories() async {
    try {
      final response = await _apiService.client.get('/categories');
      _categories = response.data['data'];
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching categories: $e');
    }
  }

  String? _currentCategory;
  String? get currentCategory => _currentCategory;

  void setCategory(String? categoryId) {
    _currentCategory = categoryId;
    notifyListeners();
  }

  Future<void> fetchAds({
    String? categoryId,
    String? search,
    String? location,
    String? minPrice,
    String? maxPrice,
    String? currency,
    bool excludeFeatured = false,
    bool refresh = true,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _ads = [];
    }

    if (!_hasMore) return;

    _isLoading = true;
    notifyListeners();

    try {
      final queryParams = <String, dynamic>{
        'page': _currentPage,
      };
      if (categoryId != null) queryParams['category_id'] = categoryId;
      if (search != null) queryParams['search'] = search;
      if (location != null) queryParams['location'] = location;
      if (minPrice != null) queryParams['min_price'] = minPrice;
      if (maxPrice != null) queryParams['max_price'] = maxPrice;
      if (currency != null) queryParams['currency'] = currency;
      if (excludeFeatured) queryParams['exclude_featured'] = 1;

      _lastSearch = search;
      _lastCategoryId = categoryId;

      final response = await _apiService.client.get('/ads', queryParameters: queryParams);
      
      final List<dynamic> newAds = response.data['data'];
      
      if (newAds.length < 20) {
        _hasMore = false;
      }

      if (refresh) {
        _ads = newAds;
      } else {
        _ads.addAll(newAds);
      }
      
      _currentPage++;
    } catch (e) {
      debugPrint('Error fetching ads: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMoreAds() async {
    if (_isLoading || !_hasMore) return;
    await fetchAds(
      categoryId: _lastCategoryId,
      search: _lastSearch,
      refresh: false,
    );
  }

  Future<Map<String, dynamic>> fetchAdById(String id) async {
    try {
      final response = await _apiService.client.get('/ads/$id');
      return response.data['data'];
    } catch (e) {
      debugPrint('Error fetching ad details: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> fetchRecentAds() async {
    try {
      final response = await _apiService.client.get('/ads/recent');
      return response.data['data'];
    } catch (e) {
      debugPrint('Error fetching recent ads: $e');
      return [];
    }
  }

  Future<void> fetchFeaturedAds() async {
    _isFeaturedLoading = true;
    notifyListeners();

    try {
      debugPrint('🌟 Fetching Featured Ads...');
      // Real API Call
      final response = await _apiService.client.get('/ads/featured');
      debugPrint('✅ Featured Ads Response: ${response.data}');
      
      _featuredAds = response.data['data']; 
      
      // Fallback for demo if API returns empty
      if (_featuredAds.isEmpty) {
        debugPrint('⚠️ No featured ads found from API. Using Mock Data for Demo.');
        _featuredAds = [

          {
            'id': 102,
            'title': 'فيلا للبيع في حي الملقا',
            'price': '4,500,000',
            'currency': 'ر.س',
            'location': 'الرياض',
            'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
            'main_image': {
              'image_url': 'https://images.unsplash.com/photo-1600596542815-22b8c153bd30?auto=format&fit=crop&w=800&q=80',
            },
            'is_featured': true,
            'featured_end_date': DateTime.now().add(const Duration(days: 6)).toIso8601String(),
          },
           {
            'id': 103,
            'title': 'آيفون 15 برو ماكس جديد',
            'price': '4,200',
            'currency': 'ر.س',
            'location': 'جدة',
            'created_at': DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(),
            'main_image': {
              'image_url': 'https://images.unsplash.com/photo-1695048180490-30ed063c8452?auto=format&fit=crop&w=800&q=80',
            },
            'is_featured': true,
            'featured_end_date': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
          },
        ];
      }
    } catch (e) {
      debugPrint('❌ Error fetching featured ads: $e');
      // On error, also use mock data so UI doesn't look broken during dev
       _featuredAds = [
          {
            'id': 101,
            'title': 'سيارة مرسيدس 2024 نظيفة جداً',
            'price': '150,000',
            'currency': 'ر.س',
            'location': 'الرياض',
            'created_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
            'main_image': {
              'image_url': 'https://images.unsplash.com/photo-1605559424843-9e4c2287f38d?auto=format&fit=crop&w=800&q=80',
            },
            'is_featured': true,
            'featured_end_date': DateTime.now().add(const Duration(days: 5)).toIso8601String(),
          },
       ];
    } finally {
      _isFeaturedLoading = false;
      notifyListeners();
    }
  }

  Future<void> createAd(Map<String, dynamic> adData) async {
    try {
      await _apiService.client.post('/ads', data: adData);
      await fetchAds();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateAd(String id, Map<String, dynamic> adData) async {
    // Optimistic Update: Update locally first
    final previousAds = List.from(_ads);
    final previousMyAds = _myAds != null ? List.from(_myAds!) : null;

    try {
      // Helper function to update an ad in a list
      List<dynamic> updateList(List<dynamic> list) {
        final index = list.indexWhere((ad) => ad['id'].toString() == id);
        if (index != -1) {
          final updatedList = List.from(list);
          final currentAd = Map<String, dynamic>.from(updatedList[index]);
          
          // Merge basic fields
          adData.forEach((key, value) {
            if (key != 'images' && key != 'removed_images') {
               currentAd[key] = value;
            }
          });

          // Handle images transformation for UI
          if (adData['images'] != null && adData['images'] is List) {
            final List<String> newImages = List<String>.from(adData['images']);
            // Convert simple string list to the object list structure expected by UI
            currentAd['images'] = newImages.map((path) => {'image_path': path}).toList();
             // Update main_image (first one)
            if (newImages.isNotEmpty) {
              currentAd['main_image'] = {'image_path': newImages.first};
            }
          }

          updatedList[index] = currentAd;
          return updatedList;
        }
        return list;
      }

      _ads = updateList(_ads);
      if (_myAds != null) {
        _myAds = updateList(_myAds!);
      }
      
      notifyListeners();

      // Make the API call
      await _apiService.client.post('/ads/$id/update', data: adData);
      
      // We don't need to refetch immediately if the server returns the updated resource, 
      // but keeping it locally is faster. 
      // Ideally, we should parse the response and update with authoritative data, 
      // but for now, the optimistic update is sufficient for "instant" feel.
      
    } catch (e) {
      // Failure: Revert changes
      _ads = previousAds;
      _myAds = previousMyAds;
      notifyListeners();
      
      debugPrint('Failed to update ad: $e');
      rethrow;
    }
  }

  Future<void> deleteAd(String id) async {
    // Optimistic Update: Remove locally first
    final previousAds = List.from(_ads);
    final previousMyAds = _myAds != null ? List.from(_myAds!) : null;

    try {
      // Remove from main ads list
      _ads.removeWhere((ad) => ad['id'].toString() == id);
      
      // Remove from my ads list
      if (_myAds != null) {
        _myAds!.removeWhere((ad) => ad['id'].toString() == id);
      }
      
      notifyListeners();

      // Make the API call
      await _apiService.client.delete('/ads/$id');
      
      // Success: No further action needed as UI is already updated
    } catch (e) {
      // Failure: Revert changes
      _ads = previousAds;
      _myAds = previousMyAds;
      notifyListeners();
      
      debugPrint('Failed to delete ad: $e');
      rethrow;
    }
  }

  Future<void> reportAd(String adId, String reason) async {
    try {
      await _apiService.client.post('/report', data: {
        'ad_id': adId,
        'reason': reason,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> uploadImage(XFile image) async {
    try {
      debugPrint('📤 Uploading image: ${image.name}');
      
      MultipartFile multipartFile;

      if (kIsWeb) {
        // 🌐 WEB: Read image as Bytes
        Uint8List bytes = await image.readAsBytes();
        multipartFile = MultipartFile.fromBytes(
          bytes,
          filename: image.name,
          contentType: MediaType('image', 'jpeg'),
        );
      } else {
        // 📱 MOBILE: Use path directly
        multipartFile = await MultipartFile.fromFile(
          image.path,
          filename: image.name,
          contentType: MediaType('image', 'jpeg'),
        );
      }
      
      final formData = FormData.fromMap({
        'image': multipartFile,
      });
      
      debugPrint('📡 Sending request to /ads/upload-image');
      final response = await _apiService.client.post(
        '/ads/upload-image', 
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
      
      debugPrint('✅ Upload response: ${response.data}');
      
      if (response.statusCode == 200 && response.data['path'] != null) {
        debugPrint('✅ Image Path: ${response.data['path']}');
        return response.data['path'];
      }
      
      throw Exception(response.data['message'] ?? 'Unknown upload error');

    } catch (e) {
      debugPrint('❌ Image upload failed: $e');
      if (e is DioException) {
        debugPrint('❌ Response data: ${e.response?.data}');
        debugPrint('❌ Status code: ${e.response?.statusCode}');
        debugPrint('❌ Error message: ${e.message}');
        // Extract server error message if available
        final serverMessage = e.response?.data['message'];
        if (serverMessage != null) {
           throw Exception(serverMessage);
        }
      }
      rethrow; // Re-throw to be caught by the UI
    }
  }

  Future<void> fetchMyAds() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.client.get('/user/ads');
      _myAds = response.data['data'];
    } catch (e) {
      debugPrint('Failed to fetch my ads: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<dynamic>> fetchComments(String adId) async {
    try {
      final response = await _apiService.client.get('/ads/$adId/comments');
      return response.data;
    } catch (e) {
      debugPrint('Error fetching comments: $e');
      return [];
    }
  }

  Future<void> addComment(String adId, String content) async {
    try {
      await _apiService.client.post('/ads/$adId/comments', data: {'content': content});
    } catch (e) {
      rethrow;
    }
  }

  Future<void> likeAd(String adId) async {
    try {
      await _apiService.client.post('/ads/$adId/like');
    } catch (e) {
      debugPrint('Error liking ad: $e');
      rethrow;
    }
  }

  Future<void> unlikeAd(String adId) async {
    try {
      await _apiService.client.post('/ads/$adId/unlike');
    } catch (e) {
      debugPrint('Error unliking ad: $e');
      rethrow;
    }
  }
}
