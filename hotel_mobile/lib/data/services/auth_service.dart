import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/user.dart';
import '../models/user_role_model.dart';
import 'user_role_service.dart';

/// Service quản lý xác thực Firebase (Google, Facebook)
/// 
/// Chức năng:
/// - Đăng nhập/Đăng ký qua Google/Facebook
/// - Quản lý session (5 ngày tự động hết hạn)
/// - Lưu user data vào SharedPreferences + FlutterSecureStorage
/// - Tự động kiểm tra và xử lý session hết hạn
/// 
/// Lưu ý: Service này làm việc với Firebase Auth
/// - Khác với BackendAuthService (làm việc với Backend API)
/// - Dùng cho Social Login (Google, Facebook)
class AuthService {
  // Singleton pattern - Chỉ có 1 instance duy nhất
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final UserRoleService _userRoleService = UserRoleService();
  User? _currentUser;
  UserRoleModel? _currentUserRole;

  // Constants for session management
  static const int _sessionDurationDays = 5; // Session hết hạn sau 5 ngày
  static const String _userDataKey = 'user_data';
  static const String _loginTimeKey = 'login_time';
  static const String _sessionTokenKey = 'session_token';

  /// Getter lấy thông tin user hiện tại
  User? get currentUser => _currentUser;
  
  /// Getter lấy role của user hiện tại (Admin/Manager/User)
  UserRoleModel? get currentUserRole => _currentUserRole;

  /// Kiểm tra session còn hợp lệ không
  /// 
  /// Session hết hạn sau 5 ngày kể từ lần đăng nhập gần nhất
  /// 
  /// Returns: true nếu session còn hợp lệ, false nếu hết hạn hoặc chưa đăng nhập
  Future<bool> get isSessionValid async {
    final loginTime = await _getLoginTime();
    if (loginTime == null) return false;

    final currentTime = DateTime.now();
    final sessionDuration = currentTime.difference(loginTime);

    return sessionDuration.inDays < _sessionDurationDays;
  }

  /// Kiểm tra user đã đăng nhập và session còn hợp lệ
  /// 
  /// Tự động load user từ storage nếu chưa load
  /// 
  /// Returns: true nếu user đã đăng nhập VÀ session còn hợp lệ
  Future<bool> get isAuthenticated async {
    if (_currentUser == null) {
      await _loadUserFromStorage();
    }

    return _currentUser != null && await isSessionValid;
  }

  /// Đăng nhập bằng Google (Firebase Auth)
  /// 
  /// Flow:
  /// 1. Sign out Google cũ để hiện account picker
  /// 2. User chọn tài khoản Google
  /// 3. Lấy Google auth tokens (accessToken, idToken)
  /// 4. Tạo Firebase credential và đăng nhập Firebase
  /// 5. Check/Tạo UserRole trong Firestore (Admin/Manager/User)
  /// 6. Lưu user data + session vào local storage
  /// 
  /// Returns: User object nếu thành công, throw Exception nếu thất bại
  Future<User?> signInWithGoogle() async {
    try {
      print('🚀 Bắt đầu đăng nhập Google với Firebase...');

      // Sign out để clear session (không disconnect để tránh lỗi)
      try {
        await _googleSignIn.signOut();
        print('✅ Signed out Google Sign-In');
      } catch (e) {
        print('⚠️ Sign out failed: $e');
      }

      print('🔄 Đã clear Google Sign-In session - sẽ hiển thị account picker');

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

  /// Đăng nhập bằng Facebook
  /// 
  /// Flow:
  /// 1. Trigger Facebook login flow
  /// 2. Lấy user data từ Facebook (name, email, picture)
  /// 3. Tạo User object và lưu vào local storage
  /// 
  /// Lưu ý: Chưa tích hợp Firebase Auth cho Facebook
  /// 
  /// Returns: User object nếu thành công, throw Exception nếu thất bại
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

  /// Đăng nhập bằng email/password (DEMO MODE - không validate với server)
  /// 
  /// Validation đơn giản:
  /// - Email có chứa @
  /// - Password không rỗng
  /// 
  /// Lưu ý: Đây là chế độ DEMO, không kết nối backend thật
  /// 
  /// Returns: User object nếu validation pass, null nếu fail
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

  /// Đăng ký tài khoản mới bằng email/password (DEMO MODE)
  /// 
  /// Validation đơn giản:
  /// - Email có chứa @
  /// - Password ≥ 6 ký tự
  /// - Name không rỗng
  /// 
  /// Lưu ý: Đây là chế độ DEMO, không kết nối backend thật
  /// 
  /// Returns: User object nếu validation pass, null nếu fail
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

  /// Đăng xuất toàn bộ (Google + Facebook + Local data)
  /// 
  /// Chạy song song với timeout 3 giây để tránh bị treo:
  /// - Đăng xuất Google (timeout 3s)
  /// - Đăng xuất Facebook (timeout 3s)
  /// - Xóa toàn bộ user data trong local storage
  /// 
  /// Dù có lỗi vẫn tiếp tục để đảm bảo user được logout
  Future<void> signOut() async {
    try {
      // Đăng xuất các provider song song với timeout
      final List<Future<void>> logoutTasks = [];

      // Google logout với timeout
      logoutTasks.add(
        _googleSignIn.signOut().timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            print('⚠️ Google logout timeout, continuing...');
          },
        ).catchError((_) {}),
      );

      // Facebook logout với timeout
      logoutTasks.add(
        FacebookAuth.instance.logOut().timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            print('⚠️ Facebook logout timeout, continuing...');
          },
        ).catchError((fbError) {
          print('⚠️ Facebook logout error: $fbError');
        }),
      );

      // Clear user data
      logoutTasks.add(_clearAllUserData());

      // Chờ tất cả các task hoàn thành (hoặc timeout)
      await Future.wait(logoutTasks);
      print('✅ User signed out successfully');
    } catch (e) {
      print('❌ Error signing out: $e');
      // Vẫn tiếp tục ngay cả khi có lỗi
    }
  }

  /// Kiểm tra trạng thái đăng nhập
  /// 
  /// Wrapper cho isAuthenticated getter
  /// 
  /// Returns: true nếu user đã đăng nhập và session còn hợp lệ
  Future<bool> isSignedIn() async {
    return await isAuthenticated;
  }

  /// Lấy danh sách authentication provider đang dùng
  /// 
  /// Dựa vào email để detect provider:
  /// - @gmail.com → Google
  /// - Còn lại → Email/Password
  /// 
  /// Returns: List các provider name
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

  /// Lấy tên provider chính (provider đầu tiên trong list)
  /// 
  /// Returns: Provider name hoặc null nếu chưa đăng nhập
  String? getPrimaryProvider() {
    final providers = getCurrentProviders();
    return providers.isNotEmpty ? providers.first : null;
  }

  /// [PRIVATE] Lưu user data kèm theo login timestamp
  /// 
  /// Lưu 3 thông tin:
  /// 1. User data → SharedPreferences
  /// 2. Login timestamp → SharedPreferences (để check session validity)
  /// 3. Session token → FlutterSecureStorage (secure storage)
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

  /// [PRIVATE] Lấy thời điểm đăng nhập gần nhất từ SharedPreferences
  /// 
  /// Returns: DateTime object hoặc null nếu chưa có login time
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

  /// [PRIVATE] Load user data từ local storage
  /// 
  /// Flow:
  /// 1. Check session validity trước
  /// 2. Nếu session hết hạn → Clear toàn bộ data
  /// 3. Nếu session còn hợp lệ → Load user từ SharedPreferences
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

  /// [PRIVATE] Tạo session token duy nhất cho user
  /// 
  /// Format: base64(user_id + email + timestamp)
  /// 
  /// Returns: Session token string
  String _generateSessionToken(User user) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final data = '${user.id}_${user.email}_$timestamp';
    return base64Encode(utf8.encode(data));
  }

  /// [PRIVATE] Xóa toàn bộ user data trong local storage
  /// 
  /// Xóa:
  /// - User data trong SharedPreferences
  /// - Login timestamp trong SharedPreferences
  /// - Session token trong FlutterSecureStorage
  /// - Reset _currentUser về null
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

  /// Tự động đăng xuất nếu session đã hết hạn
  /// 
  /// Được gọi tự động khi app resume hoặc trong initialize()
  /// 
  /// Flow: Nếu user != null VÀ session hết hạn → signOut()
  Future<void> checkAndHandleExpiredSession() async {
    if (_currentUser != null && !await isSessionValid) {
      print('Session expired, logging out user');
      await signOut();
    }
  }

  /// [PRIVATE] Lưu user data đơn giản (không có timestamp)
  /// 
  /// Chỉ dùng cho Facebook login (chưa implement đầy đủ session management)
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

  /// Khởi tạo AuthService khi app start
  /// 
  /// Flow:
  /// 1. Load user từ storage (nếu có session cũ)
  /// 2. Check và xử lý session hết hạn
  /// 3. Print log về user session
  /// 
  /// Được gọi trong main() trước khi runApp()
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
