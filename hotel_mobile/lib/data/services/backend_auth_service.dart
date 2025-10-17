import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../core/constants/app_constants.dart';
import '../../core/services/facebook_auth_service.dart';
import '../../core/services/firebase_auth_service.dart';
import '../models/user.dart';
import '../models/user_role_model.dart';

class BackendAuthService {
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

  // Base URL đã cấu hình qua AppConstants.baseUrl

  User? _currentUser;
  String? _authToken;
  UserRoleModel? _currentUserRole;

  User? get currentUser => _currentUser;
  String? get authToken => _authToken;
  UserRoleModel? get currentUserRole => _currentUserRole;

  /// Đăng nhập bằng email và password
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

        final user = User(
          id: userData['id'],
          hoTen: userData['ho_ten'] ?? '',
          email: userData['email'] ?? '',
          anhDaiDien: userData['anh_dai_dien'],
          trangThai: userData['trang_thai'] ?? 1,
          createdAt: DateTime.now(),
        );

        // Parse user role
        UserRoleModel? userRole;
        if (roleData != null) {
          userRole = UserRoleModel(
            uid: userData['id'].toString(),
            email: userData['email'] ?? '',
            displayName: userData['ho_ten'] ?? '',
            photoURL: userData['anh_dai_dien'],
            role: _parseUserRole(roleData['role'] ?? 'user'),
            isActive: roleData['is_active'] ?? true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            hotelId: roleData['hotel_id'],
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
        await _saveUserData(user, token, userRole);

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

  /// Đăng nhập bằng Google (chỉ sử dụng Firebase, không gọi backend)
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

      // Tạo User object từ Firebase user (không cần đồng bộ với backend)
      final firebaseUser = googleResult.user;
      if (firebaseUser != null) {
        final user = User(
          id: firebaseUser.uid.hashCode, // Sử dụng Firebase UID hash
          hoTen: firebaseUser.displayName ?? 'Google User',
          email: firebaseUser.email ?? '',
          anhDaiDien: firebaseUser.photoURL,
          trangThai: 1,
          createdAt: DateTime.now(),
        );

        // Default role for Google users
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

        // Lưu thông tin người dùng (không cần token backend)
        await _saveUserData(user, '', userRole);

        return AuthResult.success(user, userRole);
      }

      return AuthResult.error('Không thể lấy thông tin user từ Google');
    } catch (e) {
      return AuthResult.error('Lỗi đăng nhập Google: $e');
    }
  }

  /// Đăng nhập bằng Facebook (chỉ sử dụng Firebase, không gọi backend)
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

      // Tạo User object từ Facebook data (không cần gọi backend)
      final user = User(
        id: (facebookResult.userId ?? DateTime.now().millisecondsSinceEpoch.toString()).hashCode,
        hoTen: facebookResult.name ?? 'Facebook User',
        email: facebookResult.email ?? 'facebook@example.com',
        anhDaiDien: facebookResult.photoUrl,
        trangThai: 1,
        createdAt: DateTime.now(),
      );

      // Default role for Facebook users
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

      // Lưu thông tin người dùng (không cần token backend)
      await _saveUserData(user, '', userRole);

      return AuthResult.success(user, userRole);
    } catch (e) {
      return AuthResult.error('Lỗi đăng nhập Facebook: $e');
    }
  }

  /// Đăng ký tài khoản mới
  Future<AuthResult> signUp({
    required String hoTen,
    required String email,
    required String matKhau,
    required String sdt,
    String? gioiTinh,
    DateTime? ngaySinh,
  }) async {
    try {
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

      if (response.data['success']) {
        final userData = response.data['user'];
        final token = response.data['token'];
        final roleData = response.data['role'];

        final user = User(
          id: userData['id'],
          hoTen: userData['ho_ten'] ?? '',
          email: userData['email'] ?? '',
          anhDaiDien: userData['anh_dai_dien'],
          trangThai: userData['trang_thai'] ?? 1,
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
          hotelId: roleData?['hotel_id'],
          permissions: roleData != null 
              ? List<String>.from(roleData['permissions'] ?? [])
              : UserRole.user.defaultPermissions,
        );

        _currentUser = user;
        _authToken = token;
        _currentUserRole = userRole;

        await _saveUserData(user, token, userRole);

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
              errors.forEach((key, value) {
                if (value is List) {
                  errorList.addAll(value.map((e) => e.toString()));
                } else {
                  errorList.add(value.toString());
                }
              });
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
      return AuthResult.error('Lỗi kết nối: $e');
    }
  }

  /// Tạo user local khi backend không khả dụng
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

      await _saveUserData(user, _authToken!, userRole);

      return AuthResult.success(user, userRole);
    } catch (e) {
      return AuthResult.error('Lỗi tạo tài khoản local: $e');
    }
  }

  /// Đăng xuất
  Future<void> signOut() async {
    try {
      // Đăng xuất Facebook nếu có
      await _facebookAuthService.signOut();

      // Xóa dữ liệu local
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
      await prefs.remove('auth_token');
      await prefs.remove('user_role');

      _currentUser = null;
      _authToken = null;
      _currentUserRole = null;
    } catch (e) {
      print('Lỗi khi đăng xuất: $e');
    }
  }

  /// Parse user role from string
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

  /// Lưu thông tin người dùng vào local storage
  Future<void> _saveUserData(User user, String token, UserRoleModel? userRole) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(user.toJson()));
      await prefs.setString('auth_token', token);
      if (userRole != null) {
        await prefs.setString('user_role', jsonEncode(userRole.toJson()));
      }
    } catch (e) {
      print('Lỗi khi lưu dữ liệu user: $e');
    }
  }

  /// Khôi phục thông tin người dùng từ local storage
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

  /// Kiểm tra xem người dùng đã đăng nhập chưa
  bool get isSignedIn => _currentUser != null && _authToken != null;

  /// Đồng bộ user Firebase sang backend (tự động tạo/đăng nhập ở backend)
  Future<bool> ensureBackendSessionFromFirebase() async {
    try {
      if (_authToken != null && _currentUser != null) return true;
      final fbUser = fb.FirebaseAuth.instance.currentUser;
      if (fbUser == null) return false;

      final response = await _dio.post(
        '/auth/social-login',
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
          trangThai: userData['trang_thai'] ?? 1,
          createdAt: DateTime.now(),
        );

        _currentUser = user;
        _authToken = token?.toString();
        await _saveUserData(user, _authToken ?? '', null);
        return true;
      }
    } catch (e) {
      print('ensureBackendSessionFromFirebase error: $e');
    }
    return false;
  }
}

/// Kết quả của việc xác thực
class AuthResult {
  final bool isSuccess;
  final User? user;
  final UserRoleModel? userRole;
  final String? error;
  final bool isCancelled;

  AuthResult._({
    required this.isSuccess,
    this.user,
    this.userRole,
    this.error,
    this.isCancelled = false,
  });

  factory AuthResult.success(User user, [UserRoleModel? userRole]) {
    return AuthResult._(isSuccess: true, user: user, userRole: userRole);
  }

  factory AuthResult.error(String error) {
    return AuthResult._(isSuccess: false, error: error);
  }

  factory AuthResult.cancelled() {
    return AuthResult._(isSuccess: false, isCancelled: true);
  }
}
