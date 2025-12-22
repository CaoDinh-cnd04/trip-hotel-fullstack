/// Model đại diện cho user (phiên bản dùng trong admin/hotel manager)
/// 
/// Chứa thông tin:
/// - Thông tin đăng nhập: id, tenDangNhap, email
/// - Thông tin cá nhân: hoTen, soDienThoai, avatar, diaChi
/// - Thông tin hệ thống: chucVu, trangThai, ghiChu
/// - Thời gian: ngayTao, ngayCapNhat, ngayDangKy
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

  /// Tạo đối tượng UserModel từ JSON
  /// 
  /// [json] - Map chứa dữ liệu JSON từ API
  /// 
  /// Xử lý:
  /// - Parse trangThai từ bool/int/string sang string
  /// - Sử dụng email làm tenDangNhap
  /// - Parse DateTime từ ISO8601 string
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

  /// Chuyển đổi đối tượng UserModel sang JSON
  /// 
  /// Trả về Map chứa tất cả các trường dưới dạng JSON (snake_case)
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

  /// Tạo bản sao của UserModel với các trường được cập nhật
  /// 
  /// Cho phép cập nhật từng trường riêng lẻ mà không cần tạo mới toàn bộ object
  /// 
  /// Tất cả các tham số đều tùy chọn, nếu không cung cấp sẽ giữ nguyên giá trị cũ
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

  /// Kiểm tra xem user có đang hoạt động không
  /// 
  /// Trả về true nếu trangThai == 'active'
  bool get isActive => trangThai == 'active';
  
  /// Kiểm tra xem user có đang không hoạt động không
  /// 
  /// Trả về true nếu trangThai == 'inactive'
  bool get isInactive => trangThai == 'inactive';
  
  /// Kiểm tra xem user có bị khóa không
  /// 
  /// Trả về true nếu trangThai == 'blocked'
  bool get isBlocked => trangThai == 'blocked';

  /// Lấy tên hiển thị của trạng thái bằng tiếng Việt
  /// 
  /// Trả về: "Hoạt động", "Không hoạt động", "Bị khóa", hoặc "Không xác định"
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

  /// Lấy tên hiển thị của vai trò bằng tiếng Việt
  /// 
  /// Trả về: "Quản trị viên", "Quản lý khách sạn", "Nhân viên", hoặc "Người dùng"
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
