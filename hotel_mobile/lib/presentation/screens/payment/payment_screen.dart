import 'package:flutter/material.dart';
import 'dart:ui';
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
import 'package:hotel_mobile/presentation/screens/main_navigation_screen.dart';
import 'package:hotel_mobile/presentation/screens/payment/bank_transfer_screen.dart';
import 'package:hotel_mobile/presentation/screens/payment/vnpay_package_payment_screen.dart';
import 'package:hotel_mobile/presentation/screens/payment/payment_success_screen_v2.dart';
import 'package:hotel_mobile/core/widgets/glass_card.dart';
import 'package:hotel_mobile/data/services/applied_promotion_service.dart';
import 'package:hotel_mobile/data/services/promotion_service.dart';
import 'package:hotel_mobile/data/services/discount_service.dart';
import 'package:hotel_mobile/data/services/api_service.dart';
import 'package:hotel_mobile/data/models/amenity.dart';
import 'package:hotel_mobile/core/utils/currency_formatter.dart';
import 'package:hotel_mobile/l10n/app_localizations.dart';
import 'dart:convert';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

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
  /// Số lượng phòng (mặc định 1)
  final int roomCount;
  /// Yêu cầu thanh toán online (VNPay/Bank Transfer) - khi đặt thêm phòng ở cùng khách sạn
  final bool requiresOnlinePayment;
  /// Tối thiểu % thanh toán (khi đặt thêm phòng ở cùng khách sạn)
  final int minPaymentPercentage;

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
    this.roomCount = 1,
    this.requiresOnlinePayment = false,
    this.minPaymentPercentage = 0,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with TickerProviderStateMixin {
  /// Controller cho trường tên khách
  final _nameController = TextEditingController();
  
  /// Controller cho trường email
  final _emailController = TextEditingController();
  
  /// Controller cho trường số điện thoại
  final _phoneController = TextEditingController();
  
  /// Key để validate form thông tin khách
  final GlobalKey<State<GuestDetailsForm>> _guestFormKey = GlobalKey<State<GuestDetailsForm>>();

  /// Phương thức thanh toán được chọn
  PaymentMethod _selectedPaymentMethod = PaymentMethod.vnpay;
  
  /// Người dùng có muốn cọc 50% không (tùy chọn cho tất cả các trường hợp)
  bool _useDeposit = false;
  
  void _updatePaymentMethod(PaymentMethod method) {
    // ✅ Kiểm tra: Nếu yêu cầu thanh toán online, không cho chọn Cash
    if (widget.requiresOnlinePayment && method == PaymentMethod.cash) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.minPaymentPercentage > 0
                ? 'Bạn đang có đặt phòng tại khách sạn này. Để đặt thêm phòng, vui lòng sử dụng thanh toán VNPay hoặc chuyển khoản ngân hàng (tối thiểu ${widget.minPaymentPercentage}% tổng giá trị).'
                : 'Bạn đang có đặt phòng tại khách sạn này. Để đặt thêm phòng, vui lòng sử dụng thanh toán VNPay hoặc chuyển khoản ngân hàng.',
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
    
    // Kiểm tra điều kiện trước khi cho phép chọn
    if (method == PaymentMethod.cash && !_canUseCash) {
      // Không cho phép chọn Cash nếu không đủ điều kiện
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.roomCount >= 2
                ? 'Đặt từ 2 phòng trở lên không được thanh toán tiền mặt'
                : 'Tổng giá trị trên 3 triệu không được thanh toán tiền mặt',
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    if (_mustUseOnlinePayment && method == PaymentMethod.cash) {
      // Không cho phép chọn Cash khi >= 3 phòng
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.onlinePaymentRequired),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    if (mounted) {
      setState(() {
        _selectedPaymentMethod = method;
      });
    }
  }
  
  /// Trạng thái đang xử lý thanh toán
  bool _isProcessing = false;
  
  /// Service xử lý thanh toán
  final PaymentService _paymentService = PaymentService();
  
  /// Service authentication
  final BackendAuthService _authService = BackendAuthService();
  
  /// Service booking
  final BookingHistoryService _bookingService = BookingHistoryService();
  
  /// Service promotion
  final AppliedPromotionService _promotionService = AppliedPromotionService();
  
  /// Service promotion validation
  final PromotionService _promotionValidationService = PromotionService();
  
  /// Service discount
  final DiscountService _discountService = DiscountService();
  
  /// Service API
  final ApiService _apiService = ApiService();
  
  /// Trạng thái user đã đăng nhập
  bool _isLoggedIn = false;
  
  /// Mã giảm giá đã áp dụng
  String? _appliedDiscountCode;
  
  /// Số tiền giảm giá từ mã
  double _discountFromCode = 0;
  
  /// Trạng thái đang tìm mã giảm giá tự động
  bool _isAutoApplyingDiscount = false;
  
  // ✅ NEW: Dịch vụ tiện nghi
  List<Amenity> _paidAmenities = []; // Dịch vụ có phí
  List<Amenity> _freeAmenities = []; // Dịch vụ miễn phí (tự động thêm khi giá cao)
  Set<int> _selectedPaidAmenities = {}; // Dịch vụ có phí đã chọn
  bool _isLoadingAmenities = false;
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Các getter tính toán giá
  
  /// Giá cơ bản (roomPrice * nights * roomCount)
  double get _basePrice => widget.roomPrice * widget.nights * widget.roomCount;
  
  /// Phí dịch vụ 5% (service fee)
  double get _serviceFeeByCurrency => _basePrice * 0.05;
  
  /// Promotion validation state
  bool _isValidatingPromotion = false;
  String? _promotionValidationError;
  
  /// Số tiền giảm giá (từ widget.discount + mã giảm giá)
  /// Tính tổng số tiền giảm giá (từ promotion + discount code + widget.discount)
  /// Lưu ý: Promotion chỉ được tính nếu đã được validate với check-in date
  double get _discountAmount {
    double totalDiscount = widget.discount ?? 0;
    
    // ✅ Thêm discount từ promotion đã apply (chỉ nếu hợp lệ)
    final appliedPromotion = _promotionService.getAppliedPromotion(hotelId: widget.hotel.id);
    if (appliedPromotion != null && _basePrice > 0 && _promotionValidationError == null) {
      final promotionDiscount = _promotionService.calculateDiscountedPrice(_basePrice, hotelId: widget.hotel.id);
      final discountFromPromotion = _basePrice - promotionDiscount;
      totalDiscount += discountFromPromotion;
      print('💰 Promotion discount applied: ${appliedPromotion.ten} - ${appliedPromotion.phanTramGiam}% = ${CurrencyFormatter.formatVND(discountFromPromotion)}');
    }
    
    // Thêm discount từ code
    totalDiscount += _discountFromCode;
    
    return totalDiscount;
  }
  
  /// Tổng tiền dịch vụ đã chọn
  double get _selectedServicesTotal {
    double total = 0;
    for (var amenity in _paidAmenities) {
      if (_selectedPaidAmenities.contains(amenity.id) && amenity.giaPhi != null) {
        total += amenity.giaPhi!;
      }
    }
    return total;
  }
  
  /// Tổng tiền trước cọc (base + service + selected services - discount)
  double get _subtotal => _basePrice + _serviceFeeByCurrency + _selectedServicesTotal - _discountAmount;
  
  /// Kiểm tra có thể thanh toán tiền mặt không
  /// Điều kiện: roomCount < 2 VÀ tổng giá trị <= 3,000,000 VNĐ
  bool get _canUseCash {
    return widget.roomCount < 2 && _subtotal <= 3000000;
  }
  
  /// Kiểm tra có bắt buộc dùng VNPay không (khi >= 3 phòng)
  bool get _mustUseOnlinePayment => widget.roomCount >= 3;
  
  /// Cọc 50% nếu người dùng chọn tùy chọn cọc
  double get _depositAmount {
    if (_useDeposit) {
      return _subtotal * 0.5; // 50% cọc
    }
    return 0;
  }
  
  /// Kiểm tra có cần thanh toán cọc không
  /// Người dùng có thể chọn cọc 50% cho tất cả các trường hợp
  bool get _requiresDeposit => _useDeposit;
  
  /// Tổng tiền cần thanh toán
  /// - Nếu người dùng chọn cọc: chỉ thanh toán cọc 50%
  /// - Nếu không: thanh toán toàn bộ
  double get _finalTotal {
    if (_requiresDeposit) {
      return _depositAmount; // Chỉ thanh toán cọc 50%
    }
    return _subtotal; // Thanh toán toàn bộ
  }
  
  /// Tổng tiền đầy đủ (bao gồm cả phần còn lại sau cọc)
  double get _fullTotal => _subtotal;

  @override
  void initState() {
    super.initState();
    
    // ✅ Nếu yêu cầu thanh toán online và có minPaymentPercentage >= 50%, tự động bật cọc
    if (widget.requiresOnlinePayment && widget.minPaymentPercentage >= 50) {
      _useDeposit = true;
      // ✅ Tự động chọn VNPay nếu yêu cầu thanh toán online
      _selectedPaymentMethod = PaymentMethod.vnpay;
    }
    
    // Nếu >= 3 phòng, mặc định chọn VNPay (chỉ cho phép online payment)
    if (widget.roomCount >= 3) {
      _selectedPaymentMethod = PaymentMethod.vnpay;
    }
    
    // Initialize animations
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    
    // Start animations
    _fadeController.forward();
    _slideController.forward();
    
    _loadUserInfo();
    _loadAmenities(); // ✅ NEW: Load amenities
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  /// Tải thông tin user nếu đã đăng nhập
  /// 
  /// Tự động điền vào form:
  /// - Họ tên
  /// - Email
  /// - Số điện thoại
  /// - Tự động áp dụng mã giảm giá có giá trị cao nhất
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
    
    // Tự động tìm và áp dụng mã giảm giá có giá trị cao nhất (cho cả user đã đăng nhập và chưa đăng nhập)
    _autoApplyBestDiscountCode();
    
    // Validate promotion đã được áp dụng (nếu có) với check-in date
    _validateAppliedPromotion();
  }
  
  /// ✅ NEW: Load amenities (paid and free)
  Future<void> _loadAmenities() async {
    if (widget.hotel.id == null) return;
    
    setState(() {
      _isLoadingAmenities = true;
    });
    
    try {
      // Load paid amenities (for suggestions when low price)
      final paidResponse = await _apiService.getHotelPaidAmenities(widget.hotel.id!);
      if (paidResponse.success && paidResponse.data != null) {
        _paidAmenities = paidResponse.data!;
      }
      
      // Load free amenities (auto-add when high price)
      final freeResponse = await _apiService.getHotelFreeAmenities(widget.hotel.id!);
      if (freeResponse.success && freeResponse.data != null) {
        _freeAmenities = freeResponse.data!;
        
        // ✅ Logic: Nếu đặt phòng với giá cao (>= 1,000,000 VNĐ/đêm), tự động thêm dịch vụ miễn phí
        if (widget.roomPrice >= 1000000 && _freeAmenities.isNotEmpty) {
          // Tự động thêm 2-3 dịch vụ miễn phí đầu tiên
          final autoAddCount = _freeAmenities.length > 3 ? 3 : _freeAmenities.length;
          print('✅ Auto-adding $autoAddCount free amenities for high price booking (${widget.roomPrice} VNĐ/đêm)');
        }
      }
    } catch (e) {
      print('❌ Error loading amenities: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAmenities = false;
        });
      }
    }
  }
  
  /// ✅ NEW: Check if should suggest paid amenities (when low price)
  bool get _shouldSuggestPaidAmenities {
    // Gợi ý dịch vụ có phí khi giá phòng < 800,000 VNĐ/đêm
    return widget.roomPrice < 800000 && _paidAmenities.isNotEmpty;
  }
  
  /// ✅ NEW: Toggle selected paid amenity
  void _togglePaidAmenity(int amenityId) {
    setState(() {
      if (_selectedPaidAmenities.contains(amenityId)) {
        _selectedPaidAmenities.remove(amenityId);
      } else {
        _selectedPaidAmenities.add(amenityId);
      }
    });
  }
  
  /// Validate promotion đã được áp dụng với check-in date
  Future<void> _validateAppliedPromotion() async {
    final appliedPromotion = _promotionService.getAppliedPromotion(hotelId: widget.hotel.id);
    if (appliedPromotion == null || appliedPromotion.id == null) {
      return;
    }
    
    if (_isValidatingPromotion) return;
    
    setState(() {
      _isValidatingPromotion = true;
      _promotionValidationError = null;
    });
    
    try {
      final orderAmount = _basePrice + _serviceFeeByCurrency;
      
      final response = await _promotionValidationService.validatePromotion(
        promotionId: appliedPromotion.id!,
        orderAmount: orderAmount,
        checkInDate: widget.checkInDate,
      );
      
      if (mounted) {
        setState(() {
          _isValidatingPromotion = false;
          
          if (!response['isValid']) {
            _promotionValidationError = response['timeValidationReason'] ?? 
                                       response['message'] ?? 
                                       'Không thể áp dụng ưu đãi này';
            
            // Xóa promotion không hợp lệ
            _promotionService.clearAppliedPromotion();
            
            // Hiển thị thông báo
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_promotionValidationError!),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 4),
                action: SnackBarAction(
                  label: 'Đóng',
                  textColor: Colors.white,
                  onPressed: () {},
                ),
              ),
            );
          }
        });
      }
    } catch (e) {
      print('❌ Error validating promotion: $e');
      if (mounted) {
        setState(() {
          _isValidatingPromotion = false;
        });
      }
    }
  }

  /// Tự động tìm và áp dụng mã giảm giá có giá trị cao nhất
  void _autoApplyBestDiscountCode() async {
    if (_isAutoApplyingDiscount) return;
    
    setState(() {
      _isAutoApplyingDiscount = true;
    });
    
    try {
      // Tính tổng giá trị đơn hàng (base price + service fee)
      final orderAmount = _basePrice + _serviceFeeByCurrency;
      
      print('🔍 Auto-applying best discount code for order: ${orderAmount.toStringAsFixed(0)}₫');
      
      // Tìm mã giảm giá có giá trị cao nhất
      final bestDiscount = await _discountService.findBestDiscountCode(
        orderAmount: orderAmount,
        hotelId: widget.hotel.id,
        locationId: widget.hotel.viTriId,
      );
      
      if (bestDiscount != null && mounted) {
        final code = bestDiscount['code'] as String;
        final discountAmount = (bestDiscount['discountAmount'] ?? 0).toDouble();
        
        setState(() {
          _appliedDiscountCode = code;
          _discountFromCode = discountAmount;
        });
        
        print('✅ Auto-applied discount code: $code - ${discountAmount.toStringAsFixed(0)}₫');
        
        // Hiển thị thông báo cho user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎉 ${AppLocalizations.of(context)!.discountAutoApplied(code, CurrencyFormatter.formatVND(discountAmount))}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        print('ℹ️ No valid discount code found for auto-apply');
      }
    } catch (e) {
      print('❌ Error auto-applying discount code: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isAutoApplyingDiscount = false;
        });
      }
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
        backgroundColor: Colors.white.withValues(alpha: 0.8),
        foregroundColor: Colors.black87,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ),
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
            color: Colors.grey.shade200.withValues(alpha: 0.3),
          ),
        ),
      ),
      body: Column(
        children: [
          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(), // Đảm bảo luôn có thể scroll
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min, // Quan trọng: cho phép Column expand theo content
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Summary (Glass + Animation)
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: GlassCard(
                        blur: 15,
                        opacity: 0.25,
                        borderRadius: 20,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: OrderSummaryCard(
                          hotel: widget.hotel,
                          room: widget.room,
                          checkInDate: widget.checkInDate,
                          checkOutDate: widget.checkOutDate,
                          guestCount: widget.guestCount,
                          nights: widget.nights,
                        ),
                      ),
                    ),
                  ),

                  // Price Breakdown (Glass + Animation)
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: GlassCard(
                        blur: 15,
                        opacity: 0.25,
                        borderRadius: 20,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: PriceBreakdownCard(
                          basePrice: _basePrice,
                          serviceFeeByCurrency: _serviceFeeByCurrency,
                          discountAmount: _discountAmount,
                          finalTotal: _finalTotal,
                          nights: widget.nights,
                          roomCount: widget.roomCount,
                          requiresDeposit: _requiresDeposit,
                          depositAmount: _depositAmount,
                          fullTotal: _fullTotal,
                          paymentMethod: _selectedPaymentMethod,
                          additionalServicesTotal: _selectedServicesTotal > 0 ? _selectedServicesTotal : null, // ✅ NEW
                        ),
                      ),
                    ),
                  ),

                  // Deposit Option (Glass + Animation)
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: GlassCard(
                        blur: 15,
                        opacity: 0.25,
                        borderRadius: 20,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: _buildDepositOption(),
                      ),
                    ),
                  ),

                  // Discount Code Input (Glass + Animation)
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: GlassCard(
                        blur: 15,
                        opacity: 0.25,
                        borderRadius: 20,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: DiscountCodeInput(
                          originalPrice: _basePrice + _serviceFeeByCurrency,
                          hotelId: widget.hotel.id,
                          locationId: widget.hotel.viTriId,
                          initialCode: _appliedDiscountCode,
                          initialDiscountAmount: _discountFromCode > 0 ? _discountFromCode : null,
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
                      ),
                    ),
                  ),

                  // ✅ NEW: Additional Services Section
                  if (_shouldSuggestPaidAmenities || _selectedPaidAmenities.isNotEmpty || _freeAmenities.isNotEmpty)
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: GlassCard(
                          blur: 15,
                          opacity: 0.25,
                          borderRadius: 20,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: _buildAdditionalServicesSection(),
                        ),
                      ),
                    ),

                  // Guest Details (Glass + Animation)
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: GlassCard(
                        blur: 15,
                        opacity: 0.25,
                        borderRadius: 20,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: GuestDetailsForm(
                          key: _guestFormKey,
                          nameController: _nameController,
                          emailController: _emailController,
                          phoneController: _phoneController,
                          isLoggedIn: _isLoggedIn,
                        ),
                      ),
                    ),
                  ),

                  // Payment Options (Glass + Animation)
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: GlassCard(
                        blur: 15,
                        opacity: 0.25,
                        borderRadius: 20,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: PaymentOptions(
                          selectedMethod: _selectedPaymentMethod,
                          onMethodChanged: _updatePaymentMethod,
                          roomCount: widget.roomCount,
                          totalAmount: _subtotal,
                          canUseCash: _canUseCash && !widget.requiresOnlinePayment, // ✅ Ẩn Cash nếu yêu cầu online
                          mustUseOnlinePayment: _mustUseOnlinePayment,
                          requiresOnlinePayment: widget.requiresOnlinePayment, // ✅ Truyền yêu cầu thanh toán online
                        ),
                      ),
                    ),
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
        requiresDeposit: _requiresDeposit,
        depositAmount: _depositAmount,
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
          SnackBar(
            content: Text(AppLocalizations.of(context)!.pleaseFillAllFields),
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
      // Xử lý đặc biệt cho VNPay (cần mở WebView)
      if (_selectedPaymentMethod == PaymentMethod.vnpay) {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
          
          // Generate unique order ID for payment
          final orderId = 'ORDER${DateTime.now().millisecondsSinceEpoch}';
          
          // Navigate to VNPay Package payment screen (sử dụng package vnpay_payment_flutter)
          final orderInfo = _requiresDeposit
              ? 'Cọc ${(_depositAmount / _fullTotal * 100).toStringAsFixed(0)}% - Đặt phòng ${widget.room.tenLoaiPhong} tại ${widget.hotel.ten}'
              : 'Đặt phòng ${widget.room.tenLoaiPhong} tại ${widget.hotel.ten}';
          
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VNPayPackagePaymentScreen(
                bookingId: widget.hotel.id, // Temporary - sẽ được thay thế bằng booking ID sau khi thanh toán thành công
                amount: _finalTotal,
                orderInfo: orderInfo,
                hotel: widget.hotel,
                room: widget.room,
                checkInDate: widget.checkInDate,
                checkOutDate: widget.checkOutDate,
                guestCount: widget.guestCount,
                nights: widget.nights,
                userName: _nameController.text,
                userEmail: _emailController.text,
                userPhone: _phoneController.text,
                roomCount: widget.roomCount,
                useDeposit: _useDeposit,
                depositAmount: _depositAmount,
                fullTotal: _fullTotal,
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
            
            // Payment successful - navigate to success screen
            if (mounted) {
              final orderId = result['orderId'] ?? 'ORDER_${DateTime.now().millisecondsSinceEpoch}';
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => PaymentSuccessScreenV2(
                    orderId: orderId,
                    paymentMethod: 'vnpay',
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
      
      // Xử lý Bank Transfer (giống VNPay, chỉ khác API)
      if (_selectedPaymentMethod == PaymentMethod.bankTransfer) {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
          
          // Generate unique order ID
          final orderId = 'BT_${DateTime.now().millisecondsSinceEpoch}_${widget.hotel.id}';
          
          // Create payment URL
          final orderInfo = 'Đặt phòng ${widget.room.tenLoaiPhong} tại ${widget.hotel.ten}';
          
          try {
            // Get current user ID from BackendAuthService
            final userId = BackendAuthService().currentUser?.id;
            
            // Call backend API to get payment URL (with full booking data like Cash payment)
            final response = await ApiService().post(
              '/api/v2/bank-transfer/create-payment-url', // ✅ FIX: Added /api/ prefix
              {
                'amount': _finalTotal,
                'orderInfo': orderInfo,
                'orderId': orderId,
                'bookingCode': orderId,
                'userName': _nameController.text,
                'userEmail': _emailController.text,
                'userPhone': _phoneController.text,
                // ✅ ADD: Full booking data for auto-confirm
                'userId': userId,
                'hotelId': widget.hotel.id,
                'hotelName': widget.hotel.ten,
                'roomId': widget.room.id,
                'roomType': widget.room.tenLoaiPhong,
                'checkInDate': widget.checkInDate.toIso8601String(),
                'checkOutDate': widget.checkOutDate.toIso8601String(),
                'guestCount': widget.guestCount,
                'nights': widget.nights,
                'finalPrice': _finalTotal,
                'totalPrice': _fullTotal,
              },
            );
            
            if (response.success && response.data != null) {
              final data = response.data as Map<String, dynamic>;
              final paymentUrl = data['paymentUrl'];
              
              // ✅ FIX: Use WebView instead of external browser for better compatibility
              print('🏦 Opening Bank Transfer in WebView: $paymentUrl');
              
              if (mounted) {
                setState(() {
                  _isProcessing = false;
                });
                
                // Navigate to Bank Transfer screen with WebView
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BankTransferScreen(
                      paymentUrl: paymentUrl,
                      orderId: orderId,
                      amount: _finalTotal,
                      hotel: widget.hotel,
                      room: widget.room,
                      checkInDate: widget.checkInDate,
                      checkOutDate: widget.checkOutDate,
                      guestCount: widget.guestCount,
                      nights: widget.nights,
                    ),
                  ),
                );
              }
            } else {
              throw Exception(response.message);
            }
          } catch (e) {
            print('❌ Error creating bank transfer URL: $e');
            if (mounted) {
              setState(() {
                _isProcessing = false;
              });
              _showPaymentErrorDialog('Không thể tạo link thanh toán. Vui lòng thử lại.');
            }
          }
        }
        return;
      }
      
      // Xử lý thanh toán tiền mặt (cash)
      if (_selectedPaymentMethod == PaymentMethod.cash) {
        try {
          // ✅ NEW: Prepare selected amenities data
          final selectedAmenitiesData = {
            'paid': _selectedPaidAmenities.map((id) {
              try {
                final amenity = _paidAmenities.firstWhere((a) => a.id == id);
                return {
                  'id': id,
                  'ten': amenity.ten,
                  'gia_phi': amenity.giaPhi,
                };
              } catch (e) {
                // Amenity not found, skip it
                return null;
              }
            }).whereType<Map<String, dynamic>>().toList(),
            'free': widget.roomPrice >= 1000000 
                ? _freeAmenities.take(3).map((amenity) {
                    return {
                      'id': amenity.id,
                      'ten': amenity.ten,
                      'gia_phi': 0,
                    };
                  }).toList()
                : [],
          };
          
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
            'roomCount': widget.roomCount,
            'nights': widget.nights,
            'totalAmount': _fullTotal, // Tổng giá trị đầy đủ (bao gồm dịch vụ)
            'depositAmount': _requiresDeposit ? _depositAmount : 0, // Cọc 50% nếu có
            'paidAmount': _finalTotal, // Số tiền đã thanh toán (cọc hoặc toàn bộ)
            'remainingAmount': _requiresDeposit ? (_fullTotal - _depositAmount) : 0, // Số tiền còn lại
            'paymentMethod': 'Cash',
            'specialRequests': jsonEncode(selectedAmenitiesData), // ✅ NEW: Store amenities as JSON
            'requiresDeposit': _requiresDeposit,
            'depositPercentage': _requiresDeposit ? 50 : 0, // 50% cọc
            'useDeposit': _useDeposit, // Người dùng có chọn cọc không
            'additionalServicesTotal': _selectedServicesTotal, // ✅ NEW: Total for additional services
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
            
            // Navigate to success screen với booking code
            final orderId = booking.bookingCode ?? 'CASH_${DateTime.now().millisecondsSinceEpoch}';
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => PaymentSuccessScreenV2(
                  orderId: orderId,
                  paymentMethod: 'cash',
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
          // Show success dialog then navigate to home
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext dialogContext) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(color: Colors.green[50], shape: BoxShape.circle),
                          child: Icon(Icons.check_circle, size: 60, color: Colors.green[600]),
                        ),
                        const SizedBox(height: 20),
                        Text(AppLocalizations.of(context)!.paymentSuccess,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green[700])),
                        const SizedBox(height: 12),
                        Text(AppLocalizations.of(context)!.bookingConfirmed,
                          textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.black87)),
                      ],
                    ),
                    actions: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
                              (route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(AppLocalizations.of(context)!.backToHome, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  );
                },
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
            content: Text('${AppLocalizations.of(context)!.paymentError}: $e'),
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
      case PaymentMethod.vnpay:
        return PaymentProvider.vnpay;
      case PaymentMethod.bankTransfer:
        return PaymentProvider.bankTransfer;
      case PaymentMethod.cash:
        return PaymentProvider.hotelPayment;
    }
  }
  
  /// Poll Bank Transfer payment status
  void _pollBankTransferPaymentStatus(String orderId) {
    print('📊 Polling Bank Transfer payment status for: $orderId');
    
    int attempts = 0;
    const maxAttempts = 60; // 60 * 2 = 120 seconds (2 minutes)
    
    Timer.periodic(const Duration(seconds: 2), (timer) async {
      attempts++;
      
      if (attempts > maxAttempts) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.paymentTimeout),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      
      try {
        final response = await ApiService().get(
          '/api/v2/bank-transfer/payment-status/$orderId', // ✅ FIX: Added /api/ prefix
        );
        
        if (response.success && response.data != null) {
          final data = response.data as Map<String, dynamic>;
          final status = data['status'];
          
          if (status == 'completed') {
            timer.cancel();
            print('✅ Bank Transfer payment successful!');
            
            // Auto-create conversation
            try {
              if (widget.hotel.nguoiQuanLyId != null) {
                final MessageService messageService = MessageService();
                await messageService.createBookingConversation(
                  hotelManagerId: widget.hotel.nguoiQuanLyId.toString(),
                  hotelManagerName: widget.hotel.tenNguoiQuanLy ?? 'Quản lý',
                  hotelManagerEmail: widget.hotel.emailNguoiQuanLy ?? '',
                  hotelName: widget.hotel.ten,
                  bookingId: orderId,
                );
                print('✅ Auto-created conversation after Bank Transfer');
              }
            } catch (e) {
              print('⚠️ Could not auto-create conversation: $e');
            }
            
            if (mounted) {
              setState(() {
                _isProcessing = false;
              });
              // Navigate to success screen
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => PaymentSuccessScreenV2(
                    orderId: orderId,
                    paymentMethod: 'bank_transfer',
                  ),
                ),
              );
            }
          } else if (status == 'failed') {
            timer.cancel();
            print('❌ Bank Transfer payment failed');
            
            if (mounted) {
              setState(() {
                _isProcessing = false;
              });
              _showPaymentErrorDialog('Thanh toán thất bại. Vui lòng thử lại.');
            }
          }
        }
      } catch (e) {
        print('⚠️ Error polling payment status: $e');
      }
    });
  }

  /// Xây dựng widget tùy chọn cọc 50%
  /// ✅ NEW: Build additional services section
  Widget _buildAdditionalServicesSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.room_service, color: Colors.blue[700], size: 24),
              const SizedBox(width: 8),
              const Text(
                'Dịch vụ bổ sung',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Free amenities (auto-added for high price)
          if (widget.roomPrice >= 1000000 && _freeAmenities.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bạn được tặng miễn phí ${_freeAmenities.length} dịch vụ khi đặt phòng giá cao!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ..._freeAmenities.take(3).map((amenity) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[600], size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        amenity.ten,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'MIỄN PHÍ',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (_freeAmenities.length > 3)
              Text(
                '... và ${_freeAmenities.length - 3} dịch vụ khác',
                style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
              ),
            const SizedBox(height: 16),
          ],
          
          // Paid amenities suggestions (for low price)
          if (_shouldSuggestPaidAmenities) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Gợi ý: Thêm dịch vụ để trải nghiệm tốt hơn!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          // Paid amenities list
          if (_paidAmenities.isNotEmpty) ...[
            ..._paidAmenities.map((amenity) {
              final isSelected = _selectedPaidAmenities.contains(amenity.id);
              return InkWell(
                onTap: () => _togglePaidAmenity(amenity.id),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue[50] : Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.blue[300]! : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: isSelected,
                        onChanged: (_) => _togglePaidAmenity(amenity.id),
                        activeColor: Colors.blue[700],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              amenity.ten,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.blue[900] : Colors.black87,
                              ),
                            ),
                            if (amenity.moTa != null && amenity.moTa!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                amenity.moTa!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        amenity.giaPhi != null
                            ? CurrencyFormatter.formatVND(amenity.giaPhi!)
                            : 'Miễn phí',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.blue[700] : Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            if (_selectedPaidAmenities.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tổng dịch vụ đã chọn:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.formatVND(_selectedServicesTotal),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ] else if (_isLoadingAmenities) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            ),
          ] else if (!_shouldSuggestPaidAmenities && widget.roomPrice < 1000000) ...[
            Text(
              'Không có dịch vụ bổ sung cho gói này.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600], fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDepositOption() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet, color: Colors.blue[600], size: 24),
              const SizedBox(width: 12),
              const Text(
                'Tùy chọn thanh toán',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 20),
          
          // Option 1: Thanh toán toàn bộ
          GestureDetector(
            onTap: () {
              setState(() {
                _useDeposit = false;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: !_useDeposit ? Colors.blue[50] : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: !_useDeposit ? Colors.blue[300]! : Colors.grey[300]!,
                  width: !_useDeposit ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Radio<bool>(
                    value: false,
                    groupValue: _useDeposit,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _useDeposit = value;
                        });
                      }
                    },
                    activeColor: Colors.blue[600],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Thanh toán toàn bộ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Thanh toán 100% tổng giá trị ngay bây giờ',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Option 2: Cọc 50%
          GestureDetector(
            onTap: () {
              setState(() {
                _useDeposit = true;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _useDeposit ? Colors.orange[50] : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _useDeposit ? Colors.orange[300]! : Colors.grey[300]!,
                  width: _useDeposit ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Radio<bool>(
                    value: true,
                    groupValue: _useDeposit,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _useDeposit = value;
                        });
                      }
                    },
                    activeColor: Colors.orange[600],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Cọc 50%',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Khuyến nghị',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange[900],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Thanh toán 50% ngay, số tiền còn lại thanh toán khi nhận phòng',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
            title: Row(
              children: [
                const Icon(Icons.error, color: Colors.red, size: 28),
                const SizedBox(width: 12),
                Text(AppLocalizations.of(context)!.paymentFailed),
              ],
            ),
            content: Text(errorMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(AppLocalizations.of(context)!.close),
              ),
            ],
          ),
        );
      }
    });
  }
}