import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hotel_mobile/data/models/hotel.dart';
import 'package:hotel_mobile/data/models/room.dart';
import 'package:hotel_mobile/data/services/payment_service.dart';
import 'package:hotel_mobile/presentation/widgets/payment/order_summary_card.dart';
import 'package:hotel_mobile/presentation/widgets/payment/price_breakdown_card.dart';
import 'package:hotel_mobile/presentation/widgets/payment/guest_details_form.dart';
import 'package:hotel_mobile/presentation/widgets/payment/payment_options.dart';
import 'package:hotel_mobile/presentation/widgets/payment/security_info.dart';
import 'package:hotel_mobile/presentation/widgets/payment/payment_bottom_bar.dart';
import 'package:hotel_mobile/presentation/screens/booking/booking_history_screen.dart';
import 'package:hotel_mobile/presentation/screens/payment/payment_success_screen.dart';

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
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final GlobalKey<State<GuestDetailsForm>> _guestFormKey = GlobalKey<State<GuestDetailsForm>>();

  PaymentMethod _selectedPaymentMethod = PaymentMethod.creditCard;
  bool _isProcessing = false;
  final PaymentService _paymentService = PaymentService();

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
                    key: _guestFormKey,
                    nameController: _nameController,
                    emailController: _emailController,
                    phoneController: _phoneController,
                  ),

                  const SizedBox(height: 16),

                  // Payment Options
                  PaymentOptions(
                    selectedMethod: _selectedPaymentMethod,
                    onMethodChanged: (method) {
                      if (mounted) {
                        setState(() {
                          _selectedPaymentMethod = method;
                        });
                      }
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
    if (!mounted) return;
    
    // Validate guest details form
    final guestFormState = _guestFormKey.currentState;
    if (guestFormState == null || !(guestFormState as dynamic).validateForm()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng điền đầy đủ thông tin'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isProcessing = true;
      });
    }

    try {
      // Convert PaymentMethod to PaymentProvider
      PaymentProvider provider = _convertToPaymentProvider(_selectedPaymentMethod);
      
      // Process payment
      final result = await _paymentService.processPayment(
        provider: provider,
        amount: _finalTotal,
        orderId: 'ORDER_${DateTime.now().millisecondsSinceEpoch}',
        description: 'Đặt phòng ${widget.room.tenLoaiPhong} tại ${widget.hotel.ten}',
        additionalData: {
          'hotel_id': widget.hotel.id,
          'room_id': widget.room.id,
          'check_in': widget.checkInDate.toIso8601String(),
          'check_out': widget.checkOutDate.toIso8601String(),
          'guest_count': widget.guestCount,
        },
      );

      if (mounted) {
        if (result.success) {
          // Navigate to success screen safely with post frame callback
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => PaymentSuccessScreen(
                    hotel: widget.hotel,
                    room: widget.room,
                    checkInDate: widget.checkInDate,
                    checkOutDate: widget.checkOutDate,
                    guestCount: widget.guestCount,
                    nights: widget.nights,
                    totalAmount: _finalTotal,
                    orderId: 'ORDER_${DateTime.now().millisecondsSinceEpoch}',
                  ),
                ),
              );
            }
          });
        } else {
          _showPaymentErrorDialog(result.message);
        }
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

  PaymentProvider _convertToPaymentProvider(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.creditCard:
        return PaymentProvider.creditCard;
      case PaymentMethod.eWallet:
        return PaymentProvider.eWallet;
      case PaymentMethod.hotelPayment:
        return PaymentProvider.hotelPayment;
      case PaymentMethod.vnpay:
        return PaymentProvider.vnpay;
      case PaymentMethod.vietqr:
        return PaymentProvider.vietqr;
    }
  }

  void _showPaymentErrorDialog(String errorMessage) {
    if (!mounted) return;
    
    // Use a delayed call to ensure the widget tree is stable
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error, color: Colors.red, size: 28),
                SizedBox(width: 12),
                Text('Thanh toán thất bại'),
              ],
            ),
            content: Text(errorMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Đóng'),
              ),
            ],
          ),
        );
      }
    });
  }
}