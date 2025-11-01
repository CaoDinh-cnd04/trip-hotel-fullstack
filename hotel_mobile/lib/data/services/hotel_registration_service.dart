import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import 'package:http_parser/http_parser.dart';

/// Service xử lý đăng ký khách sạn
class HotelRegistrationService {
  static final HotelRegistrationService _instance = HotelRegistrationService._internal();
  factory HotelRegistrationService() => _instance;
  HotelRegistrationService._internal();

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.baseUrl,
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  /// Tạo đơn đăng ký khách sạn mới
  /// 
  /// Gửi thông tin đăng ký khách sạn lên server
  /// Chủ khách sạn điền form → API lưu vào database → Admin xem xét
  /// 
  /// Parameters:
  ///   - ownerName: Tên chủ khách sạn
  ///   - ownerEmail: Email liên hệ
  ///   - ownerPhone: Số điện thoại
  ///   - hotelName: Tên khách sạn
  ///   - hotelType: Loại hình (hotel, motel, apartment, homestay, resort, villa)
  ///   - address: Địa chỉ chi tiết
  ///   - provinceId: ID tỉnh/thành phố
  ///   - district: Quận/huyện (optional)
  ///   - latitude, longitude: Tọa độ GPS (optional)
  ///   - description: Mô tả khách sạn (optional)
  ///   - starRating: Hạng sao 1-5 (optional)
  ///   - taxId: Mã số thuế (optional)
  ///   - businessLicense: Giấy phép kinh doanh (optional)
  /// 
  /// Returns: HotelRegistrationResult chứa thông tin thành công/lỗi
  Future<HotelRegistrationResult> createRegistration({
    required String ownerName,
    required String ownerEmail,
    required String ownerPhone,
    required String hotelName,
    required String hotelType,
    required String address,
    required int provinceId,
    String? district,
    double? latitude,
    double? longitude,
    String? description,
    int? starRating,
    String? taxId,
    String? businessLicense,
    // Thông tin liên hệ
    String? contactEmail,
    String? contactPhone,
    String? website,
    // Chính sách
    String? checkInTime,
    String? checkOutTime,
    bool? requireDeposit,
    double? depositRate,
    String? cancellationPolicy,
    // Thông tin bổ sung
    int? totalRooms,
    // Danh sách phòng
    List<Map<String, dynamic>>? rooms,
    // Tiện nghi
    List<String>? hotelAmenities,
  }) async {
    try {
      print('📝 Đang tạo đơn đăng ký khách sạn: $hotelName');

      final response = await _dio.post(
        '/api/v2/hotel-registration',
        data: {
          'owner_name': ownerName,
          'owner_email': ownerEmail.toLowerCase(),
          'owner_phone': ownerPhone,
          'hotel_name': hotelName,
          'hotel_type': hotelType,
          'address': address,
          'province_id': provinceId,
          'district': district,
          'latitude': latitude,
          'longitude': longitude,
          'description': description,
          'star_rating': starRating,
          'tax_id': taxId,
          'business_license': businessLicense,
          // New fields
          'contact_email': contactEmail,
          'contact_phone': contactPhone,
          'website': website,
          'check_in_time': checkInTime,
          'check_out_time': checkOutTime,
          'require_deposit': requireDeposit,
          'deposit_rate': depositRate,
          'cancellation_policy': cancellationPolicy,
          'total_rooms': totalRooms,
          'rooms': rooms, // Danh sách loại phòng (JSON array)
          'hotel_amenities': hotelAmenities, // Tiện nghi khách sạn
        },
      );

      if (response.data['success'] == true) {
        print('✅ Đăng ký khách sạn thành công');
        return HotelRegistrationResult.success(
          message: response.data['message'] ?? 'Đăng ký thành công',
          registrationId: response.data['data']?['registration_id'],
        );
      } else {
        return HotelRegistrationResult.error(
          response.data['message'] ?? 'Đăng ký thất bại',
        );
      }
    } catch (e) {
      print('❌ Lỗi đăng ký khách sạn: $e');
      if (e is DioException) {
        if (e.response?.statusCode == 400) {
          return HotelRegistrationResult.error(
            e.response?.data['message'] ?? 'Dữ liệu không hợp lệ',
          );
        } else if (e.response?.statusCode == 500) {
          return HotelRegistrationResult.error('Lỗi server. Vui lòng thử lại sau.');
        }
      }
      return HotelRegistrationResult.error('Lỗi kết nối: $e');
    }
  }

  /// Tạo đơn đăng ký với upload ảnh
  /// 
  /// Upload ảnh khách sạn và phòng cùng với data đăng ký
  /// Sử dụng multipart/form-data để gửi files
  /// 
  /// Parameters:
  ///   - registrationData: Map chứa tất cả thông tin đăng ký
  ///   - hotelImages: List các file ảnh khách sạn
  ///   - roomImages: List các file ảnh phòng
  /// 
  /// Returns: HotelRegistrationResult
  Future<HotelRegistrationResult> createRegistrationWithImages({
    required Map<String, dynamic> registrationData,
    required List<File> hotelImages,
    required List<File> roomImages,
  }) async {
    try {
      print('📸 Uploading registration with ${hotelImages.length} hotel images and ${roomImages.length} room images');

      // Create FormData
      final formData = FormData();

      // Add registration data as JSON string
      formData.fields.add(MapEntry('registration_data', jsonEncode(registrationData)));

      // Add hotel images
      for (int i = 0; i < hotelImages.length; i++) {
        final file = hotelImages[i];
        final fileName = file.path.split('/').last;
        formData.files.add(MapEntry(
          'hotel_images',
          await MultipartFile.fromFile(
            file.path,
            filename: fileName,
            contentType: MediaType('image', 'jpeg'),
          ),
        ));
      }

      // Add room images
      for (int i = 0; i < roomImages.length; i++) {
        final file = roomImages[i];
        final fileName = file.path.split('/').last;
        formData.files.add(MapEntry(
          'room_images',
          await MultipartFile.fromFile(
            file.path,
            filename: fileName,
            contentType: MediaType('image', 'jpeg'),
          ),
        ));
      }

      print('📤 Sending multipart request...');
      final response = await _dio.post(
        '/api/v2/hotel-registration/with-images',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      if (response.data['success'] == true) {
        print('✅ Upload thành công!');
        return HotelRegistrationResult.success(
          message: response.data['message'] ?? 'Đăng ký thành công',
          registrationId: response.data['data']?['registration_id'],
        );
      } else {
        return HotelRegistrationResult.error(
          response.data['message'] ?? 'Đăng ký thất bại',
        );
      }
    } catch (e) {
      print('❌ Lỗi upload: $e');
      if (e is DioException) {
        if (e.response?.statusCode == 400) {
          return HotelRegistrationResult.error(
            e.response?.data['message'] ?? 'Dữ liệu không hợp lệ',
          );
        } else if (e.response?.statusCode == 500) {
          return HotelRegistrationResult.error('Lỗi server. Vui lòng thử lại sau.');
        }
      }
      return HotelRegistrationResult.error('Lỗi kết nối: $e');
    }
  }

  /// Lấy danh sách đơn đăng ký của user hiện tại
  /// 
  /// Xem tất cả các đơn đăng ký khách sạn mà user này đã gửi
  /// Cần có token để xác thực
  /// 
  /// Parameters:
  ///   - token: JWT token từ đăng nhập
  /// 
  /// Returns: Danh sách các đơn đăng ký (có thể rỗng)
  Future<List<HotelRegistration>> getMyRegistrations(String token) async {
    try {
      final response = await _dio.get(
        '/api/v2/hotel-registration/my-registrations',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((json) => HotelRegistration.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Lỗi lấy danh sách đơn đăng ký: $e');
      return [];
    }
  }

  /// Lấy tất cả đơn đăng ký (Admin)
  /// 
  /// Chỉ dành cho Admin - Xem tất cả đơn đăng ký khách sạn trong hệ thống
  /// Có thể filter theo trạng thái: pending, approved, rejected
  /// 
  /// Parameters:
  ///   - token: JWT token của Admin
  ///   - status: Filter theo trạng thái (optional)
  /// 
  /// Returns: Danh sách tất cả đơn đăng ký
  Future<List<HotelRegistration>> getAllRegistrations(String token, {String? status}) async {
    try {
      final queryParams = status != null ? '?status=$status' : '';
      
      final response = await _dio.get(
        '/api/v2/hotel-registration/admin/all$queryParams',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((json) => HotelRegistration.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Lỗi lấy tất cả đơn đăng ký: $e');
      return [];
    }
  }

  /// Cập nhật trạng thái đơn đăng ký (Admin)
  /// 
  /// Chỉ Admin mới có quyền - Duyệt hoặc từ chối đơn đăng ký
  /// Khi duyệt (approved): Hệ thống tự động tạo tài khoản Hotel Manager cho chủ khách sạn
  /// Khi từ chối (rejected): Gửi email thông báo kèm lý do
  /// 
  /// Parameters:
  ///   - registrationId: ID của đơn đăng ký
  ///   - status: Trạng thái mới (approved, rejected, pending)
  ///   - token: JWT token của Admin
  ///   - adminNote: Ghi chú từ admin (optional, bắt buộc nếu rejected)
  /// 
  /// Returns: true nếu cập nhật thành công, false nếu thất bại
  Future<bool> updateRegistrationStatus({
    required int registrationId,
    required String status,
    required String token,
    String? adminNote,
  }) async {
    try {
      final response = await _dio.put(
        '/api/v2/hotel-registration/$registrationId/status',
        data: {
          'status': status,
          'admin_note': adminNote,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      return response.data['success'] == true;
    } catch (e) {
      print('❌ Lỗi cập nhật trạng thái: $e');
      return false;
    }
  }

  /// Cập nhật thông tin đơn đăng ký
  /// 
  /// Chỉnh sửa thông tin của đơn đăng ký đã gửi
  /// Chỉ chủ đơn hoặc Admin mới có quyền chỉnh sửa
  /// 
  /// Parameters:
  ///   - registrationId: ID của đơn đăng ký cần sửa
  ///   - updateData: Map chứa các field cần cập nhật
  ///   - token: JWT token để xác thực
  /// 
  /// Returns: true nếu cập nhật thành công
  Future<bool> updateRegistration({
    required int registrationId,
    required Map<String, dynamic> updateData,
    required String token,
  }) async {
    try {
      final response = await _dio.put(
        '/api/v2/hotel-registration/$registrationId',
        data: updateData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      return response.data['success'] == true;
    } catch (e) {
      print('❌ Lỗi cập nhật đơn đăng ký: $e');
      return false;
    }
  }
}

/// Model cho đơn đăng ký khách sạn
class HotelRegistration {
  final int id;
  final String ownerName;
  final String ownerEmail;
  final String ownerPhone;
  final String hotelName;
  final String hotelType;
  final String address;
  final int provinceId;
  final String? provinceName;
  final String? district;
  final double? latitude;
  final double? longitude;
  final String? description;
  final int? starRating;
  final String? taxId;
  final String? businessLicense;
  final String status;
  final String? adminNote;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? reviewedAt;
  // ✅ NEW: Additional fields
  final String? website;
  final String? checkInTime;
  final String? checkOutTime;
  final int? totalRooms;
  final dynamic roomsData; // Can be List or String (JSON)
  final List<String>? hotelImages; // List of hotel image paths
  final List<String>? roomImages; // List of room image paths

  HotelRegistration({
    required this.id,
    required this.ownerName,
    required this.ownerEmail,
    required this.ownerPhone,
    required this.hotelName,
    required this.hotelType,
    required this.address,
    required this.provinceId,
    this.provinceName,
    this.district,
    this.latitude,
    this.longitude,
    this.description,
    this.starRating,
    this.taxId,
    this.businessLicense,
    required this.status,
    this.adminNote,
    required this.createdAt,
    this.updatedAt,
    this.reviewedAt,
    // ✅ NEW fields
    this.website,
    this.checkInTime,
    this.checkOutTime,
    this.totalRooms,
    this.roomsData,
    this.hotelImages,
    this.roomImages,
  });

  /// Chuyển đổi JSON từ API thành object HotelRegistration
  /// 
  /// Nhận JSON response từ server và parse thành Dart object
  /// Xử lý null safety và type conversion
  factory HotelRegistration.fromJson(Map<String, dynamic> json) {
    // Parse rooms_data nếu là string JSON
    dynamic roomsData;
    if (json['rooms_data'] != null) {
      if (json['rooms_data'] is String) {
        try {
          roomsData = jsonDecode(json['rooms_data']); // ✅ FIX: Use jsonDecode() from dart:convert
        } catch (e) {
          print('⚠️ Error parsing rooms_data JSON: $e');
          roomsData = json['rooms_data']; // Keep as string
        }
      } else {
        roomsData = json['rooms_data']; // Already parsed
      }
    }

    return HotelRegistration(
      id: json['id'],
      ownerName: json['owner_name'] ?? '',
      ownerEmail: json['owner_email'] ?? '',
      ownerPhone: json['owner_phone'] ?? '',
      hotelName: json['hotel_name'] ?? '',
      hotelType: json['hotel_type'] ?? '',
      address: json['address'] ?? '',
      provinceId: json['province_id'],
      provinceName: json['province_name'],
      district: json['district'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      description: json['description'],
      starRating: json['star_rating'],
      taxId: json['tax_id'],
      businessLicense: json['business_license'],
      status: json['status'] ?? 'pending',
      adminNote: json['admin_note'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      reviewedAt: json['reviewed_at'] != null ? DateTime.parse(json['reviewed_at']) : null,
      // ✅ NEW fields
      website: json['website'],
      checkInTime: json['check_in_time'],
      checkOutTime: json['check_out_time'],
      totalRooms: json['total_rooms'],
      roomsData: roomsData,
      hotelImages: json['hotel_images'] != null 
          ? List<String>.from(jsonDecode(json['hotel_images']))
          : null,
      roomImages: json['room_images'] != null
          ? List<String>.from(jsonDecode(json['room_images']))
          : null,
    );
  }

  /// Chuyển đổi status code thành text tiếng Việt hiển thị
  /// 
  /// pending → "Đang chờ duyệt"
  /// approved → "Đã duyệt"  
  /// rejected → "Từ chối"
  /// completed → "Hoàn thành"
  String get statusText {
    switch (status) {
      case 'pending':
        return 'Đang chờ duyệt';
      case 'approved':
        return 'Đã duyệt';
      case 'rejected':
        return 'Từ chối';
      case 'completed':
        return 'Hoàn thành';
      default:
        return status;
    }
  }

  /// Chuyển đổi hotel type code thành text tiếng Việt
  /// 
  /// hotel → "Khách sạn"
  /// motel → "Nhà nghỉ"
  /// apartment → "Căn hộ"
  /// homestay → "Homestay"
  /// resort → "Resort"
  /// villa → "Villa"
  String get hotelTypeText {
    switch (hotelType) {
      case 'hotel':
        return 'Khách sạn';
      case 'motel':
        return 'Nhà nghỉ';
      case 'apartment':
        return 'Căn hộ';
      case 'homestay':
        return 'Homestay';
      case 'resort':
        return 'Resort';
      case 'villa':
        return 'Villa';
      default:
        return hotelType;
    }
  }
}

/// Kết quả đăng ký khách sạn
class HotelRegistrationResult {
  final bool isSuccess;
  final String? message;
  final int? registrationId;
  final String? error;

  HotelRegistrationResult._({
    required this.isSuccess,
    this.message,
    this.registrationId,
    this.error,
  });

  /// Getter để check success (alias cho isSuccess)
  bool get success => isSuccess;

  /// Tạo kết quả thành công
  /// 
  /// Dùng khi đăng ký khách sạn thành công
  /// Chứa message thông báo và registration ID
  factory HotelRegistrationResult.success({
    String? message,
    int? registrationId,
  }) {
    return HotelRegistrationResult._(
      isSuccess: true,
      message: message,
      registrationId: registrationId,
    );
  }

  /// Tạo kết quả lỗi
  /// 
  /// Dùng khi đăng ký thất bại
  /// Chứa error message để hiển thị cho user
  factory HotelRegistrationResult.error(String error) {
    return HotelRegistrationResult._(
      isSuccess: false,
      error: error,
    );
  }
}

