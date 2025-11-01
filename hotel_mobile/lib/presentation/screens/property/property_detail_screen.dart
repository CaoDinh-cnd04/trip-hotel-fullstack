import 'package:flutter/material.dart';
import 'package:hotel_mobile/data/models/hotel.dart';
import 'package:hotel_mobile/data/models/room.dart';
import 'package:hotel_mobile/data/services/api_service.dart';
import 'package:hotel_mobile/core/utils/image_url_helper.dart';
import 'package:hotel_mobile/presentation/widgets/property_image_gallery.dart';
import 'package:hotel_mobile/presentation/widgets/property_info_section.dart';
import 'package:hotel_mobile/presentation/widgets/amenities_section.dart';
import 'package:hotel_mobile/presentation/widgets/room_selection_section.dart';
import 'package:hotel_mobile/presentation/widgets/bottom_cta_bar.dart';
import 'package:hotel_mobile/presentation/widgets/hotel_action_buttons.dart';
import 'package:hotel_mobile/presentation/widgets/reviews_section.dart';
import 'package:hotel_mobile/presentation/screens/payment/payment_screen.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/skeleton_loading_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';

class PropertyDetailScreen extends StatefulWidget {
  final Hotel hotel;
  final DateTime? checkInDate;
  final DateTime? checkOutDate;
  final int guestCount;

  const PropertyDetailScreen({
    super.key,
    required this.hotel,
    this.checkInDate,
    this.checkOutDate,
    this.guestCount = 1,
  });

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  final ApiService _apiService = ApiService();
  List<Room> _rooms = [];
  bool _isLoadingRooms = true;
  double? _lowestPrice;
  
  // Price selection state
  int _selectedPriceOption = 0; // 0: non-refundable, 1: with breakfast
  double _selectedPrice = 0;
  
  // Dates state - sử dụng từ widget hoặc default
  late DateTime _checkInDate;
  late DateTime _checkOutDate;

  @override
  void initState() {
    super.initState();
    // Khởi tạo dates từ widget hoặc default
    _checkInDate = widget.checkInDate ?? DateTime.now().add(const Duration(days: 1));
    _checkOutDate = widget.checkOutDate ?? DateTime.now().add(const Duration(days: 2));
    
    _loadRooms();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadRooms() async {
    try {
      setState(() => _isLoadingRooms = true);

      print('🔍 Loading rooms for hotel ID: ${widget.hotel.id}');
      
      // Format dates for API
      final availableFrom = DateFormat('yyyy-MM-dd').format(_checkInDate);
      final availableTo = DateFormat('yyyy-MM-dd').format(_checkOutDate);

      // Load rooms from API
      final response = await _apiService.getHotelRooms(
        widget.hotel.id ?? 0,
        availableFrom: availableFrom,
        availableTo: availableTo,
      );

      if (response.success && response.data != null && response.data!.isNotEmpty) {
        // Process rooms: transform image URLs from database to full URLs
        final processedRooms = response.data!.map((room) {
          List<String>? processedImages;
          if (room.hinhAnhPhong != null && room.hinhAnhPhong!.isNotEmpty) {
            processedImages = room.hinhAnhPhong!.map((imagePath) {
              // If already a full URL, return as is
              if (imagePath.startsWith('http')) {
                return imagePath;
              }
              // Otherwise, use ImageUrlHelper to get full URL
              return ImageUrlHelper.getRoomImageUrl(imagePath);
            }).toList();
          }

          return Room(
            id: room.id,
            soPhong: room.soPhong,
            loaiPhongId: room.loaiPhongId,
            khachSanId: room.khachSanId,
            tenLoaiPhong: room.tenLoaiPhong,
            giaPhong: room.giaPhong,
            sucChua: room.sucChua,
            moTa: room.moTa,
            hinhAnhPhong: processedImages,
            tienNghi: room.tienNghi,
            soGiuongDon: room.soGiuongDon,
            soGiuongDoi: room.soGiuongDoi,
            tinhTrang: room.tinhTrang,
          );
        }).toList();

        _rooms = processedRooms;
        
        // Calculate lowest price
        final prices = processedRooms
            .where((room) => room.giaPhong != null && room.giaPhong! > 0)
            .map((room) => room.giaPhong!)
            .toList();
        
        if (prices.isNotEmpty) {
          _lowestPrice = prices.reduce((a, b) => a < b ? a : b);
        } else {
          _lowestPrice = null;
        }

        print('✅ Loaded ${_rooms.length} rooms from API');
        print('💰 Lowest price: ${_lowestPrice}');
      } else {
        print('⚠️ No rooms found or API error: ${response.message}');
        _rooms = [];
        _lowestPrice = null;
      }

      setState(() => _isLoadingRooms = false);
    } catch (e) {
      print('❌ Error loading rooms: $e');
      setState(() {
        _isLoadingRooms = false;
        _rooms = [];
        _lowestPrice = null;
      });
    }
  }

  void _onRoomSelected(Room room) {
    // Navigate to booking screen or show room selection options
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildRoomOptionsBottomSheet(room),
    );
  }

  void _navigateToPayment(Room room, double selectedPrice) {
    // Calculate number of nights
    final nights = _checkOutDate.difference(_checkInDate).inDays;
    
    // Navigate to payment screen with selected price
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          hotel: widget.hotel,
          room: room,
          checkInDate: _checkInDate,
          checkOutDate: _checkOutDate,
          guestCount: widget.guestCount,
          nights: nights,
          roomPrice: selectedPrice, // Use selected price instead of room base price
        ),
      ),
    );
  }
  
  Future<void> _selectDates() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _checkInDate, end: _checkOutDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _checkInDate = picked.start;
        _checkOutDate = picked.end;
      });
      // Reload rooms với ngày mới
      _loadRooms();
    }
  }

  Widget _buildDateInfo(String label, String date, IconData icon, Color color) {
    // Helper để lấy màu đậm hơn
    Color getDarkerShade(Color baseColor) {
      if (baseColor == Colors.blue) return Colors.blue[800]!;
      if (baseColor == Colors.cyan) return Colors.cyan[800]!;
      if (baseColor == Colors.green) return Colors.green[800]!;
      if (baseColor == Colors.teal) return Colors.teal[800]!;
      // Fallback: làm đậm màu bằng cách giảm opacity và thêm black
      return Color.fromRGBO(
        (baseColor.red * 0.6).round(),
        (baseColor.green * 0.6).round(),
        (baseColor.blue * 0.6).round(),
        1.0,
      );
    }
    
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: color,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            date,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: getDarkerShade(color),
              letterSpacing: 0.3,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildRoomOptionsBottomSheet(Room room) {
    // Initialize selected price with room's base price
    if (_selectedPrice == 0) {
      _selectedPrice = room.giaPhong ?? 0;
    }
    
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const SizedBox(height: 24),
              Text(
                room.tenLoaiPhong ?? 'Phòng',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildPriceOption(
                'Không hoàn tiền',
                room.giaPhong ?? 0,
                'Giá tốt nhất • Không thể hủy',
                false,
                0,
                setModalState,
              ),
              const SizedBox(height: 12),
              _buildPriceOption(
                'Kèm bữa sáng',
                (room.giaPhong ?? 0) + 200000,
                'Hủy miễn phí • Bao gồm bữa sáng',
                true,
                1,
                setModalState,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _navigateToPayment(room, _selectedPrice);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Tiếp tục đặt phòng',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPriceOption(
    String title,
    double price,
    String description,
    bool recommended,
    int optionIndex,
    StateSetter setModalState,
  ) {
    final isSelected = _selectedPriceOption == optionIndex;
    
    return GestureDetector(
      onTap: () {
        setModalState(() {
          _selectedPriceOption = optionIndex;
          _selectedPrice = price;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected 
                ? Colors.blue 
                : (recommended ? Colors.orange : Colors.grey[300]!),
            width: isSelected ? 2 : (recommended ? 2 : 1),
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? Colors.blue.withOpacity(0.05) : Colors.white,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          title: Row(
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              if (recommended) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Khuyến nghị',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_formatPrice(price)}/đêm',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Đã chọn',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
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

  String _formatPrice(double price) {
    return '${(price / 1000).toStringAsFixed(0)}K VND';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // App Bar với design hiện đại
              SliverAppBar(
                expandedHeight: 0,
                floating: true,
                pinned: true,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white,
                        Colors.grey[100]!,
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                    onPressed: () => Navigator.pop(context),
                    color: Colors.black87,
                  ),
                ),
                actions: [
                  // Wrap existing buttons with modern design
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white,
                          Colors.grey[100]!,
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ShareHotelButton(hotel: widget.hotel, compact: true),
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white,
                          Colors.grey[100]!,
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: SaveHotelButton(hotel: widget.hotel, compact: true),
                  ),
                  const SizedBox(width: 8),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.grey[300]!,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Image Gallery
              SliverToBoxAdapter(
                child: PropertyImageGallery(hotel: widget.hotel),
              ),

              // Date Selection Section - Thiết kế đơn giản và đầy màu sắc
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.purple[50]!,
                        Colors.pink[50]!,
                        Colors.orange[50]!,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.purple[200]!,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _selectDates,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.purple[600]!,
                                        Colors.pink[600]!,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.purple.withOpacity(0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.calendar_month,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Chọn ngày nhận và trả phòng',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _buildDateInfo(
                                      'Nhận phòng',
                                      DateFormat('dd/MM/yyyy').format(_checkInDate),
                                      Icons.login_rounded,
                                      Colors.purple,
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 45,
                                    margin: const EdgeInsets.symmetric(horizontal: 10),
                                    color: Colors.grey[300]!,
                                  ),
                                  Expanded(
                                    child: _buildDateInfo(
                                      'Trả phòng',
                                      DateFormat('dd/MM/yyyy').format(_checkOutDate),
                                      Icons.logout_rounded,
                                      Colors.pink,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.orange[400]!,
                                          Colors.red[400]!,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.orange.withOpacity(0.3),
                                          blurRadius: 6,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.bedtime,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${_checkOutDate.difference(_checkInDate).inDays} đêm',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.blue[300]!,
                                          Colors.cyan[300]!,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.edit,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Divider
              SliverToBoxAdapter(
                child: Container(
                  height: 1,
                  color: Colors.grey[200],
                ),
              ),

              // Property Info Section
              SliverToBoxAdapter(
                child: PropertyInfoSection(hotel: widget.hotel),
              ),

              // Divider
              SliverToBoxAdapter(
                child: Container(
                  height: 8,
                  color: Colors.grey[100],
                ),
              ),

              // Reviews Section - Hiển thị NGAY sau Property Info, trước Amenities
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                    ),
                  ),
                  child: ReviewsSection(
                    hotelId: widget.hotel.id ?? 0,
                    onReviewAdded: () {
                      // Refresh reviews when a new review is added
                    },
                  ),
                ),
              ),

              // Divider
              SliverToBoxAdapter(
                child: Container(
                  height: 8,
                  color: Colors.grey[100],
                ),
              ),

              // Amenities Section
              SliverToBoxAdapter(
                child: AmenitiesSection(hotel: widget.hotel),
              ),

              // Divider
              SliverToBoxAdapter(
                child: Container(
                  height: 8,
                  color: Colors.grey[100],
                ),
              ),

              // Room Selection Section
              SliverToBoxAdapter(
                child: _isLoadingRooms
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: SkeletonLoadingWidget(
                          itemType: LoadingItemType.roomCard,
                          itemCount: 3,
                        ),
                      )
                    : _rooms.isEmpty
                        ? EmptyRoomsWidget()
                        : RoomSelectionSection(
                            rooms: _rooms,
                            onRoomSelected: _onRoomSelected,
                            checkInDate: _checkInDate,
                            checkOutDate: _checkOutDate,
                            guestCount: widget.guestCount,
                          ),
              ),

              // Bottom padding for CTA bar
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),

          // Bottom CTA Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BottomCTABar(
              lowestPrice: _lowestPrice,
              onSelectRoom: () {
                if (_rooms.isNotEmpty) {
                  _onRoomSelected(_rooms.first);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
