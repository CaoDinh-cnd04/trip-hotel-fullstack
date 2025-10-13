import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../../data/models/booking.dart';
import 'widgets/voucher_header.dart';
import 'widgets/booking_details_card.dart';
import 'widgets/qr_code_section.dart';
import 'widgets/policy_section.dart';
import 'widgets/voucher_actions.dart';

class BookingVoucherScreen extends StatefulWidget {
  final Booking booking;

  const BookingVoucherScreen({Key? key, required this.booking})
    : super(key: key);

  @override
  State<BookingVoucherScreen> createState() => _BookingVoucherScreenState();
}

class _BookingVoucherScreenState extends State<BookingVoucherScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _contactHotel() async {
    // Mock phone number - in real app, this would come from hotel data
    const phoneNumber = '1900-1234';
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _downloadVoucherPdf() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Mock PDF generation - in real app, this would generate actual PDF
      await Future.delayed(const Duration(seconds: 2));

      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              const Text('Voucher PDF đã được tải xuống'),
            ],
          ),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải PDF: ${e.toString()}'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _shareVoucher() async {
    final booking = widget.booking;

    final shareText =
        '''
🏨 Voucher Đặt Phòng

📍 ${booking.tenKhachSan}
📅 ${DateFormat('dd/MM/yyyy').format(booking.ngayNhanPhong)} - ${DateFormat('dd/MM/yyyy').format(booking.ngayTraPhong)}
👥 ${booking.soLuongKhach} khách
💰 ${NumberFormat.currency(locale: 'vi_VN', symbol: '').format(booking.tongTien)} VND

🔢 Mã xác nhận: ${booking.id}
📱 App Hotel Booking
    ''';

    await Share.share(shareText);
  }

  Future<void> _copyConfirmationCode() async {
    await Clipboard.setData(ClipboardData(text: widget.booking.id.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.copy, color: Colors.white),
            SizedBox(width: 12),
            Text('Đã sao chép mã xác nhận'),
          ],
        ),
        backgroundColor: Colors.blue[600],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Chi tiết Voucher',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            onPressed: _shareVoucher,
            icon: const Icon(Icons.share),
            tooltip: 'Chia sẻ voucher',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Voucher Header
                VoucherHeader(booking: widget.booking),

                const SizedBox(height: 20),

                // QR Code Section
                QRCodeSection(
                  booking: widget.booking,
                  onCopyCode: _copyConfirmationCode,
                ),

                const SizedBox(height: 20),

                // Booking Details
                BookingDetailsCard(booking: widget.booking),

                const SizedBox(height: 20),

                // Policy Section
                PolicySection(booking: widget.booking),

                const SizedBox(height: 20),

                // Action Buttons
                VoucherActions(
                  booking: widget.booking,
                  onContactHotel: _contactHotel,
                  onDownloadPdf: _downloadVoucherPdf,
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
