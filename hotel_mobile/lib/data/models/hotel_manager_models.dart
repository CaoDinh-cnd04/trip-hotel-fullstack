class HotelInfo {
  final int id;
  final String tenKhachSan;
  final String moTa;
  final String hinhAnh;
  final int soSao;
  final String trangThai;
  final String diaChi;
  final String tenViTri;
  final String tenTinhThanh;
  final String tenQuocGia;
  final String? emailLienHe;
  final String? sdtLienHe;
  final String? website;
  final String? gioNhanPhong;
  final String? gioTraPhong;
  final String? chinhSachHuy;
  final int? tongSoPhong;
  final double? diemDanhGiaTrungBinh;
  final int? soLuotDanhGia;

  HotelInfo({
    required this.id,
    required this.tenKhachSan,
    required this.moTa,
    required this.hinhAnh,
    required this.soSao,
    required this.trangThai,
    required this.diaChi,
    required this.tenViTri,
    required this.tenTinhThanh,
    required this.tenQuocGia,
    this.emailLienHe,
    this.sdtLienHe,
    this.website,
    this.gioNhanPhong,
    this.gioTraPhong,
    this.chinhSachHuy,
    this.tongSoPhong,
    this.diemDanhGiaTrungBinh,
    this.soLuotDanhGia,
  });

  factory HotelInfo.fromJson(Map<String, dynamic> json) {
    return HotelInfo(
      id: json['id'] ?? 0,
      tenKhachSan: json['ten_khach_san'] ?? '',
      moTa: json['mo_ta'] ?? '',
      hinhAnh: json['hinh_anh'] ?? '',
      soSao: json['so_sao'] ?? 0,
      trangThai: json['trang_thai'] ?? '',
      diaChi: json['dia_chi'] ?? '',
      tenViTri: json['ten_vi_tri'] ?? '',
      tenTinhThanh: json['ten_tinh_thanh'] ?? '',
      tenQuocGia: json['ten_quoc_gia'] ?? '',
      emailLienHe: json['email_lien_he'],
      sdtLienHe: json['sdt_lien_he'],
      website: json['website'],
      gioNhanPhong: json['gio_nhan_phong'],
      gioTraPhong: json['gio_tra_phong'],
      chinhSachHuy: json['chinh_sach_huy'],
      tongSoPhong: json['tong_so_phong'],
      diemDanhGiaTrungBinh: json['diem_danh_gia_trung_binh']?.toDouble(),
      soLuotDanhGia: json['so_luot_danh_gia'],
    );
  }
}

class HotelStats {
  final int totalRooms;
  final int availableRooms;
  final int totalBookings;
  final int completedBookings;
  final int pendingBookings;
  final double totalRevenue;
  final double averageRating;
  final int totalReviews;

  HotelStats({
    required this.totalRooms,
    required this.availableRooms,
    required this.totalBookings,
    required this.completedBookings,
    required this.pendingBookings,
    required this.totalRevenue,
    required this.averageRating,
    required this.totalReviews,
  });

  factory HotelStats.fromJson(Map<String, dynamic> json) {
    return HotelStats(
      totalRooms: json['totalRooms'] ?? 0,
      availableRooms: json['availableRooms'] ?? 0,
      totalBookings: json['totalBookings'] ?? 0,
      completedBookings: json['completedBookings'] ?? 0,
      pendingBookings: json['pendingBookings'] ?? 0,
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
    );
  }
}

class DashboardKpi {
  final int totalRooms;
  final int availableRooms;
  final int occupiedRooms;
  final int totalBookings;
  final int todayBookings;
  final int ongoingBookings;
  final int completedBookings;
  final int pendingBookings;
  final int cancelledBookings;
  final double totalRevenue;
  final double todayRevenue;
  final double monthlyRevenue;
  final double occupancyRate;
  final double averageRating;
  final int totalReviews;
  final List<RevenueChartData> revenueChart;

  DashboardKpi({
    required this.totalRooms,
    required this.availableRooms,
    required this.occupiedRooms,
    required this.totalBookings,
    required this.todayBookings,
    required this.ongoingBookings,
    required this.completedBookings,
    required this.pendingBookings,
    required this.cancelledBookings,
    required this.totalRevenue,
    required this.todayRevenue,
    required this.monthlyRevenue,
    required this.occupancyRate,
    required this.averageRating,
    required this.totalReviews,
    required this.revenueChart,
  });

  factory DashboardKpi.fromJson(Map<String, dynamic> json) {
    // Parse revenue chart data
    List<RevenueChartData> revenueChart = [];
    if (json['revenueChart'] != null && json['revenueChart'] is List) {
      revenueChart = (json['revenueChart'] as List)
          .map((item) => RevenueChartData.fromJson(item))
          .toList();
    }

    return DashboardKpi(
      totalRooms: json['totalRooms'] ?? 0,
      availableRooms: json['availableRooms'] ?? 0,
      occupiedRooms: json['occupiedRooms'] ?? 0,
      totalBookings: json['totalBookings'] ?? 0,
      todayBookings: json['todayBookings'] ?? 0,
      ongoingBookings: json['ongoingBookings'] ?? 0,
      completedBookings: json['completedBookings'] ?? 0,
      pendingBookings: json['pendingBookings'] ?? 0,
      cancelledBookings: json['cancelledBookings'] ?? 0,
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      todayRevenue: (json['todayRevenue'] ?? 0).toDouble(),
      monthlyRevenue: (json['monthlyRevenue'] ?? 0).toDouble(),
      occupancyRate: (json['occupancyRate'] ?? 0).toDouble(),
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      revenueChart: revenueChart,
    );
  }
}

class RevenueChartData {
  final DateTime date;
  final double revenue;

  RevenueChartData({
    required this.date,
    required this.revenue,
  });

  factory RevenueChartData.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic dateValue) {
      if (dateValue == null) return DateTime.now();
      try {
        if (dateValue is String) {
          return DateTime.parse(dateValue);
        } else if (dateValue is DateTime) {
          return dateValue;
        }
        return DateTime.now();
      } catch (e) {
        return DateTime.now();
      }
    }

    return RevenueChartData(
      date: parseDate(json['date']),
      revenue: (json['revenue'] ?? 0).toDouble(),
    );
  }
}

class Room {
  final String maPhong;
  final String soPhong;
  final double giaPhong;
  final String trangThai;
  final String moTa;
  final String tenLoaiPhong;
  final int soGiuong;
  final int soNguoiMax;
  final String? hinhAnh;

  Room({
    required this.maPhong,
    required this.soPhong,
    required this.giaPhong,
    required this.trangThai,
    required this.moTa,
    required this.tenLoaiPhong,
    required this.soGiuong,
    required this.soNguoiMax,
    this.hinhAnh,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      maPhong: json['ma_phong'] ?? '',
      soPhong: json['so_phong'] ?? '',
      giaPhong: (json['gia_phong'] ?? 0).toDouble(),
      trangThai: json['trang_thai'] ?? '',
      moTa: json['mo_ta'] ?? '',
      tenLoaiPhong: json['ten_loai_phong'] ?? '',
      soGiuong: json['so_giuong'] ?? 0,
      soNguoiMax: json['so_nguoi_max'] ?? 0,
      hinhAnh: json['hinh_anh'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'so_phong': soPhong,
      'gia_phong': giaPhong,
      'trang_thai': trangThai,
      'mo_ta': moTa,
      'hinh_anh': hinhAnh,
    };
  }
}

class Booking {
  final String maPhieuDat;
  final String maNguoiDung;
  final String maPhong;
  final DateTime ngayNhanPhong;
  final DateTime ngayTraPhong;
  final int soDemLuuTru;
  final double tongTien;
  final String trangThai;
  final DateTime ngayTao;
  final String soPhong;
  final String tenKhachHang;
  final String emailKhachHang;
  final String sdtKhachHang;

  Booking({
    required this.maPhieuDat,
    required this.maNguoiDung,
    required this.maPhong,
    required this.ngayNhanPhong,
    required this.ngayTraPhong,
    required this.soDemLuuTru,
    required this.tongTien,
    required this.trangThai,
    required this.ngayTao,
    required this.soPhong,
    required this.tenKhachHang,
    required this.emailKhachHang,
    required this.sdtKhachHang,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      maPhieuDat: json['ma_phieu_dat'] ?? '',
      maNguoiDung: json['ma_nguoi_dung'] ?? '',
      maPhong: json['ma_phong'] ?? '',
      ngayNhanPhong: DateTime.parse(json['ngay_nhan_phong']),
      ngayTraPhong: DateTime.parse(json['ngay_tra_phong']),
      soDemLuuTru: json['so_dem_luu_tru'] ?? 0,
      tongTien: (json['tong_tien'] ?? 0).toDouble(),
      trangThai: json['trang_thai'] ?? '',
      ngayTao: DateTime.parse(json['ngay_tao']),
      soPhong: json['so_phong'] ?? '',
      tenKhachHang: json['ten_khach_hang'] ?? '',
      emailKhachHang: json['email_khach_hang'] ?? '',
      sdtKhachHang: json['sdt_khach_hang'] ?? '',
    );
  }
}

class Review {
  final String maDanhGia;
  final int diemDanhGia;
  final String noiDung;
  final DateTime ngayDanhGia;
  final String? phanHoi;
  final String tenKhachHang;
  final String soPhong;

  Review({
    required this.maDanhGia,
    required this.diemDanhGia,
    required this.noiDung,
    required this.ngayDanhGia,
    this.phanHoi,
    required this.tenKhachHang,
    required this.soPhong,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    // ✅ FIX: Handle null values properly - map API field names correctly
    // API returns: id, so_sao_tong, binh_luan, ngay, phan_hoi_khach_san, ten_khach_hang
    // But no so_phong field, so we need to handle it
    
    // Parse date with null safety
    DateTime parseDate(dynamic dateValue) {
      if (dateValue == null) return DateTime.now();
      try {
        if (dateValue is String) {
          return DateTime.parse(dateValue);
        } else if (dateValue is DateTime) {
          return dateValue;
        }
        return DateTime.now();
      } catch (e) {
        print('⚠️ Error parsing date: $dateValue, using current date');
        return DateTime.now();
      }
    }
    
    return Review(
      maDanhGia: json['ma_danh_gia']?.toString() ?? 
                 json['id']?.toString() ?? 
                 '',
      diemDanhGia: json['diem_danh_gia'] ?? 
                   json['so_sao_tong'] ?? 
                   json['rating'] ?? 
                   0,
      noiDung: json['noi_dung']?.toString() ?? 
               json['binh_luan']?.toString() ?? 
               json['content']?.toString() ?? 
               '',
      ngayDanhGia: parseDate(json['ngay_danh_gia'] ?? 
                              json['ngay'] ?? 
                              json['reviewed_at'] ?? 
                              json['createdAt']),
      phanHoi: json['phan_hoi']?.toString() ?? 
               json['phan_hoi_khach_san']?.toString() ?? 
               json['reply']?.toString(),
      tenKhachHang: json['ten_khach_hang']?.toString() ?? 
                    json['ho_ten']?.toString() ?? 
                    json['customerName']?.toString() ?? 
                    'Khách hàng',
      soPhong: json['so_phong']?.toString() ?? 
               json['room_number']?.toString() ?? 
               json['so_phong_dat']?.toString() ?? 
               'N/A', // API might not return this, use default
    );
  }
}
