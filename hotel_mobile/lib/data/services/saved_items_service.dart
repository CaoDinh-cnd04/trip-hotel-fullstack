import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/api_response.dart';
import '../models/saved_item.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/local_storage_service.dart';

class SavedItemsService {
  final Dio _dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));
  final LocalStorageService _localStorageService = LocalStorageService();
  
  static const String _localFavoritesKey = 'local_favorites';

  Future<ApiResponse<List<SavedItem>>> getSavedItems() async {
    try {
      final token = await _localStorageService.getToken();
      
      // Nếu chưa đăng nhập, load từ local storage
      if (token == null) {
        return await _getSavedItemsLocal();
      }

      final response = await _dio.get(
        '/api/user/saved-items',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        final savedItems = data.map((json) => SavedItem.fromJson(json)).toList();
        
        return ApiResponse<List<SavedItem>>(
          success: true,
          data: savedItems,
          message: 'Lấy danh sách đã lưu thành công',
        );
      } else {
        return ApiResponse<List<SavedItem>>(
          success: false,
          message: response.data['message'] ?? 'Lỗi tải danh sách đã lưu',
        );
      }
    } catch (e) {
      print('❌ Lỗi SavedItemsService.getSavedItems: $e');
      // Nếu lỗi 404 hoặc không có dữ liệu, load từ local
      if (e.toString().contains('404') || e.toString().contains('not found')) {
        return await _getSavedItemsLocal();
      }
      // Trả về local data khi có lỗi kết nối
      return await _getSavedItemsLocal();
    }
  }
  
  /// Lấy danh sách mục đã lưu từ local storage (SharedPreferences)
  /// 
  /// Trả về danh sách SavedItem được lưu trữ cục bộ
  /// Sử dụng khi người dùng chưa đăng nhập hoặc có lỗi kết nối
  Future<ApiResponse<List<SavedItem>>> _getSavedItemsLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getString(_localFavoritesKey);
      
      print('📂 Load từ local storage...');
      
      if (favoritesJson == null) {
        print('⚠️ Local storage trống');
        return ApiResponse<List<SavedItem>>(
          success: true,
          data: [],
          message: 'Chưa có mục nào được lưu',
        );
      }
      
      final favorites = List<Map<String, dynamic>>.from(jsonDecode(favoritesJson));
      print('📦 Tìm thấy ${favorites.length} items trong local storage');
      
      // Convert to SavedItem objects
      final savedItems = favorites.map((item) {
        return SavedItem(
          id: item['item_id'] ?? '',
          itemId: item['item_id'] ?? '',
          type: item['type'] ?? 'hotel',
          name: item['name'] ?? '',
          location: item['location'],
          price: item['price'],
          imageUrl: item['image_url'],
          metadata: item['metadata'],
          savedAt: DateTime.parse(item['saved_at'] ?? DateTime.now().toIso8601String()),
        );
      }).toList();
      
      // Sort by saved date
      savedItems.sort((a, b) => b.savedAt.compareTo(a.savedAt));
      
      print('✅ Load thành công ${savedItems.length} saved items từ local');
      
      return ApiResponse<List<SavedItem>>(
        success: true,
        data: savedItems,
        message: 'Đã lưu (local)',
      );
    } catch (e) {
      print('❌ Lỗi _getSavedItemsLocal: $e');
      return ApiResponse<List<SavedItem>>(
        success: true,
        data: [],
        message: 'Lỗi load local',
      );
    }
  }

  Future<ApiResponse<void>> addToSaved({
    required String itemId,
    required String type,
    required String name,
    String? location,
    String? price,
    String? imageUrl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final token = await _localStorageService.getToken();
      
      // Nếu chưa đăng nhập, lưu local
      if (token == null) {
        return await _addToSavedLocal(
          itemId: itemId,
          type: type,
          name: name,
          location: location,
          price: price,
          imageUrl: imageUrl,
          metadata: metadata,
        );
      }

      final response = await _dio.post(
        '/api/user/saved-items',
        data: {
          'item_id': itemId,
          'type': type,
          'name': name,
          'location': location,
          'price': price,
          'image_url': imageUrl,
          'metadata': metadata,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse<void>(
          success: true,
          message: 'Đã thêm vào danh sách đã lưu',
        );
      } else {
        return ApiResponse<void>(
          success: false,
          message: response.data['message'] ?? 'Lỗi thêm vào danh sách đã lưu',
        );
      }
    } catch (e) {
      print('❌ Lỗi SavedItemsService.addToSaved: $e');
      // Fallback to local storage on error
      print('📦 Fallback: Lưu vào local storage');
      return await _addToSavedLocal(
        itemId: itemId,
        type: type,
        name: name,
        location: location,
        price: price,
        imageUrl: imageUrl,
        metadata: metadata,
      );
    }
  }
  
  /// Lưu mục vào local storage (SharedPreferences) khi chưa đăng nhập
  /// 
  /// [itemId] - ID của mục cần lưu
  /// [type] - Loại mục (hotel, room, v.v.)
  /// [name] - Tên mục
  /// [location] - Địa điểm (tùy chọn)
  /// [price] - Giá (tùy chọn)
  /// [imageUrl] - URL hình ảnh (tùy chọn)
  /// [metadata] - Dữ liệu bổ sung (tùy chọn)
  /// 
  /// Trả về ApiResponse với kết quả lưu
  Future<ApiResponse<void>> _addToSavedLocal({
    required String itemId,
    required String type,
    required String name,
    String? location,
    String? price,
    String? imageUrl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getString(_localFavoritesKey);
      
      List<Map<String, dynamic>> favorites = [];
      if (favoritesJson != null) {
        favorites = List<Map<String, dynamic>>.from(jsonDecode(favoritesJson));
      }
      
      // Check if already exists
      final exists = favorites.any((item) => 
        item['item_id'] == itemId && item['type'] == type
      );
      
      if (exists) {
        return ApiResponse<void>(
          success: false,
          message: 'Mục này đã được lưu',
        );
      }
      
      // Add new favorite
      favorites.add({
        'item_id': itemId,
        'type': type,
        'name': name,
        'location': location,
        'price': price,
        'image_url': imageUrl,
        'metadata': metadata,
        'saved_at': DateTime.now().toIso8601String(),
      });
      
      await prefs.setString(_localFavoritesKey, jsonEncode(favorites));
      
      print('✅ Đã lưu vào local storage: $name (Total: ${favorites.length} items)');
      
      return ApiResponse<void>(
        success: true,
        message: 'Đã lưu (local)',
      );
    } catch (e) {
      print('❌ Lỗi _addToSavedLocal: $e');
      return ApiResponse<void>(
        success: false,
        message: 'Lỗi lưu local: $e',
      );
    }
  }

  Future<ApiResponse<void>> removeFromSaved(String savedItemId) async {
    try {
      final token = await _localStorageService.getToken();
      if (token == null) {
        return ApiResponse<void>(
          success: false,
          message: 'Chưa đăng nhập',
        );
      }

      final response = await _dio.delete(
        '/api/user/saved-items/$savedItemId',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        return ApiResponse<void>(
          success: true,
          message: 'Đã xóa khỏi danh sách đã lưu',
        );
      } else {
        return ApiResponse<void>(
          success: false,
          message: response.data['message'] ?? 'Lỗi xóa khỏi danh sách đã lưu',
        );
      }
    } catch (e) {
      print('❌ Lỗi SavedItemsService.removeFromSaved: $e');
      return ApiResponse<void>(
        success: false,
        message: 'Lỗi kết nối: $e',
      );
    }
  }

  Future<ApiResponse<bool>> isSaved(String itemId, String type) async {
    try {
      final token = await _localStorageService.getToken();
      
      // Nếu chưa đăng nhập, check local storage
      if (token == null) {
        return await _isSavedLocal(itemId, type);
      }

      final response = await _dio.get(
        '/api/user/saved-items/check',
        queryParameters: {
          'item_id': itemId,
          'type': type,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        return ApiResponse<bool>(
          success: true,
          data: response.data['is_saved'] ?? false,
          message: 'Kiểm tra trạng thái lưu thành công',
        );
      } else {
        return ApiResponse<bool>(
          success: false,
          data: false,
          message: response.data['message'] ?? 'Lỗi kiểm tra trạng thái lưu',
        );
      }
    } catch (e) {
      print('❌ Lỗi SavedItemsService.isSaved: $e');
      // Fallback to local storage on error
      print('📦 Fallback: Kiểm tra local storage');
      return await _isSavedLocal(itemId, type);
    }
  }
  
  /// Kiểm tra xem mục đã được lưu trong local storage chưa
  /// 
  /// [itemId] - ID của mục cần kiểm tra
  /// [type] - Loại mục (hotel, room, v.v.)
  /// 
  /// Trả về ApiResponse với true nếu đã lưu, false nếu chưa
  Future<ApiResponse<bool>> _isSavedLocal(String itemId, String type) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getString(_localFavoritesKey);
      
      if (favoritesJson == null) {
        return ApiResponse<bool>(
          success: true,
          data: false,
          message: 'Chưa có mục nào được lưu',
        );
      }
      
      final favorites = List<Map<String, dynamic>>.from(jsonDecode(favoritesJson));
      final exists = favorites.any((item) => 
        item['item_id'] == itemId && item['type'] == type
      );
      
      return ApiResponse<bool>(
        success: true,
        data: exists,
        message: 'Kiểm tra local thành công',
      );
    } catch (e) {
      print('❌ Lỗi _isSavedLocal: $e');
      return ApiResponse<bool>(
        success: false,
        data: false,
        message: 'Lỗi check local: $e',
      );
    }
  }

  Future<ApiResponse<void>> removeFromSavedByItemId(String itemId, String type) async {
    // Luôn xóa từ local storage trước
    print('🗑️ Xóa từ local storage: $itemId');
    final localResult = await _removeFromSavedLocal(itemId, type);
    
    if (localResult.success) {
      print('✅ Đã xóa từ local storage thành công');
      return localResult;
    }
    
    // Nếu local không có, thử xóa từ backend
    try {
      final token = await _localStorageService.getToken();
      
      if (token == null) {
        print('⚠️ Chưa đăng nhập, không thể xóa từ backend');
        return localResult; // Return local result anyway
      }

      // Try to get from backend
      final savedItemsResult = await getSavedItems();
      if (!savedItemsResult.success || (savedItemsResult.data?.isEmpty ?? true)) {
        print('⚠️ Backend không có dữ liệu');
        return localResult;
      }

      final savedItems = savedItemsResult.data!;
      final savedItemIndex = savedItems.indexWhere(
        (item) => item.itemId == itemId && item.type == type,
      );
      
      if (savedItemIndex == -1) {
        print('⚠️ Không tìm thấy item trong backend');
        return localResult;
      }

      // Now remove from backend
      print('🌐 Xóa từ backend: ${savedItems[savedItemIndex].id}');
      final backendResult = await removeFromSaved(savedItems[savedItemIndex].id);
      return backendResult.success ? backendResult : localResult;
    } catch (e) {
      print('❌ Lỗi khi xóa từ backend: $e');
      return localResult; // Return local result on error
    }
  }
  
  /// Xóa mục khỏi local storage (SharedPreferences)
  /// 
  /// [itemId] - ID của mục cần xóa
  /// [type] - Loại mục (hotel, room, v.v.)
  /// 
  /// Trả về ApiResponse với kết quả xóa
  Future<ApiResponse<void>> _removeFromSavedLocal(String itemId, String type) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getString(_localFavoritesKey);
      
      if (favoritesJson == null) {
        print('⚠️ Local storage trống, không có gì để xóa');
        return ApiResponse<void>(
          success: false,
          message: 'Không tìm thấy mục đã lưu',
        );
      }
      
      List<Map<String, dynamic>> favorites = List<Map<String, dynamic>>.from(jsonDecode(favoritesJson));
      final originalLength = favorites.length;
      
      // Remove the item
      favorites.removeWhere((item) => 
        item['item_id'] == itemId && item['type'] == type
      );
      
      final removedCount = originalLength - favorites.length;
      
      if (removedCount == 0) {
        print('⚠️ Không tìm thấy item $itemId trong local storage');
        return ApiResponse<void>(
          success: false,
          message: 'Không tìm thấy mục đã lưu',
        );
      }
      
      await prefs.setString(_localFavoritesKey, jsonEncode(favorites));
      
      print('✅ Đã xóa $removedCount item từ local (Còn lại: ${favorites.length})');
      
      return ApiResponse<void>(
        success: true,
        message: 'Đã xóa (local)',
      );
    } catch (e) {
      print('❌ Lỗi _removeFromSavedLocal: $e');
      return ApiResponse<void>(
        success: false,
        message: 'Lỗi xóa local: $e',
      );
    }
  }

  List<SavedItem> _getFallbackSavedItems() {
    return [
      SavedItem(
        id: '1',
        itemId: '1',
        type: 'hotel',
        name: 'Hanoi Deluxe Hotel',
        location: 'Hoàn Kiếm, Hà Nội',
        price: '1,200,000 ₫/đêm',
        imageUrl: 'http://localhost:5000/images/hotels/hanoi_deluxe.jpg',
        metadata: {"rating": 4.5, "stars": 4},
        savedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      SavedItem(
        id: '2',
        itemId: '2',
        type: 'hotel',
        name: 'Lake View Hanoi',
        location: 'Tây Hồ, Hà Nội',
        price: '2,500,000 ₫/đêm',
        imageUrl: 'http://localhost:5000/images/hotels/lake_view.jpg',
        metadata: {"rating": 4.8, "stars": 5},
        savedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      SavedItem(
        id: '3',
        itemId: '3',
        type: 'activity',
        name: 'Tham quan Vịnh Hạ Long',
        location: 'Quảng Ninh',
        price: '800,000 ₫/người',
        imageUrl: 'http://localhost:5000/images/locations/baidai.jpg',
        metadata: {"duration": "1 ngày", "rating": 4.7},
        savedAt: DateTime.now().subtract(const Duration(hours: 12)),
      ),
    ];
  }

}
