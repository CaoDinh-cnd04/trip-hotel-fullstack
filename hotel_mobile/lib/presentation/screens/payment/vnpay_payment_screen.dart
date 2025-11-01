/**
 * Màn hình thanh toán VNPay
 * 
 * Chức năng:
 * - Hiển thị thông tin đơn hàng
 * - Chọn ngân hàng (optional)
 * - Tạo payment URL và mở WebView
 * - Xử lý kết quả thanh toán
 * 
 * Giao diện: Theo thiết kế VNPay chính thức
 */

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../data/services/vnpay_service.dart';
import '../../../data/services/booking_history_service.dart';
import '../../../data/models/hotel.dart';
import '../../../data/models/room.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/services/backend_auth_service.dart';

/// Màn hình thanh toán VNPay
class VNPayPaymentScreen extends StatefulWidget {
  final int bookingId;
  final double amount;
  final String orderInfo;
  
  // Thông tin booking để tạo sau khi thanh toán thành công
  final Hotel hotel;
  final Room room;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int guestCount;
  final int nights;
  final String userName;
  final String userEmail;
  final String userPhone;

  const VNPayPaymentScreen({
    Key? key,
    required this.bookingId,
    required this.amount,
    required this.orderInfo,
    required this.hotel,
    required this.room,
    required this.checkInDate,
    required this.checkOutDate,
    required this.guestCount,
    required this.nights,
    required this.userName,
    required this.userEmail,
    required this.userPhone,
  }) : super(key: key);

  @override
  State<VNPayPaymentScreen> createState() => _VNPayPaymentScreenState();
}

class _VNPayPaymentScreenState extends State<VNPayPaymentScreen> {
  final VNPayService _vnpayService = VNPayService();
  final BackendAuthService _authService = BackendAuthService();
  
  List<VNPayBank> _banks = [];
  VNPayBank? _selectedBank;
  bool _isLoadingBanks = true;
  bool _isCreatingPaymentUrl = false;
  String? _errorMessage;
  
  String? _paymentUrl;
  late WebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadBanks();
  }

  /// Kiểm tra authentication trước khi load banks
  Future<void> _checkAuthAndLoadBanks() async {
    // Kiểm tra user đã đăng nhập chưa
    final isAuth = await _authService.isAuthenticated();
    if (!isAuth) {
      setState(() {
        _errorMessage = 'Vui lòng đăng nhập để thanh toán';
        _isLoadingBanks = false;
      });
      return;
    }
    
    _loadBanks();
  }

  /// Load danh sách ngân hàng
  Future<void> _loadBanks() async {
    try {
      final banks = await _vnpayService.getBankList();
      setState(() {
        _banks = banks;
        _isLoadingBanks = false;
      });
    } catch (e) {
      print('Error loading banks: $e');
      setState(() {
        _isLoadingBanks = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tải danh sách ngân hàng: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  /// Tạo payment URL và hiển thị WebView
  Future<void> _createPaymentUrl() async {
    // Kiểm tra authentication trước
    final isAuth = await _authService.isAuthenticated();
    if (!isAuth) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vui lòng đăng nhập để thanh toán'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Đăng nhập',
            textColor: Colors.white,
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/login');
            },
          ),
        ),
      );
      return;
    }

    setState(() {
      _isCreatingPaymentUrl = true;
      _errorMessage = null;
    });

    try {
      final paymentUrl = await _vnpayService.createPaymentUrl(
        bookingId: widget.bookingId,
        amount: widget.amount,
        orderInfo: widget.orderInfo,
        bankCode: _selectedBank?.code,
      );

      setState(() {
        _paymentUrl = paymentUrl;
        _isCreatingPaymentUrl = false;
      });

      // Initialize WebView controller
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              print('Page started loading: $url');
              _handleNavigationUrl(url);
            },
            onPageFinished: (String url) {
              print('Page finished loading: $url');
            },
            onNavigationRequest: (NavigationRequest request) {
              print('Navigation request: ${request.url}');
              _handleNavigationUrl(request.url);
              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadRequest(Uri.parse(paymentUrl));
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      
      setState(() {
        _isCreatingPaymentUrl = false;
        _errorMessage = errorMsg;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $errorMsg'),
            backgroundColor: Color(0xFFED1C24), // VNPay red
            duration: Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Đóng',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  /// Xử lý URL navigation để detect return từ VNPay
  void _handleNavigationUrl(String url) {
    // Check if this is return URL from VNPay
    if (url.contains('/payment/success') || url.contains('/payment/failed')) {
      // Parse URL parameters
      final uri = Uri.parse(url);
      final queryParams = uri.queryParameters;
      
      if (url.contains('/payment/success')) {
        // Payment successful
        Navigator.pop(context, {
          'success': true,
          'orderId': queryParams['orderId'],
          'amount': queryParams['amount'],
          'transactionNo': queryParams['transactionNo'],
        });
      } else {
        // Payment failed
        Navigator.pop(context, {
          'success': false,
          'reason': queryParams['reason'],
          'message': queryParams['message'],
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const vnpayRed = Color(0xFFED1C24);
    const vnpayOrange = Color(0xFFFF6B00);
    
    // Nếu đã có payment URL, hiển thị WebView
    if (_paymentUrl != null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: vnpayRed,
          foregroundColor: Colors.white,
          elevation: 0,
          title: Row(
            children: [
              Text('VNPay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              // Confirm trước khi đóng
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Hủy thanh toán?'),
                  content: const Text('Bạn có chắc muốn hủy giao dịch thanh toán?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Không'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(context, {'success': false, 'reason': 'user_cancelled'}); // Close payment screen
                      },
                      child: const Text('Hủy thanh toán', style: TextStyle(color: vnpayRed)),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        body: WebViewWidget(controller: _webViewController),
      );
    }

    // Nếu chưa có payment URL, hiển thị form chọn ngân hàng
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: vnpayRed,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Thanh toán VNPay', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Header VNPay style
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: vnpayRed,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thông tin đơn hàng',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.orderInfo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Số tiền thanh toán:',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.formatVND(widget.amount),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bank selection
          Expanded(
            child: _isLoadingBanks
                ? const Center(child: CircularProgressIndicator(color: vnpayRed))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        'Chọn ngân hàng thanh toán',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bỏ qua nếu muốn chọn sau tại trang VNPay',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Bank list - VNPay style
                      ..._banks.map((bank) {
                        final isSelected = _selectedBank?.code == bank.code;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? vnpayRed : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(
                                  color: vnpayRed.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                setState(() {
                                  _selectedBank = bank;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    // Bank icon
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: isSelected 
                                            ? vnpayRed.withOpacity(0.1) 
                                            : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.account_balance,
                                        color: isSelected ? vnpayRed : Colors.grey.shade600,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        bank.name,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                          color: isSelected ? vnpayRed : Colors.grey[800],
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      isSelected ? Icons.check_circle : Icons.circle_outlined,
                                      color: isSelected ? vnpayRed : Colors.grey.shade400,
                                      size: 24,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
          ),

          // Payment button - VNPay style
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: !_isCreatingPaymentUrl
                        ? LinearGradient(
                            colors: [vnpayRed, vnpayOrange],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          )
                        : null,
                    color: _isCreatingPaymentUrl ? Colors.grey.shade300 : null,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: !_isCreatingPaymentUrl ? [
                      BoxShadow(
                        color: vnpayRed.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ] : null,
                  ),
                  child: ElevatedButton(
                    onPressed: _isCreatingPaymentUrl ? null : _createPaymentUrl,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isCreatingPaymentUrl
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(Icons.lock, size: 16),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'TIẾP TỤC THANH TOÁN',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

