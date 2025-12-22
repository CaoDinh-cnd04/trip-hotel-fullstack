/// Model đại diện cho đánh giá khách sạn từ khách hàng
/// 
/// Chứa thông tin:
/// - Đánh giá: rating (1-5 sao), content, reviewDate
/// - Phản hồi khách sạn: hotelResponse, responseDate
/// - Thông tin khách hàng: customerName, customerAvatar, roomNumber
class HotelReview {
  final int id;
  final int rating;
  final String content;
  final DateTime reviewDate;
  final String? hotelResponse;
  final DateTime? responseDate;
  final String customerName;
  final String? customerAvatar;
  final String roomNumber;

  HotelReview({
    required this.id,
    required this.rating,
    required this.content,
    required this.reviewDate,
    this.hotelResponse,
    this.responseDate,
    required this.customerName,
    this.customerAvatar,
    required this.roomNumber,
  });

  /// Tạo đối tượng HotelReview từ JSON
  /// 
  /// [json] - Map chứa dữ liệu JSON từ API
  /// 
  /// Xử lý:
  /// - Hỗ trợ cả tiếng Anh và tiếng Việt cho field names
  /// - Parse DateTime an toàn với null safety
  /// - Xử lý các giá trị mặc định
  factory HotelReview.fromJson(Map<String, dynamic> json) {
    // Parse date with null safety
    DateTime parseDate(dynamic dateValue) {
      if (dateValue == null) return DateTime.now();
      try {
        if (dateValue is String) {
          return DateTime.parse(dateValue);
        } else if (dateValue is DateTime) {
          return dateValue;
        }
        return DateTime.now();
      } catch (e) {
        return DateTime.now();
      }
    }

    return HotelReview(
      id: json['id'] ?? 0,
      rating: json['rating'] ?? json['so_sao_tong'] ?? 0,
      content: json['content']?.toString() ?? json['binh_luan']?.toString() ?? '',
      reviewDate: parseDate(json['review_date'] ?? json['ngay'] ?? json['reviewed_at']),
      hotelResponse: json['hotel_response']?.toString() ?? json['phan_hoi_khach_san']?.toString(),
      responseDate: json['response_date'] != null || json['ngay_phan_hoi'] != null
          ? parseDate(json['response_date'] ?? json['ngay_phan_hoi'])
          : null,
      customerName: json['customer_name']?.toString() ?? 
                   json['ten_khach_hang']?.toString() ?? 
                   'Khách hàng',
      customerAvatar: json['customer_avatar']?.toString() ?? json['anh_dai_dien']?.toString(),
      roomNumber: json['room_number']?.toString() ?? json['so_phong']?.toString() ?? 'N/A',
    );
  }
}


