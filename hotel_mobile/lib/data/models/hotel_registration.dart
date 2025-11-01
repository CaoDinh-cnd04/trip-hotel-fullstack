import 'dart:io';

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
