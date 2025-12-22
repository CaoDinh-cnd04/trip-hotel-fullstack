import '../../core/utils/image_url_helper.dart';

/// Model đại diện cho người dùng
/// 
/// Chứa thông tin:
/// - Thông tin cá nhân: họ tên, email, số điện thoại, ngày sinh, giới tính
/// - Thông tin địa chỉ: địa chỉ, avatar
/// - Thông tin hệ thống: chức vụ (vai trò), trạng thái
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

  /// Tạo đối tượng User từ JSON
  /// 
  /// [json] - Map chứa dữ liệu JSON từ API
  /// 
  /// Trả về đối tượng User với các trường được parse từ JSON
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

  /// Chuyển đổi đối tượng User sang JSON
  /// 
  /// Trả về Map chứa tất cả các trường của User dưới dạng JSON
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

  /// Tạo bản sao của User với các trường được cập nhật
  /// 
  /// Cho phép cập nhật từng trường riêng lẻ mà không cần tạo mới toàn bộ object
  /// 
  /// Tất cả các tham số đều tùy chọn, nếu không cung cấp sẽ giữ nguyên giá trị cũ
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

  /// Lấy URL đầy đủ của avatar
  /// 
  /// Sử dụng ImageUrlHelper để tạo URL từ đường dẫn avatar
  /// Trả về URL mặc định nếu không có avatar
  String get fullAvatarUrl {
    return ImageUrlHelper.getUserAvatarUrl(anhDaiDien);
  }
}
