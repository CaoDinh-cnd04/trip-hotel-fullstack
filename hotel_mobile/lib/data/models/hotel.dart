import '../../core/utils/image_url_helper.dart';

/// Model đại diện cho khách sạn
/// 
/// Chứa tất cả thông tin về khách sạn:
/// - Thông tin cơ bản: tên, mô tả, hình ảnh, địa chỉ
/// - Thông tin đánh giá: điểm trung bình, số lượt đánh giá
/// - Thông tin quản lý: người quản lý, trạng thái
/// - Chính sách: giờ nhận/trả phòng, chính sách hủy
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
  final double? giaTb;
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
    this.giaTb,
    this.createdAt,
    this.updatedAt,
    this.tenViTri,
    this.tenTinhThanh,
    this.tenQuocGia,
    this.tenNguoiQuanLy,
    this.emailNguoiQuanLy,
    this.tongSoPhongThucTe,
  });

  /// Tạo đối tượng Hotel từ JSON
  /// 
  /// [json] - Map chứa dữ liệu JSON từ API
  /// 
  /// Xử lý các trường hợp:
  /// - Chuẩn hóa đường dẫn hình ảnh cho Android emulator
  /// - Chuyển đổi an toàn các kiểu dữ liệu (int, double)
  /// - Hỗ trợ nhiều tên field (sao/so_sao, danh_gia/diem_danh_gia_trung_binh)
  factory Hotel.fromJson(Map<String, dynamic> json) {
    // Get image path and normalize for Android emulator
    String? imagePath = json['hinh_anh'];
    if (imagePath != null && imagePath.contains('://')) {
      // Replace any IP address with 10.0.2.2 for Android emulator
      imagePath = imagePath.replaceFirst(
        RegExp(r'://[^:]+:'),
        '://10.0.2.2:',
      );
    }
    
    return Hotel(
      id: _safeToInt(json['id']) ?? 0,
      ten: json['ten'] ?? '',
      moTa: json['mo_ta'],
      hinhAnh: imagePath,
      soSao: _safeToInt(json['so_sao'] ?? json['sao']), // Support both field names
      trangThai: json['trang_thai'],
      diaChi: json['dia_chi'],
      viTriId: _safeToInt(json['vi_tri_id']),
      yeuCauCoc: _safeToDouble(json['yeu_cau_coc']),
      tiLeCoc: _safeToDouble(json['ti_le_coc']),
      hoSoId: _safeToInt(json['ho_so_id']),
      nguoiQuanLyId: _safeToInt(json['nguoi_quan_ly_id']),
      emailLienHe: json['email_lien_he'],
      sdtLienHe: json['sdt_lien_he'],
      website: json['website'],
      gioNhanPhong: json['gio_nhan_phong'],
      gioTraPhong: json['gio_tra_phong'],
      chinhSachHuy: json['chinh_sach_huy'],
      tongSoPhong: _safeToInt(json['tong_so_phong']),
      diemDanhGiaTrungBinh: _safeToDouble(json['diem_danh_gia_trung_binh']) ?? _safeToDouble(json['danh_gia']),
      soLuotDanhGia: _safeToInt(json['so_luot_danh_gia'] ?? json['so_danh_gia']),
      giaTb: _safeToDouble(json['gia_tb']) ?? _safeToDouble(json['gia_trung_binh']),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      tenViTri: json['ten_vi_tri'],
      tenTinhThanh: json['ten_tinh_thanh'] ?? json['tinh_thanh'],
      tenQuocGia: json['ten_quoc_gia'] ?? json['quoc_gia'],
      tenNguoiQuanLy: json['ten_nguoi_quan_ly'],
      emailNguoiQuanLy: json['email_nguoi_quan_ly'],
      tongSoPhongThucTe: _safeToInt(json['tong_so_phong_thuc_te']),
    );
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
    return null; // For boolean or other types
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
    return null; // For boolean or other types
  }

  /// Chuyển đổi đối tượng Hotel sang JSON
  /// 
  /// Trả về Map chứa tất cả các trường của Hotel dưới dạng JSON
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
      'gia_tb': giaTb,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  String get fullImageUrl {
    return ImageUrlHelper.getHotelImageUrl(hinhAnh);
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
