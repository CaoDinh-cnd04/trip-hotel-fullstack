import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hotel_mobile/data/services/api_service.dart';
import 'package:hotel_mobile/core/constants/app_constants.dart';
import 'package:hotel_mobile/core/utils/currency_formatter.dart';
import 'package:hotel_mobile/core/theme/vip_theme_provider.dart';
import 'package:hotel_mobile/presentation/screens/main_navigation_screen.dart';
import 'package:hotel_mobile/presentation/screens/booking/booking_history_screen.dart';
import 'package:hotel_mobile/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

/// Màn hình thành công sau khi thanh toán
/// Hiển thị thông báo giao dịch thành công và thông tin đặt phòng
class PaymentSuccessScreenV2 extends StatefulWidget {
  final String orderId;
  final String paymentMethod; // 'vnpay', 'bank_transfer', 'cash'
  
  const PaymentSuccessScreenV2({
    super.key,
    required this.orderId,
    required this.paymentMethod,
  });

  @override
  State<PaymentSuccessScreenV2> createState() => _PaymentSuccessScreenV2State();
}

class _PaymentSuccessScreenV2State extends State<PaymentSuccessScreenV2> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _bookingData;
  Map<String, dynamic>? _paymentData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBookingInfo();
  }

  Future<void> _loadBookingInfo() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final response = await _apiService.get(
        '/api/v2/payment/booking-info/${widget.orderId}',
      );

      if (response.success && response.data != null) {
        setState(() {
          _paymentData = response.data['payment'];
          _bookingData = response.data['booking'];
          _isLoading = false;
        });
        
        // ✅ Refresh VIP theme sau khi thanh toán thành công (có thể tích điểm và lên hạng)
        if (mounted) {
          final vipThemeProvider = Provider.of<VipThemeProvider>(context, listen: false);
          vipThemeProvider.refreshVipLevel();
          print('✅ Refreshed VIP theme after successful payment');
        }
      } else {
        setState(() {
          _errorMessage = response.message ?? 'Không thể tải thông tin đặt phòng';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi kết nối: $e';
        _isLoading = false;
      });
    }
  }

  String _getPaymentMethodName(String method) {
    switch (method) {
      case 'vnpay':
        return 'VNPay';
      case 'bank_transfer':
        return 'Chuyển khoản ngân hàng';
      case 'cash':
        return 'Tiền mặt';
      default:
        return method;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Thanh toán thành công',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _errorMessage != null
              ? _buildErrorView()
              : _buildSuccessView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Đã xảy ra lỗi',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadBookingInfo,
              child: Text(AppLocalizations.of(context)!.tryAgain),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const MainNavigationScreen(),
                  ),
                  (route) => false,
                );
              },
              child: Text(AppLocalizations.of(context)!.backToHome),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    final booking = _bookingData;
    final payment = _paymentData;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Success Icon & Message
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.green[300]!,
                      width: 3,
                    ),
                  ),
                  child: Icon(
                    Icons.check_circle,
                    size: 70,
                    color: Colors.green[600],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '🎉 Giao dịch thành công!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Đặt phòng của bạn đã được xác nhận',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Booking Information Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.receipt_long, color: Colors.blue[600], size: 24),
                    const SizedBox(width: 12),
                    const Text(
                      'Thông tin đặt phòng',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),
                
                // Booking Details
                if (booking != null) ...[
                  _buildInfoRow('Mã đặt phòng', booking['bookingCode'] ?? widget.orderId),
                  _buildInfoRow('Khách sạn', booking['hotelName'] ?? 'N/A'),
                  _buildInfoRow('Loại phòng', booking['roomType'] ?? 'N/A'),
                  if (booking['roomNumber'] != null)
                    _buildInfoRow('Số phòng', booking['roomNumber']),
                  _buildInfoRow('Ngày nhận phòng', _formatDate(booking['checkInDate']?.toString())),
                  _buildInfoRow('Ngày trả phòng', _formatDate(booking['checkOutDate']?.toString())),
                  _buildInfoRow('Số đêm', '${booking['nights'] ?? 0} đêm'),
                  _buildInfoRow('Số khách', '${booking['guestCount'] ?? 1} khách'),
                ] else ...[
                  _buildInfoRow('Mã đơn hàng', widget.orderId),
                ],
                
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                
                // Payment Details
                if (payment != null) ...[
                  _buildInfoRow('Phương thức thanh toán', _getPaymentMethodName(payment['paymentMethod'] ?? widget.paymentMethod)),
                  if (payment['transactionNo'] != null)
                    _buildInfoRow('Mã giao dịch', payment['transactionNo']),
                  if (payment['payDate'] != null)
                    _buildInfoRow('Thời gian thanh toán', _formatDate(payment['payDate']?.toString())),
                ],
                
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                
                // Total Amount
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tổng tiền',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      payment != null && payment['amount'] != null
                          ? CurrencyFormatter.formatVND(payment['amount'].toDouble())
                          : booking != null && booking['finalPrice'] != null
                              ? CurrencyFormatter.formatVND(booking['finalPrice'].toDouble())
                              : 'N/A',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Important Notes
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Thông tin quan trọng',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '• Email xác nhận đã được gửi đến địa chỉ email của bạn\n'
                  '• Vui lòng mang theo CMND/CCCD khi nhận phòng\n'
                  '• Thời gian check-in: 14:00 - 22:00\n'
                  '• Thời gian check-out: 06:00 - 12:00',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue[700],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Action Buttons
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const BookingHistoryScreen(),
                      ),
                      (route) => route.isFirst,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Xem lịch sử đặt phòng',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const MainNavigationScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue[600],
                    side: BorderSide(color: Colors.blue[600]!, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Quay lại trang chủ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

