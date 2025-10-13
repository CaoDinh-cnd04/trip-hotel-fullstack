import 'package:flutter/material.dart';
import 'package:hotel_mobile/data/services/auth_service.dart';
import 'package:hotel_mobile/data/models/booking.dart';
import 'package:hotel_mobile/presentation/widgets/booking_card.dart';
import 'package:hotel_mobile/presentation/widgets/profile_header.dart';
import 'package:hotel_mobile/presentation/widgets/account_menu.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _authService = AuthService();

  // Mock bookings data
  late List<Booking> _allBookings;
  late List<Booking> _upcomingBookings;
  late List<Booking> _completedBookings;
  late List<Booking> _cancelledBookings;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMockBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadMockBookings() {
    final now = DateTime.now();

    // Generate mock bookings using existing Booking model
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

      // Cancelled
      Booking(
        id: 4,
        nguoiDungId: 1,
        phongId: 104,
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

    // Filter bookings by status
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Profile Header
            ProfileHeader(user: _authService.currentUser),

            // Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  fontSize: 16,
                ),
                indicatorPadding: const EdgeInsets.all(4),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Đặt chỗ'),
                  Tab(text: 'Tài khoản'),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildBookingsTab(), _buildAccountTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingsTab() {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          // Booking Sub-tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TabBar(
              labelColor: const Color(0xFF2196F3),
              unselectedLabelColor: Colors.grey[600],
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              indicatorColor: const Color(0xFF2196F3),
              indicatorWeight: 3,
              tabs: [
                Tab(text: 'Sắp tới (${_upcomingBookings.length})'),
                Tab(text: 'Hoàn thành (${_completedBookings.length})'),
                Tab(text: 'Đã hủy (${_cancelledBookings.length})'),
              ],
            ),
          ),

          // Booking Lists
          Expanded(
            child: TabBarView(
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
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Không có đặt chỗ nào',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: BookingCard(
            booking: bookings[index],
            onTap: () => _showBookingDetail(bookings[index]),
          ),
        );
      },
    );
  }

  Widget _buildAccountTab() {
    return AccountMenu(authService: _authService, onLogout: _handleLogout);
  }

  void _showBookingDetail(Booking booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
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
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chi tiết đặt chỗ #${booking.id}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildDetailRow('Khách sạn', booking.tenKhachSan ?? ''),
                    _buildDetailRow(
                      'Phòng',
                      '${booking.tenLoaiPhong} - ${booking.soPhong}',
                    ),
                    _buildDetailRow(
                      'Nhận phòng',
                      _formatDate(booking.ngayNhanPhong),
                    ),
                    _buildDetailRow(
                      'Trả phòng',
                      _formatDate(booking.ngayTraPhong),
                    ),
                    _buildDetailRow(
                      'Số khách',
                      '${booking.soLuongKhach} người',
                    ),
                    _buildDetailRow(
                      'Tổng tiền',
                      _formatCurrency(booking.tongTien),
                    ),
                    _buildDetailRow(
                      'Trạng thái',
                      booking.getStatusDisplayName(),
                    ),

                    const SizedBox(height: 20),

                    if (booking.trangThai == BookingStatus.confirmed) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            // Handle cancel booking
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Hủy đặt chỗ'),
                        ),
                      ),
                    ],
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
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

  void _handleLogout() {
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }
}

// Extension for Booking model to add display methods
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

  Color getStatusColor() {
    switch (trangThai) {
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
}
