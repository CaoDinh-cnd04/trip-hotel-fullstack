import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/services/otp_auth_service.dart';
import 'otp_screen.dart';

/// Màn hình nhập thông tin để đăng ký bằng Email + OTP
/// 
/// Luồng sử dụng:
/// 1. User điền email, họ tên, số điện thoại (nếu chưa có)
/// 2. Click "Tiếp tục" để request OTP
/// 3. Hệ thống gửi OTP đến email
/// 4. Navigate đến OTPScreen để nhập mã OTP
/// 
/// Features:
/// - Auto-fill thông tin nếu được truyền vào từ màn hình trước
/// - Validation form (email, phone format)
/// - Fade-in animation
/// - Loading state khi gửi OTP
/// - Error handling và hiển thị lỗi
class EmailOTPScreen extends StatefulWidget {
  /// Email (có thể pre-fill)
  final String? email;
  
  /// Họ tên (có thể pre-fill)
  final String? hoTen;
  
  /// Số điện thoại (có thể pre-fill)
  final String? sdt;
  
  /// Mật khẩu (optional)
  final String? matKhau;
  
  /// Giới tính (optional)
  final String? gioiTinh;
  
  /// Ngày sinh (optional)
  final DateTime? ngaySinh;

  const EmailOTPScreen({
    super.key,
    this.email,
    this.hoTen,
    this.sdt,
    this.matKhau,
    this.gioiTinh,
    this.ngaySinh,
  });

  @override
  State<EmailOTPScreen> createState() => _EmailOTPScreenState();
}

class _EmailOTPScreenState extends State<EmailOTPScreen> with TickerProviderStateMixin {
  /// Controller cho trường email
  final _emailController = TextEditingController();
  
  /// Controller cho trường họ tên
  final _nameController = TextEditingController();
  
  /// Controller cho trường số điện thoại
  final _phoneController = TextEditingController();
  
  /// Key để validate form
  final _formKey = GlobalKey<FormState>();
  
  /// Trạng thái đang gửi OTP
  bool _isLoading = false;
  
  /// Thông báo lỗi (nếu có)
  String? _errorMessage;
  
  /// Controller cho fade-in animation
  late AnimationController _animationController;
  
  /// Animation cho hiệu ứng fade
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Pre-fill controllers with provided data
    if (widget.email != null) _emailController.text = widget.email!;
    if (widget.hoTen != null) _nameController.text = widget.hoTen!;
    if (widget.sdt != null) _phoneController.text = widget.sdt!;
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Giả sử có OTPAuthService instance
      // final otpService = OTPAuthService();
      // final result = await otpService.sendOTP(
      //   _emailController.text,
      //   userData: {
      //     'ho_ten': _nameController.text,
      //     'sdt': _phoneController.text,
      //   },
      // );
      
      // Tạm thời mock kết quả thành công
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        // Chuyển đến màn hình OTP
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OTPScreen(
              email: _emailController.text,
              userData: {
                'ho_ten': _nameController.text,
                'sdt': _phoneController.text,
              },
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Không thể gửi mã OTP. Vui lòng thử lại.';
        _isLoading = false;
      });
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Email không hợp lệ';
    }
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập họ tên';
    }
    if (value.length < 2) {
      return 'Họ tên phải có ít nhất 2 ký tự';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập số điện thoại';
    }
    if (!RegExp(r'^[0-9]{10,11}$').hasMatch(value.replaceAll(' ', ''))) {
      return 'Số điện thoại không hợp lệ';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Kiểm tra nếu có thể pop, nếu không thì về home
        if (Navigator.canPop(context)) {
          return true;
        } else {
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
          return false;
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              }
            },
          ),
        title: const Text(
          'Đăng ký bằng Email',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                const SizedBox(height: 20),
                
                // Icon và title
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.email_outlined,
                      size: 40,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                Center(
                  child: Column(
                    children: [
                      const Text(
                        'Đăng ký nhanh với Email',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Nhập email để nhận mã xác thực',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Error message
                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Email field
                TextFormField(
                  controller: _emailController,
                  enabled: !_isLoading,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email *',
                    hintText: 'Nhập email của bạn',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Theme.of(context).primaryColor),
                    ),
                  ),
                  validator: _validateEmail,
                ),
                
                const SizedBox(height: 16),
                
                // Name field
                TextFormField(
                  controller: _nameController,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: 'Họ và tên *',
                    hintText: 'Nhập họ tên của bạn',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Theme.of(context).primaryColor),
                    ),
                  ),
                  validator: _validateName,
                ),
                
                const SizedBox(height: 16),
                
                // Phone field
                TextFormField(
                  controller: _phoneController,
                  enabled: !_isLoading,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Số điện thoại',
                    hintText: 'Nhập số điện thoại (tùy chọn)',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Theme.of(context).primaryColor),
                    ),
                  ),
                  validator: _validatePhone,
                ),
                
                const SizedBox(height: 32),
                
                // Info box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Cách thức hoạt động:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Chúng tôi sẽ gửi mã xác thực 6 số đến email của bạn\n'
                        '• Mã OTP có hiệu lực trong 45 giây\n'
                        '• Sau khi xác thực, tài khoản sẽ được tạo tự động\n'
                        '• Bạn sẽ được đăng nhập ngay lập tức',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue.shade600,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Send OTP button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _sendOTP,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Gửi mã OTP',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Back to login
                Center(
                  child: TextButton(
                    onPressed: _isLoading ? null : () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                      }
                    },
                    child: Text(
                      'Quay lại đăng nhập',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
              ],
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }
}
