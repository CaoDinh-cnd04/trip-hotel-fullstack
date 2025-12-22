/// Model đại diện cho đánh giá/nhận xét khách sạn
/// 
/// Chứa thông tin:
/// - Thông tin booking: bookingId, hotelId, hotelName, hotelImage
/// - Thông tin đặt phòng: location, roomType, checkInDate, checkOutDate, nights
/// - Thông tin đánh giá: isReviewed, rating, content, reviewedAt
class Review {
  final String id;
  final String bookingId;
  final String hotelId;
  final String hotelName;
  final String? hotelImage;
  final String location;
  final String roomType;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int nights;
  final bool isReviewed;
  final int? rating;
  final String? content;
  final DateTime? reviewedAt;

  Review({
    required this.id,
    required this.bookingId,
    required this.hotelId,
    required this.hotelName,
    this.hotelImage,
    required this.location,
    required this.roomType,
    required this.checkInDate,
    required this.checkOutDate,
    required this.nights,
    required this.isReviewed,
    this.rating,
    this.content,
    this.reviewedAt,
  });

  /// Tạo đối tượng Review từ JSON
  /// 
  /// [json] - Map chứa dữ liệu JSON từ API
  /// 
  /// Parse các trường từ snake_case sang camelCase
  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id']?.toString() ?? '',
      bookingId: json['booking_id']?.toString() ?? '',
      hotelId: json['hotel_id']?.toString() ?? '',
      hotelName: json['hotel_name'] ?? '',
      hotelImage: json['hotel_image'],
      location: json['location'] ?? '',
      roomType: json['room_type'] ?? '',
      checkInDate: DateTime.parse(json['check_in_date']),
      checkOutDate: DateTime.parse(json['check_out_date']),
      nights: json['nights'] ?? 0,
      isReviewed: json['is_reviewed'] == 1 || json['is_reviewed'] == true,
      rating: json['rating'],
      content: json['content'],
      reviewedAt: json['reviewed_at'] != null ? DateTime.parse(json['reviewed_at']) : null,
    );
  }

  /// Chuyển đổi đối tượng Review sang JSON
  /// 
  /// Trả về Map chứa tất cả các trường dưới dạng JSON (snake_case)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'hotel_id': hotelId,
      'hotel_name': hotelName,
      'hotel_image': hotelImage,
      'location': location,
      'room_type': roomType,
      'check_in_date': checkInDate.toIso8601String(),
      'check_out_date': checkOutDate.toIso8601String(),
      'nights': nights,
      'is_reviewed': isReviewed ? 1 : 0,
      'rating': rating,
      'content': content,
      'reviewed_at': reviewedAt?.toIso8601String(),
    };
  }
}
