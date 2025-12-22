import 'package:flutter/material.dart';
import '../../../data/models/room_availability.dart';
import '../../../data/services/room_availability_service.dart';

/// Demo screen để xem các widget availability
class RoomAvailabilityDemoScreen extends StatefulWidget {
  final String? hotelId;

  const RoomAvailabilityDemoScreen({Key? key, this.hotelId}) : super(key: key);

  @override
  State<RoomAvailabilityDemoScreen> createState() =>
      _RoomAvailabilityDemoScreenState();
}

class _RoomAvailabilityDemoScreenState
    extends State<RoomAvailabilityDemoScreen> {
  final RoomAvailabilityService _availabilityService =
      RoomAvailabilityService();

  List<RoomAvailability> _rooms = [];
  bool _isLoading = false;
  String? _error;

  DateTime _checkinDate = DateTime.now().add(const Duration(days: 1));
  DateTime _checkoutDate = DateTime.now().add(const Duration(days: 3));

  @override
  void initState() {
    super.initState();
    if (widget.hotelId != null) {
      _loadAvailability();
    } else {
      _loadMockData();
    }
  }

  Future<void> _loadAvailability() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _availabilityService.getHotelAvailability(
        hotelId: widget.hotelId!,
        checkinDate: _checkinDate,
        checkoutDate: _checkoutDate,
      );

      if (response.success) {
        setState(() {
          _rooms = response.rooms;
          _isLoading = false;
        });

        // Hiển thị warnings nếu có
        if (response.warnings != null && response.warnings!.isNotEmpty) {
          _showWarningsDialog(response.warnings!);
        }
      } else {
        setState(() {
          _error = response.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _loadMockData() {
    // Mock data để demo UI
    setState(() {
      _rooms = [
        RoomAvailability(
          maLoaiPhong: '1',
          tenLoaiPhong: 'Deluxe Room',
          giaCoban: 1500000,
          soKhachToiDa: 2,
          totalRooms: 10,
          bookedRooms: 9,
          availableRooms: 1,
          isLowAvailability: true,
          isSoldOut: false,
          warning: 'Chỉ còn 1 phòng cuối cùng!',
        ),
        RoomAvailability(
          maLoaiPhong: '2',
          tenLoaiPhong: 'Superior Room',
          giaCoban: 2000000,
          soKhachToiDa: 3,
          totalRooms: 8,
          bookedRooms: 6,
          availableRooms: 2,
          isLowAvailability: true,
          isSoldOut: false,
          warning: 'Chỉ còn 2 phòng!',
        ),
        RoomAvailability(
          maLoaiPhong: '3',
          tenLoaiPhong: 'Suite Room',
          giaCoban: 3500000,
          soKhachToiDa: 4,
          totalRooms: 5,
          bookedRooms: 5,
          availableRooms: 0,
          isLowAvailability: false,
          isSoldOut: true,
          warning: 'Đã hết phòng',
        ),
        RoomAvailability(
          maLoaiPhong: '4',
          tenLoaiPhong: 'Standard Room',
          giaCoban: 1000000,
          soKhachToiDa: 2,
          totalRooms: 15,
          bookedRooms: 8,
          availableRooms: 7,
          isLowAvailability: false,
          isSoldOut: false,
        ),
      ];
    });
  }

  void _showWarningsDialog(List<String> warnings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Cảnh báo phòng'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: warnings
              .map(
                (w) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, size: 6, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(child: Text(w)),
                    ],
                  ),
                ),
              )
              .toList(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tình trạng phòng'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: widget.hotelId != null
                ? _loadAvailability
                : _loadMockData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorWidget()
          : _buildRoomsList(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Có lỗi xảy ra',
            style: TextStyle(fontSize: 18, color: Colors.red[700]),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: const TextStyle(fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: widget.hotelId != null
                ? _loadAvailability
                : _loadMockData,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomsList() {
    return Column(
      children: [
        // Date selector
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[100],
          child: Row(
            children: [
              Expanded(
                child: _buildDateButton(
                  label: 'Nhận phòng',
                  date: _checkinDate,
                  onTap: () => _selectDate(true),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDateButton(
                  label: 'Trả phòng',
                  date: _checkoutDate,
                  onTap: () => _selectDate(false),
                ),
              ),
            ],
          ),
        ),

        // Summary
        if (_rooms.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  icon: Icons.hotel,
                  label: 'Tổng loại phòng',
                  value: '${_rooms.length}',
                  color: Colors.blue,
                ),
                _buildSummaryItem(
                  icon: Icons.check_circle,
                  label: 'Còn trống',
                  value: '${_rooms.where((r) => !r.isSoldOut).length}',
                  color: Colors.green,
                ),
                _buildSummaryItem(
                  icon: Icons.warning,
                  label: 'Sắp hết',
                  value: '${_rooms.where((r) => r.isLowAvailability).length}',
                  color: Colors.orange,
                ),
              ],
            ),
          ),

        const Divider(height: 1),

        // Rooms list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _rooms.length,
            itemBuilder: (context, index) {
              final room = _rooms[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: RoomAvailabilityCard(
                  availability: room,
                  onTap: () => _handleRoomTap(room),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDateButton({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              '${date.day}/${date.month}/${date.year}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Future<void> _selectDate(bool isCheckin) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isCheckin ? _checkinDate : _checkoutDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isCheckin) {
          _checkinDate = picked;
          if (_checkoutDate.isBefore(_checkinDate)) {
            _checkoutDate = _checkinDate.add(const Duration(days: 1));
          }
        } else {
          _checkoutDate = picked;
        }
      });

      if (widget.hotelId != null) {
        _loadAvailability();
      }
    }
  }

  void _handleRoomTap(RoomAvailability room) {
    if (room.isLowAvailability && !room.isSoldOut) {
      LowAvailabilityAlert.show(context, room).then((shouldBook) {
        if (shouldBook == true) {
          _bookRoom(room);
        }
      });
    } else if (!room.isSoldOut) {
      _bookRoom(room);
    }
  }

  void _bookRoom(RoomAvailability room) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đặt phòng ${room.tenLoaiPhong}'),
        action: SnackBarAction(label: 'Xem', onPressed: () {}),
      ),
    );
  }
}

/// Widget hiển thị thông tin phòng và tình trạng có sẵn
class RoomAvailabilityCard extends StatelessWidget {
  final RoomAvailability availability;
  final VoidCallback? onTap;

  const RoomAvailabilityCard({Key? key, required this.availability, this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      availability.tenLoaiPhong,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildAvailabilityBadge(),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Số phòng còn lại: ${availability.availableRooms}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Giá: ${availability.giaCoban.toStringAsFixed(0)} VNĐ/đêm',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.green[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Xây dựng badge hiển thị trạng thái phòng
  Widget _buildAvailabilityBadge() {
    Color badgeColor;
    String badgeText;

    if (availability.isSoldOut) {
      badgeColor = Colors.red;
      badgeText = 'Hết phòng';
    } else if (availability.isLowAvailability) {
      badgeColor = Colors.orange;
      badgeText = 'Sắp hết';
    } else {
      badgeColor = Colors.green;
      badgeText = 'Còn phòng';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        badgeText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Alert dialog hiển thị cảnh báo khi phòng sắp hết
class LowAvailabilityAlert {
  /// Hiển thị dialog cảnh báo phòng sắp hết
  static Future<bool?> show(BuildContext context, RoomAvailability room) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('⚠️ Phòng sắp hết!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${room.tenLoaiPhong} chỉ còn lại ${room.availableRooms} phòng.',
              ),
              const SizedBox(height: 8),
              const Text(
                'Bạn có muốn đặt ngay để không bỏ lỡ cơ hội?',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Để sau'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Đặt ngay'),
            ),
          ],
        );
      },
    );
  }
}
