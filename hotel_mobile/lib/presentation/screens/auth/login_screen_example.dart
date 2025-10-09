import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../widgets/facebook_login_button.dart';
import '../../../core/services/facebook_auth_service.dart';
import 'package:dio/dio.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final Dio _dio = Dio();

  // URL backend - thay đổi theo URL thực tế của bạn
  static const String _baseUrl = 'http://localhost:3000/api';

  Future<void> _handleFacebookLoginSuccess() async {
    try {
      // Lấy thông tin user hiện tại từ Facebook
      final facebookService = FacebookAuthService();
      final accessToken = await facebookService.getCurrentAccessToken();

      if (accessToken != null) {
        // Gửi access token đến backend để verify và tạo/đăng nhập user
        final response = await _dio.post(
          '$_baseUrl/auth/facebook-login',
          data: {'accessToken': accessToken},
        );

        if (response.data['success']) {
          // Đăng nhập thành công
          final user = response.data['user'];
          final token = response.data['token'];

          // Lưu token và thông tin user (ví dụ: shared_preferences)
          print('Đăng nhập thành công!');
          print('User: ${user['ho_ten']}');
          print('Email: ${user['email']}');
          print('Token: $token');

          // Navigate to home screen
          _showSuccessDialog(
            'Đăng nhập thành công!',
            'Chào mừng ${user['ho_ten']}',
          );
        } else {
          _showErrorDialog(
            'Đăng nhập thất bại',
            response.data['message'] ?? 'Có lỗi xảy ra',
          );
        }
      }
    } catch (e) {
      print('Lỗi khi gửi token đến backend: $e');
      _showErrorDialog('Lỗi kết nối', 'Không thể kết nối đến máy chủ');
    }
  }

  void _handleFacebookLoginError(String error) {
    _showErrorDialog('Lỗi đăng nhập Facebook', error);
  }

  void _handleFacebookLoginCancelled() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đăng nhập bị hủy bỏ'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng nhập'), centerTitle: true),
      body: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo hoặc title
            Text(
              'Trip Hotel',
              style: TextStyle(
                fontSize: 32.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),

            SizedBox(height: 48.h),

            // Form đăng nhập thông thường (email/password)
            // ... code form đăng nhập thông thường ...
            SizedBox(height: 32.h),

            // Divider
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Text(
                    'Hoặc',
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),

            SizedBox(height: 32.h),

            // Facebook Login Button
            FacebookLoginButton(
              onLoginSuccess: _handleFacebookLoginSuccess,
              onLoginError: _handleFacebookLoginError,
              onLoginCancelled: _handleFacebookLoginCancelled,
              margin: EdgeInsets.symmetric(vertical: 8.h),
            ),

            SizedBox(height: 16.h),

            // Facebook Icon Button (alternative style)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Hoặc đăng nhập nhanh: ',
                  style: TextStyle(fontSize: 14.sp),
                ),
                FacebookIconButton(
                  onLoginSuccess: _handleFacebookLoginSuccess,
                  onLoginError: _handleFacebookLoginError,
                  onLoginCancelled: _handleFacebookLoginCancelled,
                  size: 40.w,
                ),
              ],
            ),

            SizedBox(height: 32.h),

            // Register link
            TextButton(
              onPressed: () {
                // Navigate to register screen
              },
              child: Text(
                'Chưa có tài khoản? Đăng ký ngay',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
