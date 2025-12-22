import 'package:flutter/material.dart';

/// Enum các phương thức thanh toán
enum PaymentMethod { momo, vnpay, cash }

class PaymentOptions extends StatefulWidget {
  final PaymentMethod selectedMethod;
  final Function(PaymentMethod) onMethodChanged;
  final int roomCount;
  final double totalAmount;
  final bool canUseCash;
  final bool mustUseOnlinePayment;

  const PaymentOptions({
    super.key,
    required this.selectedMethod,
    required this.onMethodChanged,
    this.roomCount = 1,
    this.totalAmount = 0,
    this.canUseCash = true,
    this.mustUseOnlinePayment = false,
  });

  @override
  State<PaymentOptions> createState() => _PaymentOptionsState();
}

class _PaymentOptionsState extends State<PaymentOptions> {
  @override
  Widget build(BuildContext context) {
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
                Icon(Icons.payment, color: Colors.indigo[600], size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Phương thức thanh toán',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Payment Methods
            _buildPaymentCard(
              method: PaymentMethod.momo,
              title: 'Ví MoMo',
              subtitle: 'Thanh toán nhanh qua ví điện tử',
              icon: Icons.account_balance_wallet,
              iconColor: const Color(0xFFD82D8B),
            ),

            const SizedBox(height: 12),

            _buildPaymentCard(
              method: PaymentMethod.vnpay,
              title: 'VNPay',
              subtitle: 'Thẻ ATM, Internet Banking, Ví điện tử',
              icon: Icons.account_balance,
              iconColor: const Color(0xFFED1C24),
            ),

            const SizedBox(height: 12),

            // Chỉ hiển thị Cash nếu đủ điều kiện
            if (widget.canUseCash && !widget.mustUseOnlinePayment)
              _buildPaymentCard(
                method: PaymentMethod.cash,
                title: 'Thanh toán tiền mặt',
                subtitle: 'Thanh toán trực tiếp tại khách sạn',
                icon: Icons.money,
                iconColor: Colors.green[600]!,
                isEnabled: true,
              )
            else if (!widget.mustUseOnlinePayment)
              // Hiển thị thông báo tại sao không thể dùng Cash
              _buildDisabledCashCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard({
    required PaymentMethod method,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    bool isEnabled = true,
  }) {
    final isSelected = widget.selectedMethod == method;

    return GestureDetector(
      onTap: isEnabled ? () => widget.onMethodChanged(method) : null,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.5,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? iconColor.withOpacity(0.1) : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? iconColor : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Radio<PaymentMethod>(
                value: method,
                groupValue: widget.selectedMethod,
                onChanged: isEnabled
                    ? (PaymentMethod? value) {
                        if (value != null) {
                          widget.onMethodChanged(value);
                        }
                      }
                    : null,
                activeColor: iconColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDisabledCashCard() {
    String reason = '';
    if (widget.mustUseOnlinePayment) {
      reason = 'Đặt từ 3 phòng trở lên chỉ được thanh toán online';
    } else if (widget.roomCount >= 2) {
      reason = 'Đặt từ 2 phòng trở lên không được thanh toán tiền mặt';
    } else if (widget.totalAmount > 3000000) {
      reason = 'Tổng giá trị trên 3 triệu không được thanh toán tiền mặt';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.money, color: Colors.grey[600], size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thanh toán tiền mặt',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reason,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[700],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.block, color: Colors.grey[400], size: 24),
        ],
      ),
    );
  }
}