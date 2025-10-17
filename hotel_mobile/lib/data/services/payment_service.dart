import 'package:flutter/material.dart';

enum PaymentProvider {
  vnpay,
  vietqr,
  creditCard,
  eWallet,
  hotelPayment,
}

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  /// Process payment with different providers
  Future<PaymentResult> processPayment({
    required PaymentProvider provider,
    required double amount,
    required String orderId,
    required String description,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      switch (provider) {
        case PaymentProvider.vnpay:
          return await _processVNPayPayment(
            amount: amount,
            orderId: orderId,
            description: description,
            additionalData: additionalData,
          );
        case PaymentProvider.vietqr:
          return await _processVietQRPayment(
            amount: amount,
            orderId: orderId,
            description: description,
            additionalData: additionalData,
          );
        case PaymentProvider.creditCard:
          return await _processCreditCardPayment(
            amount: amount,
            orderId: orderId,
            description: description,
            additionalData: additionalData,
          );
        case PaymentProvider.eWallet:
          return await _processEWalletPayment(
            amount: amount,
            orderId: orderId,
            description: description,
            additionalData: additionalData,
          );
        case PaymentProvider.hotelPayment:
          return await _processHotelPayment(
            amount: amount,
            orderId: orderId,
            description: description,
            additionalData: additionalData,
          );
      }
    } catch (e) {
      return PaymentResult(
        success: false,
        message: 'Lỗi thanh toán: $e',
        transactionId: null,
        provider: provider,
      );
    }
  }

  /// Process VNPay payment
  Future<PaymentResult> _processVNPayPayment({
    required double amount,
    required String orderId,
    required String description,
    Map<String, dynamic>? additionalData,
  }) async {
    // Simulate VNPay payment processing
    await Future.delayed(const Duration(seconds: 2));
    
    // In a real app, you would:
    // 1. Create payment URL with VNPay API
    // 2. Open webview or redirect to VNPay gateway
    // 3. Handle payment callback
    // 4. Verify payment status
    
    return PaymentResult(
      success: true,
      message: 'Thanh toán VNPay thành công',
      transactionId: 'VNPAY_${DateTime.now().millisecondsSinceEpoch}',
      provider: PaymentProvider.vnpay,
      additionalData: {
        'vnpay_transaction_id': 'VNPAY_${DateTime.now().millisecondsSinceEpoch}',
        'bank_code': 'NCB',
        'card_type': 'ATM',
      },
    );
  }

  /// Process VietQR payment
  Future<PaymentResult> _processVietQRPayment({
    required double amount,
    required String orderId,
    required String description,
    Map<String, dynamic>? additionalData,
  }) async {
    // Simulate VietQR payment processing
    await Future.delayed(const Duration(seconds: 2));
    
    // In a real app, you would:
    // 1. Generate QR code with VietQR API
    // 2. Display QR code for user to scan
    // 3. Poll for payment status
    // 4. Handle payment confirmation
    
    return PaymentResult(
      success: true,
      message: 'Thanh toán VietQR thành công',
      transactionId: 'VIETQR_${DateTime.now().millisecondsSinceEpoch}',
      provider: PaymentProvider.vietqr,
      additionalData: {
        'qr_code': 'https://img.vietqr.io/image/970422-1234567890-qr_only.png',
        'account_number': '1234567890',
        'bank_name': 'Vietcombank',
      },
    );
  }

  /// Process Credit Card payment
  Future<PaymentResult> _processCreditCardPayment({
    required double amount,
    required String orderId,
    required String description,
    Map<String, dynamic>? additionalData,
  }) async {
    // Simulate credit card payment processing
    await Future.delayed(const Duration(seconds: 2));
    
    return PaymentResult(
      success: true,
      message: 'Thanh toán thẻ tín dụng thành công',
      transactionId: 'CC_${DateTime.now().millisecondsSinceEpoch}',
      provider: PaymentProvider.creditCard,
      additionalData: {
        'card_type': 'Visa',
        'last_four': '4242',
        'authorization_code': 'AUTH_${DateTime.now().millisecondsSinceEpoch}',
      },
    );
  }

  /// Process E-Wallet payment
  Future<PaymentResult> _processEWalletPayment({
    required double amount,
    required String orderId,
    required String description,
    Map<String, dynamic>? additionalData,
  }) async {
    // Simulate e-wallet payment processing
    await Future.delayed(const Duration(seconds: 2));
    
    return PaymentResult(
      success: true,
      message: 'Thanh toán ví điện tử thành công',
      transactionId: 'EW_${DateTime.now().millisecondsSinceEpoch}',
      provider: PaymentProvider.eWallet,
      additionalData: {
        'wallet_type': 'MoMo',
        'phone_number': '090****123',
      },
    );
  }

  /// Process Hotel payment (pay at hotel)
  Future<PaymentResult> _processHotelPayment({
    required double amount,
    required String orderId,
    required String description,
    Map<String, dynamic>? additionalData,
  }) async {
    // Hotel payment is always successful as it's paid at hotel
    await Future.delayed(const Duration(seconds: 1));
    
    return PaymentResult(
      success: true,
      message: 'Đặt phòng thành công - Thanh toán tại khách sạn',
      transactionId: 'HOTEL_${DateTime.now().millisecondsSinceEpoch}',
      provider: PaymentProvider.hotelPayment,
      additionalData: {
        'payment_method': 'Pay at hotel',
        'confirmation_required': true,
      },
    );
  }

  /// Get payment provider display name
  String getProviderDisplayName(PaymentProvider provider) {
    switch (provider) {
      case PaymentProvider.vnpay:
        return 'VNPay';
      case PaymentProvider.vietqr:
        return 'VietQR';
      case PaymentProvider.creditCard:
        return 'Thẻ tín dụng';
      case PaymentProvider.eWallet:
        return 'Ví điện tử';
      case PaymentProvider.hotelPayment:
        return 'Thanh toán tại khách sạn';
    }
  }

  /// Get payment provider icon
  IconData getProviderIcon(PaymentProvider provider) {
    switch (provider) {
      case PaymentProvider.vnpay:
        return Icons.payment;
      case PaymentProvider.vietqr:
        return Icons.qr_code;
      case PaymentProvider.creditCard:
        return Icons.credit_card;
      case PaymentProvider.eWallet:
        return Icons.account_balance_wallet;
      case PaymentProvider.hotelPayment:
        return Icons.hotel;
    }
  }

  /// Get payment provider color
  Color getProviderColor(PaymentProvider provider) {
    switch (provider) {
      case PaymentProvider.vnpay:
        return Colors.red;
      case PaymentProvider.vietqr:
        return Colors.purple;
      case PaymentProvider.creditCard:
        return Colors.blue;
      case PaymentProvider.eWallet:
        return Colors.green;
      case PaymentProvider.hotelPayment:
        return Colors.orange;
    }
  }
}

class PaymentResult {
  final bool success;
  final String message;
  final String? transactionId;
  final PaymentProvider provider;
  final Map<String, dynamic>? additionalData;

  PaymentResult({
    required this.success,
    required this.message,
    this.transactionId,
    required this.provider,
    this.additionalData,
  });

  @override
  String toString() {
    return 'PaymentResult{success: $success, message: $message, transactionId: $transactionId, provider: $provider}';
  }
}
