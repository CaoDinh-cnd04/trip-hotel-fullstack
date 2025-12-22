import 'package:flutter/material.dart';
import '../../../data/models/activity.dart';

class ActivityDetailScreen extends StatelessWidget {
  final Activity activity;

  const ActivityDetailScreen({
    super.key,
    required this.activity,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar với hình ảnh
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                activity.hinhAnh ?? 'https://via.placeholder.com/800x400',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, size: 64, color: Colors.grey),
                  );
                },
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    activity.ten,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Rating và reviews
                  if (activity.danhGia != null && activity.danhGia! > 0)
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          activity.danhGia!.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          activity.ratingText,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  // Price
                  Text(
                    activity.priceText,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Info cards
                  _buildInfoSection(),
                  const SizedBox(height: 24),
                  // Description
                  if (activity.moTa != null) ...[
                    const Text(
                      'Mô tả',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      activity.moTa!,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  // Additional images
                  if (activity.hinhAnhBoSung != null && activity.hinhAnhBoSung!.isNotEmpty) ...[
                    const Text(
                      'Hình ảnh',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: activity.hinhAnhBoSung!.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 300,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey[300],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                activity.hinhAnhBoSung![index],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.image, size: 64, color: Colors.grey);
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  // Book button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tính năng đặt chỗ đang được phát triển'),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Đặt ngay',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          if (activity.diaDiem != null)
            _buildInfoRow(
              icon: Icons.location_on,
              label: 'Địa điểm',
              value: activity.diaDiem!,
            ),
          if (activity.diaChi != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.place,
              label: 'Địa chỉ',
              value: activity.diaChi!,
            ),
          ],
          if (activity.thoiLuong != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.access_time,
              label: 'Thời lượng',
              value: activity.durationText,
            ),
          ],
          if (activity.gioBatDau != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.schedule,
              label: 'Giờ bắt đầu',
              value: activity.gioBatDau!,
            ),
          ],
          if (activity.loaiHoatDong != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.category,
              label: 'Loại hoạt động',
              value: activity.loaiHoatDong!,
            ),
          ],
          if (activity.soNguoiToiThieu != null || activity.soNguoiToiDa != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.people,
              label: 'Số người',
              value: activity.soNguoiToiThieu != null && activity.soNguoiToiDa != null
                  ? '${activity.soNguoiToiThieu} - ${activity.soNguoiToiDa} người'
                  : activity.soNguoiToiThieu != null
                      ? 'Tối thiểu ${activity.soNguoiToiThieu} người'
                      : 'Tối đa ${activity.soNguoiToiDa} người',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.orange),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
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

