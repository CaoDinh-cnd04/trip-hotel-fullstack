import 'package:flutter/material.dart';
import 'package:hotel_mobile/data/models/hotel.dart';

class PropertyInfoSection extends StatelessWidget {
  final Hotel hotel;

  const PropertyInfoSection({super.key, required this.hotel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hotel name and rating
          Text(
            hotel.ten,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),

          // Star rating
          Row(
            children: [
              _buildStarRating(hotel.soSao ?? 0),
              const SizedBox(width: 8),
              Text(
                '${hotel.soSao ?? 0} sao',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Rating score and reviews
          if (hotel.diemDanhGiaTrungBinh != null) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getRatingColor(hotel.diemDanhGiaTrungBinh!),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    hotel.diemDanhGiaTrungBinh!.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _getRatingText(hotel.diemDanhGiaTrungBinh!),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '(${hotel.soLuotDanhGia ?? 0} đánh giá)',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Address
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on, size: 18, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hotel.diaChi ?? 'Địa chỉ không có sẵn',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                        height: 1.4,
                      ),
                    ),
                    if (hotel.tenViTri != null ||
                        hotel.tenTinhThanh != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        [
                          hotel.tenViTri,
                          hotel.tenTinhThanh,
                          hotel.tenQuocGia,
                        ].where((e) => e != null && e.isNotEmpty).join(', '),
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // View on map button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                _showOnMap(context);
              },
              icon: const Icon(Icons.map, size: 20),
              label: const Text(
                'Xem trên bản đồ',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue,
                side: const BorderSide(color: Colors.blue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // Additional hotel info
          if (hotel.moTa != null && hotel.moTa!.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Mô tả',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hotel.moTa!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ],

          // Check-in/Check-out times
          if (hotel.gioNhanPhong != null || hotel.gioTraPhong != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  if (hotel.gioNhanPhong != null)
                    _buildInfoRow(
                      'Nhận phòng',
                      'Từ ${hotel.gioNhanPhong}',
                      Icons.login,
                    ),
                  if (hotel.gioNhanPhong != null && hotel.gioTraPhong != null)
                    const SizedBox(height: 12),
                  if (hotel.gioTraPhong != null)
                    _buildInfoRow(
                      'Trả phòng',
                      'Trước ${hotel.gioTraPhong}',
                      Icons.logout,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStarRating(int stars) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < stars ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 18,
        );
      }),
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 9.0) return Colors.green[700]!;
    if (rating >= 8.0) return Colors.green;
    if (rating >= 7.0) return Colors.lime[700]!;
    if (rating >= 6.0) return Colors.orange;
    return Colors.red;
  }

  String _getRatingText(double rating) {
    if (rating >= 9.0) return 'Tuyệt vời';
    if (rating >= 8.0) return 'Rất tốt';
    if (rating >= 7.0) return 'Tốt';
    if (rating >= 6.0) return 'Khá';
    return 'Trung bình';
  }

  Widget _buildInfoRow(String title, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showOnMap(BuildContext context) {
    // TODO: Implement map view
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xem trên bản đồ'),
        content: Text('Hiển thị vị trí của ${hotel.ten} trên bản đồ'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}
