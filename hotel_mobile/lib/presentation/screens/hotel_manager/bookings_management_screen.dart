import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/services/hotel_manager_service.dart';
import '../../../data/models/hotel_manager_models.dart';
import '../../../data/services/message_service.dart';
import '../chat/modern_conversation_list_screen.dart';

class BookingsManagementScreen extends StatefulWidget {
  final HotelManagerService hotelManagerService;

  const BookingsManagementScreen({
    super.key,
    required this.hotelManagerService,
  });

  @override
  State<BookingsManagementScreen> createState() => _BookingsManagementScreenState();
}

class _BookingsManagementScreenState extends State<BookingsManagementScreen> {
  List<Booking> _bookings = [];
  bool _isLoading = true;
  String? _error;
  String _selectedStatus = 'all';
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings({bool refresh = false}) async {
    try {
      setState(() {
        if (refresh) {
          _currentPage = 1;
          _hasMore = true;
        }
        _isLoading = refresh || _bookings.isEmpty;
        _error = null;
      });

      final result = await widget.hotelManagerService.getHotelBookings(
        status: _selectedStatus == 'all' ? null : _selectedStatus,
        page: _currentPage,
        limit: 20,
      );

      setState(() {
        if (refresh) {
          _bookings = result['bookings'].map<Booking>((data) => Booking.fromJson(data)).toList();
        } else {
          _bookings.addAll(result['bookings'].map<Booking>((data) => Booking.fromJson(data)));
        }
        
        _hasMore = result['bookings'].length >= 20;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý đặt phòng'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadBookings(refresh: true),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatusFilter(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildStatusChip('all', 'Tất cả'),
            const SizedBox(width: 8),
            _buildStatusChip('pending', 'Chờ xác nhận'),
            const SizedBox(width: 8),
            _buildStatusChip('confirmed', 'Đã xác nhận'),
            const SizedBox(width: 8),
            _buildStatusChip('completed', 'Hoàn thành'),
            const SizedBox(width: 8),
            _buildStatusChip('cancelled', 'Đã hủy'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status, String label) {
    final isSelected = _selectedStatus == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = status;
        });
        _loadBookings(refresh: true);
      },
      selectedColor: Colors.blue[100],
      checkmarkColor: Colors.blue[700],
    );
  }

  Widget _buildBody() {
    if (_isLoading && _bookings.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text('Lỗi: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadBookings(refresh: true),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book_online_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Chưa có đặt phòng nào',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadBookings(refresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _bookings.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _bookings.length) {
            return _buildLoadMoreButton();
          }
          return _buildBookingCard(_bookings[index]);
        },
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ElevatedButton(
          onPressed: _isLoading ? null : _loadMore,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Tải thêm'),
        ),
      ),
    );
  }

  Future<void> _loadMore() async {
    setState(() {
      _currentPage++;
    });
    await _loadBookings();
  }

  Widget _buildBookingCard(Booking booking) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
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
                        'Phòng ${booking.soPhong}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        booking.tenKhachHang,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(booking.trangThai),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(booking.trangThai),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${_formatDate(booking.ngayNhanPhong)} - ${_formatDate(booking.ngayTraPhong)}'),
                const SizedBox(width: 16),
                Icon(Icons.nights_stay, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${booking.soDemLuuTru} đêm'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(booking.emailKhachHang),
                const SizedBox(width: 16),
                Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(booking.sdtKhachHang),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${_formatCurrency(booking.tongTien)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(booking.ngayTao),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (_canUpdateStatus(booking.trangThai))
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showStatusUpdateDialog(booking),
                      child: const Text('Cập nhật trạng thái'),
                    ),
                  ),
                if (_canUpdateStatus(booking.trangThai))
                  const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _contactCustomer(booking),
                    icon: const Icon(Icons.chat, size: 18),
                    label: const Text('Liên hệ khách hàng'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'in_progress':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Chờ xác nhận';
      case 'confirmed':
        return 'Đã xác nhận';
      case 'in_progress':
        return 'Đang diễn ra';
      case 'completed':
        return 'Hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  bool _canUpdateStatus(String status) {
    // Cho phép update status từ pending, confirmed, hoặc in_progress
    return status == 'pending' || status == 'confirmed' || status == 'in_progress';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}đ';
  }

  void _showStatusUpdateDialog(Booking booking) {
    final statusOptions = [
      {'value': 'confirmed', 'label': 'Xác nhận'},
      {'value': 'completed', 'label': 'Hoàn thành'},
      {'value': 'cancelled', 'label': 'Hủy'},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cập nhật trạng thái'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: statusOptions.map((option) {
            return ListTile(
              title: Text(option['label']!),
              onTap: () {
                Navigator.of(context).pop();
                _updateBookingStatus(booking, option['value']!);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _updateBookingStatus(Booking booking, String newStatus) async {
    try {
      await widget.hotelManagerService.updateBookingStatus(booking.maPhieuDat, newStatus);
      _loadBookings(refresh: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã cập nhật trạng thái đặt phòng'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Liên hệ với khách hàng qua chat
  Future<void> _contactCustomer(Booking booking) async {
    try {
      // Show loading
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final messageService = MessageService();
      
      print('📱 Attempting to create conversation with customer: ${booking.emailKhachHang}');
      
      // Check if customer has Firebase UID mapping
      // If not, show error dialog
      await messageService.createConversationWithCustomer(
        customerEmail: booking.emailKhachHang,
        customerName: booking.tenKhachHang,
        bookingCode: booking.maPhieuDat,
      );
      
      print('✅ Conversation created successfully');

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Navigate to conversation list
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ModernConversationListScreen(),
          ),
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã tạo cuộc trò chuyện với khách hàng'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) Navigator.of(context).pop();
      
      if (mounted) {
        String errorMessage = 'Không thể tạo cuộc trò chuyện trong app';
        String detailMessage = 'Khách hàng chưa đăng nhập ứng dụng.';
        
        if (e.toString().contains('chưa có trên hệ thống chat')) {
          detailMessage = 'Khách hàng chưa đăng nhập ứng dụng.\nHãy sử dụng các phương thức liên hệ khác bên dưới.';
        }
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('⚠️ Không thể chat trong app'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(detailMessage),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Thông tin liên hệ:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(booking.tenKhachHang),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.email, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        booking.emailKhachHang,
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.phone, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(booking.sdtKhachHang),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              // Copy email
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: booking.emailKhachHang));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã copy email'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copy Email'),
              ),
              // Call phone
              TextButton.icon(
                onPressed: () async {
                  final phone = booking.sdtKhachHang.replaceAll(RegExp(r'[^0-9+]'), '');
                  final uri = Uri.parse('tel:$phone');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
                icon: const Icon(Icons.phone, size: 18),
                label: const Text('Gọi điện'),
              ),
              // Close
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Đóng'),
              ),
            ],
          ),
        );
      }
    }
  }
}
