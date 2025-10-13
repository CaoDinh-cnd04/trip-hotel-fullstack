import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hotel_mobile/data/models/booking.dart';
import 'package:hotel_mobile/data/models/room.dart';
import 'package:hotel_mobile/data/models/hotel.dart';
import 'package:hotel_mobile/data/services/api_service.dart';
import 'package:hotel_mobile/data/services/auth_service.dart';

class BookingFormScreen extends StatefulWidget {
  final Room room;
  final Hotel? hotel;

  const BookingFormScreen({super.key, required this.room, this.hotel});

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _guestCountController;
  late final TextEditingController _notesController;

  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  bool _isLoading = false;
  double _totalPrice = 0;

  @override
  void initState() {
    super.initState();
    _apiService.initialize();

    _guestCountController = TextEditingController(text: '1');
    _notesController = TextEditingController();

    // Set default dates
    _checkInDate = DateTime.now().add(const Duration(days: 1));
    _checkOutDate = DateTime.now().add(const Duration(days: 2));

    _calculateTotalPrice();
  }

  @override
  void dispose() {
    _guestCountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _calculateTotalPrice() {
    if (_checkInDate != null &&
        _checkOutDate != null &&
        widget.room.giaPhong != null) {
      int nights = _checkOutDate!.difference(_checkInDate!).inDays;
      if (nights < 1) nights = 1; // đảm bảo tối thiểu 1 đêm
      setState(() {
        _totalPrice = widget.room.giaPhong! * nights;
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isCheckIn) async {
    final initialDate = isCheckIn
        ? (_checkInDate ?? DateTime.now().add(const Duration(days: 1)))
        : (_checkOutDate ?? DateTime.now().add(const Duration(days: 2)));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkInDate = picked;
          // If check-out is before or same as check-in, adjust it
          if (_checkOutDate != null &&
              (_checkOutDate!.isBefore(picked) ||
                  _checkOutDate!.isAtSameMomentAs(picked))) {
            _checkOutDate = picked.add(const Duration(days: 1));
          }
        } else {
          _checkOutDate = picked;
        }
      });
      _calculateTotalPrice();
    }
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_checkInDate == null || _checkOutDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ngày nhận và trả phòng')),
      );
      return;
    }

    if (_checkOutDate!.isBefore(_checkInDate!) ||
        _checkOutDate!.isAtSameMomentAs(_checkInDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ngày trả phòng phải sau ngày nhận phòng'),
        ),
      );
      return;
    }

    // Check if user is logged in
    final isLoggedIn = await _authService.isSignedIn();
    // Nếu AuthService (demo) chưa đăng nhập, thử đọc Firebase user
    final bool isFirebaseLoggedIn = FirebaseAuth.instance.currentUser != null;
    if (!isLoggedIn && !isFirebaseLoggedIn) {
      final snackBar = SnackBar(
        content: const Text('Vui lòng đăng nhập để tiếp tục thanh toán'),
        action: SnackBarAction(
          label: 'Đăng nhập',
          onPressed: () {
            Navigator.pushNamed(context, '/login');
          },
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      return;
    }

    final currentUser = _authService.currentUser;
    if ((currentUser?.id == null) && !isFirebaseLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể xác định thông tin người dùng'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final booking = Booking(
        nguoiDungId: currentUser!.id!,
        phongId: widget.room.id!,
        ngayNhanPhong: _checkInDate!,
        ngayTraPhong: _checkOutDate!,
        soLuongKhach: int.parse(_guestCountController.text),
        tongTien: _totalPrice,
        trangThai: BookingStatus.pending,
        ghiChu: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        ngayTao: DateTime.now(),
      );

      final response = await _apiService.createBooking(booking);

      if (response.success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đặt phòng thành công!')));
        Navigator.of(context).pop(true);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi đặt phòng: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặt phòng'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Room Info Card
            _buildRoomInfoCard(),
            const SizedBox(height: 16),

            // Check-in Date
            _buildDateSelector(
              title: 'Ngày nhận phòng',
              date: _checkInDate,
              onTap: () => _selectDate(context, true),
            ),
            const SizedBox(height: 16),

            // Check-out Date
            _buildDateSelector(
              title: 'Ngày trả phòng',
              date: _checkOutDate,
              onTap: () => _selectDate(context, false),
            ),
            const SizedBox(height: 16),

            // Guest Count
            TextFormField(
              controller: _guestCountController,
              decoration: const InputDecoration(
                labelText: 'Số lượng khách',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.people),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập số lượng khách';
                }
                final count = int.tryParse(value.trim());
                if (count == null || count <= 0) {
                  return 'Số lượng khách phải lớn hơn 0';
                }
                if (widget.room.sucChua != null &&
                    count > widget.room.sucChua!) {
                  return 'Số lượng khách vượt quá sức chứa phòng (${widget.room.sucChua})';
                }
                return null;
              },
              onChanged: (value) {
                // không làm gì với giá ở đây (giá phụ thuộc số đêm)
              },
            ),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Ghi chú (tùy chọn)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
                hintText: 'Yêu cầu đặc biệt, ghi chú cho khách sạn...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Price Summary
            _buildPriceSummary(),
            const SizedBox(height: 24),

            // Book Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Xác nhận đặt phòng',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Room Image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[300],
                  ),
                  child: widget.room.hinhAnhPhong?.isNotEmpty == true
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            widget.room.hinhAnhPhong!.first,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.bed, size: 40),
                          ),
                        )
                      : const Icon(Icons.bed, size: 40),
                ),
                const SizedBox(width: 12),
                // Room Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Phòng ${widget.room.soPhong}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.room.tenLoaiPhong != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.room.tenLoaiPhong!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                      if (widget.room.giaPhong != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${widget.room.formattedPrice}/đêm',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (widget.hotel?.ten != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.hotel, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    widget.hotel!.ten,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ],
            if (widget.room.sucChua != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.people, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Sức chứa: ${widget.room.capacityText}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector({
    required String title,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.calendar_today),
        title: Text(title),
        subtitle: Text(date != null ? _formatDate(date) : 'Chọn ngày'),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  Widget _buildPriceSummary() {
    if (_checkInDate == null ||
        _checkOutDate == null ||
        widget.room.giaPhong == null) {
      return const SizedBox.shrink();
    }

    final nights = _checkOutDate!.difference(_checkInDate!).inDays;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tóm tắt giá',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${widget.room.formattedPrice} × $nights đêm'),
                Text(
                  _formatPrice(_totalPrice),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tổng cộng',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  _formatPrice(_totalPrice),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatPrice(double price) {
    return '${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} VNĐ';
  }
}
