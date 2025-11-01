import 'package:flutter/material.dart';
import '../../../core/widgets/skeleton_loading_widget.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/services/review_service.dart';
import '../../../data/models/review.dart';
import '../../../core/constants/app_constants.dart';

class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> with TickerProviderStateMixin {
  final ReviewService _reviewService = ReviewService();
  List<Review> _reviews = [];
  bool _isLoading = true;
  String? _error;
  
  late TabController _tabController;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final result = await _reviewService.getMyReviews();
      if (result.success) {
        setState(() {
          _reviews = result.data ?? [];
        });
      } else {
        setState(() {
          _error = result.message ?? 'Không thể tải nhận xét';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Lỗi tải nhận xét: $e';
      });
    } finally {
      setState(() {
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
          'Nhận xét của tôi',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF8B4513),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: const Color(0xFF8B4513),
            child: TabBar(
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
                Tab(text: 'Chưa đánh giá'),
                Tab(text: 'Đã đánh giá'),
                Tab(text: 'Tất cả'),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? SkeletonLoadingWidget(
              itemType: LoadingItemType.reviewCard,
              itemCount: 5,
            )
          : _reviews.isEmpty
              ? EmptyReviewsWidget(
                  isMyReviews: true,
                  onExplore: () {
                    Navigator.pushNamed(context, '/booking-history');
                  },
                )
              : _error != null
                  ? _buildErrorWidget()
                  : _buildTabContent(),
    );
  }

  Widget _buildErrorWidget() {
    return ErrorStateWidget(
      title: 'Có lỗi xảy ra',
      message: _error,
      onRetry: _loadReviews,
    );
  }

  Widget _buildTabContent() {
    final filteredReviews = _getFilteredReviews();
    
    if (filteredReviews.isEmpty) {
      return EmptyReviewsWidget(
        isMyReviews: true,
        onExplore: () {
          Navigator.pushNamed(context, '/booking-history');
        },
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadReviews,
      color: const Color(0xFF8B4513),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredReviews.length,
        itemBuilder: (context, index) {
          final review = filteredReviews[index];
          return _buildReviewCard(review);
        },
      ),
    );
  }

  List<Review> _getFilteredReviews() {
    switch (_selectedTabIndex) {
      case 0: // Chưa đánh giá
        return _reviews.where((review) => !review.isReviewed).toList();
      case 1: // Đã đánh giá
        return _reviews.where((review) => review.isReviewed).toList();
      case 2: // Tất cả
        return _reviews;
      default:
        return _reviews;
    }
  }

  Widget _buildEmptyWidget() {
    String emptyText;
    String emptySubtext;
    IconData emptyIcon;
    
    switch (_selectedTabIndex) {
      case 0:
        emptyText = 'Không có đặt phòng nào cần đánh giá';
        emptySubtext = 'Các đặt phòng hoàn thành sẽ xuất hiện ở đây để bạn đánh giá';
        emptyIcon = Icons.rate_review_outlined;
        break;
      case 1:
        emptyText = 'Chưa có nhận xét nào';
        emptySubtext = 'Nhận xét bạn đã viết sẽ xuất hiện ở đây';
        emptyIcon = Icons.star_outline;
        break;
      case 2:
        emptyText = 'Chưa có đặt phòng nào';
        emptySubtext = 'Lịch sử đặt phòng của bạn sẽ xuất hiện ở đây';
        emptyIcon = Icons.hotel_outlined;
        break;
      default:
        emptyText = 'Không có dữ liệu';
        emptySubtext = 'Dữ liệu sẽ xuất hiện ở đây';
        emptyIcon = Icons.inbox_outlined;
    }
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                emptyIcon,
                size: 64,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              emptyText,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              emptySubtext,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(Review review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openReviewDetail(review),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hotel Info with Image
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hotel Image - Improved
                    Hero(
                      tag: 'hotel-${review.id}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.grey[200]!,
                                Colors.grey[300]!,
                              ],
                            ),
                          ),
                          child: review.hotelImage != null
                              ? CachedNetworkImage(
                                  imageUrl: '${AppConstants.baseUrl}/images/hotels/${review.hotelImage}',
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: Colors.grey[300],
                                    child: Icon(Icons.hotel, size: 36, color: Colors.grey[600]),
                                  ),
                                )
                              : Container(
                                  color: Colors.grey[300],
                                  child: Icon(Icons.hotel, size: 36, color: Colors.grey[600]),
                                ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Hotel Details - Improved
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  review.hotelName,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Status Badge - Improved
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: review.isReviewed 
                                      ? Colors.green[50] 
                                      : Colors.orange[50],
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: review.isReviewed 
                                        ? Colors.green[300]! 
                                        : Colors.orange[300]!,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      review.isReviewed 
                                          ? Icons.check_circle 
                                          : Icons.pending_outlined,
                                      size: 14,
                                      color: review.isReviewed 
                                          ? Colors.green[700] 
                                          : Colors.orange[700],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      review.isReviewed ? 'Đã đánh giá' : 'Chưa đánh giá',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: review.isReviewed 
                                            ? Colors.green[700] 
                                            : Colors.orange[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Location
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  review.location,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 6),
                          
                          // Room Type
                          Row(
                            children: [
                              Icon(Icons.bed, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                review.roomType,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          
                          // Rating Display (if reviewed)
                          if (review.isReviewed && review.rating != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                ...List.generate(5, (index) {
                                  return Icon(
                                    index < review.rating! 
                                        ? Icons.star 
                                        : Icons.star_border,
                                    size: 14,
                                    color: Colors.amber,
                                  );
                                }),
                                const SizedBox(width: 6),
                                Text(
                                  '${review.rating}/5',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Booking Dates - Improved Design
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue[50]!,
                        Colors.blue[100]!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!, width: 1),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.login, size: 14, color: Colors.blue[700]),
                                const SizedBox(width: 4),
                                Text(
                                  'Nhận phòng',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(review.checkInDate),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[900],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.arrow_forward, size: 20, color: Colors.blue[700]),
                      ),
                      
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Icon(Icons.logout, size: 14, color: Colors.blue[700]),
                                const SizedBox(width: 4),
                                Text(
                                  'Trả phòng',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(review.checkOutDate),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[900],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue[700],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${review.nights}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Đêm',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blue[100],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Review Content Preview (if reviewed)
                if (review.isReviewed && review.content != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber[200]!, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.rate_review, size: 16, color: Colors.amber[700]),
                            const SizedBox(width: 6),
                            Text(
                              'Nhận xét của bạn',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.amber[900],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          review.content!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                            height: 1.5,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
                
                // Action Buttons - Improved
                const SizedBox(height: 16),
                if (!review.isReviewed)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _writeReview(review),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B4513),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.edit_note, size: 20),
                      label: const Text(
                        'Viết nhận xét',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _editReview(review),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF8B4513),
                            side: const BorderSide(color: Color(0xFF8B4513), width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Chỉnh sửa'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _deleteReview(review),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Xóa'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openReviewDetail(Review review) {
    // TODO: Navigate to review detail screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Mở chi tiết nhận xét cho ${review.hotelName}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _writeReview(Review review) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _WriteReviewDialog(
        review: review,
        onSubmit: (rating, content) async {
          await _submitReview(review, rating, content);
        },
      ),
    );
  }
  
  Future<void> _submitReview(Review review, int rating, String content) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final result = await _reviewService.createReview(
        bookingId: review.bookingId.isNotEmpty ? review.bookingId : review.id,
        rating: rating,
        content: content,
      );

      if (mounted) Navigator.pop(context); // Close loading dialog

      if (result.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('✅ Đã gửi nhận xét thành công!'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
          
          // Wait a bit for backend to commit transaction, then reload
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            await _loadReviews(); // Reload reviews
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('❌ ${result.message ?? "Không thể gửi nhận xét"}'),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _editReview(Review review) {
    // TODO: Navigate to edit review screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Chỉnh sửa nhận xét cho ${review.hotelName}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _deleteReview(Review review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Xóa nhận xét',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text('Bạn có chắc chắn muốn xóa nhận xét cho ${review.hotelName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final result = await _reviewService.deleteReview(review.id);
        if (result.success) {
          setState(() {
            _reviews.removeWhere((r) => r.id == review.id);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã xóa nhận xét'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message ?? 'Không thể xóa nhận xét'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xóa nhận xét: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day} thg ${date.month} ${date.year}';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

// ✅ Improved Write Review Dialog
class _WriteReviewDialog extends StatefulWidget {
  final Review review;
  final Function(int rating, String content) onSubmit;

  const _WriteReviewDialog({
    required this.review,
    required this.onSubmit,
  });

  @override
  State<_WriteReviewDialog> createState() => _WriteReviewDialogState();
}

class _WriteReviewDialogState extends State<_WriteReviewDialog> with SingleTickerProviderStateMixin {
  int _rating = 5;
  final TextEditingController _contentController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _contentController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: FadeTransition(
          opacity: _scaleAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                
                // Header with Hotel Info - Fixed overflow
                Row(
                  children: [
                    // Hotel Image
                    Hero(
                      tag: 'hotel-${widget.review.id}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                          ),
                          child: widget.review.hotelImage != null
                              ? CachedNetworkImage(
                                  imageUrl: '${AppConstants.baseUrl}/images/hotels/${widget.review.hotelImage}',
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) => Icon(
                                    Icons.hotel,
                                    size: 28,
                                    color: Colors.grey[600],
                                  ),
                                )
                              : Icon(Icons.hotel, size: 28, color: Colors.grey[600]),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Viết nhận xét',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.review.hotelName,
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
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      color: Colors.grey[600],
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Rating Section - Enhanced with overflow protection
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.amber[50]!,
                        Colors.orange[50]!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber[200]!, width: 1),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Đánh giá của bạn',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Star Rating - Fixed overflow, responsive
                      LayoutBuilder(
                        builder: (context, constraints) {
                          // Calculate star size based on available width (consider padding)
                          final availableWidth = constraints.maxWidth - 40; // Subtract container padding
                          final starSize = (availableWidth / 6.5).clamp(36.0, 48.0);
                          final starPadding = (availableWidth / 70).clamp(1.0, 4.0);
                          
                          return SizedBox(
                            width: double.infinity,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(5, (index) {
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _rating = index + 1;
                                    });
                                  },
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: starPadding),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      curve: Curves.easeOut,
                                      transform: Matrix4.identity()..scale(index < _rating ? 1.1 : 1.0),
                                      child: Icon(
                                        Icons.star_rounded,
                                        size: starSize,
                                        color: index < _rating 
                                            ? Colors.amber[600] 
                                            : Colors.grey[300],
                                        shadows: index < _rating
                                            ? [
                                                BoxShadow(
                                                  color: Colors.amber.withOpacity(0.3),
                                                  blurRadius: 8,
                                                  spreadRadius: 2,
                                                ),
                                              ]
                                            : null,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      // Rating Text with Color - Fixed to prevent overflow
                      Center(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: double.infinity),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getRatingIcon(_rating),
                                size: 20,
                                color: _getRatingColor(_rating),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  _getRatingText(_rating),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _getRatingColor(_rating),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Content Section - Enhanced
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.edit_note, size: 20, color: Colors.grey[700]),
                        const SizedBox(width: 8),
                        const Text(
                          'Chia sẻ trải nghiệm của bạn',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
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
                        hintText: 'Hãy chia sẻ trải nghiệm của bạn về khách sạn này...\n\nVí dụ:\n- Dịch vụ như thế nào?\n- Phòng có sạch sẽ không?\n- Vị trí có thuận tiện không?',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                          height: 1.5,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF8B4513), width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                    const SizedBox(height: 8),
                    _CharacterCounter(controller: _contentController),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Submit Button - Enhanced
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_contentController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.white),
                                SizedBox(width: 12),
                                Text('Vui lòng nhập nội dung nhận xét'),
                              ],
                            ),
                            backgroundColor: Colors.orange,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }
                      
                      Navigator.pop(context);
                      widget.onSubmit(_rating, _contentController.text.trim());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B4513),
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: const Color(0xFF8B4513).withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Gửi nhận xét',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Rất tệ';
      case 2:
        return 'Tệ';
      case 3:
        return 'Trung bình';
      case 4:
        return 'Tốt';
      case 5:
        return 'Tuyệt vời!';
      default:
        return '';
    }
  }
  
  IconData _getRatingIcon(int rating) {
    switch (rating) {
      case 1:
      case 2:
        return Icons.sentiment_very_dissatisfied;
      case 3:
        return Icons.sentiment_neutral;
      case 4:
      case 5:
        return Icons.sentiment_very_satisfied;
      default:
        return Icons.star;
    }
  }
  
  Color _getRatingColor(int rating) {
    switch (rating) {
      case 1:
      case 2:
        return Colors.red[600]!;
      case 3:
        return Colors.orange[600]!;
      case 4:
      case 5:
        return Colors.green[600]!;
      default:
        return Colors.grey;
    }
  }
}

// Character Counter Widget
class _CharacterCounter extends StatefulWidget {
  final TextEditingController controller;
  
  const _CharacterCounter({required this.controller});
  
  @override
  State<_CharacterCounter> createState() => _CharacterCounterState();
}

class _CharacterCounterState extends State<_CharacterCounter> {
  int _characterCount = 0;
  
  @override
  void initState() {
    super.initState();
    _characterCount = widget.controller.text.length;
    widget.controller.addListener(_updateCount);
  }
  
  @override
  void dispose() {
    widget.controller.removeListener(_updateCount);
    super.dispose();
  }
  
  void _updateCount() {
    setState(() {
      _characterCount = widget.controller.text.length;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        '$_characterCount/500',
        style: TextStyle(
          fontSize: 12,
          color: _characterCount > 500 
              ? Colors.red 
              : (_characterCount > 450 
                  ? Colors.orange 
                  : Colors.grey[500]),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
