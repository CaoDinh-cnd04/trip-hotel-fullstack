import 'package:flutter/material.dart';
import '../../../../data/models/booking.dart';

class VoucherActions extends StatelessWidget {
  final Booking booking;
  final VoidCallback onContactHotel;
  final VoidCallback onDownloadPdf;

  const VoucherActions({
    Key? key,
    required this.booking,
    required this.onContactHotel,
    required this.onDownloadPdf,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              Icon(Icons.support_agent, color: Colors.purple[600], size: 24),
              const SizedBox(width: 12),
              const Text(
                'Hỗ trợ khách hàng',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Contact Hotel Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onContactHotel,
              icon: const Icon(Icons.phone, color: Colors.white, size: 20),
              label: const Text(
                'Liên hệ Khách sạn',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Download PDF Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onDownloadPdf,
              icon: Icon(Icons.download, color: Colors.green[600], size: 20),
              label: Text(
                'Tải Voucher PDF',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[600],
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: Colors.green[600]!, width: 2),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Additional Actions
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  'Thay đổi đặt phòng',
                  'Sửa thông tin',
                  Icons.edit,
                  Colors.orange,
                  () => _showModifyDialog(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  'Hủy đặt phòng',
                  'Hủy booking',
                  Icons.cancel,
                  Colors.red,
                  () => _showCancelDialog(context),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Help & Support
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.help_outline, color: Colors.grey[600], size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Cần hỗ trợ?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Liên hệ hotline 1900-1234 hoặc email support@hotel.com để được hỗ trợ 24/7',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    MaterialColor color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color[200]!),
        ),
        child: Column(
          children: [
            Icon(icon, color: color[600], size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color[700],
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 10, color: color[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showModifyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thay đổi đặt phòng'),
        content: const Text(
          'Chức năng thay đổi thông tin đặt phòng sẽ được cập nhật trong phiên bản tiếp theo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy đặt phòng'),
        content: const Text(
          'Bạn có chắc chắn muốn hủy đặt phòng này? Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Không'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement cancel booking logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Chức năng hủy phòng đang được phát triển'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Có, hủy đặt phòng'),
          ),
        ],
      ),
    );
  }
}
