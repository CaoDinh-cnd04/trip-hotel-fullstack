import 'dart:io';

/// Model đại diện cho thông tin đăng ký khách sạn (dùng khi submit form)
/// 
/// Chứa thông tin:
/// - Thông tin khách sạn: hotelName, address, province, district, starRating
/// - Liên hệ: phone, email, website
/// - Mô tả: description
/// - Hình ảnh: images (List<File>)
class HotelRegistration {
  final String hotelName;
  final String address;
  final String province;
  final String district;
  final String phone;
  final String email;
  final String description;
  final String website;
  final int starRating;
  final List<File> images;

  HotelRegistration({
    required this.hotelName,
    required this.address,
    required this.province,
    required this.district,
    required this.phone,
    required this.email,
    required this.description,
    required this.website,
    required this.starRating,
    required this.images,
  });

  /// Chuyển đổi đối tượng HotelRegistration sang JSON
  /// 
  /// Trả về Map chứa tất cả các trường dưới dạng JSON (snake_case)
  /// Lưu ý: images chỉ trả về số lượng, không trả về File objects
  Map<String, dynamic> toJson() {
    return {
      'hotel_name': hotelName,
      'address': address,
      'province': province,
      'district': district,
      'phone': phone,
      'email': email,
      'description': description,
      'website': website,
      'star_rating': starRating,
      'images_count': images.length,
    };
  }
}
