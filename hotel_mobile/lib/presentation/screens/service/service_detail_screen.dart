import 'package:flutter/material.dart';
import 'package:hotel_mobile/data/models/amenity.dart';
import 'package:intl/intl.dart';

/// Màn hình hiển thị chi tiết dịch vụ/tiện ích của khách sạn
class ServiceDetailScreen extends StatelessWidget {
  final Amenity amenity;
  final String hotelName;

  const ServiceDetailScreen({
    super.key,
    required this.amenity,
    required this.hotelName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
          color: const Color(0xFF1A1A1A),
        ),
        title: const Text(
          'Chi tiết dịch vụ',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: const Color(0xFFE8E8E8),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header với icon và tên dịch vụ
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: amenity.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: amenity.color.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: amenity.color,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      amenity.icon,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          amenity.ten,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hotelName,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Thông tin giá
            _buildInfoSection(
              'Thông tin giá',
              [
                _buildInfoRow(
                  Icons.attach_money,
                  'Trạng thái',
                  amenity.mienPhi ? 'Miễn phí' : 'Có phí',
                  amenity.mienPhi ? Colors.green : Colors.orange,
                ),
                if (!amenity.mienPhi && amenity.giaPhi != null) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.payments,
                    'Giá dịch vụ',
                    _formatPrice(amenity.giaPhi!),
                    const Color(0xFF003580),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 24),

            // Mô tả/Ghi chú
            if (amenity.ghiChu != null && amenity.ghiChu!.isNotEmpty) ...[
              _buildInfoSection(
                'Thông tin chi tiết',
                [
                  Text(
                    amenity.ghiChu!,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF666666),
                      height: 1.6,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // Nhóm dịch vụ
            if (amenity.nhom != null && amenity.nhom!.isNotEmpty) ...[
              _buildInfoSection(
                'Phân loại',
                [
                  _buildInfoRow(
                    Icons.category,
                    'Nhóm dịch vụ',
                    amenity.nhom!,
                    const Color(0xFF666666),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // Mô tả bổ sung
            if (amenity.moTa != null && amenity.moTa!.isNotEmpty) ...[
              _buildInfoSection(
                'Mô tả',
                [
                  Text(
                    amenity.moTa!,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF666666),
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF666666),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatPrice(double price) {
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '',
      decimalDigits: 0,
    );
    return '${formatter.format(price)} VND';
  }
}

