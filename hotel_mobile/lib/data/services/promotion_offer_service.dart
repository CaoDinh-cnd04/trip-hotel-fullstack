import 'package:dio/dio.dart';
import '../models/api_response.dart';
import '../models/promotion_offer.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/local_storage_service.dart';

class PromotionOfferService {
  final Dio _dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));
  final LocalStorageService _localStorageService = LocalStorageService();

  // Lấy danh sách ưu đãi đang hoạt động cho một khách sạn
  Future<ApiResponse<List<PromotionOffer>>> getActiveOffersForHotel(int hotelId) async {
    try {
      final response = await _dio.get(
        '/api/promotion-offers/hotel/$hotelId/active',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        final offers = data.map((json) => PromotionOffer.fromJson(json)).toList();
        
        return ApiResponse<List<PromotionOffer>>(
          success: true,
          data: offers,
          message: 'Lấy danh sách ưu đãi thành công',
        );
      } else {
        return ApiResponse<List<PromotionOffer>>(
          success: false,
          message: response.data['message'] ?? 'Lỗi tải danh sách ưu đãi',
        );
      }
    } catch (e) {
      print('❌ Lỗi PromotionOfferService.getActiveOffersForHotel: $e');
      // Trả về fallback data khi có lỗi kết nối
      return ApiResponse<List<PromotionOffer>>(
        success: true,
        data: _getFallbackOffers(hotelId),
        message: 'Dữ liệu mẫu (offline mode)',
      );
    }
  }

  // Lấy ưu đãi cho một loại phòng cụ thể
  Future<ApiResponse<PromotionOffer?>> getOfferForRoom(int hotelId, int roomTypeId) async {
    try {
      final response = await _dio.get(
        '/api/promotion-offers/hotel/$hotelId/room/$roomTypeId',
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data != null) {
          return ApiResponse<PromotionOffer?>(
            success: true,
            data: PromotionOffer.fromJson(data),
            message: 'Lấy ưu đãi thành công',
          );
        } else {
          return ApiResponse<PromotionOffer?>(
            success: true,
            data: null,
            message: 'Không có ưu đãi cho phòng này',
          );
        }
      } else {
        return ApiResponse<PromotionOffer?>(
          success: false,
          message: response.data['message'] ?? 'Lỗi tải ưu đãi',
        );
      }
    } catch (e) {
      print('❌ Lỗi PromotionOfferService.getOfferForRoom: $e');
      return ApiResponse<PromotionOffer?>(
        success: false,
        message: 'Lỗi kết nối: $e',
      );
    }
  }

  // Đặt phòng với ưu đãi
  Future<ApiResponse<Map<String, dynamic>>> bookWithOffer({
    required String offerId,
    required DateTime checkInDate,
    required DateTime checkOutDate,
    required int adults,
    required int children,
  }) async {
    try {
      final token = await _localStorageService.getToken();
      if (token == null) {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: 'Chưa đăng nhập',
        );
      }

      final data = {
        'offer_id': offerId,
        'check_in_date': checkInDate.toIso8601String(),
        'check_out_date': checkOutDate.toIso8601String(),
        'adults': adults,
        'children': children,
      };

      final response = await _dio.post(
        '/api/promotion-offers/book',
        data: data,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: response.data['data'],
          message: response.data['message'] ?? 'Đặt phòng thành công',
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: response.data['message'] ?? 'Lỗi đặt phòng',
        );
      }
    } catch (e) {
      print('❌ Lỗi PromotionOfferService.bookWithOffer: $e');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Lỗi kết nối: $e',
      );
    }
  }

  // Tạo ưu đãi mới (cho hotel owner)
  Future<ApiResponse<PromotionOffer>> createOffer({
    required int hotelId,
    required int roomTypeId,
    required String title,
    required String description,
    required double originalPrice,
    required double discountedPrice,
    required int totalRooms,
    required int durationHours,
    required List<String> conditions,
  }) async {
    try {
      final token = await _localStorageService.getToken();
      if (token == null) {
        return ApiResponse<PromotionOffer>(
          success: false,
          message: 'Chưa đăng nhập',
        );
      }

      final now = DateTime.now();
      final data = {
        'hotel_id': hotelId,
        'room_type_id': roomTypeId,
        'title': title,
        'description': description,
        'original_price': originalPrice,
        'discounted_price': discountedPrice,
        'total_rooms': totalRooms,
        'start_time': now.toIso8601String(),
        'end_time': now.add(Duration(hours: durationHours)).toIso8601String(),
        'conditions': conditions,
      };

      final response = await _dio.post(
        '/api/promotion-offers',
        data: data,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 201) {
        return ApiResponse<PromotionOffer>(
          success: true,
          data: PromotionOffer.fromJson(response.data['data']),
          message: response.data['message'] ?? 'Tạo ưu đãi thành công',
        );
      } else {
        return ApiResponse<PromotionOffer>(
          success: false,
          message: response.data['message'] ?? 'Lỗi tạo ưu đãi',
        );
      }
    } catch (e) {
      print('❌ Lỗi PromotionOfferService.createOffer: $e');
      return ApiResponse<PromotionOffer>(
        success: false,
        message: 'Lỗi kết nối: $e',
      );
    }
  }

  // Cập nhật số phòng còn lại (khi có người đặt)
  Future<ApiResponse<void>> updateAvailableRooms(String offerId, int newAvailableRooms) async {
    try {
      final token = await _localStorageService.getToken();
      if (token == null) {
        return ApiResponse<void>(
          success: false,
          message: 'Chưa đăng nhập',
        );
      }

      final response = await _dio.put(
        '/api/promotion-offers/$offerId/rooms',
        data: {'available_rooms': newAvailableRooms},
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        return ApiResponse<void>(
          success: true,
          message: response.data['message'] ?? 'Cập nhật thành công',
        );
      } else {
        return ApiResponse<void>(
          success: false,
          message: response.data['message'] ?? 'Lỗi cập nhật',
        );
      }
    } catch (e) {
      print('❌ Lỗi PromotionOfferService.updateAvailableRooms: $e');
      return ApiResponse<void>(
        success: false,
        message: 'Lỗi kết nối: $e',
      );
    }
  }

  // Hủy ưu đãi
  Future<ApiResponse<void>> cancelOffer(String offerId) async {
    try {
      final token = await _localStorageService.getToken();
      if (token == null) {
        return ApiResponse<void>(
          success: false,
          message: 'Chưa đăng nhập',
        );
      }

      final response = await _dio.delete(
        '/api/promotion-offers/$offerId',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        return ApiResponse<void>(
          success: true,
          message: response.data['message'] ?? 'Hủy ưu đãi thành công',
        );
      } else {
        return ApiResponse<void>(
          success: false,
          message: response.data['message'] ?? 'Lỗi hủy ưu đãi',
        );
      }
    } catch (e) {
      print('❌ Lỗi PromotionOfferService.cancelOffer: $e');
      return ApiResponse<void>(
        success: false,
        message: 'Lỗi kết nối: $e',
      );
    }
  }

  // Fallback data cho demo
  List<PromotionOffer> _getFallbackOffers(int hotelId) {
    final now = DateTime.now();
    return [
      PromotionOffer(
        id: '1',
        hotelId: hotelId,
        roomTypeId: 1,
        title: 'Ưu đãi đặc biệt cuối ngày',
        description: 'Giảm giá 40% cho phòng Standard - Chỉ còn 2 phòng!',
        originalPrice: 2000000,
        discountedPrice: 1200000,
        totalRooms: 3,
        availableRooms: 2,
        startTime: now.subtract(const Duration(minutes: 30)),
        endTime: now.add(const Duration(hours: 2, minutes: 30)),
        conditions: [
          'Không thể hủy phòng',
          'Không hoàn tiền',
          'Áp dụng trong vòng 3 tiếng',
        ],
        isActive: true,
        createdAt: now.subtract(const Duration(minutes: 30)),
        updatedAt: now.subtract(const Duration(minutes: 5)),
      ),
      PromotionOffer(
        id: '2',
        hotelId: hotelId,
        roomTypeId: 2,
        title: 'Flash Sale Deluxe Room',
        description: 'Giảm giá 35% cho phòng Deluxe - Còn 1 phòng cuối!',
        originalPrice: 3000000,
        discountedPrice: 1950000,
        totalRooms: 2,
        availableRooms: 1,
        startTime: now.subtract(const Duration(minutes: 45)),
        endTime: now.add(const Duration(hours: 1, minutes: 15)),
        conditions: [
          'Không thể hủy phòng',
          'Không hoàn tiền',
          'Áp dụng trong vòng 2 tiếng',
        ],
        isActive: true,
        createdAt: now.subtract(const Duration(minutes: 45)),
        updatedAt: now.subtract(const Duration(minutes: 10)),
      ),
    ];
  }
}
