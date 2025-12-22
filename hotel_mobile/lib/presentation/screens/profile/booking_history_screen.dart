import 'package:flutter/material.dart';
import 'package:hotel_mobile/data/models/booking.dart';
import 'package:hotel_mobile/presentation/widgets/booking_card.dart';
import 'package:hotel_mobile/presentation/screens/reviews/create_review_screen.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Booking> _allBookings = [];
  List<Booking> _upcomingBookings = [];
  List<Booking> _completedBookings = [];
  List<Booking> _cancelledBookings = [];

  String _searchQuery = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadBookings() {
    setState(() {
      _isLoading = true;
    });

    // Simulate loading
    Future.delayed(const Duration(seconds: 1)).then((_) {
      final now = DateTime.now();

      _allBookings = [
        // Upcoming
        Booking(
          id: 1,
          nguoiDungId: 1,
          phongId: 101,
          ngayNhanPhong: now.add(const Duration(days: 5)),
          ngayTraPhong: now.add(const Duration(days: 7)),
          soLuongKhach: 2,
          tongTien: 2500000,
          trangThai: BookingStatus.confirmed,
          tenKhachSan: 'Khách sạn Grand Palace',
          tenLoaiPhong: 'Deluxe Room',
          soPhong: '301',
          ngayTao: now.subtract(const Duration(days: 2)),
        ),
        Booking(
          id: 2,
          nguoiDungId: 1,
          phongId: 102,
          ngayNhanPhong: now.add(const Duration(days: 15)),
          ngayTraPhong: now.add(const Duration(days: 18)),
          soLuongKhach: 4,
          tongTien: 8500000,
          trangThai: BookingStatus.confirmed,
          tenKhachSan: 'Resort Seaside Paradise',
          tenLoaiPhong: 'Family Suite',
          soPhong: '205',
          ngayTao: now.subtract(const Duration(days: 1)),
        ),
        // Completed
        Booking(
          id: 3,
          nguoiDungId: 1,
          phongId: 103,
          ngayNhanPhong: now.subtract(const Duration(days: 30)),
          ngayTraPhong: now.subtract(const Duration(days: 28)),
          soLuongKhach: 2,
          tongTien: 1800000,
          trangThai: BookingStatus.checkedOut,
          tenKhachSan: 'Hotel Luxury Downtown',
          tenLoaiPhong: 'Standard Room',
          soPhong: '412',
          ngayTao: now.subtract(const Duration(days: 35)),
        ),
        Booking(
          id: 4,
          nguoiDungId: 1,
          phongId: 104,
          ngayNhanPhong: now.subtract(const Duration(days: 60)),
          ngayTraPhong: now.subtract(const Duration(days: 58)),
          soLuongKhach: 3,
          tongTien: 3200000,
          trangThai: BookingStatus.checkedOut,
          tenKhachSan: 'Hilton Ha Noi',
          tenLoaiPhong: 'Superior Room',
          soPhong: '501',
          ngayTao: now.subtract(const Duration(days: 65)),
        ),
        // Cancelled
        Booking(
          id: 5,
          nguoiDungId: 1,
          phongId: 105,
          ngayNhanPhong: now.subtract(const Duration(days: 10)),
          ngayTraPhong: now.subtract(const Duration(days: 8)),
          soLuongKhach: 1,
          tongTien: 1200000,
          trangThai: BookingStatus.cancelled,
          tenKhachSan: 'Business Hotel Central',
          tenLoaiPhong: 'Business Room',
          soPhong: '108',
          ngayTao: now.subtract(const Duration(days: 15)),
        ),
      ];

      _upcomingBookings = _allBookings
          .where(
            (booking) =>
                booking.trangThai == BookingStatus.confirmed ||
                booking.trangThai == BookingStatus.pending,
          )
          .toList();

      _completedBookings = _allBookings
          .where((booking) => booking.trangThai == BookingStatus.checkedOut)
          .toList();

      _cancelledBookings = _allBookings
          .where((booking) => booking.trangThai == BookingStatus.cancelled)
          .toList();

      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Lịch sử đặt phòng'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo tên khách sạn...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),

          // Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(25),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: const Color(0xFF2196F3),
                borderRadius: BorderRadius.circular(25),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[600],
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              tabs: [
                Tab(text: 'Sắp tới (${_upcomingBookings.length})'),
                Tab(text: 'Hoàn thành (${_completedBookings.length})'),
                Tab(text: 'Đã hủy (${_cancelledBookings.length})'),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBookingList(_upcomingBookings),
                _buildBookingList(_completedBookings),
                _buildBookingList(_cancelledBookings),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingList(List<Booking> bookings) {
    final filteredBookings = bookings
        .where(
          (booking) =>
              booking.tenKhachSan?.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ??
              false,
        )
        .toList();

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (filteredBookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'Không có đặt chỗ nào'
                  : 'Không tìm thấy kết quả',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredBookings.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: BookingCard(
            booking: filteredBookings[index],
            onTap: () => _showBookingDetail(filteredBookings[index]),
          ),
        );
      },
    );
  }

  void _showBookingDetail(Booking booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Chi tiết đặt chỗ #${booking.id}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  booking.trangThai,
                                ).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                booking.getStatusDisplayName(),
                                style: TextStyle(
                                  color: _getStatusColor(booking.trangThai),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Hotel Info Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Khách sạn',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            booking.tenKhachSan ?? 'Không xác định',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Room Info
                    _buildDetailRow('Loại phòng', booking.tenLoaiPhong ?? ''),
                    _buildDetailRow('Số phòng', booking.soPhong ?? ''),
                    const Divider(),
                    _buildDetailRow(
                      'Ngày nhận phòng',
                      _formatDate(booking.ngayNhanPhong),
                    ),
                    _buildDetailRow(
                      'Ngày trả phòng',
                      _formatDate(booking.ngayTraPhong),
                    ),
                    _buildDetailRow(
                      'Số đêm',
                      '${booking.ngayTraPhong.difference(booking.ngayNhanPhong).inDays} đêm',
                    ),
                    const Divider(),
                    _buildDetailRow(
                      'Số khách',
                      '${booking.soLuongKhach} người',
                    ),
                    const Divider(),

                    // Price Info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Tổng tiền',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Text(
                                _formatCurrency(booking.tongTien),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2196F3),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Action Buttons
                    if (booking.trangThai == BookingStatus.confirmed) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _handleCancelBooking(booking),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Hủy đặt chỗ'),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (booking.trangThai == BookingStatus.checkedOut) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _handleWriteReview(booking),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Viết đánh giá'),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => _handleContactSupport(),
                        child: const Text('Liên hệ hỗ trợ'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} VNĐ';
  }

  String _formatPrice(double amount) {
    return _formatCurrency(amount).replaceAll(' VNĐ', '');
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

  void _handleCancelBooking(Booking booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy đặt chỗ'),
        content: const Text(
          'Bạn có chắc chắn muốn hủy đặt chỗ này? '
          'Số tiền đã thanh toán sẽ được hoàn lại.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đặt chỗ đã được hủy'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );
  }

  void _handleWriteReview(Booking booking) {
    // Navigate to new review screen with 2 tabs
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateReviewScreen(
          bookingId: booking.maDatPhong ?? booking.id.toString(),
          hotelId: booking.khachSanId ?? 0,
          hotelName: booking.tenKhachSan ?? 'Khách sạn',
        ),
      ),
    ).then((shouldRefresh) {
      if (shouldRefresh == true) {
        _loadBookings(); // Refresh bookings after review
      }
    });
  }

  Widget _buildReviewForm(Booking booking) {
    final reviewController = TextEditingController();
    double rating = 5;

    return StatefulBuilder(
      builder: (context, setState) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Đánh giá khách sạn',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                booking.tenKhachSan ?? 'Khách sạn',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Đánh giá của bạn',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: List.generate(
                  5,
                  (index) => IconButton(
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () {
                      setState(() {
                        rating = index + 1.0;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: reviewController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Chia sẻ trải nghiệm của bạn...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cảm ơn bạn đã đánh giá!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: const Text('Gửi đánh giá'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleContactSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mở trang hỗ trợ khách hàng'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}

// Extension for Booking model
extension BookingExtensions on Booking {
  String getStatusDisplayName() {
    switch (trangThai) {
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
}
