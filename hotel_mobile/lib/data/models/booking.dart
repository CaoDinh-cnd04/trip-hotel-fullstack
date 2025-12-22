/// Enum đại diện cho các trạng thái đặt phòng
enum BookingStatus {
  pending, // Chờ xác nhận
  confirmed, // Đã xác nhận
  checkedIn, // Đã check-in
  checkedOut, // Đã check-out
  cancelled, // Đã hủy
}

/// Model đại diện cho đặt phòng (booking)
/// 
/// Chứa thông tin:
/// - Thông tin đặt phòng: người dùng, phòng, ngày nhận/trả, số khách, tổng tiền
/// - Trạng thái: pending, confirmed, checkedIn, checkedOut, cancelled
/// - Thông tin từ bảng liên kết: tên người dùng, email, tên khách sạn, loại phòng
class Booking {
  final int? id;
  final int nguoiDungId;
  final int phongId;
  final DateTime ngayNhanPhong;
  final DateTime ngayTraPhong;
  final int soLuongKhach;
  final double tongTien;
  final BookingStatus trangThai;
  final String? ghiChu;
  final DateTime? ngayTao;
  final DateTime? ngayCapNhat;

  // Thông tin từ bảng liên kết
  final String? tenNguoiDung;
  final String? emailNguoiDung;
  final String? soDienThoai;
  final String? soPhong;
  final String? tenKhachSan;
  final String? tenLoaiPhong;
  final double? giaPhong;

  Booking({
    this.id,
    required this.nguoiDungId,
    required this.phongId,
    required this.ngayNhanPhong,
    required this.ngayTraPhong,
    required this.soLuongKhach,
    required this.tongTien,
    this.trangThai = BookingStatus.pending,
    this.ghiChu,
    this.ngayTao,
    this.ngayCapNhat,
    this.tenNguoiDung,
    this.emailNguoiDung,
    this.soDienThoai,
    this.soPhong,
    this.tenKhachSan,
    this.tenLoaiPhong,
    this.giaPhong,
  });

  /// Tạo đối tượng Booking từ JSON
  /// 
  /// [json] - Map chứa dữ liệu JSON từ API
  /// 
  /// Xử lý:
  /// - Parse ngày tháng từ ISO8601 string
  /// - Parse trạng thái từ string hoặc int
  /// - Chuyển đổi an toàn các kiểu dữ liệu số
  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: _safeToInt(json['id']) ?? 0,
      nguoiDungId: _safeToInt(json['nguoi_dung_id']) ?? 0,
      phongId: _safeToInt(json['phong_id']) ?? 0,
      ngayNhanPhong: DateTime.parse(json['ngay_nhan_phong']),
      ngayTraPhong: DateTime.parse(json['ngay_tra_phong']),
      soLuongKhach: _safeToInt(json['so_luong_khach']) ?? 1,
      tongTien: _safeToDouble(json['tong_tien']) ?? 0,
      trangThai: _parseBookingStatus(json['trang_thai']),
      ghiChu: json['ghi_chu'],
      ngayTao: json['ngay_tao'] != null
          ? DateTime.parse(json['ngay_tao'])
          : null,
      ngayCapNhat: json['ngay_cap_nhat'] != null
          ? DateTime.parse(json['ngay_cap_nhat'])
          : null,
      tenNguoiDung: json['ten_nguoi_dung'],
      emailNguoiDung: json['email_nguoi_dung'],
      soDienThoai: json['so_dien_thoai'],
      soPhong: json['so_phong'],
      tenKhachSan: json['ten_khach_san'],
      tenLoaiPhong: json['ten_loai_phong'],
      giaPhong: _safeToDouble(json['gia_phong']),
    );
  }

  /// Parse trạng thái đặt phòng từ string hoặc int
  /// 
  /// [status] - Trạng thái có thể là String hoặc int
  /// 
  /// Hỗ trợ cả tiếng Việt và tiếng Anh
  /// Trả về BookingStatus tương ứng, mặc định là pending
  static BookingStatus _parseBookingStatus(dynamic status) {
    if (status is String) {
      switch (status.toLowerCase()) {
        case 'pending':
        case 'cho_xac_nhan':
          return BookingStatus.pending;
        case 'confirmed':
        case 'da_xac_nhan':
          return BookingStatus.confirmed;
        case 'checked_in':
        case 'da_check_in':
          return BookingStatus.checkedIn;
        case 'checked_out':
        case 'da_check_out':
          return BookingStatus.checkedOut;
        case 'cancelled':
        case 'da_huy':
          return BookingStatus.cancelled;
        default:
          return BookingStatus.pending;
      }
    } else if (status is int) {
      switch (status) {
        case 0:
          return BookingStatus.pending;
        case 1:
          return BookingStatus.confirmed;
        case 2:
          return BookingStatus.checkedIn;
        case 3:
          return BookingStatus.checkedOut;
        case 4:
          return BookingStatus.cancelled;
        default:
          return BookingStatus.pending;
      }
    }
    return BookingStatus.pending;
  }

  /// Chuyển đổi đối tượng Booking sang JSON
  /// 
  /// Trả về Map chứa tất cả các trường của Booking dưới dạng JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nguoi_dung_id': nguoiDungId,
      'phong_id': phongId,
      'ngay_nhan_phong': ngayNhanPhong.toIso8601String(),
      'ngay_tra_phong': ngayTraPhong.toIso8601String(),
      'so_luong_khach': soLuongKhach,
      'tong_tien': tongTien,
      'trang_thai': _bookingStatusToString(trangThai),
      'ghi_chu': ghiChu,
      'ngay_tao': ngayTao?.toIso8601String(),
      'ngay_cap_nhat': ngayCapNhat?.toIso8601String(),
    };
  }

  /// Chuyển đổi BookingStatus enum sang string
  /// 
  /// [status] - Trạng thái cần chuyển đổi
  /// 
  /// Trả về string tương ứng với trạng thái
  String _bookingStatusToString(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'pending';
      case BookingStatus.confirmed:
        return 'confirmed';
      case BookingStatus.checkedIn:
        return 'checked_in';
      case BookingStatus.checkedOut:
        return 'checked_out';
      case BookingStatus.cancelled:
        return 'cancelled';
    }
  }

  /// Tạo bản sao của Booking với các trường được cập nhật
  /// 
  /// Cho phép cập nhật từng trường riêng lẻ mà không cần tạo mới toàn bộ object
  /// 
  /// Tất cả các tham số đều tùy chọn, nếu không cung cấp sẽ giữ nguyên giá trị cũ
  Booking copyWith({
    int? id,
    int? nguoiDungId,
    int? phongId,
    DateTime? ngayNhanPhong,
    DateTime? ngayTraPhong,
    int? soLuongKhach,
    double? tongTien,
    BookingStatus? trangThai,
    String? ghiChu,
    DateTime? ngayTao,
    DateTime? ngayCapNhat,
    String? tenNguoiDung,
    String? emailNguoiDung,
    String? soDienThoai,
    String? soPhong,
    String? tenKhachSan,
    String? tenLoaiPhong,
    double? giaPhong,
  }) {
    return Booking(
      id: id ?? this.id,
      nguoiDungId: nguoiDungId ?? this.nguoiDungId,
      phongId: phongId ?? this.phongId,
      ngayNhanPhong: ngayNhanPhong ?? this.ngayNhanPhong,
      ngayTraPhong: ngayTraPhong ?? this.ngayTraPhong,
      soLuongKhach: soLuongKhach ?? this.soLuongKhach,
      tongTien: tongTien ?? this.tongTien,
      trangThai: trangThai ?? this.trangThai,
      ghiChu: ghiChu ?? this.ghiChu,
      ngayTao: ngayTao ?? this.ngayTao,
      ngayCapNhat: ngayCapNhat ?? this.ngayCapNhat,
      tenNguoiDung: tenNguoiDung ?? this.tenNguoiDung,
      emailNguoiDung: emailNguoiDung ?? this.emailNguoiDung,
      soDienThoai: soDienThoai ?? this.soDienThoai,
      soPhong: soPhong ?? this.soPhong,
      tenKhachSan: tenKhachSan ?? this.tenKhachSan,
      tenLoaiPhong: tenLoaiPhong ?? this.tenLoaiPhong,
      giaPhong: giaPhong ?? this.giaPhong,
    );
  }

  /// Lấy text hiển thị của trạng thái đặt phòng bằng tiếng Việt
  /// 
  /// Trả về chuỗi mô tả trạng thái (ví dụ: "Chờ xác nhận", "Đã xác nhận")
  String get statusText {
    switch (trangThai) {
      case BookingStatus.pending:
        return 'Chờ xác nhận';
      case BookingStatus.confirmed:
        return 'Đã xác nhận';
      case BookingStatus.checkedIn:
        return 'Đã check-in';
      case BookingStatus.checkedOut:
        return 'Đã check-out';
      case BookingStatus.cancelled:
        return 'Đã hủy';
    }
  }

  /// Lấy tổng tiền đã được format theo định dạng VNĐ
  /// 
  /// Ví dụ: 1000000 -> "1.000.000 VNĐ"
  String get formattedTotalPrice {
    return '${tongTien.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} VNĐ';
  }

  /// Tính số đêm ở của đặt phòng
  /// 
  /// Trả về số ngày chênh lệch giữa ngày trả và ngày nhận
  int get numberOfNights {
    return ngayTraPhong.difference(ngayNhanPhong).inDays;
  }

  /// Kiểm tra xem đặt phòng có thể hủy không
  /// 
  /// Trả về true nếu trạng thái là pending hoặc confirmed
  bool get canCancel {
    return trangThai == BookingStatus.pending ||
        trangThai == BookingStatus.confirmed;
  }

  /// Kiểm tra xem có thể check-in không
  /// 
  /// Trả về true nếu:
  /// - Trạng thái là confirmed
  /// - Thời gian hiện tại đã qua 2 giờ trước ngày nhận phòng
  bool get canCheckIn {
    return trangThai == BookingStatus.confirmed &&
        DateTime.now().isAfter(
          ngayNhanPhong.subtract(const Duration(hours: 2)),
        );
  }

  @override
  String toString() {
    return 'Booking{id: $id, phong: $soPhong, hotel: $tenKhachSan, status: $statusText}';
  }

  /// Chuyển đổi giá trị sang double một cách an toàn
  /// 
  /// [value] - Giá trị có thể là double, int, String, hoặc null
  /// 
  /// Trả về double nếu chuyển đổi thành công, null nếu không
  static double? _safeToDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed;
    }
    return null;
  }

  /// Chuyển đổi giá trị sang int một cách an toàn
  /// 
  /// [value] - Giá trị có thể là int, double, String, hoặc null
  /// 
  /// Trả về int nếu chuyển đổi thành công, null nếu không
  static int? _safeToInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed;
    }
    return null;
  }
}
