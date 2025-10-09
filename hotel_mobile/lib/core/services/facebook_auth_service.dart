import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class FacebookAuthResult {
  final bool isSuccess;
  final bool isCancelled;
  final String? error;
  final String? userId;
  final String? email;
  final String? name;
  final String? photoUrl;
  final String? accessToken;

  FacebookAuthResult({
    required this.isSuccess,
    this.isCancelled = false,
    this.error,
    this.userId,
    this.email,
    this.name,
    this.photoUrl,
    this.accessToken,
  });
}

class FacebookAuthService {
  /// Đăng nhập bằng Facebook
  Future<FacebookAuthResult> signInWithFacebook() async {
    try {
      print('🔄 Bắt đầu Facebook Sign-In...');

      // Thực hiện đăng nhập Facebook
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      print('📱 Facebook Login Status: ${result.status}');

      // Xử lý các trường hợp khác nhau
      switch (result.status) {
        case LoginStatus.success:
          // Đăng nhập thành công
          final AccessToken accessToken = result.accessToken!;
          print('✅ Facebook Access Token: ${accessToken.token}');

          // Lấy thông tin user
          final userData = await FacebookAuth.instance.getUserData(
            fields: "id,name,email,picture.width(200).height(200)",
          );

          print('👤 Facebook User Data: $userData');

          return FacebookAuthResult(
            isSuccess: true,
            userId: userData['id'],
            email: userData['email'],
            name: userData['name'],
            photoUrl: userData['picture']?['data']?['url'],
            accessToken: accessToken.token,
          );

        case LoginStatus.cancelled:
          // User hủy đăng nhập
          print('⚠️ Facebook đăng nhập bị hủy');
          return FacebookAuthResult(isSuccess: false, isCancelled: true);

        case LoginStatus.failed:
          // Đăng nhập thất bại
          print('❌ Facebook đăng nhập thất bại: ${result.message}');
          return FacebookAuthResult(
            isSuccess: false,
            error: result.message ?? 'Facebook đăng nhập thất bại',
          );

        default:
          print('❓ Facebook đăng nhập trạng thái không xác định');
          return FacebookAuthResult(
            isSuccess: false,
            error: 'Trạng thái đăng nhập không xác định',
          );
      }
    } catch (e) {
      print('💥 Exception trong Facebook Sign-In: $e');
      return FacebookAuthResult(
        isSuccess: false,
        error: 'Lỗi không xác định: $e',
      );
    }
  }

  /// Đăng xuất Facebook
  Future<void> signOut() async {
    try {
      await FacebookAuth.instance.logOut();
      print('✅ Facebook đăng xuất thành công');
    } catch (e) {
      print('❌ Lỗi khi đăng xuất Facebook: $e');
      throw Exception('Đăng xuất Facebook thất bại: $e');
    }
  }

  /// Kiểm tra trạng thái đăng nhập
  Future<bool> isLoggedIn() async {
    try {
      final AccessToken? accessToken = await FacebookAuth.instance.accessToken;
      return accessToken != null && !accessToken.isExpired;
    } catch (e) {
      print('❌ Lỗi kiểm tra trạng thái Facebook: $e');
      return false;
    }
  }

  /// Lấy access token hiện tại
  Future<String?> getCurrentAccessToken() async {
    try {
      final AccessToken? accessToken = await FacebookAuth.instance.accessToken;
      return accessToken?.token;
    } catch (e) {
      print('❌ Lỗi lấy Facebook access token: $e');
      return null;
    }
  }
}
