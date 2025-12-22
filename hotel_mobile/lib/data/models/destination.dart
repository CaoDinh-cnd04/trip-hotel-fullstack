import '../../core/utils/image_url_helper.dart';

/// Model đại diện cho điểm đến/địa điểm du lịch
/// 
/// Chứa thông tin:
/// - Thông tin cơ bản: id, tên, quốc gia, mô tả, hình ảnh
/// - Thống kê: số khách sạn, giá trung bình
class Destination {
  final String id;
  final String ten;
  final String quocGia;
  final String moTa;
  final String hinhAnh;
  final int soKhachSan;
  final double giaTb;

  Destination({
    required this.id,
    required this.ten,
    required this.quocGia,
    required this.moTa,
    required this.hinhAnh,
    required this.soKhachSan,
    required this.giaTb,
  });

  /// Tạo đối tượng Destination từ JSON
  /// 
  /// [json] - Map chứa dữ liệu JSON từ API
  /// 
  /// Xử lý:
  /// - Chuẩn hóa đường dẫn hình ảnh cho Android emulator (thay IP thành 10.0.2.2)
  /// - Chuyển đổi an toàn các kiểu dữ liệu số
  factory Destination.fromJson(Map<String, dynamic> json) {
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
    
    return Destination(
      id: json['id']?.toString() ?? '',
      ten: json['ten']?.toString() ?? '',
      quocGia: json['quoc_gia']?.toString() ?? '',
      moTa: json['mo_ta']?.toString() ?? '',
      hinhAnh: imagePath,
      soKhachSan: json['so_khach_san'] ?? 0,
      giaTb: (json['gia_tb'] ?? 0).toDouble(),
    );
  }

  /// Chuyển đổi đối tượng Destination sang JSON
  /// 
  /// Trả về Map chứa tất cả các trường dưới dạng JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ten': ten,
      'quoc_gia': quocGia,
      'mo_ta': moTa,
      'hinh_anh': hinhAnh,
      'so_khach_san': soKhachSan,
      'gia_tb': giaTb,
    };
  }

  @override
  String toString() {
    return 'Destination(id: $id, ten: $ten, quocGia: $quocGia)';
  }

  /// Lấy URL đầy đủ của hình ảnh địa điểm
  /// 
  /// Sử dụng ImageUrlHelper để tạo URL từ đường dẫn hình ảnh
  /// Trả về URL mặc định nếu không có hình ảnh
  String get fullImageUrl {
    return ImageUrlHelper.getLocationImageUrl(hinhAnh);
  }
}
