/// Model đại diện cho KPI (Key Performance Indicators) của Admin Dashboard
/// 
/// Chứa thông tin:
/// - Thống kê users: totalUsers, activeUsers, newUsersThisMonth
/// - Thống kê hotels: totalHotels, activeHotels
/// - Thống kê bookings: totalBookings, completedBookings, pendingBookings
/// - Thống kê revenue: totalRevenue, monthlyRevenue
/// - Phân bổ: userRoleDistribution, bookingStatusDistribution
/// - Tăng trưởng: monthlyGrowth
/// - Tương thích: tongSoKhachSan, tongSoNguoiDung, hoSoChoDuyet, phanBoChucVu
class AdminKpiModel {
  final int totalUsers;
  final int activeUsers;
  final int newUsersThisMonth;
  final int totalHotels;
  final int activeHotels;
  final int totalBookings;
  final int completedBookings;
  final int pendingBookings;
  final double totalRevenue;
  final double monthlyRevenue;
  final List<UserRoleDistribution> userRoleDistribution;
  final List<BookingStatusDistribution> bookingStatusDistribution;
  final MonthlyGrowth monthlyGrowth;
  
  // Additional fields for compatibility
  final int tongSoKhachSan;
  final int tongSoNguoiDung;
  final int hoSoChoDuyet;
  final List<String> phanBoChucVu;

  AdminKpiModel({
    required this.totalUsers,
    required this.activeUsers,
    required this.newUsersThisMonth,
    required this.totalHotels,
    required this.activeHotels,
    required this.totalBookings,
    required this.completedBookings,
    required this.pendingBookings,
    required this.totalRevenue,
    required this.monthlyRevenue,
    required this.userRoleDistribution,
    required this.bookingStatusDistribution,
    required this.monthlyGrowth,
    this.tongSoKhachSan = 0,
    this.tongSoNguoiDung = 0,
    this.hoSoChoDuyet = 0,
    this.phanBoChucVu = const [],
  });

  /// Tạo đối tượng AdminKpiModel từ JSON
  /// 
  /// [json] - Map chứa dữ liệu JSON từ API
  /// 
  /// Parse các trường từ JSON, xử lý các nested objects (UserRoleDistribution, BookingStatusDistribution, MonthlyGrowth)
  factory AdminKpiModel.fromJson(Map<String, dynamic> json) {
    return AdminKpiModel(
      totalUsers: json['totalUsers'] ?? 0,
      activeUsers: json['activeUsers'] ?? 0,
      newUsersThisMonth: json['newUsersThisMonth'] ?? 0,
      totalHotels: json['totalHotels'] ?? 0,
      activeHotels: json['activeHotels'] ?? 0,
      totalBookings: json['totalBookings'] ?? 0,
      completedBookings: json['completedBookings'] ?? 0,
      pendingBookings: json['pendingBookings'] ?? 0,
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      monthlyRevenue: (json['monthlyRevenue'] ?? 0).toDouble(),
      userRoleDistribution: (json['userRoleDistribution'] as List<dynamic>?)
          ?.map((item) => UserRoleDistribution.fromJson(item))
          .toList() ?? [],
      bookingStatusDistribution: (json['bookingStatusDistribution'] as List<dynamic>?)
          ?.map((item) => BookingStatusDistribution.fromJson(item))
          .toList() ?? [],
      monthlyGrowth: MonthlyGrowth.fromJson(json['monthlyGrowth'] ?? {}),
      tongSoKhachSan: json['tongSoKhachSan'] ?? json['totalHotels'] ?? 0,
      tongSoNguoiDung: json['tongSoNguoiDung'] ?? json['totalUsers'] ?? 0,
      hoSoChoDuyet: json['hoSoChoDuyet'] ?? json['pendingBookings'] ?? 0,
      phanBoChucVu: (json['phanBoChucVu'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  /// Tạo đối tượng AdminKpiModel với dữ liệu mock để testing
  /// 
  /// Trả về AdminKpiModel với các giá trị mẫu phù hợp để test UI
  factory AdminKpiModel.mock() {
    return AdminKpiModel(
      totalUsers: 1250,
      activeUsers: 1100,
      newUsersThisMonth: 85,
      totalHotels: 45,
      activeHotels: 42,
      totalBookings: 3200,
      completedBookings: 2800,
      pendingBookings: 400,
      totalRevenue: 125000000.0,
      monthlyRevenue: 8500000.0,
      userRoleDistribution: [
        UserRoleDistribution(role: 'User', count: 1000),
        UserRoleDistribution(role: 'HotelManager', count: 45),
        UserRoleDistribution(role: 'Admin', count: 5),
      ],
      bookingStatusDistribution: [
        BookingStatusDistribution(status: 'completed', count: 2800),
        BookingStatusDistribution(status: 'pending', count: 400),
        BookingStatusDistribution(status: 'cancelled', count: 200),
      ],
      monthlyGrowth: MonthlyGrowth(
        users: 12.5,
        bookings: 18.3,
        revenue: 22.1,
      ),
    );
  }
}

/// Model đại diện cho phân bổ vai trò người dùng
/// 
/// Chứa: role (tên vai trò) và count (số lượng)
class UserRoleDistribution {
  final String role;
  final int count;

  UserRoleDistribution({
    required this.role,
    required this.count,
  });

  /// Tạo đối tượng UserRoleDistribution từ JSON
  /// 
  /// [json] - Map chứa dữ liệu JSON từ API
  factory UserRoleDistribution.fromJson(Map<String, dynamic> json) {
    return UserRoleDistribution(
      role: json['role'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}

/// Model đại diện cho phân bổ trạng thái booking
/// 
/// Chứa: status (trạng thái) và count (số lượng)
class BookingStatusDistribution {
  final String status;
  final int count;

  BookingStatusDistribution({
    required this.status,
    required this.count,
  });

  /// Tạo đối tượng BookingStatusDistribution từ JSON
  /// 
  /// [json] - Map chứa dữ liệu JSON từ API
  factory BookingStatusDistribution.fromJson(Map<String, dynamic> json) {
    return BookingStatusDistribution(
      status: json['status'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}

/// Model đại diện cho tăng trưởng hàng tháng
/// 
/// Chứa phần trăm tăng trưởng: users (người dùng), bookings (đặt phòng), revenue (doanh thu)
class MonthlyGrowth {
  final double users;
  final double bookings;
  final double revenue;

  MonthlyGrowth({
    required this.users,
    required this.bookings,
    required this.revenue,
  });

  /// Tạo đối tượng MonthlyGrowth từ JSON
  /// 
  /// [json] - Map chứa dữ liệu JSON từ API
  /// 
  /// Parse các trường phần trăm tăng trưởng
  factory MonthlyGrowth.fromJson(Map<String, dynamic> json) {
    return MonthlyGrowth(
      users: (json['users'] ?? 0).toDouble(),
      bookings: (json['bookings'] ?? 0).toDouble(),
      revenue: (json['revenue'] ?? 0).toDouble(),
    );
  }
}

/// Extension cho AdminKpiModel để thêm các phương thức tiện ích
extension AdminKpiModelExtensions on AdminKpiModel {
  /// Lấy doanh thu đã được format (M/K hoặc số)
  /// 
  /// Ví dụ: 125000000 -> "125.0M", 850000 -> "850.0K"
  String get formattedDoanhThu {
    if (totalRevenue >= 1000000) {
      return '${(totalRevenue / 1000000).toStringAsFixed(1)}M';
    } else if (totalRevenue >= 1000) {
      return '${(totalRevenue / 1000).toStringAsFixed(1)}K';
    } else {
      return totalRevenue.toStringAsFixed(0);
    }
  }
}