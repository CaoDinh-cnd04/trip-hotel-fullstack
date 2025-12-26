import 'package:dio/dio.dart';
import '../models/api_response.dart';
import '../../core/constants/app_constants.dart';

/// Model cho tiện nghi khách sạn
class HotelAmenity {
  final int id;
  final String ten;
  final String? nhom;
  final String? icon;
  final String? moTa;
  final bool? mienPhi;
  final double? giaPhi;
  final String? ghiChu;

  HotelAmenity({
    required this.id,
    required this.ten,
    this.nhom,
    this.icon,
    this.moTa,
    this.mienPhi,
    this.giaPhi,
    this.ghiChu,
  });

  factory HotelAmenity.fromJson(Map<String, dynamic> json) {
    return HotelAmenity(
      id: json['id'] ?? 0,
      ten: json['ten'] ?? '',
      nhom: json['nhom'],
      icon: json['icon'],
      moTa: json['mo_ta'],
      mienPhi: json['mien_phi'] == 1 || json['mien_phi'] == true,
      giaPhi: json['gia_phi'] != null ? (json['gia_phi'] is double ? json['gia_phi'] : double.tryParse(json['gia_phi'].toString())) : null,
      ghiChu: json['ghi_chu'],
    );
  }
}

/// Service để lấy danh sách tiện nghi của khách sạn
class HotelAmenityService {
  final Dio _dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));

  /// Lấy danh sách tiện nghi của khách sạn
  /// 
  /// [hotelId] - ID của khách sạn
  /// 
  /// Trả về ApiResponse chứa danh sách HotelAmenity
  Future<ApiResponse<List<HotelAmenity>>> getHotelAmenities(int hotelId) async {
    try {
      final response = await _dio.get(
        '/api/khachsan/$hotelId/tien-nghi',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        final amenities = data.map((json) => HotelAmenity.fromJson(json)).toList();
        
        return ApiResponse<List<HotelAmenity>>(
          success: true,
          data: amenities,
          message: 'Lấy danh sách tiện nghi thành công',
        );
      } else {
        return ApiResponse<List<HotelAmenity>>(
          success: false,
          message: response.data['message'] ?? 'Lỗi tải danh sách tiện nghi',
        );
      }
    } catch (e) {
      print('❌ Lỗi HotelAmenityService.getHotelAmenities: $e');
      return ApiResponse<List<HotelAmenity>>(
        success: false,
        message: 'Lỗi kết nối: $e',
      );
    }
  }
}

