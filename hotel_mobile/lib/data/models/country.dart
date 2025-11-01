import '../../core/utils/image_url_helper.dart';

class Country {
  final String id;
  final String ten;
  final String moTa;
  final String hinhAnh;
  final int soKhachSan;
  final int soTinhThanh;

  Country({
    required this.id,
    required this.ten,
    required this.moTa,
    required this.hinhAnh,
    required this.soKhachSan,
    required this.soTinhThanh,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    // Get image path and normalize for Android emulator
    String imagePath = json['hinh_anh']?.toString() ?? '';
    
    // If API returns full URL with different IP, replace with emulator IP
    if (imagePath.contains('://')) {
      // Replace any IP address with 10.0.2.2 for Android emulator
      imagePath = imagePath.replaceFirst(
        RegExp(r'://[^:]+:'),
        '://10.0.2.2:',
      );
    }
    
    return Country(
      id: json['id']?.toString() ?? '',
      ten: json['ten']?.toString() ?? '',
      moTa: json['mo_ta']?.toString() ?? '',
      hinhAnh: imagePath,
      soKhachSan: json['so_khach_san'] ?? 0,
      soTinhThanh: json['so_tinh_thanh'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ten': ten,
      'mo_ta': moTa,
      'hinh_anh': hinhAnh,
      'so_khach_san': soKhachSan,
      'so_tinh_thanh': soTinhThanh,
    };
  }

  @override
  String toString() {
    return 'Country(id: $id, ten: $ten)';
  }

  /// Get full image URL
  String get fullImageUrl {
    return ImageUrlHelper.getCountryImageUrl(hinhAnh);
  }
}
