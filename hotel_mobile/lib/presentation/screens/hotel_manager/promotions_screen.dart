import 'package:flutter/material.dart';
import '../../../data/services/booking_service.dart';
import '../../../data/services/api_service.dart';
import '../../../data/models/promotion.dart';

class PromotionsScreen extends StatefulWidget {
  const PromotionsScreen({super.key});

  @override
  State<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen> {
  final BookingService _bookingService = BookingService();
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _promotions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPromotions();
  }

  Future<void> _loadPromotions() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final promotions = await _bookingService.getPromotions();
      setState(() {
        _promotions = promotions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Khuyến mãi',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _showAddPromotionDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadPromotions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorWidget()
          : _buildPromotionsList(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Có lỗi xảy ra',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Không thể tải dữ liệu',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
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

  Widget _buildPromotionsList() {
    if (_promotions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_offer_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Chưa có khuyến mãi nào',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPromotions,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _promotions.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final promotion = _promotions[index];
          return _buildPromotionCard(promotion);
        },
      ),
    );
  }

  Widget _buildPromotionCard(Map<String, dynamic> promotion) {
    final title = promotion['title'] ?? 'N/A';
    final description = promotion['description'] ?? 'N/A';
    final discount = promotion['discount'] ?? 0.0;
    final discountType = promotion['discountType'] ?? 'percentage';
    final startDate = promotion['startDate'];
    final endDate = promotion['endDate'];
    final isActive = promotion['isActive'] ?? false;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showPromotionDetail(promotion),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.green.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isActive ? 'Đang hoạt động' : 'Không hoạt động',
                      style: TextStyle(
                        color: isActive ? Colors.green : Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Description
              Text(
                description,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // Discount info
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      discountType == 'percentage'
                          ? '${discount.toStringAsFixed(0)}%'
                          : '${discount.toStringAsFixed(0)} VNĐ',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (startDate != null && endDate != null)
                    Text(
                      '${_formatDate(startDate)} - ${_formatDate(endDate)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () => _showEditPromotionDialog(promotion),
                    icon: const Icon(Icons.edit, size: 20),
                    tooltip: 'Chỉnh sửa',
                  ),
                  IconButton(
                    onPressed: () => _showDeleteConfirmation(promotion),
                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                    tooltip: 'Xóa',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPromotionDetail(Map<String, dynamic> promotion) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Title
              Text(
                'Chi tiết khuyến mãi',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Tiêu đề', promotion['title'] ?? 'N/A'),
                      _buildDetailRow(
                        'Mô tả',
                        promotion['description'] ?? 'N/A',
                      ),
                      _buildDetailRow(
                        'Loại giảm giá',
                        promotion['discountType'] == 'percentage'
                            ? 'Phần trăm'
                            : 'Số tiền',
                      ),
                      _buildDetailRow(
                        'Giá trị giảm',
                        promotion['discountType'] == 'percentage'
                            ? '${promotion['discount']?.toStringAsFixed(0) ?? '0'}%'
                            : '${promotion['discount']?.toStringAsFixed(0) ?? '0'} VNĐ',
                      ),
                      _buildDetailRow(
                        'Ngày bắt đầu',
                        promotion['startDate'] != null
                            ? _formatDate(promotion['startDate'])
                            : 'N/A',
                      ),
                      _buildDetailRow(
                        'Ngày kết thúc',
                        promotion['endDate'] != null
                            ? _formatDate(promotion['endDate'])
                            : 'N/A',
                      ),
                      _buildDetailRow(
                        'Trạng thái',
                        promotion['isActive'] == true
                            ? 'Đang hoạt động'
                            : 'Không hoạt động',
                      ),
                      _buildDetailRow(
                        'Điều kiện',
                        promotion['conditions'] ?? 'Không có điều kiện',
                      ),
                    ],
                  ),
                ),
              ),
              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showEditPromotionDialog(promotion);
                      },
                      child: const Text('Chỉnh sửa'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Đóng'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddPromotionDialog() {
    showDialog(
      context: context,
      builder: (context) => _PromotionDialog(
        onSave: (promotionData) async {
          await _createPromotion(promotionData);
        },
      ),
    );
  }

  Future<void> _createPromotion(Map<String, dynamic> promotionData) async {
    try {
      // Convert to Promotion object
      final promotion = Promotion(
        id: 0, // Will be assigned by backend
        ten: promotionData['title'] ?? '',
        moTa: promotionData['description'] ?? '',
        phanTramGiam: (promotionData['value'] ?? 0.0).toDouble(),
        ngayBatDau: promotionData['startDate'] ?? DateTime.now(),
        ngayKetThuc:
            promotionData['endDate'] ??
            DateTime.now().add(const Duration(days: 30)),
        trangThai: promotionData['status'] ?? true,
        hinhAnh: promotionData['image'] ?? '',
      );

      final response = await _apiService.createPromotion(promotion);

      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thêm khuyến mãi thành công')),
          );
          _loadPromotions(); // Reload promotions
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Lỗi: ${response.message}')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tạo khuyến mãi: $e')));
      }
    }
  }

  void _showEditPromotionDialog(Map<String, dynamic> promotion) {
    showDialog(
      context: context,
      builder: (context) => _PromotionDialog(
        promotion: promotion,
        onSave: (promotionData) async {
          await _updatePromotion(promotion['id'], promotionData);
        },
      ),
    );
  }

  Future<void> _updatePromotion(
    int promotionId,
    Map<String, dynamic> promotionData,
  ) async {
    try {
      // Convert to Promotion object
      final promotion = Promotion(
        id: promotionId,
        ten: promotionData['title'] ?? '',
        moTa: promotionData['description'] ?? '',
        phanTramGiam: (promotionData['value'] ?? 0.0).toDouble(),
        ngayBatDau: promotionData['startDate'] ?? DateTime.now(),
        ngayKetThuc:
            promotionData['endDate'] ??
            DateTime.now().add(const Duration(days: 30)),
        trangThai: promotionData['status'] ?? true,
        hinhAnh: promotionData['image'] ?? '',
      );

      final response = await _apiService.updatePromotion(promotion);

      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật khuyến mãi thành công')),
          );
          _loadPromotions(); // Reload promotions
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Lỗi: ${response.message}')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi cập nhật khuyến mãi: $e')));
      }
    }
  }

  void _showDeleteConfirmation(Map<String, dynamic> promotion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc chắn muốn xóa khuyến mãi "${promotion['title']}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deletePromotion(promotion['id']);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePromotion(int promotionId) async {
    try {
      final response = await _apiService.deletePromotion(promotionId);

      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Xóa khuyến mãi thành công')),
          );
          _loadPromotions(); // Reload promotions
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Lỗi: ${response.message}')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi xóa khuyến mãi: $e')));
      }
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    // Assuming date is in ISO format or DateTime
    try {
      final dateTime = date is String ? DateTime.parse(date) : date as DateTime;
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    } catch (e) {
      return 'N/A';
    }
  }
}

class _PromotionDialog extends StatefulWidget {
  final Map<String, dynamic>? promotion;
  final Function(Map<String, dynamic>) onSave;

  const _PromotionDialog({this.promotion, required this.onSave});

  @override
  State<_PromotionDialog> createState() => _PromotionDialogState();
}

class _PromotionDialogState extends State<_PromotionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _discountController = TextEditingController();
  final _conditionsController = TextEditingController();
  String _discountType = 'percentage';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    if (widget.promotion != null) {
      _titleController.text = widget.promotion!['title'] ?? '';
      _descriptionController.text = widget.promotion!['description'] ?? '';
      _discountController.text =
          widget.promotion!['discount']?.toString() ?? '';
      _conditionsController.text = widget.promotion!['conditions'] ?? '';
      _discountType = widget.promotion!['discountType'] ?? 'percentage';
      _isActive = widget.promotion!['isActive'] ?? true;
      // Parse dates if available
      if (widget.promotion!['startDate'] != null) {
        _startDate = DateTime.tryParse(widget.promotion!['startDate']);
      }
      if (widget.promotion!['endDate'] != null) {
        _endDate = DateTime.tryParse(widget.promotion!['endDate']);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _discountController.dispose();
    _conditionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.promotion == null
            ? 'Thêm khuyến mãi mới'
            : 'Chỉnh sửa khuyến mãi',
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Tiêu đề',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập tiêu đề';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Mô tả',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mô tả';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _discountType,
                      decoration: const InputDecoration(
                        labelText: 'Loại giảm giá',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'percentage',
                          child: Text('Phần trăm (%)'),
                        ),
                        DropdownMenuItem(
                          value: 'amount',
                          child: Text('Số tiền (VNĐ)'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _discountType = value!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _discountController,
                      decoration: InputDecoration(
                        labelText: _discountType == 'percentage'
                            ? 'Phần trăm'
                            : 'Số tiền',
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập giá trị';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Vui lòng nhập số hợp lệ';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Ngày bắt đầu',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _startDate != null
                              ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                              : 'Chọn ngày',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, false),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Ngày kết thúc',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _endDate != null
                              ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                              : 'Chọn ngày',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _conditionsController,
                decoration: const InputDecoration(
                  labelText: 'Điều kiện áp dụng',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Trạng thái hoạt động'),
                subtitle: Text(
                  _isActive ? 'Đang hoạt động' : 'Không hoạt động',
                ),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _savePromotion,
          child: Text(widget.promotion == null ? 'Thêm' : 'Cập nhật'),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now()),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _savePromotion() {
    if (_formKey.currentState!.validate()) {
      if (_startDate == null || _endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng chọn ngày bắt đầu và kết thúc'),
          ),
        );
        return;
      }

      final promotionData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'discount': double.parse(_discountController.text),
        'discountType': _discountType,
        'startDate': _startDate!.toIso8601String(),
        'endDate': _endDate!.toIso8601String(),
        'conditions': _conditionsController.text,
        'isActive': _isActive,
      };

      widget.onSave(promotionData);
      Navigator.pop(context);
    }
  }
}
