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

  factory Promotion.fromJson(Map<String, dynamic> json) {
    return Promotion(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0'),
      ten: json['ten'] ?? '',
      moTa: json['mo_ta'],
      phanTramGiam: (json['phan_tram_giam'] ?? json['phan_tram'] ?? 0).toDouble(),
      ngayBatDau: DateTime.parse(json['ngay_bat_dau']),
      ngayKetThuc: DateTime.parse(json['ngay_ket_thuc']),
      trangThai: json['trang_thai'] == 1 || json['trang_thai'] == true,
      hinhAnh: json['hinh_anh'],
      ngayTao: json['ngay_tao'] != null
          ? DateTime.parse(json['ngay_tao'])
          : null,
      ngayCapNhat: json['ngay_cap_nhat'] != null
          ? DateTime.parse(json['ngay_cap_nhat'])
          : null,
      location: json['location'] ?? json['ten_vi_tri'] ?? json['ten_tinh_thanh'],
      hotelName: json['hotel_name'] ?? json['ten_khach_san'],
      hotelAddress: json['hotel_address'] ?? json['dia_chi'],
      khachSanId: json['khach_san_id'],
      image: json['image'] ?? json['hotel_image'],
    );
  }

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

  bool get isActive {
    final now = DateTime.now();
    return trangThai && now.isAfter(ngayBatDau) && now.isBefore(ngayKetThuc);
  }

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
