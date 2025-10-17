import 'package:json_annotation/json_annotation.dart';

part 'kpi_model.g.dart';

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

  factory KpiModel.fromJson(Map<String, dynamic> json) =>
      _$KpiModelFromJson(json);

  Map<String, dynamic> toJson() => _$KpiModelToJson(this);

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

  // Helper methods
  String get formattedDoanhThu => '${doanhThu.toStringAsFixed(0).replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
    (Match m) => '${m[1]},'
  )} VNĐ';

  String get formattedDoanhThuHomNay => '${doanhThuHomNay.toStringAsFixed(0).replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
    (Match m) => '${m[1]},'
  )} VNĐ';

  String get formattedDoanhThuThangNay => '${doanhThuThangNay.toStringAsFixed(0).replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
    (Match m) => '${m[1]},'
  )} VNĐ';

  String get formattedDoanhThuTrungBinh => '${doanhThuTrungBinh.toStringAsFixed(0).replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
    (Match m) => '${m[1]},'
  )} VNĐ';

  String get formattedTyLeLapDay => '${tyLeLapDay.toStringAsFixed(1)}%';
  String get formattedTyLeHuy => '${tyLeHuy.toStringAsFixed(1)}%';
}

@JsonSerializable()
class DoanhThuNgay {
  final DateTime ngay;
  final double doanhThu;

  const DoanhThuNgay({
    required this.ngay,
    required this.doanhThu,
  });

  factory DoanhThuNgay.fromJson(Map<String, dynamic> json) =>
      _$DoanhThuNgayFromJson(json);

  Map<String, dynamic> toJson() => _$DoanhThuNgayToJson(this);

  DoanhThuNgay copyWith({
    DateTime? ngay,
    double? doanhThu,
  }) {
    return DoanhThuNgay(
      ngay: ngay ?? this.ngay,
      doanhThu: doanhThu ?? this.doanhThu,
    );
  }

  String get formattedNgay => 
      '${ngay.day.toString().padLeft(2, '0')}/${ngay.month.toString().padLeft(2, '0')}';

  String get formattedDoanhThu => '${doanhThu.toStringAsFixed(0).replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
    (Match m) => '${m[1]},'
  )}';
}
