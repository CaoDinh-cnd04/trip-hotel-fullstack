import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  final String id;
  final String tenDangNhap;
  final String email;
  final String hoTen;
  final String soDienThoai;
  final String chucVu;
  final String trangThai;
  final DateTime ngayTao;
  final DateTime? ngayCapNhat;
  final String? avatar;
  final String? diaChi;
  final String? ghiChu;

  const UserModel({
    required this.id,
    required this.tenDangNhap,
    required this.email,
    required this.hoTen,
    required this.soDienThoai,
    required this.chucVu,
    required this.trangThai,
    required this.ngayTao,
    this.ngayCapNhat,
    this.avatar,
    this.diaChi,
    this.ghiChu,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  UserModel copyWith({
    String? id,
    String? tenDangNhap,
    String? email,
    String? hoTen,
    String? soDienThoai,
    String? chucVu,
    String? trangThai,
    DateTime? ngayTao,
    DateTime? ngayCapNhat,
    String? avatar,
    String? diaChi,
    String? ghiChu,
  }) {
    return UserModel(
      id: id ?? this.id,
      tenDangNhap: tenDangNhap ?? this.tenDangNhap,
      email: email ?? this.email,
      hoTen: hoTen ?? this.hoTen,
      soDienThoai: soDienThoai ?? this.soDienThoai,
      chucVu: chucVu ?? this.chucVu,
      trangThai: trangThai ?? this.trangThai,
      ngayTao: ngayTao ?? this.ngayTao,
      ngayCapNhat: ngayCapNhat ?? this.ngayCapNhat,
      avatar: avatar ?? this.avatar,
      diaChi: diaChi ?? this.diaChi,
      ghiChu: ghiChu ?? this.ghiChu,
    );
  }

  // Helper methods
  bool get isActive => trangThai == 'active';
  bool get isInactive => trangThai == 'inactive';
  bool get isBlocked => trangThai == 'blocked';

  String get statusDisplayName {
    switch (trangThai) {
      case 'active':
        return 'Hoạt động';
      case 'inactive':
        return 'Không hoạt động';
      case 'blocked':
        return 'Bị khóa';
      default:
        return 'Không xác định';
    }
  }

  String get roleDisplayName {
    switch (chucVu.toLowerCase()) {
      case 'admin':
        return 'Quản trị viên';
      case 'hotelmanager':
        return 'Quản lý khách sạn';
      case 'user':
        return 'Người dùng';
      default:
        return chucVu;
    }
  }

  String get formattedNgayTao => 
      '${ngayTao.day.toString().padLeft(2, '0')}/${ngayTao.month.toString().padLeft(2, '0')}/${ngayTao.year}';

  String get formattedNgayCapNhat => ngayCapNhat != null
      ? '${ngayCapNhat!.day.toString().padLeft(2, '0')}/${ngayCapNhat!.month.toString().padLeft(2, '0')}/${ngayCapNhat!.year}'
      : 'Chưa cập nhật';
}
