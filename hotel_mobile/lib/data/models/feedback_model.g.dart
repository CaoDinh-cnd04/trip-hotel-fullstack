// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feedback_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FeedbackModel _$FeedbackModelFromJson(Map<String, dynamic> json) =>
    FeedbackModel(
      id: (json['id'] as num).toInt(),
      nguoiDungId: (json['nguoiDungId'] as num).toInt(),
      hoTen: json['hoTen'] as String?,
      email: json['email'] as String?,
      tieuDe: json['tieuDe'] as String,
      noiDung: json['noiDung'] as String,
      loaiPhanHoi: json['loaiPhanHoi'] as String,
      trangThai: json['trangThai'] as String,
      uuTien: (json['uuTien'] as num?)?.toInt(),
      phanHoiCuaAdmin: json['phanHoiCuaAdmin'] as String?,
      adminId: (json['adminId'] as num?)?.toInt(),
      adminName: json['adminName'] as String?,
      ngayPhanHoi: json['ngayPhanHoi'] == null
          ? null
          : DateTime.parse(json['ngayPhanHoi'] as String),
      ngayGiaiQuyet: json['ngayGiaiQuyet'] == null
          ? null
          : DateTime.parse(json['ngayGiaiQuyet'] as String),
      ngayTao: DateTime.parse(json['ngayTao'] as String),
      ngayCapNhat: json['ngayCapNhat'] == null
          ? null
          : DateTime.parse(json['ngayCapNhat'] as String),
      hinhAnh: (json['hinhAnh'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$FeedbackModelToJson(FeedbackModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nguoiDungId': instance.nguoiDungId,
      'hoTen': instance.hoTen,
      'email': instance.email,
      'tieuDe': instance.tieuDe,
      'noiDung': instance.noiDung,
      'loaiPhanHoi': instance.loaiPhanHoi,
      'trangThai': instance.trangThai,
      'uuTien': instance.uuTien,
      'phanHoiCuaAdmin': instance.phanHoiCuaAdmin,
      'adminId': instance.adminId,
      'adminName': instance.adminName,
      'ngayPhanHoi': instance.ngayPhanHoi?.toIso8601String(),
      'ngayGiaiQuyet': instance.ngayGiaiQuyet?.toIso8601String(),
      'ngayTao': instance.ngayTao.toIso8601String(),
      'ngayCapNhat': instance.ngayCapNhat?.toIso8601String(),
      'hinhAnh': instance.hinhAnh,
      'metadata': instance.metadata,
    };
