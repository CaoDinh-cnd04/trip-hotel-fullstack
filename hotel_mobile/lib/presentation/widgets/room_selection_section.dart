import 'package:flutter/material.dart';
import 'package:hotel_mobile/data/models/room.dart';
import 'package:intl/intl.dart';
import 'room_availability_badge.dart';

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
  final Map<String, bool> _expandedStates = {}; // Use room type as key instead of index
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

  int? get _numberOfNights {
    if (widget.checkInDate != null && widget.checkOutDate != null) {
      return widget.checkOutDate!.difference(widget.checkInDate!).inDays;
    }
    return null;
  }

  // Nhóm phòng theo loại và trả về danh sách phòng đại diện với số lượng
  List<MapEntry<Room, int>> _getGroupedRooms() {
    // Nhóm phòng theo tenLoaiPhong
    final Map<String, List<Room>> grouped = {};
    for (var room in widget.rooms) {
      final roomType = room.tenLoaiPhong ?? 'Phòng không tên';
      if (!grouped.containsKey(roomType)) {
        grouped[roomType] = [];
      }
      grouped[roomType]!.add(room);
    }

    // Lấy 1 phòng đầu tiên làm đại diện cho mỗi nhóm
    return grouped.entries.map((entry) {
      final representativeRoom = entry.value.first;
      final remainingCount = entry.value.length - 1; // Số phòng còn lại (trừ phòng đại diện)
      return MapEntry(representativeRoom, remainingCount);
    }).toList();
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

    final groupedRooms = _getGroupedRooms();
    final totalRooms = widget.rooms.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            Colors.grey[50]!,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header với design hiện đại và số lượng phòng
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.indigo[50]!,
                  Colors.purple[50]!,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.indigo[200]!,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.indigo[400]!,
                        Colors.purple[400]!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.indigo.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.bed,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lựa chọn phòng và giá',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Đang hiển thị ${groupedRooms.length} loại phòng (Tổng ${totalRooms} phòng)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_numberOfNights != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange[400]!,
                          Colors.orange[600]!,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.bedtime,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$_numberOfNights đêm',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Rooms list - chỉ hiển thị 1 phòng đại diện cho mỗi loại
          ...groupedRooms.map((roomEntry) {
            final room = roomEntry.key;
            final remainingCount = roomEntry.value;
            final roomType = room.tenLoaiPhong ?? 'Phòng không tên';
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildRoomCard(room, roomType, remainingCount),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRoomCard(Room room, String roomType, int remainingCount) {
    final roomImages = room.hinhAnhPhong ?? [];
    final isExpanded = _expandedStates[roomType] ?? false;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isExpanded ? Colors.blue[300]! : Colors.grey[300]!,
          width: isExpanded ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isExpanded 
                ? Colors.blue.withOpacity(0.15)
                : Colors.black.withOpacity(0.08),
            blurRadius: isExpanded ? 20 : 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Room Image
          if (roomImages.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Stack(
                children: [
                  Container(
                    height: 180,
                    width: double.infinity,
                    child: Image.network(
                      roomImages.first,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.bed,
                            size: 50,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                  // Availability badge ở góc trên bên phải
                  Positioned(
                    top: 12,
                    right: 12,
                    child: RoomAvailabilityBadge(room: room),
                  ),
                ],
              ),
            ),

          // Room Info với design hiện đại
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Room name với gradient effect
                Row(
                  children: [
                    Expanded(
                      child: ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [Colors.indigo[800]!, Colors.purple[800]!],
                        ).createShader(bounds),
                        child: Text(
                          room.tenLoaiPhong ?? 'Phòng không tên',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ),
                    // Badge hiển thị số lượng phòng còn lại
                    if (remainingCount > 0)
                      Container(
                        margin: const EdgeInsets.only(left: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.green[400]!,
                              Colors.teal[400]!,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.bed_outlined,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Còn $remainingCount phòng',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Guest capacity với icon đẹp hơn
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_rounded, size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 6),
                      Text(
                        'Tối đa ${room.sucChua ?? 1} khách',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue[900],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Description
                if (room.moTa != null && room.moTa!.isNotEmpty)
                  Text(
                    room.moTa!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: isExpanded ? null : 2,
                    overflow: isExpanded ? null : TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 16),

                // Price với design hiện đại
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue[50]!,
                        Colors.cyan[50]!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Giá mỗi đêm',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${currencyFormat.format(room.giaPhong ?? 0)}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.blue[800],
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      // Expand/Collapse button với gradient
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue[400]!,
                              Colors.cyan[400]!,
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _expandedStates[roomType] = !isExpanded;
                              });
                            },
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              child: Icon(
                                isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Expanded content
                if (isExpanded) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // Room images carousel
                  if (roomImages.length > 1) ...[
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: roomImages.length,
                        itemBuilder: (context, imgIndex) {
                          return Container(
                            width: 160,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey[200],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                roomImages[imgIndex],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.image_not_supported, color: Colors.grey);
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
                    'Tiện ích phòng',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFeatureChip(Icons.bed, 'Giường đôi'),
                      _buildFeatureChip(Icons.wifi, 'WiFi miễn phí'),
                      _buildFeatureChip(Icons.air, 'Điều hòa'),
                      _buildFeatureChip(Icons.tv, 'TV'),
                      _buildFeatureChip(Icons.local_parking, 'Bãi đỗ xe'),
                      _buildFeatureChip(Icons.restaurant, 'Nhà hàng'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Pricing options
                  const Text(
                    'Tùy chọn giá',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildPricingOption(
                    'Không hoàn tiền',
                    room.giaPhong ?? 0,
                    'Giá tốt nhất • Không thể hủy',
                    false,
                    room,
                    0,
                  ),
                  const SizedBox(height: 8),
                  _buildPricingOption(
                    'Kèm bữa sáng',
                    (room.giaPhong ?? 0) + 200000,
                    'Hủy miễn phí • Bao gồm bữa sáng',
                    true,
                    room,
                    1,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
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
    int optionIndex,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: recommended ? Colors.blue[50] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: recommended ? Colors.blue[300]! : Colors.grey[300]!,
          width: recommended ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: recommended ? Colors.blue[700] : Colors.black87,
                ),
              ),
              if (recommended) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[700],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Khuyến nghị',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${currencyFormat.format(price)}/đêm',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  widget.onRoomSelected(room);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: const Text(
                  'Chọn',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}