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

  // Check if voucher is currently valid
  bool get isValid {
    if (!trangThai) return false;

    final now = DateTime.now();
    return ngayBatDau.isBefore(now) &&
        ngayKetThuc.isAfter(now) &&
        soLuongConLai > 0;
  }

  // Check if voucher is active (not expired but might not be started)
  bool get isActive {
    return trangThai && soLuongConLai > 0;
  }

  // Check if voucher has started
  bool get hasStarted {
    return DateTime.now().isAfter(ngayBatDau);
  }

  // Check if voucher has expired
  bool get hasExpired {
    return DateTime.now().isAfter(ngayKetThuc);
  }

  // Get discount description text
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

  // Get minimum order description
  String? get minimumOrderDescription {
    if (giaTriDonHangToiThieu != null) {
      return 'Đơn hàng từ ${giaTriDonHangToiThieu!.toStringAsFixed(0)}đ';
    }
    return null;
  }

  // Calculate discount amount for a given order value
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

  // Check if user can use this voucher (considering usage limits)
  bool canUserUse({int? currentUserUsage}) {
    if (!isValid) return false;

    if (gioiHanSuDungMoiNguoi != null && currentUserUsage != null) {
      return currentUserUsage < gioiHanSuDungMoiNguoi!;
    }

    return true;
  }

  // Get remaining days until expiry
  int get remainingDays {
    if (hasExpired) return 0;
    return ngayKetThuc.difference(DateTime.now()).inDays;
  }

  // Get status text for UI display
  String get statusText {
    if (!trangThai) return 'Đã vô hiệu hóa';
    if (!hasStarted) return 'Chưa bắt đầu';
    if (hasExpired) return 'Đã hết hạn';
    if (soLuongConLai <= 0) return 'Đã hết lượt';
    if (remainingDays <= 3) return 'Sắp hết hạn';
    return 'Có thể sử dụng';
  }

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
