import 'package:flutter/material.dart';
import 'package:hotel_mobile/data/services/review_service.dart';
import 'package:hotel_mobile/data/services/service_review_service.dart';
import 'package:hotel_mobile/core/services/backend_auth_service.dart';

/// Màn hình tạo đánh giá với 2 loại:
/// 1. Đánh giá tổng quan khách sạn (lưu vào bảng danh_gia)
/// 2. Đánh giá dịch vụ (lưu vào bảng dich_vu_reviews)
class CreateReviewScreen extends StatefulWidget {
  final String? bookingId;
  final int hotelId;
  final String hotelName;

  const CreateReviewScreen({
    super.key,
    this.bookingId,
    required this.hotelId,
    required this.hotelName,
  });

  @override
  State<CreateReviewScreen> createState() => _CreateReviewScreenState();
}

class _CreateReviewScreenState extends State<CreateReviewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ReviewService _reviewService = ReviewService();
  final ServiceReviewService _serviceReviewService = ServiceReviewService();

  // Đánh giá khách sạn
  int _hotelRating = 0;
  final TextEditingController _hotelCommentController = TextEditingController();

  // Đánh giá dịch vụ
  String? _selectedService;
  int _serviceRating = 0;
  final TextEditingController _serviceCommentController = TextEditingController();

  bool _isSubmitting = false;

  // Danh sách dịch vụ có thể đánh giá
  final List<String> _services = [
    'Spa',
    'Hồ bơi',
    'Nhà hàng',
    'WiFi miễn phí',
    'Bãi đỗ xe',
    'Gần trung tâm',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _hotelCommentController.dispose();
    _serviceCommentController.dispose();
    super.dispose();
  }

  Future<void> _submitHotelReview() async {
    if (_hotelRating == 0) {
      _showError('Vui lòng chọn điểm đánh giá');
      return;
    }

    if (_hotelCommentController.text.trim().isEmpty) {
      _showError('Vui lòng nhập nội dung đánh giá');
      return;
    }

    if (widget.bookingId == null || widget.bookingId!.isEmpty) {
      _showError('Không tìm thấy thông tin đặt phòng');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await _reviewService.createReview(
        bookingId: widget.bookingId!,
        rating: _hotelRating,
        content: _hotelCommentController.text.trim(),
      );

      if (mounted) {
        setState(() => _isSubmitting = false);
        
        if (result.success) {
          _showSuccess('Đánh giá khách sạn đã được gửi thành công!');
          Navigator.pop(context, true); // Trả về true để refresh
        } else {
          _showError(result.message ?? 'Có lỗi xảy ra khi gửi đánh giá');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showError('Lỗi: $e');
      }
    }
  }

  Future<void> _submitServiceReview() async {
    if (_selectedService == null) {
      _showError('Vui lòng chọn dịch vụ cần đánh giá');
      return;
    }

    if (_serviceRating == 0) {
      _showError('Vui lòng chọn điểm đánh giá');
      return;
    }

    if (_serviceCommentController.text.trim().isEmpty) {
      _showError('Vui lòng nhập nội dung đánh giá');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await _serviceReviewService.createServiceReview(
        serviceName: _selectedService!,
        hotelId: widget.hotelId,
        rating: _serviceRating.toDouble(),
        comment: _serviceCommentController.text.trim(),
      );

      if (mounted) {
        setState(() => _isSubmitting = false);
        
        if (result.success) {
          _showSuccess('Đánh giá dịch vụ đã được gửi thành công!');
          // Reset form
          _selectedService = null;
          _serviceRating = 0;
          _serviceCommentController.clear();
          setState(() {});
        } else {
          _showError(result.message ?? 'Có lỗi xảy ra khi gửi đánh giá');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showError('Lỗi: $e');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Viết đánh giá'),
        backgroundColor: const Color(0xFF8B4513),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Đánh giá khách sạn'),
            Tab(text: 'Đánh giá dịch vụ'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHotelReviewTab(),
          _buildServiceReviewTab(),
        ],
      ),
    );
  }

  Widget _buildHotelReviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thông tin khách sạn
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.hotel, color: Colors.brown[700], size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.hotelName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.bookingId != null)
                        Text(
                          'Mã đặt phòng: ${widget.bookingId}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Điểm đánh giá
          const Text(
            'Đánh giá tổng quan *',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildRatingSelector(
            rating: _hotelRating,
            onRatingChanged: (rating) {
              setState(() => _hotelRating = rating);
            },
          ),
          const SizedBox(height: 32),

          // Nội dung đánh giá
          const Text(
            'Nội dung đánh giá *',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _hotelCommentController,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: 'Chia sẻ trải nghiệm của bạn về khách sạn...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 32),

          // Nút gửi
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitHotelReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B4513),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Gửi đánh giá',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceReviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thông tin khách sạn
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.hotel, color: Colors.brown[700], size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.hotelName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Chọn dịch vụ
          const Text(
            'Chọn dịch vụ cần đánh giá *',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedService,
            decoration: InputDecoration(
              hintText: 'Chọn dịch vụ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            items: _services.map((service) {
              return DropdownMenuItem(
                value: service,
                child: Text(service),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedService = value);
            },
          ),
          const SizedBox(height: 24),

          // Điểm đánh giá
          const Text(
            'Đánh giá dịch vụ *',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildRatingSelector(
            rating: _serviceRating,
            onRatingChanged: (rating) {
              setState(() => _serviceRating = rating);
            },
          ),
          const SizedBox(height: 32),

          // Nội dung đánh giá
          const Text(
            'Nội dung đánh giá *',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _serviceCommentController,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: 'Chia sẻ trải nghiệm của bạn về dịch vụ này...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 32),

          // Nút gửi
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitServiceReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B4513),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Gửi đánh giá',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSelector({
    required int rating,
    required ValueChanged<int> onRatingChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        return GestureDetector(
          onTap: () => onRatingChanged(starIndex),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              starIndex <= rating ? Icons.star : Icons.star_border,
              size: 48,
              color: starIndex <= rating
                  ? Colors.amber
                  : Colors.grey[400],
            ),
          ),
        );
      }),
    );
  }
}

