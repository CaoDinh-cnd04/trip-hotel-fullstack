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
  final DateTime? ngayDangKy;
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
    this.ngayDangKy,
    this.avatar,
    this.diaChi,
    this.ghiChu,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Convert trang_thai from backend format
    String trangThai = 'inactive';
    final trangThaiValue = json['trang_thai'];
    if (trangThaiValue is bool) {
      trangThai = trangThaiValue ? 'active' : 'inactive';
    } else if (trangThaiValue is int) {
      trangThai = trangThaiValue == 1 ? 'active' : 'inactive';
    } else if (trangThaiValue is String) {
      trangThai = trangThaiValue.toLowerCase();
    }

    final email = json['email']?.toString() ?? '';
    
    return UserModel(
      id: json['id']?.toString() ?? '',
      tenDangNhap: email,  // Use email as username
      email: email,
      hoTen: json['ho_ten']?.toString() ?? '',
      soDienThoai: json['sdt']?.toString() ?? '',
      chucVu: json['chuc_vu']?.toString() ?? 'User',
      trangThai: trangThai,
      ngayTao: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      ngayCapNhat: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
      ngayDangKy: json['ngay_dang_ky'] != null 
          ? DateTime.parse(json['ngay_dang_ky']) 
          : null,
      avatar: json['anh_dai_dien']?.toString(),
      diaChi: json['dia_chi']?.toString(),
      ghiChu: json['ghi_chu']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'ho_ten': hoTen,
    'sdt': soDienThoai,
    'chuc_vu': chucVu,
    'trang_thai': trangThai,
    'created_at': ngayTao.toIso8601String(),
    'updated_at': ngayCapNhat?.toIso8601String(),
    'ngay_dang_ky': ngayDangKy?.toIso8601String(),
    'anh_dai_dien': avatar,
    'dia_chi': diaChi,
    'ghi_chu': ghiChu,
  };

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
