import 'package:json_annotation/json_annotation.dart';

part 'application_model.g.dart';

/// Model đại diện cho đơn đăng ký khách sạn
/// 
/// Chứa thông tin:
/// - Thông tin khách sạn: tenKhachSan, diaChi, moTa, hinhAnh
/// - Thông tin người đăng ký: tenNguoiDangKy, soDienThoai, email
/// - Trạng thái: trangThai (pending/approved/rejected)
/// - Thông tin duyệt: ngayDuyet, lyDoTuChoi, nguoiDuyet
/// - Thời gian: ngayDangKy
/// - Thông tin bổ sung: thongTinBoSung
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

  /// Tạo đối tượng ApplicationModel từ JSON
  /// 
  /// [json] - Map chứa dữ liệu JSON từ API
  /// 
  /// Sử dụng code generation từ json_annotation
  factory ApplicationModel.fromJson(Map<String, dynamic> json) =>
      _$ApplicationModelFromJson(json);

  /// Chuyển đổi đối tượng ApplicationModel sang JSON
  /// 
  /// Trả về Map chứa tất cả các trường dưới dạng JSON
  /// Sử dụng code generation từ json_annotation
  Map<String, dynamic> toJson() => _$ApplicationModelToJson(this);

  /// Tạo bản sao của ApplicationModel với các trường được cập nhật
  /// 
  /// Cho phép cập nhật từng trường riêng lẻ mà không cần tạo mới toàn bộ object
  /// 
  /// Tất cả các tham số đều tùy chọn, nếu không cung cấp sẽ giữ nguyên giá trị cũ
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

  /// Kiểm tra xem đơn có đang chờ duyệt không
  /// 
  /// Trả về true nếu trangThai == 'pending'
  bool get isPending => trangThai == 'pending';
  
  /// Kiểm tra xem đơn đã được duyệt chưa
  /// 
  /// Trả về true nếu trangThai == 'approved'
  bool get isApproved => trangThai == 'approved';
  
  /// Kiểm tra xem đơn có bị từ chối không
  /// 
  /// Trả về true nếu trangThai == 'rejected'
  bool get isRejected => trangThai == 'rejected';

  /// Lấy tên hiển thị của trạng thái đơn bằng tiếng Việt
  /// 
  /// Trả về: "Chờ duyệt", "Đã duyệt", "Từ chối", hoặc "Không xác định"
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

  /// Lấy ngày đăng ký đã được format (dd/MM/yyyy)
  /// 
  /// Ví dụ: "15/12/2024"
  String get formattedNgayDangKy => 
      '${ngayDangKy.day.toString().padLeft(2, '0')}/${ngayDangKy.month.toString().padLeft(2, '0')}/${ngayDangKy.year}';

  /// Lấy ngày duyệt đã được format (dd/MM/yyyy)
  /// 
  /// Ví dụ: "20/12/2024" hoặc chuỗi rỗng nếu chưa duyệt
  String get formattedNgayDuyet => ngayDuyet != null
      ? '${ngayDuyet!.day.toString().padLeft(2, '0')}/${ngayDuyet!.month.toString().padLeft(2, '0')}/${ngayDuyet!.year}'
      : 'Chưa duyệt';

  /// Lấy mô tả ngắn (rút gọn nếu quá 100 ký tự)
  /// 
  /// Trả về mô tả gốc nếu <= 100 ký tự, hoặc mô tả rút gọn + "..." nếu > 100 ký tự
  String get shortMoTa => moTa.length > 100 ? '${moTa.substring(0, 100)}...' : moTa;
}
