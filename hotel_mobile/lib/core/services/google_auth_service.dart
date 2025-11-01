import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class GoogleAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Đăng nhập bằng Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Kiểm tra nếu đang chạy trên web
      if (kIsWeb) {
        // Đăng nhập trên web
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        // Force account selection on web
        googleProvider.setCustomParameters({'prompt': 'select_account'});

        return await _auth.signInWithPopup(googleProvider);
      } else {
        // Đăng nhập trên mobile (Android/iOS)
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

        if (googleUser == null) {
          // Người dùng đã hủy đăng nhập
          print('Google Sign-In cancelled by user');
          return null;
        }

        // Lấy thông tin xác thực từ Google
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        if (googleAuth.accessToken == null || googleAuth.idToken == null) {
          throw Exception('Không thể lấy access token hoặc id token từ Google');
        }

        // Tạo credential cho Firebase
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Đăng nhập vào Firebase
        final userCredential = await _auth.signInWithCredential(credential);
        print('Google Sign-In successful: ${userCredential.user?.email}');
        return userCredential;
      }
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      throw Exception('Lỗi Firebase Auth: ${e.message}');
    } catch (e) {
      print('Lỗi đăng nhập Google: $e');
      throw Exception('Đăng nhập Google thất bại: $e');
    }
  }

  // Đăng xuất
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(), 
        _googleSignIn.signOut()
      ]);
      print('✅ Đã đăng xuất Google Sign-In');
    } catch (e) {
      print('Lỗi đăng xuất: $e');
      throw Exception('Đăng xuất thất bại: $e');
    }
  }

  // Lấy thông tin user hiện tại
  User? get currentUser => _auth.currentUser;

  // Stream để lắng nghe thay đổi trạng thái đăng nhập
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Kiểm tra xem user đã đăng nhập chưa
  bool get isSignedIn => _auth.currentUser != null;
}
