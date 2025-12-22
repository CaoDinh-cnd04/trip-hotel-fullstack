/// Model đại diện cho khuyến mãi
/// 
/// Chứa thông tin:
/// - Thông tin cơ bản: tên, mô tả, phần trăm giảm giá
/// - Thời gian: ngày bắt đầu, ngày kết thúc
/// - Trạng thái: active/inactive
/// - Thông tin khách sạn: tên, địa chỉ, hình ảnh (nếu khuyến mãi áp dụng cho một khách sạn cụ thể)
class Promotion {
  final int? id;
  final String ten;
  final String? moTa;
  final double phanTramGiam;
  final DateTime ngayBatDau;
  final DateTime ngayKetThuc;
  final bool trangThai;
  final String? hinhAnh;
  final DateTime? ngayTao;
  final DateTime? ngayCapNhat;
  final String? location;
  final String? hotelName;
  final String? hotelAddress;
  final int? khachSanId;
  final String? image;

  Promotion({
    this.id,
    required this.ten,
    this.moTa,
    required this.phanTramGiam,
    required this.ngayBatDau,
    required this.ngayKetThuc,
    this.trangThai = true,
    this.hinhAnh,
    this.ngayTao,
    this.ngayCapNhat,
    this.location,
    this.hotelName,
    this.hotelAddress,
    this.khachSanId,
    this.image,
  });

  /// Tạo đối tượng Promotion từ JSON
  /// 
  /// [json] - Map chứa dữ liệu JSON từ API
  /// 
  /// Hỗ trợ nhiều tên field khác nhau để tương thích với các phiên bản API
  factory Promotion.fromJson(Map<String, dynamic> json) {
    // Helper function để parse date an toàn
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      try {
        if (value is DateTime) return value;
        if (value is String) {
          // Xử lý nhiều format date
          if (value.contains('T')) {
            return DateTime.parse(value);
          } else {
            // Format: "2024-01-01" hoặc "2024/01/01"
            return DateTime.parse(value.replaceAll('/', '-'));
          }
        }
        return null;
      } catch (e) {
        print('⚠️ Error parsing date: $value - $e');
        return null;
      }
    }

    // Helper function để parse double an toàn
    double parseDouble(dynamic value, {double defaultValue = 0.0}) {
      if (value == null) return defaultValue;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        return double.tryParse(value) ?? defaultValue;
      }
      return defaultValue;
    }

    // Helper function để parse int an toàn
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      if (value is double) return value.toInt();
      return null;
    }

    // Helper function để parse bool an toàn (hỗ trợ SQL Server BIT)
    bool parseBool(dynamic value) {
      if (value == null) return false;
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) {
        final lower = value.toLowerCase().trim();
        return lower == 'true' || lower == '1' || lower == 'yes';
      }
      return false;
    }

    // Helper function để parse string an toàn
    String? safeString(dynamic value) {
      if (value == null) return null;
      if (value is String) return value.isEmpty ? null : value;
      return value.toString();
    }

    // Parse tên promotion - hỗ trợ nhiều field names
    final ten = safeString(json['ten']) ?? 
                safeString(json['ten_khuyen_mai']) ?? 
                safeString(json['title']) ?? 
                '';

    // Parse ngày bắt đầu và kết thúc
    final ngayBatDau = parseDate(json['ngay_bat_dau']) ?? DateTime.now();
    final ngayKetThuc = parseDate(json['ngay_ket_thuc']) ?? DateTime.now().add(const Duration(days: 30));

    return Promotion(
      id: parseInt(json['id']),
      ten: ten,
      moTa: safeString(json['mo_ta']) ?? safeString(json['moTa']) ?? safeString(json['description']),
      phanTramGiam: parseDouble(json['phan_tram_giam'] ?? json['phan_tram'] ?? json['discount_percentage']),
      ngayBatDau: ngayBatDau,
      ngayKetThuc: ngayKetThuc,
      trangThai: parseBool(json['trang_thai'] ?? json['trangThai'] ?? json['is_active'] ?? json['active']),
      hinhAnh: safeString(json['hinh_anh']) ?? safeString(json['hinhAnh']) ?? safeString(json['image_url']),
      ngayTao: parseDate(json['ngay_tao'] ?? json['ngayTao'] ?? json['created_at'] ?? json['createdAt']),
      ngayCapNhat: parseDate(json['ngay_cap_nhat'] ?? json['ngayCapNhat'] ?? json['updated_at'] ?? json['updatedAt']),
      location: safeString(json['location']) ?? 
                safeString(json['ten_vi_tri']) ?? 
                safeString(json['ten_tinh_thanh']) ?? 
                safeString(json['vi_tri']) ??
                safeString(json['tinh_thanh']),
      hotelName: safeString(json['hotel_name']) ?? 
                 safeString(json['ten_khach_san']) ?? 
                 safeString(json['hotelName']),
      hotelAddress: safeString(json['hotel_address']) ?? 
                    safeString(json['dia_chi']) ?? 
                    safeString(json['hotelAddress']),
      khachSanId: parseInt(json['khach_san_id'] ?? json['khachSanId'] ?? json['hotel_id'] ?? json['hotelId']),
      image: safeString(json['image']) ?? 
             safeString(json['hotel_image']) ?? 
             safeString(json['hinh_anh']) ??
             safeString(json['image_url']),
    );
  }

  /// Chuyển đổi đối tượng Promotion sang JSON
  /// 
  /// Trả về Map chứa tất cả các trường của Promotion dưới dạng JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ten': ten,
      'mo_ta': moTa,
      'phan_tram_giam': phanTramGiam,
      'ngay_bat_dau': ngayBatDau.toIso8601String(),
      'ngay_ket_thuc': ngayKetThuc.toIso8601String(),
      'trang_thai': trangThai,
      'hinh_anh': hinhAnh,
      'ngay_tao': ngayTao?.toIso8601String(),
      'ngay_cap_nhat': ngayCapNhat?.toIso8601String(),
    };
  }

  /// Tạo bản sao của Promotion với các trường được cập nhật
  /// 
  /// Cho phép cập nhật từng trường riêng lẻ mà không cần tạo mới toàn bộ object
  /// 
  /// Tất cả các tham số đều tùy chọn, nếu không cung cấp sẽ giữ nguyên giá trị cũ
  Promotion copyWith({
    int? id,
    String? ten,
    String? moTa,
    double? phanTramGiam,
    DateTime? ngayBatDau,
    DateTime? ngayKetThuc,
    bool? trangThai,
    String? hinhAnh,
    DateTime? ngayTao,
    DateTime? ngayCapNhat,
    String? location,
    String? hotelName,
    String? hotelAddress,
    int? khachSanId,
    String? image,
  }) {
    return Promotion(
      id: id ?? this.id,
      ten: ten ?? this.ten,
      moTa: moTa ?? this.moTa,
      phanTramGiam: phanTramGiam ?? this.phanTramGiam,
      ngayBatDau: ngayBatDau ?? this.ngayBatDau,
      ngayKetThuc: ngayKetThuc ?? this.ngayKetThuc,
      trangThai: trangThai ?? this.trangThai,
      hinhAnh: hinhAnh ?? this.hinhAnh,
      ngayTao: ngayTao ?? this.ngayTao,
      ngayCapNhat: ngayCapNhat ?? this.ngayCapNhat,
      location: location ?? this.location,
      hotelName: hotelName ?? this.hotelName,
      hotelAddress: hotelAddress ?? this.hotelAddress,
      khachSanId: khachSanId ?? this.khachSanId,
      image: image ?? this.image,
    );
  }

  /// Kiểm tra xem khuyến mãi có đang hoạt động không
  /// 
  /// Trả về true nếu:
  /// - Trạng thái là true (active)
  /// - Thời gian hiện tại nằm trong khoảng từ ngày bắt đầu đến ngày kết thúc
  bool get isActive {
    final now = DateTime.now();
    return trangThai && now.isAfter(ngayBatDau) && now.isBefore(ngayKetThuc);
  }

  /// Lấy text hiển thị phần trăm giảm giá
  /// 
  /// Ví dụ: 20 -> "20% OFF"
  /// Trả về "0% OFF" nếu phần trăm không hợp lệ
  String get discountText {
    if (phanTramGiam.isFinite && !phanTramGiam.isNaN) {
      return '${phanTramGiam.toInt()}% OFF';
    }
    return '0% OFF';
  }

  @override
  String toString() {
    return 'Promotion{id: $id, ten: $ten, phanTramGiam: $phanTramGiam%, isActive: $isActive}';
  }
}
