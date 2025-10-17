// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_kpi_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminKpiModel _$AdminKpiModelFromJson(Map<String, dynamic> json) =>
    AdminKpiModel(
      tongSoKhachSan: (json['tongSoKhachSan'] as num).toInt(),
      tongSoNguoiDung: (json['tongSoNguoiDung'] as num).toInt(),
      hoSoChoDuyet: (json['hoSoChoDuyet'] as num).toInt(),
      doanhThuHeThongThang: (json['doanhThuHeThongThang'] as num).toDouble(),
      phanBoChucVu: (json['phanBoChucVu'] as List<dynamic>)
          .map((e) => UserRoleDistribution.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$AdminKpiModelToJson(AdminKpiModel instance) =>
    <String, dynamic>{
      'tongSoKhachSan': instance.tongSoKhachSan,
      'tongSoNguoiDung': instance.tongSoNguoiDung,
      'hoSoChoDuyet': instance.hoSoChoDuyet,
      'doanhThuHeThongThang': instance.doanhThuHeThongThang,
      'phanBoChucVu': instance.phanBoChucVu,
    };

UserRoleDistribution _$UserRoleDistributionFromJson(
  Map<String, dynamic> json,
) => UserRoleDistribution(
  chucVu: json['chucVu'] as String,
  soLuong: (json['soLuong'] as num).toInt(),
  phanTram: (json['phanTram'] as num).toDouble(),
);

Map<String, dynamic> _$UserRoleDistributionToJson(
  UserRoleDistribution instance,
) => <String, dynamic>{
  'chucVu': instance.chucVu,
  'soLuong': instance.soLuong,
  'phanTram': instance.phanTram,
};
