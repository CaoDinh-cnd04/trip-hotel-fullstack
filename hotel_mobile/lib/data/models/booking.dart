enum BookingStatus {
  pending, // Chờ xác nhận
  confirmed, // Đã xác nhận
  checkedIn, // Đã check-in
  checkedOut, // Đã check-out
  cancelled, // Đã hủy
}

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

  String get formattedTotalPrice {
    return '${tongTien.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} VNĐ';
  }

  int get numberOfNights {
    return ngayTraPhong.difference(ngayNhanPhong).inDays;
  }

  bool get canCancel {
    return trangThai == BookingStatus.pending ||
        trangThai == BookingStatus.confirmed;
  }

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
