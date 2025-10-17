import '../models/user_role_model.dart';
import 'backend_auth_service.dart';

class RolePermissionService {
  static final RolePermissionService _instance = RolePermissionService._internal();
  factory RolePermissionService() => _instance;
  RolePermissionService._internal();

  final BackendAuthService _authService = BackendAuthService();

  /// Get current user role
  UserRoleModel? get currentUserRole => _authService.currentUserRole;

  /// Check if current user has specific role
  bool hasRole(UserRole role) {
    return currentUserRole?.role == role;
  }

  /// Check if current user is admin
  bool get isAdmin => hasRole(UserRole.admin);

  /// Check if current user is hotel manager
  bool get isHotelManager => hasRole(UserRole.hotelManager);

  /// Check if current user is regular user
  bool get isUser => hasRole(UserRole.user);

  /// Check if current user has specific permission
  bool hasPermission(String permission) {
    return currentUserRole?.hasPermission(permission) ?? false;
  }

  /// Check if current user can access admin features
  bool get canAccessAdmin => isAdmin;

  /// Check if current user can access hotel manager features
  bool get canAccessHotelManager => isAdmin || isHotelManager;

  /// Check if current user can manage users
  bool get canManageUsers => isAdmin;

  /// Check if current user can manage hotels
  bool get canManageHotels => isAdmin || isHotelManager;

  /// Check if current user can manage bookings
  bool get canManageBookings => isAdmin || isHotelManager;

  /// Check if current user can manage rooms
  bool get canManageRooms => isAdmin || isHotelManager;

  /// Check if current user can manage promotions
  bool get canManagePromotions => isAdmin || isHotelManager;

  /// Get role display name
  String get roleDisplayName => currentUserRole?.role.displayName ?? 'Không xác định';

  /// Get role-based navigation items
  List<NavigationItem> getNavigationItems() {
    if (isAdmin) {
      return _getAdminNavigationItems();
    } else if (isHotelManager) {
      return _getHotelManagerNavigationItems();
    } else {
      return _getUserNavigationItems();
    }
  }

  List<NavigationItem> _getAdminNavigationItems() {
    return [
      NavigationItem(
        title: 'Trang chủ',
        route: '/main',
        icon: 'home',
        permissions: [],
      ),
      NavigationItem(
        title: 'Quản lý người dùng',
        route: '/admin/users',
        icon: 'people',
        permissions: ['user:read', 'user:write'],
      ),
      NavigationItem(
        title: 'Quản lý khách sạn',
        route: '/admin/hotels',
        icon: 'hotel',
        permissions: ['hotel:read', 'hotel:write'],
      ),
      NavigationItem(
        title: 'Quản lý đặt phòng',
        route: '/admin/bookings',
        icon: 'booking',
        permissions: ['booking:read', 'booking:write'],
      ),
      NavigationItem(
        title: 'Thống kê',
        route: '/admin/statistics',
        icon: 'analytics',
        permissions: ['system:admin'],
      ),
      NavigationItem(
        title: 'Cài đặt hệ thống',
        route: '/admin/settings',
        icon: 'settings',
        permissions: ['system:admin'],
      ),
    ];
  }

  List<NavigationItem> _getHotelManagerNavigationItems() {
    return [
      NavigationItem(
        title: 'Trang chủ',
        route: '/main',
        icon: 'home',
        permissions: [],
      ),
      NavigationItem(
        title: 'Quản lý khách sạn',
        route: '/hotel-manager/dashboard',
        icon: 'hotel',
        permissions: ['hotel:read', 'hotel:write'],
      ),
      NavigationItem(
        title: 'Quản lý phòng',
        route: '/hotel-manager/rooms',
        icon: 'room',
        permissions: ['room:read', 'room:write'],
      ),
      NavigationItem(
        title: 'Đặt phòng',
        route: '/hotel-manager/bookings',
        icon: 'booking',
        permissions: ['booking:read', 'booking:write'],
      ),
      NavigationItem(
        title: 'Khuyến mãi',
        route: '/hotel-manager/promotions',
        icon: 'promotion',
        permissions: ['promotion:read', 'promotion:write'],
      ),
      NavigationItem(
        title: 'Thống kê',
        route: '/hotel-manager/statistics',
        icon: 'analytics',
        permissions: ['hotel:read'],
      ),
    ];
  }

  List<NavigationItem> _getUserNavigationItems() {
    return [
      NavigationItem(
        title: 'Trang chủ',
        route: '/main',
        icon: 'home',
        permissions: [],
      ),
      NavigationItem(
        title: 'Tìm kiếm khách sạn',
        route: '/search',
        icon: 'search',
        permissions: ['hotel:read'],
      ),
      NavigationItem(
        title: 'Đặt phòng của tôi',
        route: '/my-bookings',
        icon: 'booking',
        permissions: ['booking:read'],
      ),
      NavigationItem(
        title: 'Ưu đãi',
        route: '/deals',
        icon: 'promotion',
        permissions: ['hotel:read'],
      ),
      NavigationItem(
        title: 'Tài khoản',
        route: '/profile',
        icon: 'account',
        permissions: [],
      ),
    ];
  }

  /// Check if user can access specific route
  bool canAccessRoute(String route) {
    final navigationItems = getNavigationItems();
    final item = navigationItems.firstWhere(
      (item) => item.route == route,
      orElse: () => NavigationItem(
        title: '',
        route: route,
        icon: '',
        permissions: [],
      ),
    );

    if (item.permissions.isEmpty) return true;
    
    return item.permissions.any((permission) => hasPermission(permission));
  }

  /// Get role-based welcome message
  String getWelcomeMessage() {
    if (isAdmin) {
      return 'Chào mừng Quản trị viên';
    } else if (isHotelManager) {
      return 'Chào mừng Quản lý khách sạn';
    } else {
      return 'Chào mừng bạn đến với Hotel Booking';
    }
  }

  /// Get role-based dashboard route
  String getDashboardRoute() {
    if (isAdmin) {
      return '/admin/dashboard';
    } else if (isHotelManager) {
      return '/hotel-manager/dashboard';
    } else {
      return '/main';
    }
  }
}

class NavigationItem {
  final String title;
  final String route;
  final String icon;
  final List<String> permissions;

  NavigationItem({
    required this.title,
    required this.route,
    required this.icon,
    required this.permissions,
  });
}
