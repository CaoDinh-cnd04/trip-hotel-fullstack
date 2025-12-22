import 'package:json_annotation/json_annotation.dart';

part 'kpi_model.g.dart';

/// Model đại diện cho KPI của Hotel Manager Dashboard
/// 
/// Chứa thông tin:
/// - Doanh thu: doanhThu, doanhThuHomNay, doanhThuThangNay, doanhThuTrungBinh, doanhThu7Ngay
/// - Đặt phòng: tongDatPhong, datPhongMoi, tyLeHuy
/// - Phòng: tongPhong, phongTrong, tyLeLapDay
@JsonSerializable()
class KpiModel {
  final double doanhThu;
  final double tyLeLapDay;
  final int tongDatPhong;
  final int datPhongMoi;
  final double doanhThuTrungBinh;
  final double tyLeHuy;
  final int tongPhong;
  final int phongTrong;
  final double doanhThuHomNay;
  final double doanhThuThangNay;
  final List<DoanhThuNgay> doanhThu7Ngay;

  const KpiModel({
    required this.doanhThu,
    required this.tyLeLapDay,
    required this.tongDatPhong,
    required this.datPhongMoi,
    required this.doanhThuTrungBinh,
    required this.tyLeHuy,
    required this.tongPhong,
    required this.phongTrong,
    required this.doanhThuHomNay,
    required this.doanhThuThangNay,
    required this.doanhThu7Ngay,
  });

  /// Tạo đối tượng KpiModel từ JSON
  /// 
  /// [json] - Map chứa dữ liệu JSON từ API
  /// 
  /// Sử dụng code generation từ json_annotation
  factory KpiModel.fromJson(Map<String, dynamic> json) =>
      _$KpiModelFromJson(json);

  /// Chuyển đổi đối tượng KpiModel sang JSON
  /// 
  /// Trả về Map chứa tất cả các trường dưới dạng JSON
  /// Sử dụng code generation từ json_annotation
  Map<String, dynamic> toJson() => _$KpiModelToJson(this);

  /// Tạo bản sao của KpiModel với các trường được cập nhật
  /// 
  /// Cho phép cập nhật từng trường riêng lẻ mà không cần tạo mới toàn bộ object
  /// 
  /// Tất cả các tham số đều tùy chọn, nếu không cung cấp sẽ giữ nguyên giá trị cũ
  KpiModel copyWith({
    double? doanhThu,
    double? tyLeLapDay,
    int? tongDatPhong,
    int? datPhongMoi,
    double? doanhThuTrungBinh,
    double? tyLeHuy,
    int? tongPhong,
    int? phongTrong,
    double? doanhThuHomNay,
    double? doanhThuThangNay,
    List<DoanhThuNgay>? doanhThu7Ngay,
  }) {
    return KpiModel(
      doanhThu: doanhThu ?? this.doanhThu,
      tyLeLapDay: tyLeLapDay ?? this.tyLeLapDay,
      tongDatPhong: tongDatPhong ?? this.tongDatPhong,
      datPhongMoi: datPhongMoi ?? this.datPhongMoi,
      doanhThuTrungBinh: doanhThuTrungBinh ?? this.doanhThuTrungBinh,
      tyLeHuy: tyLeHuy ?? this.tyLeHuy,
      tongPhong: tongPhong ?? this.tongPhong,
      phongTrong: phongTrong ?? this.phongTrong,
      doanhThuHomNay: doanhThuHomNay ?? this.doanhThuHomNay,
      doanhThuThangNay: doanhThuThangNay ?? this.doanhThuThangNay,
      doanhThu7Ngay: doanhThu7Ngay ?? this.doanhThu7Ngay,
    );
  }

  /// Lấy doanh thu đã được format với dấu phẩy phân cách hàng nghìn
  /// 
  /// Ví dụ: 1250000 -> "1,250,000 VNĐ"
  String get formattedDoanhThu => '${doanhThu.toStringAsFixed(0).replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
    (Match m) => '${m[1]},'
  )} VNĐ';

  /// Lấy doanh thu hôm nay đã được format với dấu phẩy phân cách hàng nghìn
  String get formattedDoanhThuHomNay => '${doanhThuHomNay.toStringAsFixed(0).replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
    (Match m) => '${m[1]},'
  )} VNĐ';

  /// Lấy doanh thu tháng này đã được format với dấu phẩy phân cách hàng nghìn
  String get formattedDoanhThuThangNay => '${doanhThuThangNay.toStringAsFixed(0).replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
    (Match m) => '${m[1]},'
  )} VNĐ';

  /// Lấy doanh thu trung bình đã được format với dấu phẩy phân cách hàng nghìn
  String get formattedDoanhThuTrungBinh => '${doanhThuTrungBinh.toStringAsFixed(0).replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
    (Match m) => '${m[1]},'
  )} VNĐ';

  /// Lấy tỷ lệ lấp đầy đã được format (phần trăm)
  /// 
  /// Ví dụ: 85.5 -> "85.5%"
  String get formattedTyLeLapDay => '${tyLeLapDay.toStringAsFixed(1)}%';
  
  /// Lấy tỷ lệ hủy đã được format (phần trăm)
  /// 
  /// Ví dụ: 12.3 -> "12.3%"
  String get formattedTyLeHuy => '${tyLeHuy.toStringAsFixed(1)}%';
}

/// Model đại diện cho doanh thu theo ngày (7 ngày gần nhất)
/// 
/// Chứa: ngay (DateTime) và doanhThu (double)
@JsonSerializable()
class DoanhThuNgay {
  final DateTime ngay;
  final double doanhThu;

  const DoanhThuNgay({
    required this.ngay,
    required this.doanhThu,
  });

  /// Tạo đối tượng DoanhThuNgay từ JSON
  /// 
  /// [json] - Map chứa dữ liệu JSON từ API
  /// 
  /// Sử dụng code generation từ json_annotation
  factory DoanhThuNgay.fromJson(Map<String, dynamic> json) =>
      _$DoanhThuNgayFromJson(json);

  /// Chuyển đổi đối tượng DoanhThuNgay sang JSON
  /// 
  /// Trả về Map chứa tất cả các trường dưới dạng JSON
  /// Sử dụng code generation từ json_annotation
  Map<String, dynamic> toJson() => _$DoanhThuNgayToJson(this);

  /// Tạo bản sao của DoanhThuNgay với các trường được cập nhật
  /// 
  /// Cho phép cập nhật từng trường riêng lẻ mà không cần tạo mới toàn bộ object
  /// 
  /// Tất cả các tham số đều tùy chọn, nếu không cung cấp sẽ giữ nguyên giá trị cũ
  DoanhThuNgay copyWith({
    DateTime? ngay,
    double? doanhThu,
  }) {
    return DoanhThuNgay(
      ngay: ngay ?? this.ngay,
      doanhThu: doanhThu ?? this.doanhThu,
    );
  }

  /// Lấy ngày đã được format (dd/MM)
  /// 
  /// Ví dụ: "15/12"
  String get formattedNgay => 
      '${ngay.day.toString().padLeft(2, '0')}/${ngay.month.toString().padLeft(2, '0')}';

  /// Lấy doanh thu đã được format với dấu phẩy phân cách hàng nghìn
  /// 
  /// Ví dụ: 1250000 -> "1,250,000"
  String get formattedDoanhThu => '${doanhThu.toStringAsFixed(0).replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
    (Match m) => '${m[1]},'
  )}';
}
