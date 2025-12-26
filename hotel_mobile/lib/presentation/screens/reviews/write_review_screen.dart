import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/vip_theme_extensions.dart';
import '../../../data/services/review_service.dart';
import '../../../data/services/image_upload_service.dart';
import '../../../data/services/backend_auth_service.dart';
import '../../../data/services/hotel_amenity_service.dart';
import '../../../core/utils/image_url_helper.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/services/hotel_amenity_service.dart';
import '../../../l10n/app_localizations.dart';

/// Màn hình viết đánh giá khách sạn với TabBar tách thành 2 phần:
/// - Tab 1: Đánh giá khách sạn (overall rating, comment, images)
/// - Tab 2: Đánh giá dịch vụ (service ratings)
class WriteReviewScreen extends StatefulWidget {
  final String? bookingId;
  final int hotelId;
  final String hotelName;
  final String? hotelImage;

  const WriteReviewScreen({
    super.key,
    this.bookingId,
    required this.hotelId,
    required this.hotelName,
    this.hotelImage,
  });

  /// Hiển thị màn hình viết đánh giá dưới dạng modal bottom sheet
  static Future<bool?> showAsModal(
    BuildContext context, {
    String? bookingId,
    required int hotelId,
    required String hotelName,
    String? hotelImage,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WriteReviewScreen(
        bookingId: bookingId,
        hotelId: hotelId,
        hotelName: hotelName,
        hotelImage: hotelImage,
      ),
    );
  }

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> with SingleTickerProviderStateMixin {
  final ReviewService _reviewService = ReviewService();
  final ImageUploadService _imageUploadService = ImageUploadService();
  final BackendAuthService _authService = BackendAuthService();
  final HotelAmenityService _amenityService = HotelAmenityService();
  final ImagePicker _imagePicker = ImagePicker();

  late TabController _tabController;

  // Rating tổng thể (bắt buộc)
  int _overallRating = 0;

  // Danh sách tiện nghi của khách sạn
  List<HotelAmenity> _amenities = [];
  bool _isLoadingAmenities = false;

  // Rating các dịch vụ (tùy chọn) - Key là amenity_id, Value là rating (1-5)
  final Map<int, int> _serviceRatings = {};

  // Nhận xét cho từng tiện nghi - Key là amenity_id, Value là nội dung nhận xét
  final Map<int, TextEditingController> _serviceComments = {};

  // Ảnh cho từng tiện nghi - Key là amenity_id, Value là danh sách File
  final Map<int, List<File>> _serviceImages = {};

  // URL ảnh đã upload cho từng tiện nghi - Key là amenity_id, Value là danh sách URL
  final Map<int, List<String>> _serviceImageUrls = {};

  // Trạng thái upload ảnh cho từng tiện nghi
  final Map<int, bool> _isUploadingServiceImages = {};

  // Nội dung đánh giá
  final TextEditingController _contentController = TextEditingController();

  // Ảnh đã upload
  List<String> _uploadedImageUrls = [];
  List<File> _selectedImages = [];
  bool _isUploadingImages = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAmenities();
  }

  /// Load danh sách tiện nghi của khách sạn
  Future<void> _loadAmenities() async {
    setState(() {
      _isLoadingAmenities = true;
    });

    try {
      final result = await _amenityService.getHotelAmenities(widget.hotelId);
      if (result.success && result.data != null) {
        setState(() {
          _amenities = result.data!;
          // Khởi tạo rating = 0, comment controller, và danh sách ảnh cho tất cả tiện nghi
          for (var amenity in _amenities) {
            _serviceRatings[amenity.id] = 0;
            _serviceComments[amenity.id] = TextEditingController();
            _serviceImages[amenity.id] = [];
            _serviceImageUrls[amenity.id] = [];
            _isUploadingServiceImages[amenity.id] = false;
          }
        });
      } else {
        print('⚠️ Không thể tải danh sách tiện nghi: ${result.message}');
      }
    } catch (e) {
      print('❌ Lỗi khi tải danh sách tiện nghi: $e');
    } finally {
      setState(() {
        _isLoadingAmenities = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _contentController.dispose();
    // Dispose tất cả comment controllers
    for (var controller in _serviceComments.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Chọn ảnh từ gallery
  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images.map((xFile) => File(xFile.path)));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi chọn ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Upload tất cả ảnh đã chọn
  Future<void> _uploadAllImages() async {
    if (_selectedImages.isEmpty) return;

    setState(() {
      _isUploadingImages = true;
    });

    try {
      final userId = _authService.currentUser?.id;
      
      for (var imageFile in _selectedImages) {
        try {
          final response = await _imageUploadService.uploadImage(
            imageFile: imageFile,
            category: 'reviews',
            entityType: 'review',
            entityId: widget.bookingId ?? widget.hotelId.toString(),
            uploadedBy: userId?.toString(),
            maxWidth: 1920,
            maxHeight: 1920,
            quality: 85,
          );

          if (response.success && response.image != null) {
            _uploadedImageUrls.add(response.image!.url);
          }
        } catch (e) {
          print('❌ Error uploading image: $e');
        }
      }

      setState(() {
        _isUploadingImages = false;
      });
    } catch (e) {
      setState(() {
        _isUploadingImages = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi upload ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Xóa ảnh đã chọn
  void _removeSelectedImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  /// Chọn ảnh cho tiện nghi cụ thể
  Future<void> _pickServiceImages(int amenityId) async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (images.isNotEmpty) {
        setState(() {
          _serviceImages[amenityId] ??= [];
          _serviceImages[amenityId]!.addAll(images.map((xFile) => File(xFile.path)));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi chọn ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Upload ảnh cho tiện nghi cụ thể
  Future<void> _uploadServiceImages(int amenityId) async {
    final images = _serviceImages[amenityId];
    if (images == null || images.isEmpty) return;

    setState(() {
      _isUploadingServiceImages[amenityId] = true;
    });

    try {
      final userId = _authService.currentUser?.id;
      final uploadedUrls = <String>[];
      
      for (var imageFile in images) {
        try {
          final response = await _imageUploadService.uploadImage(
            imageFile: imageFile,
            category: 'reviews',
            entityType: 'service_review',
            entityId: amenityId.toString(),
            uploadedBy: userId?.toString(),
            maxWidth: 1920,
            maxHeight: 1920,
            quality: 85,
          );

          if (response.success && response.image != null) {
            uploadedUrls.add(response.image!.url);
          }
        } catch (e) {
          print('❌ Error uploading service image: $e');
        }
      }

      setState(() {
        _serviceImageUrls[amenityId] = uploadedUrls;
        _isUploadingServiceImages[amenityId] = false;
      });
    } catch (e) {
      setState(() {
        _isUploadingServiceImages[amenityId] = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi upload ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Xóa ảnh của tiện nghi
  void _removeServiceImage(int amenityId, int index) {
    setState(() {
      _serviceImages[amenityId]?.removeAt(index);
    });
  }

  /// Validate form
  bool _validateForm() {
    if (_overallRating == 0) {
      _showError('Vui lòng chọn điểm đánh giá tổng thể');
      return false;
    }

    if (_contentController.text.trim().isEmpty) {
      _showError('Vui lòng nhập nội dung đánh giá');
      return false;
    }

    if (_contentController.text.trim().length < 10) {
      _showError('Nội dung đánh giá phải có ít nhất 10 ký tự');
      return false;
    }

    if (widget.bookingId == null || widget.bookingId!.isEmpty) {
      _showError('Thông tin đặt phòng không hợp lệ');
      return false;
    }

    return true;
  }

  /// Submit review
  Future<void> _submitReview() async {
    if (!_validateForm()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Upload ảnh tổng thể trước (nếu có)
      if (_selectedImages.isNotEmpty) {
        await _uploadAllImages();
      }

      // Upload ảnh cho từng tiện nghi (nếu có)
      for (var amenityId in _serviceImages.keys) {
        final images = _serviceImages[amenityId];
        if (images != null && images.isNotEmpty) {
          await _uploadServiceImages(amenityId);
        }
      }

      // Chuẩn bị service ratings với nhận xét và ảnh
      // Format: { "amenity_id": { "rating": 5, "comment": "...", "images": [...] } }
      final Map<String, dynamic> activeServiceRatings = {};
      _serviceRatings.forEach((amenityId, rating) {
        if (rating > 0) {
          final comment = _serviceComments[amenityId]?.text.trim() ?? '';
          final images = _serviceImageUrls[amenityId] ?? [];
          
          activeServiceRatings[amenityId.toString()] = {
            'rating': rating,
            'comment': comment.isNotEmpty ? comment : null,
            'images': images.isNotEmpty ? images : null,
          };
        }
      });

      // Gửi review
      final result = await _reviewService.createReview(
        bookingId: widget.bookingId!,
        rating: _overallRating,
        content: _contentController.text.trim(),
        serviceRatings: activeServiceRatings.isNotEmpty ? activeServiceRatings : null,
        imageUrls: _uploadedImageUrls.isNotEmpty ? _uploadedImageUrls : null,
      );

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        if (result.success) {
          _showSuccess('Đánh giá đã được gửi thành công!');
          Navigator.pop(context, true);
        } else {
          _showError(result.message ?? 'Có lỗi xảy ra khi gửi đánh giá');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
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
    final vipTheme = context.vipTheme;
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(
        maxHeight: mediaQuery.size.height * 0.95,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          // Drag handle
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Icon khách sạn
                if (widget.hotelImage != null && widget.hotelImage!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      ImageUrlHelper.getHotelImageUrl(widget.hotelImage),
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.hotel, color: Colors.grey[600], size: 20),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.hotel, color: Colors.grey[600], size: 20),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Viết nhận xét',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[900],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.hotelName,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.grey[600]),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // TabBar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: vipTheme.primaryColor,
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: vipTheme.primaryColor,
              indicatorWeight: 3,
              tabs: const [
                Tab(
                  icon: Icon(Icons.hotel, size: 20),
                  text: 'Đánh giá khách sạn',
                ),
                Tab(
                  icon: Icon(Icons.star_rate, size: 20),
                  text: 'Đánh giá dịch vụ',
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // TabBarView
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Đánh giá khách sạn
                _buildHotelReviewTab(vipTheme),
                // Tab 2: Đánh giá dịch vụ
                _buildServiceReviewTab(vipTheme),
              ],
            ),
          ),

          // Nút gửi nhận xét (cố định ở dưới)
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: 12 + bottomPadding,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_overallRating > 0 &&
                        _contentController.text.trim().length >= 10 &&
                        !_isSubmitting &&
                        widget.bookingId != null &&
                        widget.bookingId!.isNotEmpty)
                    ? _submitReview
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: vipTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: Colors.grey[300],
                  elevation: 0,
                ),
                icon: _isSubmitting
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(Icons.send, size: 20),
                label: Text(
                  _isSubmitting ? 'Đang gửi...' : 'Gửi nhận xét',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Tab 1: Đánh giá khách sạn (overall rating, comment, images)
  Widget _buildHotelReviewTab(vipTheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Phần đánh giá tổng thể (nền vàng nhạt)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đánh giá của bạn',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),
                // 5 sao
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starIndex = index + 1;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _overallRating = starIndex;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          starIndex <= _overallRating
                              ? Icons.star
                              : Icons.star_border,
                          size: 40,
                          color: starIndex <= _overallRating
                              ? Colors.amber[700]
                              : Colors.grey[400],
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                // Nút "Tuyệt vời!" (chỉ hiện khi có rating)
                if (_overallRating > 0)
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                      ),
                      icon: Icon(Icons.sentiment_very_satisfied, size: 20),
                      label: Text(
                        _getRatingText(_overallRating),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Phần chia sẻ trải nghiệm
          Row(
            children: [
              Icon(Icons.edit_note, color: Colors.grey[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Chia sẻ trải nghiệm của bạn',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contentController,
            maxLines: 6,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'Hãy chia sẻ trải nghiệm của bạn về khách sạn này...\n\nVí dụ:\n- Dịch vụ như thế nào?\n- Phòng có sạch sẽ không?',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: vipTheme.primaryColor, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.all(16),
              counterText: '', // Ẩn counter mặc định
            ),
            style: TextStyle(fontSize: 14, color: Colors.grey[800]),
          ),
          // Character counter (chỉ 1 lần)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _contentController,
                builder: (context, value, child) {
                  return Text(
                    '${value.text.length}/500',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Phần upload ảnh (nền tím)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.purple[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.photo_library, color: Colors.purple[700], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Hình ảnh (Tùy chọn)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.purple[900],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Nút upload ảnh
                ElevatedButton.icon(
                  onPressed: _isUploadingImages ? null : _pickImages,
                  icon: Icon(
                    _isUploadingImages ? Icons.upload : Icons.add_photo_alternate,
                    size: 20,
                  ),
                  label: Text(
                    _isUploadingImages
                        ? 'Đang upload ảnh...'
                        : 'Chọn ảnh từ thư viện',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
                // Hiển thị ảnh đã chọn
                if (_selectedImages.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Ảnh đã chọn (${_selectedImages.length}):',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.purple[900],
                    ),
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1,
                    ),
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) {
                      return _buildImagePreview(_selectedImages[index], index);
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Tab 2: Đánh giá dịch vụ (service ratings)
  Widget _buildServiceReviewTab(vipTheme) {
    if (_isLoadingAmenities) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_amenities.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Khách sạn này chưa có tiện nghi nào',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Đánh giá các tiện nghi của khách sạn để giúp người khác hiểu rõ hơn về trải nghiệm của bạn.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue[900],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Danh sách đánh giá tiện nghi (động từ API)
          ..._amenities.map((amenity) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildServiceRatingItem(
                amenity: amenity,
                label: amenity.ten,
                icon: amenity.icon,
                rating: _serviceRatings[amenity.id] ?? 0,
                commentController: _serviceComments[amenity.id]!,
                images: _serviceImages[amenity.id] ?? [],
                isUploading: _isUploadingServiceImages[amenity.id] ?? false,
                onRatingChanged: (rating) {
                  setState(() {
                    _serviceRatings[amenity.id] = rating;
                  });
                },
                onPickImages: () => _pickServiceImages(amenity.id),
                onRemoveImage: (index) => _removeServiceImage(amenity.id, index),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildServiceRatingItem({
    required HotelAmenity amenity,
    required String label,
    String? icon,
    required int rating,
    required TextEditingController commentController,
    required List<File> images,
    required bool isUploading,
    required ValueChanged<int> onRatingChanged,
    required VoidCallback onPickImages,
    required ValueChanged<int> onRemoveImage,
  }) {
    final vipTheme = context.vipTheme;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header với icon và tên
          Row(
            children: [
              if (icon != null && icon.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Image.network(
                    icon.startsWith('http') ? icon : '${AppConstants.baseUrl}/images/amenities/$icon',
                    width: 24,
                    height: 24,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.star_rate,
                      size: 24,
                      color: Colors.blue[700],
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    Icons.star_rate,
                    size: 24,
                    color: Colors.blue[700],
                  ),
                ),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[900],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Rating stars
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: List.generate(5, (index) {
                    final starIndex = index + 1;
                    return GestureDetector(
                      onTap: () => onRatingChanged(starIndex),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(
                          starIndex <= rating ? Icons.star : Icons.star_border,
                          size: 32,
                          color: starIndex <= rating
                              ? Colors.amber[700]
                              : Colors.grey[300],
                        ),
                      ),
                    );
                  }),
                ),
              ),
              if (rating > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$rating/5',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue[900],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          
          // Nhận xét (chỉ hiện khi có rating)
          if (rating > 0) ...[
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              maxLines: 3,
              maxLength: 300,
              decoration: InputDecoration(
                hintText: 'Nhận xét về $label (tùy chọn)',
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
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
                  borderSide: BorderSide(color: vipTheme.primaryColor, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(12),
                counterText: '',
              ),
              style: TextStyle(fontSize: 14, color: Colors.grey[800]),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: commentController,
                  builder: (context, value, child) {
                    return Text(
                      '${value.text.length}/300',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
          
          // Upload ảnh (chỉ hiện khi có rating)
          if (rating > 0) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: isUploading ? null : onPickImages,
              icon: Icon(
                isUploading ? Icons.upload : Icons.add_photo_alternate,
                size: 18,
              ),
              label: Text(
                isUploading ? 'Đang upload...' : 'Thêm ảnh (tùy chọn)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 1,
              ),
            ),
            
            // Hiển thị ảnh đã chọn
            if (images.isNotEmpty) ...[
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return _buildServiceImagePreview(images[index], index, onRemoveImage);
                },
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildServiceImagePreview(File image, int index, ValueChanged<int> onRemove) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            image,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => onRemove(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview(File image, int index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            image,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeSelectedImage(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 5:
        return 'Tuyệt vời!';
      case 4:
        return 'Rất tốt!';
      case 3:
        return 'Tốt!';
      case 2:
        return 'Khá!';
      case 1:
        return 'Trung bình';
      default:
        return '';
    }
  }

}
