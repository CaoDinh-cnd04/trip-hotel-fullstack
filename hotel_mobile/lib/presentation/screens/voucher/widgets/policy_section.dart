import 'package:flutter/material.dart';
import '../../../../data/models/booking.dart';

class PolicySection extends StatelessWidget {
  final Booking booking;

  const PolicySection({Key? key, required this.booking}) : super(key: key);

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
              Icon(Icons.policy, color: Colors.orange[600], size: 24),
              const SizedBox(width: 12),
              const Text(
                'Chính sách khách sạn',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Check-in/Check-out Policy
          _buildPolicyCard(
            'Thời gian nhận/trả phòng',
            [
              'Check-in: Từ 14:00',
              'Check-out: Trước 12:00',
              'Nhận phòng sớm/trả phòng muộn có thể tính phí',
            ],
            Icons.schedule,
            Colors.blue,
          ),

          const SizedBox(height: 16),

          // Cancellation Policy
          _buildPolicyCard(
            'Chính sách hủy phòng',
            [
              'Hủy miễn phí: Trước 24h so với ngày nhận phòng',
              'Hủy muộn: Tính phí 100% đêm đầu tiên',
              'No-show: Tính phí toàn bộ kỳ nghỉ',
            ],
            Icons.cancel_outlined,
            Colors.red,
          ),

          const SizedBox(height: 16),

          // Hotel Amenities
          _buildPolicyCard(
            'Tiện ích khách sạn',
            [
              'WiFi miễn phí trong toàn bộ khách sạn',
              'Bể bơi ngoài trời',
              'Phòng gym 24/7',
              'Dịch vụ phòng 24/7',
              'Spa & Massage',
            ],
            Icons.local_offer,
            Colors.green,
          ),

          const SizedBox(height: 16),

          // Important Notes
          _buildPolicyCard(
            'Lưu ý quan trọng',
            [
              'Mang theo CMND/CCCD khi check-in',
              'Không hút thuốc trong phòng',
              'Không được phép mang thú cưng',
              'Giữ gìn vệ sinh và tài sản khách sạn',
            ],
            Icons.info_outline,
            Colors.purple,
          ),

          const SizedBox(height: 20),

          // Contact Information
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
                Text(
                  'Thông tin liên hệ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.phone, color: Colors.blue[600], size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Hotline: 1900-1234 (24/7)',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.email, color: Colors.blue[600], size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Email: support@hotel.com',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyCard(
    String title,
    List<String> policies,
    IconData icon,
    MaterialColor color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color[600], size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...policies.map(
            (policy) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: color[600],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      policy,
                      style: TextStyle(
                        fontSize: 12,
                        color: color[700],
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
