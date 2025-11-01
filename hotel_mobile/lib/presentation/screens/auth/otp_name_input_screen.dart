import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../data/services/backend_auth_service.dart';
import '../../../data/models/user.dart';
import '../../../core/constants/app_constants.dart';

/// Màn hình nhập tên cho user mới đăng ký qua OTP
/// 
/// Flow:
/// 1. User verify OTP thành công
/// 2. Nếu ho_ten == null hoặc rỗng → Hiển thị màn hình này
/// 3. User nhập tên → Cập nhật tên vào backend
/// 4. Navigate to home
class OTPNameInputScreen extends StatefulWidget {
  final String email;
  final String userId;
  final String token;

  const OTPNameInputScreen({
    super.key,
    required this.email,
    required this.userId,
    required this.token,
  });

  @override
  State<OTPNameInputScreen> createState() => _OTPNameInputScreenState();
}

class _OTPNameInputScreenState extends State<OTPNameInputScreen> with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isLoading = false;
  final BackendAuthService _backendAuthService = BackendAuthService();
  final Dio _dio = Dio();

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _animationController.forward();
    
    // Pre-fill với tên từ email (phần trước @)
    final emailPrefix = widget.email.split('@').first;
    _nameController.text = emailPrefix;
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _updateName() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      print('🔄 Đang cập nhật tên cho user: ${widget.userId}');
      
      _dio.options.baseUrl = AppConstants.baseUrl;
      _dio.options.headers['Authorization'] = 'Bearer ${widget.token}';
      
      final response = await _dio.put(
        '/api/user/profile',
        data: {
          'ho_ten': _nameController.text.trim(),
        },
      );

      if (response.data['success'] == true) {
        print('✅ Cập nhật tên thành công');
        
        // Reload user data từ backend
        try {
          final userResponse = await _dio.get(
            '/api/user/profile',
            options: Options(
              headers: {'Authorization': 'Bearer ${widget.token}'},
            ),
          );
          
          if (userResponse.data['success'] == true) {
            final updatedUserData = userResponse.data['data'];
            final updatedUser = User.fromJson(updatedUserData);
            
            // Save updated user
            await _backendAuthService.saveUserData(
              updatedUser,
              widget.token,
              _backendAuthService.currentUserRole!,
            );
            
            print('✅ Đã reload user data với tên mới: ${updatedUser.hoTen}');
          }
        } catch (e) {
          print('⚠️ Warning: Không reload được user data, but continue anyway: $e');
        }
        
        // Navigate to home
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        }
      } else {
        throw Exception(response.data['message'] ?? 'Cập nhật tên thất bại');
      }
    } catch (e) {
      print('❌ Lỗi cập nhật tên: $e');
      
      String errorMsg = 'Không thể cập nhật tên';
      if (e is DioException) {
        if (e.response?.data?['message'] != null) {
          errorMsg = e.response!.data['message'];
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(errorMsg)),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Icon
                    Container(
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
                          Icons.person_add,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Title
                    const Text(
                      'Hoàn tất đăng ký',
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
                      'Chào mừng bạn đến với ứng dụng!\nVui lòng nhập tên của bạn để tiếp tục.',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Email display
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF2196F3).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.email,
                            color: Color(0xFF2196F3),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.email,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF2196F3),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Name input
                    TextFormField(
                      controller: _nameController,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Họ và tên *',
                        hintText: 'Nguyễn Văn A',
                        prefixIcon: const Icon(Icons.person, color: Color(0xFF2196F3)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF2196F3),
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.red),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập tên của bạn';
                        }
                        if (value.trim().length < 2) {
                          return 'Tên phải có ít nhất 2 ký tự';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Submit button
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateName,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2196F3),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          elevation: 3,
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
                                'Tiếp tục',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Privacy note
                    Text(
                      'Bằng việc tiếp tục, bạn đồng ý với\nĐiều khoản sử dụng và Chính sách bảo mật',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
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

