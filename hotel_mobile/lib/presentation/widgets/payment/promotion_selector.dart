import 'package:flutter/material.dart';
import 'package:hotel_mobile/data/models/promotion.dart';
import 'package:hotel_mobile/data/services/promotion_service.dart';
import 'package:hotel_mobile/core/utils/currency_formatter.dart';

/// Widget để chọn và áp dụng promotion (ưu đãi)
/// 
/// Hiển thị:
/// - Nút "Chọn ưu đãi" để mở bottom sheet
/// - Bottom sheet với danh sách promotions active
/// - Promotion đã chọn với badge và nút xóa
/// 
/// Callbacks:
/// - onPromotionApplied(Promotion, double discountAmount)
/// - onPromotionRemoved()
class PromotionSelector extends StatefulWidget {
  /// Tổng tiền đơn hàng (để validate promotion)
  final double orderAmount;
  
  /// Ngày check-in (để kiểm tra điều kiện thời gian)
  final DateTime? checkInDate;
  
  /// Callback khi áp dụng promotion thành công
  final Function(Promotion promotion, double discountAmount) onPromotionApplied;
  
  /// Callback khi xóa promotion
  final VoidCallback onPromotionRemoved;

  const PromotionSelector({
    super.key,
    required this.orderAmount,
    this.checkInDate,
    required this.onPromotionApplied,
    required this.onPromotionRemoved,
  });

  @override
  State<PromotionSelector> createState() => _PromotionSelectorState();
}

class _PromotionSelectorState extends State<PromotionSelector> {
  final PromotionService _promotionService = PromotionService();
  
  /// Promotion đã chọn
  Promotion? _selectedPromotion;
  
  /// Số tiền được giảm từ promotion
  double _discountAmount = 0;
  
  /// Trạng thái loading
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.card_giftcard, color: Colors.orange[700], size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Ưu đãi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Selected Promotion hoặc Button chọn
            if (_selectedPromotion != null)
              _buildSelectedPromotion()
            else
              _buildSelectPromotionButton(),
          ],
        ),
      ),
    );
  }

  /// Build button để chọn promotion
  Widget _buildSelectPromotionButton() {
    return OutlinedButton.icon(
      onPressed: _isLoading ? null : _showPromotionBottomSheet,
      icon: const Icon(Icons.local_offer),
      label: const Text('Chọn ưu đãi'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.blue[700],
        side: BorderSide(color: Colors.blue[300]!),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  /// Build promotion đã chọn
  Widget _buildSelectedPromotion() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange[700],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.card_giftcard,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          
          // Promotion info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedPromotion!.ten,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Giảm ${CurrencyFormatter.formatVND(_discountAmount)}',
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          // Remove button
          IconButton(
            onPressed: _removePromotion,
            icon: const Icon(Icons.close, size: 20),
            color: Colors.grey[600],
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  /// Hiển thị bottom sheet chọn promotion
  void _showPromotionBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return _PromotionListBottomSheet(
            scrollController: scrollController,
            orderAmount: widget.orderAmount,
            checkInDate: widget.checkInDate,
            onPromotionSelected: _applyPromotion,
          );
        },
      ),
    );
  }

  /// Áp dụng promotion
  Future<void> _applyPromotion(Promotion promotion) async {
    setState(() => _isLoading = true);
    
    // Validate promotion với backend (bao gồm check-in date để kiểm tra điều kiện thời gian)
    final response = await _promotionService.validatePromotion(
      promotionId: promotion.id!,
      orderAmount: widget.orderAmount,
      checkInDate: widget.checkInDate,
    );
    
    setState(() => _isLoading = false);
    
    if (response['success'] && response['isValid']) {
      final discountAmount = response['discountAmount'] ?? 0.0;
      
      setState(() {
        _selectedPromotion = promotion;
        _discountAmount = discountAmount;
      });
      
      // Callback to parent
      widget.onPromotionApplied(promotion, discountAmount);
      
      // Đóng bottom sheet
      if (mounted) {
        Navigator.of(context).pop();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã áp dụng ưu đãi: ${promotion.ten}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      // Show error với lý do cụ thể
      final errorMessage = response['timeValidationReason'] ?? 
                          response['message'] ?? 
                          'Không thể áp dụng ưu đãi này';
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Đóng',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  /// Xóa promotion đã chọn
  void _removePromotion() {
    setState(() {
      _selectedPromotion = null;
      _discountAmount = 0;
    });
    
    // Callback to parent
    widget.onPromotionRemoved();
  }
}

/// Bottom sheet hiển thị danh sách promotions
class _PromotionListBottomSheet extends StatefulWidget {
  final ScrollController scrollController;
  final double orderAmount;
  final DateTime? checkInDate;
  final Function(Promotion) onPromotionSelected;

  const _PromotionListBottomSheet({
    required this.scrollController,
    required this.orderAmount,
    this.checkInDate,
    required this.onPromotionSelected,
  });

  @override
  State<_PromotionListBottomSheet> createState() => _PromotionListBottomSheetState();
}

class _PromotionListBottomSheetState extends State<_PromotionListBottomSheet> {
  final PromotionService _promotionService = PromotionService();
  List<Promotion> _promotions = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPromotions();
  }

  /// Load danh sách promotions
  Future<void> _loadPromotions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    final response = await _promotionService.getActivePromotions();
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (response['success']) {
          _promotions = response['data'] ?? [];
        } else {
          _errorMessage = response['message'] ?? 'Không thể tải danh sách ưu đãi';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          
          // Header
          Row(
            children: [
              Icon(Icons.card_giftcard, color: Colors.orange[700]),
              const SizedBox(width: 12),
              const Text(
                'Chọn ưu đãi',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  /// Build content dựa vào state
  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPromotions,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }
    
    if (_promotions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.card_giftcard_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Chưa có ưu đãi nào',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }
    
    // List of promotions
    return ListView.builder(
      controller: widget.scrollController,
      itemCount: _promotions.length,
      itemBuilder: (context, index) {
        final promotion = _promotions[index];
        return _buildPromotionCard(promotion);
      },
    );
  }

  /// Build promotion card
  Widget _buildPromotionCard(Promotion promotion) {
    final now = DateTime.now();
    final isExpired = now.isAfter(promotion.ngayKetThuc);
    final daysLeft = promotion.ngayKetThuc.difference(now).inDays;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: isExpired ? null : () => widget.onPromotionSelected(promotion),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isExpired ? Colors.grey[200] : Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.local_offer,
                  color: isExpired ? Colors.grey[400] : Colors.orange[700],
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              
              // Promotion info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      promotion.ten,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isExpired ? Colors.grey[600] : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (promotion.moTa != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        promotion.moTa!,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Badge giảm giá
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isExpired ? Colors.grey[300] : Colors.orange[700],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Giảm ${promotion.phanTramGiam.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Thời gian còn lại
                        if (!isExpired)
                          Text(
                            'Còn $daysLeft ngày',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          )
                        else
                          Text(
                            'Đã hết hạn',
                            style: TextStyle(
                              color: Colors.red[400],
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Arrow icon
              if (!isExpired)
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

