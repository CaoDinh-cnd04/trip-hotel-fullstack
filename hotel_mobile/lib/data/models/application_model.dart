import 'package:json_annotation/json_annotation.dart';

part 'application_model.g.dart';

@JsonSerializable()
class ApplicationModel {
  final String id;
  final String tenKhachSan;
  final String tenNguoiDangKy;
  final String soDienThoai;
  final String email;
  final String diaChi;
  final String moTa;
  final String trangThai;
  final DateTime ngayDangKy;
  final DateTime? ngayDuyet;
  final String? lyDoTuChoi;
  final String? nguoiDuyet;
  final List<String> hinhAnh;
  final Map<String, dynamic>? thongTinBoSung;

  const ApplicationModel({
    required this.id,
    required this.tenKhachSan,
    required this.tenNguoiDangKy,
    required this.soDienThoai,
    required this.email,
    required this.diaChi,
    required this.moTa,
    required this.trangThai,
    required this.ngayDangKy,
    this.ngayDuyet,
    this.lyDoTuChoi,
    this.nguoiDuyet,
    required this.hinhAnh,
    this.thongTinBoSung,
  });

  factory ApplicationModel.fromJson(Map<String, dynamic> json) =>
      _$ApplicationModelFromJson(json);

  Map<String, dynamic> toJson() => _$ApplicationModelToJson(this);

  ApplicationModel copyWith({
    String? id,
    String? tenKhachSan,
    String? tenNguoiDangKy,
    String? soDienThoai,
    String? email,
    String? diaChi,
    String? moTa,
    String? trangThai,
    DateTime? ngayDangKy,
    DateTime? ngayDuyet,
    String? lyDoTuChoi,
    String? nguoiDuyet,
    List<String>? hinhAnh,
    Map<String, dynamic>? thongTinBoSung,
  }) {
    return ApplicationModel(
      id: id ?? this.id,
      tenKhachSan: tenKhachSan ?? this.tenKhachSan,
      tenNguoiDangKy: tenNguoiDangKy ?? this.tenNguoiDangKy,
      soDienThoai: soDienThoai ?? this.soDienThoai,
      email: email ?? this.email,
      diaChi: diaChi ?? this.diaChi,
      moTa: moTa ?? this.moTa,
      trangThai: trangThai ?? this.trangThai,
      ngayDangKy: ngayDangKy ?? this.ngayDangKy,
      ngayDuyet: ngayDuyet ?? this.ngayDuyet,
      lyDoTuChoi: lyDoTuChoi ?? this.lyDoTuChoi,
      nguoiDuyet: nguoiDuyet ?? this.nguoiDuyet,
      hinhAnh: hinhAnh ?? this.hinhAnh,
      thongTinBoSung: thongTinBoSung ?? this.thongTinBoSung,
    );
  }

  // Helper methods
  bool get isPending => trangThai == 'pending';
  bool get isApproved => trangThai == 'approved';
  bool get isRejected => trangThai == 'rejected';

  String get statusDisplayName {
    switch (trangThai) {
      case 'pending':
        return 'Chờ duyệt';
      case 'approved':
        return 'Đã duyệt';
      case 'rejected':
        return 'Từ chối';
      default:
        return 'Không xác định';
    }
  }

  String get formattedNgayDangKy => 
      '${ngayDangKy.day.toString().padLeft(2, '0')}/${ngayDangKy.month.toString().padLeft(2, '0')}/${ngayDangKy.year}';

  String get formattedNgayDuyet => ngayDuyet != null
      ? '${ngayDuyet!.day.toString().padLeft(2, '0')}/${ngayDuyet!.month.toString().padLeft(2, '0')}/${ngayDuyet!.year}'
      : 'Chưa duyệt';

  String get shortMoTa => moTa.length > 100 ? '${moTa.substring(0, 100)}...' : moTa;
}
