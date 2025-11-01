import '../../core/utils/image_url_helper.dart';

class User {
  final int? id;
  final String? hoTen;
  final String email;
  final String? sdt;
  final String? ngaySinh;
  final String? gioiTinh;
  final String? diaChi;
  final String? anhDaiDien;
  final String? chucVu;
  final int? trangThai;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    this.id,
    this.hoTen,
    required this.email,
    this.sdt,
    this.ngaySinh,
    this.gioiTinh,
    this.diaChi,
    this.anhDaiDien,
    this.chucVu,
    this.trangThai,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      hoTen: json['ho_ten'],
      email: json['email'],
      sdt: json['sdt'],
      ngaySinh: json['ngay_sinh'],
      gioiTinh: json['gioi_tinh'],
      diaChi: json['dia_chi'],
      anhDaiDien: json['anh_dai_dien'],
      chucVu: json['chuc_vu'],
      trangThai: json['trang_thai'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ho_ten': hoTen,
      'email': email,
      'sdt': sdt,
      'ngay_sinh': ngaySinh,
      'gioi_tinh': gioiTinh,
      'dia_chi': diaChi,
      'anh_dai_dien': anhDaiDien,
      'chuc_vu': chucVu,
      'trang_thai': trangThai,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  User copyWith({
    int? id,
    String? hoTen,
    String? email,
    String? sdt,
    String? ngaySinh,
    String? gioiTinh,
    String? diaChi,
    String? anhDaiDien,
    String? chucVu,
    int? trangThai,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      hoTen: hoTen ?? this.hoTen,
      email: email ?? this.email,
      sdt: sdt ?? this.sdt,
      ngaySinh: ngaySinh ?? this.ngaySinh,
      gioiTinh: gioiTinh ?? this.gioiTinh,
      diaChi: diaChi ?? this.diaChi,
      anhDaiDien: anhDaiDien ?? this.anhDaiDien,
      chucVu: chucVu ?? this.chucVu,
      trangThai: trangThai ?? this.trangThai,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get full avatar URL
  String get fullAvatarUrl {
    return ImageUrlHelper.getUserAvatarUrl(anhDaiDien);
  }
}
