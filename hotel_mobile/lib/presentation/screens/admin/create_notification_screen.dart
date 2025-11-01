import 'package:flutter/material.dart';
import 'package:hotel_mobile/data/services/notification_service.dart';

class CreateNotificationScreen extends StatefulWidget {
  const CreateNotificationScreen({super.key});

  @override
  State<CreateNotificationScreen> createState() => _CreateNotificationScreenState();
}

class _CreateNotificationScreenState extends State<CreateNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _actionUrlController = TextEditingController();
  final _actionTextController = TextEditingController();
  final _hotelIdController = TextEditingController();
  
  final NotificationService _notificationService = NotificationService();
  
  String _selectedType = 'promotion';
  DateTime? _expiresAt;
  bool _isLoading = false;
  bool _sendEmail = true; // Default: send email to all users

  final List<Map<String, String>> _notificationTypes = [
    {'value': 'promotion', 'label': 'Ưu đãi', 'icon': '🎉'},
    {'value': 'new_room', 'label': 'Phòng mới', 'icon': '🏨'},
    {'value': 'app_program', 'label': 'Chương trình app', 'icon': '📱'},
    {'value': 'booking_success', 'label': 'Đặt phòng thành công', 'icon': '✅'},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _imageUrlController.dispose();
    _actionUrlController.dispose();
    _actionTextController.dispose();
    _hotelIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo thông báo'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createNotification,
            child: const Text(
              'Tạo',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Notification Type
                    _buildSectionTitle('Loại thông báo'),
                    _buildTypeSelector(),
                    
                    const SizedBox(height: 24),
                    
                    // Basic Information
                    _buildSectionTitle('Thông tin cơ bản'),
                    _buildTextField(
                      controller: _titleController,
                      label: 'Tiêu đề',
                      hint: 'Nhập tiêu đề thông báo',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập tiêu đề';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildTextField(
                      controller: _contentController,
                      label: 'Nội dung',
                      hint: 'Nhập nội dung thông báo',
                      maxLines: 4,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập nội dung';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Optional Information - Dynamic based on notification type
                    _buildSectionTitle('Thông tin tùy chọn'),
                    const SizedBox(height: 4),
                    Text(
                      _getOptionalFieldsHint(),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    _buildOptionalFields(),
                    
                    const SizedBox(height: 24),
                    
                    // Email Options
                    _buildSectionTitle('Tùy chọn gửi thông báo'),
                    const SizedBox(height: 8),
                    _buildEmailOption(),
                    
                    const SizedBox(height: 32),
                    
                    // Preview
                    _buildSectionTitle('Xem trước'),
                    _buildPreview(),
                    
                    const SizedBox(height: 32),
                    
                    // Create Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _createNotification,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Tạo thông báo',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: _notificationTypes.map((type) {
          final isSelected = _selectedType == type['value'];
          return RadioListTile<String>(
            value: type['value']!,
            groupValue: _selectedType,
            onChanged: (value) {
              setState(() {
                final oldType = _selectedType;
                _selectedType = value!;
                
                // Clear irrelevant fields when changing notification type
                _clearIrrelevantFields(oldType, _selectedType);
              });
            },
            title: Row(
              children: [
                Text(type['icon']!, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(type['label']!),
              ],
            ),
            activeColor: Colors.blue,
            contentPadding: EdgeInsets.zero,
          );
        }).toList(),
      ),
    );
  }

  void _clearIrrelevantFields(String oldType, String newType) {
    // Clear all optional fields first
    _imageUrlController.clear();
    _actionUrlController.clear();
    _actionTextController.clear();
    _hotelIdController.clear();
    _expiresAt = null;
    
    // Note: You can keep some fields if switching between similar types
    // For now, we clear everything for simplicity
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
      ),
    );
  }

  String _getOptionalFieldsHint() {
    switch (_selectedType) {
      case 'promotion':
        return 'Thích hợp cho thông báo khuyến mãi, ưu đãi đặc biệt';
      case 'new_room':
        return 'Thích hợp cho giới thiệu phòng mới tại khách sạn';
      case 'app_program':
        return 'Thích hợp cho cập nhật tính năng mới, sự kiện trong app';
      case 'booking_success':
        return 'Thích hợp cho xác nhận đặt phòng thành công';
      default:
        return 'Tùy chỉnh thông tin thêm cho thông báo';
    }
  }

  Widget _buildOptionalFields() {
    switch (_selectedType) {
      case 'promotion': // 🎉 Ưu đãi
        return Column(
          children: [
            _buildTextField(
              controller: _imageUrlController,
              label: '🖼️ URL hình ảnh khuyến mãi',
              hint: 'https://example.com/promotion.jpg',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _actionUrlController,
              label: '🔗 Link đến trang khuyến mãi',
              hint: '/deals, /promotions/123',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _actionTextController,
              label: '✨ Văn bản nút CTA',
              hint: 'Xem ưu đãi, Đặt ngay, Nhận ngay',
            ),
            const SizedBox(height: 16),
            _buildExpirationDate(),
          ],
        );

      case 'new_room': // 🏨 Phòng mới
        return Column(
          children: [
            _buildTextField(
              controller: _hotelIdController,
              label: '🏨 ID Khách sạn',
              hint: '1, 2, 3...',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập ID khách sạn';
                }
                if (int.tryParse(value) == null) {
                  return 'ID phải là số';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _imageUrlController,
              label: '🖼️ Hình ảnh phòng',
              hint: 'https://example.com/room.jpg',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _actionUrlController,
              label: '🔗 Link đến chi tiết phòng',
              hint: '/hotels/123/rooms/456',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _actionTextController,
              label: '✨ Văn bản nút',
              hint: 'Xem phòng, Đặt ngay',
            ),
          ],
        );

      case 'app_program': // 📱 Chương trình app
        return Column(
          children: [
            _buildTextField(
              controller: _imageUrlController,
              label: '🖼️ Banner chương trình',
              hint: 'https://example.com/program-banner.jpg',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _actionUrlController,
              label: '🔗 Link đến chương trình',
              hint: '/programs, /events/summer2024',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _actionTextController,
              label: '✨ Văn bản nút',
              hint: 'Tham gia ngay, Tìm hiểu thêm',
            ),
            const SizedBox(height: 16),
            _buildExpirationDate(),
          ],
        );

      case 'booking_success': // ✅ Đặt phòng thành công
        return Column(
          children: [
            _buildTextField(
              controller: _hotelIdController,
              label: '🏨 ID Khách sạn (nếu có)',
              hint: '1, 2, 3...',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _actionUrlController,
              label: '🔗 Link đến chi tiết đặt phòng',
              hint: '/booking-history, /bookings/789',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _actionTextController,
              label: '✨ Văn bản nút',
              hint: 'Xem chi tiết, Quản lý đặt phòng',
            ),
          ],
        );

      default:
        return Column(
          children: [
            _buildTextField(
              controller: _imageUrlController,
              label: 'URL hình ảnh',
              hint: 'https://example.com/image.jpg',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _actionUrlController,
              label: 'URL hành động',
              hint: '/deals, /hotels, etc.',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _actionTextController,
              label: 'Văn bản nút hành động',
              hint: 'Xem chi tiết, Đặt ngay, etc.',
            ),
            const SizedBox(height: 16),
            _buildExpirationDate(),
          ],
        );
    }
  }

  Widget _buildEmailOption() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.email, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gửi email thông báo',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _sendEmail 
                      ? 'Tất cả người dùng sẽ nhận email về thông báo này'
                      : 'Chỉ hiển thị trong app, không gửi email',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _sendEmail,
            onChanged: (value) {
              setState(() {
                _sendEmail = value;
              });
            },
            activeColor: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildExpirationDate() {
    return InkWell(
      onTap: _selectExpirationDate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[400]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _expiresAt != null
                    ? 'Hết hạn: ${_formatDate(_expiresAt!)}'
                    : 'Chọn ngày hết hạn (tùy chọn)',
                style: TextStyle(
                  color: _expiresAt != null ? Colors.black87 : Colors.grey[600],
                ),
              ),
            ),
            if (_expiresAt != null)
              IconButton(
                onPressed: () {
                  setState(() {
                    _expiresAt = null;
                  });
                },
                icon: const Icon(Icons.clear, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getNotificationColor(_selectedType).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    _notificationTypes
                        .firstWhere((type) => type['value'] == _selectedType)['icon']!,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _titleController.text.isEmpty ? 'Tiêu đề thông báo' : _titleController.text,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _contentController.text.isEmpty 
                          ? 'Nội dung thông báo sẽ hiển thị ở đây...'
                          : _contentController.text,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getNotificationColor(_selectedType).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _notificationTypes
                      .firstWhere((type) => type['value'] == _selectedType)['label']!,
                  style: TextStyle(
                    fontSize: 12,
                    color: _getNotificationColor(_selectedType),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Vừa xong',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'promotion':
        return Colors.orange;
      case 'new_room':
        return Colors.green;
      case 'app_program':
        return Colors.purple;
      case 'booking_success':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Future<void> _selectExpirationDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() {
        _expiresAt = date;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _createNotification() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _notificationService.createNotification(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        type: _selectedType,
        imageUrl: _imageUrlController.text.trim().isEmpty 
            ? null 
            : _imageUrlController.text.trim(),
        actionUrl: _actionUrlController.text.trim().isEmpty 
            ? null 
            : _actionUrlController.text.trim(),
        actionText: _actionTextController.text.trim().isEmpty 
            ? null 
            : _actionTextController.text.trim(),
        expiresAt: _expiresAt,
        hotelId: _hotelIdController.text.trim().isEmpty 
            ? null 
            : int.tryParse(_hotelIdController.text.trim()),
        sendEmail: _sendEmail, // Pass email option
      );

      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tạo thông báo thành công!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: ${response.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tạo thông báo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
