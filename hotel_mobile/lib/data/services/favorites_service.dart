/**
 * Favorites Service - Quản lý khách sạn yêu thích
 * 
 * Lưu LOCAL bằng SharedPreferences (không cần backend)
 * 
 * Chức năng:
 * - Thêm/xóa khách sạn yêu thích
 * - Kiểm tra khách sạn đã lưu chưa
 * - Lấy danh sách tất cả khách sạn đã lưu
 * - Xóa tất cả
 */

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/hotel.dart';

class FavoritesService {
  static const String _favoritesKey = 'favorite_hotels';

  /// Thêm khách sạn vào danh sách yêu thích
  Future<bool> addFavorite(Hotel hotel) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favorites = await getFavorites();
      
      // Kiểm tra đã tồn tại chưa
      if (favorites.any((h) => h.id == hotel.id)) {
        return false; // Đã tồn tại
      }
      
      // Thêm vào danh sách
      favorites.add(hotel);
      
      // Lưu vào SharedPreferences
      final jsonList = favorites.map((h) => h.toJson()).toList();
      await prefs.setString(_favoritesKey, jsonEncode(jsonList));
      
      print('✅ Added hotel ${hotel.ten} to favorites');
      return true;
    } catch (e) {
      print('❌ Error adding favorite: $e');
      return false;
    }
  }

  /// Xóa khách sạn khỏi danh sách yêu thích
  Future<bool> removeFavorite(int hotelId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favorites = await getFavorites();
      
      // Xóa khỏi danh sách
      favorites.removeWhere((h) => h.id == hotelId);
      
      // Lưu lại vào SharedPreferences
      final jsonList = favorites.map((h) => h.toJson()).toList();
      await prefs.setString(_favoritesKey, jsonEncode(jsonList));
      
      print('✅ Removed hotel ID $hotelId from favorites');
      return true;
    } catch (e) {
      print('❌ Error removing favorite: $e');
      return false;
    }
  }

  /// Toggle favorite (thêm nếu chưa có, xóa nếu đã có)
  Future<bool> toggleFavorite(Hotel hotel) async {
    final isFav = await isFavorite(hotel.id);
    if (isFav) {
      return await removeFavorite(hotel.id);
    } else {
      return await addFavorite(hotel);
    }
  }

  /// Kiểm tra khách sạn đã được lưu chưa
  Future<bool> isFavorite(int hotelId) async {
    try {
      final favorites = await getFavorites();
      return favorites.any((h) => h.id == hotelId);
    } catch (e) {
      print('❌ Error checking favorite: $e');
      return false;
    }
  }

  /// Lấy danh sách tất cả khách sạn yêu thích
  Future<List<Hotel>> getFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_favoritesKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final hotels = jsonList.map((json) => Hotel.fromJson(json)).toList();
      
      // Sắp xếp theo thời gian mới nhất
      hotels.sort((a, b) => (b.createdAt ?? DateTime.now())
          .compareTo(a.createdAt ?? DateTime.now()));
      
      return hotels;
    } catch (e) {
      print('❌ Error getting favorites: $e');
      return [];
    }
  }

  /// Lấy số lượng khách sạn yêu thích
  Future<int> getFavoritesCount() async {
    final favorites = await getFavorites();
    return favorites.length;
  }

  /// Xóa tất cả khách sạn yêu thích
  Future<bool> clearAllFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_favoritesKey);
      print('✅ Cleared all favorites');
      return true;
    } catch (e) {
      print('❌ Error clearing favorites: $e');
      return false;
    }
  }

  /// Kiểm tra có khách sạn nào được lưu không
  Future<bool> hasFavorites() async {
    final count = await getFavoritesCount();
    return count > 0;
  }
}

