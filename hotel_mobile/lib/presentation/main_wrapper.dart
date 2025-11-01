import 'dart:async';
import 'package:flutter/material.dart';
import '../data/services/auth_service.dart';
import '../data/services/backend_auth_service.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/auth/agoda_style_login_screen.dart';
import 'screens/admin/admin_main_screen.dart';
import 'screens/hotel_manager/hotel_manager_main_screen.dart';
import '../../data/models/user_role_model.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({Key? key}) : super(key: key);

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  final AuthService _authService = AuthService();
  final BackendAuthService _backendAuthService = BackendAuthService();
  bool _isLoading = true;
  bool _isAuthenticated = false;
  bool _isAdmin = false;
  bool _isHotelManager = false;

  @override
  void initState() {
    super.initState();
    _initializeAuthState();
    
    // Listen for auth state changes - removed since AuthService doesn't have authStateChanges

    // Periodic check for auth state changes (fallback)
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

  Future<void> _initializeAuthState() async {
    // Force restore user data from storage first
    await _backendAuthService.restoreUserData();
    await _checkAuthState();
  }

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
