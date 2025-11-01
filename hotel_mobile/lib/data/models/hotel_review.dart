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


