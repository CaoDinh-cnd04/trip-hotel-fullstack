import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../data/services/backend_auth_service.dart';
import '../../data/models/user_role_model.dart';
import '../widgets/language_switcher.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final BackendAuthService _backendAuthService = BackendAuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _backendAuthService.signInWithEmailPassword(
        _emailController.text,
        _passwordController.text,
      );

      if (result.isSuccess && mounted) {
        // Get role information
        String roleMessage = '';
        if (result.userRole != null) {
          switch (result.userRole!.role) {
            case UserRole.admin:
              roleMessage = ' (Quản trị viên)';
              break;
            case UserRole.hotelManager:
              roleMessage = ' (Quản lý khách sạn)';
              break;
            case UserRole.user:
              roleMessage = ' (Người dùng)';
              break;
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chào mừng ${result.user?.hoTen}$roleMessage!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate based on role
        if (result.userRole?.role == UserRole.admin) {
          Navigator.pushReplacementNamed(context, '/admin/dashboard');
        } else if (result.userRole?.role == UserRole.hotelManager) {
          Navigator.pushReplacementNamed(context, '/hotel-manager/dashboard');
        } else {
          Navigator.pushReplacementNamed(context, '/main');
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Đăng nhập thất bại'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi kết nối: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);

    try {
      // Sử dụng Backend Auth Service cho Google
      final result = await _backendAuthService.signInWithGoogle();

      if (result.isSuccess && mounted) {
        // Get role information
        String roleMessage = '';
        if (result.userRole != null) {
          switch (result.userRole!.role) {
            case UserRole.admin:
              roleMessage = ' (Quản trị viên)';
              break;
            case UserRole.hotelManager:
              roleMessage = ' (Quản lý khách sạn)';
              break;
            case UserRole.user:
              roleMessage = ' (Người dùng)';
              break;
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chào mừng ${result.user?.hoTen}$roleMessage!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate based on role
        if (result.userRole?.role == UserRole.admin) {
          Navigator.pushReplacementNamed(context, '/admin/dashboard');
        } else if (result.userRole?.role == UserRole.hotelManager) {
          Navigator.pushReplacementNamed(context, '/hotel-manager/dashboard');
        } else {
          Navigator.pushReplacementNamed(context, '/main');
        }
      } else if (result.isCancelled && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng nhập bị hủy bỏ'),
            backgroundColor: Colors.orange,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Đăng nhập Google thất bại'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi đăng nhập Google: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleFacebookLogin() async {
    setState(() => _isLoading = true);

    try {
      // Sử dụng Backend Auth Service cho Facebook
      final result = await _backendAuthService.signInWithFacebook();

      if (result.isSuccess && mounted) {
        // Get role information
        String roleMessage = '';
        if (result.userRole != null) {
          switch (result.userRole!.role) {
            case UserRole.admin:
              roleMessage = ' (Quản trị viên)';
              break;
            case UserRole.hotelManager:
              roleMessage = ' (Quản lý khách sạn)';
              break;
            case UserRole.user:
              roleMessage = ' (Người dùng)';
              break;
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chào mừng ${result.user?.hoTen}$roleMessage!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate based on role
        if (result.userRole?.role == UserRole.admin) {
          Navigator.pushReplacementNamed(context, '/admin/dashboard');
        } else if (result.userRole?.role == UserRole.hotelManager) {
          Navigator.pushReplacementNamed(context, '/hotel-manager/dashboard');
        } else {
          Navigator.pushReplacementNamed(context, '/main');
        }
      } else if (result.isCancelled && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng nhập bị hủy bỏ'),
            backgroundColor: Colors.orange,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Đăng nhập Facebook thất bại'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi đăng nhập Facebook: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2196F3), Color(0xFF21CBF3), Color(0xFF42A5F5)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Language Switcher
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [LanguageSwitcher()],
                ),
                const SizedBox(height: 20),

                // Logo and Title
                _buildHeader(l10n),

                const SizedBox(height: 60),

                // Login Form
                _buildLoginForm(l10n),

                const SizedBox(height: 32),

                // Social Login Buttons
                _buildSocialLoginButtons(),

                const SizedBox(height: 24),

                // Register Link
                _buildRegisterLink(),

                const SizedBox(height: 20),

                // Guest Mode
                _buildGuestModeButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.hotel, size: 60, color: Colors.white),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.appTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.appTitle, // You can add a subtitle key to the ARB files
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 16,
            fontWeight: FontWeight.w300,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginForm(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.login,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Email Field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: l10n.email,
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: const Color(0xFFF8F9FA),
            ),
          ),
          const SizedBox(height: 16),

          // Password Field
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: l10n.password,
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: const Color(0xFFF8F9FA),
            ),
          ),
          const SizedBox(height: 8),

          // Forgot Password
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                // TODO: Implement forgot password
              },
              child: const Text('Quên mật khẩu?'),
            ),
          ),
          const SizedBox(height: 16),

          // Login Button
          ElevatedButton(
            onPressed: _isLoading ? null : _handleEmailLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
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
                    'Đăng nhập',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSocialLoginButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Divider(color: Colors.white.withValues(alpha: 0.5)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Hoặc đăng nhập với',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Divider(color: Colors.white.withValues(alpha: 0.5)),
            ),
          ],
        ),
        const SizedBox(height: 24),

        Row(
          children: [
            // Google Login
            Expanded(
              child: _buildSocialButton(
                onPressed: _isLoading ? null : _handleGoogleLogin,
                icon: Icons.g_mobiledata,
                label: 'Google',
                backgroundColor: Colors.white,
                textColor: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(width: 16),

            // Facebook Login
            Expanded(
              child: _buildSocialButton(
                onPressed: _isLoading ? null : _handleFacebookLogin,
                icon: Icons.facebook,
                label: 'Facebook',
                backgroundColor: const Color(0xFF1877F2),
                textColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Chưa có tài khoản? ',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 16,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.pushNamed(context, '/register');
          },
          child: const Text(
            'Đăng ký ngay',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuestModeButton() {
    return TextButton(
      onPressed: () {
        Navigator.pushReplacementNamed(context, '/main');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_outline,
              color: Colors.white.withValues(alpha: 0.9),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Tiếp tục với tư cách khách',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
