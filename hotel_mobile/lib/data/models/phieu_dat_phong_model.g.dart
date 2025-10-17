// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'phieu_dat_phong_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PhieuDatPhongModel _$PhieuDatPhongModelFromJson(Map<String, dynamic> json) =>
    PhieuDatPhongModel(
      id: json['id'] as String,
      maPhieu: json['maPhieu'] as String,
      tenKhachHang: json['tenKhachHang'] as String,
      soDienThoai: json['soDienThoai'] as String,
      email: json['email'] as String,
      maPhong: json['maPhong'] as String,
      tenPhong: json['tenPhong'] as String,
      ngayCheckIn: DateTime.parse(json['ngayCheckIn'] as String),
      ngayCheckOut: DateTime.parse(json['ngayCheckOut'] as String),
      soDem: (json['soDem'] as num).toInt(),
      giaPhong: (json['giaPhong'] as num).toDouble(),
      tongTien: (json['tongTien'] as num).toDouble(),
      trangThai: json['trangThai'] as String,
      ghiChu: json['ghiChu'] as String,
      ngayTao: DateTime.parse(json['ngayTao'] as String),
      ngayCapNhat: json['ngayCapNhat'] == null
          ? null
          : DateTime.parse(json['ngayCapNhat'] as String),
    );

Map<String, dynamic> _$PhieuDatPhongModelToJson(PhieuDatPhongModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'maPhieu': instance.maPhieu,
      'tenKhachHang': instance.tenKhachHang,
      'soDienThoai': instance.soDienThoai,
      'email': instance.email,
      'maPhong': instance.maPhong,
      'tenPhong': instance.tenPhong,
      'ngayCheckIn': instance.ngayCheckIn.toIso8601String(),
      'ngayCheckOut': instance.ngayCheckOut.toIso8601String(),
      'soDem': instance.soDem,
      'giaPhong': instance.giaPhong,
      'tongTien': instance.tongTien,
      'trangThai': instance.trangThai,
      'ghiChu': instance.ghiChu,
      'ngayTao': instance.ngayTao.toIso8601String(),
      'ngayCapNhat': instance.ngayCapNhat?.toIso8601String(),
    };
