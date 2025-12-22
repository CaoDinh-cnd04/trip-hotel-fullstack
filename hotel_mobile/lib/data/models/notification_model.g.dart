// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationModel _$NotificationModelFromJson(Map<String, dynamic> json) =>
    NotificationModel(
      id: json['id'] as int,
      tieuDe: json['tieuDe'] as String,
      noiDung: json['noiDung'] as String,
      loaiThongBao: json['loaiThongBao'] as String,
      urlHinhAnh: json['urlHinhAnh'] as String?,
      urlHanhDong: json['urlHanhDong'] as String?,
      vanBanNut: json['vanBanNut'] as String?,
      khachSanId: json['khachSanId'] as int?,
      ngayHetHan: json['ngayHetHan'] == null
          ? null
          : DateTime.parse(json['ngayHetHan'] as String),
      hienThi: json['hienThi'] as bool,
      doiTuongNhan: json['doiTuongNhan'] as String,
      nguoiDungId: json['nguoiDungId'] as int?,
      guiEmail: json['guiEmail'] as bool,
      nguoiTaoId: json['nguoiTaoId'] as int,
      ngayTao: DateTime.parse(json['ngayTao'] as String),
      ngayCapNhat: json['ngayCapNhat'] == null
          ? null
          : DateTime.parse(json['ngayCapNhat'] as String),
      daDoc: json['daDoc'] as bool? ?? false,
    );

Map<String, dynamic> _$NotificationModelToJson(NotificationModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tieuDe': instance.tieuDe,
      'noiDung': instance.noiDung,
      'loaiThongBao': instance.loaiThongBao,
      'urlHinhAnh': instance.urlHinhAnh,
      'urlHanhDong': instance.urlHanhDong,
      'vanBanNut': instance.vanBanNut,
      'khachSanId': instance.khachSanId,
      'ngayHetHan': instance.ngayHetHan?.toIso8601String(),
      'hienThi': instance.hienThi,
      'doiTuongNhan': instance.doiTuongNhan,
      'nguoiDungId': instance.nguoiDungId,
      'guiEmail': instance.guiEmail,
      'nguoiTaoId': instance.nguoiTaoId,
      'ngayTao': instance.ngayTao.toIso8601String(),
      'ngayCapNhat': instance.ngayCapNhat?.toIso8601String(),
      'daDoc': instance.daDoc,
    };
