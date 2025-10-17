// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  id: json['id'] as String,
  tenDangNhap: json['tenDangNhap'] as String,
  email: json['email'] as String,
  hoTen: json['hoTen'] as String,
  soDienThoai: json['soDienThoai'] as String,
  chucVu: json['chucVu'] as String,
  trangThai: json['trangThai'] as String,
  ngayTao: DateTime.parse(json['ngayTao'] as String),
  ngayCapNhat: json['ngayCapNhat'] == null
      ? null
      : DateTime.parse(json['ngayCapNhat'] as String),
  avatar: json['avatar'] as String?,
  diaChi: json['diaChi'] as String?,
  ghiChu: json['ghiChu'] as String?,
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'id': instance.id,
  'tenDangNhap': instance.tenDangNhap,
  'email': instance.email,
  'hoTen': instance.hoTen,
  'soDienThoai': instance.soDienThoai,
  'chucVu': instance.chucVu,
  'trangThai': instance.trangThai,
  'ngayTao': instance.ngayTao.toIso8601String(),
  'ngayCapNhat': instance.ngayCapNhat?.toIso8601String(),
  'avatar': instance.avatar,
  'diaChi': instance.diaChi,
  'ghiChu': instance.ghiChu,
};
