import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PriceBreakdownCard extends StatelessWidget {
  final double basePrice;
  final double serviceFeeByCurrency;
  final double discountAmount;
  final double finalTotal;
  final int nights;

  const PriceBreakdownCard({
    super.key,
    required this.basePrice,
    required this.serviceFeeByCurrency,
    required this.discountAmount,
    required this.finalTotal,
    required this.nights,
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
              title: 'Giá phòng ($nights đêm)',
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

            // Tổng tiền
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tổng cộng',
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
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
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