import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:hotel_mobile/data/models/hotel.dart';
import 'package:hotel_mobile/data/models/room.dart';
import 'package:hotel_mobile/data/services/api_service.dart';
import 'package:hotel_mobile/data/services/applied_promotion_service.dart';
import 'package:hotel_mobile/core/utils/image_url_helper.dart';
import 'package:hotel_mobile/presentation/widgets/property_image_gallery.dart';
import 'package:hotel_mobile/presentation/widgets/property_info_section.dart';
import 'package:hotel_mobile/presentation/widgets/amenities_section.dart';
import 'package:hotel_mobile/presentation/widgets/room_selection_section.dart';
import 'package:hotel_mobile/presentation/widgets/bottom_cta_bar.dart';
import 'package:hotel_mobile/presentation/widgets/hotel_action_buttons.dart';
import 'package:hotel_mobile/presentation/widgets/reviews_section.dart';
import 'package:hotel_mobile/presentation/screens/payment/payment_screen.dart';
import 'package:hotel_mobile/core/widgets/glass_card.dart';
import 'package:hotel_mobile/presentation/screens/map/map_view_screen.dart';
import 'package:hotel_mobile/presentation/screens/map/map_view_screen_simple.dart';
import 'package:hotel_mobile/presentation/screens/service/amenity_detail_screen.dart';
import 'package:hotel_mobile/data/models/amenity.dart';
import 'package:hotel_mobile/data/services/booking_history_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/skeleton_loading_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../l10n/app_localizations.dart';

/// Màn hình chi tiết khách sạn - Thiết kế theo phong cách Agoda
/// Gồm 9 phần chính:
/// 1. Header: slideshow ảnh, tên khách sạn, điểm đánh giá, vị trí
/// 2. Điểm nổi bật: gần trung tâm, hồ bơi, dịch vụ tốt
/// 3. Mô tả tổng quan: giới thiệu chi tiết về khách sạn
/// 4. Thông tin hữu ích: giờ nhận/trả phòng, chính sách hủy, khoảng cách
/// 5. Chính sách lưu trú: vật nuôi, trẻ em, thanh toán
/// 6. Danh sách phòng: ảnh, tiện nghi, giá, nút "Đặt ngay"
/// 7. Đánh giá khách hàng: điểm trung bình và nhận xét
/// 8. Vị trí bản đồ: Google Maps
/// 9. Gợi ý khách sạn tương tự
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

class _PropertyDetailScreenState extends State<PropertyDetailScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final ApiService _apiService = ApiService();
  final AppliedPromotionService _promotionService = AppliedPromotionService();
  final BookingHistoryService _bookingService = BookingHistoryService();
  
  List<Room> _rooms = [];
  bool _isLoadingRooms = true;
  double? _lowestPrice;
  double? _originalLowestPrice; // Lưu giá gốc để hiển thị
  int _selectedPriceOption = 0;
  double _selectedPrice = 0;
  
  late DateTime _checkInDate;
  late DateTime _checkOutDate;
  
  // Similar hotels
  List<Hotel> _similarHotels = [];
  bool _isLoadingSimilarHotels = false;
  
  // Amenities
  List<Amenity> _amenities = [];
  bool _isLoadingAmenities = false;
  
  // Booking active check
  bool _canBook = true;
  bool _isCheckingBooking = false;
  String? _bookingBlockMessage;
  bool _requiresOnlinePayment = false; // Yêu cầu thanh toán online (VNPay/Bank Transfer)
  int _minPaymentPercentage = 0; // Tối thiểu % thanh toán
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _checkInDate = widget.checkInDate ?? DateTime.now().add(const Duration(days: 1));
    _checkOutDate = widget.checkOutDate ?? DateTime.now().add(const Duration(days: 2));
    
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
    
    _fadeController.forward();
    _slideController.forward();
    
    _loadRooms();
    _loadSimilarHotels();
    _loadAmenities();
    _checkActiveBooking();
  }

  /// Kiểm tra xem user có booking active ở khách sạn khác không
  Future<void> _checkActiveBooking() async {
    try {
      setState(() {
        _isCheckingBooking = true;
      });

      print('🔍 Checking active booking for hotel: ${widget.hotel.id} (${widget.hotel.ten})');
      
      final result = await _bookingService.checkActiveBooking(
        hotelId: widget.hotel.id,
      );

      print('🔍 Check active booking result:');
      print('   - canBook: ${result['canBook']}');
      print('   - hasOtherHotelBooking: ${result['hasOtherHotelBooking']}');
      print('   - hasSameHotelBooking: ${result['hasSameHotelBooking']}');
      print('   - requiresOnlinePayment: ${result['requiresOnlinePayment']}');
      print('   - minPaymentPercentage: ${result['minPaymentPercentage']}');
      print('   - message: ${result['message']}');

      setState(() {
        _canBook = result['canBook'] ?? true;
        _bookingBlockMessage = result['message'];
        _requiresOnlinePayment = result['requiresOnlinePayment'] ?? false;
        _minPaymentPercentage = result['minPaymentPercentage'] ?? 0;
        _isCheckingBooking = false;
      });
      
      print('✅ Updated state: canBook=$_canBook, requiresOnlinePayment=$_requiresOnlinePayment, minPaymentPercentage=$_minPaymentPercentage');
    } catch (e) {
      print('⚠️ Error checking active booking: $e');
      // Fail-safe: cho phép đặt phòng nếu có lỗi
      setState(() {
        _canBook = true;
        _requiresOnlinePayment = false;
        _minPaymentPercentage = 0;
        _isCheckingBooking = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadRooms() async {
    try {
      setState(() => _isLoadingRooms = true);

      final availableFrom = DateFormat('yyyy-MM-dd').format(_checkInDate);
      final availableTo = DateFormat('yyyy-MM-dd').format(_checkOutDate);

      final response = await _apiService.getHotelRooms(
        widget.hotel.id ?? 0,
        availableFrom: availableFrom,
        availableTo: availableTo,
      );

      if (response.success && response.data != null && response.data!.isNotEmpty) {
        final processedRooms = response.data!.map((room) {
          List<String>? processedImages;
          if (room.hinhAnhPhong != null && room.hinhAnhPhong!.isNotEmpty) {
            processedImages = room.hinhAnhPhong!.map((imagePath) {
              if (imagePath.startsWith('http')) {
                return imagePath;
              }
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
        
        final prices = processedRooms
            .where((room) => room.giaPhong != null && room.giaPhong! > 0)
            .map((room) => room.giaPhong!)
            .toList();
        
        if (prices.isNotEmpty) {
          _originalLowestPrice = prices.reduce((a, b) => a < b ? a : b);
          // Áp dụng promotion nếu có
          _lowestPrice = _promotionService.calculateDiscountedPrice(
            _originalLowestPrice!,
            hotelId: widget.hotel.id,
          );
        } else {
          _lowestPrice = null;
          _originalLowestPrice = null;
        }
      } else {
        _rooms = [];
        _lowestPrice = null;
      }

      setState(() => _isLoadingRooms = false);
    } catch (e) {
      setState(() {
        _isLoadingRooms = false;
        _rooms = [];
        _lowestPrice = null;
      });
    }
  }

  Future<void> _loadAmenities() async {
    try {
      setState(() => _isLoadingAmenities = true);
      
      final response = await _apiService.getHotelAmenities(widget.hotel.id ?? 0);
      
      if (response.success && response.data != null) {
        _amenities = response.data!;
      } else {
        _amenities = [];
      }
      
      setState(() => _isLoadingAmenities = false);
    } catch (e) {
      print('❌ Error loading amenities: $e');
      setState(() {
        _isLoadingAmenities = false;
        _amenities = [];
      });
    }
  }

  Future<void> _loadSimilarHotels() async {
    try {
      setState(() => _isLoadingSimilarHotels = true);
      
      // Xác định địa điểm để tìm kiếm
      // Ưu tiên: tenViTri (quận/huyện) > tenTinhThanh (tỉnh/thành) > diaChi
      String? searchLocation;
      if (widget.hotel.tenViTri != null && widget.hotel.tenViTri!.isNotEmpty) {
        searchLocation = widget.hotel.tenViTri;
      } else if (widget.hotel.tenTinhThanh != null && widget.hotel.tenTinhThanh!.isNotEmpty) {
        searchLocation = widget.hotel.tenTinhThanh;
      } else if (widget.hotel.diaChi != null && widget.hotel.diaChi!.isNotEmpty) {
        // Lấy phần địa chỉ chính (quận/huyện hoặc tỉnh/thành từ địa chỉ)
        final addressParts = widget.hotel.diaChi!.split(',');
        if (addressParts.length >= 2) {
          searchLocation = addressParts[addressParts.length - 2].trim(); // Lấy phần gần cuối
        } else {
          searchLocation = widget.hotel.diaChi;
        }
      }
      
      print('🔍 Loading similar hotels for location: $searchLocation');
      
      if (searchLocation != null && searchLocation.isNotEmpty) {
        // Thử tìm theo search parameter (tìm trong tên, địa chỉ, vị trí)
        final response = await _apiService.getHotels(
          limit: 20, // Lấy nhiều hơn để có đủ sau khi filter
          search: searchLocation,
        );
        
        print('📊 Similar hotels API response: success=${response.success}, count=${response.data?.length ?? 0}');
        
        if (response.success && response.data != null && response.data!.isNotEmpty) {
          // Lọc khách sạn cùng địa điểm và loại bỏ khách sạn hiện tại
          _similarHotels = response.data!
              .where((h) {
                // Loại bỏ khách sạn hiện tại
                if (h.id == widget.hotel.id) return false;
                
                // Kiểm tra cùng địa điểm: so sánh tenViTri hoặc tenTinhThanh
                final sameLocation = 
                    (widget.hotel.tenViTri != null && h.tenViTri != null && 
                     widget.hotel.tenViTri == h.tenViTri) ||
                    (widget.hotel.tenTinhThanh != null && h.tenTinhThanh != null && 
                     widget.hotel.tenTinhThanh == h.tenTinhThanh);
                
                return sameLocation;
              })
              .take(4)
              .toList();
          
          print('✅ Found ${_similarHotels.length} similar hotels');
        } else {
          // Fallback: Nếu không tìm thấy theo địa điểm, lấy tất cả và filter sau
          print('⚠️ No hotels found with search, trying fallback...');
          final fallbackResponse = await _apiService.getHotels(limit: 20);
          
          if (fallbackResponse.success && fallbackResponse.data != null) {
            _similarHotels = fallbackResponse.data!
                .where((h) => h.id != widget.hotel.id)
                .take(4)
                .toList();
            print('✅ Fallback: Found ${_similarHotels.length} hotels');
          }
        }
      } else {
        // Nếu không có địa điểm, lấy tất cả và loại bỏ khách sạn hiện tại
        print('⚠️ No location info, loading all hotels...');
        final response = await _apiService.getHotels(limit: 20);
        
        if (response.success && response.data != null) {
          _similarHotels = response.data!
              .where((h) => h.id != widget.hotel.id)
              .take(4)
              .toList();
          print('✅ Found ${_similarHotels.length} hotels (no location filter)');
        }
      }
      
      setState(() => _isLoadingSimilarHotels = false);
    } catch (e) {
      print('❌ Error loading similar hotels: $e');
      setState(() => _isLoadingSimilarHotels = false);
    }
  }

  void _showMapView() async {
    try {
      // Build search query từ địa chỉ khách sạn
      String searchQuery = widget.hotel.ten;
      List<String> addressParts = [];
      
      if (widget.hotel.diaChi != null && widget.hotel.diaChi!.isNotEmpty) {
        addressParts.add(widget.hotel.diaChi!);
      }
      if (widget.hotel.tenViTri != null && widget.hotel.tenViTri!.isNotEmpty) {
        addressParts.add(widget.hotel.tenViTri!);
      }
      if (widget.hotel.tenTinhThanh != null && widget.hotel.tenTinhThanh!.isNotEmpty) {
        addressParts.add(widget.hotel.tenTinhThanh!);
      }
      if (widget.hotel.tenQuocGia != null && widget.hotel.tenQuocGia!.isNotEmpty) {
        addressParts.add(widget.hotel.tenQuocGia!);
      }
      
      if (addressParts.isNotEmpty) {
        searchQuery += ', ${addressParts.join(', ')}';
      }
      
      if (searchQuery.isEmpty || searchQuery == widget.hotel.ten) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.noAddressForMap),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Encode query để dùng trong URL
      final encodedQuery = Uri.encodeComponent(searchQuery);
      
      // Tạo URI cho Google Maps
      final geoUri = Uri.parse('geo:0,0?q=$encodedQuery');
      final webUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedQuery');

      bool launched = false;

      // Thử mở ứng dụng Google Maps (nếu có)
      try {
        if (await canLaunchUrl(geoUri)) {
          launched = await launchUrl(geoUri, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        print('⚠️ Cannot launch geo URI: $e');
      }

      // Nếu không mở được app, thử mở trình duyệt web
      if (!launched) {
        try {
          if (await canLaunchUrl(webUri)) {
            launched = await launchUrl(webUri, mode: LaunchMode.externalApplication);
          }
        } catch (e) {
          print('⚠️ Cannot launch web URI: $e');
        }
      }

      if (!launched) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.cannotOpenGoogleMaps),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Error opening Google Maps: $e');
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.mapError}: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Lấy giá sau khi áp dụng promotion
  double _getPriceWithPromotion(double originalPrice, Room room) {
    return _promotionService.calculateDiscountedPrice(
      originalPrice,
      hotelId: room.khachSanId ?? widget.hotel.id,
    );
  }

  void _onRoomSelected(Room room) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildRoomOptionsBottomSheet(room),
    );
  }

  void _navigateToPayment(Room room, double selectedPrice, {int roomCount = 1}) {
    // ✅ Kiểm tra xem có thể đặt phòng không
    if (!_canBook) {
      _showBookingBlockedDialog();
      return;
    }

    final nights = _checkOutDate.difference(_checkInDate).inDays;
    
    // ✅ Reload room availability sau khi quay lại từ payment screen
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
          roomPrice: selectedPrice,
          roomCount: roomCount,
          requiresOnlinePayment: _requiresOnlinePayment, // ✅ Truyền yêu cầu thanh toán online
          minPaymentPercentage: _minPaymentPercentage, // ✅ Truyền % thanh toán tối thiểu
        ),
      ),
    ).then((_) {
      // Reload room availability sau khi quay lại (có thể đã đặt phòng thành công)
      print('🔄 Reloading room availability after returning from payment...');
      _loadRooms();
      _checkActiveBooking(); // Kiểm tra lại booking active
    });
  }

  /// Hiển thị dialog thông báo không được đặt phòng
  void _showBookingBlockedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.orange),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context)!.cannotBookRoom),
          ],
        ),
        content: Text(_bookingBlockMessage ?? 'Bạn đang có đặt phòng tại khách sạn khác. Vui lòng đợi đến sau ngày checkout để đặt khách sạn khác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.understood),
          ),
        ],
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
              primary: Color(0xFF003580),
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
      _loadRooms();
    }
  }

  Widget _buildDateInfo(String label, String date, IconData icon, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF999999),
                    fontWeight: FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            date,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
              letterSpacing: -0.3,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildRoomOptionsBottomSheet(Room room) {
    if (_selectedPrice == 0) {
      _selectedPrice = room.giaPhong ?? 0;
    }
    
    return StatefulBuilder(
      builder: (context, setModalState) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                    _getPriceWithPromotion(room.giaPhong ?? 0, room),
                    'Giá tốt nhất • Không thể hủy',
                    false,
                    0,
                    setModalState,
                  ),
                  const SizedBox(height: 12),
                  _buildPriceOption(
                    'Kèm bữa sáng',
                    (room.giaPhong ?? 0) + 200000,
                    _getPriceWithPromotion((room.giaPhong ?? 0) + 200000, room),
                    'Hủy miễn phí • Bao gồm bữa sáng',
                    true,
                    1,
                    setModalState,
                  ),
                  const SizedBox(height: 24),
                  // ✅ Ẩn nút đặt phòng nếu có booking active ở khách sạn khác
                  if (!_canBook) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _bookingBlockMessage ?? 'Bạn đang có đặt phòng tại khách sạn khác. Vui lòng đợi đến sau ngày checkout để đặt khách sạn khác.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.orange[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (_requiresOnlinePayment) ...[
                    // ✅ Hiển thị thông báo khi đặt thêm phòng ở cùng khách sạn
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _minPaymentPercentage > 0
                                  ? 'Bạn đang có đặt phòng tại khách sạn này. Để đặt thêm phòng, vui lòng sử dụng thanh toán VNPay hoặc chuyển khoản ngân hàng (tối thiểu $_minPaymentPercentage% tổng giá trị).'
                                  : 'Bạn đang có đặt phòng tại khách sạn này. Để đặt thêm phòng, vui lòng sử dụng thanh toán VNPay hoặc chuyển khoản ngân hàng.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _navigateToPayment(room, _selectedPrice);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF003580),
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
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _navigateToPayment(room, _selectedPrice);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF003580),
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
                  ],
                  SizedBox(height: MediaQuery.of(context).padding.bottom),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPriceOption(
    String title,
    double originalPrice,
    double discountedPrice,
    String description,
    bool recommended,
    int optionIndex,
    StateSetter setModalState,
  ) {
    final isSelected = _selectedPriceOption == optionIndex;
    final promotion = _promotionService.getAppliedPromotion(hotelId: widget.hotel.id);
    final hasPromotion = promotion != null && discountedPrice < originalPrice;
    
    return GestureDetector(
      onTap: () {
        setModalState(() {
          _selectedPriceOption = optionIndex;
          _selectedPrice = discountedPrice;
        });
      },
      child: GlassCard(
        blur: 15,
        opacity: isSelected ? 0.3 : 0.2,
        borderRadius: 16,
        borderColor: isSelected 
            ? const Color(0xFF003580)
            : (recommended ? Colors.orange : Colors.grey[300]),
        borderWidth: isSelected ? 2 : (recommended ? 2 : 1),
        padding: EdgeInsets.zero,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isSelected ? const Color(0xFF003580).withValues(alpha: 0.05) : Colors.transparent,
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
                      color: const Color(0xFF003580),
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
                if (hasPromotion) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.green[300]!),
                    ),
                    child: Text(
                      '-${promotion!.phanTramGiam.toInt()}%',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasPromotion) ...[
                          Text(
                            '${_formatPrice(originalPrice)}/đêm',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(height: 2),
                        ],
                        Text(
                          '${_formatPrice(discountedPrice)}/đêm',
                          style: const TextStyle(
                            color: Color(0xFF003580),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF003580),
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
      ),
    );
  }

  String _formatPrice(double price) {
    // ✅ Sử dụng CurrencyFormatter để format theo currency đã chọn
    return CurrencyFormatter.format(price);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              /// ============================================
              /// PHẦN 1: HEADER - AppBar + Image Gallery
              /// ============================================
              SliverAppBar(
                expandedHeight: 0,
                floating: true,
                pinned: true,
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1A1A1A),
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                  onPressed: () => Navigator.pop(context),
                  color: const Color(0xFF1A1A1A),
                ),
                actions: [
                  ShareHotelButton(hotel: widget.hotel, compact: true),
                  SaveHotelButton(hotel: widget.hotel, compact: true),
                  const SizedBox(width: 8),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(
                    height: 1,
                    color: const Color(0xFFE8E8E8),
                  ),
                ),
              ),

              /// Image Gallery với Header Info
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    PropertyImageGallery(hotel: widget.hotel),
                    // Header info overlay
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.7),
                            ],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.hotel.ten,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                if (widget.hotel.diemDanhGiaTrungBinh != null) ...[
                                  Icon(Icons.star, color: Colors.amber, size: 18),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${widget.hotel.diemDanhGiaTrungBinh!.toStringAsFixed(1)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Expanded(
                                  child: Text(
                                    widget.hotel.tenViTri ?? widget.hotel.diaChi ?? '',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              /// ============================================
              /// PHẦN 2: ĐIỂM NỔI BẬT - DỊCH VỤ
              /// ============================================
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE8E8E8)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dịch vụ & Tiện ích',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _isLoadingAmenities
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(20),
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF003580),
                                    ),
                                  ),
                                )
                              : _amenities.isEmpty
                                  ? _buildDefaultAmenities()
                                  : Wrap(
                                      spacing: 12,
                                      runSpacing: 12,
                                      children: _amenities.map((amenity) {
                                        return _buildAmenityChip(amenity);
                                      }).toList(),
                                    ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              /// ============================================
              /// PHẦN 3: MÔ TẢ TỔNG QUAN
              /// ============================================
              if (widget.hotel.moTa != null && widget.hotel.moTa!.isNotEmpty)
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE8E8E8)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Mô tả tổng quan',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              widget.hotel.moTa!,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Color(0xFF666666),
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              /// ============================================
              /// PHẦN 4: THÔNG TIN HỮU ÍCH
              /// ============================================
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE8E8E8)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Thông tin hữu ích',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            Icons.login,
                            'Giờ nhận phòng',
                            widget.hotel.gioNhanPhong ?? '14:00',
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            Icons.logout,
                            'Giờ trả phòng',
                            widget.hotel.gioTraPhong ?? '12:00',
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            Icons.cancel_outlined,
                            'Chính sách hủy',
                            widget.hotel.chinhSachHuy ?? 'Hủy miễn phí trước 24h',
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            Icons.location_on,
                            'Khoảng cách',
                            'Cách trung tâm 2.5 km',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              /// ============================================
              /// PHẦN 5: CHÍNH SÁCH LƯU TRÚ
              /// ============================================
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE8E8E8)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Chính sách lưu trú',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildPolicyRow(Icons.pets, 'Vật nuôi', 'Không cho phép'),
                          const SizedBox(height: 12),
                          _buildPolicyRow(Icons.child_care, 'Trẻ em', 'Miễn phí cho trẻ dưới 5 tuổi'),
                          const SizedBox(height: 12),
                          _buildPolicyRow(Icons.payment, 'Thanh toán', 'Chấp nhận thẻ tín dụng và tiền mặt'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              /// ============================================
              /// PHẦN 6: DANH SÁCH PHÒNG
              /// ============================================
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
                        : Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Chọn phòng',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                RoomSelectionSection(
                                  rooms: _rooms,
                                  onRoomSelected: _onRoomSelected,
                                  checkInDate: _checkInDate,
                                  checkOutDate: _checkOutDate,
                                  guestCount: widget.guestCount,
                                ),
                              ],
                            ),
                          ),
              ),

              /// ============================================
              /// PHẦN 7: ĐÁNH GIÁ KHÁCH HÀNG
              /// ============================================
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE8E8E8)),
                  ),
                  child: ReviewsSection(
                    hotelId: widget.hotel.id ?? 0,
                    onReviewAdded: () {},
                  ),
                ),
              ),

              /// ============================================
              /// PHẦN 8: VỊ TRÍ BẢN ĐỒ
              /// ============================================
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE8E8E8)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Vị trí',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.hotel.diaChi ?? widget.hotel.tenViTri ?? '',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF666666),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Nút "Xem bản đồ" thay vì hiển thị map trực tiếp
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _showMapView,
                            icon: const Icon(
                              Icons.map_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                            label: const Text(
                              'Xem bản đồ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF003580),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              /// ============================================
              /// PHẦN 9: GỢI Ý KHÁCH SẠN TƯƠNG TỰ
              /// ============================================
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Khách sạn tương tự',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          if (widget.hotel.tenViTri != null || widget.hotel.tenTinhThanh != null)
                            Text(
                              'Tại ${widget.hotel.tenViTri ?? widget.hotel.tenTinhThanh}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF666666),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Hiển thị loading hoặc danh sách
                      _isLoadingSimilarHotels
                          ? const SizedBox(
                              height: 280,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF003580),
                                ),
                              ),
                            )
                          : _similarHotels.isEmpty
                              ? Container(
                                  height: 100,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE8E8E8)),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'Không có khách sạn tương tự',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF999999),
                                      ),
                                    ),
                                  ),
                                )
                              : SizedBox(
                                  height: 280,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _similarHotels.length,
                                    itemBuilder: (context, index) {
                                      final hotel = _similarHotels[index];
                                      return Container(
                                        width: 220,
                                        margin: const EdgeInsets.only(right: 16),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: const Color(0xFFE8E8E8)),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.04),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: InkWell(
                                          onTap: () {
                                            // Navigate đến màn hình chi tiết khách sạn tương tự
                                            // Giữ nguyên dates và guest count
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
                                          },
                                          borderRadius: BorderRadius.circular(16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Hình ảnh khách sạn
                                              ClipRRect(
                                                borderRadius: const BorderRadius.vertical(
                                                  top: Radius.circular(16),
                                                ),
                                                child: Stack(
                                                  children: [
                                                    Image.network(
                                                      hotel.fullImageUrl,
                                                      height: 140,
                                                      width: double.infinity,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) {
                                                        return Container(
                                                          height: 140,
                                                          color: Colors.grey[300],
                                                          child: const Icon(Icons.hotel, size: 40),
                                                        );
                                                      },
                                                    ),
                                                    // Badge số sao (nếu có)
                                                    if (hotel.soSao != null && hotel.soSao! > 0)
                                                      Positioned(
                                                        top: 8,
                                                        left: 8,
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFFFFB800),
                                                            borderRadius: BorderRadius.circular(6),
                                                          ),
                                                          child: Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              const Icon(Icons.star, color: Colors.white, size: 14),
                                                              const SizedBox(width: 4),
                                                              Text(
                                                                '${hotel.soSao}',
                                                                style: const TextStyle(
                                                                  color: Colors.white,
                                                                  fontSize: 12,
                                                                  fontWeight: FontWeight.w700,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              // Thông tin khách sạn
                                              Expanded(
                                                child: Padding(
                                                  padding: const EdgeInsets.all(12),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      // Tên khách sạn
                                                      Text(
                                                        hotel.ten,
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.w600,
                                                          color: Color(0xFF1A1A1A),
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      const SizedBox(height: 8),
                                                      // Rating
                                                      if (hotel.diemDanhGiaTrungBinh != null)
                                                        Row(
                                                          children: [
                                                            const Icon(Icons.star, color: Colors.amber, size: 16),
                                                            const SizedBox(width: 4),
                                                            Text(
                                                              hotel.diemDanhGiaTrungBinh!.toStringAsFixed(1),
                                                              style: const TextStyle(
                                                                fontSize: 14,
                                                                fontWeight: FontWeight.w600,
                                                                color: Color(0xFF1A1A1A),
                                                              ),
                                                            ),
                                                            if (hotel.soLuotDanhGia != null && hotel.soLuotDanhGia! > 0) ...[
                                                              const SizedBox(width: 4),
                                                              Text(
                                                                '(${hotel.soLuotDanhGia})',
                                                                style: const TextStyle(
                                                                  fontSize: 12,
                                                                  color: Color(0xFF666666),
                                                                ),
                                                              ),
                                                            ],
                                                          ],
                                                        ),
                                                      const Spacer(),
                                                      // Giá
                                                      if (hotel.giaTb != null)
                                                        Text(
                                                          'Từ ${_formatPrice(hotel.giaTb!)}/đêm',
                                                          style: const TextStyle(
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.w700,
                                                            color: Color(0xFF003580),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),

          /// ============================================
          /// STICKY BUTTON "ĐẶT NGAY"
          /// ============================================
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    if (_lowestPrice != null) ...[
                      _buildBottomPriceDisplay(),
                      const SizedBox(width: 16),
                    ],
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_rooms.isNotEmpty) {
                            _onRoomSelected(_rooms.first);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF003580),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Đặt ngay',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenityChip(Amenity amenity) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AmenityDetailScreen(
              amenity: amenity,
              hotelName: widget.hotel.ten ?? 'Khách sạn',
              hotelId: widget.hotel.id,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: amenity.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: amenity.color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(amenity.icon, size: 18, color: amenity.color),
            const SizedBox(width: 8),
            Text(
              amenity.ten,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1A1A),
              ),
            ),
            if (amenity.mienPhi) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.green[300]!),
                ),
                child: const Text(
                  'Miễn phí',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAmenities() {
    // Fallback amenities nếu không có dữ liệu từ API
    final defaultAmenities = [
      {'icon': Icons.location_city, 'label': 'Gần trung tâm'},
      {'icon': Icons.pool, 'label': 'Hồ bơi'},
      {'icon': Icons.spa, 'label': 'Spa'},
      {'icon': Icons.wifi, 'label': 'WiFi miễn phí'},
      {'icon': Icons.restaurant, 'label': 'Nhà hàng'},
      {'icon': Icons.local_parking, 'label': 'Bãi đỗ xe'},
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: defaultAmenities.map((item) {
        // Tạo Amenity object từ default data
        final amenity = Amenity(
          id: 0,
          ten: item['label'] as String,
          mienPhi: true,
        );
        
        return GestureDetector(
          onTap: () {
            // Navigate to amenity detail screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AmenityDetailScreen(
                  amenity: amenity,
                  hotelName: widget.hotel.ten ?? 'Khách sạn',
                  hotelId: widget.hotel.id,
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item['icon'] as IconData, size: 18, color: const Color(0xFF003580)),
                const SizedBox(width: 8),
                Text(
                  item['label'] as String,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF003580)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF666666),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Hiển thị giá trong bottom bar với promotion
  Widget _buildBottomPriceDisplay() {
    final promotion = _promotionService.getAppliedPromotion(hotelId: widget.hotel.id);
    final hasPromotion = promotion != null && 
                        _originalLowestPrice != null && 
                        _lowestPrice != null &&
                        _lowestPrice! < _originalLowestPrice!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Giá từ',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF666666),
          ),
        ),
        if (hasPromotion) ...[
          // Giá gốc (gạch ngang)
          Text(
            '${_formatPrice(_originalLowestPrice!)}/đêm',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
              decoration: TextDecoration.lineThrough,
            ),
          ),
          const SizedBox(height: 2),
          // Giá đã giảm
          Row(
            children: [
              Text(
                '${_formatPrice(_lowestPrice!)}/đêm',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF003580),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.green[300]!),
                ),
                child: Text(
                  '-${promotion!.phanTramGiam.toInt()}%',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.green[700],
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          // Không có promotion
          Text(
            '${_formatPrice(_lowestPrice!)}/đêm',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF003580),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPolicyRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF003580)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF666666),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}