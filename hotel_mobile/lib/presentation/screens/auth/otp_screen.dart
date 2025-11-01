import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import '../../../data/services/otp_auth_service.dart';
import '../../../data/services/backend_auth_service.dart';
import '../../../data/models/user.dart';
import '../../../data/models/user_role_model.dart';
import '../../../core/constants/app_constants.dart';
import 'otp_name_input_screen.dart';
import 'dart:async';

class OTPScreen extends StatefulWidget {
  final String email;
  final Map<String, dynamic>? userData;

  const OTPScreen({
    super.key,
    required this.email,
    this.userData,
  });

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> with TickerProviderStateMixin {
  late final OTPAuthService _otpAuthService;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  bool _isLoading = false;
  String _otp = '';
  int _timeLeft = (AppConstants.otpExpiryMs ~/ 1000);
  bool _canResend = false;
  Timer? _timer;
  
  // Create 6 controllers for 6 OTP digits
  final List<TextEditingController> _controllers = List.generate(
    6, 
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );

  @override
  void initState() {
    super.initState();
    
    // Initialize OTPAuthService with required dependencies
    final dio = Dio();
    final backendAuthService = BackendAuthService();
    _otpAuthService = OTPAuthService(dio, backendAuthService);
    
    // Initialize animations
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    
    _fadeController.forward();
    _scaleController.forward();
    
    _startCountdown();
    
    // Auto-focus first field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fadeController.dispose();
    _scaleController.dispose();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_timeLeft > 0) {
          _timeLeft--;
          } else {
            _canResend = true;
            timer.cancel();
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _verifyOTP() async {
    if (_otp.length != 6) {
      _showSnackBar('Vui lòng nhập đầy đủ 6 số', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _otpAuthService.verifyOTP(widget.email, _otp);
      
      if (result.isSuccess) {
        // Hiển thị thông báo thành công
        _showSnackBar('🎉 Xác thực thành công!', isError: false);
        
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (mounted) {
          // Check nếu user chưa có tên → Yêu cầu nhập tên
          final user = result.user;
          if (user != null && (user.hoTen == null || user.hoTen!.isEmpty || user.hoTen == widget.email.split('@').first)) {
            // User mới hoặc chưa có tên → Navigate to name input
            print('⚠️ User chưa có tên, yêu cầu nhập tên');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => OTPNameInputScreen(
                  email: widget.email,
                  userId: user.id.toString(),
                  token: result.token ?? '',
                ),
              ),
            );
          } else {
            // User đã có tên → Navigate to home
            print('✅ User đã có tên: ${user?.hoTen}');
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
          }
        }
      } else {
        _showSnackBar(result.error ?? 'Xác thực OTP thất bại', isError: true);
        _clearOTP();
      }
    } catch (e) {
      print('❌ Verify OTP error: $e');
      String errorMsg = 'Lỗi xác thực OTP';
      
      if (e is DioException) {
        if (e.response?.statusCode == 500) {
          errorMsg = 'Lỗi máy chủ. Vui lòng thử lại sau.';
        } else if (e.response?.data?['message'] != null) {
          errorMsg = e.response!.data['message'];
        }
      }
      
      _showSnackBar(errorMsg, isError: true);
      _clearOTP();
    } finally {
      if (mounted) {
      setState(() => _isLoading = false);
      }
    }
  }

  void _resendOTP() async {
    setState(() => _isLoading = true);

    try {
      final result = await _otpAuthService.resendOTP(widget.email);
      
      if (result.isSuccess) {
        _showSnackBar('Mã OTP mới đã được gửi!', isError: false);
        
        setState(() {
          _timeLeft = result.expiresIn ?? 300;
          _canResend = false;
        });
        _startCountdown();
        _clearOTP();
      } else {
        _showSnackBar(result.error ?? 'Không thể gửi lại OTP', isError: true);
      }
    } catch (e) {
      _showSnackBar('Lỗi: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearOTP() {
    for (var controller in _controllers) {
      controller.clear();
    }
    setState(() {
      _otp = '';
    });
    _focusNodes[0].requestFocus();
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 15),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
        child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
          children: [
                // Top Icon with Animation
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF2196F3).withOpacity(0.1),
                          const Color(0xFF1976D2).withOpacity(0.1),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.email_outlined,
                        size: 64,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
            
            // Title
            const Text(
                  'Xác thực OTP',
              style: TextStyle(
                    fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
                    letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            
                const SizedBox(height: 12),
            
            // Subtitle
            Text(
                  'Nhập mã OTP đã được gửi đến',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.email,
              style: const TextStyle(
                fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2196F3),
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 40),
            
                // OTP Input Fields
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                    return _buildOTPField(index);
                  }),
                ),
                
                const SizedBox(height: 32),
                
                // Timer Display
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: _timeLeft > 0 
                        ? const Color(0xFF2196F3).withOpacity(0.1)
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _timeLeft > 0 
                          ? const Color(0xFF2196F3).withOpacity(0.3)
                          : Colors.red.shade200,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _timeLeft > 0 ? Icons.timer_outlined : Icons.timer_off_outlined,
                        size: 20,
                        color: _timeLeft > 0 ? const Color(0xFF2196F3) : Colors.red.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _timeLeft > 0 
                            ? 'Mã có hiệu lực: ${_formatTime(_timeLeft)}'
                            : 'Mã OTP đã hết hạn',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _timeLeft > 0 ? const Color(0xFF2196F3) : Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
            ),
            
            const SizedBox(height: 32),
            
            // Verify Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: (_isLoading || _otp.length != 6) ? null : _verifyOTP,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      elevation: _otp.length == 6 ? 3 : 0,
                      shadowColor: const Color(0xFF2196F3).withOpacity(0.4),
                shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                            height: 24,
                            width: 24,
                      child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                            'Xác thực',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                    ),
            ),
            
            const SizedBox(height: 24),
            
                // Resend Button
                TextButton(
                  onPressed: _canResend && !_isLoading ? _resendOTP : null,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.refresh,
                        size: 20,
                        color: _canResend ? const Color(0xFF2196F3) : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Gửi lại mã OTP',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _canResend ? const Color(0xFF2196F3) : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Help Text
                Text(
                  'Không nhận được mã? Kiểm tra hộp thư spam',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOTPField(int index) {
    return Container(
      width: 48,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _controllers[index].text.isNotEmpty
              ? const Color(0xFF2196F3)
              : Colors.grey.shade300,
          width: 2,
        ),
        boxShadow: _controllers[index].text.isNotEmpty
            ? [
                BoxShadow(
                  color: const Color(0xFF2196F3).withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A1A1A),
        ),
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        onChanged: (value) {
          if (value.isNotEmpty) {
            // Auto-focus next field
            if (index < 5) {
              _focusNodes[index + 1].requestFocus();
            } else {
              _focusNodes[index].unfocus();
            }
          } else {
            // Auto-focus previous field on delete
            if (index > 0) {
              _focusNodes[index - 1].requestFocus();
            }
          }
          
          // Update OTP string
          setState(() {
            _otp = _controllers.map((c) => c.text).join();
          });
        },
        onSubmitted: (_) {
          if (_otp.length == 6) {
            _verifyOTP();
          }
        },
      ),
    );
  }
}
