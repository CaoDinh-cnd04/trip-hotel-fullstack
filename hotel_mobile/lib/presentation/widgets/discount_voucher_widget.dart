import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/models/discount_voucher.dart';
import '../../../data/services/promotion_service.dart';

class DiscountVoucherWidget extends StatefulWidget {
  final double orderAmount;
  final Function(DiscountVoucher?, double) onVoucherApplied;
  final DiscountVoucher? appliedVoucher;

  const DiscountVoucherWidget({
    Key? key,
    required this.orderAmount,
    required this.onVoucherApplied,
    this.appliedVoucher,
  }) : super(key: key);

  @override
  State<DiscountVoucherWidget> createState() => _DiscountVoucherWidgetState();
}

class _DiscountVoucherWidgetState extends State<DiscountVoucherWidget> {
  final TextEditingController _voucherController = TextEditingController();
  final PromotionService _promotionService = PromotionService();

  bool _isValidating = false;
  bool _showMyVouchers = false;
  List<DiscountVoucher> _myVouchers = [];
  bool _loadingMyVouchers = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.appliedVoucher != null) {
      _voucherController.text = widget.appliedVoucher!.maGiamGia;
    }
  }

  @override
  void dispose() {
    _voucherController.dispose();
    super.dispose();
  }

  Future<void> _validateVoucherCode() async {
    final voucherCode = _voucherController.text.trim();
    if (voucherCode.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập mã giảm giá');
      return;
    }

    setState(() {
      _isValidating = true;
      _errorMessage = null;
    });

    try {
      final result = await _promotionService.validateDiscountVoucher(
        voucherCode,
        widget.orderAmount,
      );

      if (result['success'] && result['isValid']) {
        final voucher = result['voucher'] as DiscountVoucher?;
        final discountAmount = result['discountAmount'] as double;

        if (voucher != null) {
          widget.onVoucherApplied(voucher, discountAmount);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Áp dụng mã thành công! Giảm ${discountAmount.toStringAsFixed(0)}đ',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Mã giảm giá không hợp lệ';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi kết nối mạng';
      });
    } finally {
      setState(() => _isValidating = false);
    }
  }

  Future<void> _loadMyVouchers() async {
    if (_loadingMyVouchers) return;

    setState(() => _loadingMyVouchers = true);

    try {
      final vouchers = await _promotionService.getMyDiscountVouchers();
      setState(() {
        _myVouchers = vouchers.where((v) => v.isValid).toList();
        _showMyVouchers = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải mã giảm giá: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _loadingMyVouchers = false);
    }
  }

  void _selectVoucher(DiscountVoucher voucher) {
    _voucherController.text = voucher.maGiamGia;
    setState(() => _showMyVouchers = false);
    _validateVoucherCode();
  }

  void _removeVoucher() {
    _voucherController.clear();
    widget.onVoucherApplied(null, 0);
    setState(() {
      _errorMessage = null;
      _showMyVouchers = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
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
          Row(
            children: [
              Icon(Icons.local_offer, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              const Text(
                'Mã giảm giá',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (widget.appliedVoucher != null)
                GestureDetector(
                  onTap: _removeVoucher,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(Icons.close, size: 16, color: Colors.red[600]),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (widget.appliedVoucher != null) ...[
            _buildAppliedVoucherCard(),
          ] else ...[
            _buildVoucherInput(),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red[600], fontSize: 12),
              ),
            ],
            const SizedBox(height: 12),
            _buildMyVouchersButton(),
          ],

          if (_showMyVouchers) ...[
            const SizedBox(height: 16),
            _buildMyVouchersList(),
          ],
        ],
      ),
    );
  }

  Widget _buildAppliedVoucherCard() {
    final voucher = widget.appliedVoucher!;
    final discountAmount = voucher.calculateDiscountAmount(widget.orderAmount);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[50]!, Colors.green[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[600], size: 18),
              const SizedBox(width: 6),
              const Text(
                'Đã áp dụng mã',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            voucher.tenMaGiamGia,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'Mã: ${voucher.maGiamGia}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const Spacer(),
              Text(
                '- ${discountAmount.toStringAsFixed(0)}đ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherInput() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _voucherController,
            decoration: InputDecoration(
              hintText: 'Nhập mã giảm giá',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.blue),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              suffixIcon: _voucherController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _voucherController.clear();
                        setState(() => _errorMessage = null);
                      },
                      icon: Icon(
                        Icons.clear,
                        color: Colors.grey[400],
                        size: 18,
                      ),
                    )
                  : null,
            ),
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
            ],
            onChanged: (value) {
              setState(() => _errorMessage = null);
            },
            onFieldSubmitted: (_) => _validateVoucherCode(),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _isValidating ? null : _validateVoucherCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: _isValidating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Áp dụng',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildMyVouchersButton() {
    return GestureDetector(
      onTap: _loadingMyVouchers ? null : _loadMyVouchers,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_loadingMyVouchers) ...[
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
              const Text('Đang tải...'),
            ] else ...[
              Icon(Icons.card_giftcard, color: Colors.blue[600], size: 16),
              const SizedBox(width: 8),
              Text(
                'Chọn từ mã của tôi',
                style: TextStyle(
                  color: Colors.blue[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMyVouchersList() {
    if (_myVouchers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'Bạn chưa có mã giảm giá nào',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _myVouchers.length,
        separatorBuilder: (context, index) =>
            Divider(height: 1, color: Colors.grey[200]),
        itemBuilder: (context, index) {
          final voucher = _myVouchers[index];
          final isApplicable =
              voucher.giaTriDonHangToiThieu == null ||
              widget.orderAmount >= voucher.giaTriDonHangToiThieu!;

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            title: Text(
              voucher.tenMaGiamGia,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isApplicable ? Colors.black : Colors.grey,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  voucher.discountDescription,
                  style: TextStyle(
                    fontSize: 12,
                    color: isApplicable ? Colors.blue[600] : Colors.grey,
                  ),
                ),
                if (voucher.minimumOrderDescription != null)
                  Text(
                    voucher.minimumOrderDescription!,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
              ],
            ),
            trailing: isApplicable
                ? Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.grey[400],
                  )
                : Text(
                    'Không đủ ĐK',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
            onTap: isApplicable ? () => _selectVoucher(voucher) : null,
          );
        },
      ),
    );
  }
}
