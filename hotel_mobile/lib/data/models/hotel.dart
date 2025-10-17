class Hotel {
  final int id;
  final String ten;
  final String? moTa;
  final String? hinhAnh;
  final int? soSao;
  final String? trangThai;
  final String? diaChi;
  final int? viTriId;
  final double? yeuCauCoc;
  final double? tiLeCoc;
  final int? hoSoId;
  final int? nguoiQuanLyId;
  final String? emailLienHe;
  final String? sdtLienHe;
  final String? website;
  final String? gioNhanPhong;
  final String? gioTraPhong;
  final String? chinhSachHuy;
  final int? tongSoPhong;
  final double? diemDanhGiaTrungBinh;
  final int? soLuotDanhGia;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Additional fields from joins
  final String? tenViTri;
  final String? tenTinhThanh;
  final String? tenQuocGia;
  final String? tenNguoiQuanLy;
  final String? emailNguoiQuanLy;
  final int? tongSoPhongThucTe;

  Hotel({
    required this.id,
    required this.ten,
    this.moTa,
    this.hinhAnh,
    this.soSao,
    this.trangThai,
    this.diaChi,
    this.viTriId,
    this.yeuCauCoc,
    this.tiLeCoc,
    this.hoSoId,
    this.nguoiQuanLyId,
    this.emailLienHe,
    this.sdtLienHe,
    this.website,
    this.gioNhanPhong,
    this.gioTraPhong,
    this.chinhSachHuy,
    this.tongSoPhong,
    this.diemDanhGiaTrungBinh,
    this.soLuotDanhGia,
    this.createdAt,
    this.updatedAt,
    this.tenViTri,
    this.tenTinhThanh,
    this.tenQuocGia,
    this.tenNguoiQuanLy,
    this.emailNguoiQuanLy,
    this.tongSoPhongThucTe,
  });

  factory Hotel.fromJson(Map<String, dynamic> json) {
    return Hotel(
      id: json['id'],
      ten: json['ten'],
      moTa: json['mo_ta'],
      hinhAnh: json['hinh_anh'],
      soSao: json['so_sao'],
      trangThai: json['trang_thai'],
      diaChi: json['dia_chi'],
      viTriId: json['vi_tri_id'],
      yeuCauCoc: _safeToDouble(json['yeu_cau_coc']),
      tiLeCoc: _safeToDouble(json['ti_le_coc']),
      hoSoId: json['ho_so_id'],
      nguoiQuanLyId: json['nguoi_quan_ly_id'],
      emailLienHe: json['email_lien_he'],
      sdtLienHe: json['sdt_lien_he'],
      website: json['website'],
      gioNhanPhong: json['gio_nhan_phong'],
      gioTraPhong: json['gio_tra_phong'],
      chinhSachHuy: json['chinh_sach_huy'],
      tongSoPhong: json['tong_so_phong'],
      diemDanhGiaTrungBinh: _safeToDouble(json['diem_danh_gia_trung_binh']),
      soLuotDanhGia: json['so_luot_danh_gia'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      tenViTri: json['ten_vi_tri'],
      tenTinhThanh: json['ten_tinh_thanh'],
      tenQuocGia: json['ten_quoc_gia'],
      tenNguoiQuanLy: json['ten_nguoi_quan_ly'],
      emailNguoiQuanLy: json['email_nguoi_quan_ly'],
      tongSoPhongThucTe: json['tong_so_phong_thuc_te'],
    );
  }

  static double? _safeToDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed;
    }
    return null; // For boolean or other types
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ten': ten,
      'mo_ta': moTa,
      'hinh_anh': hinhAnh,
      'so_sao': soSao,
      'trang_thai': trangThai,
      'dia_chi': diaChi,
      'vi_tri_id': viTriId,
      'yeu_cau_coc': yeuCauCoc,
      'ti_le_coc': tiLeCoc,
      'ho_so_id': hoSoId,
      'nguoi_quan_ly_id': nguoiQuanLyId,
      'email_lien_he': emailLienHe,
      'sdt_lien_he': sdtLienHe,
      'website': website,
      'gio_nhan_phong': gioNhanPhong,
      'gio_tra_phong': gioTraPhong,
      'chinh_sach_huy': chinhSachHuy,
      'tong_so_phong': tongSoPhong,
      'diem_danh_gia_trung_binh': diemDanhGiaTrungBinh,
      'so_luot_danh_gia': soLuotDanhGia,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  String get fullImageUrl {
    if (hinhAnh == null || hinhAnh!.isEmpty) {
      return 'https://via.placeholder.com/300x200?text=No+Image';
    }

    if (hinhAnh!.startsWith('http')) {
      return hinhAnh!;
    }

    // Use the same base URL as API
    return 'http://10.0.2.2:5000$hinhAnh';
  }

  String get displayLocation {
    List<String> locationParts = [];
    if (tenViTri != null && tenViTri!.isNotEmpty) {
      locationParts.add(tenViTri!);
    }
    if (tenTinhThanh != null && tenTinhThanh!.isNotEmpty) {
      locationParts.add(tenTinhThanh!);
    }
    if (tenQuocGia != null && tenQuocGia!.isNotEmpty) {
      locationParts.add(tenQuocGia!);
    }
    return locationParts.join(', ');
  }

  String get starRating {
    if (soSao == null) return 'N/A';
    return '★' * soSao! + '☆' * (5 - soSao!);
  }
}
