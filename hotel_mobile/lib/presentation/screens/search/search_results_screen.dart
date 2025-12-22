import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../core/widgets/empty_state_widget.dart';
import 'package:hotel_mobile/data/models/hotel.dart';
import 'package:hotel_mobile/data/services/api_service.dart';
import 'package:hotel_mobile/presentation/widgets/search_result_card.dart';
import 'package:hotel_mobile/presentation/widgets/sticky_filter_bar.dart';
import 'package:hotel_mobile/presentation/widgets/compact_search_header.dart';
import 'package:hotel_mobile/presentation/widgets/enhanced_filter_bottom_sheet.dart';
import 'package:hotel_mobile/presentation/widgets/enhanced_sort_bottom_sheet.dart';
import 'package:hotel_mobile/presentation/widgets/promotion_banner.dart';
import 'package:hotel_mobile/presentation/widgets/edit_search_modal.dart';
import 'package:hotel_mobile/core/widgets/glass_card.dart';

/// Màn hình hiển thị kết quả tìm kiếm khách sạn
/// Thiết kế theo phong cách Agoda: header màu xanh, filter bar đơn giản, danh sách card ngang
/// 
/// Tham số:
/// - location: Địa điểm tìm kiếm
/// - checkInDate: Ngày nhận phòng
/// - checkOutDate: Ngày trả phòng
/// - guestCount: Số lượng khách
/// - roomCount: Số lượng phòng
class SearchResultsScreen extends StatefulWidget {
  final String location;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int guestCount;
  final int roomCount;

  const SearchResultsScreen({
    super.key,
    required this.location,
    required this.checkInDate,
    required this.checkOutDate,
    required this.guestCount,
    required this.roomCount,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen>
    with TickerProviderStateMixin {
  /// ApiService để gọi API lấy danh sách khách sạn
  final ApiService _apiService = ApiService();
  
  /// ScrollController để điều khiển scroll của danh sách
  final ScrollController _scrollController = ScrollController();
  
  // Animation controller cho staggered animations
  late AnimationController _staggerController;

  /// Danh sách khách sạn đã được filter và sort
  List<Hotel> _hotels = [];
  
  /// Danh sách tất cả khách sạn (trước khi filter) - dùng để filter
  List<Hotel> _allHotels = [];
  
  /// Trạng thái loading khi đang tải dữ liệu
  bool _isLoading = true;
  
  /// Thông báo lỗi (nếu có)
  String? _error;

  /// Tham số tìm kiếm (có thể chỉnh sửa)
  late String _location;
  late DateTime _checkInDate;
  late DateTime _checkOutDate;
  late int _guestCount;
  late int _roomCount;

  /// Trạng thái sort và filter
  String _sortBy = 'most_suitable'; // Mặc định: Phù hợp nhất
  
  /// Map chứa các filter đang active
  /// - priceRange: Khoảng giá (RangeValues)
  /// - starRating: Set các sao đã chọn (Set<int>)
  /// - guestReviewScore: Điểm đánh giá tối thiểu (double?)
  /// - propertyTypes: Loại khách sạn (Set<String>)
  /// - areas: Khu vực (Set<String>)
  /// - amenities: Tiện ích (Set<String>)
  /// - cancellationPolicy: Có hủy miễn phí không (bool)
  Map<String, dynamic> _filters = {
    'priceRange': const RangeValues(0, 40000000), // Khoảng giá mặc định
    'starRating': <int>{}, // Chưa chọn sao nào
    'guestReviewScore': null, // Chưa chọn điểm đánh giá
    'propertyTypes': <String>{}, // Chưa chọn loại khách sạn
    'areas': <String>{}, // Chưa chọn khu vực
    'amenities': <String>{}, // Chưa chọn tiện ích
    'cancellationPolicy': false, // Không yêu cầu hủy miễn phí
  };

  /// ============================================
  /// HÀM: initState
  /// ============================================
  /// Khởi tạo state khi widget được tạo
  /// - Khởi tạo các tham số tìm kiếm từ widget
  /// - Gọi _loadSearchResults() để tải danh sách khách sạn
  @override
  void initState() {
    super.initState();
    // Khởi tạo các tham số tìm kiếm từ widget (có thể chỉnh sửa sau)
    _location = widget.location;
    _checkInDate = widget.checkInDate;
    _checkOutDate = widget.checkOutDate;
    _guestCount = widget.guestCount;
    _roomCount = widget.roomCount;
    
    // Initialize animation controller
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    // Start animation
    _staggerController.forward();
    
    // Tải danh sách khách sạn từ API
    _loadSearchResults();
  }

  /// ============================================
  /// HÀM: dispose
  /// ============================================
  /// Giải phóng tài nguyên khi widget bị hủy
  /// Quan trọng: Phải dispose ScrollController để tránh memory leak
  @override
  void dispose() {
    _scrollController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  /// ============================================
  /// HÀM: _loadSearchResults
  /// ============================================
  /// Tải danh sách khách sạn từ API dựa trên địa điểm tìm kiếm
  /// 
  /// Logic:
  /// 1. Set loading = true
  /// 2. Gọi API getHotels() với location
  /// 3. Lưu tất cả hotels vào _allHotels
  /// 4. Áp dụng filter và sort
  /// 5. Cập nhật state
  Future<void> _loadSearchResults() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Gọi API với tham số tìm kiếm (location)
      final response = await _apiService.getHotels(
        search: _location,
        limit: 100, // Giới hạn 100 khách sạn
      );

      setState(() {
        _allHotels = response.data ?? []; // Lưu tất cả hotels (trước khi filter)
        _applyFiltersAndSort(); // Áp dụng filter và sort
        _isLoading = false;
      });
    } catch (e) {
      // Xử lý lỗi
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// ============================================
  /// HÀM: _applyFiltersAndSort
  /// ============================================
  /// Áp dụng các filter và sort cho danh sách khách sạn
  /// 
  /// Logic:
  /// 1. Bắt đầu với tất cả hotels (_allHotels)
  /// 2. Áp dụng filter theo sao (starRating)
  /// 3. Áp dụng filter theo khoảng giá (priceRange)
  /// 4. Áp dụng filter theo điểm đánh giá (guestReviewScore)
  /// 5. Áp dụng filter theo chính sách hủy (cancellationPolicy)
  /// 6. Áp dụng sort theo _sortBy
  /// 7. Cập nhật _hotels với danh sách đã được filter và sort
  void _applyFiltersAndSort() {
    // Bắt đầu với tất cả hotels
    List<Hotel> filtered = List.from(_allHotels);

    /// Filter 1: Lọc theo số sao
    final starRating = _filters['starRating'] as Set<int>;
    if (starRating.isNotEmpty) {
      filtered = filtered.where((hotel) {
        // Chỉ giữ lại hotels có số sao trong danh sách đã chọn
        return hotel.soSao != null && starRating.contains(hotel.soSao!);
      }).toList();
    }

    /// Filter 2: Lọc theo khoảng giá
    final priceRange = _filters['priceRange'] as RangeValues;
    filtered = filtered.where((hotel) {
      final price = hotel.giaTb ?? 1000000; // Giá mặc định nếu null
      // Giữ lại hotels có giá trong khoảng đã chọn
      return price >= priceRange.start && price <= priceRange.end;
    }).toList();

    /// Filter 3: Lọc theo điểm đánh giá khách hàng
    final guestReview = _filters['guestReviewScore'];
    if (guestReview != null) {
      filtered = filtered.where((hotel) {
        final rating = hotel.diemDanhGiaTrungBinh ?? 0;
        // Giữ lại hotels có điểm đánh giá >= điểm tối thiểu
        return rating >= guestReview;
      }).toList();
    }

    /// Filter 4: Lọc theo chính sách hủy (cần backend support)
    if (_filters['cancellationPolicy'] == true) {
      // Filter hotels with free cancellation
      // Hiện tại chưa có dữ liệu từ backend, nên giữ lại tất cả
    }

    /// Bước cuối: Áp dụng sort
    _sortHotels(filtered);

    // Cập nhật state với danh sách đã được filter và sort
    setState(() {
      _hotels = filtered;
    });
  }

  /// ============================================
  /// HÀM: _onSortChanged
  /// ============================================
  /// Được gọi khi người dùng thay đổi cách sắp xếp
  /// 
  /// Tham số:
  /// - sortBy: Kiểu sắp xếp mới (ví dụ: 'price_low', 'rating', etc.)
  void _onSortChanged(String sortBy) {
    setState(() {
      _sortBy = sortBy; // Cập nhật sort type
      _applyFiltersAndSort(); // Áp dụng lại filter và sort
    });
  }

  /// ============================================
  /// HÀM: _onFiltersChanged
  /// ============================================
  /// Được gọi khi người dùng thay đổi filter
  /// 
  /// Tham số:
  /// - filters: Map chứa các filter mới
  void _onFiltersChanged(Map<String, dynamic> filters) {
    setState(() {
      _filters = filters; // Cập nhật filters
      _applyFiltersAndSort(); // Áp dụng lại filter và sort
    });
  }

  /// ============================================
  /// HÀM: _sortHotels
  /// ============================================
  /// Sắp xếp danh sách hotels theo _sortBy
  /// 
  /// Các kiểu sort:
  /// - 'price_low': Giá từ thấp đến cao
  /// - 'price_high': Giá từ cao đến thấp
  /// - 'rating' / 'most_suitable': Điểm đánh giá từ cao đến thấp
  /// - 'stars_high': Số sao từ cao đến thấp
  /// - 'limited_promotion': Khuyến mãi (hiện tại sort theo rating)
  /// 
  /// Tham số:
  /// - hotels: Danh sách hotels cần sort (sẽ được sort in-place)
  void _sortHotels(List<Hotel> hotels) {
    switch (_sortBy) {
      case 'price_low':
        // Sắp xếp theo giá từ thấp đến cao
        hotels.sort((a, b) => (a.giaTb ?? 0).compareTo(b.giaTb ?? 0));
        break;
      case 'price_high':
        // Sắp xếp theo giá từ cao đến thấp
        hotels.sort((a, b) => (b.giaTb ?? 0).compareTo(a.giaTb ?? 0));
        break;
      case 'rating':
      case 'most_suitable':
        // Sắp xếp theo điểm đánh giá từ cao đến thấp (mặc định)
        hotels.sort(
          (a, b) => (b.diemDanhGiaTrungBinh ?? 0).compareTo(
            a.diemDanhGiaTrungBinh ?? 0,
          ),
        );
        break;
      case 'stars_high':
        // Sắp xếp theo số sao từ cao đến thấp
        hotels.sort((a, b) => (b.soSao ?? 0).compareTo(a.soSao ?? 0));
        break;
      case 'limited_promotion':
        // Sắp xếp theo khuyến mãi (hiện tại sort theo rating vì chưa có dữ liệu)
        hotels.sort(
          (a, b) => (b.diemDanhGiaTrungBinh ?? 0).compareTo(
            a.diemDanhGiaTrungBinh ?? 0,
          ),
        );
        break;
      default:
        // Giữ nguyên thứ tự ban đầu
        break;
    }
  }

  void _onSearchUpdated({
    required String location,
    required DateTime checkInDate,
    required DateTime checkOutDate,
    required int guestCount,
    required int roomCount,
  }) {
    setState(() {
      _location = location;
      _checkInDate = checkInDate;
      _checkOutDate = checkOutDate;
      _guestCount = guestCount;
      _roomCount = roomCount;
    });
    _loadSearchResults();
  }

  void _showMapView() {
    // Navigate to map view
    Navigator.pushNamed(
      context,
      '/map-view',
      arguments: {
        'hotels': _hotels,
        'location': widget.location,
        'checkInDate': widget.checkInDate,
        'checkOutDate': widget.checkOutDate,
        'guestCount': widget.guestCount,
        'roomCount': widget.roomCount,
      },
    );
  }

  /// ============================================
  /// HÀM BUILD CHÍNH
  /// ============================================
  /// Xây dựng giao diện màn hình kết quả tìm kiếm
  /// 
  /// Cấu trúc:
  /// - Column chứa:
  ///   1. CompactSearchHeader: Header màu xanh với input fields
  ///   2. _buildEnhancedFilterBar: Filter bar với sort/filter/map buttons
  ///   3. _buildResultsList: Danh sách khách sạn (có thể scroll)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Nền xám nhẹ
      body: Column(
        children: [
          /// ============================================
          /// COMPACT SEARCH HEADER
          /// ============================================
          /// Header màu xanh với các input field có thể chỉnh sửa
          CompactSearchHeader(
            location: _location,
            checkInDate: _checkInDate,
            checkOutDate: _checkOutDate,
            guestCount: _guestCount,
            roomCount: _roomCount,
            onTap: _showEditSearchModal, // Click để chỉnh sửa tìm kiếm
          ),

          /// ============================================
          /// FILTER BAR
          /// ============================================
          /// Bar chứa số lượng kết quả và các nút Sort/Filter/Map
          _buildEnhancedFilterBar(),

          /// ============================================
          /// RESULTS LIST
          /// ============================================
          /// Danh sách khách sạn với layout ngang (Agoda style)
          Expanded(child: _buildResultsList()),
        ],
      ),
    );
  }

  /// ============================================
  /// HÀM: _buildEnhancedFilterBar
  /// ============================================
  /// Xây dựng filter bar với số lượng kết quả và các nút Sort/Filter/Map
  /// Thiết kế Agoda style: đơn giản, rõ ràng
  /// 
  /// Layout:
  /// - Dòng 1: Số lượng kết quả và nút Filter với badge
  /// - Dòng 2: Nút Sort và Map
  Widget _buildEnhancedFilterBar() {
    final activeFilterCount = _getActiveFilterCount();
    
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.shade200.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              /// Dòng 1: Số lượng kết quả và nút Filter
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
                    // Số lượng kết quả
                    Expanded(
                      child: Text(
                        'Tìm thấy ${_hotels.length} khách sạn',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1A1A1A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    
                    // Nút Filter với badge
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _buildFilterBarButton(
                          context: context,
                          icon: Icons.tune,
                          label: activeFilterCount > 0 ? '$activeFilterCount bộ lọc' : 'Bộ lọc',
                          onTap: _showFilterBottomSheet,
                          isActive: activeFilterCount > 0,
                        ),
                        // Badge đỏ nếu có filter active
                        if (activeFilterCount > 0)
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFFE91E63), // Màu đỏ Agoda
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                '$activeFilterCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              
              /// Dòng 2: Nút Sort và Map
              Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    // Sort button
                    Expanded(
                      child: _buildFilterBarButton(
                        context: context,
                        icon: Icons.sort,
                        label: _getSortLabel(_sortBy),
                        onTap: _showSortBottomSheet,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Map button
                    Expanded(
                      child: _buildFilterBarButton(
                        context: context,
                        icon: Icons.map,
                        label: 'Bản đồ',
                        onTap: _showMapView,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ============================================
  /// HÀM HELPER: _buildFilterBarButton
  /// ============================================
  /// Xây dựng nút trong filter bar
  /// 
  /// Tham số:
  /// - context: BuildContext
  /// - icon: Icon hiển thị
  /// - label: Text hiển thị
  /// - onTap: Callback khi click
  /// - isActive: true nếu button đang active (có filter được áp dụng)
  /// 
  /// Trả về: Material với InkWell và Container
  Widget _buildFilterBarButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isActive 
                  ? const Color(0xFF003580) // Viền xanh nếu active
                  : const Color(0xFFE8E8E8), // Viền xám nếu không active
              width: isActive ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: isActive 
                ? const Color(0xFFF0F7FF) // Nền xanh nhạt nếu active
                : Colors.white, // Nền trắng nếu không active
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon, 
                size: 18, 
                color: isActive 
                    ? const Color(0xFF003580) // Màu xanh nếu active
                    : const Color(0xFF666666), // Màu xám nếu không active
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isActive 
                        ? const Color(0xFF003580) // Màu xanh nếu active
                        : const Color(0xFF666666), // Màu xám nếu không active
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getSortLabel(String sortBy) {
    switch (sortBy) {
      case 'price_low':
        return 'Giá thấp';
      case 'price_high':
        return 'Giá cao';
      case 'rating':
        return 'Đánh giá';
      case 'stars_high':
        return 'Sao 5-0';
      case 'limited_promotion':
        return 'Khuyến mãi';
      case 'most_suitable':
      default:
        return 'Phù hợp';
    }
  }

  bool _hasActiveFilters() {
    final starRating = _filters['starRating'] as Set<int>;
    final areas = _filters['areas'] as Set<String>;
    final propertyTypes = _filters['propertyTypes'] as Set<String>;
    final amenities = _filters['amenities'] as Set<String>;
    final guestReview = _filters['guestReviewScore'];
    final cancellation = _filters['cancellationPolicy'];

    return starRating.isNotEmpty ||
        areas.isNotEmpty ||
        propertyTypes.isNotEmpty ||
        amenities.isNotEmpty ||
        guestReview != null ||
        cancellation == true;
  }

  int _getActiveFilterCount() {
    int count = 0;
    final starRating = _filters['starRating'] as Set<int>;
    final areas = _filters['areas'] as Set<String>;
    final propertyTypes = _filters['propertyTypes'] as Set<String>;
    final amenities = _filters['amenities'] as Set<String>;
    
    if (starRating.isNotEmpty) count++;
    if (areas.isNotEmpty) count++;
    if (propertyTypes.isNotEmpty) count++;
    if (amenities.isNotEmpty) count++;
    if (_filters['guestReviewScore'] != null) count++;
    if (_filters['cancellationPolicy'] == true) count++;
    
    return count;
  }

  /// ============================================
  /// HÀM: _buildResultsList
  /// ============================================
  /// Xây dựng danh sách kết quả tìm kiếm
  /// 
  /// Logic:
  /// - Nếu đang loading: hiển thị CircularProgressIndicator
  /// - Nếu có lỗi: hiển thị error message với nút "Thử lại"
  /// - Nếu không có kết quả: hiển thị EmptySearchResultsWidget
  /// - Nếu có kết quả: hiển thị danh sách hotels với SearchResultCard
  /// 
  /// Trả về: Widget tương ứng với trạng thái hiện tại
  Widget _buildResultsList() {
    // Trạng thái loading
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF003580)), // Màu xanh Agoda
            ),
            SizedBox(height: 16),
            Text(
              'Đang tìm kiếm khách sạn...',
              style: TextStyle(
                color: Color(0xFF666666),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    // Trạng thái lỗi
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline, 
              size: 64, 
              color: Color(0xFF999999),
            ),
            const SizedBox(height: 16),
            const Text(
              'Có lỗi xảy ra',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSearchResults, // Thử lại
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003580), // Màu xanh Agoda
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Thử lại',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Trạng thái không có kết quả
    if (_hotels.isEmpty) {
      return EmptySearchResultsWidget(
        onClearFilter: () {
          // Reset tất cả filters về mặc định
          setState(() {
            _filters = {
              'priceRange': const RangeValues(0, 40000000),
              'starRating': <int>{},
              'guestReviewScore': null,
              'propertyTypes': <String>{},
              'areas': <String>{},
              'amenities': <String>{},
              'cancellationPolicy': false,
            };
            _applyFiltersAndSort(); // Áp dụng lại filter
          });
        },
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSearchResults,
      color: const Color(0xFF003580),
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          /// ============================================
          /// PROMOTION BANNER (Tùy chọn)
          /// ============================================
          /// Hiển thị banner khuyến mãi nếu có
          /// Có thể ẩn đi nếu không cần thiết
          // SliverToBoxAdapter(
          //   child: PromotionBanner(
          //     onTap: () {
          //       ScaffoldMessenger.of(context).showSnackBar(
          //         const SnackBar(
          //           content: Text('Khuyến mãi đã được kích hoạt!'),
          //           backgroundColor: Color(0xFF4CAF50),
          //         ),
          //       );
          //     },
          //   ),
          // ),

          /// ============================================
          /// HOTEL LIST
          /// ============================================
          /// Danh sách các card khách sạn với layout ngang và animations
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final hotel = _hotels[index];
                  // Staggered animation delay
                  final animationDelay = index * 0.1;
                  final animationValue = (_staggerController.value - animationDelay).clamp(0.0, 1.0);
                  
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 300 + (index * 50).toInt()),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, 30 * (1 - value)),
                        child: Opacity(
                          opacity: value,
                          child: SearchResultCard(
                            hotel: hotel,
                            checkInDate: _checkInDate,
                            checkOutDate: _checkOutDate,
                            guestCount: _guestCount,
                            roomCount: _roomCount,
                            onTap: () => _navigateToHotelDetail(hotel),
                          ),
                        ),
                      );
                    },
                  );
                },
                childCount: _hotels.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet() {
    // Calculate max price from hotels
    double maxPrice = 40000000;
    if (_allHotels.isNotEmpty) {
      final prices = _allHotels
          .map((h) => h.giaTb ?? 0)
          .where((p) => p > 0)
          .toList();
      if (prices.isNotEmpty) {
        maxPrice = prices.reduce((a, b) => a > b ? a : b);
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EnhancedFilterBottomSheet(
        filters: _filters,
        onFiltersChanged: _onFiltersChanged,
        maxPrice: maxPrice,
        totalResults: _hotels.length,
      ),
    );
  }

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => EnhancedSortBottomSheet(
        currentSort: _sortBy,
        onSortChanged: _onSortChanged,
      ),
    );
  }

  void _showEditSearchModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditSearchModal(
        location: _location,
        checkInDate: _checkInDate,
        checkOutDate: _checkOutDate,
        guestCount: _guestCount,
        roomCount: _roomCount,
        onSearchUpdated: _onSearchUpdated,
      ),
    );
  }

  void _navigateToHotelDetail(Hotel hotel) {
    Navigator.pushNamed(
      context,
      '/property-detail',
      arguments: {
        'hotel': hotel,
        'checkInDate': _checkInDate,
        'checkOutDate': _checkOutDate,
        'guestCount': _guestCount,
        'roomCount': _roomCount,
      },
    );
  }
}

// Old FilterBottomSheet removed - now using EnhancedFilterBottomSheet

// Keep old implementation for backwards compatibility (can be removed later)
class FilterBottomSheet extends StatefulWidget {
  final Map<String, dynamic> filters;
  final ValueChanged<Map<String, dynamic>> onFiltersChanged;

  const FilterBottomSheet({
    super.key,
    required this.filters,
    required this.onFiltersChanged,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late Map<String, dynamic> _tempFilters;

  @override
  void initState() {
    super.initState();
    _tempFilters = Map.from(widget.filters);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                Text(
                  'Bộ lọc',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: _applyFilters,
                  child: const Text('Áp dụng'),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Filter Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPriceRangeFilter(),
                  const SizedBox(height: 24),
                  _buildStarRatingFilter(),
                  const SizedBox(height: 24),
                  _buildAmenitiesFilter(),
                  const SizedBox(height: 24),
                  _buildCancellationFilter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Khoảng giá',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        RangeSlider(
          values: _tempFilters['priceRange'],
          min: 0,
          max: 5000000,
          divisions: 50,
          labels: RangeLabels(
            '${(_tempFilters['priceRange'].start / 1000).round()}k',
            '${(_tempFilters['priceRange'].end / 1000).round()}k',
          ),
          onChanged: (values) {
            setState(() {
              _tempFilters['priceRange'] = values;
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${(_tempFilters['priceRange'].start / 1000).round()}k VNĐ'),
            Text('${(_tempFilters['priceRange'].end / 1000).round()}k VNĐ'),
          ],
        ),
      ],
    );
  }

  Widget _buildStarRatingFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Xếp hạng sao',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [1, 2, 3, 4, 5].map((star) {
            final isSelected = (_tempFilters['starRating'] as Set<int>)
                .contains(star);
            return FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [Text('$star'), const Icon(Icons.star, size: 16)],
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  final starRating = _tempFilters['starRating'] as Set<int>;
                  if (selected) {
                    starRating.add(star);
                  } else {
                    starRating.remove(star);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAmenitiesFilter() {
    final amenities = [
      'WiFi miễn phí',
      'Bể bơi',
      'Phòng gym',
      'Spa',
      'Nhà hàng',
      'Chỗ đậu xe',
      'Máy lạnh',
      'Dịch vụ phòng',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tiện nghi',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: amenities.map((amenity) {
            final isSelected = (_tempFilters['amenities'] as Set<String>)
                .contains(amenity);
            return FilterChip(
              label: Text(amenity),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  final amenitiesSet = _tempFilters['amenities'] as Set<String>;
                  if (selected) {
                    amenitiesSet.add(amenity);
                  } else {
                    amenitiesSet.remove(amenity);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCancellationFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chính sách hủy',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          title: const Text('Hủy miễn phí'),
          value: _tempFilters['cancellationPolicy'],
          onChanged: (value) {
            setState(() {
              _tempFilters['cancellationPolicy'] = value ?? false;
            });
          },
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  void _applyFilters() {
    widget.onFiltersChanged(_tempFilters);
    Navigator.pop(context);
  }
}
