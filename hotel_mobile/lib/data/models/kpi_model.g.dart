// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kpi_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KpiModel _$KpiModelFromJson(Map<String, dynamic> json) => KpiModel(
  doanhThu: (json['doanhThu'] as num).toDouble(),
  tyLeLapDay: (json['tyLeLapDay'] as num).toDouble(),
  tongDatPhong: (json['tongDatPhong'] as num).toInt(),
  datPhongMoi: (json['datPhongMoi'] as num).toInt(),
  doanhThuTrungBinh: (json['doanhThuTrungBinh'] as num).toDouble(),
  tyLeHuy: (json['tyLeHuy'] as num).toDouble(),
  tongPhong: (json['tongPhong'] as num).toInt(),
  phongTrong: (json['phongTrong'] as num).toInt(),
  doanhThuHomNay: (json['doanhThuHomNay'] as num).toDouble(),
  doanhThuThangNay: (json['doanhThuThangNay'] as num).toDouble(),
  doanhThu7Ngay: (json['doanhThu7Ngay'] as List<dynamic>)
      .map((e) => DoanhThuNgay.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$KpiModelToJson(KpiModel instance) => <String, dynamic>{
  'doanhThu': instance.doanhThu,
  'tyLeLapDay': instance.tyLeLapDay,
  'tongDatPhong': instance.tongDatPhong,
  'datPhongMoi': instance.datPhongMoi,
  'doanhThuTrungBinh': instance.doanhThuTrungBinh,
  'tyLeHuy': instance.tyLeHuy,
  'tongPhong': instance.tongPhong,
  'phongTrong': instance.phongTrong,
  'doanhThuHomNay': instance.doanhThuHomNay,
  'doanhThuThangNay': instance.doanhThuThangNay,
  'doanhThu7Ngay': instance.doanhThu7Ngay,
};

DoanhThuNgay _$DoanhThuNgayFromJson(Map<String, dynamic> json) => DoanhThuNgay(
  ngay: DateTime.parse(json['ngay'] as String),
  doanhThu: (json['doanhThu'] as num).toDouble(),
);

Map<String, dynamic> _$DoanhThuNgayToJson(DoanhThuNgay instance) =>
    <String, dynamic>{
      'ngay': instance.ngay.toIso8601String(),
      'doanhThu': instance.doanhThu,
    };
