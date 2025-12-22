/// Model đại diện cho tình trạng sẵn có của loại phòng
/// 
/// Chứa thông tin:
/// - Thông tin phòng: maLoaiPhong, tenLoaiPhong, giaCoban, soKhachToiDa
/// - Tình trạng phòng: totalRooms, bookedRooms, availableRooms
/// - Cảnh báo: isLowAvailability, isSoldOut, warning
class RoomAvailability {
  final String maLoaiPhong;
  final String tenLoaiPhong;
  final double giaCoban;
  final int soKhachToiDa;
  final int totalRooms;
  final int bookedRooms;
  final int availableRooms;
  final bool isLowAvailability;
  final bool isSoldOut;
  final String? warning;

  RoomAvailability({
    required this.maLoaiPhong,
    required this.tenLoaiPhong,
    required this.giaCoban,
    required this.soKhachToiDa,
    required this.totalRooms,
    required this.bookedRooms,
    required this.availableRooms,
    required this.isLowAvailability,
    required this.isSoldOut,
    this.warning,
  });

  /// Tạo đối tượng RoomAvailability từ JSON
  /// 
  /// [json] - Map chứa dữ liệu JSON từ API
  /// 
  /// Parse các trường từ snake_case sang camelCase
  /// Chuyển đổi an toàn các kiểu dữ liệu số
  factory RoomAvailability.fromJson(Map<String, dynamic> json) {
    return RoomAvailability(
      maLoaiPhong: json['ma_loai_phong']?.toString() ?? '',
      tenLoaiPhong: json['ten_loai_phong']?.toString() ?? '',
      giaCoban: (json['gia_co_ban'] ?? 0).toDouble(),
      soKhachToiDa: json['so_khach_toi_da'] ?? 0,
      totalRooms: json['total_rooms'] ?? 0,
      bookedRooms: json['booked_rooms'] ?? 0,
      availableRooms: json['available_rooms'] ?? 0,
      isLowAvailability: json['is_low_availability'] == 1,
      isSoldOut: json['is_sold_out'] == 1,
      warning: json['warning']?.toString(),
    );
  }

  /// Lấy giá phòng đã được format (đơn vị: nghìn VNĐ)
  /// 
  /// Ví dụ: 500000 -> "500K VNĐ"
  String get formattedPrice {
    return '${(giaCoban / 1000).toStringAsFixed(0)}K VNĐ';
  }

  /// Lấy text hiển thị trạng thái phòng bằng tiếng Việt
  /// 
  /// Trả về: "Hết phòng", "Sắp hết", hoặc "Còn phòng"
  String get availabilityStatus {
    if (isSoldOut) return 'Hết phòng';
    if (isLowAvailability) return 'Sắp hết';
    return 'Còn phòng';
  }

  /// Tính tỷ lệ lấp đầy phòng (tính bằng phần trăm)
  /// 
  /// Trả về tỷ lệ bookedRooms / totalRooms * 100, hoặc 0 nếu totalRooms = 0
  double get occupancyRate {
    if (totalRooms == 0) return 0;
    return (bookedRooms / totalRooms * 100);
  }
}

/// Model đại diện cho response của API kiểm tra availability khách sạn
/// 
/// Chứa:
/// - success: Trạng thái thành công/thất bại
/// - message: Thông báo từ server
/// - rooms: Danh sách RoomAvailability của tất cả loại phòng
/// - warnings: Danh sách cảnh báo (nếu có)
class HotelAvailabilityResponse {
  final bool success;
  final String message;
  final List<RoomAvailability> rooms;
  final List<String>? warnings;

  HotelAvailabilityResponse({
    required this.success,
    required this.message,
    required this.rooms,
    this.warnings,
  });

  /// Tạo đối tượng HotelAvailabilityResponse từ JSON
  /// 
  /// [json] - Map chứa dữ liệu JSON từ API
  /// 
  /// Parse danh sách rooms từ field 'data'
  factory HotelAvailabilityResponse.fromJson(Map<String, dynamic> json) {
    return HotelAvailabilityResponse(
      success: json['success'] ?? false,
      message: json['message']?.toString() ?? '',
      rooms: (json['data'] as List?)
              ?.map((room) => RoomAvailability.fromJson(room))
              .toList() ??
          [],
      warnings: (json['warnings'] as List?)?.map((w) => w.toString()).toList(),
    );
  }
}

