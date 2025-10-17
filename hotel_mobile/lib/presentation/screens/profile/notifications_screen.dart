import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _bookingNotifications = true;
  bool _promotionNotifications = true;
  bool _emailMarketing = false;
  bool _pushNotifications = true;
  bool _smsNotifications = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Cài đặt thông báo',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Push Notifications Section
          _buildSectionCard(
            title: 'Thông báo đẩy',
            icon: Icons.notifications,
            children: [
              _buildSwitchTile(
                title: 'Thông báo đặt phòng',
                subtitle: 'Nhận thông báo về trạng thái đặt phòng',
                value: _bookingNotifications,
                onChanged: (value) {
                  setState(() {
                    _bookingNotifications = value;
                  });
                },
              ),
              _buildSwitchTile(
                title: 'Khuyến mãi và ưu đãi',
                subtitle: 'Nhận thông báo về ưu đãi mới',
                value: _promotionNotifications,
                onChanged: (value) {
                  setState(() {
                    _promotionNotifications = value;
                  });
                },
              ),
              _buildSwitchTile(
                title: 'Thông báo chung',
                subtitle: 'Nhận thông báo về dịch vụ và cập nhật',
                value: _pushNotifications,
                onChanged: (value) {
                  setState(() {
                    _pushNotifications = value;
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Email Notifications Section
          _buildSectionCard(
            title: 'Thông báo email',
            icon: Icons.email,
            children: [
              _buildSwitchTile(
                title: 'Email marketing',
                subtitle: 'Nhận email về dịch vụ và ưu đãi',
                value: _emailMarketing,
                onChanged: (value) {
                  setState(() {
                    _emailMarketing = value;
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // SMS Notifications Section
          _buildSectionCard(
            title: 'Thông báo SMS',
            icon: Icons.sms,
            children: [
              _buildSwitchTile(
                title: 'SMS quan trọng',
                subtitle: 'Nhận SMS cho các thông báo quan trọng',
                value: _smsNotifications,
                onChanged: (value) {
                  setState(() {
                    _smsNotifications = value;
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Lưu cài đặt',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF2196F3),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 13,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF2196F3),
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  void _saveSettings() {
    // In a real app, you would save these settings to local storage or backend
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã lưu cài đặt thông báo'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.of(context).pop();
  }
}
