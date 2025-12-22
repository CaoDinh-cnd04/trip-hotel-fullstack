/// Model đại diện cho hoạt động (tour, vé tham quan, activity)
/// 
/// Chứa thông tin:
/// - Thông tin cơ bản: tên, mô tả, giá, địa điểm
/// - Thời gian: thời lượng, giờ bắt đầu
/// - Hình ảnh và đánh giá
/// - Số lượng người tham gia
class Activity {
  final int? id;
  final String ten;
  final String? moTa;
  final double gia;
  final String? diaDiem;
  final String? diaChi;
  final int? thoiLuong; // Thời lượng tính bằng phút
  final String? gioBatDau;
  final String? hinhAnh;
  final double? danhGia; // Điểm đánh giá trung bình (0-5)
  final int? soLuongDanhGia;
  final bool trangThai;
  final DateTime? ngayTao;
  final DateTime? ngayCapNhat;
  final String? loaiHoatDong; // Ví dụ: "Tour", "Vé tham quan", "Trải nghiệm"
  final int? soNguoiToiDa;
  final int? soNguoiToiThieu;
  final List<String>? hinhAnhBoSung; // Danh sách hình ảnh bổ sung

  Activity({
    this.id,
    required this.ten,
    this.moTa,
    required this.gia,
    this.diaDiem,
    this.diaChi,
    this.thoiLuong,
    this.gioBatDau,
    this.hinhAnh,
    this.danhGia,
    this.soLuongDanhGia,
    this.trangThai = true,
    this.ngayTao,
    this.ngayCapNhat,
    this.loaiHoatDong,
    this.soNguoiToiDa,
    this.soNguoiToiThieu,
    this.hinhAnhBoSung,
  });

  /// Tạo đối tượng Activity từ JSON
  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0'),
      ten: json['ten'] ?? '',
      moTa: json['mo_ta'] ?? json['moTa'],
      gia: (json['gia'] ?? 0).toDouble(),
      diaDiem: json['dia_diem'] ?? json['diaDiem'],
      diaChi: json['dia_chi'] ?? json['diaChi'],
      thoiLuong: json['thoi_luong'] ?? json['thoiLuong'],
      gioBatDau: json['gio_bat_dau'] ?? json['gioBatDau'],
      hinhAnh: json['hinh_anh'] ?? json['hinhAnh'],
      danhGia: json['danh_gia'] != null ? (json['danh_gia'] as num).toDouble() : null,
      soLuongDanhGia: json['so_luong_danh_gia'] ?? json['soLuongDanhGia'],
      trangThai: json['trang_thai'] == 1 || json['trang_thai'] == true,
      ngayTao: json['ngay_tao'] != null
          ? DateTime.parse(json['ngay_tao'])
          : null,
      ngayCapNhat: json['ngay_cap_nhat'] != null
          ? DateTime.parse(json['ngay_cap_nhat'])
          : null,
      loaiHoatDong: json['loai_hoat_dong'] ?? json['loaiHoatDong'],
      soNguoiToiDa: json['so_nguoi_toi_da'] ?? json['soNguoiToiDa'],
      soNguoiToiThieu: json['so_nguoi_toi_thieu'] ?? json['soNguoiToiThieu'],
      hinhAnhBoSung: json['hinh_anh_bo_sung'] != null
          ? List<String>.from(json['hinh_anh_bo_sung'])
          : null,
    );
  }

  /// Chuyển đổi đối tượng Activity sang JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ten': ten,
      'mo_ta': moTa,
      'gia': gia,
      'dia_diem': diaDiem,
      'dia_chi': diaChi,
      'thoi_luong': thoiLuong,
      'gio_bat_dau': gioBatDau,
      'hinh_anh': hinhAnh,
      'danh_gia': danhGia,
      'so_luong_danh_gia': soLuongDanhGia,
      'trang_thai': trangThai,
      'ngay_tao': ngayTao?.toIso8601String(),
      'ngay_cap_nhat': ngayCapNhat?.toIso8601String(),
      'loai_hoat_dong': loaiHoatDong,
      'so_nguoi_toi_da': soNguoiToiDa,
      'so_nguoi_toi_thieu': soNguoiToiThieu,
      'hinh_anh_bo_sung': hinhAnhBoSung,
    };
  }

  /// Tạo bản sao của Activity với các trường được cập nhật
  Activity copyWith({
    int? id,
    String? ten,
    String? moTa,
    double? gia,
    String? diaDiem,
    String? diaChi,
    int? thoiLuong,
    String? gioBatDau,
    String? hinhAnh,
    double? danhGia,
    int? soLuongDanhGia,
    bool? trangThai,
    DateTime? ngayTao,
    DateTime? ngayCapNhat,
    String? loaiHoatDong,
    int? soNguoiToiDa,
    int? soNguoiToiThieu,
    List<String>? hinhAnhBoSung,
  }) {
    return Activity(
      id: id ?? this.id,
      ten: ten ?? this.ten,
      moTa: moTa ?? this.moTa,
      gia: gia ?? this.gia,
      diaDiem: diaDiem ?? this.diaDiem,
      diaChi: diaChi ?? this.diaChi,
      thoiLuong: thoiLuong ?? this.thoiLuong,
      gioBatDau: gioBatDau ?? this.gioBatDau,
      hinhAnh: hinhAnh ?? this.hinhAnh,
      danhGia: danhGia ?? this.danhGia,
      soLuongDanhGia: soLuongDanhGia ?? this.soLuongDanhGia,
      trangThai: trangThai ?? this.trangThai,
      ngayTao: ngayTao ?? this.ngayTao,
      ngayCapNhat: ngayCapNhat ?? this.ngayCapNhat,
      loaiHoatDong: loaiHoatDong ?? this.loaiHoatDong,
      soNguoiToiDa: soNguoiToiDa ?? this.soNguoiToiDa,
      soNguoiToiThieu: soNguoiToiThieu ?? this.soNguoiToiThieu,
      hinhAnhBoSung: hinhAnhBoSung ?? this.hinhAnhBoSung,
    );
  }

  /// Lấy text hiển thị giá
  String get priceText {
    return '${gia.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )} ₫';
  }

  /// Lấy text hiển thị thời lượng
  String get durationText {
    if (thoiLuong == null) return '';
    if (thoiLuong! < 60) {
      return '$thoiLuong phút';
    } else {
      final hours = thoiLuong! ~/ 60;
      final minutes = thoiLuong! % 60;
      if (minutes == 0) {
        return '$hours giờ';
      }
      return '$hours giờ $minutes phút';
    }
  }

  /// Lấy text hiển thị đánh giá
  String get ratingText {
    if (danhGia == null || danhGia == 0) {
      return 'Chưa có đánh giá';
    }
    return '${danhGia!.toStringAsFixed(1)} (${soLuongDanhGia ?? 0} đánh giá)';
  }

  @override
  String toString() {
    return 'Activity{id: $id, ten: $ten, gia: $gia, danhGia: $danhGia}';
  }
}

