import 'package:flutter/material.dart';
import '../data/services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_screen.dart';

/// Widget wrapper để quản lý trạng thái xác thực đơn giản
/// 
/// Chức năng:
/// - Kiểm tra trạng thái đăng nhập khi khởi động
/// - Hiển thị màn hình loading trong lúc kiểm tra
/// - Điều hướng dựa trên trạng thái đăng nhập:
///   - Đã đăng nhập → MainNavigationScreen
///   - Chưa đăng nhập → LoginScreen
/// 
/// Khác với MainWrapper: AuthWrapper không phân biệt vai trò (admin/hotel manager/user)
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  /// Service để kiểm tra trạng thái xác thực
  final AuthService _authService = AuthService();
  
  /// Trạng thái đang tải (đang kiểm tra xác thực)
  bool _isLoading = true;
  
  /// Trạng thái đã xác thực hay chưa
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    // Kiểm tra trạng thái xác thực ngay khi widget được khởi tạo
    _checkAuthState();
  }

  /// Kiểm tra trạng thái xác thực của người dùng
  /// 
  /// Quy trình:
  /// 1. Kiểm tra xem người dùng có đang đăng nhập không
  /// 2. Cập nhật trạng thái _isAuthenticated và _isLoading
  /// 3. Xử lý lỗi nếu có
  Future<void> _checkAuthState() async {
    try {
      // Check if user is authenticated and session is valid
      final isAuth = await _authService.isAuthenticated;

      setState(() {
        _isAuthenticated = isAuth;
        _isLoading = false;
      });

      if (isAuth && _authService.currentUser != null) {
        print('✅ User authenticated: ${_authService.currentUser!.email}');
      } else {
        print('❌ User not authenticated or session expired');
      }
    } catch (e) {
      print('Error checking auth state: $e');
      setState(() {
        _isAuthenticated = false;
        _isLoading = false;
      });
    }
  }

  /// Xây dựng giao diện dựa trên trạng thái xác thực
  /// 
  /// Trả về:
  /// - Loading screen nếu đang kiểm tra (_isLoading = true)
  /// - MainNavigationScreen nếu đã đăng nhập (_isAuthenticated = true)
  /// - LoginScreen nếu chưa đăng nhập (_isAuthenticated = false)
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
                'Đang kiểm tra phiên đăng nhập...',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // Return appropriate screen based on authentication state
    return _isAuthenticated
        ? const MainNavigationScreen()
        : const LoginScreen();
  }
}
