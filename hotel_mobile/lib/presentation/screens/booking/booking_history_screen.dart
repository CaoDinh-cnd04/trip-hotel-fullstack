import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookingHistory();
  }

  Future<void> _loadBookingHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookingStrings = prefs.getStringList('booking_history') ?? [];
      
      setState(() {
        _bookings = bookingStrings
            .map((bookingString) => jsonDecode(bookingString) as Map<String, dynamic>)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Lỗi khi tải lịch sử đặt phòng: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử đặt phòng'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bookings.isEmpty
              ? _buildEmptyState()
              : _buildBookingList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.hotel_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có đặt phòng nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy đặt phòng để xem lịch sử ở đây',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.search),
            label: const Text('Tìm khách sạn'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingList() {
    return RefreshIndicator(
      onRefresh: _loadBookingHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _bookings.length,
        itemBuilder: (context, index) {
          final booking = _bookings[index];
          return _buildBookingCard(booking);
        },
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final status = booking['status'] as String;
    final isConfirmed = status == 'confirmed';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Row(
              children: [
                Expanded(
                  child: Text(
                    booking['hotel_name'] as String,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isConfirmed ? Colors.green[100] : Colors.orange[100],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isConfirmed ? Colors.green : Colors.orange,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    isConfirmed ? 'Đã xác nhận' : 'Chờ xác nhận',
                    style: TextStyle(
                      color: isConfirmed ? Colors.green[700] : Colors.orange[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Room type
            Row(
              children: [
                const Icon(Icons.bed, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  booking['room_type'] as String,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Check-in date
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Nhận phòng: ${_formatDate(DateTime.parse(booking['check_in'] as String))}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Check-out date
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Trả phòng: ${_formatDate(DateTime.parse(booking['check_out'] as String))}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Guest count
            Row(
              children: [
                const Icon(Icons.people, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  '${booking['guest_count']} khách',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Total amount and transaction ID
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tổng tiền: ${_formatCurrency(booking['total_amount'] as double)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                Text(
                  'Mã: ${booking['id']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Payment method
            Row(
              children: [
                const Icon(Icons.payment, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Thanh toán: ${_getPaymentMethodDisplayName(booking['payment_method'] as String)}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showBookingDetails(booking),
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text('Chi tiết'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (!isConfirmed)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _cancelBooking(booking),
                      icon: const Icon(Icons.cancel, size: 16),
                      label: const Text('Hủy'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
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

  void _showBookingDetails(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chi tiết đặt phòng'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Khách sạn', booking['hotel_name']),
              _buildDetailRow('Loại phòng', booking['room_type']),
              _buildDetailRow('Ngày nhận phòng', _formatDate(DateTime.parse(booking['check_in']))),
              _buildDetailRow('Ngày trả phòng', _formatDate(DateTime.parse(booking['check_out']))),
              _buildDetailRow('Số khách', '${booking['guest_count']} người'),
              _buildDetailRow('Tổng tiền', _formatCurrency(booking['total_amount'])),
              _buildDetailRow('Phương thức thanh toán', _getPaymentMethodDisplayName(booking['payment_method'])),
              _buildDetailRow('Trạng thái', booking['status'] == 'confirmed' ? 'Đã xác nhận' : 'Chờ xác nhận'),
              _buildDetailRow('Mã giao dịch', booking['id']),
              _buildDetailRow('Tên khách', booking['guest_name']),
              _buildDetailRow('Email', booking['guest_email']),
              _buildDetailRow('Số điện thoại', booking['guest_phone']),
              _buildDetailRow('Ngày đặt', _formatDate(DateTime.parse(booking['created_at']))),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _cancelBooking(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy đặt phòng'),
        content: const Text('Bạn có chắc chắn muốn hủy đặt phòng này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Không'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _removeBooking(booking);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Có, hủy'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeBooking(Map<String, dynamic> booking) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookingStrings = prefs.getStringList('booking_history') ?? [];
      
      // Remove the booking from the list
      final updatedBookings = bookingStrings.where((bookingString) {
        final bookingData = jsonDecode(bookingString) as Map<String, dynamic>;
        return bookingData['id'] != booking['id'];
      }).toList();
      
      await prefs.setStringList('booking_history', updatedBookings);
      
      // Reload the list
      await _loadBookingHistory();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã hủy đặt phòng thành công'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Lỗi khi hủy đặt phòng: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Có lỗi xảy ra khi hủy đặt phòng'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} VNĐ';
  }

  String _getPaymentMethodDisplayName(String method) {
    switch (method) {
      case 'PaymentMethod.creditCard':
        return 'Thẻ tín dụng';
      case 'PaymentMethod.eWallet':
        return 'Ví điện tử';
      case 'PaymentMethod.hotelPayment':
        return 'Thanh toán tại khách sạn';
      case 'PaymentMethod.vnpay':
        return 'VNPay';
      case 'PaymentMethod.vietqr':
        return 'VietQR';
      default:
        return method;
    }
  }
}
