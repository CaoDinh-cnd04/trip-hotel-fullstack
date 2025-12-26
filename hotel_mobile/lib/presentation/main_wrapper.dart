import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/services/auth_service.dart';
import '../data/services/backend_auth_service.dart';
import '../core/theme/vip_theme_provider.dart';
import '../core/services/currency_service.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/auth/triphotel_style_login_screen.dart';
import 'screens/admin/admin_main_screen.dart';
import 'screens/hotel_manager/hotel_manager_main_screen.dart';
import '../../data/models/user_role_model.dart';

/// Widget wrapper chính để điều hướng dựa trên vai trò người dùng
/// 
/// Chức năng:
/// - Kiểm tra trạng thái đăng nhập khi khởi động
/// - Phân biệt vai trò: Admin, Hotel Manager, hoặc User thường
/// - Hiển thị giao diện phù hợp với từng vai trò:
///   - Admin → AdminMainScreen
///   - Hotel Manager → HotelManagerMainScreen
///   - User thường → MainNavigationScreen
/// 
/// Khác với AuthWrapper: MainWrapper có khả năng phân biệt vai trò và điều hướng phức tạp hơn
class MainWrapper extends StatefulWidget {
  const MainWrapper({Key? key}) : super(key: key);

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  /// Service để kiểm tra trạng thái xác thực Firebase
  final AuthService _authService = AuthService();
  
  /// Service để kiểm tra trạng thái xác thực backend và vai trò
  final BackendAuthService _backendAuthService = BackendAuthService();
  
  /// Trạng thái đang tải (đang kiểm tra xác thực và vai trò)
  bool _isLoading = true;
  
  /// Trạng thái đã xác thực hay chưa
  bool _isAuthenticated = false;
  
  /// Trạng thái có phải admin không
  bool _isAdmin = false;
  
  /// Trạng thái có phải hotel manager không
  bool _isHotelManager = false;

  @override
  void initState() {
    super.initState();
    // Khởi tạo trạng thái xác thực
    _initializeAuthState();
    
    // Kiểm tra định kỳ trạng thái xác thực mỗi 2 giây (fallback)
    // Dừng timer khi đã xác nhận là admin để tránh kiểm tra không cần thiết
    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        _checkAuthState();
        if (_isAdmin && _isAuthenticated) {
          timer.cancel();
        }
      } else {
        timer.cancel();
      }
    });
  }

  /// Khởi tạo trạng thái xác thực khi widget được tạo
  /// 
  /// Quy trình:
  /// 1. Khôi phục dữ liệu người dùng từ local storage
  /// 2. Kiểm tra trạng thái đăng nhập và vai trò người dùng
  Future<void> _initializeAuthState() async {
    // Force restore user data from storage first
    await _backendAuthService.restoreUserData();
    await _checkAuthState();
  }

  /// Kiểm tra trạng thái đăng nhập và vai trò của người dùng
  /// 
  /// Quy trình:
  /// 1. Kiểm tra xác thực từ AuthService và BackendAuthService
  /// 2. Xác định vai trò: Admin, Hotel Manager, hoặc User thường
  ///    - Ưu tiên: Kiểm tra từ UserRoleModel (backendUserRole)
  ///    - Fallback: Kiểm tra từ User.chucVu nếu không có UserRoleModel
  /// 3. Cập nhật trạng thái UI dựa trên vai trò
  /// 4. Hiển thị giao diện tương ứng
  /// 
  /// Hỗ trợ nhiều format cho Hotel Manager:
  /// - "hotelmanager", "hotel_manager", "hotel manager", "manager"
  /// - Hoặc bất kỳ chuỗi nào chứa cả "hotel" và "manager"
  Future<void> _checkAuthState() async {
    try {
      // Check if user is authenticated and session is valid
      final isAuth = await _authService.isAuthenticated;
      final backendIsAuth = _backendAuthService.currentUser != null;
      
      // Check user role
      bool isAdmin = false;
      bool isHotelManager = false;
      if (isAuth || backendIsAuth) {
        final backendUser = _backendAuthService.currentUser;
        final backendUserRole = _backendAuthService.currentUserRole;
        
        if (backendUserRole != null) {
          isAdmin = backendUserRole.isAdmin;
          isHotelManager = backendUserRole.role == UserRole.hotelManager;
          print('🔍 ===== ROLE CHECK (FROM UserRoleModel) =====');
          print('🔍 User role VALUE: ${backendUserRole.role.value}');
          print('🔍 User role ENUM: ${backendUserRole.role}');
          print('🔍 Is admin (from isAdmin getter): $isAdmin');
          print('🔍 Is hotel manager: $isHotelManager');
          print('🔍 ==========================================');
        } else if (backendUser != null) {
          // Fallback: check user role from backend user data
          final chucVu = backendUser.chucVu?.toLowerCase()?.trim() ?? '';
          isAdmin = chucVu == 'admin';
          // ✅ FIX: Check nhiều format của HotelManager role
          isHotelManager = chucVu == 'hotelmanager' || 
                           chucVu == 'hotel_manager' || 
                           chucVu == 'hotel manager' ||
                           chucVu == 'manager' ||
                           chucVu.contains('hotel') && chucVu.contains('manager');
          print('🔍 ===== ROLE CHECK (FALLBACK from User.chucVu) =====');
          print('🔍 User chucVu (original): ${backendUser.chucVu}');
          print('🔍 User chucVu (lowercase): $chucVu');
          print('🔍 Is admin (chucVu == "admin"): $isAdmin');
          print('🔍 Is hotel manager: $isHotelManager');
          print('🔍 ==========================================');
        } else {
          print('⚠️ WARNING: Both backendUserRole and backendUser are NULL!');
        }
        
        // Debug: Print all user info
        print('🔍 Debug - Backend user: $backendUser');
        print('🔍 Debug - Backend user role: $backendUserRole');
      }

      setState(() {
        _isAuthenticated = isAuth || backendIsAuth;
        _isAdmin = isAdmin;
        _isHotelManager = isHotelManager;
        _isLoading = false;
      });

      print('🔍 MainWrapper Debug:');
      print('🔍 isAuth: $isAuth');
      print('🔍 backendIsAuth: $backendIsAuth');
      print('🔍 _isAuthenticated: ${_isAuthenticated}');
      print('🔍 _isAdmin: $isAdmin');
      print('🔍 _isHotelManager: $isHotelManager');

      // Force refresh if admin user detected
      if (isAdmin && backendIsAuth) {
        print('👑 Admin user detected - forcing UI refresh');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _isAuthenticated = true;
              _isAdmin = true;
              _isLoading = false;
            });
          }
        });
      }

      if (isAuth && _authService.currentUser != null) {
        print('✅ User authenticated: ${_authService.currentUser!.email}');
        
        // ✅ Refresh VIP theme và Currency sau khi user đăng nhập
        if (mounted) {
          try {
            final vipThemeProvider = Provider.of<VipThemeProvider>(context, listen: false);
            vipThemeProvider.refreshVipLevel();
            print('🔄 [MainWrapper] Refreshed VIP theme after login');
            
            // Refresh currency từ API
            CurrencyService.instance.refreshCurrency();
            print('🔄 [MainWrapper] Refreshed currency after login');
          } catch (e) {
            print('⚠️ [MainWrapper] Error refreshing settings: $e');
          }
        }
        
        if (isAdmin) {
          print('👑 Admin user detected - showing admin interface');
        } else if (isHotelManager) {
          print('🏨 Hotel Manager detected - showing hotel manager interface');
        } else {
          print('👤 Regular user - showing main interface');
        }
      } else {
        print('ℹ️ User not authenticated - showing main interface');
      }
    } catch (e) {
      print('Error checking auth state: $e');
      setState(() {
        _isAuthenticated = false;
        _isAdmin = false;
        _isHotelManager = false;
        _isLoading = false;
      });
    }
  }

  /// Làm mới trạng thái xác thực khi người dùng đăng nhập/đăng xuất
  /// 
  /// Được gọi từ các màn hình con khi có thay đổi về trạng thái đăng nhập
  /// Ví dụ: Sau khi đăng nhập thành công, hoặc khi đăng xuất
  Future<void> refreshAuthState() async {
    await _checkAuthState();
  }

  /// Xây dựng giao diện dựa trên trạng thái xác thực và vai trò người dùng
  /// 
  /// Trả về:
  /// - Loading screen nếu đang kiểm tra (_isLoading = true)
  /// - AdminMainScreen nếu là admin (_isAdmin = true)
  /// - HotelManagerMainScreen nếu là hotel manager (_isHotelManager = true)
  /// - MainNavigationScreen nếu là user thường hoặc chưa đăng nhập
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Đang khởi tạo ứng dụng...',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // Show appropriate interface based on user role
    if (_isAdmin) {
      return const AdminMainScreen();
    } else if (_isHotelManager) {
      return const HotelManagerMainScreen();
    } else {
      return MainNavigationScreen(
        isAuthenticated: _isAuthenticated,
        onAuthStateChanged: refreshAuthState,
      );
    }
  }
}
