import 'package:flutter/material.dart';
import 'package:hotel_mobile/data/models/hotel.dart';
import 'package:hotel_mobile/data/models/room.dart';
import 'package:hotel_mobile/data/services/payment_service.dart';
import 'package:hotel_mobile/data/services/backend_auth_service.dart';
import 'package:hotel_mobile/data/services/booking_history_service.dart';
import 'package:hotel_mobile/data/services/message_service.dart';
import 'package:hotel_mobile/presentation/widgets/payment/order_summary_card.dart';
import 'package:hotel_mobile/presentation/widgets/payment/price_breakdown_card.dart';
import 'package:hotel_mobile/presentation/widgets/payment/guest_details_form.dart';
import 'package:hotel_mobile/presentation/widgets/payment/payment_options.dart';
import 'package:hotel_mobile/presentation/widgets/payment/payment_bottom_bar.dart';
import 'package:hotel_mobile/presentation/widgets/payment/discount_code_input.dart';
import 'package:hotel_mobile/presentation/screens/payment/payment_success_screen.dart';
import 'package:hotel_mobile/presentation/screens/payment/vnpay_payment_screen.dart';
import 'package:hotel_mobile/presentation/screens/payment/vnpay_qr_payment_screen.dart';
import 'package:hotel_mobile/presentation/screens/payment/momo_payment_screen.dart';

/// Màn hình thanh toán đặt phòng
/// 
/// Cho phép người dùng:
/// - Xem tóm tắt đơn hàng (hotel, room, dates, nights, guests)
/// - Xem chi tiết giá (room price, service fee, discount, total)
/// - Điền thông tin khách (name, email, phone) - auto-fill nếu đã đăng nhập
/// - Chọn phương thức thanh toán (Credit Card, Bank Transfer, E-Wallet, Cash)
/// - Xác nhận và thanh toán
/// 
/// Luồng xử lý:
/// 1. Load thông tin user nếu đã đăng nhập
/// 2. User điền/xác nhận thông tin
/// 3. Chọn payment method
/// 4. Click "Thanh toán"
/// 5. Gọi API tạo booking
/// 6. Navigate đến PaymentSuccessScreen hoặc hiển thị lỗi
class PaymentScreen extends StatefulWidget {
  /// Thông tin khách sạn được chọn
  final Hotel hotel;
  
  /// Thông tin phòng được chọn
  final Room room;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  /// Số lượng khách
  final int guestCount;
  /// Số đêm lưu trú
  final int nights;
  /// Giá phòng mỗi đêm
  final double roomPrice;
  /// Số tiền giảm giá (nếu có)
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
  /// Controller cho trường tên khách
  final _nameController = TextEditingController();
  
  /// Controller cho trường email
  final _emailController = TextEditingController();
  
  /// Controller cho trường số điện thoại
  final _phoneController = TextEditingController();
  
  /// Key để validate form thông tin khách
  final GlobalKey<State<GuestDetailsForm>> _guestFormKey = GlobalKey<State<GuestDetailsForm>>();

  /// Phương thức thanh toán được chọn (mặc định: MoMo)
  PaymentMethod _selectedPaymentMethod = PaymentMethod.momo;
  
  /// Trạng thái đang xử lý thanh toán
  bool _isProcessing = false;
  
  /// Service xử lý thanh toán
  final PaymentService _paymentService = PaymentService();
  
  /// Service authentication
  final BackendAuthService _authService = BackendAuthService();
  
  /// Service booking
  final BookingHistoryService _bookingService = BookingHistoryService();
  
  /// Trạng thái user đã đăng nhập
  bool _isLoggedIn = false;
  
  /// Mã giảm giá đã áp dụng
  String? _appliedDiscountCode;
  
  /// Số tiền giảm giá từ mã
  double _discountFromCode = 0;
  

  // Các getter tính toán giá
  
  /// Giá cơ bản (roomPrice * nights)
  double get _basePrice => widget.roomPrice * widget.nights;
  
  /// Phí dịch vụ 5% (service fee)
  double get _serviceFeeByCurrency => _basePrice * 0.05;
  
  /// Số tiền giảm giá (từ widget.discount + mã giảm giá)
  double get _discountAmount => (widget.discount ?? 0) + _discountFromCode;
  
  /// Tổng tiền cuối cùng (base + service - discount)
  double get _finalTotal =>
      _basePrice + _serviceFeeByCurrency - _discountAmount;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Tải thông tin user nếu đã đăng nhập
  /// 
  /// Tự động điền vào form:
  /// - Họ tên
  /// - Email
  /// - Số điện thoại
  void _loadUserInfo() async {
    // Kiểm tra xem user đã đăng nhập chưa
    final user = _authService.currentUser;
    if (user != null && _authService.isSignedIn) {
      setState(() {
        _isLoggedIn = true;
        // Tự động điền thông tin từ user đã đăng nhập
        _nameController.text = user.hoTen ?? '';
        _emailController.text = user.email ?? '';
        _phoneController.text = user.sdt ?? '';
      });
    } else {
      setState(() {
        _isLoggedIn = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Chi tiết đặt phòng',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back, size: 20),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey[200],
          ),
        ),
      ),
      body: Column(
        children: [
          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

                  // Price Breakdown
                  PriceBreakdownCard(
                    basePrice: _basePrice,
                    serviceFeeByCurrency: _serviceFeeByCurrency,
                    discountAmount: _discountAmount,
                    finalTotal: _finalTotal,
                    nights: widget.nights,
                  ),

                  // Discount Code Input
                  DiscountCodeInput(
                    originalPrice: _basePrice + _serviceFeeByCurrency,
                    hotelId: widget.hotel.id,
                    locationId: widget.hotel.viTriId,
                    onDiscountApplied: (code, discountAmount) {
                      setState(() {
                        _appliedDiscountCode = code;
                        _discountFromCode = discountAmount;
                      });
                    },
                    onDiscountRemoved: () {
                      setState(() {
                        _appliedDiscountCode = null;
                        _discountFromCode = 0;
                      });
                    },
                  ),

                  // Guest Details
                  GuestDetailsForm(
                    key: _guestFormKey,
                    nameController: _nameController,
                    emailController: _emailController,
                    phoneController: _phoneController,
                    isLoggedIn: _isLoggedIn,
                  ),

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

  /// Xử lý thanh toán
  /// 
  /// Quy trình:
  /// 1. Validate form thông tin khách (name, email, phone)
  /// 2. Tạo PaymentData từ thông tin đã nhập
  /// 3. Gọi PaymentService để tạo booking
  /// 4. Nếu thành công: navigate đến PaymentSuccessScreen
  /// 5. Nếu lỗi: hiển thị dialog thông báo lỗi
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
      // Xử lý đặc biệt cho MoMo (cần mở WebView)
      if (_selectedPaymentMethod == PaymentMethod.momo) {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
          
          // Generate unique order ID for payment
          final orderId = 'ORDER${DateTime.now().millisecondsSinceEpoch}';
          
          // Navigate to MoMo payment screen
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MoMoPaymentScreen(
                bookingId: widget.hotel.id, // Temporary - sẽ được thay thế bằng booking ID sau khi thanh toán thành công
                amount: _finalTotal,
                orderInfo: 'Đặt phòng ${widget.room.tenLoaiPhong} tại ${widget.hotel.ten}',
                hotel: widget.hotel,
                room: widget.room,
                checkInDate: widget.checkInDate,
                checkOutDate: widget.checkOutDate,
                guestCount: widget.guestCount,
                nights: widget.nights,
                userName: _nameController.text,
                userEmail: _emailController.text,
                userPhone: _phoneController.text,
              ),
            ),
          );
          
          // Xử lý kết quả từ MoMo
          if (result != null && result['success'] == true) {
            // ✅ Auto-create conversation with hotel manager after MoMo success
            try {
              if (widget.hotel.nguoiQuanLyId != null) {
                final MessageService messageService = MessageService();
                await messageService.createBookingConversation(
                  hotelManagerId: widget.hotel.nguoiQuanLyId.toString(),
                  hotelManagerName: widget.hotel.tenNguoiQuanLy ?? 'Quản lý',
                  hotelManagerEmail: widget.hotel.emailNguoiQuanLy ?? '',
                  hotelName: widget.hotel.ten,
                  bookingId: result['orderId'] ?? 'ORDER_${DateTime.now().millisecondsSinceEpoch}',
                );
                print('✅ Auto-created conversation after MoMo payment');
              }
            } catch (e) {
              print('⚠️ Could not auto-create conversation: $e');
              // Don't block payment flow
            }
            
            // Payment successful
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
                    orderId: result['orderId'] ?? 'ORDER_${DateTime.now().millisecondsSinceEpoch}',
                  ),
                ),
              );
            }
          } else if (result != null && result['success'] == false) {
            // Payment failed
            final reason = result['reason'] ?? 'unknown';
            final message = result['message'] ?? 'Thanh toán thất bại';
            
            if (mounted) {
              if (reason != 'user_cancelled' && reason != 'error') {
                _showPaymentErrorDialog(message);
              }
            }
          }
        }
        return;
      }
      
      // Xử lý đặc biệt cho VNPay (cần mở WebView)
      if (_selectedPaymentMethod == PaymentMethod.vnpay) {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
          
          // Generate unique order ID for payment
          final orderId = 'ORDER${DateTime.now().millisecondsSinceEpoch}';
          
          // Navigate to VNPay QR payment screen (giao diện đẹp)
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VNPayQRPaymentScreen(
                bookingId: widget.hotel.id, // Temporary - sẽ được thay thế bằng booking ID sau khi thanh toán thành công
                amount: _finalTotal,
                orderInfo: 'Đặt phòng ${widget.room.tenLoaiPhong} tại ${widget.hotel.ten}',
                hotel: widget.hotel,
                room: widget.room,
                checkInDate: widget.checkInDate,
                checkOutDate: widget.checkOutDate,
                guestCount: widget.guestCount,
                nights: widget.nights,
                userName: _nameController.text,
                userEmail: _emailController.text,
                userPhone: _phoneController.text,
              ),
            ),
          );
          
          // Xử lý kết quả từ VNPay
          if (result != null && result['success'] == true) {
            // ✅ Auto-create conversation with hotel manager after VNPay success
            try {
              if (widget.hotel.nguoiQuanLyId != null) {
                final MessageService messageService = MessageService();
                await messageService.createBookingConversation(
                  hotelManagerId: widget.hotel.nguoiQuanLyId.toString(),
                  hotelManagerName: widget.hotel.tenNguoiQuanLy ?? 'Quản lý',
                  hotelManagerEmail: widget.hotel.emailNguoiQuanLy ?? '',
                  hotelName: widget.hotel.ten,
                  bookingId: result['orderId'] ?? 'ORDER_${DateTime.now().millisecondsSinceEpoch}',
                );
                print('✅ Auto-created conversation after VNPay payment');
              }
            } catch (e) {
              print('⚠️ Could not auto-create conversation: $e');
              // Don't block payment flow
            }
            
            // Payment successful
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
                    orderId: result['orderId'] ?? 'ORDER_${DateTime.now().millisecondsSinceEpoch}',
                  ),
                ),
              );
            }
          } else if (result != null && result['success'] == false) {
            // Payment failed
            final reason = result['reason'] ?? 'unknown';
            final message = result['message'] ?? 'Thanh toán thất bại';
            
            if (mounted) {
              if (reason != 'user_cancelled') {
                _showPaymentErrorDialog(message);
              }
            }
          }
        }
        return;
      }
      
      // Xử lý thanh toán tiền mặt (cash)
      if (_selectedPaymentMethod == PaymentMethod.cash) {
        try {
          // Tạo booking trong database với trạng thái pending
          final bookingData = {
            'userPhone': _phoneController.text,
            'userEmail': _emailController.text,
            'userName': _nameController.text,
            'hotelId': widget.hotel.id,
            'hotelName': widget.hotel.ten,
            'roomId': widget.room.id,
            'roomNumber': widget.room.soPhong,
            'roomType': widget.room.tenLoaiPhong,
            'checkInDate': widget.checkInDate.toIso8601String(),
            'checkOutDate': widget.checkOutDate.toIso8601String(),
            'guestCount': widget.guestCount,
            'roomCount': 1,
            'nights': widget.nights,
            'totalAmount': _finalTotal,
            'paymentMethod': 'Cash',
            'specialRequests': '',
          };
          
          print('💵 Creating cash booking...');
          final booking = await _bookingService.createCashBooking(bookingData);
          print('✅ Cash booking created: ${booking.id}');
          
          // ✅ Auto-create conversation with hotel manager after booking
          try {
            if (widget.hotel.nguoiQuanLyId != null) {
              final MessageService messageService = MessageService();
              await messageService.createBookingConversation(
                hotelManagerId: widget.hotel.nguoiQuanLyId.toString(),
                hotelManagerName: widget.hotel.tenNguoiQuanLy ?? 'Quản lý',
                hotelManagerEmail: widget.hotel.emailNguoiQuanLy ?? '',
                hotelName: widget.hotel.ten,
                bookingId: booking.bookingCode ?? 'CASH_${DateTime.now().millisecondsSinceEpoch}',
              );
              print('✅ Auto-created conversation with hotel manager');
            }
          } catch (e) {
            print('⚠️ Could not auto-create conversation: $e');
            // Don't block booking flow, just log
          }
          
          if (mounted) {
            setState(() {
              _isProcessing = false;
            });
            
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
                  orderId: booking.bookingCode ?? 'CASH_${DateTime.now().millisecondsSinceEpoch}',
                ),
              ),
            );
          }
        } catch (e) {
          print('❌ Error creating cash booking: $e');
          if (mounted) {
            setState(() {
              _isProcessing = false;
            });
            _showPaymentErrorDialog('Không thể tạo đặt phòng. Vui lòng thử lại.');
          }
        }
        return;
      }
      
      // Xử lý các phương thức thanh toán khác (mock) - không nên reach được đoạn này
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

  /// Convert PaymentMethod sang PaymentProvider (for backward compatibility)
  /// 
  /// Note: Hiện tại không sử dụng vì đã xử lý trực tiếp từng payment method
  PaymentProvider _convertToPaymentProvider(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.momo:
        return PaymentProvider.eWallet;
      case PaymentMethod.vnpay:
        return PaymentProvider.vnpay;
      case PaymentMethod.cash:
        return PaymentProvider.hotelPayment;
    }
  }

  /// Hiển thị dialog thông báo lỗi thanh toán
  /// 
  /// Parameters:
  /// - [errorMessage]: Thông báo lỗi cần hiển thị
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