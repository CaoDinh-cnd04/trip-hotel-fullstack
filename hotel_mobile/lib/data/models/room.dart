import 'dart:convert';
import '../../core/utils/image_url_helper.dart';

class Room {
  final int? id;
  final String soPhong;
  final int loaiPhongId;
  final int khachSanId;
  final bool tinhTrang;
  final String? moTa;
  final DateTime? ngayTao;
  final DateTime? ngayCapNhat;

  // Thông tin từ bảng liên kết
  final String? tenLoaiPhong;
  final double? giaPhong;
  final int? sucChua;
  final List<String>? hinhAnhPhong;
  final String? tenKhachSan;
  
  // Thông tin tiện nghi
  final List<String>? tienNghi;
  final int? soGiuongDon;
  final int? soGiuongDoi;
  
  // Availability status (from real-time API)
  final bool? isAvailable;
  final int? currentBookings;
  final String? trangThaiText;
  final String? trangThaiColor;
  final int? totalRooms;       // Total rooms of this type
  final int? availableCount;   // Available rooms count
  final int? occupiedCount;    // Occupied rooms count

  Room({
    this.id,
    required this.soPhong,
    required this.loaiPhongId,
    required this.khachSanId,
    this.tinhTrang = true,
    this.moTa,
    this.ngayTao,
    this.ngayCapNhat,
    this.tenLoaiPhong,
    this.giaPhong,
    this.sucChua,
    this.hinhAnhPhong,
    this.tenKhachSan,
    this.tienNghi,
    this.soGiuongDon,
    this.soGiuongDoi,
    this.isAvailable,
    this.currentBookings,
    this.trangThaiText,
    this.trangThaiColor,
    this.totalRooms,
    this.availableCount,
    this.occupiedCount,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    List<String>? images;
    
    // Try hinh_anh first (backend field), then hinh_anh_phong (legacy)
    final imageField = json['hinh_anh'] ?? json['hinh_anh_phong'];
    
    if (imageField != null) {
      print('🏠 Room ${json['id']}: imageField = $imageField (type: ${imageField.runtimeType})');
      
      if (imageField is String) {
        // Try to parse as JSON array first
        try {
          final parsed = jsonDecode(imageField);
          if (parsed is List) {
            images = List<String>.from(parsed);
            print('🏠 Room ${json['id']}: Parsed ${images?.length} images from JSON array');
          } else {
            images = [imageField];
          }
        } catch (e) {
          // Not JSON, treat as single image filename
          images = [imageField];
          print('🏠 Room ${json['id']}: Using as single filename');
        }
      } else if (imageField is List) {
        images = List<String>.from(imageField);
        print('🏠 Room ${json['id']}: Got ${images?.length} images from List');
      }
    } else {
      print('⚠️ Room ${json['id']}: No image field found');
    }

    // Parse price from different possible field names
    double? price;
    if (json['gia_phong'] != null) {
      price = _safeToDouble(json['gia_phong']);
    } else if (json['gia_tien'] != null) {
      price = _safeToDouble(json['gia_tien']);
    } else if (json['gia_co_ban'] != null) {
      price = _safeToDouble(json['gia_co_ban']);
    }
    
    // Ensure price is valid (not Infinity or NaN)
    if (price != null && (!price.isFinite || price.isNaN)) {
      price = 500000; // Default price
    }

    // Parse capacity from different possible field names
    int? capacity;
    if (json['suc_chua'] != null) {
      capacity = _safeToInt(json['suc_chua']);
    } else if (json['so_khach'] != null) {
      capacity = _safeToInt(json['so_khach']);
    } else if (json['so_khach_toi_da'] != null) {
      capacity = _safeToInt(json['so_khach_toi_da']);
    }
    
    // Ensure price comes from gia_tien or gia_phong (SQL Server uses gia_tien)
    if (price == null || price == 0) {
      // Fallback: try other price fields
      if (json['gia_co_ban'] != null) {
        price = _safeToDouble(json['gia_co_ban']);
      }
    }

    // Parse description from different possible field names
    String? description;
    if (json['mo_ta'] != null) {
      description = json['mo_ta'];
    } else if (json['mo_ta_loai_phong'] != null) {
      description = json['mo_ta_loai_phong'];
    }

    // Parse amenities
    List<String>? amenities;
    if (json['tien_nghi'] != null) {
      if (json['tien_nghi'] is List) {
        amenities = List<String>.from(json['tien_nghi']);
      } else if (json['tien_nghi'] is String) {
        amenities = [json['tien_nghi']];
      }
    }

    return Room(
      id: _safeToInt(json['id']),
      soPhong: json['so_phong'] ?? json['ma_phong'] ?? '',
      loaiPhongId: _safeToInt(json['loai_phong_id']) ?? 0,
      khachSanId: _safeToInt(json['khach_san_id']) ?? _safeToInt(json['khachSanId']) ?? 0,
      tinhTrang: json['tinh_trang'] == 1 || json['tinh_trang'] == true,
      moTa: description,
      ngayTao: json['ngay_tao'] != null
          ? DateTime.parse(json['ngay_tao'])
          : null,
      ngayCapNhat: json['ngay_cap_nhat'] != null
          ? DateTime.parse(json['ngay_cap_nhat'])
          : null,
      tenLoaiPhong: json['ten_loai_phong'] ?? json['ten'],
      giaPhong: price ?? 0,
      sucChua: capacity,
      hinhAnhPhong: images,
      tenKhachSan: json['ten_khach_san'],
      tienNghi: amenities,
      soGiuongDon: _safeToInt(json['so_giuong_don']),
      soGiuongDoi: _safeToInt(json['so_giuong_doi']),
      // Parse availability fields
      isAvailable: json['is_available'] == 1 || json['is_available'] == true,
      currentBookings: _safeToInt(json['current_bookings']),
      trangThaiText: json['trang_thai_text'],
      trangThaiColor: json['trang_thai_color'],
      totalRooms: _safeToInt(json['total_rooms']),
      availableCount: _safeToInt(json['available_count']),
      occupiedCount: _safeToInt(json['occupied_count']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'so_phong': soPhong,
      'loai_phong_id': loaiPhongId,
      'khach_san_id': khachSanId,
      'tinh_trang': tinhTrang,
      'mo_ta': moTa,
      'ngay_tao': ngayTao?.toIso8601String(),
      'ngay_cap_nhat': ngayCapNhat?.toIso8601String(),
    };
  }

  String get formattedPrice {
    if (giaPhong == null || !giaPhong!.isFinite || giaPhong!.isNaN) {
      return '500,000';
    }
    return giaPhong!.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
      (Match m) => '${m[1]},'
    );
  }

  Room copyWith({
    int? id,
    String? soPhong,
    int? loaiPhongId,
    int? khachSanId,
    bool? tinhTrang,
    String? moTa,
    DateTime? ngayTao,
    DateTime? ngayCapNhat,
    String? tenLoaiPhong,
    double? giaPhong,
    int? sucChua,
    List<String>? hinhAnhPhong,
    String? tenKhachSan,
    List<String>? tienNghi,
    int? soGiuongDon,
    int? soGiuongDoi,
    bool? isAvailable,
    int? currentBookings,
    String? trangThaiText,
    String? trangThaiColor,
  }) {
    return Room(
      id: id ?? this.id,
      soPhong: soPhong ?? this.soPhong,
      loaiPhongId: loaiPhongId ?? this.loaiPhongId,
      khachSanId: khachSanId ?? this.khachSanId,
      tinhTrang: tinhTrang ?? this.tinhTrang,
      moTa: moTa ?? this.moTa,
      ngayTao: ngayTao ?? this.ngayTao,
      ngayCapNhat: ngayCapNhat ?? this.ngayCapNhat,
      tenLoaiPhong: tenLoaiPhong ?? this.tenLoaiPhong,
      giaPhong: giaPhong ?? this.giaPhong,
      sucChua: sucChua ?? this.sucChua,
      hinhAnhPhong: hinhAnhPhong ?? this.hinhAnhPhong,
      tenKhachSan: tenKhachSan ?? this.tenKhachSan,
      tienNghi: tienNghi ?? this.tienNghi,
      soGiuongDon: soGiuongDon ?? this.soGiuongDon,
      soGiuongDoi: soGiuongDoi ?? this.soGiuongDoi,
      isAvailable: isAvailable ?? this.isAvailable,
      currentBookings: currentBookings ?? this.currentBookings,
      trangThaiText: trangThaiText ?? this.trangThaiText,
      trangThaiColor: trangThaiColor ?? this.trangThaiColor,
    );
  }

  String get statusText => trangThaiText ?? (tinhTrang ? 'Có sẵn' : 'Đã đặt');

  String get capacityText => sucChua != null ? '$sucChua khách' : 'N/A';

  @override
  String toString() {
    return 'Room{id: $id, soPhong: $soPhong, tenLoaiPhong: $tenLoaiPhong, giaPhong: $giaPhong}';
  }

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

  /// Get full image URLs for room images
  List<String> get fullImageUrls {
    if (hinhAnhPhong == null || hinhAnhPhong!.isEmpty) {
      return [ImageUrlHelper.getDefaultRoomImageUrl()];
    }
    return ImageUrlHelper.getRoomImageUrls(hinhAnhPhong!);
  }

  /// Get primary image URL
  String get primaryImageUrl {
    if (hinhAnhPhong == null || hinhAnhPhong!.isEmpty) {
      return ImageUrlHelper.getDefaultRoomImageUrl();
    }
    return ImageUrlHelper.getRoomImageUrl(hinhAnhPhong!.first);
  }
}
