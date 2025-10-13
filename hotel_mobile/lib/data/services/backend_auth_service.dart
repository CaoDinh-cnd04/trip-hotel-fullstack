import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../core/constants/app_constants.dart';
import '../../core/services/facebook_auth_service.dart';
import '../models/user.dart';

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

  // Base URL đã cấu hình qua AppConstants.baseUrl

  User? _currentUser;
  String? _authToken;

  User? get currentUser => _currentUser;
  String? get authToken => _authToken;

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

        final user = User(
          id: userData['id'],
          hoTen: userData['ho_ten'] ?? '',
          email: userData['email'] ?? '',
          anhDaiDien: userData['hinh_anh'],
          trangThai: userData['trang_thai'] ?? 1,
          createdAt: DateTime.now(),
        );

        _currentUser = user;
        _authToken = token;

        // Lưu thông tin người dùng
        await _saveUserData(user, token);

        return AuthResult.success(user);
      } else {
        return AuthResult.error(
          response.data['message'] ?? 'Đăng nhập thất bại',
        );
      }
    } catch (e) {
      return AuthResult.error('Lỗi kết nối: $e');
    }
  }

  /// Đăng nhập bằng Facebook
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

      // Gửi access token đến backend
      final response = await _dio.post(
        '/auth/facebook-login',
        data: {'accessToken': facebookResult.accessToken},
      );

      if (response.data['success']) {
        final userData = response.data['user'];
        final token = response.data['token'];

        final user = User(
          id: userData['id'],
          hoTen: userData['ho_ten'] ?? '',
          email: userData['email'] ?? '',
          anhDaiDien: userData['hinh_anh'],
          trangThai: userData['trang_thai'] ?? 1,
          createdAt: DateTime.now(),
        );

        _currentUser = user;
        _authToken = token;

        // Lưu thông tin người dùng
        await _saveUserData(user, token);

        return AuthResult.success(user);
      } else {
        return AuthResult.error(
          response.data['message'] ?? 'Đăng nhập Facebook thất bại',
        );
      }
    } catch (e) {
      return AuthResult.error('Lỗi kết nối: $e');
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

        final user = User(
          id: userData['id'],
          hoTen: userData['ho_ten'] ?? '',
          email: userData['email'] ?? '',
          anhDaiDien: userData['hinh_anh'],
          trangThai: userData['trang_thai'] ?? 1,
          createdAt: DateTime.now(),
        );

        _currentUser = user;
        _authToken = token;

        await _saveUserData(user, token);

        return AuthResult.success(user);
      } else {
        return AuthResult.error(response.data['message'] ?? 'Đăng ký thất bại');
      }
    } catch (e) {
      return AuthResult.error('Lỗi kết nối: $e');
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

      _currentUser = null;
      _authToken = null;
    } catch (e) {
      print('Lỗi khi đăng xuất: $e');
    }
  }

  /// Lưu thông tin người dùng vào local storage
  Future<void> _saveUserData(User user, String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(user.toJson()));
      await prefs.setString('auth_token', token);
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

      if (userData != null && token != null) {
        _currentUser = User.fromJson(jsonDecode(userData));
        _authToken = token;
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
        await _saveUserData(user, _authToken ?? '');
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
  final String? error;
  final bool isCancelled;

  AuthResult._({
    required this.isSuccess,
    this.user,
    this.error,
    this.isCancelled = false,
  });

  factory AuthResult.success(User user) {
    return AuthResult._(isSuccess: true, user: user);
  }

  factory AuthResult.error(String error) {
    return AuthResult._(isSuccess: false, error: error);
  }

  factory AuthResult.cancelled() {
    return AuthResult._(isSuccess: false, isCancelled: true);
  }
}
