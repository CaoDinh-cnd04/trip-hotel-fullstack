import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../l10n/app_localizations.dart';

/// Màn hình Về chúng tôi
/// 
/// Hiển thị thông tin về ứng dụng Hotel Booking bao gồm:
/// - Logo và mô tả ngắn gọn
/// - Sứ mệnh và tầm nhìn của công ty
/// - Thông tin liên hệ (email, phone, địa chỉ)
/// - Phiên bản ứng dụng hiện tại
class AboutUsScreen extends StatefulWidget {
  const AboutUsScreen({Key? key}) : super(key: key);

  @override
  State<AboutUsScreen> createState() => _AboutUsScreenState();
}

class _AboutUsScreenState extends State<AboutUsScreen> {
  /// Phiên bản app (format: version+buildNumber)
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  /// Tải thông tin phiên bản ứng dụng từ package info
  /// 
  /// Sử dụng package_info_plus để lấy version và build number
  /// Nếu không lấy được thì mặc định là '1.0.0'
  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _version = '${packageInfo.version} (${packageInfo.buildNumber})';
      });
    } catch (e) {
      setState(() {
        _version = '1.0.0';
      });
    }
  }

  /// Xây dựng giao diện màn hình Về chúng tôi
  /// 
  /// Bao gồm:
  /// - AppBar với tiêu đề
  /// - Header gradient với logo
  /// - Các card thông tin (Mission, Vision, Contact)
  /// - Thông tin phiên bản
  /// - Footer copyright
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(l10n.aboutUsTitle),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header với logo
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.8),
                  ],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.hotel,
                      size: 60,
                      color: Color(0xFF2196F3),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Hotel Booking',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.aboutUsDescription,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Mission
                  _buildInfoCard(
                    icon: Icons.flag,
                    title: l10n.ourMission,
                    content: l10n.ourMissionText,
                    color: Colors.blue,
                  ),

                  const SizedBox(height: 16),

                  // Vision
                  _buildInfoCard(
                    icon: Icons.visibility,
                    title: l10n.ourVision,
                    content: l10n.ourVisionText,
                    color: Colors.green,
                  ),

                  const SizedBox(height: 16),

                  // Contact Info
                  _buildContactCard(l10n),

                  const SizedBox(height: 16),

                  // Version Info
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.version,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            _version,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Footer
                  Text(
                    '© 2024 Hotel Booking\nAll rights reserved',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tạo card thông tin với icon và nội dung
  /// 
  /// Parameters:
  /// - [icon]: Icon hiển thị bên trái
  /// - [title]: Tiêu đề card
  /// - [content]: Nội dung mô tả
  /// - [color]: Màu chủ đạo cho icon
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tạo card hiển thị thông tin liên hệ
  /// 
  /// Hiển thị:
  /// - Email hỗ trợ
  /// - Số điện thoại hotline
  /// - Địa chỉ văn phòng
  /// 
  /// Parameters:
  /// - [l10n]: Đối tượng localization để lấy text đa ngôn ngữ
  Widget _buildContactCard(AppLocalizations l10n) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.contact_mail,
                    color: Colors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.contactInfo,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildContactItem(
              icon: Icons.email,
              label: l10n.emailAddress,
              value: 'support@hotelbooking.vn',
            ),
            const Divider(height: 24),
            _buildContactItem(
              icon: Icons.phone,
              label: l10n.phoneContact,
              value: '1900-xxxx',
            ),
            const Divider(height: 24),
            _buildContactItem(
              icon: Icons.location_on,
              label: l10n.address,
              value: 'Hà Nội, Việt Nam',
            ),
          ],
        ),
      ),
    );
  }

  /// Tạo một dòng thông tin liên hệ
  /// 
  /// Parameters:
  /// - [icon]: Icon đại diện (email, phone, location)
  /// - [label]: Nhãn mô tả (Email, Phone, Address)
  /// - [value]: Giá trị thực tế
  Widget _buildContactItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

