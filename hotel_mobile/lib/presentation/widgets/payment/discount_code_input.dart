import 'package:flutter/material.dart';
import '../../../data/services/discount_service.dart';
import 'discount_code_list_sheet.dart';

/// Widget để nhập và áp dụng mã giảm giá
/// 
/// Features:
/// - Input field để nhập mã
/// - Nút "Áp dụng" để validate mã
/// - Hiển thị thông báo mã hợp lệ/không hợp lệ
/// - Hiển thị số tiền giảm giá nếu mã hợp lệ
/// - Nút "Xóa" để remove mã đã áp dụng
class DiscountCodeInput extends StatefulWidget {
  /// Callback khi mã giảm giá được áp dụng thành công
  /// Trả về discount amount (số tiền giảm)
  final Function(String code, double discountAmount) onDiscountApplied;
  
  /// Callback khi mã giảm giá bị xóa
  final VoidCallback onDiscountRemoved;
  
  /// Giá gốc để tính discount
  final double originalPrice;
  
  /// ID khách sạn (không bắt buộc - mã giảm giá áp dụng cho tất cả khách sạn)
  /// Lưu ý: Mã giảm giá khác với Ưu đãi - Ưu đãi chỉ áp dụng cho khách sạn cụ thể
  final int? hotelId;
  
  /// ID địa điểm (không bắt buộc - mã giảm giá áp dụng cho tất cả địa điểm)
  final int? locationId;
  
  /// Mã giảm giá đã được áp dụng sẵn (tự động)
  final String? initialCode;
  
  /// Số tiền giảm giá đã được tính sẵn (nếu có initialCode)
  final double? initialDiscountAmount;

  const DiscountCodeInput({
    super.key,
    required this.onDiscountApplied,
    required this.onDiscountRemoved,
    required this.originalPrice,
    this.hotelId,
    this.locationId,
    this.initialCode,
    this.initialDiscountAmount,
  });

  @override
  State<DiscountCodeInput> createState() => _DiscountCodeInputState();
}

class _DiscountCodeInputState extends State<DiscountCodeInput> {
  final TextEditingController _codeController = TextEditingController();
  final DiscountService _discountService = DiscountService();
  
  bool _isLoading = false;
  bool _isApplied = false;
  String? _appliedCode;
  double _discountAmount = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    
    // Nếu có initial code, tự động áp dụng
    if (widget.initialCode != null && widget.initialCode!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _applyInitialCode();
      });
    }
  }

  @override
  void didUpdateWidget(DiscountCodeInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Cập nhật khi initialCode thay đổi (ví dụ: khi mã được tự động áp dụng)
    if (widget.initialCode != null && 
        widget.initialCode!.isNotEmpty && 
        widget.initialCode != oldWidget.initialCode) {
      // Chỉ cập nhật nếu chưa có mã nào được áp dụng, hoặc mã mới khác mã cũ
      if (!_isApplied || _appliedCode != widget.initialCode) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _applyInitialCode();
        });
      }
    } else if (widget.initialCode == null || widget.initialCode!.isEmpty) {
      // Nếu initialCode bị xóa, xóa mã đã áp dụng
      if (_isApplied && oldWidget.initialCode != null && oldWidget.initialCode!.isNotEmpty) {
        _removeDiscountCode();
      }
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }
  
  /// Áp dụng mã giảm giá ban đầu (tự động)
  void _applyInitialCode() {
    if (widget.initialCode == null || widget.initialCode!.isEmpty) return;
    
    final discountAmount = widget.initialDiscountAmount ?? 0;
    
    // Chỉ áp dụng nếu chưa có mã nào được áp dụng, hoặc mã mới khác mã cũ
    if ((!_isApplied || _appliedCode != widget.initialCode) && discountAmount > 0) {
      setState(() {
        _isApplied = true;
        _appliedCode = widget.initialCode;
        _discountAmount = discountAmount;
        _codeController.text = widget.initialCode!;
        _errorMessage = null; // Xóa lỗi nếu có
      });
      
      print('✅ Applied initial discount code: ${widget.initialCode} - ${discountAmount.toStringAsFixed(0)}₫');
      
      // Callback to parent (chỉ gọi nếu mã thực sự thay đổi)
      if (_appliedCode != widget.initialCode) {
        widget.onDiscountApplied(widget.initialCode!, discountAmount);
      }
    } else if (_isApplied && _appliedCode == widget.initialCode) {
      // Nếu mã đã được áp dụng và giống với initialCode, chỉ cập nhật discountAmount nếu khác
      if (_discountAmount != discountAmount && discountAmount > 0) {
        setState(() {
          _discountAmount = discountAmount;
        });
      }
    }
  }

  /// Validate và áp dụng mã giảm giá
  Future<void> _applyDiscountCode() async {
    final code = _codeController.text.trim().toUpperCase();
    
    if (code.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập mã giảm giá';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Call API to validate discount code
      final response = await _discountService.validateDiscountCode(
        code: code,
        orderAmount: widget.originalPrice,
        hotelId: widget.hotelId,
        locationId: widget.locationId,
      );
      
      if (response['success']) {
        final discountAmount = (response['discountAmount'] ?? 0).toDouble();
        
        if (discountAmount > 0) {
          setState(() {
            _isApplied = true;
            _appliedCode = code;
            _discountAmount = discountAmount;
            _isLoading = false;
          });
          
          // Callback to parent
          widget.onDiscountApplied(code, _discountAmount);
          
          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Áp dụng mã $code thành công! Giảm ${_formatCurrency(_discountAmount)}'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } else {
          setState(() {
            _errorMessage = 'Mã giảm giá không áp dụng được cho đơn hàng này';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Mã giảm giá không hợp lệ';
          _isLoading = false;
        });
        
        // Show error message nếu cần đăng nhập
        if (response['requiresLogin'] == true && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Vui lòng đăng nhập để sử dụng mã giảm giá'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Đăng nhập',
                textColor: Colors.white,
                onPressed: () {
                  // TODO: Navigate to login screen
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi kết nối. Vui lòng thử lại';
        _isLoading = false;
      });
    }
  }

  /// Remove mã giảm giá đã áp dụng
  void _removeDiscountCode() {
    setState(() {
      _isApplied = false;
      _appliedCode = null;
      _discountAmount = 0;
      _errorMessage = null;
      _codeController.clear();
    });
    
    widget.onDiscountRemoved();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xóa mã giảm giá'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Hiển thị bottom sheet danh sách mã giảm giá
  void _showDiscountCodeList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => DiscountCodeListSheet(
          originalPrice: widget.originalPrice,
          hotelId: widget.hotelId,
          locationId: widget.locationId,
          currentAppliedCode: _appliedCode,
          scrollController: scrollController,
          onCodeSelected: (code, discountAmount) {
            // Áp dụng mã được chọn
            setState(() {
              _isApplied = true;
              _appliedCode = code;
              _discountAmount = discountAmount;
              _codeController.text = code;
              _errorMessage = null;
            });
            
            // Callback to parent
            widget.onDiscountApplied(code, discountAmount);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.local_offer,
                  color: Colors.orange.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Mã giảm giá',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Nút xem danh sách mã giảm giá
                TextButton.icon(
                  onPressed: _showDiscountCodeList,
                  icon: Icon(
                    Icons.list,
                    size: 18,
                    color: Colors.blue.shade600,
                  ),
                  label: Text(
                    'Xem danh sách',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Nếu chưa áp dụng mã - hiển thị input
            if (!_isApplied) ...[
              Row(
                children: [
                  // Text field
                  Expanded(
                    child: TextField(
                      controller: _codeController,
                      decoration: InputDecoration(
                        hintText: 'Nhập mã giảm giá',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: Icon(Icons.confirmation_number, color: Colors.grey[600]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
                        ),
                        errorText: _errorMessage,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      onSubmitted: (_) => _applyDiscountCode(),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Apply button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _applyDiscountCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Áp dụng',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                  ),
                ],
              ),
              
              // Suggestion hint
              const SizedBox(height: 12),
              Text(
                '💡 Nhập mã giảm giá để được ưu đãi ngay!',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            
            // Nếu đã áp dụng mã - hiển thị thông tin
            if (_isApplied) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green.shade700,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mã $_appliedCode đã áp dụng',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade900,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Giảm ${_formatCurrency(_discountAmount)}',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _removeDiscountCode,
                      icon: Icon(Icons.close, color: Colors.red.shade600),
                      tooltip: 'Xóa mã',
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}₫';
  }
}

