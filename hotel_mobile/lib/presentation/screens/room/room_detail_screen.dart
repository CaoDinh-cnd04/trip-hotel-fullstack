import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:hotel_mobile/data/models/room.dart';
import 'package:hotel_mobile/data/models/hotel.dart';
import 'package:hotel_mobile/data/services/api_service.dart';
import 'package:hotel_mobile/presentation/screens/booking/booking_form_screen.dart';
import 'package:hotel_mobile/core/utils/image_url_helper.dart';
import 'package:hotel_mobile/core/widgets/glass_card.dart';
import 'package:animations/animations.dart';
import 'package:intl/intl.dart';

/// Màn hình chi tiết phòng - Thiết kế hiện đại
/// Sử dụng CustomScrollView với Sliver widgets để có trải nghiệm scroll mượt mà
/// 
/// Tham số:
/// - room: Đối tượng Room cần hiển thị chi tiết
/// - hotel: Đối tượng Hotel (optional) để hiển thị thông tin khách sạn
class RoomDetailScreen extends StatefulWidget {
  final Room room;
  final Hotel? hotel;

  const RoomDetailScreen({super.key, required this.room, this.hotel});

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController();

  Room? _roomDetails;
  bool _isLoading = true;
  int _currentImageIndex = 0;
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _apiService.initialize();
    
    // Initialize animations
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    
    _loadRoomDetails();
    
    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadRoomDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.room.id != null) {
        final response = await _apiService.getRoomById(widget.room.id!);
        if (response.success && response.data != null) {
          setState(() {
            _roomDetails = response.data!;
            _isLoading = false;
          });
        } else {
          setState(() {
            _roomDetails = widget.room;
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _roomDetails = widget.room;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _roomDetails = widget.room;
        _isLoading = false;
      });
    }
  }

  /// Format tiền tệ theo định dạng Việt Nam
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: const Text(
            'Chi tiết phòng',
            style: TextStyle(
              color: Color(0xFF1A1A1A),
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final room = _roomDetails ?? widget.room;
    final images = room.fullImageUrls;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              /// ============================================
              /// SLIVER 1: APP BAR (Glass morphism)
              /// ============================================
              SliverAppBar(
                expandedHeight: 0,
                floating: true,
                pinned: true,
                backgroundColor: Colors.white.withValues(alpha: 0.8),
                foregroundColor: const Color(0xFF1A1A1A),
                elevation: 0,
                flexibleSpace: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                  onPressed: () => Navigator.pop(context),
                  color: const Color(0xFF1A1A1A),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 22),
                    onPressed: _loadRoomDetails,
                    color: const Color(0xFF666666),
                  ),
                  const SizedBox(width: 8),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(
                    height: 1,
                    color: const Color(0xFFE8E8E8).withValues(alpha: 0.3),
                  ),
                ),
              ),

              /// ============================================
              /// SLIVER 2: IMAGE GALLERY
              /// ============================================
              SliverToBoxAdapter(
                child: _buildImageGallery(images),
              ),

              /// ============================================
              /// SLIVER 3: ROOM HEADER (Glass + Animation)
              /// ============================================
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: GlassCard(
                      blur: 15,
                      opacity: 0.25,
                      borderRadius: 0,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      padding: const EdgeInsets.all(20),
                      child: _buildRoomHeader(room),
                    ),
                  ),
                ),
              ),

              /// ============================================
              /// SLIVER 4: PRICE OPTIONS (Glass + Animation)
              /// ============================================
              if (room.giaPhong != null)
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: GlassCard(
                        blur: 15,
                        opacity: 0.25,
                        borderRadius: 20,
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        padding: const EdgeInsets.all(20),
                        child: _buildPriceOptions(room),
                      ),
                    ),
                  ),
                ),

              /// ============================================
              /// SLIVER 5: ROOM DETAILS (Glass + Animation)
              /// ============================================
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: GlassCard(
                      blur: 15,
                      opacity: 0.25,
                      borderRadius: 20,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(20),
                      child: _buildRoomDetails(room),
                    ),
                  ),
                ),
              ),

              /// ============================================
              /// SLIVER 6: DESCRIPTION (Glass + Animation)
              /// ============================================
              if (room.moTa != null && room.moTa!.isNotEmpty)
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: GlassCard(
                        blur: 15,
                        opacity: 0.25,
                        borderRadius: 20,
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        padding: const EdgeInsets.all(20),
                        child: _buildDescription(room),
                      ),
                    ),
                  ),
                ),

              /// ============================================
              /// SLIVER 7: AMENITIES (Glass + Animation)
              /// ============================================
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: GlassCard(
                      blur: 15,
                      opacity: 0.25,
                      borderRadius: 20,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(20),
                      child: _buildAmenities(room),
                    ),
                  ),
                ),
              ),

              /// Bottom padding
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),

          /// ============================================
          /// BOTTOM CTA BAR
          /// ============================================
          if (room.tinhTrang)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomBar(room),
            ),
        ],
      ),
    );
  }

  /// ============================================
  /// HÀM: _buildImageGallery
  /// ============================================
  /// Gallery hình ảnh phòng - chiều cao 300px
  Widget _buildImageGallery(List<String> images) {
    if (images.isEmpty) {
      return Container(
        width: double.infinity,
        height: 300,
        color: const Color(0xFFE8E8E8),
        child: const Center(
          child: Icon(Icons.bed, size: 64, color: Color(0xFF999999)),
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: 300,
      color: Colors.white,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: images.length,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Image.network(
                images[index],
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFFE8E8E8),
                  child: const Center(
                    child: Icon(Icons.bed, size: 64, color: Color(0xFF999999)),
                  ),
                ),
              );
            },
          ),
          if (images.length > 1) ...[
            // Page indicator
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: images.asMap().entries.map((entry) {
                  return GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        entry.key,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      width: _currentImageIndex == entry.key ? 24 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: _currentImageIndex == entry.key
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            // Image counter
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentImageIndex + 1}/${images.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            // Navigation arrows
            if (_currentImageIndex > 0)
              Positioned(
                left: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ),
            if (_currentImageIndex < images.length - 1)
              Positioned(
                right: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    onPressed: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  /// ============================================
  /// HÀM: _buildRoomHeader
  /// ============================================
  /// Header hiển thị tên phòng và thông tin cơ bản
  Widget _buildRoomHeader(Room room) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tên phòng
        Text(
          room.tenLoaiPhong ?? 'Phòng ${room.soPhong}',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
            letterSpacing: -0.3,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 12),
        
        // Thông tin nhanh
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            // Sức chứa
            if (room.sucChua != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.people_outline,
                    size: 16,
                    color: Color(0xFF666666),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${room.sucChua} khách',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            // Giường
            if (room.soGiuongDon != null || room.soGiuongDoi != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.bed,
                    size: 16,
                    color: Color(0xFF666666),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getBedInfoShort(room),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  String _getBedInfoShort(Room room) {
    final beds = <String>[];
    if (room.soGiuongDon != null && room.soGiuongDon! > 0) {
      beds.add('${room.soGiuongDon} đơn');
    }
    if (room.soGiuongDoi != null && room.soGiuongDoi! > 0) {
      beds.add('${room.soGiuongDoi} đôi');
    }
    return beds.isEmpty ? 'N/A' : beds.join(', ');
  }

  /// ============================================
  /// HÀM: _buildPriceOptions
  /// ============================================
  /// Tùy chọn giá - Non-refundable và Free cancellation
  Widget _buildPriceOptions(Room room) {
    final basePrice = room.giaPhong ?? 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tùy chọn giá',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 16),
        
        // Option 1: Non-refundable (Best price)
        _buildPriceOptionCard(
          title: 'Không hoàn tiền',
          price: basePrice,
          description: 'Giá tốt nhất • Không thể hủy',
          recommended: false,
          room: room,
        ),
        const SizedBox(height: 12),
        
        // Option 2: Free cancellation (Recommended)
        _buildPriceOptionCard(
          title: 'Có thể hủy miễn phí',
          price: basePrice + 200000, // +200k for free cancellation
          description: 'Hủy miễn phí • Linh hoạt hơn',
          recommended: true,
          room: room,
        ),
      ],
    );
  }

  Widget _buildPriceOptionCard({
    required String title,
    required double price,
    required String description,
    required bool recommended,
    required Room room,
  }) {
    return OpenContainer(
      closedBuilder: (context, action) => GestureDetector(
        onTap: action,
        child: GlassCard(
          blur: 20,
          opacity: recommended ? 0.3 : 0.2,
          borderRadius: 16,
          borderColor: recommended ? const Color(0xFF003580) : Colors.white,
          borderWidth: recommended ? 2 : 1,
          padding: const EdgeInsets.all(16),
          child: _buildPriceOptionContent(
            title: title,
            price: price,
            description: description,
            recommended: recommended,
          ),
        ),
      ),
      openBuilder: (context, action) => BookingFormScreen(room: room, hotel: widget.hotel),
      transitionDuration: const Duration(milliseconds: 400),
      closedElevation: 0,
      openElevation: 0,
    );
  }

  Widget _buildPriceOptionContent({
    required String title,
    required double price,
    required String description,
    required bool recommended,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            if (recommended)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF003580),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Khuyến nghị',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          description,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF666666),
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '${currencyFormat.format(price)}/đêm',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF003580),
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  /// ============================================
  /// HÀM: _buildRoomDetails
  /// ============================================
  /// Chi tiết phòng - grid layout
  Widget _buildRoomDetails(Room room) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chi tiết phòng',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 16),
        
        // Grid layout cho thông tin - 2 cột
        if (room.sucChua != null || room.soGiuongDon != null || room.soGiuongDoi != null)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (room.sucChua != null)
                Expanded(
                  child: _buildDetailItem(
                    icon: Icons.people_outline,
                    label: 'Sức chứa',
                    value: '${room.sucChua} khách',
                  ),
                ),
              if (room.sucChua != null && (room.soGiuongDon != null || room.soGiuongDoi != null))
                const SizedBox(width: 16),
              if (room.soGiuongDon != null || room.soGiuongDoi != null)
                Expanded(
                  child: _buildDetailItem(
                    icon: Icons.bed,
                    label: 'Giường',
                    value: _getBedInfo(room),
                  ),
                ),
            ],
          ),
        if (room.tenKhachSan != null || widget.hotel != null) ...[
          if (room.sucChua != null || room.soGiuongDon != null || room.soGiuongDoi != null)
            const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  icon: Icons.hotel_outlined,
                  label: 'Khách sạn',
                  value: room.tenKhachSan ?? widget.hotel?.ten ?? 'N/A',
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: const Color(0xFF666666),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF666666),
                  fontWeight: FontWeight.w400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  String _getBedInfo(Room room) {
    final beds = <String>[];
    if (room.soGiuongDon != null && room.soGiuongDon! > 0) {
      beds.add('${room.soGiuongDon} giường đơn');
    }
    if (room.soGiuongDoi != null && room.soGiuongDoi! > 0) {
      beds.add('${room.soGiuongDoi} giường đôi');
    }
    return beds.isEmpty ? 'N/A' : beds.join(', ');
  }


  /// ============================================
  /// HÀM: _buildDescription
  /// ============================================
  /// Mô tả phòng
  Widget _buildDescription(Room room) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mô tả phòng',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          room.moTa!,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF1A1A1A),
            height: 1.6,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  /// ============================================
  /// HÀM: _buildAmenities
  /// ============================================
  /// Tiện ích phòng - grid layout 2 cột
  Widget _buildAmenities(Room room) {
    // Lấy tiện ích từ room hoặc dùng mặc định
    final amenities = room.tienNghi ?? [];
    
    // Nếu không có tiện ích, dùng danh sách mặc định
    final defaultAmenities = [
      {'icon': Icons.wifi, 'text': 'WiFi miễn phí'},
      {'icon': Icons.ac_unit, 'text': 'Điều hòa'},
      {'icon': Icons.tv, 'text': 'TV'},
      {'icon': Icons.local_bar, 'text': 'Minibar'},
      {'icon': Icons.bathroom, 'text': 'Phòng tắm'},
      {'icon': Icons.dry_cleaning, 'text': 'Máy sấy'},
    ];

    final displayAmenities = amenities.isEmpty 
        ? defaultAmenities 
        : amenities.map((amenity) => {
            'icon': _getAmenityIcon(amenity),
            'text': amenity,
          }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tiện ích phòng',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 16),
        // Grid layout 2 cột - sử dụng Wrap để tự động xuống dòng
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: displayAmenities.map((amenity) {
            return SizedBox(
              width: (MediaQuery.of(context).size.width - 44) / 2, // 2 columns
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      amenity['icon'] as IconData,
                      size: 18,
                      color: const Color(0xFF1A1A1A),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        amenity['text'] as String,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1A1A1A),
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Helper function để map tên tiện ích sang icon
  IconData _getAmenityIcon(String amenity) {
    final lowerAmenity = amenity.toLowerCase();
    if (lowerAmenity.contains('wifi') || lowerAmenity.contains('internet')) {
      return Icons.wifi;
    } else if (lowerAmenity.contains('điều hòa') || lowerAmenity.contains('ac')) {
      return Icons.ac_unit;
    } else if (lowerAmenity.contains('tv') || lowerAmenity.contains('tivi')) {
      return Icons.tv;
    } else if (lowerAmenity.contains('minibar') || lowerAmenity.contains('bar')) {
      return Icons.local_bar;
    } else if (lowerAmenity.contains('phòng tắm') || lowerAmenity.contains('bathroom')) {
      return Icons.bathroom;
    } else if (lowerAmenity.contains('máy sấy') || lowerAmenity.contains('dry')) {
      return Icons.dry_cleaning;
    } else if (lowerAmenity.contains('giường')) {
      return Icons.bed;
    } else if (lowerAmenity.contains('bãi đỗ') || lowerAmenity.contains('parking')) {
      return Icons.local_parking;
    }
    return Icons.check_circle;
  }

  /// ============================================
  /// HÀM: _buildBottomBar
  /// ============================================
  /// Bottom bar với glass morphism effect
  Widget _buildBottomBar(Room room) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                if (room.giaPhong != null)
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Từ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF999999),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currencyFormat.format(room.giaPhong ?? 0),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF003580),
                            letterSpacing: -0.3,
                            height: 1.0,
                          ),
                        ),
                        const Text(
                          '/đêm',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF999999),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => _navigateToBooking(room),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003580),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Chọn phòng',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToBooking(Room room) async {
    if (room.id == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Không thể đặt phòng này')));
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            BookingFormScreen(room: room, hotel: widget.hotel),
      ),
    );

    if (result == true) {
      // Refresh room details after booking
      _loadRoomDetails();
    }
  }
}

