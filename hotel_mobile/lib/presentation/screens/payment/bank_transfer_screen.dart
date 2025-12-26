/**
 * Màn hình thanh toán chuyển khoản ngân hàng
 * Hiển thị QR code và thông tin chuyển khoản NATIVE (không dùng WebView)
 */

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:dio/dio.dart';
import 'package:hotel_mobile/data/models/hotel.dart';
import 'package:hotel_mobile/data/models/room.dart';
import 'package:hotel_mobile/core/constants/app_constants.dart';
import 'package:hotel_mobile/l10n/app_localizations.dart';
import 'package:hotel_mobile/presentation/screens/main_navigation_screen.dart';
import 'package:hotel_mobile/presentation/screens/payment/payment_success_screen_v2.dart';

class BankTransferScreen extends StatefulWidget {
  final String paymentUrl;
  final String orderId;
  final double amount;
  final Hotel hotel;
  final Room room;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int guestCount;
  final int nights;

  const BankTransferScreen({
    Key? key,
    required this.paymentUrl,
    required this.orderId,
    required this.amount,
    required this.hotel,
    required this.room,
    required this.checkInDate,
    required this.checkOutDate,
    required this.guestCount,
    required this.nights,
  }) : super(key: key);

  @override
  State<BankTransferScreen> createState() => _BankTransferScreenState();
}

class _BankTransferScreenState extends State<BankTransferScreen> {
  bool _isProcessing = false;
  Timer? _pollingTimer;
  Timer? _countdownTimer;
  int _remainingSeconds = 300; // 5 phút = 300 giây

  // Bank info
  final String bankName = 'Vietcombank';
  final String accountNumber = '1234567890';
  final String accountName = 'TRIPHOTEL VIP';

  @override
  void initState() {
    super.initState();
    print('🏦 Bank Transfer Screen initialized');
    print('📦 OrderId: ${widget.orderId}');
    print('💰 Amount: ${widget.amount}');
    
    // Start polling payment status
    _startPollingPaymentStatus();
    
    // Start countdown timer
    _startCountdownTimer();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdownTimer() {
    print('⏰ Starting 5-minute countdown timer...');
    
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _remainingSeconds--;
      });

      print('⏱️ Time remaining: $_remainingSeconds seconds');

      // Khi hết thời gian
      if (_remainingSeconds <= 0) {
        timer.cancel();
        _pollingTimer?.cancel();
        _showTimeoutDialog();
      }
    });
  }

  void _showTimeoutDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.timer_off, color: Colors.red, size: 32),
            const SizedBox(width: 12),
            Builder(
              builder: (context) => Text(AppLocalizations.of(context)!.paymentTimeoutTitle),
            ),
          ],
        ),
        content: const Text(
          'Thời gian thanh toán đã hết (5 phút). Vui lòng thử lại.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Đóng dialog
              Navigator.of(context).pop(); // Quay về màn hình trước
            },
            child: Text(AppLocalizations.of(context)!.close, style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _startPollingPaymentStatus() {
    print('🔄 Starting payment status polling...');
    
    // Poll every 3 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        print('🔍 Polling payment status for orderId: ${widget.orderId}');
        final dio = Dio();
        final response = await dio.get(
          '${AppConstants.baseUrl}/api/v2/bank-transfer/payment-status/${widget.orderId}',
        );

        if (response.statusCode == 200) {
          print('✅ Got response: ${response.data}');
          
          if (response.data['success'] == true) {
            final data = response.data['data'];
            final status = data['trang_thai'];

            print('📊 Payment status: $status');

            if (status == 'confirmed') {
              print('✅ Payment confirmed! Navigating to success screen...');
              timer.cancel();
              _navigateToSuccess();
            }
          }
        }
      } catch (e) {
        print('❌ Error polling payment status: $e');
      }
    });
  }

  void _handlePaymentConfirmation() async {
    print('🎉 User clicked "Tôi đã chuyển khoản" button');

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.confirmPayment),
        content: const Text(
          'Bạn đã hoàn tất chuyển khoản?\n\n'
          'Vui lòng chắc chắn rằng bạn đã chuyển đúng số tiền và nội dung.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.notPaid),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocalizations.of(context)!.paid),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() {
        _isProcessing = true;
      });

      try {
        // Call backend to confirm payment
        final dio = Dio();
        final response = await dio.post(
          '${AppConstants.baseUrl}/api/bank-transfer/return',
          data: {
            'orderId': widget.orderId,
            'success': 'true',
          },
        );

        print('📡 Confirm response: ${response.data}');

        if (response.statusCode == 200 && mounted) {
          _navigateToSuccess();
        }
      } catch (e) {
        print('❌ Error confirming payment: $e');
        
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.errorOccurred),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _navigateToSuccess() {
    if (!mounted) return;

    _pollingTimer?.cancel();
    _countdownTimer?.cancel();

    // Navigate to success screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => PaymentSuccessScreenV2(
          orderId: widget.orderId,
          paymentMethod: 'bank_transfer',
        ),
      ),
    );
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.copied(label)),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  @override
  Widget build(BuildContext context) {
    // Generate VietQR link
    final qrContent = 'https://img.vietqr.io/image/$bankName-$accountNumber-compact2.jpg'
        '?amount=${widget.amount.toInt()}'
        '&addInfo=${Uri.encodeComponent(widget.orderId)}';

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.bankTransfer),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isProcessing
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Builder(
                    builder: (context) => Text(AppLocalizations.of(context)!.processingPayment),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.qr_code_2,
                          size: 48,
                          color: Colors.blue,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Quét mã QR để thanh toán',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Số tiền: ${_formatCurrency(widget.amount)} đ',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Countdown Timer
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _remainingSeconds <= 60
                                ? Colors.red.shade100
                                : Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.timer,
                                size: 20,
                                color: _remainingSeconds <= 60
                                    ? Colors.red
                                    : Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Thời gian còn lại: ${_formatTime(_remainingSeconds)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: _remainingSeconds <= 60
                                      ? Colors.red
                                      : Colors.orange.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Warning banner khi còn dưới 1 phút
                  if (_remainingSeconds <= 60)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        border: Border.all(color: Colors.red, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.red,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Sắp hết thời gian!',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Vui lòng hoàn tất thanh toán trong ${_formatTime(_remainingSeconds)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.red.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // QR Code
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade300,
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: qrContent,
                        version: QrVersions.auto,
                        size: 250.0,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Bank info card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Thông tin chuyển khoản',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(height: 24),
                          _buildInfoRow(
                            icon: Icons.account_balance,
                            label: 'Ngân hàng',
                            value: bankName,
                            onCopy: () => _copyToClipboard(bankName, 'tên ngân hàng'),
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            icon: Icons.credit_card,
                            label: 'Số tài khoản',
                            value: accountNumber,
                            onCopy: () => _copyToClipboard(accountNumber, 'số tài khoản'),
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            icon: Icons.person,
                            label: 'Chủ tài khoản',
                            value: accountName,
                            onCopy: () => _copyToClipboard(accountName, 'tên chủ TK'),
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            icon: Icons.attach_money,
                            label: 'Số tiền',
                            value: '${_formatCurrency(widget.amount)} đ',
                            onCopy: () =>
                                _copyToClipboard(widget.amount.toInt().toString(), 'số tiền'),
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            icon: Icons.description,
                            label: 'Nội dung CK',
                            value: widget.orderId,
                            onCopy: () => _copyToClipboard(widget.orderId, 'nội dung'),
                            isImportant: true,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Important note
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.orange.shade700),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            '⚠️ Lưu ý:\n'
                            '• Thời gian thanh toán: 5 phút\n'
                            '• Chuyển ĐÚNG nội dung để xác nhận tự động\n'
                            '• Sau khi chuyển khoản, nhấn "Tôi đã chuyển khoản"',
                            style: TextStyle(fontSize: 13, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Confirm button
                  ElevatedButton(
                    onPressed: _isProcessing ? null : _handlePaymentConfirmation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Tôi đã chuyển khoản',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Cancel button
                  OutlinedButton(
                    onPressed: _isProcessing
                        ? null
                        : () {
                            _pollingTimer?.cancel();
                            Navigator.of(context).pop();
                          },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Hủy',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onCopy,
    bool isImportant = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isImportant ? FontWeight.bold : FontWeight.w500,
                  color: isImportant ? Colors.red : Colors.black,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy, size: 20),
          onPressed: onCopy,
          tooltip: 'Sao chép',
          color: Colors.blue,
        ),
      ],
    );
  }
}
