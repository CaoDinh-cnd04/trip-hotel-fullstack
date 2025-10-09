import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../core/services/facebook_auth_service.dart';

class FacebookDebugScreen extends StatefulWidget {
  const FacebookDebugScreen({Key? key}) : super(key: key);

  @override
  State<FacebookDebugScreen> createState() => _FacebookDebugScreenState();
}

class _FacebookDebugScreenState extends State<FacebookDebugScreen> {
  final FacebookAuthService _facebookAuthService = FacebookAuthService();
  String _debugInfo = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDebugInfo();
  }

  void _loadDebugInfo() {
    setState(() {
      _debugInfo =
          '''
🔧 DEBUG THÔNG TIN FACEBOOK LOGIN

📱 Platform: ${kIsWeb ? 'Web' : (Theme.of(context).platform.name)}
📦 Package: com.example.hotel_mobile
🆔 Facebook App ID: 1361581552264816
🏷️ App Name: Trip Hotel

📋 CẤU HÌNH CẦN KIỂM TRA:
1. Facebook Developer Console
2. Key Hash (Android)
3. Bundle ID (iOS)
4. Domain (Web)

🌐 Links:
- FB Console: https://developers.facebook.com/apps/1361581552264816/
- Settings: https://developers.facebook.com/apps/1361581552264816/settings/basic/
      ''';
    });
  }

  Future<void> _testFacebookLogin() async {
    setState(() {
      _isLoading = true;
      _debugInfo += '\n\n🔄 Đang test Facebook Login...';
    });

    try {
      final result = await _facebookAuthService.signInWithFacebook();

      setState(() {
        if (result.isSuccess) {
          _debugInfo += '\n\n✅ THÀNH CÔNG!';
          _debugInfo += '\n📧 Email: ${result.email ?? 'Không có'}';
          _debugInfo += '\n👤 Tên: ${result.name ?? 'Không có'}';
          _debugInfo += '\n🆔 ID: ${result.userId ?? 'Không có'}';
          _debugInfo +=
              '\n🔑 Token: ${result.accessToken?.substring(0, 20) ?? 'Không có'}...';
        } else if (result.isCancelled) {
          _debugInfo += '\n\n⚠️ Người dùng hủy đăng nhập';
        } else {
          _debugInfo += '\n\n❌ THẤT BẠI!';
          _debugInfo += '\n💬 Lỗi: ${result.error}';
        }
      });
    } catch (e) {
      setState(() {
        _debugInfo += '\n\n💥 EXCEPTION!';
        _debugInfo += '\n💬 Chi tiết: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    try {
      await _facebookAuthService.signOut();
      setState(() {
        _debugInfo += '\n\n🚪 Đã đăng xuất Facebook';
      });
    } catch (e) {
      setState(() {
        _debugInfo += '\n\n❌ Lỗi đăng xuất: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Facebook Debug'),
        backgroundColor: const Color(0xFF1877F2),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Debug Info
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _debugInfo,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testFacebookLogin,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.facebook),
                    label: Text(
                      _isLoading ? 'Đang test...' : 'Test Facebook Login',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1877F2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _signOut,
                    icon: const Icon(Icons.logout),
                    label: const Text('Đăng xuất'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _debugInfo = '';
                });
                _loadDebugInfo();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Làm mới'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 40),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
