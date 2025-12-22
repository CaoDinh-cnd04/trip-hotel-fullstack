import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';

class HotelManagerService {
  final Dio _dio;

  HotelManagerService(this._dio) {
    _dio.options.baseUrl = AppConstants.baseUrl;
    _dio.options.connectTimeout = AppConstants.connectTimeout;
    _dio.options.receiveTimeout = AppConstants.receiveTimeout;
    _dio.options.sendTimeout = AppConstants.sendTimeout;
  }

  // Set authorization token
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  // Get assigned hotel information
  Future<Map<String, dynamic>> getAssignedHotel() async {
    try {
      final response = await _dio.get('/api/v2/hotel-manager/hotel');
      return response.data['data'];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Get hotel statistics
  Future<Map<String, dynamic>> getHotelStats() async {
    try {
      final response = await _dio.get('/api/v2/hotel-manager/hotel/stats');
      return response.data['data'];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Get dashboard KPI
  Future<Map<String, dynamic>> getDashboardKpi() async {
    try {
      final response = await _dio.get('/api/v2/hotel-manager/dashboard');
      return response.data['data'];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Update hotel information
  Future<Map<String, dynamic>> updateHotel(Map<String, dynamic> hotelData) async {
    try {
      final response = await _dio.put('/api/v2/hotel-manager/hotel', data: hotelData);
      return response.data['data'];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Get all amenities
  Future<List<Map<String, dynamic>>> getAllAmenities() async {
    try {
      final response = await _dio.get('/api/v2/hotel-manager/amenities');
      return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Create new amenity for hotel
  Future<Map<String, dynamic>> createAmenity({
    required String ten,
    String? moTa,
    String? nhom,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v2/hotel-manager/amenities',
        data: {
          'ten': ten,
          'mo_ta': moTa,
          'nhom': nhom ?? 'Khác',
          // ✅ Removed loai_tien_nghi - column doesn't exist in database
        },
      );
      return response.data['data'];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Get hotel amenities with pricing
  Future<List<Map<String, dynamic>>> getHotelAmenitiesWithPricing() async {
    try {
      final response = await _dio.get('/api/v2/hotel-manager/hotel/amenities');
      return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Update amenity pricing
  Future<Map<String, dynamic>> updateAmenityPricing({
    required int amenityId,
    required bool mienPhi,
    double? giaPhi,
    String? ghiChu,
  }) async {
    try {
      final response = await _dio.put(
        '/api/v2/hotel-manager/amenities/$amenityId/pricing',
        data: {
          'amenityId': amenityId,
          'mienPhi': mienPhi,
          'giaPhi': giaPhi,
          'ghiChu': ghiChu,
        },
      );
      return response.data['data'];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Update hotel amenities
  Future<void> updateHotelAmenities(List<int> amenityIds) async {
    try {
      await _dio.put('/api/v2/hotel-manager/hotel/amenities', data: {'amenities': amenityIds});
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Get hotel rooms
  Future<List<Map<String, dynamic>>> getHotelRooms() async {
    try {
      final response = await _dio.get('/api/v2/hotel-manager/hotel/rooms');
      return List<Map<String, dynamic>>.from(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Add new room
  Future<Map<String, dynamic>> addRoom(Map<String, dynamic> roomData) async {
    try {
      final response = await _dio.post('/api/v2/hotel-manager/hotel/rooms', data: roomData);
      return response.data['data'];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Update room
  Future<Map<String, dynamic>> updateRoom(String roomId, Map<String, dynamic> roomData) async {
    try {
      final response = await _dio.put('/api/v2/hotel-manager/hotel/rooms/$roomId', data: roomData);
      return response.data['data'];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Delete room
  Future<void> deleteRoom(String roomId) async {
    try {
      await _dio.delete('/api/v2/hotel-manager/hotel/rooms/$roomId');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Upload room images
  Future<Map<String, dynamic>> uploadRoomImages(String roomId, List<String> imagePaths) async {
    try {
      final formData = FormData();
      
      for (final path in imagePaths) {
        formData.files.add(MapEntry(
          'images',
          await MultipartFile.fromFile(path, filename: path.split('/').last),
        ));
      }
      
      final response = await _dio.post(
        '/api/v2/hotel-manager/hotel/rooms/$roomId/images',
        data: formData,
      );
      
      return response.data['data'];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Get hotel bookings
  Future<Map<String, dynamic>> getHotelBookings({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (status != null && status != 'all') {
        queryParams['status'] = status;
      }

      final response = await _dio.get('/api/v2/hotel-manager/hotel/bookings', queryParameters: queryParams);
      return {
        'bookings': List<Map<String, dynamic>>.from(response.data['data']),
        'pagination': response.data['pagination'],
      };
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Update booking status
  Future<void> updateBookingStatus(String bookingId, String status) async {
    try {
      await _dio.put('/api/v2/hotel-manager/hotel/bookings/$bookingId', data: {'status': status});
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Get hotel reviews
  Future<List<Map<String, dynamic>>> getHotelReviews() async {
    try {
      final response = await _dio.get('/api/v2/hotel-manager/hotel/reviews');
      return List<Map<String, dynamic>>.from(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Respond to review
  Future<void> respondToReview(String reviewId, String response) async {
    try {
      await _dio.post('/api/v2/hotel-manager/hotel/reviews/$reviewId/respond', data: {'phan_hoi': response});
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Error handling
  String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Kết nối timeout. Vui lòng thử lại.';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['message'] ?? 'Lỗi server';
        return 'Lỗi $statusCode: $message';
      case DioExceptionType.cancel:
        return 'Yêu cầu đã bị hủy';
      case DioExceptionType.unknown:
        return 'Lỗi kết nối. Vui lòng kiểm tra internet.';
      default:
        return 'Có lỗi xảy ra. Vui lòng thử lại.';
    }
  }
}
