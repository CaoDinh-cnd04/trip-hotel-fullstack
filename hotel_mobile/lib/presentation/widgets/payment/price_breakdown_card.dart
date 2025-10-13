import 'package:flutter/material.dart';

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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.receipt_long,
                  color: Colors.green[600],
                  size: 24,
                ),
              ),
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

          // Price Details
          _buildPriceRow(
            title: 'Giá phòng ($nights đêm)',
            amount: basePrice,
            isSubtotal: false,
          ),

          const SizedBox(height: 12),

          _buildPriceRow(
            title: 'Phí dịch vụ',
            amount: serviceFeeByCurrency,
            isSubtotal: false,
          ),

          if (discountAmount > 0) ...[
            const SizedBox(height: 12),
            _buildPriceRow(
              title: 'Giảm giá',
              amount: -discountAmount,
              isDiscount: true,
            ),
          ],

          const SizedBox(height: 16),

          // Divider
          Container(height: 1, color: Colors.grey[300]),

          const SizedBox(height: 16),

          // Total
          _buildPriceRow(title: 'Tổng tiền', amount: finalTotal, isTotal: true),

          const SizedBox(height: 12),

          // Additional Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.blue[600], size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Giá đã bao gồm thuế và phí. Không có phí ẩn.',
                    style: TextStyle(color: Colors.blue[700], fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow({
    required String title,
    required double amount,
    bool isTotal = false,
    bool isDiscount = false,
    bool isSubtotal = false,
  }) {
    final color = isTotal
        ? const Color(0xFF2196F3)
        : isDiscount
        ? Colors.green
        : Colors.black87;

    final fontSize = isTotal ? 18.0 : 16.0;
    final fontWeight = isTotal ? FontWeight.bold : FontWeight.w500;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
          ),
        ),
        Text(
          _formatCurrency(amount.abs()),
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} VNĐ';
  }
}
