import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'payment_options.dart';

class PriceBreakdownCard extends StatelessWidget {
  final double basePrice;
  final double serviceFeeByCurrency;
  final double discountAmount;
  final double finalTotal;
  final int nights;
  final int roomCount;
  final bool requiresDeposit;
  final double depositAmount;
  final double fullTotal;
  final PaymentMethod paymentMethod;
  final double? additionalServicesTotal; // ✅ NEW: Total for additional services

  const PriceBreakdownCard({
    super.key,
    required this.basePrice,
    required this.serviceFeeByCurrency,
    required this.discountAmount,
    required this.finalTotal,
    required this.nights,
    this.roomCount = 1,
    this.requiresDeposit = false,
    this.depositAmount = 0,
    this.fullTotal = 0,
    this.paymentMethod = PaymentMethod.vnpay,
    this.additionalServicesTotal, // ✅ NEW
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.receipt_long, color: Colors.green[600], size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Chi tiết giá',
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

            // Giá phòng
            _buildPriceRow(
              title: roomCount > 1 
                  ? 'Giá phòng ($nights đêm × $roomCount phòng)'
                  : 'Giá phòng ($nights đêm)',
              amount: basePrice,
              currencyFormat: currencyFormat,
            ),

            const SizedBox(height: 12),

            // Phí dịch vụ
            _buildPriceRow(
              title: 'Phí dịch vụ',
              amount: serviceFeeByCurrency,
              currencyFormat: currencyFormat,
            ),

            // ✅ NEW: Dịch vụ bổ sung (nếu có)
            if (additionalServicesTotal != null && additionalServicesTotal! > 0) ...[
              const SizedBox(height: 12),
              _buildPriceRow(
                title: 'Dịch vụ bổ sung',
                amount: additionalServicesTotal!,
                currencyFormat: currencyFormat,
              ),
            ],

            // Giảm giá (nếu có)
            if (discountAmount > 0) ...[
              const SizedBox(height: 12),
              _buildPriceRow(
                title: 'Giảm giá',
                amount: -discountAmount,
                currencyFormat: currencyFormat,
                isDiscount: true,
              ),
            ],

            const SizedBox(height: 20),
            Divider(height: 1, thickness: 1, color: Colors.grey[300]),

            const SizedBox(height: 16),

            // Tổng tiền trước cọc
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  requiresDeposit ? 'Tổng giá trị' : 'Tổng cộng',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  currencyFormat.format(requiresDeposit ? fullTotal : finalTotal),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),

            // Hiển thị thông tin cọc nếu người dùng chọn cọc 50%
            if (requiresDeposit) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange[200]!,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.orange[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Bạn đã chọn thanh toán cọc 50%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[900],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Cọc 50% (bắt buộc)',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          currencyFormat.format(depositAmount),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Số tiền còn lại sẽ thanh toán khi nhận phòng',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Tổng thanh toán (cọc)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Thanh toán ngay',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    currencyFormat.format(finalTotal),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow({
    required String title,
    required double amount,
    required NumberFormat currencyFormat,
    bool isDiscount = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        Text(
          currencyFormat.format(amount.abs()),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDiscount ? Colors.green[700] : Colors.black87,
          ),
        ),
      ],
    );
  }
}