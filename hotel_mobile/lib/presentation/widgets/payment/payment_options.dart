import 'package:flutter/material.dart';

enum PaymentMethod { creditCard, eWallet, hotelPayment }

class PaymentOptions extends StatefulWidget {
  final PaymentMethod selectedMethod;
  final Function(PaymentMethod) onMethodChanged;

  const PaymentOptions({
    super.key,
    required this.selectedMethod,
    required this.onMethodChanged,
  });

  @override
  State<PaymentOptions> createState() => _PaymentOptionsState();
}

class _PaymentOptionsState extends State<PaymentOptions> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.grey[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payment, color: Colors.blue[600], size: 24),
                const SizedBox(width: 8),
                Text(
                  'Phương thức thanh toán',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Thẻ tín dụng/ghi nợ
            _buildPaymentOption(
              method: PaymentMethod.creditCard,
              title: 'Thẻ tín dụng/ghi nợ',
              subtitle: 'Visa, MasterCard, JCB',
              icon: Icons.credit_card,
              iconColor: Colors.blue[600]!,
            ),

            const SizedBox(height: 12),

            // Ví điện tử
            _buildPaymentOption(
              method: PaymentMethod.eWallet,
              title: 'Ví điện tử',
              subtitle: 'MoMo, ZaloPay, VNPay',
              icon: Icons.account_balance_wallet,
              iconColor: Colors.green[600]!,
            ),

            const SizedBox(height: 12),

            // Thanh toán tại khách sạn
            _buildPaymentOption(
              method: PaymentMethod.hotelPayment,
              title: 'Thanh toán tại khách sạn',
              subtitle: 'Tiền mặt hoặc thẻ tại quầy lễ tân',
              icon: Icons.hotel,
              iconColor: Colors.orange[600]!,
            ),

            const SizedBox(height: 16),

            // Thông tin bổ sung cho phương thức được chọn
            if (widget.selectedMethod == PaymentMethod.creditCard)
              _buildCreditCardInfo(),
            if (widget.selectedMethod == PaymentMethod.eWallet)
              _buildEWalletInfo(),
            if (widget.selectedMethod == PaymentMethod.hotelPayment)
              _buildHotelPaymentInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required PaymentMethod method,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    final isSelected = widget.selectedMethod == method;

    return GestureDetector(
      onTap: () => widget.onMethodChanged(method),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[50] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue[300]! : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Radio<PaymentMethod>(
              value: method,
              groupValue: widget.selectedMethod,
              onChanged: (PaymentMethod? value) {
                if (value != null) {
                  widget.onMethodChanged(value);
                }
              },
              activeColor: Colors.blue[600],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditCardInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.security, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Thông tin thẻ được mã hóa và bảo mật 100%',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[600], size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Bạn sẽ được chuyển đến trang thanh toán an toàn',
                  style: TextStyle(fontSize: 11, color: Colors.blue[600]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEWalletInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.flash_on, color: Colors.green[600], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Thanh toán nhanh chóng và tiện lợi qua ứng dụng',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHotelPaymentInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.schedule, color: Colors.orange[600], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Thanh toán khi nhận phòng tại khách sạn',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.cancel_outlined, color: Colors.orange[600], size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Có thể hủy miễn phí trước 24h',
                  style: TextStyle(fontSize: 11, color: Colors.orange[600]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
