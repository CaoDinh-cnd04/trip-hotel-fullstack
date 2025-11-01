import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../../core/services/language_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../data/services/hotel_manager_service.dart';
import 'profile_management_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  String _selectedCurrency = 'VND';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          l10n.settings,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
      ),
      body: ListView(
        children: [
          _buildSectionHeader('Tài khoản'),
          _buildAccountSection(),
          const SizedBox(height: 24),
          _buildSectionHeader('Thông báo'),
          _buildNotificationSection(),
          const SizedBox(height: 24),
          _buildSectionHeader('Giao diện'),
          _buildAppearanceSection(),
          const SizedBox(height: 24),
          _buildSectionHeader('Hệ thống'),
          _buildSystemSection(),
          const SizedBox(height: 24),
          _buildSectionHeader('Hỗ trợ'),
          _buildSupportSection(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
      ),
    );
  }

  Widget _buildAccountSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ListTile(
            leading: const CircleAvatar(
              backgroundImage: NetworkImage('https://via.placeholder.com/150'),
            ),
            title: const Text(
              'Nguyễn Văn A',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('Quản lý khách sạn'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileManagementScreen(
                    hotelManagerService: HotelManagerService(Dio()),
                  ),
                ),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Bảo mật'),
            subtitle: const Text('Mật khẩu, xác thực 2 yếu tố'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chức năng bảo mật sẽ được triển khai')),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
            onTap: () {
              _showLogoutConfirmation();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Thông báo đặt phòng'),
            subtitle: const Text('Nhận thông báo khi có đặt phòng mới'),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Cài đặt thông báo'),
            subtitle: const Text('Tùy chỉnh loại thông báo'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chức năng cài đặt thông báo sẽ được triển khai')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Chế độ tối'),
            subtitle: const Text('Giao diện tối cho mắt'),
            value: _darkModeEnabled,
            onChanged: (value) {
              setState(() {
                _darkModeEnabled = value;
              });
            },
          ),
          const Divider(height: 1),
          Consumer<LanguageService>(
            builder: (context, languageService, child) {
              final l10n = AppLocalizations.of(context)!;
              return ListTile(
                leading: const Icon(Icons.language),
                title: Text(l10n.language),
                subtitle: Text(languageService.currentLanguageDisplayName),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showLanguageDialog();
                },
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: const Text('Đơn vị tiền tệ'),
            subtitle: Text(_getCurrencyName(_selectedCurrency)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showCurrencyDialog();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSystemSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.storage),
            title: const Text('Dung lượng lưu trữ'),
            subtitle: const Text('Đã sử dụng 2.5 GB / 10 GB'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chức năng quản lý lưu trữ sẽ được triển khai')),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.update),
            title: const Text('Cập nhật ứng dụng'),
            subtitle: const Text('Phiên bản 1.0.0'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã là phiên bản mới nhất')),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('Sao lưu dữ liệu'),
            subtitle: const Text('Sao lưu tự động hàng ngày'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chức năng sao lưu sẽ được triển khai')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Trung tâm trợ giúp'),
            subtitle: const Text('Hướng dẫn sử dụng'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chức năng trợ giúp sẽ được triển khai')),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.contact_support),
            title: const Text('Liên hệ hỗ trợ'),
            subtitle: const Text('hotline@hotel.com'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chức năng liên hệ sẽ được triển khai')),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Về ứng dụng'),
            subtitle: const Text('Phiên bản 1.0.0'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showAboutDialog();
            },
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement logout logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chức năng đăng xuất sẽ được triển khai')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.chooseLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text(l10n.vietnamese),
              value: 'vi',
              groupValue: languageService.currentLanguageCode,
              onChanged: (value) async {
                await languageService.changeLanguage(value!);
                if (mounted) {
                  Navigator.pop(context);
                  // Đợi UI rebuild với ngôn ngữ mới
                  await Future.delayed(const Duration(milliseconds: 100));
                  final newL10n = AppLocalizations.of(context)!;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(newL10n.languageChanged),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
            RadioListTile<String>(
              title: Text(l10n.english),
              value: 'en',
              groupValue: languageService.currentLanguageCode,
              onChanged: (value) async {
                await languageService.changeLanguage(value!);
                if (mounted) {
                  Navigator.pop(context);
                  // Đợi UI rebuild với ngôn ngữ mới
                  await Future.delayed(const Duration(milliseconds: 100));
                  final newL10n = AppLocalizations.of(context)!;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(newL10n.languageChanged),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCurrencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chọn đơn vị tiền tệ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Việt Nam Đồng (VNĐ)'),
              value: 'VND',
              groupValue: _selectedCurrency,
              onChanged: (value) {
                setState(() {
                  _selectedCurrency = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('US Dollar (USD)'),
              value: 'USD',
              groupValue: _selectedCurrency,
              onChanged: (value) {
                setState(() {
                  _selectedCurrency = value!;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Hotel Manager',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.hotel, size: 48),
      children: [
        const Text('Ứng dụng quản lý khách sạn chuyên nghiệp'),
        const SizedBox(height: 16),
        const Text('Phát triển bởi: Hotel Management Team'),
        const Text('Email: support@hotel.com'),
        const Text('Hotline: 1900-xxxx'),
      ],
    );
  }

  String _getCurrencyName(String code) {
    switch (code) {
      case 'VND':
        return 'Việt Nam Đồng (VNĐ)';
      case 'USD':
        return 'US Dollar (USD)';
      default:
        return 'Việt Nam Đồng (VNĐ)';
    }
  }
}
