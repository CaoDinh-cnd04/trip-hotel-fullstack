import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import '../../core/constants/app_constants.dart';
import '../../core/services/facebook_auth_service.dart';
import '../../core/services/firebase_auth_service.dart';
import '../models/user.dart';
import '../models/user_role_model.dart';

/// Mock Firebase User class cho Facebook login
/// 
/// Vì Facebook login không dùng Firebase Auth,
/// nên tạo class giả để đồng bộ với backend dễ hơn
class MockFirebaseUser {
  final String uid;
  final String? displayName;
  final String? email;
  final String? photoURL;

  MockFirebaseUser({
    required this.uid,
    this.displayName,
    this.email,
    this.photoURL,
  });

  /// Tạo mock ID token cho Firebase (không phải token thật)
  Future<String> getIdToken() async {
    return 'mock_token_$uid';
  }
}

/// Service xác thực với Backend API (Node.js + SQL Server)
/// 
/// Chức năng chính:
/// - Đăng nhập/Đăng ký trực tiếp với Backend API
/// - Đăng nhập Social (Google/Facebook) → Đồng bộ với Backend
/// - Quản lý session (token JWT, user data trong SharedPreferences)
/// - Fallback: Tạo user local khi backend offline
/// 
/// Khác với AuthService (Firebase Auth), service này:
/// - Làm việc TRỰC TIẾP với Backend API
/// - Dùng cho OTP Login, Email/Password Login
/// - Đồng bộ Social Login từ Firebase sang Backend
/// - Lưu JWT token từ Backend (không phải Firebase token)
class BackendAuthService {
  // Singleton pattern
  static final BackendAuthService _instance = BackendAuthService._internal();
  factory BackendAuthService() => _instance;
  BackendAuthService._internal();

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.baseUrl,
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
  final FacebookAuthService _facebookAuthService = FacebookAuthService();
  final FirebaseAuthService _firebaseAuthService = FirebaseAuthService();

  User? _currentUser;
  String? _authToken; // JWT token từ Backend
  UserRoleModel? _currentUserRole;

  /// Getter lấy user hiện tại
  User? get currentUser => _currentUser;
  
  /// Getter lấy auth token (JWT từ Backend)
  String? get authToken => _authToken;
  String? getToken() => _authToken;
  
  /// Getter lấy role của user (Admin/Manager/User)
  UserRoleModel? get currentUserRole => _currentUserRole;

  /// Đăng nhập bằng email và password với Backend API
  /// 
  /// Gọi API: POST /auth/login
  /// 
  /// Flow:
  /// 1. Gửi email + mật khẩu lên Backend
  /// 2. Backend validate và trả về user + JWT token + role
  /// 3. Lưu user data + token + role vào SharedPreferences
  /// 4. Lưu login_time để AuthService check session validity
  /// 
  /// Returns: AuthResult với user/role hoặc error message
  Future<AuthResult> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'mat_khau': password},
      );

      if (response.data['success']) {
        final userData = response.data['user'];
        final token = response.data['token'];
        final roleData = response.data['role'];

        print('🔍 ===== FLUTTER LOGIN DEBUG =====');
        print('📧 Email: $email');
        print('👤 User data: $userData');
        print('🎭 Role data: $roleData');
        if (roleData != null) {
          print('🎯 Role from backend: ${roleData['role']}');
          print('🔐 Permissions: ${roleData['permissions']}');
        } else {
          print('⚠️ WARNING: roleData is NULL!');
        }
        print('🔍 ================================');

        final user = User(
          id: userData['id'],
          hoTen: userData['ho_ten'] ?? '',
          email: userData['email'] ?? '',
          anhDaiDien: userData['anh_dai_dien'],
          trangThai: userData['trang_thai'] is bool 
              ? (userData['trang_thai'] ? 1 : 0)
              : (userData['trang_thai'] ?? 1),
          createdAt: DateTime.now(),
        );

        // Parse user role
        UserRoleModel? userRole;
        if (roleData != null) {
          final parsedRole = _parseUserRole(roleData['role'] ?? 'user');
          print('🎭 Parsed role ENUM: $parsedRole');
          print('🎭 Parsed role VALUE: ${parsedRole.value}');
          print('✅ Is Admin: ${parsedRole == UserRole.admin}');
          
          userRole = UserRoleModel(
            uid: userData['id'].toString(),
            email: userData['email'] ?? '',
            displayName: userData['ho_ten'] ?? '',
            photoURL: userData['anh_dai_dien'],
            role: parsedRole,
            isActive: roleData['is_active'] ?? true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            hotelId: roleData['hotel_id']?.toString(),
            permissions: List<String>.from(roleData['permissions'] ?? []),
          );
        } else {
          // Default role for users without role data
          userRole = UserRoleModel(
            uid: userData['id'].toString(),
            email: userData['email'] ?? '',
            displayName: userData['ho_ten'] ?? '',
            photoURL: userData['anh_dai_dien'],
            role: UserRole.user,
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            permissions: UserRole.user.defaultPermissions,
          );
        }

        _currentUser = user;
        _authToken = token;
        _currentUserRole = userRole;

        // Lưu thông tin người dùng và role
        await saveUserData(user, token, userRole);

        // 🔥 Sign in to Firebase for chat functionality
        await _syncToFirebase(email, password, user, userRole);

        return AuthResult.success(user, userRole);
      } else {
        return AuthResult.error(
          response.data['message'] ?? 'Đăng nhập thất bại',
        );
      }
    } catch (e) {
      print('❌ Login error: $e');
      if (e is DioException) {
        if (e.response?.statusCode == 401) {
          return AuthResult.error('Email hoặc mật khẩu không đúng.');
        } else if (e.response?.statusCode == 400) {
          return AuthResult.error('Dữ liệu không hợp lệ. Vui lòng kiểm tra lại thông tin.');
        } else if (e.response?.statusCode == 500) {
          return AuthResult.error('Lỗi máy chủ. Vui lòng thử lại sau.');
        }
      }
      return AuthResult.error('Lỗi kết nối: $e');
    }
  }

  /// Đăng nhập bằng Google (Firebase Auth → Đồng bộ Backend)
  /// 
  /// Flow:
  /// 1. Đăng nhập Google qua Firebase (FirebaseAuthService)
  /// 2. Lấy Firebase user info (uid, email, displayName, photoURL)
  /// 3. Gọi Backend API để đồng bộ user:
  ///    - Nếu email ĐÃ TỒN TẠI trong DB → Cập nhật google_id và login
  ///    - Nếu email CHƯA TỒN TẠI → Tạo user mới trong DB
  /// 4. Backend trả về user + JWT token + role
  /// 5. Lưu vào SharedPreferences
  /// 
  /// Fallback: Nếu backend offline → Tạo user local (không sync được)
  /// 
  /// Returns: AuthResult với user/role hoặc error
  Future<AuthResult> signInWithGoogle() async {
    try {
      // Đăng nhập với Google qua Firebase
      final googleResult = await _firebaseAuthService.signInWithGoogle();

      if (!googleResult.isSuccess) {
        if (googleResult.isCancelled) {
          return AuthResult.cancelled();
        }
        return AuthResult.error(
          googleResult.error ?? 'Đăng nhập Google thất bại',
        );
      }

      final firebaseUser = googleResult.user;
      if (firebaseUser == null) {
        return AuthResult.error('Không thể lấy thông tin user từ Google');
      }

      print('🔥 Firebase Google login thành công, đang đồng bộ với backend...');

      // Đồng bộ user với backend
      final syncResult = await _syncFirebaseUserToBackend(
        firebaseUser: firebaseUser,
        provider: 'google.com',
        googleId: firebaseUser.providerData
            .where((provider) => provider.providerId == 'google.com')
            .firstOrNull?.uid,
      );

      if (syncResult.isSuccess) {
        _currentUser = syncResult.user;
        _currentUserRole = syncResult.userRole;
        _authToken = syncResult.token;

        await saveUserData(syncResult.user!, syncResult.token!, syncResult.userRole);
        
        // ✅ Lưu vào Firestore để hotel manager có thể liên hệ
        await _saveUserToFirestore(
          firebaseUser: firebaseUser,
          backendUser: syncResult.user!,
          userRole: syncResult.userRole!,
        );
        
        return syncResult;
      } else {
        // Fallback: tạo user local nếu không đồng bộ được backend
        print('⚠️ Không thể đồng bộ với backend, tạo user local...');
        final user = User(
          id: firebaseUser.uid.hashCode,
          hoTen: firebaseUser.displayName ?? 'Google User',
          email: firebaseUser.email ?? '',
          anhDaiDien: firebaseUser.photoURL,
          trangThai: 1,
          createdAt: DateTime.now(),
        );

        final userRole = UserRoleModel(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName: firebaseUser.displayName ?? 'Google User',
          photoURL: firebaseUser.photoURL,
          role: UserRole.user,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          permissions: UserRole.user.defaultPermissions,
        );

        _currentUser = user;
        _currentUserRole = userRole;
        _authToken = 'firebase_${firebaseUser.uid}';

        await saveUserData(user, _authToken!, userRole);
        return AuthResult.success(user, userRole);
      }
    } catch (e) {
      return AuthResult.error('Lỗi đăng nhập Google: $e');
    }
  }

  /// Đăng nhập bằng Facebook (FacebookAuthService → Đồng bộ Backend)
  /// 
  /// Flow tương tự Google login, nhưng:
  /// - Dùng FacebookAuthService (không qua Firebase)
  /// - Tạo MockFirebaseUser để đồng bộ backend
  /// - Backend lưu facebook_id thay vì google_id
  /// 
  /// Fallback: Nếu backend offline → Tạo user local
  /// 
  /// Returns: AuthResult với user/role hoặc error
  Future<AuthResult> signInWithFacebook() async {
    try {
      // Đăng nhập với Facebook
      final facebookResult = await _facebookAuthService.signInWithFacebook();

      if (!facebookResult.isSuccess) {
        if (facebookResult.isCancelled) {
          return AuthResult.cancelled();
        }
        return AuthResult.error(
          facebookResult.error ?? 'Đăng nhập Facebook thất bại',
        );
      }

      print('🔥 Facebook login thành công, đang đồng bộ với backend...');

      // Tạo mock Firebase user object từ Facebook data
      final firebaseUser = MockFirebaseUser(
        uid: facebookResult.userId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        displayName: facebookResult.name,
        email: facebookResult.email,
        photoURL: facebookResult.photoUrl,
      );

      // Đồng bộ user với backend
      final syncResult = await _syncFirebaseUserToBackend(
        firebaseUser: firebaseUser,
        provider: 'facebook.com',
        facebookId: facebookResult.userId,
      );

      if (syncResult.isSuccess) {
        _currentUser = syncResult.user;
        _currentUserRole = syncResult.userRole;
        _authToken = syncResult.token;

        await saveUserData(syncResult.user!, syncResult.token!, syncResult.userRole);
        
        // ✅ Lưu vào Firestore để hotel manager có thể liên hệ
        await _saveUserToFirestore(
          firebaseUser: firebaseUser,
          backendUser: syncResult.user!,
          userRole: syncResult.userRole!,
        );
        
        return syncResult;
      } else {
        // Fallback: tạo user local nếu không đồng bộ được backend
        print('⚠️ Không thể đồng bộ với backend, tạo user local...');
        final user = User(
          id: (facebookResult.userId ?? DateTime.now().millisecondsSinceEpoch.toString()).hashCode,
          hoTen: facebookResult.name ?? 'Facebook User',
          email: facebookResult.email ?? 'facebook@example.com',
          anhDaiDien: facebookResult.photoUrl,
          trangThai: 1,
          createdAt: DateTime.now(),
        );

        final userRole = UserRoleModel(
          uid: facebookResult.userId ?? DateTime.now().millisecondsSinceEpoch.toString(),
          email: facebookResult.email ?? 'facebook@example.com',
          displayName: facebookResult.name ?? 'Facebook User',
          photoURL: facebookResult.photoUrl,
          role: UserRole.user,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          permissions: UserRole.user.defaultPermissions,
        );

        _currentUser = user;
        _currentUserRole = userRole;
        _authToken = 'facebook_${facebookResult.userId ?? DateTime.now().millisecondsSinceEpoch}';

        await saveUserData(user, _authToken!, userRole);
        return AuthResult.success(user, userRole);
      }
    } catch (e) {
      return AuthResult.error('Lỗi đăng nhập Facebook: $e');
    }
  }

  /// Đăng ký tài khoản mới với Backend API
  /// 
  /// Gọi API: POST /auth/register
  /// 
  /// Validation (Backend):
  /// - Email unique (không trùng)
  /// - Password ≥ 6 ký tự
  /// - Số điện thoại hợp lệ
  /// 
  /// Sau khi tạo thành công:
  /// - User mới có role = 'user' (default)
  /// - Tự động đăng nhập (trả về token)
  /// 
  /// Fallback: Nếu backend offline → Tạo user local (không lưu DB)
  /// 
  /// Returns: AuthResult với user/role/token hoặc error
  Future<AuthResult> signUp({
    required String hoTen,
    required String email,
    required String matKhau,
    required String sdt,
    String? gioiTinh,
    DateTime? ngaySinh,
  }) async {
    try {
      print('🚀 Bắt đầu đăng ký: $email');
      
      final response = await _dio.post(
        '/auth/register',
        data: {
          'ho_ten': hoTen,
          'email': email,
          'mat_khau': matKhau,
          'sdt': sdt,
          'gioi_tinh': gioiTinh,
          'ngay_sinh': ngaySinh?.toIso8601String(),
        },
      );
      
      print('📡 Response từ server: ${response.statusCode}');
      print('📄 Response data: ${response.data}');

      if (response.data['success']) {
        final userData = response.data['user'];
        final token = response.data['token'];
        final roleData = response.data['role'];

        final user = User(
          id: userData['id'],
          hoTen: userData['ho_ten'] ?? '',
          email: userData['email'] ?? '',
          anhDaiDien: userData['anh_dai_dien'],
          trangThai: userData['trang_thai'] is bool 
              ? (userData['trang_thai'] ? 1 : 0)
              : (userData['trang_thai'] ?? 1),
          createdAt: DateTime.now(),
        );

        // Parse user role (new users default to 'user' role)
        UserRoleModel userRole = UserRoleModel(
          uid: userData['id'].toString(),
          email: userData['email'] ?? '',
          displayName: userData['ho_ten'] ?? '',
          photoURL: userData['hinh_anh'],
          role: roleData != null ? _parseUserRole(roleData['role'] ?? 'user') : UserRole.user,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          hotelId: roleData?['hotel_id']?.toString(),
          permissions: roleData != null 
              ? List<String>.from(roleData['permissions'] ?? [])
              : UserRole.user.defaultPermissions,
        );

        _currentUser = user;
        _authToken = token;
        _currentUserRole = userRole;

        await saveUserData(user, token, userRole);

        return AuthResult.success(user, userRole);
      } else {
        return AuthResult.error(response.data['message'] ?? 'Đăng ký thất bại');
      }
    } catch (e) {
      print('❌ Register error: $e');
      if (e is DioException) {
        if (e.response?.statusCode == 400) {
          // Parse validation errors from backend
          final errorData = e.response?.data;
          if (errorData is Map<String, dynamic>) {
            final message = errorData['message'] ?? 'Dữ liệu không hợp lệ';
            final errors = errorData['errors'];
            if (errors != null) {
              final errorList = <String>[];
              if (errors is Map) {
                for (final entry in errors.entries) {
                  final key = entry.key;
                  final value = entry.value;
                  if (value is List) {
                    errorList.addAll(value.map((e) => e.toString()));
                  } else {
                    errorList.add(value.toString());
                  }
                }
              } else if (errors is List) {
                errorList.addAll(errors.map((e) => e.toString()));
              } else {
                errorList.add(errors.toString());
              }
              return AuthResult.error('${message}\n${errorList.join('\n')}');
            }
            return AuthResult.error(message);
          }
          return AuthResult.error('Dữ liệu không hợp lệ. Vui lòng kiểm tra lại thông tin.');
        } else if (e.response?.statusCode == 409) {
          return AuthResult.error('Email đã được sử dụng. Vui lòng chọn email khác.');
        } else if (e.response?.statusCode == 500) {
          return AuthResult.error('Lỗi máy chủ. Vui lòng thử lại sau.');
        } else if (e.type == DioExceptionType.connectionTimeout || 
                   e.type == DioExceptionType.receiveTimeout ||
                   e.type == DioExceptionType.connectionError) {
          // Fallback: Tạo user local khi không kết nối được backend
          print('🔄 Backend không khả dụng, tạo user local...');
          return _createLocalUser(hoTen, email, sdt);
        }
      }
      
      // Fallback cho tất cả các lỗi khác - tạo user local
      print('🔄 Có lỗi kết nối, tạo user local làm fallback...');
      return _createLocalUser(hoTen, email, sdt);
    }
  }

  /// [PRIVATE] Tạo user local khi backend offline (FALLBACK)
  /// 
  /// Chỉ lưu trong SharedPreferences (không có trong DB thật)
  /// User local:
  /// - id = timestamp
  /// - role = 'user'
  /// - token = 'local_token_{timestamp}'
  /// 
  /// Lưu ý: User local KHÔNG ĐỒNG BỘ với backend, chỉ dùng khi demo/offline
  Future<AuthResult> _createLocalUser(String hoTen, String email, String sdt) async {
    try {
      final user = User(
        id: DateTime.now().millisecondsSinceEpoch,
        hoTen: hoTen,
        email: email,
        anhDaiDien: null,
        trangThai: 1,
        createdAt: DateTime.now(),
      );

      final userRole = UserRoleModel(
        uid: user.id.toString(),
        email: email,
        displayName: hoTen,
        photoURL: null,
        role: UserRole.user,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        permissions: UserRole.user.defaultPermissions,
      );

      _currentUser = user;
      _authToken = 'local_token_${DateTime.now().millisecondsSinceEpoch}';
      _currentUserRole = userRole;

      await saveUserData(user, _authToken!, userRole);

      return AuthResult.success(user, userRole);
    } catch (e) {
      return AuthResult.error('Lỗi tạo tài khoản local: $e');
    }
  }

  /// Đăng xuất toàn bộ
  /// 
  /// Xóa:
  /// - user_data trong SharedPreferences
  /// - auth_token trong SharedPreferences
  /// - user_role trong SharedPreferences
  /// - login_time trong SharedPreferences (quan trọng!)
  /// - Firebase session (QUAN TRỌNG cho chat!)
  /// - Facebook session
  /// 
  /// Reset:
  /// - _currentUser = null
  /// - _authToken = null
  /// - _currentUserRole = null
  Future<void> signOut() async {
    try {
      // ✅ FIX: Đăng xuất Firebase Auth (QUAN TRỌNG cho chat!)
      try {
        await fb.FirebaseAuth.instance.signOut();
        print('✅ Firebase Auth signed out');
      } catch (firebaseError) {
        print('⚠️ Firebase signOut error (non-critical): $firebaseError');
      }

      // Đăng xuất Facebook nếu có
      await _facebookAuthService.signOut();

      // Xóa dữ liệu local
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
      await prefs.remove('auth_token');
      await prefs.remove('user_role');
      await prefs.remove('login_time'); // Xóa login timestamp

      _currentUser = null;
      _authToken = null;
      _currentUserRole = null;
      
      print('✅ User logged out and all data cleared (including Firebase)');
    } catch (e) {
      print('Lỗi khi đăng xuất: $e');
    }
  }

  /// [PRIVATE] Parse user role từ string sang enum UserRole
  /// 
  /// Mapping:
  /// - "admin" → UserRole.admin
  /// - "hotel_manager" / "hotelmanager" / "manager" → UserRole.hotelManager
  /// - "user" / default → UserRole.user
  UserRole _parseUserRole(String roleString) {
    switch (roleString.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'hotel_manager':
      case 'hotelmanager':
        return UserRole.hotelManager;
      case 'user':
      default:
        return UserRole.user;
    }
  }

  /// Lưu thông tin user vào SharedPreferences (QUAN TRỌNG!)
  /// 
  /// Lưu 4 keys:
  /// 1. user_data - User object (JSON)
  /// 2. auth_token - JWT token từ Backend
  /// 3. user_role - UserRoleModel (JSON) - Admin/Manager/User
  /// 4. login_time - Timestamp đăng nhập (để AuthService check session)
  /// 
  /// ⚠️ Nếu thiếu login_time → Session sẽ bị xem là expired ngay lập tức!
  Future<void> saveUserData(User user, String token, UserRoleModel? userRole) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentTime = DateTime.now().toIso8601String();
      
      await prefs.setString('user_data', jsonEncode(user.toJson()));
      await prefs.setString('auth_token', token);
      
      // Lưu login timestamp để AuthService có thể check session validity
      await prefs.setString('login_time', currentTime);
      
      if (userRole != null) {
        await prefs.setString('user_role', jsonEncode(userRole.toJson()));
      }
      
      print('✅ User data saved with login timestamp: $currentTime');
    } catch (e) {
      print('Lỗi khi lưu dữ liệu user: $e');
    }
  }

  /// Khôi phục user data từ SharedPreferences khi app start
  /// 
  /// Được gọi trong main() để restore session cũ (nếu có)
  /// 
  /// Load:
  /// - user_data → _currentUser
  /// - auth_token → _authToken
  /// - user_role → _currentUserRole
  /// 
  /// Lưu ý: Không check login_time ở đây, AuthService sẽ check
  Future<void> restoreUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_data');
      final token = prefs.getString('auth_token');
      final roleData = prefs.getString('user_role');

      if (userData != null && token != null) {
        _currentUser = User.fromJson(jsonDecode(userData));
        _authToken = token;
        
        if (roleData != null) {
          _currentUserRole = UserRoleModel.fromJson(jsonDecode(roleData));
        }
      }
    } catch (e) {
      print('Lỗi khi khôi phục dữ liệu user: $e');
    }
  }

  /// Kiểm tra user đã đăng nhập chưa (dựa vào _currentUser và _authToken)
  /// 
  /// Returns: true nếu có user + token, false nếu chưa đăng nhập
  bool get isSignedIn => _currentUser != null && _authToken != null;

  /// [PRIVATE] Đồng bộ Firebase user với Backend API
  /// 
  /// Gọi API: POST /api/auth/firebase-social-login
  /// 
  /// Backend logic:
  /// - Check email có tồn tại chưa
  /// - Nếu có → Cập nhật google_id/facebook_id và login
  /// - Nếu chưa → Tạo user mới với provider info
  /// - Trả về user + JWT token + role
  /// 
  /// Parameters:
  ///   - firebaseUser: fb.User (Google) hoặc MockFirebaseUser (Facebook)
  ///   - provider: "google.com" hoặc "facebook.com"
  ///   - googleId/facebookId: Provider-specific ID
  /// 
  /// Returns: AuthResult với user/role/token hoặc error
  Future<AuthResult> _syncFirebaseUserToBackend({
    required dynamic firebaseUser, // Can be fb.User or MockFirebaseUser
    required String provider,
    String? googleId,
    String? facebookId,
  }) async {
    try {
      print('🔄 Đang đồng bộ Firebase user với backend...');
      
      final response = await _dio.post(
        '/api/auth/firebase-social-login',
        data: {
          'firebase_uid': firebaseUser.uid,
          'email': firebaseUser.email,
          'ho_ten': firebaseUser.displayName,
          'anh_dai_dien': firebaseUser.photoURL,
          'provider': provider,
          'google_id': googleId,
          'facebook_id': facebookId,
          'access_token': await firebaseUser.getIdToken(),
        },
      );

      if (response.data['success'] == true) {
        final userData = response.data['user'];
        final token = response.data['token'];
        final roleData = response.data['role'];

        print('📦 Backend Response:');
        print('  - userData: $userData');
        print('  - roleData: $roleData');
        print('  - chuc_vu from user: ${userData['chuc_vu']}');

        final user = User(
          id: userData['id'],
          hoTen: userData['ho_ten'] ?? firebaseUser.displayName ?? '',
          email: userData['email'] ?? firebaseUser.email ?? '',
          anhDaiDien: userData['anh_dai_dien'] ?? firebaseUser.photoURL,
          trangThai: userData['trang_thai'] is bool 
              ? (userData['trang_thai'] ? 1 : 0)
              : (userData['trang_thai'] ?? 1),
          chucVu: userData['chuc_vu'], // Thêm chuc_vu từ backend
          createdAt: DateTime.now(),
        );

        // Parse user role
        UserRoleModel? userRole;
        if (roleData != null) {
          final parsedRole = _parseUserRole(roleData['role'] ?? 'user');
          print('🎭 Parsing role:');
          print('  - roleData[role]: ${roleData['role']}');
          print('  - Parsed to: ${parsedRole.value}');
          
          userRole = UserRoleModel(
            uid: userData['id'].toString(),
            email: userData['email'] ?? '',
            displayName: userData['ho_ten'] ?? '',
            photoURL: userData['anh_dai_dien'],
            role: parsedRole,
            isActive: roleData['is_active'] ?? true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            hotelId: roleData['hotel_id']?.toString(),
            permissions: List<String>.from(roleData['permissions'] ?? []),
          );
        } else {
          // Default role for users without role data
          userRole = UserRoleModel(
            uid: userData['id'].toString(),
            email: userData['email'] ?? '',
            displayName: userData['ho_ten'] ?? '',
            photoURL: userData['anh_dai_dien'],
            role: UserRole.user,
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            permissions: UserRole.user.defaultPermissions,
          );
        }

        print('✅ Đồng bộ Firebase thành công với backend');
        return AuthResult.success(user, userRole, token);
      } else {
        return AuthResult.error(
          response.data['message'] ?? 'Không thể đồng bộ với backend',
        );
      }
    } catch (e) {
      print('❌ Lỗi đồng bộ Firebase với backend: $e');
      print('📡 BaseURL đang dùng: ${AppConstants.baseUrl}');
      
      if (e is DioException) {
        if (e.response?.statusCode == 409) {
          return AuthResult.error('Tài khoản đã được liên kết với tài khoản khác');
        } else if (e.response?.statusCode == 400) {
          return AuthResult.error('Dữ liệu không hợp lệ');
        } else if (e.type == DioExceptionType.connectionError || 
                   e.type == DioExceptionType.connectionTimeout) {
          return AuthResult.error(
            'Không thể kết nối đến server.\n'
            'Vui lòng kiểm tra:\n'
            '1. Backend server đã chạy chưa?\n'
            '2. URL: ${AppConstants.baseUrl}\n'
            '3. Thử khởi động lại app'
          );
        }
      }
      return AuthResult.error('Lỗi kết nối backend. Vui lòng thử lại sau.');
    }
  }

  /// Đồng bộ Firebase user hiện tại với Backend (nếu chưa đồng bộ)
  /// 
  /// Gọi API: POST /api/auth/social-login
  /// 
  /// Use case: Khi user đã login Firebase nhưng chưa có session Backend
  /// 
  /// Returns: true nếu đồng bộ thành công, false nếu thất bại
  Future<bool> ensureBackendSessionFromFirebase() async {
    try {
      if (_authToken != null && _currentUser != null) return true;
      final fbUser = fb.FirebaseAuth.instance.currentUser;
      if (fbUser == null) return false;

      final response = await _dio.post(
        '/api/auth/social-login',
        data: {
          'email': fbUser.email,
          'ho_ten': fbUser.displayName,
          'anh_dai_dien': fbUser.photoURL,
          'provider': fbUser.providerData.isNotEmpty
              ? fbUser.providerData.first.providerId
              : 'firebase',
          'access_token': await fbUser.getIdToken(),
        },
      );

      if (response.data['success'] == true) {
        final userData = response.data['data']?['user'] ?? response.data['user'];
        final token = response.data['data']?['token'] ?? response.data['token'];

        final user = User(
          id: userData['id'],
          hoTen: userData['ho_ten'] ?? fbUser.displayName ?? '',
          email: userData['email'] ?? fbUser.email ?? '',
          anhDaiDien: userData['anh_dai_dien'] ?? userData['hinh_anh'] ?? fbUser.photoURL,
          trangThai: userData['trang_thai'] is bool 
              ? (userData['trang_thai'] ? 1 : 0)
              : (userData['trang_thai'] ?? 1),
          createdAt: DateTime.now(),
        );

        _currentUser = user;
        _authToken = token?.toString();
        await saveUserData(user, _authToken ?? '', null);
        return true;
      }
    } catch (e) {
      print('ensureBackendSessionFromFirebase error: $e');
    }
    return false;
  }

  /// 🔥 Sync backend user to Firebase Auth for chat functionality
  Future<void> _syncToFirebase(
    String email,
    String password,
    User user,
    UserRoleModel userRole,
  ) async {
    try {
      print('🔥 Syncing to Firebase for chat...');
      
      // Try to sign in to Firebase with email/password
      try {
        final result = await _firebaseAuthService.signInWithEmailPassword(
          email,
          password,
        );
        
        if (result.isSuccess && result.user != null) {
          print('✅ Firebase sign-in successful: ${result.user!.uid}');
          
          // Update Firebase user profile
          await result.user!.updateDisplayName(user.hoTen);
          if (user.anhDaiDien != null) {
            await result.user!.updatePhotoURL(user.anhDaiDien);
          }
          
          // Store user role in Firestore
          await firestore.FirebaseFirestore.instance
              .collection('users')
              .doc(result.user!.uid)
              .set({
            'email': email,
            'display_name': user.hoTen,
            'photo_url': user.anhDaiDien,
            'role': userRole.role.value, // ✅ Dùng .value để lưu đúng format
            'backend_user_id': user.id,
            'is_active': userRole.isActive,
            'hotel_id': userRole.hotelId,
            'updated_at': firestore.FieldValue.serverTimestamp(),
          }, firestore.SetOptions(merge: true));
          
          print('✅ Firebase sync completed!');
          return;
        }
      } catch (signInError) {
        print('⚠️ Firebase sign-in failed, trying to create account: $signInError');
        
        // If sign-in fails, try to create new Firebase account
        final createResult = await _firebaseAuthService.signUpWithEmailPassword(
          email,
          password,
          user.hoTen ?? email.split('@')[0], // Fallback to email prefix if name is null
        );
        
        if (createResult.isSuccess && createResult.user != null) {
          print('✅ Firebase account created: ${createResult.user!.uid}');
          
          // Update photo if available
          if (user.anhDaiDien != null) {
            await createResult.user!.updatePhotoURL(user.anhDaiDien);
          }
          
          // Store user data in Firestore
          await firestore.FirebaseFirestore.instance
              .collection('users')
              .doc(createResult.user!.uid)
              .set({
            'email': email,
            'display_name': user.hoTen,
            'photo_url': user.anhDaiDien,
            'role': userRole.role.value, // ✅ Dùng .value để lưu đúng format
            'backend_user_id': user.id,
            'is_active': userRole.isActive,
            'hotel_id': userRole.hotelId,
            'created_at': firestore.FieldValue.serverTimestamp(),
            'updated_at': firestore.FieldValue.serverTimestamp(),
          });
          
          print('✅ Firebase sync completed (new account)!');
        } else {
          print('❌ Failed to create Firebase account: ${createResult.error}');
        }
      }
    } catch (e) {
      print('❌ Firebase sync error: $e');
      // Don't throw - Firebase sync is optional, backend login should still work
    }
  }

  /// [PRIVATE] Kiểm tra email có trong whitelist Admin không
  /// 
  /// Hardcoded admin emails (dùng cho fallback local admin)
  /// 
  /// Returns: true nếu email trong danh sách admin
  bool _isAdminEmail(String email) {
    final adminEmails = [
      'dcao52862@gmail.com',
      'admin@bookinghotel.com',
      'admin@gmail.com',
    ];
    return adminEmails.contains(email.toLowerCase());
  }

  /// [PRIVATE] Tạo user local với role Admin (FALLBACK)
  /// 
  /// Dùng khi:
  /// - Backend offline
  /// - Email trong danh sách admin whitelist
  /// 
  /// Tạo user local với:
  /// - role = UserRole.admin
  /// - token = 'local_admin_token_{uid}'
  /// 
  /// Lưu ý: User này KHÔNG có trong DB thật
  AuthResult _createLocalAdminUser(dynamic firebaseUser) {
    final user = User(
      id: null,
      hoTen: firebaseUser.displayName ?? 'Admin User',
      email: firebaseUser.email!,
      anhDaiDien: firebaseUser.photoURL,
      chucVu: 'Admin',
      trangThai: 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final userRole = UserRoleModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email!,
      displayName: firebaseUser.displayName ?? 'Admin User',
      photoURL: firebaseUser.photoURL,
      role: UserRole.admin,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      permissions: [],
    );

    // Lưu user và role vào local storage
    _currentUser = user;
    _currentUserRole = userRole;
    _authToken = 'local_admin_token_${firebaseUser.uid}';

    // Lưu vào SharedPreferences
    _saveUserData(user, userRole, _authToken!);

    print('✅ Đã tạo user local admin: ${user.email}');
    return AuthResult.success(user, userRole, _authToken!);
  }

  /// [PRIVATE] Lưu user data vào SharedPreferences (helper method)
  /// 
  /// Tương tự saveUserData() nhưng:
  /// - Không nullable parameters
  /// - Dùng nội bộ trong class
  Future<void> _saveUserData(User user, UserRoleModel userRole, String token) async {
    final prefs = await SharedPreferences.getInstance();
    final currentTime = DateTime.now().toIso8601String();
    
    await prefs.setString('user_data', jsonEncode(user.toJson()));
    await prefs.setString('user_role', jsonEncode(userRole.toJson()));
    await prefs.setString('auth_token', token);
    await prefs.setString('login_time', currentTime); // Lưu login timestamp
  }
}

/// Class chứa kết quả của việc xác thực
/// 
/// 3 trạng thái:
/// 1. Success: isSuccess = true, có user + userRole + token
/// 2. Error: isSuccess = false, có error message
/// 3. Cancelled: isSuccess = false, isCancelled = true (user hủy login)
class AuthResult {
  final bool isSuccess;
  final User? user;
  final UserRoleModel? userRole;
  final String? token;
  final String? error;
  final bool isCancelled;

  AuthResult._({
    required this.isSuccess,
    this.user,
    this.userRole,
    this.token,
    this.error,
    this.isCancelled = false,
  });

  /// Tạo AuthResult thành công
  /// 
  /// Parameters:
  ///   - user: User object (required)
  ///   - userRole: UserRoleModel (optional)
  ///   - token: JWT token (optional)
  factory AuthResult.success(User user, [UserRoleModel? userRole, String? token]) {
    return AuthResult._(isSuccess: true, user: user, userRole: userRole, token: token);
  }

  /// Tạo AuthResult lỗi
  /// 
  /// Parameters:
  ///   - error: Error message
  factory AuthResult.error(String error) {
    return AuthResult._(isSuccess: false, error: error);
  }

  /// Tạo AuthResult bị hủy (user cancelled login)
  factory AuthResult.cancelled() {
    return AuthResult._(isSuccess: false, isCancelled: true);
  }
}

/// Extension cho BackendAuthService - Lưu user vào Firestore
extension BackendAuthServiceFirestore on BackendAuthService {
  /// Lưu user profile vào Firestore để hotel manager có thể tìm và liên hệ
  Future<void> _saveUserToFirestore({
    required dynamic firebaseUser,
    required User backendUser,
    required UserRoleModel userRole,
  }) async {
    try {
      final firestoreInstance = firestore.FirebaseFirestore.instance;
      
      // Lấy Firebase UID (có thể là real Firebase UID hoặc mock UID)
      final firebaseUid = firebaseUser.uid;
      
      print('💾 Đang lưu user vào Firestore...');
      print('  - Firebase UID: $firebaseUid');
      print('  - Backend User ID: ${backendUser.id}');
      print('  - Email: ${backendUser.email}');
      
      // Tạo user profile trong Firestore
      final userProfile = {
        'backend_user_id': backendUser.id.toString(),
        'firebase_uid': firebaseUid,
        'email': backendUser.email.toLowerCase(), // ✅ Lưu lowercase để query dễ
        'display_name': backendUser.hoTen,
        'photo_url': backendUser.anhDaiDien,
        'role': userRole.role.value, // ✅ FIX: Dùng .value thay vì .name để lưu "hotel_manager" thay vì "hotelManager"
        'hotel_id': userRole.hotelId,
        'is_active': userRole.isActive,
        'last_login': firestore.FieldValue.serverTimestamp(),
        'updated_at': firestore.FieldValue.serverTimestamp(),
      };
      
      // Lưu vào collection 'users' (key = Firebase UID)
      await firestoreInstance.collection('users').doc(firebaseUid).set(
        userProfile,
        firestore.SetOptions(merge: true),
      );
      
      // Lưu vào collection 'user_mapping' (key = Backend User ID) để reverse lookup
      await firestoreInstance.collection('user_mapping').doc(backendUser.id.toString()).set({
        'firebase_uid': firebaseUid,
        'email': backendUser.email.toLowerCase(),
        'updated_at': firestore.FieldValue.serverTimestamp(),
      });
      
      print('✅ Đã lưu user vào Firestore thành công');
      
      // ✅ FIX: Cập nhật conversations cũ có offline placeholder
      await _fixOfflineConversations(firebaseUid, backendUser.id.toString());
      
    } catch (e) {
      print('❌ Lỗi khi lưu user vào Firestore: $e');
      // Không throw error, chỉ log để không block login flow
    }
  }
  
  /// Fix offline conversations by replacing offline_ID with real Firebase UID
  Future<void> _fixOfflineConversations(String realFirebaseUid, String backendUserId) async {
    try {
      print('🔧 Fixing offline conversations for user $backendUserId...');
      
      final offlinePlaceholder = 'offline_$backendUserId';
      
      // Query conversations with offline placeholder
      final conversationsSnapshot = await firestore.FirebaseFirestore.instance
          .collection('conversations')
          .where('participants', arrayContains: offlinePlaceholder)
          .get();
      
      if (conversationsSnapshot.docs.isEmpty) {
        print('✅ No offline conversations to fix');
        return;
      }
      
      print('🔍 Found ${conversationsSnapshot.docs.length} offline conversations to fix');
      
      for (var doc in conversationsSnapshot.docs) {
        try {
          final data = doc.data();
          final participants = List<String>.from(data['participants'] ?? []);
          final participantRoles = Map<String, dynamic>.from(data['participantRoles'] ?? {});
          final participantNames = Map<String, dynamic>.from(data['participantNames'] ?? {});
          final participantEmails = Map<String, dynamic>.from(data['participantEmails'] ?? {});
          
          // Replace offline placeholder with real UID
          final index = participants.indexOf(offlinePlaceholder);
          if (index != -1) {
            participants[index] = realFirebaseUid;
            
            // Update roles, names, emails
            if (participantRoles.containsKey(offlinePlaceholder)) {
              participantRoles[realFirebaseUid] = participantRoles[offlinePlaceholder];
              participantRoles.remove(offlinePlaceholder);
            }
            if (participantNames.containsKey(offlinePlaceholder)) {
              participantNames[realFirebaseUid] = participantNames[offlinePlaceholder];
              participantNames.remove(offlinePlaceholder);
            }
            if (participantEmails.containsKey(offlinePlaceholder)) {
              participantEmails[realFirebaseUid] = participantEmails[offlinePlaceholder];
              participantEmails.remove(offlinePlaceholder);
            }
            
            // Update Firestore
            await doc.reference.update({
              'participants': participants,
              'participantRoles': participantRoles,
              'participantNames': participantNames,
              'participantEmails': participantEmails,
              'updated_at': firestore.FieldValue.serverTimestamp(),
            });
            
            print('✅ Fixed conversation ${doc.id}: $offlinePlaceholder → $realFirebaseUid');
          }
        } catch (e) {
          print('⚠️ Error fixing conversation ${doc.id}: $e');
        }
      }
      
      print('✅ Finished fixing offline conversations');
    } catch (e) {
      print('❌ Error in _fixOfflineConversations: $e');
      // Non-critical, don't throw
    }
  }
}
