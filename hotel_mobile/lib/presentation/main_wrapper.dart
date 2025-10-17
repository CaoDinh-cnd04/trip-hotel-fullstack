import 'package:flutter/material.dart';
import '../data/services/auth_service.dart';
import 'screens/main_navigation_screen.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({Key? key}) : super(key: key);

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
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
        print('ℹ️ User not authenticated - showing main interface');
      }
    } catch (e) {
      print('Error checking auth state: $e');
      setState(() {
        _isAuthenticated = false;
        _isLoading = false;
      });
    }
  }

  // Method to refresh auth state when user logs in/out
  Future<void> refreshAuthState() async {
    await _checkAuthState();
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
                'Đang khởi tạo ứng dụng...',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // Always show MainNavigationScreen, but pass auth state
    return MainNavigationScreen(
      isAuthenticated: _isAuthenticated,
      onAuthStateChanged: refreshAuthState,
    );
  }
}
