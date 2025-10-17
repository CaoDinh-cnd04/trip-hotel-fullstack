import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/user.dart';
import '../models/user_role_model.dart';
import 'user_role_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final UserRoleService _userRoleService = UserRoleService();
  User? _currentUser;
  UserRoleModel? _currentUserRole;

  // Constants for session management
  static const int _sessionDurationDays = 5; // 5 days session
  static const String _userDataKey = 'user_data';
  static const String _loginTimeKey = 'login_time';
  static const String _sessionTokenKey = 'session_token';

  // Getter cho current user
  User? get currentUser => _currentUser;
  UserRoleModel? get currentUserRole => _currentUserRole;

  // Check if user session is still valid
  Future<bool> get isSessionValid async {
    final loginTime = await _getLoginTime();
    if (loginTime == null) return false;

    final currentTime = DateTime.now();
    final sessionDuration = currentTime.difference(loginTime);

    return sessionDuration.inDays < _sessionDurationDays;
  }

  // Check if user is authenticated and session is valid
  Future<bool> get isAuthenticated async {
    if (_currentUser == null) {
      await _loadUserFromStorage();
    }

    return _currentUser != null && await isSessionValid;
  }

  // Đăng nhập bằng Google với error handling tốt hơn và role management
  Future<User?> signInWithGoogle() async {
    try {
      print('🚀 Bắt đầu đăng nhập Google với Firebase...');

      // Sign out trước để force chọn account
      await _googleSignIn.signOut();

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('❌ User đã hủy đăng nhập Google');
        throw Exception('Đăng nhập Google bị hủy bởi người dùng');
      }

      print('✅ Google Sign-In thành công: ${googleUser.email}');

      // Get auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      print('🔑 Đã lấy được Google auth tokens');

      // Create a new credential
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      print('🔐 Đã tạo Firebase credential');

      // Sign in to Firebase with the Google credential
      final firebase_auth.UserCredential userCredential = 
          await firebase_auth.FirebaseAuth.instance.signInWithCredential(credential);
      
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Firebase authentication failed');
      }

      print('👤 User: ${firebaseUser.displayName}');
      print('📧 Email: ${firebaseUser.email}');
      print('🆔 UID: ${firebaseUser.uid}');

      // Check if user role exists in Firestore
      UserRoleModel? userRole = await _userRoleService.getCurrentUserRole();
      
      if (userRole == null) {
        // First time login - create user role
        print('🆕 Tạo user role mới cho lần đầu đăng nhập');
        userRole = await _userRoleService.createUserRole(
          uid: firebaseUser.uid,
          email: firebaseUser.email!,
          displayName: firebaseUser.displayName ?? 'Google User',
          photoURL: firebaseUser.photoURL,
          role: UserRole.user, // Default role
        );
      } else {
        print('✅ User role đã tồn tại: ${userRole.role.displayName}');
      }

      _currentUserRole = userRole;

      // Tạo user với field names đúng theo model
      final user = User(
        id: firebaseUser.uid.hashCode, // Use Firebase UID hash
        hoTen: firebaseUser.displayName ?? 'Google User',
        email: firebaseUser.email!,
        anhDaiDien: firebaseUser.photoURL,
        trangThai: 1,
        createdAt: DateTime.now(),
      );

      _currentUser = user;
      await _saveUserDataWithTimestamp(user);
      print('✅ Google Sign In hoàn tất với role: ${userRole?.role.displayName ?? 'Unknown'}');
      return user;
    } catch (e) {
      print('❌ Error signing in with Google: $e');
      throw Exception('Đăng nhập Google thất bại: $e');
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
          id:
              (userData['id'] ??
                      DateTime.now().millisecondsSinceEpoch.toString())
                  .hashCode,
          hoTen: userData['name'] ?? 'Facebook User',
          email: userData['email'] ?? 'facebook@example.com',
          anhDaiDien: userData['picture']?['data']?['url'],
          trangThai: 1,
          createdAt: DateTime.now(),
        );

        _currentUser = user;
        await _saveUserData(user);
        print('Facebook Sign In successful for: ${user.email}');
        return user;
      } else {
        print('Facebook login failed: ${loginResult.message}');
        throw Exception('Đăng nhập Facebook thất bại: ${loginResult.message}');
      }
    } catch (e) {
      print('Error signing in with Facebook: $e');
      throw Exception('Đăng nhập Facebook thất bại: $e');
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
        await _saveUserDataWithTimestamp(user);
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
        await _saveUserDataWithTimestamp(user);
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
      await _clearAllUserData();
      print('User signed out');
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  // Kiểm tra trạng thái đăng nhập
  Future<bool> isSignedIn() async {
    return await isAuthenticated;
  }

  // Lấy thông tin provider hiện tại của user
  List<String> getCurrentProviders() {
    if (_currentUser == null) return [];

    // Dựa vào thông tin user để xác định provider
    // Nếu có Google ID hoặc email từ Google
    if (_currentUser!.email.contains('@gmail.com')) {
      return ['Google'];
    }

    // Có thể thêm logic khác để detect Facebook
    // Hiện tại chỉ return generic provider
    return ['Email/Password'];
  }

  // Lấy tên provider chính (provider đầu tiên)
  String? getPrimaryProvider() {
    final providers = getCurrentProviders();
    return providers.isNotEmpty ? providers.first : null;
  }

  // Session management methods
  Future<void> _saveUserDataWithTimestamp(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = json.encode(user.toJson());
      final currentTime = DateTime.now().toIso8601String();

      // Save user data
      await prefs.setString(_userDataKey, userJson);

      // Save login timestamp
      await prefs.setString(_loginTimeKey, currentTime);

      // Generate and save session token
      final sessionToken = _generateSessionToken(user);
      await _secureStorage.write(key: _sessionTokenKey, value: sessionToken);

      print('User data and session saved successfully');
    } catch (e) {
      print('Error saving user data with timestamp: $e');
    }
  }

  Future<DateTime?> _getLoginTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final loginTimeStr = prefs.getString(_loginTimeKey);

      if (loginTimeStr != null) {
        return DateTime.parse(loginTimeStr);
      }

      return null;
    } catch (e) {
      print('Error getting login time: $e');
      return null;
    }
  }

  Future<void> _loadUserFromStorage() async {
    try {
      // Check if session is valid first
      if (!await isSessionValid) {
        print('Session expired, clearing user data');
        await _clearAllUserData();
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userDataKey);

      if (userJson != null) {
        final userMap = json.decode(userJson) as Map<String, dynamic>;
        _currentUser = User.fromJson(userMap);
        print('User loaded from storage: ${_currentUser?.email}');
      }
    } catch (e) {
      print('Error loading user from storage: $e');
      await _clearAllUserData();
    }
  }

  String _generateSessionToken(User user) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final data = '${user.id}_${user.email}_$timestamp';
    return base64Encode(utf8.encode(data));
  }

  Future<void> _clearAllUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userDataKey);
      await prefs.remove(_loginTimeKey);
      await _secureStorage.delete(key: _sessionTokenKey);

      _currentUser = null;
      print('All user data cleared');
    } catch (e) {
      print('Error clearing all user data: $e');
    }
  }

  // Auto logout when session expires
  Future<void> checkAndHandleExpiredSession() async {
    if (_currentUser != null && !await isSessionValid) {
      print('Session expired, logging out user');
      await signOut();
    }
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

  // Khởi tạo và kiểm tra user khi app start
  Future<void> initialize() async {
    try {
      await _loadUserFromStorage();
      await checkAndHandleExpiredSession();

      if (_currentUser != null) {
        print('User session restored: ${_currentUser!.email}');
      } else {
        print('No valid user session found');
      }
    } catch (e) {
      print('Error initializing AuthService: $e');
    }
  }
}
