import 'package:flutter/material.dart';
import '../../../data/services/user_profile_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../core/services/firebase_auth_service.dart';

class AccountSecurityScreen extends StatefulWidget {
  const AccountSecurityScreen({super.key});

  @override
  State<AccountSecurityScreen> createState() => _AccountSecurityScreenState();
}

class _AccountSecurityScreenState extends State<AccountSecurityScreen> {
  final UserProfileService _userProfileService = UserProfileService();
  final AuthService _authService = AuthService();
  final FirebaseAuthService _firebaseAuthService = FirebaseAuthService();
  
  bool _isLoading = false;
  String? _error;
  String? _userEmail;
  String? _userPhone;
  bool _emailVerified = false;
  bool _phoneLinked = false;

  @override
  void initState() {
    super.initState();
    _loadUserSecurityInfo();
  }

  Future<void> _loadUserSecurityInfo() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final user = _firebaseAuthService.currentUser;
      if (user != null) {
        setState(() {
          _userEmail = user.email;
          _emailVerified = user.emailVerified;
          _userPhone = user.phoneNumber;
          _phoneLinked = _userPhone != null && _userPhone!.isNotEmpty;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Lỗi tải thông tin bảo mật: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Bảo mật tài khoản'),
        backgroundColor: const Color(0xFF8B4513),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _buildSecurityContent(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadUserSecurityInfo,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B4513),
            ),
            child: const Text(
              'Thử lại',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Security Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bảo mật tài khoản',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Quản lý thông tin bảo mật và xác thực tài khoản của bạn',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Email Section
          _buildSecurityCard(
            title: 'Địa chỉ email đã liên kết',
            icon: Icons.email,
            subtitle: _userEmail ?? 'Chưa có email',
            status: _emailVerified ? 'Đã xác thực' : 'Chưa xác thực',
            statusColor: _emailVerified ? Colors.green : Colors.orange,
            onTap: _emailVerified ? null : _verifyEmail,
            actionText: _emailVerified ? null : 'Xác thực',
          ),
          
          const SizedBox(height: 16),
          
          // Phone Section
          _buildSecurityCard(
            title: 'Liên kết số điện thoại',
            icon: Icons.phone,
            subtitle: _phoneLinked ? (_userPhone ?? 'Số điện thoại') : 'Chưa liên kết số điện thoại',
            status: _phoneLinked ? 'Đã liên kết' : 'Chưa liên kết',
            statusColor: _phoneLinked ? Colors.green : Colors.grey,
            onTap: _phoneLinked ? _unlinkPhone : _linkPhone,
            actionText: _phoneLinked ? 'Hủy liên kết' : 'Liên kết',
          ),
          
          const SizedBox(height: 16),
          
          // Password Section
          _buildSecurityCard(
            title: 'Mật khẩu',
            icon: Icons.lock,
            subtitle: '••••••••••••',
            status: 'Đã thiết lập',
            statusColor: Colors.green,
            onTap: _changePassword,
            actionText: 'Thiết lập lại',
          ),
          
          const SizedBox(height: 24),
          
          // Security Tips
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.security, color: Colors.blue[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Mẹo bảo mật',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSecurityTip('Sử dụng mật khẩu mạnh với ít nhất 8 ký tự'),
                _buildSecurityTip('Không chia sẻ thông tin đăng nhập với người khác'),
                _buildSecurityTip('Đăng xuất khỏi thiết bị công cộng'),
                _buildSecurityTip('Cập nhật thông tin liên hệ thường xuyên'),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Danger Zone
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Vùng nguy hiểm',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Các hành động này không thể hoàn tác. Hãy cẩn thận.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.red[600],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _deleteAccount,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Xóa tài khoản'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard({
    required String title,
    required IconData icon,
    required String subtitle,
    required String status,
    required Color statusColor,
    VoidCallback? onTap,
    String? actionText,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF8B4513),
                size: 24,
              ),
            ),
            
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              statusColor == Colors.green ? Icons.check_circle : Icons.info,
                              size: 14,
                              color: statusColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              status,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            if (actionText != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B4513),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  actionText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ] else ...[
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityTip(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(top: 8, right: 8),
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyEmail() async {
    try {
      await _firebaseAuthService.currentUser?.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email xác thực đã được gửi. Vui lòng kiểm tra hộp thư.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi gửi email xác thực: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _linkPhone() {
    // TODO: Implement phone linking
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tính năng liên kết số điện thoại đang phát triển'),
      ),
    );
  }

  void _unlinkPhone() {
    // TODO: Implement phone unlinking
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tính năng hủy liên kết số điện thoại đang phát triển'),
      ),
    );
  }

  void _changePassword() {
    // TODO: Implement password change
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tính năng đổi mật khẩu đang phát triển'),
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tài khoản'),
        content: const Text(
          'Bạn có chắc chắn muốn xóa tài khoản? Hành động này không thể hoàn tác và tất cả dữ liệu sẽ bị mất vĩnh viễn.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa tài khoản'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final result = await _userProfileService.deleteAccount();
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tài khoản đã được xóa thành công'),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate to login screen
          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message ?? 'Không thể xóa tài khoản'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xóa tài khoản: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
