import 'package:flutter/material.dart';
import '../data/services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

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
