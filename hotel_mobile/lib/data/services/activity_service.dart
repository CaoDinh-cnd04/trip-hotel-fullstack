import 'package:dio/dio.dart';
import '../models/activity.dart';
import '../models/api_response.dart';
import '../../core/constants/app_constants.dart';
import 'backend_auth_service.dart';

/// Service để tương tác với API hoạt động (activities)
/// 
/// Chức năng:
/// - Lấy danh sách activities
/// - Tìm kiếm activities theo từ khóa, địa điểm, ngày
/// - Lấy chi tiết activity
class ActivityService {
  final Dio _dio = Dio();
  final BackendAuthService _authService = BackendAuthService();

  /// Lấy danh sách activities
  /// 
  /// Parameters:
  ///   - page: Trang hiện tại
  ///   - limit: Số lượng items/trang
  ///   - active: Lọc theo trạng thái (true=đang hoạt động)
  /// 
  /// Returns: ApiResponse<List<Activity>>
  Future<ApiResponse<List<Activity>>> getActivities({
    int page = 1,
    int limit = 20,
    bool? active,
  }) async {
    try {
      final token = await _authService.getToken();
      
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (active != null) {
        queryParams['active'] = active;
      }

      final response = await _dio.get(
        '${AppConstants.baseUrl}${AppConstants.activitiesEndpoint}',
        queryParameters: queryParams,
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );

      return ApiResponse<List<Activity>>.fromJson(response.data, (data) {
        if (data is List) {
          return data.map((item) => Activity.fromJson(item)).toList();
        }
        return <Activity>[];
      });
    } catch (e) {
      print('❌ Error getting activities: $e');
      // Trả về mock data nếu API chưa có
      return ApiResponse<List<Activity>>(
        success: true,
        message: 'Đang sử dụng dữ liệu mẫu',
        data: _getMockActivities(),
      );
    }
  }

  /// Tìm kiếm activities
  /// 
  /// Parameters:
  ///   - query: Từ khóa tìm kiếm
  ///   - location: Địa điểm
  ///   - date: Ngày tham gia
  ///   - adults: Số người lớn
  ///   - children: Số trẻ em
  ///   - page: Trang hiện tại
  ///   - limit: Số lượng items/trang
  /// 
  /// Returns: ApiResponse<List<Activity>>
  Future<ApiResponse<List<Activity>>> searchActivities({
    String? query,
    String? location,
    DateTime? date,
    int? adults,
    int? children,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final token = await _authService.getToken();
      
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      
      if (query != null && query.isNotEmpty) {
        queryParams['q'] = query;
      }
      if (location != null && location.isNotEmpty) {
        queryParams['location'] = location;
      }
      if (date != null) {
        queryParams['date'] = date.toIso8601String().split('T')[0];
      }
      if (adults != null) {
        queryParams['adults'] = adults;
      }
      if (children != null) {
        queryParams['children'] = children;
      }

      final response = await _dio.get(
        '${AppConstants.baseUrl}${AppConstants.activitiesEndpoint}/search',
        queryParameters: queryParams,
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );

      return ApiResponse<List<Activity>>.fromJson(response.data, (data) {
        if (data is List) {
          return data.map((item) => Activity.fromJson(item)).toList();
        }
        return <Activity>[];
      });
    } catch (e) {
      print('❌ Error searching activities: $e');
      // Trả về mock data với filter
      final allActivities = _getMockActivities();
      List<Activity> filtered = allActivities;
      
      if (query != null && query.isNotEmpty) {
        filtered = filtered.where((activity) {
          return activity.ten.toLowerCase().contains(query.toLowerCase()) ||
                 (activity.moTa?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
                 (activity.diaDiem?.toLowerCase().contains(query.toLowerCase()) ?? false);
        }).toList();
      }
      
      if (location != null && location.isNotEmpty) {
        filtered = filtered.where((activity) {
          return activity.diaDiem?.toLowerCase().contains(location.toLowerCase()) ?? false;
        }).toList();
      }

      return ApiResponse<List<Activity>>(
        success: true,
        message: 'Đang sử dụng dữ liệu mẫu',
        data: filtered,
      );
    }
  }

  /// Lấy chi tiết activity theo ID
  /// 
  /// Returns: ApiResponse<Activity>
  Future<ApiResponse<Activity>> getActivityById(int id) async {
    try {
      final token = await _authService.getToken();
      
      final response = await _dio.get(
        '${AppConstants.baseUrl}${AppConstants.activitiesEndpoint}/$id',
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );

      return ApiResponse<Activity>.fromJson(
        response.data,
        (data) => Activity.fromJson(data),
      );
    } catch (e) {
      print('❌ Error getting activity by id: $e');
      // Trả về mock data
      final mockActivities = _getMockActivities();
      final activity = mockActivities.firstWhere(
        (a) => a.id == id,
        orElse: () => mockActivities.first,
      );
      
      return ApiResponse<Activity>(
        success: true,
        message: 'Đang sử dụng dữ liệu mẫu',
        data: activity,
      );
    }
  }

  /// Mock data cho activities (sử dụng khi API chưa có)
  List<Activity> _getMockActivities() {
    return [
      Activity(
        id: 1,
        ten: 'Tour Vũng Tàu 1 ngày',
        moTa: 'Khám phá những điểm đến hấp dẫn tại Vũng Tàu với tour trọn gói 1 ngày. Bao gồm tham quan các địa danh nổi tiếng, thưởng thức hải sản tươi ngon và tắm biển tại các bãi biển đẹp nhất.',
        gia: 500000,
        diaDiem: 'Vũng Tàu',
        diaChi: 'Bắt đầu từ Trung tâm Vũng Tàu',
        thoiLuong: 480, // 8 giờ
        gioBatDau: '08:00',
        hinhAnh: 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800',
        danhGia: 4.5,
        soLuongDanhGia: 128,
        loaiHoatDong: 'Tour',
        soNguoiToiDa: 30,
        soNguoiToiThieu: 2,
        hinhAnhBoSung: [
          'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800',
          'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800',
        ],
      ),
      Activity(
        id: 2,
        ten: 'Tham quan Tượng Chúa Kitô Vua',
        moTa: 'Tham quan tượng Chúa Kitô Vua - biểu tượng của Vũng Tàu. Từ đỉnh núi, bạn có thể ngắm toàn cảnh thành phố biển xinh đẹp.',
        gia: 50000,
        diaDiem: 'Vũng Tàu',
        diaChi: 'Núi Nhỏ, Vũng Tàu',
        thoiLuong: 120, // 2 giờ
        gioBatDau: '06:00',
        hinhAnh: 'https://images.unsplash.com/photo-1515542622106-78bda8ba0e5b?w=800',
        danhGia: 4.8,
        soLuongDanhGia: 256,
        loaiHoatDong: 'Vé tham quan',
        soNguoiToiDa: 50,
        soNguoiToiThieu: 1,
      ),
      Activity(
        id: 3,
        ten: 'Lặn biển ngắm san hô',
        moTa: 'Trải nghiệm lặn biển ngắm san hô đầy màu sắc tại vùng biển Vũng Tàu. Hướng dẫn viên chuyên nghiệp sẽ hỗ trợ bạn trong suốt hành trình.',
        gia: 800000,
        diaDiem: 'Vũng Tàu',
        diaChi: 'Bãi Sau, Vũng Tàu',
        thoiLuong: 180, // 3 giờ
        gioBatDau: '09:00',
        hinhAnh: 'https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=800',
        danhGia: 4.7,
        soLuongDanhGia: 89,
        loaiHoatDong: 'Trải nghiệm',
        soNguoiToiDa: 10,
        soNguoiToiThieu: 1,
      ),
      Activity(
        id: 4,
        ten: 'Chèo thuyền kayak',
        moTa: 'Chèo thuyền kayak khám phá vịnh Vũng Tàu. Hoạt động phù hợp cho cả gia đình, mang lại trải nghiệm thú vị và gần gũi với thiên nhiên.',
        gia: 300000,
        diaDiem: 'Vũng Tàu',
        diaChi: 'Bãi Trước, Vũng Tàu',
        thoiLuong: 120, // 2 giờ
        gioBatDau: '07:00',
        hinhAnh: 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=800',
        danhGia: 4.6,
        soLuongDanhGia: 142,
        loaiHoatDong: 'Trải nghiệm',
        soNguoiToiDa: 20,
        soNguoiToiThieu: 1,
      ),
      Activity(
        id: 5,
        ten: 'Tham quan Bạch Dinh',
        moTa: 'Tham quan Bạch Dinh - dinh thự cổ kính của vua Bảo Đại. Tìm hiểu về lịch sử và văn hóa Việt Nam qua các hiện vật trưng bày.',
        gia: 40000,
        diaDiem: 'Vũng Tàu',
        diaChi: 'Số 4 Trần Phú, Vũng Tàu',
        thoiLuong: 90, // 1.5 giờ
        gioBatDau: '08:00',
        hinhAnh: 'https://images.unsplash.com/photo-1515542622106-78bda8ba0e5b?w=800',
        danhGia: 4.3,
        soLuongDanhGia: 95,
        loaiHoatDong: 'Vé tham quan',
        soNguoiToiDa: 40,
        soNguoiToiThieu: 1,
      ),
      Activity(
        id: 6,
        ten: 'Xem hoàng hôn tại Núi Lớn',
        moTa: 'Ngắm hoàng hôn tuyệt đẹp từ đỉnh Núi Lớn. Trải nghiệm khó quên với khung cảnh thiên nhiên hùng vĩ và không khí trong lành.',
        gia: 0,
        diaDiem: 'Vũng Tàu',
        diaChi: 'Núi Lớn, Vũng Tàu',
        thoiLuong: 60, // 1 giờ
        gioBatDau: '17:00',
        hinhAnh: 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800',
        danhGia: 4.9,
        soLuongDanhGia: 203,
        loaiHoatDong: 'Trải nghiệm',
        soNguoiToiDa: 100,
        soNguoiToiThieu: 1,
      ),
    ];
  }
}

