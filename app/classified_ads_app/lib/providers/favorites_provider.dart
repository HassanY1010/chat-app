import 'package:flutter/material.dart';
import '../services/api_service.dart';

class FavoritesProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService.instance;
  List<dynamic> _favorites = [];
  bool _isLoading = false;

  List<dynamic> get favorites => _favorites;
  bool get isLoading => _isLoading;

  Future<void> fetchFavorites() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.client.get('/favorites');
      _favorites = response.data['data'] ?? [];
    } catch (e) {
      debugPrint('Error fetching favorites: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(String adId) async {
    try {
      await _apiService.client.post('/favorite/$adId');
      // Optimistically update or re-fetch
      // For now, re-fetch to strict sync
      await fetchFavorites();
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      rethrow;
    }
  }

  bool isFavorite(int adId) {
    return _favorites.any((ad) => ad['id'] == adId);
  }
}
