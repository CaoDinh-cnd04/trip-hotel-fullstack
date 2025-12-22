import 'package:flutter/material.dart';
import '../../../data/services/discount_service.dart';
import '../../../core/utils/currency_formatter.dart';

/// Bottom sheet hiển thị danh sách mã giảm giá có sẵn
/// 
/// Cho phép người dùng:
/// - Xem danh sách tất cả mã giảm giá có sẵn
/// - Xem thông tin chi tiết mỗi mã (mô tả, giá trị giảm, điều kiện)
/// - Chọn mã để áp dụng
class DiscountCodeListSheet extends StatefulWidget {
  /// Giá gốc để tính discount
  final double originalPrice;
  
  /// ID khách sạn (tùy chọn)
  final int? hotelId;
  
  /// ID địa điểm (tùy chọn)
  final int? locationId;
  
  /// Mã giảm giá đang được áp dụng (nếu có)
  final String? currentAppliedCode;
  
  /// Scroll controller cho DraggableScrollableSheet
  final ScrollController? scrollController;
  
  /// Callback khi người dùng chọn mã giảm giá
  final Function(String code, double discountAmount) onCodeSelected;

  const DiscountCodeListSheet({
    super.key,
    required this.originalPrice,
    this.hotelId,
    this.locationId,
    this.currentAppliedCode,
    this.scrollController,
    required this.onCodeSelected,
  });

  @override
  State<DiscountCodeListSheet> createState() => _DiscountCodeListSheetState();
}

class _DiscountCodeListSheetState extends State<DiscountCodeListSheet> {
  final DiscountService _discountService = DiscountService();
  
  List<Map<String, dynamic>> _availableDiscounts = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  // Map để lưu discount amount đã tính cho mỗi mã
  final Map<String, double> _calculatedDiscounts = {};

  @override
  void initState() {
    super.initState();
    _loadDiscountCodes();
  }

  /// Load danh sách mã giảm giá có sẵn
  Future<void> _loadDiscountCodes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final discounts = await _discountService.getAvailableDiscounts();
      
      if (mounted) {
        setState(() {
          _availableDiscounts = discounts;
          _isLoading = false;
        });
        
        // Tính discount amount cho từng mã
        _calculateDiscountsForAllCodes();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Lỗi khi tải danh sách mã giảm giá';
          _isLoading = false;
        });
      }
    }
  }

  /// Tính discount amount cho tất cả mã giảm giá
  Future<void> _calculateDiscountsForAllCodes() async {
    for (final discount in _availableDiscounts) {
      final code = discount['code'] as String?;
      if (code == null || code.isEmpty) continue;
      
      try {
        final result = await _discountService.validateDiscountCode(
          code: code,
          orderAmount: widget.originalPrice,
          hotelId: widget.hotelId,
          locationId: widget.locationId,
        );
        
        if (result['success'] == true) {
          final discountAmount = (result['discountAmount'] ?? 0).toDouble();
          _calculatedDiscounts[code] = discountAmount;
        } else {
          _calculatedDiscounts[code] = 0;
        }
      } catch (e) {
        _calculatedDiscounts[code] = 0;
      }
    }
    
    if (mounted) {
      setState(() {});
    }
  }

  /// Xử lý khi người dùng chọn mã giảm giá
  void _handleCodeSelection(String code, double discountAmount) {
    if (discountAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mã giảm giá này không áp dụng được cho đơn hàng của bạn'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    // Gọi callback
    widget.onCodeSelected(code, discountAmount);
    
    // Đóng bottom sheet
    Navigator.of(context).pop();
    
    // Hiển thị thông báo thành công
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Đã áp dụng mã $code! Giảm ${CurrencyFormatter.formatVND(discountAmount)}'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.local_offer,
                  color: Colors.orange.shade700,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Danh sách mã giảm giá',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _errorMessage != null
                    ? Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.grey[600]),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadDiscountCodes,
                              child: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      )
                    : _availableDiscounts.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.inbox_outlined,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Hiện không có mã giảm giá nào',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: widget.scrollController,
                            itemCount: _availableDiscounts.length,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemBuilder: (context, index) {
                              final discount = _availableDiscounts[index];
                              final code = discount['code'] as String? ?? '';
                              final description = discount['description'] as String? ?? '';
                              final discountType = discount['discountType'] as String? ?? '';
                              final discountValue = (discount['discountValue'] ?? 0).toDouble();
                              final minOrderValue = (discount['minOrderValue'] ?? 0).toDouble();
                              final maxDiscountValue = (discount['maxDiscountValue'] as num?)?.toDouble();
                              
                              final calculatedAmount = _calculatedDiscounts[code] ?? 0;
                              final isApplied = widget.currentAppliedCode == code;
                              final canApply = calculatedAmount > 0;
                              
                              return _buildDiscountCard(
                                code: code,
                                description: description,
                                discountType: discountType,
                                discountValue: discountValue,
                                minOrderValue: minOrderValue,
                                maxDiscountValue: maxDiscountValue,
                                calculatedAmount: calculatedAmount,
                                isApplied: isApplied,
                                canApply: canApply,
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountCard({
    required String code,
    required String description,
    required String discountType,
    required double discountValue,
    required double minOrderValue,
    required double? maxDiscountValue,
    required double calculatedAmount,
    required bool isApplied,
    required bool canApply,
  }) {
    final isPercentage = discountType.toLowerCase().contains('phần trăm') || 
                        discountType.toLowerCase() == 'percentage';
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isApplied 
            ? Colors.green.shade50 
            : canApply 
                ? Colors.blue.shade50 
                : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isApplied 
              ? Colors.green.shade300 
              : canApply 
                  ? Colors.blue.shade200 
                  : Colors.grey.shade300,
          width: isApplied ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: canApply ? () => _handleCodeSelection(code, calculatedAmount) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Code badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isApplied 
                          ? Colors.green.shade600 
                          : Colors.orange.shade600,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      code,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Status badge
                  if (isApplied)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 14,
                            color: Colors.white,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Đang áp dụng',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (!canApply)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Không áp dụng được',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Description
              if (description.isNotEmpty)
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              
              const SizedBox(height: 8),
              
              // Discount info
              Row(
                children: [
                  Icon(
                    Icons.percent,
                    size: 16,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isPercentage
                        ? 'Giảm ${discountValue.toStringAsFixed(0)}%'
                        : 'Giảm ${CurrencyFormatter.formatVND(discountValue)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  if (maxDiscountValue != null && maxDiscountValue > 0)
                    Text(
                      ' (tối đa ${CurrencyFormatter.formatVND(maxDiscountValue)})',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
              
              // Calculated discount amount
              if (calculatedAmount > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.savings,
                        size: 16,
                        color: Colors.green.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Bạn sẽ tiết kiệm: ${CurrencyFormatter.formatVND(calculatedAmount)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Min order value
              if (minOrderValue > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Áp dụng cho đơn hàng từ ${CurrencyFormatter.formatVND(minOrderValue)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

