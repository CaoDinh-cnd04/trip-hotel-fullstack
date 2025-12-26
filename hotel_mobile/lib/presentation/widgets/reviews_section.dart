import 'package:flutter/material.dart';
import 'package:hotel_mobile/data/models/hotel_review.dart';
import 'package:hotel_mobile/data/services/api_service.dart';
import 'package:intl/intl.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../screens/reviews/write_review_screen.dart';

class ReviewsSection extends StatefulWidget {
  final int hotelId;
  final String? hotelName;
  final String? hotelImage;
  final String? bookingId; // Optional: để viết review từ booking
  final VoidCallback? onReviewAdded;

  const ReviewsSection({
    super.key,
    required this.hotelId,
    this.hotelName,
    this.hotelImage,
    this.bookingId,
    this.onReviewAdded,
  });

  @override
  State<ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<ReviewsSection> {
  final ApiService _apiService = ApiService();
  List<HotelReview> _reviews = [];
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  final int _initialDisplayCount = 3;

  @override
  void initState() {
    super.initState();
    // Delay nhỏ để đảm bảo widget đã mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReviews();
    });
  }

  @override
  void didUpdateWidget(ReviewsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload reviews when hotelId changes or when coming back to this screen
    if (oldWidget.hotelId != widget.hotelId) {
      _loadReviews();
    }
  }

  Future<void> _loadReviews() async {
    if (!mounted) return;
    
    // Check if hotelId is valid - nhưng vẫn hiển thị UI
    if (widget.hotelId == 0 || widget.hotelId == null) {
      print('⚠️ ReviewsSection: Invalid hotelId = ${widget.hotelId} - Will show empty state');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = false; // Không show error, chỉ show empty state
          _reviews = []; // Show empty state thay vì error
        });
      }
      return;
    }
    
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = null;
      });
    }

    try {
      print('🔍 ===== LOADING REVIEWS =====');
      print('📋 Hotel ID: ${widget.hotelId}');
      print('📋 API Endpoint: /api/khachsan/${widget.hotelId}/reviews');
      
      final response = await _apiService.getHotelReviews(widget.hotelId);
      
      print('📥 API Response:');
      print('   - success: ${response.success}');
      print('   - message: ${response.message}');
      print('   - data: ${response.data}');
      print('   - data length: ${response.data?.length ?? 0}');
      print('   - data type: ${response.data.runtimeType}');
      
      if (response.data != null && response.data!.isNotEmpty) {
        final firstReview = response.data!.first;
        print('📋 First review sample:');
        print('   - ID: ${firstReview.id}');
        print('   - Customer: ${firstReview.customerName}');
        print('   - Rating: ${firstReview.rating}');
        print('   - Content length: ${firstReview.content.length}');
      }
      
      if (!mounted) {
        print('⚠️ Widget not mounted, skipping update');
        return;
      }
      
      if (response.success && response.data != null) {
        setState(() {
          _reviews = response.data!;
          _isLoading = false;
          _hasError = false;
        });
        print('✅ SUCCESS: Loaded ${_reviews.length} reviews for hotel ${widget.hotelId}');
        print('🔍 Reviews preview:');
        for (var i = 0; i < min(_reviews.length, 3); i++) {
          final review = _reviews[i];
          final preview = review.content.length > 50 
              ? '${review.content.substring(0, 50)}...' 
              : review.content;
          print('   ${i + 1}. ${review.customerName} - ${review.rating} sao - "$preview"');
        }
        if (_reviews.length > 3) {
          print('   ... và ${_reviews.length - 3} đánh giá khác');
        }
      } else {
        print('❌ Reviews API returned error or no data');
        print('   - success: ${response.success}');
        print('   - message: ${response.message}');
        print('   - data: ${response.data}');
        setState(() {
          _hasError = false; // Show empty state thay vì error
          _reviews = [];
          _isLoading = false;
          _errorMessage = response.message ?? 'Không có đánh giá';
        });
      }
      print('🔍 ===== END LOADING REVIEWS =====');
    } catch (e, stackTrace) {
      print('❌ ===== ERROR LOADING REVIEWS =====');
      print('❌ Error: $e');
      print('❌ Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _hasError = true; // Show error để debug
          _reviews = [];
          _isLoading = false;
          _errorMessage = 'Lỗi: $e';
        });
      }
      print('❌ ===== END ERROR =====');
    }
  }
  
  int min(int a, int b) => a < b ? a : b;

  // Public method to refresh reviews (can be called from outside)
  void refreshReviews() {
    _loadReviews();
  }

  // Helper methods for rating display
  Color _getRatingColor(double rating) {
    if (rating >= 9.0) return Colors.green[700]!;
    if (rating >= 8.0) return Colors.green;
    if (rating >= 7.0) return Colors.lime[700]!;
    if (rating >= 6.0) return Colors.orange;
    return Colors.red;
  }

  String _getRatingText(double rating) {
    if (rating >= 9.0) return 'Tuyệt vời';
    if (rating >= 8.0) return 'Rất tốt';
    if (rating >= 7.0) return 'Tốt';
    if (rating >= 6.0) return 'Khá';
    return 'Trung bình';
  }

  @override
  Widget build(BuildContext context) {
    // LUÔN hiển thị section, ngay cả khi hotelId = 0 (sẽ show error state)
    // Chỉ check khi đang load hoặc có data
    
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_hasError) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
        ),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: Colors.grey[400], size: 48),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Lỗi khi tải đánh giá',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _loadReviews,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_reviews.isEmpty) {
      // Empty state với header đẹp
      return Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header với màu sắc đẹp
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.yellow[100]!,
                    Colors.orange[100]!,
                    Colors.pink[100]!,
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.orange[300]!, width: 2),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange[600]!,
                          Colors.pink[600]!,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.rate_review, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Đánh giá từ khách hàng',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Empty state content - dùng EmptyReviewsWidget
            EmptyReviewsWidget(
              isMyReviews: false,
            ),
          ],
        ),
      );
    }

    final displayReviews = _reviews.length > _initialDisplayCount
        ? _reviews.take(_initialDisplayCount).toList()
        : _reviews;
    final hasMore = _reviews.length > _initialDisplayCount;
    final averageRating = _reviews.isEmpty 
        ? 0.0 
        : _reviews.map((r) => r.rating.toDouble()).reduce((a, b) => a + b) / _reviews.length;

    // Tính toán phân bố rating
    final ratingDistribution = Map<int, int>();
    for (var review in _reviews) {
      ratingDistribution[review.rating] = (ratingDistribution[review.rating] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header đơn giản và đầy màu sắc
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.yellow[100]!,
                  Colors.orange[100]!,
                  Colors.pink[100]!,
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.orange[300]!, width: 2),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.orange[600]!,
                        Colors.pink[600]!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.rate_review, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Đánh giá từ khách hàng',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          // Nút viết đánh giá
                          TextButton.icon(
                            onPressed: widget.bookingId == null
                                ? () {
                                    // Hiển thị thông báo cần booking để viết review
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Vui lòng đặt phòng và hoàn thành chuyến đi để viết đánh giá'),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                  }
                                : () {
                                    WriteReviewScreen.showAsModal(
                                      context,
                                      bookingId: widget.bookingId!,
                                      hotelId: widget.hotelId,
                                      hotelName: widget.hotelName ?? 'Khách sạn',
                                      hotelImage: widget.hotelImage,
                                    ).then((shouldRefresh) {
                                      if (shouldRefresh == true) {
                                        refreshReviews();
                                        widget.onReviewAdded?.call();
                                      }
                                    });
                                  },
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text('Viết đánh giá'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.blue[700],
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          // Stars
                          ...List.generate(5, (index) {
                            return Icon(
                              index < averageRating.round()
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.orange[700],
                              size: 18,
                            );
                          }),
                          const SizedBox(width: 8),
                          // Rating number và text
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _getRatingColor(averageRating),
                                    _getRatingColor(averageRating).withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    averageRating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '${_reviews.length} đánh giá',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getRatingText(averageRating),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Rating Distribution - Phân bố đánh giá
          if (_reviews.length > 3) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Phân bố đánh giá',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(5, (index) {
                    final rating = 5 - index;
                    final count = ratingDistribution[rating] ?? 0;
                    final percentage = _reviews.isEmpty ? 0.0 : (count / _reviews.length * 100);
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          // Star và số
                          SizedBox(
                            width: 60,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.star,
                                  color: Colors.amber[700],
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$rating',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Progress bar
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: percentage / 100,
                                minHeight: 8,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.amber[700]!,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Count
                          SizedBox(
                            width: 40,
                            child: Text(
                              '$count',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 24),

          // Reviews List
          ...displayReviews.map((review) => _buildReviewCard(review)),

          // Show more button
          if (hasMore)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Center(
                child: TextButton(
                  onPressed: () {
                    // Navigate to full reviews page or expand
                    showDialog(
                      context: context,
                      builder: (context) => _ReviewsDialog(
                        reviews: _reviews,
                        hotelId: widget.hotelId,
                      ),
                    );
                  },
                  child: Text(
                    'Xem tất cả ${_reviews.length} đánh giá',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(HotelReview review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!, width: 1),
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
          // User info and rating - Đơn giản và đầy màu sắc
          Row(
            children: [
              // Avatar với border đầy màu sắc
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.purple[400]!,
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.purple[100],
                  backgroundImage: review.customerAvatar != null
                      ? NetworkImage(review.customerAvatar!)
                      : null,
                  child: review.customerAvatar == null
                      ? Text(
                          review.customerName.isNotEmpty
                              ? review.customerName[0].toUpperCase()
                              : 'K',
                          style: TextStyle(
                            color: Colors.purple[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            review.customerName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Rating badge nhỏ với màu sắc
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _getRatingColor(review.rating.toDouble()),
                                _getRatingColor(review.rating.toDouble()).withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${review.rating}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        // Stars
                        ...List.generate(5, (index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 2),
                            child: Icon(
                              index < review.rating
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.orange[600],
                              size: 14,
                            ),
                          );
                        }),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            DateFormat('dd/MM/yyyy').format(review.reviewDate),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (review.roomNumber.isNotEmpty && review.roomNumber != 'N/A') ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue[200]!,
                                    Colors.cyan[200]!,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                'P${review.roomNumber}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.blue[900],
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Review content với màu sắc đẹp hơn
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue[50]!,
                  Colors.purple[50]!,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!, width: 1.5),
            ),
            child: Text(
              review.content,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
                height: 1.5,
                letterSpacing: 0.2,
              ),
            ),
          ),
          
          // Hotel response - Đơn giản và đầy màu sắc
          if (review.hotelResponse != null && review.hotelResponse!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.green[50]!,
                    Colors.teal[50]!,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[300]!, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.green[600]!,
                              Colors.teal[600]!,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: const Icon(
                          Icons.hotel,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Phản hồi từ khách sạn',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[800],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (review.responseDate != null)
                        Flexible(
                          child: Text(
                            DateFormat('dd/MM/yyyy').format(review.responseDate!),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    review.hotelResponse!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[800],
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReviewsDialog extends StatelessWidget {
  final List<HotelReview> reviews;
  final int hotelId;

  const _ReviewsDialog({
    required this.reviews,
    required this.hotelId,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tất cả đánh giá',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            
            // Reviews list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: reviews.length,
                itemBuilder: (context, index) {
                  final review = reviews[index];
                  return _buildReviewCard(review);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(HotelReview review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.blue[100],
                backgroundImage: review.customerAvatar != null
                    ? NetworkImage(review.customerAvatar!)
                    : null,
                child: review.customerAvatar == null
                    ? Text(
                        review.customerName.isNotEmpty
                            ? review.customerName[0].toUpperCase()
                            : 'K',
                        style: TextStyle(color: Colors.blue[700]),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.customerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < review.rating
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 14,
                          );
                        }),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('dd/MM/yyyy').format(review.reviewDate),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review.content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
              height: 1.5,
            ),
          ),
          if (review.hotelResponse != null && review.hotelResponse!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.hotel, size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Phản hồi từ khách sạn',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    review.hotelResponse!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[800],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

