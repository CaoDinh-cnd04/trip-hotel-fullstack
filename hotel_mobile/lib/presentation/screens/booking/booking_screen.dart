import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/hotel.dart';
import '../../../data/models/room.dart';
import '../../../data/services/booking_service.dart';
import '../../../data/services/search_history_service.dart';
import '../payment/payment_screen.dart';

class BookingScreen extends StatefulWidget {
  final Hotel hotel;

  const BookingScreen({
    super.key,
    required this.hotel,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final BookingService _bookingService = BookingService();
  
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  int _rooms = 1;
  int _adults = 2;
  int _children = 0;
  bool _isLoading = false;
  String? _error;
  List<Room> _availableRooms = [];
  Room? _selectedRoom;

  @override
  void initState() {
    super.initState();
    _checkInDate = DateTime.now().add(const Duration(days: 1));
    _checkOutDate = DateTime.now().add(const Duration(days: 2));
    _loadAvailableRooms();
  }

  Future<void> _loadAvailableRooms() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      print('🏨 Loading rooms cho khách sạn: ${widget.hotel.ten} (ID: ${widget.hotel.id})');
      final response = await _bookingService.getRooms(widget.hotel.id);
      
      print('📡 Response: success=${response.success}, data count=${response.data?.length}');
      
      if (response.success && response.data != null && response.data!.isNotEmpty) {
        setState(() {
          _availableRooms = response.data!;
          _selectedRoom = _availableRooms.first;
          _isLoading = false;
        });
        print('✅ Đã load ${_availableRooms.length} phòng');
      } else {
        // Hiển thị lỗi thay vì fallback
        setState(() {
          _error = response.message ?? 'Không có phòng nào';
          _isLoading = false;
        });
        print('⚠️ Không có phòng: ${response.message}');
      }
    } catch (e) {
      print('❌ Exception load rooms: $e');
      setState(() {
        _error = 'Lỗi tải danh sách phòng: $e';
        _isLoading = false;
        _availableRooms = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Đặt phòng'),
        backgroundColor: const Color(0xFF8B4513),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Hotel Info Card
                  _buildHotelInfoCard(),
                  
                  const SizedBox(height: 16),
                  
                  // Booking Details Card
                  _buildBookingDetailsCard(),
                  
                  const SizedBox(height: 16),
                  
                  // Price Summary Card
                  _buildPriceSummaryCard(),
                  
                  const SizedBox(height: 16),
                  
                  // Error Message
                  if (_error != null) _buildErrorCard(),
                  
                  const SizedBox(height: 100), // Space for bottom button
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildHotelInfoCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hotel Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: widget.hotel.hinhAnh != null
                  ? Image.network(
                      widget.hotel.hinhAnh!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.hotel, size: 64, color: Colors.grey),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.hotel, size: 64, color: Colors.grey),
                    ),
            ),
          ),
          
          // Hotel Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.hotel.ten,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.hotel.diaChi ?? 'Địa chỉ không xác định',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    // Rating
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < (widget.hotel.soSao ?? 4) ? Icons.star : Icons.star_border,
                            size: 16,
                            color: Colors.amber,
                          );
                        }),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.hotel.diemDanhGiaTrungBinh?.toStringAsFixed(1) ?? "4.5"}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    
                    const Spacer(),
                    
                    // Price
                    Text(
                      'Từ ${widget.hotel.giaTb?.toStringAsFixed(0) ?? "500,000"} ₫/đêm',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B4513),
                      ),
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

  Widget _buildBookingDetailsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chi tiết đặt phòng',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Check-in Date
          _buildDateField(
            'Ngày nhận phòng',
            _checkInDate!,
            Icons.calendar_today,
            () => _selectDate(true),
          ),
          
          const SizedBox(height: 16),
          
          // Check-out Date
          _buildDateField(
            'Ngày trả phòng',
            _checkOutDate!,
            Icons.calendar_today,
            () => _selectDate(false),
          ),
          
          const SizedBox(height: 16),
          
          // Room Selection
          _buildRoomSelection(),
          
          const SizedBox(height: 16),
          
          // Guest Selection
          _buildGuestSelection(),
        ],
      ),
    );
  }

  Widget _buildDateField(String label, DateTime date, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF8B4513)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(date),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chọn loại phòng',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        
        const SizedBox(height: 12),
        
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_availableRooms.isEmpty)
          const Text(
            'Không có phòng khả dụng',
            style: TextStyle(color: Colors.red),
          )
        else
          ..._availableRooms.map((room) => _buildRoomOption(room)).toList(),
      ],
    );
  }

  Widget _buildRoomOption(Room room) {
    final isSelected = _selectedRoom?.id == room.id;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRoom = room;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.grey[50],
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.tenLoaiPhong ?? 'Standard Room',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.blue : Colors.black87,
                    ),
                  ),
                  
                  if (room.moTa != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      room.moTa!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 4),
                  
                  Row(
                    children: [
                      Icon(Icons.person, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Tối đa ${room.sucChua ?? 2} khách',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${room.giaPhong?.toStringAsFixed(0) ?? "500,000"} ₫',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.blue : const Color(0xFF8B4513),
                  ),
                ),
                const Text(
                  '/đêm',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestSelection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Khách',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$_rooms phòng • $_adults người lớn • $_children trẻ em',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          // Room Selection
          _buildCounterRow('Phòng', _rooms, (value) {
            setState(() {
              _rooms = value;
            });
          }),
          const SizedBox(height: 12),
          // Adults Selection
          _buildCounterRow('Người lớn', _adults, (value) {
            setState(() {
              _adults = value;
            });
          }),
          const SizedBox(height: 12),
          // Children Selection
          _buildCounterRow('Trẻ em', _children, (value) {
            setState(() {
              _children = value;
            });
          }),
        ],
      ),
    );
  }

  Widget _buildCounterRow(String label, int value, Function(int) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        Row(
          children: [
            IconButton(
              onPressed: value > (label == 'Phòng' ? 1 : 0) ? () => onChanged(value - 1) : null,
              icon: Icon(
                Icons.remove_circle_outline,
                color: value > (label == 'Phòng' ? 1 : 0) ? const Color(0xFF8B4513) : Colors.grey[400],
              ),
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              padding: EdgeInsets.zero,
            ),
            Container(
              width: 40,
              alignment: Alignment.center,
              child: Text(
                '$value',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              onPressed: () => onChanged(value + 1),
              icon: const Icon(Icons.add_circle_outline),
              color: const Color(0xFF8B4513),
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceSummaryCard() {
    final nights = _checkOutDate!.difference(_checkInDate!).inDays;
    final roomPrice = _selectedRoom?.giaPhong ?? widget.hotel.giaTb ?? 500000;
    final basePrice = roomPrice * nights * _rooms;
    final tax = basePrice * 0.1; // 10% tax
    final total = basePrice + tax;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tóm tắt giá',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          
          const SizedBox(height: 16),
          
          _buildPriceRow('Giá phòng ($nights đêm)', basePrice.toStringAsFixed(0)),
          _buildPriceRow('Thuế (10%)', tax.toStringAsFixed(0)),
          
          const Divider(),
          
          _buildPriceRow(
            'Tổng cộng',
            total.toStringAsFixed(0),
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String price, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.black87 : Colors.grey[600],
            ),
          ),
          Text(
            '${price} ₫',
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: FontWeight.bold,
              color: isTotal ? const Color(0xFF8B4513) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _confirmBooking,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B4513),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Xác nhận đặt phòng',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(bool isCheckIn) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isCheckIn ? _checkInDate! : _checkOutDate!,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkInDate = picked;
          // Ensure check-out is after check-in
          if (_checkOutDate!.isBefore(picked.add(const Duration(days: 1)))) {
            _checkOutDate = picked.add(const Duration(days: 1));
          }
        } else {
          _checkOutDate = picked;
        }
      });
    }
  }

  Future<void> _confirmBooking() async {
    if (_checkInDate == null || _checkOutDate == null) {
      setState(() {
        _error = 'Vui lòng chọn ngày nhận và trả phòng';
      });
      return;
    }

    if (_checkOutDate!.isBefore(_checkInDate!.add(const Duration(days: 1)))) {
      setState(() {
        _error = 'Ngày trả phòng phải sau ngày nhận phòng ít nhất 1 ngày';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Save search history
      await SearchHistoryService.saveSearchHistory(
        location: widget.hotel.ten,
        checkInDate: _checkInDate!,
        checkOutDate: _checkOutDate!,
        rooms: _rooms,
        adults: _adults,
        children: _children,
      );

      // Create booking
      final result = await _bookingService.createBooking(
        hotelId: widget.hotel.id.toString(),
        checkInDate: _checkInDate!,
        checkOutDate: _checkOutDate!,
        rooms: _rooms,
        adults: _adults,
        children: _children,
      );

      if (result.success) {
        // ✅ Reload room availability sau khi quay lại từ payment screen
        // Navigate to payment screen
        if (_selectedRoom != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentScreen(
                hotel: widget.hotel,
                room: _selectedRoom!,
                checkInDate: _checkInDate!,
                checkOutDate: _checkOutDate!,
                guestCount: _adults,
                nights: _checkOutDate!.difference(_checkInDate!).inDays,
                roomPrice: _selectedRoom!.giaPhong ?? 500000,
                roomCount: _rooms,
              ),
            ),
          ).then((_) {
            // Reload room availability sau khi quay lại (có thể đã đặt phòng thành công)
            print('🔄 Reloading room availability after returning from payment...');
            _loadAvailableRooms();
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vui lòng chọn loại phòng'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        setState(() {
          _error = result.message ?? 'Có lỗi xảy ra khi đặt phòng';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Lỗi đặt phòng: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    final weekdays = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    final months = ['thg 1', 'thg 2', 'thg 3', 'thg 4', 'thg 5', 'thg 6', 
                   'thg 7', 'thg 8', 'thg 9', 'thg 10', 'thg 11', 'thg 12'];
    
    return '${weekdays[date.weekday % 7]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
