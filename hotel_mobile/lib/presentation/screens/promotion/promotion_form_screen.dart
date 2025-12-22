import 'package:flutter/material.dart';
import 'package:hotel_mobile/data/models/promotion.dart';
import 'package:hotel_mobile/data/services/api_service.dart';
import 'package:hotel_mobile/data/services/notification_service.dart';
import 'package:hotel_mobile/data/services/email_notification_service.dart';

class PromotionFormScreen extends StatefulWidget {
  final Promotion? promotion;

  const PromotionFormScreen({super.key, this.promotion});

  @override
  State<PromotionFormScreen> createState() => _PromotionFormScreenState();
}

class _PromotionFormScreenState extends State<PromotionFormScreen> {
  final ApiService _apiService = ApiService();
  final NotificationService _notificationService = NotificationService();
  final EmailNotificationService _emailService = EmailNotificationService();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _discountController;
  late final TextEditingController _imageController;

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isActive = true;
  bool _isLoading = false;

  bool get _isEditing => widget.promotion != null;

  @override
  void initState() {
    super.initState();
    _apiService.initialize();

    final promotion = widget.promotion;
    _nameController = TextEditingController(text: promotion?.ten ?? '');
    _descriptionController = TextEditingController(text: promotion?.moTa ?? '');
    _discountController = TextEditingController(
      text: promotion?.phanTramGiam.toString() ?? '',
    );
    _imageController = TextEditingController(text: promotion?.hinhAnh ?? '');

    if (promotion != null) {
      _startDate = promotion.ngayBatDau;
      _endDate = promotion.ngayKetThuc;
      _isActive = promotion.trangThai;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _discountController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final initialDate = isStartDate
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? DateTime.now().add(const Duration(days: 7)));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // If end date is before start date, reset it
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _savePromotion() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ngày bắt đầu')),
      );
      return;
    }

    if (_endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ngày kết thúc')),
      );
      return;
    }

    if (_endDate!.isBefore(_startDate!) ||
        _endDate!.isAtSameMomentAs(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ngày kết thúc phải sau ngày bắt đầu')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final promotion = Promotion(
        id: widget.promotion?.id,
        ten: _nameController.text.trim(),
        moTa: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        phanTramGiam: double.parse(_discountController.text),
        ngayBatDau: _startDate!,
        ngayKetThuc: _endDate!,
        trangThai: _isActive,
        hinhAnh: _imageController.text.trim().isEmpty
            ? null
            : _imageController.text.trim(),
        ngayTao: widget.promotion?.ngayTao ?? DateTime.now(),
        ngayCapNhat: DateTime.now(),
      );

      final response = _isEditing
          ? await _apiService.updatePromotion(promotion)
          : await _apiService.createPromotion(promotion);

      if (response.success) {
        // Nếu tạo promotion mới (không phải edit), gửi thông báo đến người dùng
        if (!_isEditing && response.data != null) {
          try {
            final createdPromotion = response.data!;
            
            // Tạo thông báo trong app
            await _notificationService.createNotification(
              title: '🎉 Ưu đãi mới: ${createdPromotion.ten}',
              content: '${createdPromotion.moTa ?? "Ưu đãi đặc biệt"} - Giảm ${createdPromotion.phanTramGiam}%! Hãy khám phá ngay!',
              type: 'promotion',
              imageUrl: createdPromotion.hinhAnh,
              actionUrl: '/deals',
              actionText: 'Xem ưu đãi',
              expiresAt: createdPromotion.ngayKetThuc,
              sendEmail: true, // Gửi email đến tất cả người dùng
            );

            // Gửi email thông báo riêng (backup)
            _emailService.initialize();
            await _emailService.sendNewPromotionNotificationEmail(
              promotionTitle: createdPromotion.ten,
              promotionDescription: createdPromotion.moTa ?? 'Ưu đãi đặc biệt',
              promotionImageUrl: createdPromotion.hinhAnh,
              promotionId: createdPromotion.id,
              discountPercent: createdPromotion.phanTramGiam,
            );
          } catch (e) {
            print('⚠️ Lỗi gửi thông báo ưu đãi mới: $e');
            // Không hiển thị lỗi cho user vì việc tạo promotion đã thành công
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Cập nhật khuyến mãi thành công'
                  : 'Tạo khuyến mãi thành công. Đã gửi thông báo đến người dùng.',
            ),
            duration: Duration(seconds: _isEditing ? 2 : 4),
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Sửa Khuyến mãi' : 'Tạo Khuyến mãi'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            )
          else
            IconButton(icon: const Icon(Icons.save), onPressed: _savePromotion),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Promotion Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên khuyến mãi *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.local_offer),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tên khuyến mãi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Mô tả',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Discount Percentage
            TextFormField(
              controller: _discountController,
              decoration: const InputDecoration(
                labelText: 'Phần trăm giảm giá (%) *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.percent),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập phần trăm giảm giá';
                }
                final discount = double.tryParse(value);
                if (discount == null) {
                  return 'Vui lòng nhập số hợp lệ';
                }
                if (discount <= 0 || discount > 100) {
                  return 'Phần trăm giảm giá phải từ 1 đến 100';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Image URL
            TextFormField(
              controller: _imageController,
              decoration: const InputDecoration(
                labelText: 'URL hình ảnh',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.image),
                hintText: 'https://example.com/image.jpg',
              ),
            ),
            const SizedBox(height: 16),

            // Date Selection
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Ngày bắt đầu'),
                      subtitle: Text(
                        _startDate != null
                            ? _formatDate(_startDate!)
                            : 'Chọn ngày bắt đầu',
                      ),
                      onTap: () => _selectDate(context, true),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Card(
                    child: ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Ngày kết thúc'),
                      subtitle: Text(
                        _endDate != null
                            ? _formatDate(_endDate!)
                            : 'Chọn ngày kết thúc',
                      ),
                      onTap: () => _selectDate(context, false),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Active Status
            Card(
              child: SwitchListTile(
                title: const Text('Trạng thái hoạt động'),
                subtitle: Text(
                  _isActive
                      ? 'Khuyến mãi đang hoạt động'
                      : 'Khuyến mãi không hoạt động',
                ),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _savePromotion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(_isEditing ? 'Cập nhật' : 'Tạo mới'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
