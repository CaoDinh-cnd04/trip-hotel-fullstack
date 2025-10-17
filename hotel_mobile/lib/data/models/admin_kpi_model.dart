import 'package:json_annotation/json_annotation.dart';

part 'admin_kpi_model.g.dart';

@JsonSerializable()
class AdminKpiModel {
  final int tongSoKhachSan;
  final int tongSoNguoiDung;
  final int hoSoChoDuyet;
  final double doanhThuHeThongThang;
  final List<UserRoleDistribution> phanBoChucVu;

  const AdminKpiModel({
    required this.tongSoKhachSan,
    required this.tongSoNguoiDung,
    required this.hoSoChoDuyet,
    required this.doanhThuHeThongThang,
    required this.phanBoChucVu,
  });

  factory AdminKpiModel.fromJson(Map<String, dynamic> json) =>
      _$AdminKpiModelFromJson(json);

  Map<String, dynamic> toJson() => _$AdminKpiModelToJson(this);

  AdminKpiModel copyWith({
    int? tongSoKhachSan,
    int? tongSoNguoiDung,
    int? hoSoChoDuyet,
    double? doanhThuHeThongThang,
    List<UserRoleDistribution>? phanBoChucVu,
  }) {
    return AdminKpiModel(
      tongSoKhachSan: tongSoKhachSan ?? this.tongSoKhachSan,
      tongSoNguoiDung: tongSoNguoiDung ?? this.tongSoNguoiDung,
      hoSoChoDuyet: hoSoChoDuyet ?? this.hoSoChoDuyet,
      doanhThuHeThongThang: doanhThuHeThongThang ?? this.doanhThuHeThongThang,
      phanBoChucVu: phanBoChucVu ?? this.phanBoChucVu,
    );
  }

  // Helper methods
  String get formattedDoanhThu => '${doanhThuHeThongThang.toStringAsFixed(0).replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
    (Match m) => '${m[1]},'
  )} VNĐ';
}

@JsonSerializable()
class UserRoleDistribution {
  final String chucVu;
  final int soLuong;
  final double phanTram;

  const UserRoleDistribution({
    required this.chucVu,
    required this.soLuong,
    required this.phanTram,
  });

  factory UserRoleDistribution.fromJson(Map<String, dynamic> json) =>
      _$UserRoleDistributionFromJson(json);

  Map<String, dynamic> toJson() => _$UserRoleDistributionToJson(this);

  UserRoleDistribution copyWith({
    String? chucVu,
    int? soLuong,
    double? phanTram,
  }) {
    return UserRoleDistribution(
      chucVu: chucVu ?? this.chucVu,
      soLuong: soLuong ?? this.soLuong,
      phanTram: phanTram ?? this.phanTram,
    );
  }

  String get displayName {
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

  String get formattedPhanTram => '${phanTram.toStringAsFixed(1)}%';
}
