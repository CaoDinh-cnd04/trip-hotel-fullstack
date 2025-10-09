import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn();
  User? _currentUser;

  // Getter cho current user
  User? get currentUser => _currentUser;

  // Đăng nhập bằng Google với error handling tốt hơn
  Future<User?> signInWithGoogle() async {
    try {
      print('Starting Google Sign In...');

      // Sign out trước để force chọn account
      await _googleSignIn.signOut();

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('Google Sign In cancelled by user');
        return null;
      }

      print('Google user: ${googleUser.email}');

      // Tạo user với field names đúng theo model
      final user = User(
        id: googleUser.id.hashCode, // Convert string to int
        hoTen: googleUser.displayName ?? 'Google User',
        email: googleUser.email,
        anhDaiDien: googleUser.photoUrl,
        trangThai: 1,
        createdAt: DateTime.now(),
      );

      _currentUser = user;
      await _saveUserData(user);
      return user;
    } catch (e) {
      print('Error signing in with Google: $e');
      return null;
    }
  }

  // Đăng nhập bằng Facebook với error handling tốt hơn
  Future<User?> signInWithFacebook() async {
    try {
      print('Starting Facebook Login...');

      // Trigger the sign-in flow
      final LoginResult loginResult = await FacebookAuth.instance.login();
      print('Facebook login status: ${loginResult.status}');

      if (loginResult.status == LoginStatus.success) {
        // Get user data from Facebook
        final userData = await FacebookAuth.instance.getUserData();
        print('Facebook user data: $userData');

        // Tạo user với field names đúng theo model
        final user = User(
          id: userData['id'].hashCode, // Convert string to int
          hoTen: userData['name'] ?? 'Facebook User',
          email: userData['email'] ?? 'facebook@example.com',
          anhDaiDien: userData['picture']?['data']?['url'],
          trangThai: 1,
          createdAt: DateTime.now(),
        );

        _currentUser = user;
        await _saveUserData(user);
        return user;
      } else {
        print('Facebook login failed: ${loginResult.message}');
        return null;
      }
    } catch (e) {
      print('Error signing in with Facebook: $e');
      return null;
    }
  }

  // Đăng nhập bằng email/password (demo mode)
  Future<User?> signInWithEmailPassword(String email, String password) async {
    try {
      print('Email login attempt: $email');

      // Demo: chỉ cần email có @ và password không rỗng
      if (email.contains('@') && password.isNotEmpty) {
        final user = User(
          id: email.hashCode, // Use email hash as ID
          hoTen: email.split('@')[0], // Use email prefix as name
          email: email,
          trangThai: 1,
          createdAt: DateTime.now(),
        );

        _currentUser = user;
        await _saveUserData(user);
        return user;
      }

      return null;
    } catch (e) {
      print('Error signing in with email: $e');
      return null;
    }
  }

  // Đăng ký bằng email/password (demo mode)
  Future<User?> registerWithEmailPassword(
    String email,
    String password,
    String name,
  ) async {
    try {
      print('Register attempt: $email');

      // Demo: validation cơ bản
      if (email.contains('@') && password.length >= 6 && name.isNotEmpty) {
        final user = User(
          id: email.hashCode,
          hoTen: name,
          email: email,
          trangThai: 1,
          createdAt: DateTime.now(),
        );

        _currentUser = user;
        await _saveUserData(user);
        return user;
      }

      return null;
    } catch (e) {
      print('Error registering: $e');
      return null;
    }
  }

  // Đăng xuất
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await FacebookAuth.instance.logOut();
      await _clearUserData();
      _currentUser = null;
      print('User signed out');
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  // Kiểm tra trạng thái đăng nhập
  Future<bool> isSignedIn() async {
    if (_currentUser != null) return true;

    // Kiểm tra shared preferences
    final userData = await _getUserData();
    if (userData != null) {
      _currentUser = userData;
      return true;
    }

    return false;
  }

  // Lưu thông tin user vào SharedPreferences
  Future<void> _saveUserData(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = json.encode(user.toJson());
      await prefs.setString('user_data', userJson);
      print('User data saved to SharedPreferences');
    } catch (e) {
      print('Error saving user data: $e');
    }
  }

  // Lấy thông tin user từ SharedPreferences
  Future<User?> _getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user_data');

      if (userJson != null) {
        final userMap = json.decode(userJson) as Map<String, dynamic>;
        return User.fromJson(userMap);
      }

      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Xóa thông tin user khỏi SharedPreferences
  Future<void> _clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
      print('User data cleared from SharedPreferences');
    } catch (e) {
      print('Error clearing user data: $e');
    }
  }

  // Khởi tạo và kiểm tra user khi app start
  Future<void> initialize() async {
    try {
      final userData = await _getUserData();
      if (userData != null) {
        _currentUser = userData;
        print('User restored from SharedPreferences: ${userData.email}');
      }
    } catch (e) {
      print('Error initializing AuthService: $e');
    }
  }
}
