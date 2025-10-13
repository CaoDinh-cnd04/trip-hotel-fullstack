class Room {
  final int? id;
  final String soPhong;
  final int loaiPhongId;
  final int khachSanId;
  final bool tinhTrang;
  final String? moTa;
  final DateTime? ngayTao;
  final DateTime? ngayCapNhat;

  // Thông tin từ bảng liên kết
  final String? tenLoaiPhong;
  final double? giaPhong;
  final int? sucChua;
  final List<String>? hinhAnhPhong;
  final String? tenKhachSan;

  Room({
    this.id,
    required this.soPhong,
    required this.loaiPhongId,
    required this.khachSanId,
    this.tinhTrang = true,
    this.moTa,
    this.ngayTao,
    this.ngayCapNhat,
    this.tenLoaiPhong,
    this.giaPhong,
    this.sucChua,
    this.hinhAnhPhong,
    this.tenKhachSan,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    List<String>? images;
    if (json['hinh_anh_phong'] != null) {
      if (json['hinh_anh_phong'] is String) {
        images = [json['hinh_anh_phong']];
      } else if (json['hinh_anh_phong'] is List) {
        images = List<String>.from(json['hinh_anh_phong']);
      }
    }

    return Room(
      id: json['id'],
      soPhong: json['so_phong'] ?? '',
      loaiPhongId: json['loai_phong_id'] ?? 0,
      khachSanId: json['khach_san_id'] ?? 0,
      tinhTrang: json['tinh_trang'] == 1 || json['tinh_trang'] == true,
      moTa: json['mo_ta'],
      ngayTao: json['ngay_tao'] != null
          ? DateTime.parse(json['ngay_tao'])
          : null,
      ngayCapNhat: json['ngay_cap_nhat'] != null
          ? DateTime.parse(json['ngay_cap_nhat'])
          : null,
      tenLoaiPhong: json['ten_loai_phong'],
      giaPhong: json['gia_phong'] != null
          ? (json['gia_phong']).toDouble()
          : null,
      sucChua: json['suc_chua'],
      hinhAnhPhong: images,
      tenKhachSan: json['ten_khach_san'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'so_phong': soPhong,
      'loai_phong_id': loaiPhongId,
      'khach_san_id': khachSanId,
      'tinh_trang': tinhTrang,
      'mo_ta': moTa,
      'ngay_tao': ngayTao?.toIso8601String(),
      'ngay_cap_nhat': ngayCapNhat?.toIso8601String(),
    };
  }

  Room copyWith({
    int? id,
    String? soPhong,
    int? loaiPhongId,
    int? khachSanId,
    bool? tinhTrang,
    String? moTa,
    DateTime? ngayTao,
    DateTime? ngayCapNhat,
    String? tenLoaiPhong,
    double? giaPhong,
    int? sucChua,
    List<String>? hinhAnhPhong,
    String? tenKhachSan,
  }) {
    return Room(
      id: id ?? this.id,
      soPhong: soPhong ?? this.soPhong,
      loaiPhongId: loaiPhongId ?? this.loaiPhongId,
      khachSanId: khachSanId ?? this.khachSanId,
      tinhTrang: tinhTrang ?? this.tinhTrang,
      moTa: moTa ?? this.moTa,
      ngayTao: ngayTao ?? this.ngayTao,
      ngayCapNhat: ngayCapNhat ?? this.ngayCapNhat,
      tenLoaiPhong: tenLoaiPhong ?? this.tenLoaiPhong,
      giaPhong: giaPhong ?? this.giaPhong,
      sucChua: sucChua ?? this.sucChua,
      hinhAnhPhong: hinhAnhPhong ?? this.hinhAnhPhong,
      tenKhachSan: tenKhachSan ?? this.tenKhachSan,
    );
  }

  String get statusText => tinhTrang ? 'Có sẵn' : 'Đã đặt';

  String get formattedPrice {
    if (giaPhong != null) {
      return '${giaPhong!.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} VNĐ';
    }
    return 'Liên hệ';
  }

  String get capacityText => sucChua != null ? '$sucChua khách' : 'N/A';

  @override
  String toString() {
    return 'Room{id: $id, soPhong: $soPhong, tenLoaiPhong: $tenLoaiPhong, giaPhong: $giaPhong}';
  }
}
