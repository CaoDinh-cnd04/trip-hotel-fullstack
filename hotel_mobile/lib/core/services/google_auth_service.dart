import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

/// Service xử lý đăng nhập Google với Firebase
/// 
/// Chức năng:
/// - Đăng nhập bằng Google (hỗ trợ cả Web và Mobile)
/// - Đăng xuất Google và Firebase
/// - Lấy thông tin user hiện tại
/// - Stream theo dõi thay đổi trạng thái đăng nhập
/// 
/// Flow đăng nhập:
/// - Web: Sử dụng Firebase signInWithPopup với account picker
/// - Mobile: Sử dụng GoogleSignIn SDK → Lấy tokens → Đăng nhập Firebase
class GoogleAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Đăng nhập bằng Google với Firebase
  /// 
  /// Quy trình:
  /// - Web: Popup Google account picker → Firebase signInWithPopup
  /// - Mobile: GoogleSignIn SDK → Lấy accessToken/idToken → Tạo Firebase credential → Đăng nhập
  /// 
  /// Returns:
  /// - UserCredential nếu thành công
  /// - null nếu user hủy đăng nhập
  /// - Throw Exception nếu có lỗi
  /// 
  /// Xử lý lỗi:
  /// - FirebaseAuthException: Parse và throw với message rõ ràng
  /// - Missing tokens: Throw exception thông báo
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

  /// Đăng xuất khỏi Google và Firebase
  /// 
  /// Thực hiện đăng xuất đồng thời từ:
  /// - Firebase Auth
  /// - Google Sign-In SDK
  /// 
  /// Throws Exception nếu có lỗi trong quá trình đăng xuất
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

  /// Lấy Firebase User hiện tại
  /// 
  /// Trả về User nếu đã đăng nhập, null nếu chưa đăng nhập
  User? get currentUser => _auth.currentUser;

  /// Stream theo dõi thay đổi trạng thái đăng nhập Firebase
  /// 
  /// Emit event khi:
  /// - User đăng nhập thành công
  /// - User đăng xuất
  /// - Token hết hạn
  /// 
  /// Sử dụng để tự động cập nhật UI khi trạng thái đăng nhập thay đổi
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Kiểm tra xem user đã đăng nhập chưa
  /// 
  /// Trả về true nếu có currentUser, false nếu không
  bool get isSignedIn => _auth.currentUser != null;
}
