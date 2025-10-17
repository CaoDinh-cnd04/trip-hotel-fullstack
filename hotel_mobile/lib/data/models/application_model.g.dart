// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'application_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApplicationModel _$ApplicationModelFromJson(Map<String, dynamic> json) =>
    ApplicationModel(
      id: json['id'] as String,
      tenKhachSan: json['tenKhachSan'] as String,
      tenNguoiDangKy: json['tenNguoiDangKy'] as String,
      soDienThoai: json['soDienThoai'] as String,
      email: json['email'] as String,
      diaChi: json['diaChi'] as String,
      moTa: json['moTa'] as String,
      trangThai: json['trangThai'] as String,
      ngayDangKy: DateTime.parse(json['ngayDangKy'] as String),
      ngayDuyet: json['ngayDuyet'] == null
          ? null
          : DateTime.parse(json['ngayDuyet'] as String),
      lyDoTuChoi: json['lyDoTuChoi'] as String?,
      nguoiDuyet: json['nguoiDuyet'] as String?,
      hinhAnh: (json['hinhAnh'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      thongTinBoSung: json['thongTinBoSung'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$ApplicationModelToJson(ApplicationModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tenKhachSan': instance.tenKhachSan,
      'tenNguoiDangKy': instance.tenNguoiDangKy,
      'soDienThoai': instance.soDienThoai,
      'email': instance.email,
      'diaChi': instance.diaChi,
      'moTa': instance.moTa,
      'trangThai': instance.trangThai,
      'ngayDangKy': instance.ngayDangKy.toIso8601String(),
      'ngayDuyet': instance.ngayDuyet?.toIso8601String(),
      'lyDoTuChoi': instance.lyDoTuChoi,
      'nguoiDuyet': instance.nguoiDuyet,
      'hinhAnh': instance.hinhAnh,
      'thongTinBoSung': instance.thongTinBoSung,
    };
