import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class FirebaseAuthService {
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  factory FirebaseAuthService() => _instance;
  FirebaseAuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Lấy user hiện tại
  User? get currentUser => _auth.currentUser;

  /// Stream theo dõi trạng thái auth
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Đăng nhập bằng Google với Firebase
  Future<FirebaseAuthResult> signInWithGoogle() async {
    try {
      print('🚀 Bắt đầu đăng nhập Google với Firebase...');

      // Trigger authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('❌ User đã hủy đăng nhập Google');
        return FirebaseAuthResult.cancelled();
      }

      print('✅ Google Sign-In thành công: ${googleUser.email}');

      // Obtain auth details from request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      print('🔑 Đã lấy được Google auth tokens');

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('🔐 Đã tạo Firebase credential');

      // Sign in to Firebase with Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      final User? user = userCredential.user;

      if (user != null) {
        print('🎉 Firebase đăng nhập thành công!');
        print('👤 User: ${user.displayName}');
        print('📧 Email: ${user.email}');
        print('🆔 UID: ${user.uid}');

        return FirebaseAuthResult.success(user);
      } else {
        print('❌ Firebase user là null');
        return FirebaseAuthResult.error(
          'Không thể lấy thông tin user từ Firebase',
        );
      }
    } catch (error) {
      print('💥 Lỗi đăng nhập Google: $error');
      return FirebaseAuthResult.error('Lỗi đăng nhập Google: $error');
    }
  }

  /// Đăng nhập bằng email và password
  Future<FirebaseAuthResult> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      print('🚀 Đăng nhập bằng email: $email');

      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      final User? user = userCredential.user;

      if (user != null) {
        print('✅ Đăng nhập email thành công');
        return FirebaseAuthResult.success(user);
      } else {
        return FirebaseAuthResult.error('Không thể lấy thông tin user');
      }
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth Error: ${e.code}');
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'Không tìm thấy tài khoản với email này';
          break;
        case 'wrong-password':
          message = 'Mật khẩu không chính xác';
          break;
        case 'invalid-email':
          message = 'Email không hợp lệ';
          break;
        case 'user-disabled':
          message = 'Tài khoản đã bị vô hiệu hóa';
          break;
        default:
          message = 'Lỗi đăng nhập: ${e.message}';
      }
      return FirebaseAuthResult.error(message);
    } catch (e) {
      print('💥 Lỗi đăng nhập: $e');
      return FirebaseAuthResult.error('Lỗi kết nối: $e');
    }
  }

  /// Đăng ký tài khoản mới
  Future<FirebaseAuthResult> signUpWithEmailPassword(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      print('🚀 Đăng ký tài khoản: $email');

      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      final User? user = userCredential.user;

      if (user != null) {
        // Cập nhật display name
        await user.updateDisplayName(displayName);
        await user.reload();

        print('✅ Đăng ký thành công');
        return FirebaseAuthResult.success(_auth.currentUser!);
      } else {
        return FirebaseAuthResult.error('Không thể tạo tài khoản');
      }
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth Error: ${e.code}');
      String message;
      switch (e.code) {
        case 'weak-password':
          message = 'Mật khẩu quá yếu';
          break;
        case 'email-already-in-use':
          message = 'Email đã được sử dụng';
          break;
        case 'invalid-email':
          message = 'Email không hợp lệ';
          break;
        default:
          message = 'Lỗi đăng ký: ${e.message}';
      }
      return FirebaseAuthResult.error(message);
    } catch (e) {
      print('💥 Lỗi đăng ký: $e');
      return FirebaseAuthResult.error('Lỗi kết nối: $e');
    }
  }

  /// Đăng xuất
  Future<void> signOut() async {
    try {
      print('🚪 Đăng xuất...');

      // Đăng xuất khỏi Google
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
        print('✅ Đã đăng xuất Google');
      }

      // Đăng xuất khỏi Firebase
      await _auth.signOut();
      print('✅ Đã đăng xuất Firebase');
    } catch (e) {
      print('❌ Lỗi đăng xuất: $e');
    }
  }

  /// Kiểm tra xem user đã đăng nhập chưa
  bool get isSignedIn => _auth.currentUser != null;

  /// Lấy Firebase ID Token (để gửi lên backend)
  Future<String?> getIdToken() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        return await user.getIdToken();
      }
      return null;
    } catch (e) {
      print('❌ Lỗi lấy ID token: $e');
      return null;
    }
  }

  /// Refresh ID Token
  Future<String?> refreshIdToken() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        return await user.getIdToken(true); // force refresh
      }
      return null;
    } catch (e) {
      print('❌ Lỗi refresh token: $e');
      return null;
    }
  }
}

/// Kết quả của Firebase Authentication
class FirebaseAuthResult {
  final bool isSuccess;
  final User? user;
  final String? error;
  final bool isCancelled;

  FirebaseAuthResult._({
    required this.isSuccess,
    this.user,
    this.error,
    this.isCancelled = false,
  });

  factory FirebaseAuthResult.success(User user) {
    return FirebaseAuthResult._(isSuccess: true, user: user);
  }

  factory FirebaseAuthResult.error(String error) {
    return FirebaseAuthResult._(isSuccess: false, error: error);
  }

  factory FirebaseAuthResult.cancelled() {
    return FirebaseAuthResult._(isSuccess: false, isCancelled: true);
  }

  /// Các getter tiện ích
  String? get email => user?.email;
  String? get displayName => user?.displayName;
  String? get photoURL => user?.photoURL;
  String? get uid => user?.uid;
}
