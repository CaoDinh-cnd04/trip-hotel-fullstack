import 'package:flutter/material.dart';
import 'package:hotel_mobile/data/models/room.dart';

class RoomSelectionSection extends StatefulWidget {
  final List<Room> rooms;
  final Function(Room) onRoomSelected;
  final DateTime? checkInDate;
  final DateTime? checkOutDate;
  final int guestCount;

  const RoomSelectionSection({
    super.key,
    required this.rooms,
    required this.onRoomSelected,
    this.checkInDate,
    this.checkOutDate,
    required this.guestCount,
  });

  @override
  State<RoomSelectionSection> createState() => _RoomSelectionSectionState();
}

class _RoomSelectionSectionState extends State<RoomSelectionSection> {
  final Map<int, bool> _expandedStates = {};

  int? get _numberOfNights {
    if (widget.checkInDate != null && widget.checkOutDate != null) {
      return widget.checkOutDate!.difference(widget.checkInDate!).inDays;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.rooms.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: const Center(
          child: Text(
            'Không có phòng nào khả dụng',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              const Text(
                'Lựa chọn phòng và giá',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              if (_numberOfNights != null)
                Text(
                  '$_numberOfNights đêm',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Rooms list
          ...widget.rooms.asMap().entries.map((entry) {
            final index = entry.key;
            final room = entry.value;
            return _buildRoomCard(room, index);
          }),
        ],
      ),
    );
  }

  Widget _buildRoomCard(Room room, int index) {
    final roomImages = room.hinhAnhPhong ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        onExpansionChanged: (expanded) {
          setState(() {
            _expandedStates[index] = expanded;
          });
        },
        leading: null,
        title: _buildRoomHeader(room, roomImages),
        children: [_buildRoomDetails(room)],
      ),
    );
  }

  Widget _buildRoomHeader(Room room, List<String> roomImages) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Room image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[200],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: roomImages.isNotEmpty
                  ? Image.network(
                      roomImages.first,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                            size: 30,
                          ),
                        );
                      },
                    )
                  : const Icon(Icons.bed, color: Colors.grey, size: 30),
            ),
          ),
          const SizedBox(width: 12),

          // Room info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room.tenLoaiPhong ?? 'Phòng không tên',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tối đa ${room.sucChua ?? 1} khách',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                if (room.moTa != null)
                  Text(
                    room.moTa!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 8),
                _buildPriceDisplay(room.giaPhong ?? 0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomDetails(Room room) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Room images carousel
          if (room.hinhAnhPhong != null && room.hinhAnhPhong!.isNotEmpty) ...[
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: room.hinhAnhPhong!.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: 160,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        room.hinhAnhPhong![index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Room features
          const Text(
            'Đặc điểm phòng',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _buildFeatureChip(Icons.bed, 'Giường đôi'),
              _buildFeatureChip(Icons.wifi, 'WiFi miễn phí'),
              _buildFeatureChip(Icons.air, 'Điều hòa'),
              _buildFeatureChip(Icons.tv, 'TV'),
            ],
          ),
          const SizedBox(height: 16),

          // Pricing options
          const Text(
            'Tùy chọn giá',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),

          _buildPricingOption(
            'Không hoàn tiền',
            room.giaPhong ?? 0,
            'Giá tốt nhất • Không thể hủy',
            false,
            room,
          ),
          const SizedBox(height: 8),
          _buildPricingOption(
            'Kèm bữa sáng',
            (room.giaPhong ?? 0) + 200000,
            'Hủy miễn phí • Bao gồm bữa sáng',
            true,
            room,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceDisplay(double price) {
    return Row(
      children: [
        Text('Từ ', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        Text(
          _formatPrice(price),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Text('/đêm', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildFeatureChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingOption(
    String title,
    double price,
    String description,
    bool recommended,
    Room room,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: recommended ? Colors.blue : Colors.grey[300]!,
          width: recommended ? 2 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        title: Row(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            if (recommended) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Khuyến nghị',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  _formatPrice(price),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                Text(
                  '/đêm',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const Spacer(),
                SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    onPressed: () => widget.onRoomSelected(room),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text(
                      'Chọn',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K';
    }
    return '${price.toStringAsFixed(0)}';
  }
}
