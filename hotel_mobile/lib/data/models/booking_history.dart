/// Model đại diện cho lịch sử đặt phòng
/// 
/// Chứa thông tin:
/// - Thông tin khách sạn: hotelId, hotelName, hotelImage, location
/// - Thông tin đặt phòng: checkInDate, checkOutDate, nights, rooms, adults, children
/// - Thông tin thanh toán: totalAmount
/// - Trạng thái: status (pending/confirmed/cancelled/completed), canCancel, cancellationReason
/// - Thời gian: createdAt, updatedAt
class BookingHistory {
  final String id;
  final String hotelId;
  final String hotelName;
  final String? hotelImage;
  final String location;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int nights;
  final int rooms;
  final int adults;
  final int children;
  final double totalAmount;
  final String status; // 'pending', 'confirmed', 'cancelled', 'completed'
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? cancellationReason;
  final bool canCancel;

  BookingHistory({
    required this.id,
    required this.hotelId,
    required this.hotelName,
    this.hotelImage,
    required this.location,
    required this.checkInDate,
    required this.checkOutDate,
    required this.nights,
    required this.rooms,
    required this.adults,
    required this.children,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.cancellationReason,
    required this.canCancel,
  });

  /// Tạo đối tượng BookingHistory từ JSON
  /// 
  /// [json] - Map chứa dữ liệu JSON từ API
  /// 
  /// Parse các trường từ snake_case sang camelCase
  /// Xử lý parse DateTime và boolean
  factory BookingHistory.fromJson(Map<String, dynamic> json) {
    return BookingHistory(
      id: json['id']?.toString() ?? '',
      hotelId: json['hotel_id']?.toString() ?? '',
      hotelName: json['hotel_name'] ?? '',
      hotelImage: json['hotel_image'],
      location: json['location'] ?? '',
      checkInDate: DateTime.parse(json['check_in_date']),
      checkOutDate: DateTime.parse(json['check_out_date']),
      nights: json['nights'] ?? 0,
      rooms: json['rooms'] ?? 1,
      adults: json['adults'] ?? 1,
      children: json['children'] ?? 0,
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      cancellationReason: json['cancellation_reason'],
      canCancel: json['can_cancel'] == true || json['status'] == 'pending',
    );
  }

  /// Chuyển đổi đối tượng BookingHistory sang JSON
  /// 
  /// Trả về Map chứa tất cả các trường dưới dạng JSON (snake_case)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hotel_id': hotelId,
      'hotel_name': hotelName,
      'hotel_image': hotelImage,
      'location': location,
      'check_in_date': checkInDate.toIso8601String(),
      'check_out_date': checkOutDate.toIso8601String(),
      'nights': nights,
      'rooms': rooms,
      'adults': adults,
      'children': children,
      'total_amount': totalAmount,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'cancellation_reason': cancellationReason,
      'can_cancel': canCancel,
    };
  }

  /// Lấy text hiển thị trạng thái đặt phòng bằng tiếng Việt
  /// 
  /// Trả về: "Chờ xác nhận", "Đã xác nhận", "Đã hủy", "Hoàn thành", hoặc "Không xác định"
  String get statusText {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Chờ xác nhận';
      case 'confirmed':
        return 'Đã xác nhận';
      case 'cancelled':
        return 'Đã hủy';
      case 'completed':
        return 'Hoàn thành';
      default:
        return 'Không xác định';
    }
  }

  /// Lấy màu hiển thị cho trạng thái đặt phòng
  /// 
  /// Trả về tên màu: "orange" (pending), "green" (confirmed), "red" (cancelled), "blue" (completed), "grey" (default)
  String get statusColor {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'orange';
      case 'confirmed':
        return 'green';
      case 'cancelled':
        return 'red';
      case 'completed':
        return 'blue';
      default:
        return 'grey';
    }
  }
}
