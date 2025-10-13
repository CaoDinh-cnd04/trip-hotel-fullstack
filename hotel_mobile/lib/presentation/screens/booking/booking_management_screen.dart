import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hotel_mobile/data/models/booking.dart';
import 'package:hotel_mobile/data/services/api_service.dart';
import 'package:hotel_mobile/data/services/auth_service.dart';

class BookingManagementScreen extends StatefulWidget {
  const BookingManagementScreen({super.key});

  @override
  State<BookingManagementScreen> createState() =>
      _BookingManagementScreenState();
}

class _BookingManagementScreenState extends State<BookingManagementScreen> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  List<Booking> _bookings = [];
  bool _isLoading = true;
  String? _error;
  BookingStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _apiService.initialize();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Check if user is logged in (AuthService or Firebase)
      final isLoggedIn = await _authService.isSignedIn();
      final isFirebaseLoggedIn = FirebaseAuth.instance.currentUser != null;
      if (!isLoggedIn && !isFirebaseLoggedIn) {
        setState(() {
          _error = 'Vui lòng đăng nhập để xem danh sách đặt phòng';
          _isLoading = false;
        });
        return;
      }

      // Note: Firebase authentication is handled separately
      // Backend session sync can be implemented if needed

      final currentUser = _authService.currentUser;
      if (currentUser?.id == null) {
        setState(() {
          _error = 'Không thể xác định thông tin người dùng';
          _isLoading = false;
        });
        return;
      }

      final response = await _apiService.getBookings(
        limit: 100,
        userId: currentUser!.id,
        status: _selectedStatus,
      );

      if (response.success && response.data != null) {
        setState(() {
          _bookings = response.data!;
          _isLoading = false;
        });
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

  Future<void> _cancelBooking(Booking booking) async {
    if (!booking.canCancel) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể hủy đặt phòng này')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận hủy đặt phòng'),
        content: Text(
          'Bạn có chắc chắn muốn hủy đặt phòng ${booking.soPhong ?? "này"}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hủy đặt phòng'),
          ),
        ],
      ),
    );

    if (confirmed == true && booking.id != null) {
      try {
        final response = await _apiService.cancelBooking(booking.id!);
        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã hủy đặt phòng thành công')),
          );
          _loadBookings();
        } else {
          throw Exception(response.message);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi hủy đặt phòng: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Đặt phòng'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadBookings),
        ],
      ),
      body: Column(
        children: [
          // Status Filter
          Container(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<BookingStatus?>(
              decoration: const InputDecoration(
                labelText: 'Lọc theo trạng thái',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.filter_list),
              ),
              value: _selectedStatus,
              items: [
                const DropdownMenuItem<BookingStatus?>(
                  value: null,
                  child: Text('Tất cả'),
                ),
                ...BookingStatus.values.map(
                  (status) => DropdownMenuItem(
                    value: status,
                    child: Text(_getStatusText(status)),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value;
                });
                _loadBookings();
              },
            ),
          ),
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadBookings,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  )
                : _bookings.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.book_online, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Không có đặt phòng nào'),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadBookings,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _bookings.length,
                      itemBuilder: (context, index) {
                        final booking = _bookings[index];
                        return _buildBookingCard(booking);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.tenKhachSan ?? 'Khách sạn',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Phòng ${booking.soPhong ?? "N/A"} - ${booking.tenLoaiPhong ?? "Loại phòng"}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(booking.trangThai),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        booking.statusText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Booking Details
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                        icon: Icons.calendar_today,
                        title: 'Nhận phòng',
                        value: _formatDate(booking.ngayNhanPhong),
                      ),
                    ),
                    Expanded(
                      child: _buildDetailItem(
                        icon: Icons.calendar_today_outlined,
                        title: 'Trả phòng',
                        value: _formatDate(booking.ngayTraPhong),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                        icon: Icons.people,
                        title: 'Số khách',
                        value: '${booking.soLuongKhach} khách',
                      ),
                    ),
                    Expanded(
                      child: _buildDetailItem(
                        icon: Icons.nights_stay,
                        title: 'Số đêm',
                        value: '${booking.numberOfNights} đêm',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Total Price
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tổng tiền',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        booking.formattedTotalPrice,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),

                // Notes
                if (booking.ghiChu != null && booking.ghiChu!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ghi chú:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          booking.ghiChu!,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Action Buttons
          if (booking.canCancel || booking.canCheckIn)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (booking.canCheckIn)
                    TextButton.icon(
                      onPressed: () {
                        // TODO: Implement check-in functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Chức năng check-in đang được phát triển',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: const Text('Check-in'),
                    ),
                  if (booking.canCancel) ...[
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _cancelBooking(booking),
                      icon: const Icon(
                        Icons.cancel,
                        size: 16,
                        color: Colors.red,
                      ),
                      label: const Text(
                        'Hủy đặt phòng',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }

  String _getStatusText(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'Chờ xác nhận';
      case BookingStatus.confirmed:
        return 'Đã xác nhận';
      case BookingStatus.checkedIn:
        return 'Đã check-in';
      case BookingStatus.checkedOut:
        return 'Đã check-out';
      case BookingStatus.cancelled:
        return 'Đã hủy';
    }
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.confirmed:
        return Colors.green;
      case BookingStatus.checkedIn:
        return Colors.blue;
      case BookingStatus.checkedOut:
        return Colors.grey;
      case BookingStatus.cancelled:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
