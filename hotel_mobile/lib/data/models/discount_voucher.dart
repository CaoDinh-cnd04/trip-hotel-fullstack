/// Model đại diện cho voucher/mã giảm giá
/// 
/// Chứa thông tin:
/// - Thông tin cơ bản: maGiamGia, tenMaGiamGia, moTa
/// - Loại giảm giá: loaiGiam (phan_tram hoặc tien_mat), giaTriGiam, giamToiDa
/// - Điều kiện: giaTriDonHangToiThieu, soLuongGioiHan, soLuongConLai, gioiHanSuDungMoiNguoi
/// - Thời gian: ngayBatDau, ngayKetThuc
/// - Trạng thái: trangThai, maNguoiDung (null = public voucher)
/// - Theo dõi sử dụng: soLanDaSuDungCuaToi
class DiscountVoucher {
  final int? id;
  final String maGiamGia;
  final String tenMaGiamGia;
  final String? moTa;
  final String loaiGiam; // 'phan_tram' | 'tien_mat'
  final double giaTriGiam;
  final double? giamToiDa;
  final double? giaTriDonHangToiThieu;
  final DateTime ngayBatDau;
  final DateTime ngayKetThuc;
  final int soLuongGioiHan;
  final int soLuongConLai;
  final int? gioiHanSuDungMoiNguoi;
  final bool trangThai;
  final int? maNguoiDung; // null = public voucher
  final DateTime? ngayTao;
  final DateTime? ngayCapNhat;
  final int? soLanDaSuDungCuaToi; // For user-specific usage tracking

  DiscountVoucher({
    this.id,
    required this.maGiamGia,
    required this.tenMaGiamGia,
    this.moTa,
    required this.loaiGiam,
    required this.giaTriGiam,
    this.giamToiDa,
    this.giaTriDonHangToiThieu,
    required this.ngayBatDau,
    required this.ngayKetThuc,
    required this.soLuongGioiHan,
    required this.soLuongConLai,
    this.gioiHanSuDungMoiNguoi,
    this.trangThai = true,
    this.maNguoiDung,
    this.ngayTao,
    this.ngayCapNhat,
    this.soLanDaSuDungCuaToi,
  });

  /// Tạo đối tượng DiscountVoucher từ JSON
  /// 
  /// [json] - Map chứa dữ liệu JSON từ API
  /// 
  /// Parse các trường từ snake_case sang camelCase
  /// Xử lý parse DateTime và boolean
  factory DiscountVoucher.fromJson(Map<String, dynamic> json) {
    return DiscountVoucher(
      id: json['id'],
      maGiamGia: json['ma_giam_gia'] ?? '',
      tenMaGiamGia: json['ten_ma_giam_gia'] ?? '',
      moTa: json['mo_ta'],
      loaiGiam: json['loai_giam'] ?? 'phan_tram',
      giaTriGiam: (json['gia_tri_giam'] ?? 0).toDouble(),
      giamToiDa: json['giam_toi_da']?.toDouble(),
      giaTriDonHangToiThieu: json['gia_tri_don_hang_toi_thieu']?.toDouble(),
      ngayBatDau: DateTime.parse(json['ngay_bat_dau']),
      ngayKetThuc: DateTime.parse(json['ngay_ket_thuc']),
      soLuongGioiHan: json['so_luong_gioi_han'] ?? 0,
      soLuongConLai: json['so_luong_con_lai'] ?? 0,
      gioiHanSuDungMoiNguoi: json['gioi_han_su_dung_moi_nguoi'],
      trangThai: json['trang_thai'] == 1 || json['trang_thai'] == true,
      maNguoiDung: json['ma_nguoi_dung'],
      ngayTao: json['ngay_tao'] != null
          ? DateTime.parse(json['ngay_tao'])
          : null,
      ngayCapNhat: json['ngay_cap_nhat'] != null
          ? DateTime.parse(json['ngay_cap_nhat'])
          : null,
      soLanDaSuDungCuaToi: json['so_lan_da_su_dung_cua_toi'],
    );
  }

  /// Chuyển đổi đối tượng DiscountVoucher sang JSON
  /// 
  /// Trả về Map chứa tất cả các trường dưới dạng JSON (snake_case)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ma_giam_gia': maGiamGia,
      'ten_ma_giam_gia': tenMaGiamGia,
      'mo_ta': moTa,
      'loai_giam': loaiGiam,
      'gia_tri_giam': giaTriGiam,
      'giam_toi_da': giamToiDa,
      'gia_tri_don_hang_toi_thieu': giaTriDonHangToiThieu,
      'ngay_bat_dau': ngayBatDau.toIso8601String(),
      'ngay_ket_thuc': ngayKetThuc.toIso8601String(),
      'so_luong_gioi_han': soLuongGioiHan,
      'so_luong_con_lai': soLuongConLai,
      'gioi_han_su_dung_moi_nguoi': gioiHanSuDungMoiNguoi,
      'trang_thai': trangThai ? 1 : 0,
      'ma_nguoi_dung': maNguoiDung,
      'ngay_tao': ngayTao?.toIso8601String(),
      'ngay_cap_nhat': ngayCapNhat?.toIso8601String(),
    };
  }

  /// Kiểm tra xem voucher có hợp lệ để sử dụng không
  /// 
  /// Trả về true nếu:
  /// - trangThai = true
  /// - Thời gian hiện tại nằm trong khoảng ngayBatDau và ngayKetThuc
  /// - soLuongConLai > 0
  bool get isValid {
    if (!trangThai) return false;

    final now = DateTime.now();
    return ngayBatDau.isBefore(now) &&
        ngayKetThuc.isAfter(now) &&
        soLuongConLai > 0;
  }

  /// Kiểm tra xem voucher có đang active không (chưa hết số lượt)
  /// 
  /// Trả về true nếu trangThai = true và soLuongConLai > 0
  bool get isActive {
    return trangThai && soLuongConLai > 0;
  }

  /// Kiểm tra xem voucher đã bắt đầu chưa
  /// 
  /// Trả về true nếu thời gian hiện tại đã qua ngayBatDau
  bool get hasStarted {
    return DateTime.now().isAfter(ngayBatDau);
  }

  /// Kiểm tra xem voucher đã hết hạn chưa
  /// 
  /// Trả về true nếu thời gian hiện tại đã qua ngayKetThuc
  bool get hasExpired {
    return DateTime.now().isAfter(ngayKetThuc);
  }

  /// Lấy mô tả giảm giá dưới dạng text
  /// 
  /// Ví dụ: "Giảm 20% (tối đa 100.000đ)" hoặc "Giảm 50.000đ"
  String get discountDescription {
    if (loaiGiam == 'phan_tram') {
      String desc = 'Giảm ${(giaTriGiam * 100).toInt()}%';
      if (giamToiDa != null) {
        desc += ' (tối đa ${giamToiDa!.toStringAsFixed(0)}đ)';
      }
      return desc;
    } else {
      return 'Giảm ${giaTriGiam.toStringAsFixed(0)}đ';
    }
  }

  /// Lấy mô tả giá trị đơn hàng tối thiểu
  /// 
  /// Trả về chuỗi mô tả hoặc null nếu không có điều kiện tối thiểu
  /// Ví dụ: "Đơn hàng từ 500.000đ"
  String? get minimumOrderDescription {
    if (giaTriDonHangToiThieu != null) {
      return 'Đơn hàng từ ${giaTriDonHangToiThieu!.toStringAsFixed(0)}đ';
    }
    return null;
  }

  /// Tính số tiền được giảm cho một đơn hàng
  /// 
  /// [orderValue] - Giá trị đơn hàng
  /// 
  /// Trả về số tiền được giảm dựa trên loaiGiam:
  /// - phan_tram: orderValue * (giaTriGiam / 100), tối đa giamToiDa (nếu có)
  /// - tien_mat: giaTriGiam
  /// 
  /// Trả về 0 nếu voucher không hợp lệ hoặc orderValue < giaTriDonHangToiThieu
  double calculateDiscountAmount(double orderValue) {
    if (!isValid ||
        (giaTriDonHangToiThieu != null &&
            orderValue < giaTriDonHangToiThieu!)) {
      return 0;
    }

    double discount = 0;
    if (loaiGiam == 'phan_tram') {
      discount = orderValue * (giaTriGiam / 100);
      if (giamToiDa != null && discount > giamToiDa!) {
        discount = giamToiDa!;
      }
    } else {
      discount = giaTriGiam;
    }

    return discount;
  }

  /// Kiểm tra xem user có thể sử dụng voucher này không (tính đến giới hạn sử dụng)
  /// 
  /// [currentUserUsage] - Số lần user đã sử dụng voucher này (tùy chọn)
  /// 
  /// Trả về true nếu:
  /// - Voucher hợp lệ (isValid)
  /// - currentUserUsage < gioiHanSuDungMoiNguoi (nếu có giới hạn)
  bool canUserUse({int? currentUserUsage}) {
    if (!isValid) return false;

    if (gioiHanSuDungMoiNguoi != null && currentUserUsage != null) {
      return currentUserUsage < gioiHanSuDungMoiNguoi!;
    }

    return true;
  }

  /// Tính số ngày còn lại cho đến khi hết hạn
  /// 
  /// Trả về số ngày còn lại, hoặc 0 nếu đã hết hạn
  int get remainingDays {
    if (hasExpired) return 0;
    return ngayKetThuc.difference(DateTime.now()).inDays;
  }

  /// Lấy text hiển thị trạng thái voucher cho UI
  /// 
  /// Trả về: "Đã vô hiệu hóa", "Chưa bắt đầu", "Đã hết hạn", "Đã hết lượt", "Sắp hết hạn", hoặc "Có thể sử dụng"
  String get statusText {
    if (!trangThai) return 'Đã vô hiệu hóa';
    if (!hasStarted) return 'Chưa bắt đầu';
    if (hasExpired) return 'Đã hết hạn';
    if (soLuongConLai <= 0) return 'Đã hết lượt';
    if (remainingDays <= 3) return 'Sắp hết hạn';
    return 'Có thể sử dụng';
  }

  /// Tạo bản sao của DiscountVoucher với các trường được cập nhật
  /// 
  /// Cho phép cập nhật từng trường riêng lẻ mà không cần tạo mới toàn bộ object
  /// 
  /// Tất cả các tham số đều tùy chọn, nếu không cung cấp sẽ giữ nguyên giá trị cũ
  DiscountVoucher copyWith({
    int? id,
    String? maGiamGia,
    String? tenMaGiamGia,
    String? moTa,
    String? loaiGiam,
    double? giaTriGiam,
    double? giamToiDa,
    double? giaTriDonHangToiThieu,
    DateTime? ngayBatDau,
    DateTime? ngayKetThuc,
    int? soLuongGioiHan,
    int? soLuongConLai,
    int? gioiHanSuDungMoiNguoi,
    bool? trangThai,
    int? maNguoiDung,
    DateTime? ngayTao,
    DateTime? ngayCapNhat,
    int? soLanDaSuDungCuaToi,
  }) {
    return DiscountVoucher(
      id: id ?? this.id,
      maGiamGia: maGiamGia ?? this.maGiamGia,
      tenMaGiamGia: tenMaGiamGia ?? this.tenMaGiamGia,
      moTa: moTa ?? this.moTa,
      loaiGiam: loaiGiam ?? this.loaiGiam,
      giaTriGiam: giaTriGiam ?? this.giaTriGiam,
      giamToiDa: giamToiDa ?? this.giamToiDa,
      giaTriDonHangToiThieu:
          giaTriDonHangToiThieu ?? this.giaTriDonHangToiThieu,
      ngayBatDau: ngayBatDau ?? this.ngayBatDau,
      ngayKetThuc: ngayKetThuc ?? this.ngayKetThuc,
      soLuongGioiHan: soLuongGioiHan ?? this.soLuongGioiHan,
      soLuongConLai: soLuongConLai ?? this.soLuongConLai,
      gioiHanSuDungMoiNguoi:
          gioiHanSuDungMoiNguoi ?? this.gioiHanSuDungMoiNguoi,
      trangThai: trangThai ?? this.trangThai,
      maNguoiDung: maNguoiDung ?? this.maNguoiDung,
      ngayTao: ngayTao ?? this.ngayTao,
      ngayCapNhat: ngayCapNhat ?? this.ngayCapNhat,
      soLanDaSuDungCuaToi: soLanDaSuDungCuaToi ?? this.soLanDaSuDungCuaToi,
    );
  }
}
