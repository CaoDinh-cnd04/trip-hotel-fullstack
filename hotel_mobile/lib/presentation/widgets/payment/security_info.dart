import 'package:flutter/material.dart';

class SecurityInfo extends StatelessWidget {
  const SecurityInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.grey[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security, color: Colors.green[600], size: 24),
                const SizedBox(width: 8),
                Text(
                  'Bảo mật & An toàn',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // SSL Encryption
            _buildSecurityFeature(
              icon: Icons.lock,
              iconColor: Colors.green[600]!,
              title: 'Mã hóa SSL 256-bit',
              description:
                  'Thông tin thanh toán được bảo vệ với công nghệ mã hóa hàng đầu',
            ),

            const SizedBox(height: 12),

            // PCI DSS Compliant
            _buildSecurityFeature(
              icon: Icons.verified_user,
              iconColor: Colors.blue[600]!,
              title: 'Tuân thủ tiêu chuẩn PCI DSS',
              description:
                  'Đảm bảo an toàn dữ liệu thẻ tín dụng theo chuẩn quốc tế',
            ),

            const SizedBox(height: 12),

            // 24/7 Monitoring
            _buildSecurityFeature(
              icon: Icons.monitor_heart,
              iconColor: Colors.orange[600]!,
              title: 'Giám sát 24/7',
              description:
                  'Hệ thống được giám sát liên tục để phát hiện gian lận',
            ),

            const SizedBox(height: 12),

            // Data Protection
            _buildSecurityFeature(
              icon: Icons.privacy_tip,
              iconColor: Colors.purple[600]!,
              title: 'Bảo vệ dữ liệu cá nhân',
              description: 'Thông tin cá nhân được bảo mật tuyệt đối theo GDPR',
            ),

            const SizedBox(height: 20),

            // Trust badges
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        color: Colors.green[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Được tin tưởng bởi hơn 1 triệu khách hàng',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildTrustBadge('SSL', Colors.green),
                      _buildTrustBadge('PCI DSS', Colors.blue),
                      _buildTrustBadge('ISO 27001', Colors.orange),
                      _buildTrustBadge('GDPR', Colors.purple),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Contact support
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.support_agent, color: Colors.blue[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cần hỗ trợ?',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[700],
                          ),
                        ),
                        Text(
                          'Liên hệ hotline 1900-xxx-xxx (24/7)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.phone, color: Colors.blue[600], size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityFeature({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrustBadge(String text, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color[300]!),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color[700],
        ),
      ),
    );
  }
}
