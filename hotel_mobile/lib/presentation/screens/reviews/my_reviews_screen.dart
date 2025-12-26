import 'package:flutter/material.dart';
import '../../../core/widgets/skeleton_loading_widget.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/services/review_service.dart';
import '../../../data/models/review.dart';
import '../../../core/constants/app_constants.dart';
import 'write_review_screen.dart';

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
    WriteReviewScreen.showAsModal(
      context,
      bookingId: review.bookingId.isNotEmpty ? review.bookingId : review.id,
      hotelId: int.tryParse(review.hotelId) ?? 0,
      hotelName: review.hotelName,
      hotelImage: review.hotelImage,
    ).then((shouldRefresh) {
      if (shouldRefresh == true) {
        _loadReviews(); // Reload reviews after successful submission
      }
    });
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

