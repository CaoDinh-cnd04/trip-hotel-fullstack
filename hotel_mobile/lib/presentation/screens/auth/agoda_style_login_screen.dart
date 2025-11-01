import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'otp_screen.dart';
import '../../../data/services/backend_auth_service.dart';
import '../../../data/services/otp_auth_service.dart';

/// Màn hình đăng nhập theo phong cách Agoda
/// 
/// Cung cấp 3 phương thức đăng nhập:
/// 1. **Email + OTP** - Đăng nhập/đăng ký bằng email, nhận mã OTP qua email
/// 2. **Google Sign-In** - Đăng nhập nhanh bằng tài khoản Google
/// 3. **Facebook Login** - Đăng nhập bằng tài khoản Facebook
/// 
/// Thiết kế:
/// - UI hiện đại, clean với background trắng
/// - Social login buttons với màu brand
/// - Hỗ trợ WillPopScope để xử lý nút back
class AgodaStyleLoginScreen extends StatefulWidget {
  const AgodaStyleLoginScreen({super.key});

  @override
  State<AgodaStyleLoginScreen> createState() => _AgodaStyleLoginScreenState();
}

class _AgodaStyleLoginScreenState extends State<AgodaStyleLoginScreen> {
  /// Controller cho trường nhập email
  final _emailController = TextEditingController();
  
  /// Service xử lý authentication với backend
  final _authService = BackendAuthService();
  
  /// Service xử lý OTP authentication
  late final OTPAuthService _otpAuthService;
  
  /// Trạng thái email hợp lệ (format đúng)
  bool _isEmailValid = false;
  
  /// Trạng thái đang loading
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateEmail);
    
    // Initialize OTP service
    final dio = Dio();
    _otpAuthService = OTPAuthService(dio, _authService);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// Validate định dạng email
  /// 
  /// Sử dụng RegEx để kiểm tra email hợp lệ
  /// Cập nhật trạng thái [_isEmailValid] để enable/disable button
  void _validateEmail() {
    setState(() {
      _isEmailValid = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text);
    });
  }

  /// Xử lý tiếp tục với email
  /// 
  /// Quy trình:
  /// 1. Validate email
  /// 2. Gửi OTP đến email
  /// 3. Navigate đến màn hình nhập OTP
  Future<void> _continueWithEmail() async {
    if (!_isEmailValid || _isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      print('📧 Đang gửi OTP đến: ${_emailController.text}');
      
      // Gửi OTP trước khi navigate
      final result = await _otpAuthService.sendOTP(_emailController.text);
      
      if (result.isSuccess && mounted) {
        print('✅ OTP đã gửi thành công!');
        
        // Hiển thị thông báo
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📧 Mã OTP đã được gửi đến email của bạn!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Navigate to OTP screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OTPScreen(email: _emailController.text),
          ),
        );
      } else if (mounted) {
        // Hiển thị lỗi
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Không thể gửi mã OTP'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Lỗi gửi OTP: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Xử lý đăng nhập bằng Google
  /// 
  /// Quy trình:
  /// 1. Gọi Google Sign-In API
  /// 2. Đồng bộ với backend Firebase
  /// 3. Navigate về MainWrapper nếu thành công
  Future<void> _loginWithGoogle() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      final result = await _authService.signInWithGoogle();
      
      if (result.isSuccess && mounted) {
        // Let MainWrapper handle routing based on user role
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      } else if (result.isCancelled && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng nhập Google bị hủy')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error ?? 'Đăng nhập Google thất bại')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi đăng nhập Google: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Xử lý đăng nhập bằng Facebook
  /// 
  /// Quy trình:
  /// 1. Gọi Facebook Login API
  /// 2. Đồng bộ với backend Firebase  
  /// 3. Navigate về MainWrapper nếu thành công
  Future<void> _loginWithFacebook() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      final result = await _authService.signInWithFacebook();
      
      if (result.isSuccess && mounted) {
        // Let MainWrapper handle routing based on user role
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      } else if (result.isCancelled && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng nhập Facebook bị hủy')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error ?? 'Đăng nhập Facebook thất bại')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi đăng nhập Facebook: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Khi nhấn back, quay về MainWrapper thay vì pop ra màn hình đen
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              IconButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false),
                icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
              ),
              
              const SizedBox(height: 40),
              
              // Title
              const Text(
                'Đăng nhập hoặc tạo tài khoản',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Subtitle
              const Text(
                'Đăng ký miễn phí hoặc đăng nhập để nhận được các ưu đãi và quyền lợi hấp dẫn!',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 40),
              
              // Google Login Button
              _buildSocialLoginButton(
                onPressed: _isLoading ? null : () => _loginWithGoogle(),
                backgroundColor: const Color(0xFF4285F4),
                textColor: Colors.white,
                icon: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Center(
                    child: Text(
                      'G',
                      style: TextStyle(
                        color: Color(0xFF4285F4),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                text: 'Đăng nhập bằng Google',
              ),
              
              const SizedBox(height: 16),
              
              // Facebook Login Button
              _buildSocialLoginButton(
                onPressed: _isLoading ? null : () => _loginWithFacebook(),
                backgroundColor: Colors.white,
                textColor: const Color(0xFF1877F2),
                borderColor: Colors.grey.shade300,
                icon: const Text(
                  'f',
                  style: TextStyle(
                    color: Color(0xFF1877F2),
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                text: 'Đăng nhập với Facebook',
              ),
              
              
              const SizedBox(height: 32),
              
              // Separator
              const Center(
                child: Text(
                  'hoặc',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Email Section
              const Text(
                'Email',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Email Input Field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'id@email.com',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF4285F4), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Continue Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isEmailValid && !_isLoading) ? _continueWithEmail : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isEmailValid ? const Color(0xFF4285F4) : Colors.grey.shade300,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Tiếp tục',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Alternative login link
              Center(
                child: TextButton(
                  onPressed: () {
                    // TODO: Navigate to other login methods
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tính năng đang phát triển')),
                    );
                  },
                  child: const Text(
                    'Đăng nhập bằng cách khác',
                    style: TextStyle(
                      color: Color(0xFF4285F4),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Legal text
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      height: 1.4,
                    ),
                    children: [
                      TextSpan(text: 'Khi đăng nhập, tôi đồng ý với các '),
                      TextSpan(
                        text: 'Điều khoản sử dụng',
                        style: TextStyle(
                          color: Color(0xFF4285F4),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      TextSpan(text: ' và '),
                      TextSpan(
                        text: 'Chính sách bảo mật',
                        style: TextStyle(
                          color: Color(0xFF4285F4),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      TextSpan(text: ' của Hotel Booking.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildSocialLoginButton({
    required VoidCallback? onPressed,
    required Color backgroundColor,
    required Color textColor,
    required Widget icon,
    required String text,
    Color? borderColor,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: borderColor != null ? BorderSide(color: borderColor) : BorderSide.none,
          ),
          elevation: 0,
        ),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
                textAlign: TextAlign.left,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
