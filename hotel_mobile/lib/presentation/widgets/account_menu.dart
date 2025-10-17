import 'package:flutter/material.dart';
import 'package:hotel_mobile/data/services/auth_service.dart';
import '../screens/profile/my_vouchers_screen.dart';
import '../screens/profile/personal_info_screen.dart';
import '../screens/profile/favorites_screen.dart';
import '../screens/profile/search_history_screen.dart';
import '../screens/profile/security_screen.dart';
import '../screens/profile/notifications_screen.dart';
import '../screens/profile/payment_management_screen.dart';
import '../screens/profile/booking_history_screen.dart';

class AccountMenu extends StatelessWidget {
  final AuthService authService;
  final VoidCallback onLogout;

  const AccountMenu({
    super.key,
    required this.authService,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Bookings Section
        _buildSectionHeader('Đặt phòng'),
        _buildMenuItem(
          icon: Icons.hotel,
          title: 'Lịch sử đặt phòng',
          subtitle: 'Xem các đặt phòng đã thực hiện',
          onTap: () => _navigateToBookingHistory(context),
        ),

        const SizedBox(height: 24),

        // Personal Section
        _buildSectionHeader('Cá nhân'),
        _buildMenuItem(
          icon: Icons.person_outline,
          title: 'Thông tin cá nhân',
          subtitle: 'Chỉnh sửa thông tin và ảnh đại diện',
          onTap: () => _navigateToPersonalInfo(context),
        ),
        _buildMenuItem(
          icon: Icons.history,
          title: 'Lịch sử tìm kiếm',
          subtitle: 'Xem các tìm kiếm gần đây',
          onTap: () => _navigateToSearchHistory(context),
        ),
        _buildMenuItem(
          icon: Icons.favorite_outline,
          title: 'Danh sách yêu thích',
          subtitle: 'Khách sạn đã lưu',
          onTap: () => _navigateToFavorites(context),
        ),

        const SizedBox(height: 24),

        // Payment Section
        _buildSectionHeader('Thanh toán'),
        _buildMenuItem(
          icon: Icons.payment,
          title: 'Quản lý thanh toán',
          subtitle: 'Thẻ tín dụng và phương thức thanh toán',
          onTap: () => _navigateToPaymentManagement(context),
        ),
        _buildMenuItem(
          icon: Icons.local_offer,
          title: 'Mã giảm giá của tôi',
          subtitle: 'Xem và quản lý mã khuyến mãi',
          onTap: () => _navigateToMyVouchers(context),
        ),
        _buildMenuItem(
          icon: Icons.receipt_long,
          title: 'Lịch sử giao dịch',
          subtitle: 'Xem các giao dịch đã thực hiện',
          onTap: () => _showComingSoon(context),
        ),

        const SizedBox(height: 24),

        // Support Section
        _buildSectionHeader('Hỗ trợ'),
        _buildMenuItem(
          icon: Icons.help_outline,
          title: 'Trung tâm hỗ trợ',
          subtitle: 'FAQ và liên hệ hỗ trợ',
          onTap: () => _showComingSoon(context),
        ),
        _buildMenuItem(
          icon: Icons.chat_bubble_outline,
          title: 'Phản hồi',
          subtitle: 'Gửi ý kiến và đánh giá',
          onTap: () => _showComingSoon(context),
        ),
        _buildMenuItem(
          icon: Icons.info_outline,
          title: 'Về ứng dụng',
          subtitle: 'Phiên bản và thông tin ứng dụng',
          onTap: () => _showAboutDialog(context),
        ),

        const SizedBox(height: 24),

        // Settings Section
        _buildSectionHeader('Cài đặt'),
        _buildMenuItem(
          icon: Icons.notifications,
          title: 'Thông báo',
          subtitle: 'Cài đặt thông báo và email',
          onTap: () => _navigateToNotifications(context),
        ),
        _buildMenuItem(
          icon: Icons.language,
          title: 'Ngôn ngữ',
          subtitle: 'Tiếng Việt',
          onTap: () => _showLanguageDialog(context),
        ),
        _buildMenuItem(
          icon: Icons.security,
          title: 'Bảo mật',
          subtitle: 'Đổi mật khẩu và bảo mật tài khoản',
          onTap: () => _navigateToSecurity(context),
        ),

        const SizedBox(height: 32),

        // Logout Button
        _buildLogoutButton(context),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: (textColor ?? const Color(0xFF2196F3)).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: textColor ?? const Color(0xFF2196F3),
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: textColor ?? Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[400],
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.logout, color: Colors.red, size: 24),
        ),
        title: const Text(
          'Đăng xuất',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.red,
          ),
        ),
        subtitle: const Text(
          'Đăng xuất khỏi tài khoản hiện tại',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        onTap: () => _showLogoutConfirmation(context),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sắp ra mắt'),
        content: const Text('Tính năng này đang được phát triển và sẽ có sớm!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Hotel Booking App',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2196F3), Color(0xFF42A5F5)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.hotel, color: Colors.white, size: 30),
      ),
      children: [
        const Text(
          'Ứng dụng đặt phòng khách sạn hàng đầu Việt Nam. '
          'Tìm và đặt phòng dễ dàng với hàng ngàn lựa chọn khách sạn.',
        ),
      ],
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    // Lấy thông tin provider hiện tại
    final providers = authService.getCurrentProviders();
    final providerText = providers.isNotEmpty
        ? 'Bạn đang đăng nhập bằng ${providers.join(", ")}.\n\nBạn có chắc chắn muốn đăng xuất?'
        : 'Bạn có chắc chắn muốn đăng xuất?';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: Text(providerText),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();

              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) =>
                    const Center(child: CircularProgressIndicator()),
              );

              await authService.signOut();

              // Close loading
              Navigator.of(context).pop();

              final successMessage = providers.isNotEmpty
                  ? 'Đã đăng xuất thành công khỏi ${providers.join(", ")}'
                  : 'Đã đăng xuất thành công';

              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(successMessage)));

              onLogout();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  void _navigateToMyVouchers(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MyVouchersScreen()),
    );
  }

  void _navigateToPersonalInfo(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PersonalInfoScreen()),
    );
  }

  void _navigateToFavorites(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FavoritesScreen()),
    );
  }

  void _navigateToSearchHistory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SearchHistoryScreen()),
    );
  }

  void _navigateToSecurity(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SecurityScreen()),
    );
  }

  void _navigateToNotifications(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationsScreen()),
    );
  }

  void _navigateToPaymentManagement(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PaymentManagementScreen()),
    );
  }

  void _navigateToBookingHistory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BookingHistoryScreen()),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chọn ngôn ngữ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Tiếng Việt'),
              subtitle: const Text('Vietnamese'),
              value: 'vi',
              groupValue: 'vi',
              onChanged: (value) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã chọn Tiếng Việt')),
                );
              },
            ),
            RadioListTile<String>(
              title: const Text('English'),
              subtitle: const Text('English'),
              value: 'en',
              groupValue: 'vi',
              onChanged: (value) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('English selected')),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );
  }
}
