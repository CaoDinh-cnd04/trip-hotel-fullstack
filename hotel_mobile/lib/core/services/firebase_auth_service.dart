import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

/// Service xử lý xác thực Firebase (Google, Facebook, Email/Password)
/// 
/// Chức năng:
/// - Đăng nhập bằng Google với Firebase
/// - Đăng nhập bằng Facebook với Firebase
/// - Đăng nhập bằng Email/Password với Firebase
/// - Đăng xuất
/// - Gửi và xác thực OTP
/// - Refresh token
/// - Stream theo dõi thay đổi trạng thái đăng nhập
/// 
/// Singleton pattern - chỉ có 1 instance duy nhất
/// 
/// Lưu ý: Service này làm việc với Firebase Auth
/// - Khác với BackendAuthService (làm việc với Backend API trực tiếp)
/// - Dùng cho Social Login (Google, Facebook) và Email/Password với Firebase
class FirebaseAuthService {
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  factory FirebaseAuthService() => _instance;
  FirebaseAuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

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

  /// Đăng nhập bằng Google với Firebase
  /// 
  /// Quy trình:
  /// 1. Sign out Google cũ để hiện account picker
  /// 2. User chọn tài khoản Google
  /// 3. Lấy Google auth tokens (accessToken, idToken)
  /// 4. Tạo Firebase credential và đăng nhập Firebase
  /// 5. Xử lý lỗi nếu có (account-exists-with-different-credential, PigeonUserDetails)
  /// 
  /// Returns: FirebaseAuthResult với:
  /// - success: User object nếu thành công
  /// - error: Error message nếu thất bại
  /// - cancelled: true nếu user hủy đăng nhập
  Future<FirebaseAuthResult> signInWithGoogle() async {
    try {
      print('🚀 Bắt đầu đăng nhập Google với Firebase...');

      // Sign out để clear session và hiện account picker
      try {
        await _googleSignIn.signOut();
        print('✅ Đã clear Google Sign-In session - sẽ hiển thị account picker');
      } catch (e) {
        print('⚠️ Google Sign out failed (có thể chưa đăng nhập): $e');
      }

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
      UserCredential userCredential;
      try {
        userCredential = await _auth.signInWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        print('� Firebase Auth Exception: ${e.code}');

        if (e.code == 'account-exists-with-different-credential') {
          // Account already exists with different credential
          print('⚠️ Account đã tồn tại với credential khác');

          if (e.email != null) {
            final List<String> signInMethods = await _auth
                .fetchSignInMethodsForEmail(e.email!);

            print('📧 Email: ${e.email}');
            print('🔗 Existing sign-in methods: $signInMethods');

            return FirebaseAuthResult.error(
              'Tài khoản với email ${e.email} đã tồn tại.\n'
              'Hãy đăng nhập bằng: ${signInMethods.join(", ")}',
            );
          }

          return FirebaseAuthResult.error(
            'Tài khoản đã tồn tại với phương thức đăng nhập khác.',
          );
        }

        return FirebaseAuthResult.error('Lỗi Firebase: ${e.message}');
      } catch (firebaseError) {
        print('💥 Lỗi Firebase credential: $firebaseError');

        // Handle PigeonUserDetails error
        if (firebaseError.toString().contains('PigeonUserDetails')) {
          print('🐦 Lỗi PigeonUserDetails - checking if auth succeeded...');

          // Wait a moment for auth state to update
          await Future.delayed(const Duration(milliseconds: 500));

          final User? currentUser = _auth.currentUser;
          if (currentUser != null) {
            print(
              '✅ Authentication thành công despite PigeonUserDetails error',
            );
            print('👤 User: ${currentUser.displayName}');
            print('📧 Email: ${currentUser.email}');
            print('🆔 UID: ${currentUser.uid}');

            return FirebaseAuthResult.success(currentUser);
          } else {
            print('❌ No current user found');
            return FirebaseAuthResult.error(
              'Lỗi kết nối Google. Hãy thử lại sau.',
            );
          }
        }

        return FirebaseAuthResult.error('Lỗi Firebase: $firebaseError');
      }

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

  /// Đăng nhập bằng Facebook với Firebase
  /// 
  /// Quy trình:
  /// 1. Trigger Facebook authentication flow với permissions (email, public_profile)
  /// 2. Lấy access token từ Facebook
  /// 3. Tạo Firebase credential từ Facebook token
  /// 4. Đăng nhập Firebase với credential
  /// 5. Xử lý lỗi nếu có (account-exists-with-different-credential)
  /// 
  /// Xử lý lỗi đặc biệt:
  /// - account-exists-with-different-credential: Thử link credential hoặc hướng dẫn user
  /// - PigeonUserDetails: Xử lý lỗi kết nối
  /// 
  /// Returns: FirebaseAuthResult với:
  /// - success: User object nếu thành công
  /// - error: Error message nếu thất bại
  /// - cancelled: true nếu user hủy đăng nhập
  Future<FirebaseAuthResult> signInWithFacebook() async {
    try {
      print('🚀 Bắt đầu đăng nhập Facebook với Firebase...');

      // Trigger Facebook authentication flow
      final LoginResult loginResult = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (loginResult.status == LoginStatus.cancelled) {
        print('❌ User đã hủy đăng nhập Facebook');
        return FirebaseAuthResult.cancelled();
      }

      if (loginResult.status == LoginStatus.success) {
        print('✅ Facebook Sign-In thành công');

        // Create a credential from the access token
        final OAuthCredential facebookAuthCredential =
            FacebookAuthProvider.credential(loginResult.accessToken!.token);

        print('🔐 Đã tạo Firebase credential từ Facebook token');

        try {
          // Sign in to Firebase with Facebook credential
          final UserCredential userCredential = await _auth
              .signInWithCredential(facebookAuthCredential);

          final User? user = userCredential.user;

          if (user != null) {
            print('🎉 Firebase đăng nhập Facebook thành công!');
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
        } on FirebaseAuthException catch (e) {
          print('🔥 Firebase Auth Exception: ${e.code}');

          if (e.code == 'account-exists-with-different-credential') {
            // Account already exists with different credential
            print('⚠️ Account đã tồn tại với credential khác');

            // Thử link credential nếu người dùng đăng nhập bằng phương thức cũ
            if (e.email != null) {
              final List<String> methods =
                  await _auth.fetchSignInMethodsForEmail(e.email!);

              print('📧 Email: ${e.email}');
              print('🔗 Existing sign-in methods: $methods');

              // Nếu là password: yêu cầu người dùng đăng nhập email trước, sau đó link
              if (methods.contains('password')) {
                return FirebaseAuthResult.error(
                  'Email ${e.email} đã đăng ký bằng Email/Password.\n'
                  'Hãy đăng nhập bằng Email, sau đó vào hồ sơ để liên kết Facebook.',
                );
              }

              // Nếu là Google: thử đăng nhập Google rồi link Facebook
              if (methods.contains('google.com')) {
                try {
                  final googleProvider = GoogleAuthProvider();
                  final googleCred = await _auth.signInWithProvider(googleProvider);
                  if (googleCred.user != null) {
                    await googleCred.user!.linkWithCredential(facebookAuthCredential);
                    return FirebaseAuthResult.success(googleCred.user!);
                  }
                } catch (linkErr) {
                  print('❌ Link Facebook->Google thất bại: $linkErr');
                }
                return FirebaseAuthResult.error(
                  'Email đã đăng ký bằng Google. Hãy đăng nhập Google rồi liên kết Facebook.',
                );
              }

              // Trường hợp khác: trả về hướng dẫn chung
              return FirebaseAuthResult.error(
                'Email đã tồn tại với phương thức khác: ${methods.join(', ')}.',
              );
            }

            return FirebaseAuthResult.error('Tài khoản đã tồn tại với phương thức khác.');
          }

          return FirebaseAuthResult.error('Lỗi Firebase: ${e.message}');
        }
      } else {
        print('❌ Facebook login thất bại: ${loginResult.message}');
        return FirebaseAuthResult.error(
          'Đăng nhập Facebook thất bại: ${loginResult.message}',
        );
      }
    } catch (error) {
      print('💥 Lỗi đăng nhập Facebook: $error');

      // Handle specific PigeonUserDetails error
      if (error.toString().contains('PigeonUserDetails')) {
        print('🐦 Lỗi PigeonUserDetails - thử lại với cách khác');
        return FirebaseAuthResult.error(
          'Lỗi kết nối Facebook. Hãy thử lại sau.',
        );
      }

      return FirebaseAuthResult.error('Lỗi đăng nhập Facebook: $error');
    }
  }

  /// Đăng nhập bằng email và password với Firebase
  /// 
  /// [email] - Email của user
  /// [password] - Mật khẩu của user
  /// 
  /// Xử lý lỗi:
  /// - user-not-found: Không tìm thấy tài khoản
  /// - wrong-password: Mật khẩu không chính xác
  /// - invalid-email: Email không hợp lệ
  /// - user-disabled: Tài khoản bị vô hiệu hóa
  /// 
  /// Returns: FirebaseAuthResult với user nếu thành công, error message nếu thất bại
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

  /// Đăng ký tài khoản mới với email và password
  /// 
  /// [email] - Email của user
  /// [password] - Mật khẩu của user
  /// [displayName] - Tên hiển thị của user
  /// 
  /// Quy trình:
  /// 1. Tạo user mới với email/password
  /// 2. Cập nhật display name
  /// 3. Reload user để lấy thông tin mới nhất
  /// 
  /// Xử lý lỗi:
  /// - weak-password: Mật khẩu quá yếu
  /// - email-already-in-use: Email đã được sử dụng
  /// - invalid-email: Email không hợp lệ
  /// 
  /// Returns: FirebaseAuthResult với user nếu thành công, error message nếu thất bại
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

  /// Đăng xuất khỏi Firebase và tất cả các provider (Google, Facebook)
  /// 
  /// Quy trình tối ưu:
  /// 1. Đăng xuất Firebase trước (quan trọng nhất)
  /// 2. Đăng xuất các provider khác song song với timeout (3 giây)
  ///    - Google Sign-In logout
  ///    - Facebook logout
  /// 3. Tiếp tục ngay cả khi một số provider logout timeout (không chặn)
  /// 
  /// Lưu ý: Các provider logout có timeout để tránh chặn UI quá lâu
  Future<void> signOut() async {
    try {
      print('🚪 Đăng xuất...');

      // Lấy thông tin user hiện tại để biết đang dùng provider nào
      final User? currentUser = _auth.currentUser;
      List<String> activeProviders = [];

      if (currentUser != null) {
        // Check which providers are currently linked
        for (final providerData in currentUser.providerData) {
          switch (providerData.providerId) {
            case 'google.com':
              activeProviders.add('Google');
              break;
            case 'facebook.com':
              activeProviders.add('Facebook');
              break;
            case 'password':
              activeProviders.add('Email/Password');
              break;
            default:
              activeProviders.add(providerData.providerId);
          }
        }

        if (activeProviders.isNotEmpty) {
          print('👤 Đang đăng xuất khỏi: ${activeProviders.join(", ")}');
        }
      }

      // Đăng xuất Firebase trước (quan trọng nhất)
      await _auth.signOut();
      print('✅ Đã đăng xuất khỏi Firebase');

      // Đăng xuất các provider khác song song với timeout
      final List<Future<void>> logoutTasks = [];

      // Google logout với timeout
      logoutTasks.add(
        _googleSignIn.isSignedIn().then((isSignedIn) async {
          if (isSignedIn) {
            await _googleSignIn.signOut();
            print('✅ Đã đăng xuất Google');
          }
        }).timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            print('⚠️ Google logout timeout, continuing...');
          },
        ),
      );

      // Facebook logout với timeout
      logoutTasks.add(
        FacebookAuth.instance.logOut().then((_) {
          print('✅ Đã đăng xuất Facebook');
        }).timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            print('⚠️ Facebook logout timeout, continuing...');
          },
        ).catchError((fbError) {
          print('⚠️ Lỗi đăng xuất Facebook: $fbError');
        }),
      );

      // Chờ tất cả các task hoàn thành (hoặc timeout)
      await Future.wait(logoutTasks);

      if (activeProviders.isNotEmpty) {
        print('🎉 Đăng xuất thành công khỏi ${activeProviders.join(", ")}');
      }
    } catch (e) {
      print('❌ Lỗi đăng xuất: $e');
      // Vẫn tiếp tục ngay cả khi có lỗi
    }
  }

  /// Kiểm tra xem user đã đăng nhập chưa
  /// 
  /// Trả về true nếu có currentUser, false nếu không
  bool get isSignedIn => _auth.currentUser != null;

  /// Lấy danh sách các provider hiện tại mà user đang sử dụng
  /// 
  /// Trả về danh sách tên provider: ["Google", "Facebook", "Email/Password"]
  /// Trả về [] nếu chưa đăng nhập
  List<String> getCurrentProviders() {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return [];

    List<String> providers = [];
    for (final providerData in currentUser.providerData) {
      switch (providerData.providerId) {
        case 'google.com':
          providers.add('Google');
          break;
        case 'facebook.com':
          providers.add('Facebook');
          break;
        case 'password':
          providers.add('Email/Password');
          break;
        default:
          providers.add(providerData.providerId);
      }
    }
    return providers;
  }

  /// Lấy tên provider chính (provider đầu tiên mà user sử dụng để đăng nhập)
  /// 
  /// Trả về tên provider: "Google", "Facebook", hoặc "Email/Password"
  /// Trả về null nếu chưa đăng nhập
  String? getPrimaryProvider() {
    final providers = getCurrentProviders();
    return providers.isNotEmpty ? providers.first : null;
  }

  /// Lấy Firebase ID Token (dùng để gửi lên backend xác thực)
  /// 
  /// Token này có thể được gửi lên backend để verify user identity
  /// 
  /// Returns: ID token nếu có user, null nếu chưa đăng nhập hoặc có lỗi
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

  /// Làm mới (refresh) Firebase ID Token
  /// 
  /// Force refresh token ngay cả khi token chưa hết hạn
  /// Dùng khi token bị reject bởi backend hoặc cần token mới nhất
  /// 
  /// Returns: ID token mới nếu thành công, null nếu có lỗi
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

/// Model đại diện cho kết quả của Firebase Authentication
/// 
/// Chứa thông tin:
/// - isSuccess: Trạng thái thành công/thất bại
/// - user: Firebase User object (nếu thành công)
/// - error: Error message (nếu thất bại)
/// - isCancelled: true nếu user hủy đăng nhập
/// 
/// Các factory methods:
/// - success(): Tạo result thành công với User
/// - error(): Tạo result lỗi với message
/// - cancelled(): Tạo result khi user hủy
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

  /// Tạo FirebaseAuthResult thành công với User
  /// 
  /// [user] - Firebase User object
  factory FirebaseAuthResult.success(User user) {
    return FirebaseAuthResult._(isSuccess: true, user: user);
  }

  /// Tạo FirebaseAuthResult lỗi với error message
  /// 
  /// [error] - Thông báo lỗi
  factory FirebaseAuthResult.error(String error) {
    return FirebaseAuthResult._(isSuccess: false, error: error);
  }

  /// Tạo FirebaseAuthResult khi user hủy đăng nhập
  factory FirebaseAuthResult.cancelled() {
    return FirebaseAuthResult._(isSuccess: false, isCancelled: true);
  }

  /// Lấy email của user (tiện ích)
  String? get email => user?.email;
  
  /// Lấy tên hiển thị của user (tiện ích)
  String? get displayName => user?.displayName;
  
  /// Lấy URL avatar của user (tiện ích)
  String? get photoURL => user?.photoURL;
  
  /// Lấy UID của user (tiện ích)
  String? get uid => user?.uid;
}
