import 'package:flutter/material.dart';

/// Model đại diện cho tiện ích/dịch vụ của khách sạn
/// 
/// Chứa thông tin về các dịch vụ mà khách sạn cung cấp:
/// - Thông tin cơ bản: tên, nhóm, mô tả
/// - Thông tin giá: miễn phí hay có phí, giá nếu có phí
class Amenity {
  final int id;
  final String ten;
  final String? nhom;
  final bool mienPhi;
  final double? giaPhi;
  final String? ghiChu;
  final String? moTa;
  final int? trangThai;

  Amenity({
    required this.id,
    required this.ten,
    this.nhom,
    required this.mienPhi,
    this.giaPhi,
    this.ghiChu,
    this.moTa,
    this.trangThai,
  });

  /// Tạo đối tượng Amenity từ JSON
  factory Amenity.fromJson(Map<String, dynamic> json) {
    return Amenity(
      id: _safeToInt(json['id']) ?? 0,
      ten: json['ten'] ?? json['ten_tien_nghi'] ?? '',
      nhom: json['nhom'],
      mienPhi: json['mien_phi'] == true || json['mien_phi'] == 1 || json['mien_phi'] == 'true',
      giaPhi: _safeToDouble(json['gia_phi']),
      ghiChu: json['ghi_chu'],
      moTa: json['mo_ta'],
      trangThai: _safeToInt(json['trang_thai']),
    );
  }

  /// Chuyển đổi giá trị sang double một cách an toàn
  static double? _safeToDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed;
    }
    return null;
  }

  /// Chuyển đổi giá trị sang int một cách an toàn
  static int? _safeToInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed;
    }
    return null;
  }

  /// Chuyển đổi đối tượng Amenity sang JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ten': ten,
      'nhom': nhom,
      'mien_phi': mienPhi,
      'gia_phi': giaPhi,
      'ghi_chu': ghiChu,
      'mo_ta': moTa,
      'trang_thai': trangThai,
    };
  }

  /// Lấy icon tương ứng với tên dịch vụ
  IconData get icon {
    final nameLower = ten.toLowerCase();
    if (nameLower.contains('wifi') || nameLower.contains('internet')) {
      return Icons.wifi;
    } else if (nameLower.contains('hồ bơi') || nameLower.contains('pool') || nameLower.contains('bể bơi')) {
      return Icons.pool;
    } else if (nameLower.contains('spa')) {
      return Icons.spa;
    } else if (nameLower.contains('gym') || nameLower.contains('thể dục') || nameLower.contains('fitness')) {
      return Icons.fitness_center;
    } else if (nameLower.contains('nhà hàng') || nameLower.contains('restaurant')) {
      return Icons.restaurant;
    } else if (nameLower.contains('bar') || nameLower.contains('quầy bar')) {
      return Icons.local_bar;
    } else if (nameLower.contains('đỗ xe') || nameLower.contains('parking') || nameLower.contains('bãi đỗ')) {
      return Icons.local_parking;
    } else if (nameLower.contains('giặt') || nameLower.contains('laundry')) {
      return Icons.local_laundry_service;
    } else if (nameLower.contains('phòng') && nameLower.contains('dịch vụ')) {
      return Icons.room_service;
    } else if (nameLower.contains('sân bay') || nameLower.contains('airport') || nameLower.contains('đưa đón')) {
      return Icons.airport_shuttle;
    } else if (nameLower.contains('thang máy') || nameLower.contains('elevator')) {
      return Icons.elevator;
    } else if (nameLower.contains('điều hòa') || nameLower.contains('air')) {
      return Icons.ac_unit;
    } else if (nameLower.contains('tv') || nameLower.contains('tivi')) {
      return Icons.tv;
    } else if (nameLower.contains('thú cưng') || nameLower.contains('pet')) {
      return Icons.pets;
    } else if (nameLower.contains('trẻ em') || nameLower.contains('child')) {
      return Icons.child_friendly;
    } else if (nameLower.contains('kinh doanh') || nameLower.contains('business')) {
      return Icons.business_center;
    } else {
      return Icons.check_circle;
    }
  }

  /// Màu sắc tương ứng với dịch vụ
  Color get color {
    final nameLower = ten.toLowerCase();
    if (nameLower.contains('wifi') || nameLower.contains('internet')) {
      return Colors.blue;
    } else if (nameLower.contains('hồ bơi') || nameLower.contains('pool') || nameLower.contains('bể bơi')) {
      return Colors.cyan;
    } else if (nameLower.contains('spa')) {
      return Colors.pink;
    } else if (nameLower.contains('gym') || nameLower.contains('thể dục')) {
      return Colors.orange;
    } else if (nameLower.contains('nhà hàng') || nameLower.contains('restaurant')) {
      return Colors.red;
    } else if (nameLower.contains('bar')) {
      return Colors.brown;
    } else if (nameLower.contains('đỗ xe') || nameLower.contains('parking')) {
      return Colors.grey;
    } else {
      return const Color(0xFF003580);
    }
  }
}

