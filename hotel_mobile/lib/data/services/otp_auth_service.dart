import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../models/user_role_model.dart';
import 'backend_auth_service.dart';
import '../../core/constants/app_constants.dart';

/// Service xử lý xác thực OTP
class OTPAuthService {
  final Dio _dio;
  final BackendAuthService _backendAuthService;

  OTPAuthService(this._dio, this._backendAuthService) {
    // Set base URL for Dio
    _dio.options.baseUrl = AppConstants.baseUrl;
    _dio.options.connectTimeout = AppConstants.connectTimeout;
    _dio.options.receiveTimeout = AppConstants.receiveTimeout;
    _dio.options.sendTimeout = AppConstants.sendTimeout;
  }

  /// Gửi mã OTP đến email để đăng nhập/đăng ký
  /// 
  /// Chức năng Passwordless Login - User không cần mật khẩu
  /// Backend sẽ gửi email chứa mã OTP 6 số, có hiệu lực 5 phút
  /// 
  /// Parameters:
  ///   - email: Email nhận mã OTP
  ///   - userData: Thông tin user (optional, dùng cho đăng ký mới)
  /// 
  /// Returns: OTPResult với thông tin thành công/lỗi
  Future<OTPResult> sendOTP(String email, {Map<String, dynamic>? userData}) async {
    try {
      print('📧 Đang gửi OTP đến: $email');
      
      final response = await _dio.post(
        '/api/v2/otp/send-otp',
        data: {
          'email': email.toLowerCase(),
          'user_data': userData,
        },
      );

      if (response.data['success'] == true) {
        print('✅ OTP đã được gửi thành công');
        return OTPResult.success(
          response.data['message'] ?? 'Mã OTP đã được gửi',
          response.data['expires_in'] ?? 45,
        );
      } else {
        return OTPResult.error(
          response.data['message'] ?? 'Không thể gửi mã OTP',
        );
      }
    } catch (e) {
      print('❌ Lỗi gửi OTP: $e');
      if (e is DioException) {
        if (e.response?.statusCode == 409) {
          return OTPResult.error('Email này đã được sử dụng');
        } else if (e.response?.statusCode == 429) {
          return OTPResult.error('Vui lòng đợi 45 giây trước khi gửi lại mã OTP');
        } else if (e.response?.statusCode == 400) {
          return OTPResult.error(e.response?.data['message'] ?? 'Dữ liệu không hợp lệ');
        }
      }
      return OTPResult.error('Lỗi kết nối: $e');
    }
  }

  /// Xác thực mã OTP và đăng nhập user
  /// 
  /// Khi verify thành công:
  /// - Nếu email ĐÃ TỒN TẠI: Đăng nhập vào tài khoản cũ
  /// - Nếu email CHƯA TỒN TẠI: Tự động tạo tài khoản mới
  /// - Lưu user data, token, role vào BackendAuthService
  /// - Trả về AuthResult với đầy đủ thông tin
  /// 
  /// Parameters:
  ///   - email: Email đã nhận OTP
  ///   - otpCode: Mã OTP 6 số người dùng nhập vào
  /// 
  /// Returns: AuthResult chứa user info, role, token
  Future<AuthResult> verifyOTP(String email, String otpCode) async {
    try {
      print('🔐 Đang xác thực OTP cho: $email');
      
      final response = await _dio.post(
        '/api/v2/otp/verify-otp',
        data: {
          'email': email.toLowerCase(),
          'otp_code': otpCode,
        },
      );

      if (response.data['success'] == true) {
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
          createdAt: userData['ngay_dang_ky'] != null
              ? DateTime.parse(userData['ngay_dang_ky'])
              : DateTime.now(),
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

        // Lưu thông tin user vào BackendAuthService
        await _backendAuthService.saveUserData(user, token, userRole);

        // Auto-login to Firebase for chat functionality
        try {
          await _loginToFirebaseForChat(user, userRole);
        } catch (e) {
          print('⚠️ Firebase login error (non-critical): $e');
          // Don't fail the whole login if Firebase fails
        }

        print('✅ Xác thực OTP thành công');
        return AuthResult.success(user, userRole, token);
      } else {
        return AuthResult.error(
          response.data['message'] ?? 'Mã OTP không hợp lệ',
        );
      }
    } catch (e) {
      print('❌ Lỗi xác thực OTP: $e');
      if (e is DioException) {
        if (e.response?.statusCode == 400) {
          return AuthResult.error(e.response?.data['message'] ?? 'Mã OTP không hợp lệ');
        }
      }
      return AuthResult.error('Lỗi xác thực: $e');
    }
  }

  /// Gửi lại mã OTP mới (khi OTP cũ hết hạn hoặc không nhận được)
  /// 
  /// Xóa OTP cũ và tạo mã OTP mới gửi đến email
  /// Mã mới cũng có hiệu lực 5 phút
  /// 
  /// Parameters:
  ///   - email: Email cần nhận OTP mới
  /// 
  /// Returns: OTPResult với thông tin thành công/lỗi
  Future<OTPResult> resendOTP(String email) async {
    try {
      print('🔄 Đang gửi lại OTP cho: $email');
      
      final response = await _dio.post(
        '/api/v2/otp/resend-otp',
        data: {
          'email': email.toLowerCase(),
        },
      );

      if (response.data['success'] == true) {
        print('✅ OTP đã được gửi lại thành công');
        return OTPResult.success(
          response.data['message'] ?? 'Mã OTP mới đã được gửi',
          response.data['expires_in'] ?? 45,
        );
      } else {
        return OTPResult.error(
          response.data['message'] ?? 'Không thể gửi lại mã OTP',
        );
      }
    } catch (e) {
      print('❌ Lỗi gửi lại OTP: $e');
      if (e is DioException) {
        if (e.response?.statusCode == 409) {
          return OTPResult.error('Email này đã được sử dụng');
        } else if (e.response?.statusCode == 400) {
          return OTPResult.error(e.response?.data['message'] ?? 'Dữ liệu không hợp lệ');
        }
      }
      return OTPResult.error('Lỗi kết nối: $e');
    }
  }

  /// Parse user role từ string thành enum UserRole
  /// 
  /// Chuyển đổi:
  /// - "admin" → UserRole.admin
  /// - "manager" / "hotel_manager" → UserRole.hotelManager
  /// - "user" / default → UserRole.user
  UserRole _parseUserRole(String roleString) {
    print('🔍 OTP Auth - Parsing role string: "$roleString"');
    switch (roleString.toLowerCase()) {
      case 'admin':
        print('✅ Parsed as: UserRole.admin');
        return UserRole.admin;
      case 'manager':
      case 'hotel_manager':
      case 'hotelmanager':
        print('✅ Parsed as: UserRole.hotelManager');
        return UserRole.hotelManager;
      case 'user':
      default:
        print('✅ Parsed as: UserRole.user (default)');
        return UserRole.user;
    }
  }

  /// Auto-login to Firebase for chat functionality
  /// Uses anonymous auth and stores backend user info in Firestore
  Future<void> _loginToFirebaseForChat(User user, UserRoleModel userRole) async {
    try {
      final firebaseAuth = firebase_auth.FirebaseAuth.instance;
      
      // Check if already signed in with the same email
      if (firebaseAuth.currentUser != null) {
        if (firebaseAuth.currentUser!.email == user.email.toLowerCase()) {
          print('✅ Already signed in to Firebase: ${firebaseAuth.currentUser!.uid}');
          await _updateFirestoreUserProfile(user, userRole);
          return;
        } else {
          // Sign out old user first
          print('⚠️ Different user signed in, signing out...');
          await firebaseAuth.signOut();
        }
      }

      // Generate consistent password from backend user ID
      final password = 'user_${user.id}_firebase_password';
      final email = user.email.toLowerCase();

      print('🔐 Signing in to Firebase for chat...');
      
      try {
        // Try to sign in first
        final credential = await firebaseAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        print('✅ Firebase login successful (existing): ${credential.user?.uid}');
      } catch (e) {
        // If user doesn't exist, create new account
        print('⚠️ User not found in Firebase, creating new account...');
        final credential = await firebaseAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        print('✅ Firebase account created: ${credential.user?.uid}');
        
        // Update display name
        await credential.user?.updateDisplayName(user.hoTen);
        if (user.anhDaiDien != null && user.anhDaiDien!.isNotEmpty) {
          await credential.user?.updatePhotoURL(user.anhDaiDien);
        }
      }

      // Store backend user info in Firestore for chat reference
      await _updateFirestoreUserProfile(user, userRole);
      
    } catch (e) {
      print('❌ Firebase login error: $e');
      rethrow;
    }
  }

  /// Update Firestore user profile with backend user info
  /// Creates a mapping between backend user ID and Firebase UID
  Future<void> _updateFirestoreUserProfile(User user, UserRoleModel userRole) async {
    try {
      final firebaseAuth = firebase_auth.FirebaseAuth.instance;
      final firebaseUser = firebaseAuth.currentUser;
      
      if (firebaseUser == null) {
        print('⚠️ No Firebase user to update profile');
        return;
      }

      final firestore = FirebaseFirestore.instance;
      
      // Create/update user profile in Firestore
      final userProfile = {
        'backend_user_id': user.id.toString(),
        'firebase_uid': firebaseUser.uid,
        'email': user.email.toLowerCase(), // ✅ Lưu lowercase để query dễ dàng
        'display_name': user.hoTen,
        'photo_url': user.anhDaiDien,
        'role': userRole.role.value, // ✅ FIX: Dùng .value thay vì .name để lưu "hotel_manager" thay vì "hotelManager"
        'hotel_id': userRole.hotelId,
        'is_active': userRole.isActive,
        'last_login': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };
      
      // Save to both 'users' collection (by Firebase UID) and 'user_mapping' (by backend ID)
      await firestore.collection('users').doc(firebaseUser.uid).set(
        userProfile,
        SetOptions(merge: true),
      );
      
      await firestore.collection('user_mapping').doc(user.id.toString()).set({
        'firebase_uid': firebaseUser.uid,
        'email': user.email.toLowerCase(), // ✅ Thêm email vào mapping để query
        'updated_at': FieldValue.serverTimestamp(),
      });
      
      print('✅ Firebase user profile updated: ${firebaseUser.uid} → Backend ID: ${user.id}');
      
    } catch (e) {
      print('❌ Error updating Firestore profile: $e');
    }
  }
}

/// Kết quả gửi OTP
class OTPResult {
  final bool isSuccess;
  final String? message;
  final int? expiresIn;
  final String? error;

  OTPResult._({
    required this.isSuccess,
    this.message,
    this.expiresIn,
    this.error,
  });

  /// Tạo kết quả thành công khi gửi OTP
  /// 
  /// Parameters:
  ///   - message: Thông báo thành công
  ///   - expiresIn: Thời gian hết hạn (giây)
  factory OTPResult.success(String message, [int? expiresIn]) {
    return OTPResult._(isSuccess: true, message: message, expiresIn: expiresIn);
  }

  /// Tạo kết quả lỗi khi gửi OTP thất bại
  /// 
  /// Parameters:
  ///   - error: Thông báo lỗi
  factory OTPResult.error(String error) {
    return OTPResult._(isSuccess: false, error: error);
  }
}
