/**
 * Màn hình kết quả thanh toán VNPay
 * Hiển thị kết quả sau khi thanh toán thành công hoặc thất bại
 * Giống giao diện VNPay sandbox
 */

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/currency_formatter.dart';

/// Màn hình hiển thị kết quả thanh toán VNPay
/// Được sử dụng để thông báo cho người dùng về trạng thái thanh toán
class VNPayPaymentResultScreen extends StatelessWidget {
  // Trạng thái thanh toán: true = thành công, false = thất bại
  final bool isSuccess;
  // Mã giao dịch từ VNPay
  final String? transactionNo;
  // Mã đơn hàng của ứng dụng
  final String? orderId;
  // Số tiền thanh toán
  final double? amount;
  // Thông báo kết quả từ VNPay
  final String? message;
  // Mã lỗi nếu có
  final String? errorCode;
  // Thời gian thực hiện thanh toán
  final DateTime? paymentTime;

  /// Constructor khởi tạo màn hình kết quả thanh toán
  /// [isSuccess] - Trạng thái thanh toán thành công hay thất bại
  /// [transactionNo] - Mã giao dịch VNPay
  /// [orderId] - Mã đơn hàng
  /// [amount] - Số tiền thanh toán
  /// [message] - Thông báo từ VNPay
  /// [errorCode] - Mã lỗi nếu thanh toán thất bại
  /// [paymentTime] - Thời điểm thanh toán
  const VNPayPaymentResultScreen({
    Key? key,
    required this.isSuccess,
    this.transactionNo,
    this.orderId,
    this.amount,
    this.message,
    this.errorCode,
    this.paymentTime,
  }) : super(key: key);

  /// Xây dựng giao diện chính của màn hình
  /// Bao gồm header VNPay, icon kết quả, thông tin chi tiết và nút hành động
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header VNPay với logo và thông tin cổng thanh toán
              _buildHeader(),

              const SizedBox(height: 40),

              // Icon kết quả: tick xanh cho thành công, X đỏ cho thất bại
              _buildResultIcon(),

              const SizedBox(height: 24),

              // Thông báo kết quả thanh toán
              _buildResultMessage(),

              const SizedBox(height: 40),

              // Card hiển thị chi tiết giao dịch thành công
              if (isSuccess && transactionNo != null) _buildSuccessDetails(),
              // Card hiển thị thông tin lỗi nếu thất bại
              if (!isSuccess) _buildErrorDetails(),

              const SizedBox(height: 40),

              // Các nút hành động: Quay lại, Thử lại
              _buildActionButtons(context),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  /// Xây dựng header của màn hình với logo VNPay và thông tin cổng thanh toán
  /// Bao gồm logo VNPay màu đỏ và text "CỔNG THANH TOÁN VNPAYQR"
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Phần logo và thông tin VNPay
          Row(
            children: [
              // Logo VNPay trong container màu đỏ nhạt
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFED1C24).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'VNPAY',
                  style: TextStyle(
                    color: Color(0xFFED1C24),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Thông tin text về cổng thanh toán
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Text "CỔNG THANH TOÁN" nhỏ màu xám
                  Text(
                    'CỔNG THANH TOÁN',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                      letterSpacing: 0.5,
                    ),
                  ),
                  // Text "VNPAYQR" lớn đậm màu đen
                  Text(
                    'VNPAYQR',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Nút đóng (X) ở góc phải
          const Icon(Icons.close, color: Colors.grey),
        ],
      ),
    );
  }

  /// Xây dựng icon kết quả thanh toán
  /// Hiển thị tick xanh nếu thành công, dấu X đỏ nếu thất bại
  Widget _buildResultIcon() {
    if (isSuccess) {
      // Icon thành công: tick xanh trong vòng tròn xanh nhạt
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.green[50],
          shape: BoxShape.circle,
          border: Border.all(color: Colors.green[300]!, width: 3),
        ),
        child: const Icon(Icons.check_circle, size: 70, color: Colors.green),
      );
    } else {
      // Icon thất bại: dấu X đỏ trong vòng tròn đỏ nhạt
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.red[50],
          shape: BoxShape.circle,
          border: Border.all(color: Colors.red[300]!, width: 3),
        ),
        child: const Icon(Icons.cancel, size: 70, color: Colors.red),
      );
    }
  }

  /// Xây dựng thông báo kết quả thanh toán
  /// Hiển thị tiêu đề và mô tả tương ứng với trạng thái thành công/thất bại
  Widget _buildResultMessage() {
    return Column(
      children: [
        // Tiêu đề kết quả: "Giao dịch thành công" hoặc "Giao dịch không thành công"
        Text(
          isSuccess ? 'Giao dịch thành công' : 'Giao dịch không thành công',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isSuccess ? Colors.green[700] : Colors.red[700],
          ),
        ),
        const SizedBox(height: 12),
        // Mô tả chi tiết theo trạng thái
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            isSuccess
                ? 'Cảm ơn bạn đã sử dụng VNPay' // Thông báo cảm ơn khi thành công
                : (message ??
                      'Vui lòng thử lại hoặc liên hệ hỗ trợ'), // Thông báo lỗi hoặc hướng dẫn
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  /// Xây dựng card hiển thị chi tiết giao dịch thành công
  /// Bao gồm mã giao dịch, mã đơn hàng, số tiền và thời gian thanh toán
  Widget _buildSuccessDetails() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề "Thông tin giao dịch"
          const Text(
            'Thông tin giao dịch',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          // Mã giao dịch VNPay
          _buildDetailRow('Mã giao dịch', transactionNo ?? '-'),
          // Mã đơn hàng (nếu có)
          if (orderId != null) _buildDetailRow('Mã đơn hàng', orderId!),
          // Số tiền đã thanh toán (định dạng tiền tệ)
          if (amount != null)
            _buildDetailRow('Số tiền', CurrencyFormatter.format(amount!)),
          // Thời gian thực hiện thanh toán
          _buildDetailRow(
            'Thời gian',
            paymentTime != null
                ? DateFormat('dd/MM/yyyy HH:mm:ss').format(paymentTime!)
                : DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now()),
          ),
        ],
      ),
    );
  }

  /// Xây dựng card hiển thị thông tin lỗi khi thanh toán thất bại
  /// Bao gồm mã lỗi và mô tả chi tiết lỗi
  Widget _buildErrorDetails() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề "Chi tiết lỗi" với icon cảnh báo
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red[700], size: 20),
              const SizedBox(width: 8),
              const Text(
                'Chi tiết lỗi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Mã lỗi từ VNPay (nếu có)
          if (errorCode != null) _buildDetailRow('Mã lỗi', errorCode!),
          // Mô tả chi tiết lỗi (nếu có)
          if (message != null) _buildDetailRow('Mô tả', message!),
        ],
      ),
    );
  }

  /// Xây dựng một hàng hiển thị thông tin chi tiết
  /// [label] - Nhãn mô tả (VD: "Mã giao dịch")
  /// [value] - Giá trị tương ứng (VD: "TXN123456")
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cột trái: Nhãn mô tả (có độ rộng cố định 100px)
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          // Cột phải: Giá trị tương ứng (căn phải)
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  /// Xây dựng các nút hành động ở cuối màn hình
  /// Bao gồm nút "Quay lại ứng dụng" và nút "Thử lại" (nếu thanh toán thất bại)
  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Nút chính: "Quay lại ứng dụng" (màu đỏ VNPay)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                // Đóng màn hình và quay lại màn hình trước
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFED1C24),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Quay lại ứng dụng',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          // Nút phụ: "Thử lại" (chỉ hiển thị khi thanh toán thất bại)
          if (!isSuccess) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                // Đóng màn hình hiện tại và quay lại màn hình thanh toán
                Navigator.of(context).pop();
                // TODO: Navigate back to payment screen
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey[300]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                'Thử lại',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
