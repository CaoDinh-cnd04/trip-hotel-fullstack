import 'package:flutter/material.dart';
import 'package:hotel_mobile/data/models/hotel.dart';
import 'package:hotel_mobile/data/models/room.dart';
import 'package:hotel_mobile/presentation/widgets/payment/order_summary_card.dart';
import 'package:hotel_mobile/presentation/widgets/payment/price_breakdown_card.dart';
import 'package:hotel_mobile/presentation/widgets/payment/guest_details_form.dart';
import 'package:hotel_mobile/presentation/widgets/payment/payment_options.dart';
import 'package:hotel_mobile/presentation/widgets/payment/security_info.dart';
import 'package:hotel_mobile/presentation/widgets/payment/payment_bottom_bar.dart';

class PaymentScreen extends StatefulWidget {
  final Hotel hotel;
  final Room room;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int guestCount;
  final int nights;
  final double roomPrice;
  final double? discount;

  const PaymentScreen({
    super.key,
    required this.hotel,
    required this.room,
    required this.checkInDate,
    required this.checkOutDate,
    required this.guestCount,
    required this.nights,
    required this.roomPrice,
    this.discount,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  PaymentMethod _selectedPaymentMethod = PaymentMethod.creditCard;
  bool _isProcessing = false;

  // Price calculations
  double get _basePrice => widget.roomPrice * widget.nights;
  double get _serviceFeeByCurrency => _basePrice * 0.05; // 5% service fee
  double get _discountAmount => widget.discount ?? 0;
  double get _finalTotal =>
      _basePrice + _serviceFeeByCurrency - _discountAmount;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Thanh toán'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order Summary
                    OrderSummaryCard(
                      hotel: widget.hotel,
                      room: widget.room,
                      checkInDate: widget.checkInDate,
                      checkOutDate: widget.checkOutDate,
                      guestCount: widget.guestCount,
                      nights: widget.nights,
                    ),

                    const SizedBox(height: 16),

                    // Price Breakdown
                    PriceBreakdownCard(
                      basePrice: _basePrice,
                      serviceFeeByCurrency: _serviceFeeByCurrency,
                      discountAmount: _discountAmount,
                      finalTotal: _finalTotal,
                      nights: widget.nights,
                    ),

                    const SizedBox(height: 16),

                    // Guest Details
                    GuestDetailsForm(
                      nameController: _nameController,
                      emailController: _emailController,
                      phoneController: _phoneController,
                      formKey: _formKey,
                    ),

                    const SizedBox(height: 16),

                    // Payment Options
                    PaymentOptions(
                      selectedMethod: _selectedPaymentMethod,
                      onMethodChanged: (method) {
                        setState(() {
                          _selectedPaymentMethod = method;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // Security Info
                    const SecurityInfo(),

                    const SizedBox(height: 100), // Space for bottom bar
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: PaymentBottomBar(
        totalPrice: _finalTotal,
        onPaymentPressed: _processPayment,
        isLoading: _isProcessing,
      ),
    );
  }

  void _processPayment() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng điền đầy đủ thông tin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                SizedBox(width: 12),
                Text('Thanh toán thành công!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đã đặt phòng ${widget.room.tenLoaiPhong} tại ${widget.hotel.ten}',
                ),
                const SizedBox(height: 8),
                Text('Tổng tiền: ${_formatCurrency(_finalTotal)}'),
                const SizedBox(height: 8),
                const Text('Thông tin xác nhận đã được gửi qua email.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(
                    context,
                  ).popUntil((route) => route.isFirst); // Back to home
                },
                child: const Text('Đóng'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  // Navigate to booking detail
                  _navigateToBookingDetail();
                },
                child: const Text('Xem đặt chỗ'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi thanh toán: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _navigateToBookingDetail() {
    // Navigate to booking detail screen
    // Implementation depends on your app structure
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} VNĐ';
  }
}
