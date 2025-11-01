import 'package:flutter/material.dart';
import 'package:hotel_mobile/data/models/hotel.dart';
import 'package:hotel_mobile/data/services/api_service.dart';
import 'package:hotel_mobile/presentation/screens/room/room_detail_screen.dart';
import 'package:hotel_mobile/presentation/screens/booking/enhanced_booking_screen.dart';
import 'package:hotel_mobile/presentation/screens/property/property_detail_screen.dart';
import 'package:hotel_mobile/presentation/widgets/hotel_card_with_favorite.dart';
import 'package:hotel_mobile/presentation/widgets/enhanced_filter_bottom_sheet.dart';
import 'package:intl/intl.dart';

class HotelListScreen extends StatefulWidget {
  final String location;
  final String? title;
  final DateTime? checkInDate;
  final DateTime? checkOutDate;
  final int guestCount;
  final int roomCount;

  const HotelListScreen({
    super.key,
    required this.location,
    this.title,
    this.checkInDate,
    this.checkOutDate,
    this.guestCount = 1,
    this.roomCount = 1,
  });

  @override
  State<HotelListScreen> createState() => _HotelListScreenState();
}

class _HotelListScreenState extends State<HotelListScreen> {
  final ApiService _apiService = ApiService();
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  List<Hotel> _hotels = [];
  List<Hotel> _allHotels = []; // Store all hotels for filtering
  bool _isLoading = true;
  String? _error;
  
  // Dates state - sử dụng từ widget hoặc default
  late DateTime _checkInDate;
  late DateTime _checkOutDate;
  
  // Filter state - sẽ được cập nhật khi có hotels
  Map<String, dynamic> _filters = {
    'starRating': <int>{},
    'priceRange': const RangeValues(0, 40000000), // Default, sẽ được cập nhật khi load hotels
    'guestReviewScore': null,
    'amenities': <String>{},
    'cancellationPolicy': false,
  };
  int _activeFilterCount = 0;

  @override
  void initState() {
    super.initState();
    // Khởi tạo dates từ widget hoặc default
    _checkInDate = widget.checkInDate ?? DateTime.now().add(const Duration(days: 1));
    _checkOutDate = widget.checkOutDate ?? DateTime.now().add(const Duration(days: 2));
    
    _apiService.initialize();
    _loadHotels();
    _updateActiveFilterCount();
  }
  
  void _updateActiveFilterCount() {
    int count = 0;
    if ((_filters['starRating'] as Set<int>).isNotEmpty) count++;
    final priceRange = _filters['priceRange'] as RangeValues;
    if (priceRange.start > 0 || priceRange.end < 40000000) count++;
    if (_filters['guestReviewScore'] != null) count++;
    if ((_filters['amenities'] as Set<String>).isNotEmpty) count++;
    if (_filters['cancellationPolicy'] == true) count++;
    setState(() {
      _activeFilterCount = count;
    });
  }

  Future<void> _loadHotels() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Handle special search cases
      String searchQuery = widget.location;
      bool sortByRating = false;

      if (widget.location == 'Tất cả') {
        searchQuery = ''; // Get all hotels
      } else if (widget.location.contains('đánh giá cao') ||
          widget.location.contains('rating') ||
          widget.location.contains('Đánh giá cao')) {
        searchQuery = ''; // Get all hotels to sort by rating
        sortByRating = true;
      } else if (widget.location.contains('Gần bạn') ||
          widget.location.contains('gần đây')) {
        searchQuery = 'Thành phố Hồ Chí Minh'; // Default to HCMC for nearby
      }

      print('🔍 Searching hotels with query: "$searchQuery"');

      final response = await _apiService.getHotels(
        search: searchQuery,
        limit: 50,
      );

      print('📊 API Response: success=${response.success}, count=${response.data?.length ?? 0}');

      if (response.success && response.data != null && response.data!.isNotEmpty) {
        // ✅ API thành công và có data - dùng data thật từ SQL Server
        List<Hotel> hotels = response.data!;

        // Sort by rating if needed
        if (sortByRating) {
          hotels.sort(
            (a, b) => (b.diemDanhGiaTrungBinh ?? 0.0).compareTo(
              a.diemDanhGiaTrungBinh ?? 0.0,
            ),
          );
        }

        // Calculate maxPrice and update filter
        double maxPrice = 40000000;
        if (hotels.isNotEmpty) {
          final prices = hotels.map((h) => h.giaTb ?? 0).where((p) => p > 0).toList();
          if (prices.isNotEmpty) {
            maxPrice = prices.reduce((a, b) => a > b ? a : b).toDouble();
          }
          if (maxPrice < 1000000) maxPrice = 40000000;
          
          // Update priceRange if current max is larger than actual maxPrice
          final currentPriceRange = _filters['priceRange'] as RangeValues;
          if (currentPriceRange.end > maxPrice) {
            _filters['priceRange'] = RangeValues(
              currentPriceRange.start.clamp(0.0, maxPrice),
              maxPrice,
            );
          }
        }
        
        setState(() {
          _allHotels = hotels;
          _applyFilters();
          _isLoading = false;
        });
        print('✅ Loaded ${hotels.length} hotels from backend API');
      } else {
        // ❌ API fail hoặc không có data - dùng fallback
        print('⚠️ API returned no data, using fallback');
        _loadFallbackData();
      }
    } catch (e) {
      print('❌ Error loading hotels: $e');
      // Use fallback data when API fails
      _loadFallbackData();
    }
  }

  void _loadFallbackData() {
    // Create fallback hotels based on location
    List<Hotel> fallbackHotels = [];
    
    final locationLower = widget.location.toLowerCase();
    
    if (locationLower.contains('hà nội') || locationLower.contains('hanoi')) {
      fallbackHotels = _getHanoiHotels();
    } else if (locationLower.contains('hồ chí minh') || 
               locationLower.contains('tp.hcm') ||
               locationLower.contains('saigon') ||
               locationLower.contains('sài gòn')) {
      fallbackHotels = _getHCMCHotels();
    } else if (locationLower.contains('đà nẵng') || locationLower.contains('danang')) {
      fallbackHotels = _getDaNangHotels();
    } else if (locationLower.contains('vũng tàu') || locationLower.contains('vung tau')) {
      fallbackHotels = _getVungTauHotels();
    } else if (locationLower.contains('nha trang')) {
      fallbackHotels = _getNhaTrangHotels();
    } else if (locationLower.contains('phú quốc') || locationLower.contains('phu quoc')) {
      fallbackHotels = _getPhuQuocHotels();
    } else {
      // If no match, show empty to avoid confusion
      fallbackHotels = [];
    }

        // Calculate maxPrice and update filter for fallback data
        double maxPrice = 40000000;
        if (fallbackHotels.isNotEmpty) {
          final prices = fallbackHotels.map((h) => h.giaTb ?? 0).where((p) => p > 0).toList();
          if (prices.isNotEmpty) {
            maxPrice = prices.reduce((a, b) => a > b ? a : b).toDouble();
          }
          if (maxPrice < 1000000) maxPrice = 40000000;
          
          // Update priceRange if current max is larger than actual maxPrice
          final currentPriceRange = _filters['priceRange'] as RangeValues;
          if (currentPriceRange.end > maxPrice) {
            _filters['priceRange'] = RangeValues(
              currentPriceRange.start.clamp(0.0, maxPrice),
              maxPrice,
            );
          }
        }
        
        setState(() {
          _allHotels = fallbackHotels;
          _applyFilters();
          _isLoading = false;
          _error = null;
        });
  }

  List<Hotel> _getHanoiHotels() {
    return [
      Hotel(
        id: 1,
        ten: 'Hanoi Heritage Hotel',
        diaChi: 'Phố Cổ, Hoàn Kiếm, Hà Nội',
        giaTb: 800000,
        soSao: 4,
        diemDanhGiaTrungBinh: 4.5,
        hinhAnh: '/images/hotels/hanoi_heritage.jpg',
        moTa: 'Khách sạn cổ điển tại trung tâm phố cổ Hà Nội',
      ),
      Hotel(
        id: 2,
        ten: 'Grand Hotel Hanoi',
        diaChi: 'Quận Ba Đình, Hà Nội',
        giaTb: 1200000,
        soSao: 5,
        diemDanhGiaTrungBinh: 4.8,
        hinhAnh: '/images/hotels/hanoi_deluxe.jpg',
        moTa: 'Khách sạn 5 sao sang trọng gần Hồ Gươm',
      ),
      Hotel(
        id: 3,
        ten: 'Lake View Hotel',
        diaChi: 'Bờ Hồ Tây, Hà Nội',
        giaTb: 900000,
        soSao: 4,
        diemDanhGiaTrungBinh: 4.3,
        hinhAnh: '/images/hotels/lake_view.jpg',
        moTa: 'Khách sạn với view hồ tuyệt đẹp',
      ),
    ];
  }

  List<Hotel> _getHCMCHotels() {
    return [
      Hotel(
        id: 4,
        ten: 'Grand Hotel Saigon',
        diaChi: 'Quận 1, TP. Hồ Chí Minh',
        giaTb: 1500000,
        soSao: 5,
        diemDanhGiaTrungBinh: 4.7,
        hinhAnh: '/images/hotels/saigon_star.jpg',
        moTa: 'Khách sạn 5 sao tại trung tâm Sài Gòn',
      ),
      Hotel(
        id: 5,
        ten: 'Saigon Riverside Hotel',
        diaChi: 'Quận 1, TP. Hồ Chí Minh',
        giaTb: 1100000,
        soSao: 4,
        diemDanhGiaTrungBinh: 4.4,
        hinhAnh: '/images/hotels/saigon_riverside.jpg',
        moTa: 'Khách sạn bên sông Sài Gòn',
      ),
      Hotel(
        id: 6,
        ten: 'District 3 Boutique Hotel',
        diaChi: 'Quận 3, TP. Hồ Chí Minh',
        giaTb: 700000,
        soSao: 3,
        diemDanhGiaTrungBinh: 4.1,
        hinhAnh: '/images/hotels/district3_boutique.jpg',
        moTa: 'Khách sạn boutique tại Quận 3',
      ),
    ];
  }

  List<Hotel> _getDaNangHotels() {
    return [
      Hotel(
        id: 7,
        ten: 'Da Nang Beach Resort',
        diaChi: 'Bãi biển Mỹ Khê, Đà Nẵng',
        giaTb: 1300000,
        soSao: 5,
        diemDanhGiaTrungBinh: 4.6,
        hinhAnh: '/images/hotels/marble_mountain.jpg',
        moTa: 'Resort 5 sao bên bãi biển đẹp nhất Đà Nẵng',
      ),
      Hotel(
        id: 8,
        ten: 'Golden Bay Hotel',
        diaChi: 'Sơn Trà, Đà Nẵng',
        giaTb: 1000000,
        soSao: 4,
        diemDanhGiaTrungBinh: 4.3,
        hinhAnh: '/images/hotels/golden_bay.jpg',
        moTa: 'Khách sạn với view biển tuyệt đẹp',
      ),
    ];
  }

  List<Hotel> _getVungTauHotels() {
    return [
      Hotel(
        id: 9,
        ten: 'Seashell Hotel & Spa',
        diaChi: 'Bãi Sau, Vũng Tàu',
        giaTb: 950000,
        soSao: 4,
        diemDanhGiaTrungBinh: 4.4,
        hinhAnh: '/images/hotels/beach_paradise.jpg',
        moTa: 'Resort view biển đẹp tại Vũng Tàu',
      ),
      Hotel(
        id: 10,
        ten: 'Imperial Hotel Vung Tau',
        diaChi: 'Bãi Trước, Vũng Tàu',
        giaTb: 1200000,
        soSao: 5,
        diemDanhGiaTrungBinh: 4.6,
        hinhAnh: '/images/hotels/golden_bay.jpg',
        moTa: 'Khách sạn 5 sao sang trọng view biển',
      ),
      Hotel(
        id: 11,
        ten: 'Sammy Hotel',
        diaChi: 'Thùy Vân, Vũng Tàu',
        giaTb: 650000,
        soSao: 3,
        diemDanhGiaTrungBinh: 4.1,
        hinhAnh: '/images/hotels/danang_city.jpg',
        moTa: 'Khách sạn tiện nghi giá tốt gần biển',
      ),
    ];
  }

  List<Hotel> _getNhaTrangHotels() {
    return [
      Hotel(
        id: 12,
        ten: 'Beach Paradise Resort',
        diaChi: 'Trần Phú, Nha Trang',
        giaTb: 1200000,
        soSao: 4,
        diemDanhGiaTrungBinh: 4.5,
        hinhAnh: '/images/hotels/nhatrang_beachfront.jpg',
        moTa: 'Resort bên bãi biển Nha Trang',
      ),
      Hotel(
        id: 13,
        ten: 'Nha Trang Lodge',
        diaChi: 'Lô 29, Trần Phú, Nha Trang',
        giaTb: 850000,
        soSao: 4,
        diemDanhGiaTrungBinh: 4.3,
        hinhAnh: '/images/hotels/marble_mountain.jpg',
        moTa: 'Khách sạn ven biển với tiện nghi hiện đại',
      ),
    ];
  }

  List<Hotel> _getPhuQuocHotels() {
    return [
      Hotel(
        id: 14,
        ten: 'Phu Quoc Eco Beach Resort',
        diaChi: 'Bãi Dài, Phú Quốc',
        giaTb: 1500000,
        soSao: 5,
        diemDanhGiaTrungBinh: 4.7,
        hinhAnh: '/images/hotels/beach_paradise.jpg',
        moTa: 'Resort sinh thái cao cấp',
      ),
      Hotel(
        id: 15,
        ten: 'Sunset Beach Hotel',
        diaChi: 'Bãi Kem, Phú Quốc',
        giaTb: 1100000,
        soSao: 4,
        diemDanhGiaTrungBinh: 4.4,
        hinhAnh: '/images/hotels/golden_bay.jpg',
        moTa: 'Khách sạn view hoàng hôn tuyệt đẹp',
      ),
    ];
  }

  void _applyFilters() {
    List<Hotel> filtered = List.from(_allHotels);
    
    // Apply star rating filter
    final starRating = _filters['starRating'] as Set<int>;
    if (starRating.isNotEmpty) {
      filtered = filtered.where((hotel) {
        return hotel.soSao != null && starRating.contains(hotel.soSao!);
      }).toList();
    }
    
    // Apply price range filter
    final priceRange = _filters['priceRange'] as RangeValues;
    filtered = filtered.where((hotel) {
      final price = hotel.giaTb ?? 1000000;
      return price >= priceRange.start && price <= priceRange.end;
    }).toList();
    
    // Apply guest review score filter
    final guestReview = _filters['guestReviewScore'];
    if (guestReview != null) {
      filtered = filtered.where((hotel) {
        final rating = hotel.diemDanhGiaTrungBinh ?? 0;
        return rating >= guestReview;
      }).toList();
    }
    
    // Apply amenities filter (if needed in future)
    final amenities = _filters['amenities'] as Set<String>;
    // TODO: Implement amenities filter when backend supports it
    
    // Apply cancellation policy filter
    if (_filters['cancellationPolicy'] == true) {
      // TODO: Filter hotels with free cancellation when backend supports it
    }
    
    setState(() {
      _hotels = filtered;
    });
    _updateActiveFilterCount();
  }
  
  void _showFilterBottomSheet() {
    // Calculate max price from all hotels
    double maxPrice = 40000000;
    if (_allHotels.isNotEmpty) {
      final prices = _allHotels.map((h) => h.giaTb ?? 0).where((p) => p > 0).toList();
      if (prices.isNotEmpty) {
        maxPrice = prices.reduce((a, b) => a > b ? a : b).toDouble();
      }
      // Ensure min maxPrice
      if (maxPrice < 1000000) maxPrice = 40000000;
    }
    
    // Clamp existing priceRange to new maxPrice if needed
    final currentPriceRange = _filters['priceRange'] as RangeValues;
    if (currentPriceRange.end > maxPrice) {
      _filters['priceRange'] = RangeValues(
        currentPriceRange.start.clamp(0.0, maxPrice),
        maxPrice,
      );
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EnhancedFilterBottomSheet(
        filters: _filters,
        maxPrice: maxPrice,
        totalResults: _allHotels.length,
        onFiltersChanged: (newFilters) {
          setState(() {
            _filters = newFilters;
            _applyFilters();
          });
        },
      ),
    );
  }

  Future<void> _viewHotelRooms(Hotel hotel) async {
    try {
      // Navigate to PropertyDetailScreen với dates hiện tại
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PropertyDetailScreen(
              hotel: hotel,
              checkInDate: _checkInDate,
              checkOutDate: _checkOutDate,
              guestCount: widget.guestCount,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi mở trang đặt phòng: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getAppBarTitle() {
    if (widget.title != null) {
      return widget.title!;
    }
    if (widget.location.contains('đánh giá cao') ||
        widget.location.contains('Đánh giá cao')) {
      return 'Khách sạn đánh giá cao';
    } else if (widget.location.contains('Gần bạn') ||
        widget.location.contains('gần đây')) {
      return 'Khách sạn gần đây';
    } else if (widget.location == 'Tất cả khách sạn') {
      return 'Tất cả khách sạn';
    } else {
      return 'Khách sạn tại ${widget.location}';
    }
  }

  /// Edit location - Show dialog to input new location
  void _editLocation() {
    final TextEditingController controller = TextEditingController(text: widget.location);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.location_on, color: Color(0xFF1E88E5)),
            SizedBox(width: 8),
            Text('Thay đổi địa điểm'),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Nhập tên địa điểm',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (controller.text.isNotEmpty && controller.text != widget.location) {
                // Navigate to new search with updated location
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HotelListScreen(
                      location: controller.text,
                      checkInDate: widget.checkInDate,
                      checkOutDate: widget.checkOutDate,
                      guestCount: widget.guestCount,
                      roomCount: widget.roomCount,
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Tìm kiếm'),
          ),
        ],
      ),
    );
  }

  /// Edit dates - Show date range picker
  void _editDates() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _checkInDate, end: _checkOutDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1E88E5),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _checkInDate = picked.start;
        _checkOutDate = picked.end;
      });
      
      // Cập nhật dates khi navigate đến hotel detail
      // Dates sẽ được truyền qua khi user click vào hotel card
    }
  }

  /// Edit guests and rooms - Show dialog with counter
  void _editGuests() {
    int tempGuestCount = widget.guestCount;
    int tempRoomCount = widget.roomCount;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.people, color: Color(0xFF1E88E5)),
              SizedBox(width: 8),
              Text('Số khách & phòng'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Guest count
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Số khách', style: TextStyle(fontSize: 16)),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (tempGuestCount > 1) {
                            setDialogState(() => tempGuestCount--);
                          }
                        },
                        icon: const Icon(Icons.remove_circle_outline),
                        color: const Color(0xFF1E88E5),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$tempGuestCount',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          if (tempGuestCount < 10) {
                            setDialogState(() => tempGuestCount++);
                          }
                        },
                        icon: const Icon(Icons.add_circle_outline),
                        color: const Color(0xFF1E88E5),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Room count
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Số phòng', style: TextStyle(fontSize: 16)),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (tempRoomCount > 1) {
                            setDialogState(() => tempRoomCount--);
                          }
                        },
                        icon: const Icon(Icons.remove_circle_outline),
                        color: const Color(0xFF1E88E5),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$tempRoomCount',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          if (tempRoomCount < 5) {
                            setDialogState(() => tempRoomCount++);
                          }
                        },
                        icon: const Icon(Icons.add_circle_outline),
                        color: const Color(0xFF1E88E5),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (tempGuestCount != widget.guestCount || tempRoomCount != widget.roomCount) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HotelListScreen(
                        location: widget.location,
                        checkInDate: widget.checkInDate,
                        checkOutDate: widget.checkOutDate,
                        guestCount: tempGuestCount,
                        roomCount: tempRoomCount,
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Áp dụng'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _getAppBarTitle(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Filter button với badge hiển thị số lượng filter đang active
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.tune),
                tooltip: 'Bộ lọc',
                onPressed: _showFilterBottomSheet,
              ),
              if (_activeFilterCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_activeFilterCount',
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
      body: Column(
        children: [
          // Search Info Header with Gradient
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Location - Editable
                      InkWell(
                        onTap: _editLocation,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  widget.location,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.edit,
                                color: Colors.white.withOpacity(0.7),
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Dates and Guests
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          // Check-in/Check-out dates - LUÔN HIỂN THỊ
                          Expanded(
                            child: InkWell(
                              onTap: _editDates,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.calendar_today, color: Colors.white, size: 14),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '${DateFormat('dd/MM').format(_checkInDate)} - ${DateFormat('dd/MM').format(_checkOutDate)}',
                                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            '${_checkOutDate.difference(_checkInDate).inDays} đêm',
                                            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.edit, color: Colors.white.withOpacity(0.7), size: 14),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: _editGuests,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.people, color: Colors.white, size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${widget.guestCount}K • ${widget.roomCount}P',
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.edit, color: Colors.white.withOpacity(0.7), size: 14),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Results count
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isLoading ? 'Đang tìm kiếm...' : 'Tìm thấy ${_hotels.length} khách sạn',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_activeFilterCount > 0 && !_isLoading) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.filter_alt, size: 12, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                '$_activeFilterCount bộ lọc',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Hotels List
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: Color(0xFF1E88E5)),
                        const SizedBox(height: 16),
                        Text(
                          'Đang tìm kiếm khách sạn...',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : _error != null
                ? _buildErrorState()
                : _hotels.isEmpty
                ? _buildEmptyState()
                : _buildHotelsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline, 
                size: 64, 
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Đã xảy ra lỗi',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Không thể tải dữ liệu',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadHotels,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.hotel_outlined, 
                size: 64, 
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Không tìm thấy khách sạn',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hiện chưa có khách sạn nào tại ${widget.location}',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Vui lòng thử tìm kiếm địa điểm khác',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Quay lại'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1E88E5),
                    side: const BorderSide(color: Color(0xFF1E88E5)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _loadHotels,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Thử lại'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHotelsList() {
    return RefreshIndicator(
      onRefresh: _loadHotels,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _hotels.length,
        itemBuilder: (context, index) {
          final hotel = _hotels[index];
          return _buildHotelCard(hotel);
        },
      ),
    );
  }

  Widget _buildHotelCard(Hotel hotel) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: HotelCardWithFavorite(
        hotel: hotel,
        width: double.infinity,
        height: 280,
        onTap: () => _viewHotelRooms(hotel),
      ),
    );
  }
}
