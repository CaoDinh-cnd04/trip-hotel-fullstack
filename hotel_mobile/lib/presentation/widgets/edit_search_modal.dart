import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EditSearchModal extends StatefulWidget {
  final String location;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int guestCount;
  final int roomCount;
  final Function({
    required String location,
    required DateTime checkInDate,
    required DateTime checkOutDate,
    required int guestCount,
    required int roomCount,
  }) onSearchUpdated;

  const EditSearchModal({
    super.key,
    required this.location,
    required this.checkInDate,
    required this.checkOutDate,
    required this.guestCount,
    required this.roomCount,
    required this.onSearchUpdated,
  });

  @override
  State<EditSearchModal> createState() => _EditSearchModalState();
}

class _EditSearchModalState extends State<EditSearchModal> {
  late TextEditingController _locationController;
  late DateTime _checkInDate;
  late DateTime _checkOutDate;
  late int _guestCount;
  late int _roomCount;
  bool _showPromotions = false;

  @override
  void initState() {
    super.initState();
    _locationController = TextEditingController(text: widget.location);
    _checkInDate = widget.checkInDate;
    _checkOutDate = widget.checkOutDate;
    _guestCount = widget.guestCount;
    _roomCount = widget.roomCount;
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('E, dd MMM', 'vi_VN');

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                  ),
                ),
                const Text(
                  'Tất cả phòng',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 48), // Balance the close button
              ],
            ),
          ),

          // Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildTab('Qua đêm', true),
                ),
                Expanded(
                  child: _buildTab('Ở trong ngày', false),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location Search
                  _buildLocationField(),

                  const SizedBox(height: 16),

                  // Date Selection
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateField(
                          dateFormat.format(_checkInDate),
                          Icons.calendar_today,
                          () => _selectDate(true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDateField(
                          dateFormat.format(_checkOutDate),
                          Icons.calendar_today,
                          () => _selectDate(false),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Guest & Room Selection
                  _buildGuestRoomField(),

                  const SizedBox(height: 16),

                  // Promotions Checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: _showPromotions,
                        onChanged: (value) {
                          setState(() {
                            _showPromotions = value ?? false;
                          });
                        },
                        activeColor: const Color(0xFF003580),
                      ),
                      const Icon(Icons.access_time, color: Colors.grey, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Cho xem các khuyến mại có thời hạn trước',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Tiết kiệm tới 20%',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bottom Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _performSearch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003580),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Khám phá ưu đãi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String title, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isSelected ? const Color(0xFF003580) : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? const Color(0xFF003580) : Colors.grey,
        ),
      ),
    );
  }

  Widget _buildLocationField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                hintText: 'Tìm khách sạn, địa điểm...',
                border: InputBorder.none,
              ),
            ),
          ),
          const Icon(Icons.navigation, color: Colors.blue),
        ],
      ),
    );
  }

  Widget _buildDateField(String text, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey, size: 20),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                text,
                style: const TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestRoomField() {
    return GestureDetector(
      onTap: _showGuestRoomPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.person, color: Colors.grey, size: 20),
            const SizedBox(width: 12),
            Text(
              '$_roomCount phòng $_guestCount người lớn 0 trẻ em',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  void _selectDate(bool isCheckIn) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isCheckIn ? _checkInDate : _checkOutDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF003580),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkInDate = picked;
          // Ensure checkout is after checkin
          if (_checkOutDate.isBefore(_checkInDate)) {
            _checkOutDate = _checkInDate.add(const Duration(days: 1));
          }
        } else {
          _checkOutDate = picked;
        }
      });
    }
  }

  void _showGuestRoomPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Rooms
              _buildCounterRow(
                'Phòng',
                _roomCount,
                (value) {
                  setState(() => _roomCount = value);
                  setModalState(() {});
                },
              ),
              const SizedBox(height: 16),
              // Guests
              _buildCounterRow(
                'Người lớn',
                _guestCount,
                (value) {
                  setState(() => _guestCount = value);
                  setModalState(() {});
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003580),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Xong',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCounterRow(String label, int value, ValueChanged<int> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        Row(
          children: [
            IconButton(
              onPressed: value > 1 ? () => onChanged(value - 1) : null,
              icon: const Icon(Icons.remove_circle_outline),
              color: const Color(0xFF003580),
            ),
            Container(
              width: 40,
              alignment: Alignment.center,
              child: Text(
                '$value',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              onPressed: () => onChanged(value + 1),
              icon: const Icon(Icons.add_circle_outline),
              color: const Color(0xFF003580),
            ),
          ],
        ),
      ],
    );
  }

  void _performSearch() {
    widget.onSearchUpdated(
      location: _locationController.text.isNotEmpty
          ? _locationController.text
          : widget.location,
      checkInDate: _checkInDate,
      checkOutDate: _checkOutDate,
      guestCount: _guestCount,
      roomCount: _roomCount,
    );
    Navigator.pop(context);
  }
}

