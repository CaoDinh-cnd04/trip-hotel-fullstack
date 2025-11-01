/**
 * Backend Auth Service
 * 
 * Wrapper service để check authentication status
 * Dùng cho payment và các tính năng cần đăng nhập
 */

import 'local_storage_service.dart';

class BackendAuthService {
  final LocalStorageService _localStorage = LocalStorageService();

  /// Check if user is signed in (synchronous)
  bool get isSignedIn {
    // Tạm thời return false, sẽ dùng isAuthenticated() để check async
    return false;
  }

  /// Get access token
  Future<String?> getToken() async {
    return await _localStorage.getToken();
  }

  /// Check if user is authenticated (async version - recommended)
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}

