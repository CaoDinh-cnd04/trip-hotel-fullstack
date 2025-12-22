/**
 * Màn hình kết quả thanh toán MoMo
 * Hiển thị kết quả sau khi thanh toán thành công hoặc thất bại
 * Giống giao diện VNPay nhưng với màu sắc MoMo
 */

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/currency_formatter.dart';

class MoMoPaymentResultScreen extends StatelessWidget {
  final bool isSuccess;
  final String? transactionNo;
  final String? orderId;
  final double? amount;
  final String? message;
  final String? errorCode;
  final DateTime? paymentTime;

  const MoMoPaymentResultScreen({
    Key? key,
    required this.isSuccess,
    this.transactionNo,
    this.orderId,
    this.amount,
    this.message,
    this.errorCode,
    this.paymentTime,
  }) : super(key: key);

  // MoMo colors
  static const Color momoPink = Color(0xFFD82D8B);
  static const Color momoDarkPink = Color(0xFFB91C72);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header MoMo
              _buildHeader(),
              
              const SizedBox(height: 40),
              
              // Result Icon & Message
              _buildResultIcon(),
              
              const SizedBox(height: 24),
              
              _buildResultMessage(),
              
              const SizedBox(height: 40),
              
              // Transaction Details Card
              if (isSuccess && transactionNo != null) _buildSuccessDetails(),
              if (!isSuccess) _buildErrorDetails(),
              
              const SizedBox(height: 40),
              
              // Action Buttons
              _buildActionButtons(context),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: momoPink.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'MOMO',
                  style: TextStyle(
                    color: momoPink,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VÍ ĐIỆN TỬ',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'MOMO',
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
          const Icon(Icons.close, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildResultIcon() {
    if (isSuccess) {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.green[50],
          shape: BoxShape.circle,
          border: Border.all(color: Colors.green[300]!, width: 3),
        ),
        child: const Icon(
          Icons.check_circle,
          size: 70,
          color: Colors.green,
        ),
      );
    } else {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.red[50],
          shape: BoxShape.circle,
          border: Border.all(color: Colors.red[300]!, width: 3),
        ),
        child: const Icon(
          Icons.cancel,
          size: 70,
          color: Colors.red,
        ),
      );
    }
  }

  Widget _buildResultMessage() {
    return Column(
      children: [
        Text(
          isSuccess ? 'Giao dịch thành công' : 'Giao dịch không thành công',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isSuccess ? Colors.green[700] : Colors.red[700],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            isSuccess
                ? 'Cảm ơn bạn đã sử dụng MoMo'
                : (message ?? 'Vui lòng thử lại hoặc liên hệ hỗ trợ'),
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
          const Text(
            'Thông tin giao dịch',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Mã giao dịch', transactionNo ?? '-'),
          if (orderId != null) _buildDetailRow('Mã đơn hàng', orderId!),
          if (amount != null)
            _buildDetailRow('Số tiền', CurrencyFormatter.format(amount!)),
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
          if (errorCode != null) _buildDetailRow('Mã lỗi', errorCode!),
          if (message != null) _buildDetailRow('Mô tả', message!),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
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

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Quay lại ứng dụng button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: momoPink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Quay lại ứng dụng',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (!isSuccess) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

