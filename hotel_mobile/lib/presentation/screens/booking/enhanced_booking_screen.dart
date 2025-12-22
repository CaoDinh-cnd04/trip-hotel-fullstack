import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/hotel.dart';
import '../../../data/models/room.dart';
import '../../../data/services/booking_service.dart';
import '../payment/payment_screen.dart';
import '../../widgets/improved_image_widget.dart';
import '../../widgets/room_availability_badge.dart';

class EnhancedBookingScreen extends StatefulWidget {
  final Hotel hotel;

  const EnhancedBookingScreen({
    super.key,
    required this.hotel,
  });

  @override
  State<EnhancedBookingScreen> createState() => _EnhancedBookingScreenState();
}

class _EnhancedBookingScreenState extends State<EnhancedBookingScreen> {
  final BookingService _bookingService = BookingService();
  List<Room> _availableRooms = [];
  Room? _selectedRoom;
  String _selectedPriceOption = 'standard';
  bool _isLoading = true;
  String? _error;
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  int _rooms = 1;
  int _adults = 2;
  int _children = 0;

  @override
  void initState() {
    super.initState();
    _checkInDate = DateTime.now().add(const Duration(days: 1));
    _checkOutDate = DateTime.now().add(const Duration(days: 2));
    _loadAvailableRooms();
  }

  Future<void> _loadAvailableRooms() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await _bookingService.getRooms(widget.hotel.id);
      
      if (response.success && response.data != null) {
        setState(() {
          _availableRooms = response.data!;
          if (_availableRooms.isNotEmpty) {
            _selectedRoom = _availableRooms.first;
          }
        });
      } else {
        // Fallback data
        _loadFallbackRooms();
      }
    } catch (e) {
      print('❌ Lỗi load rooms: $e');
      _loadFallbackRooms();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _loadFallbackRooms() {
    final basePrice = widget.hotel.giaTb ?? 500000;
    setState(() {
      _availableRooms = [
        Room(
          id: 1,
          soPhong: '101',
          loaiPhongId: 1,
          khachSanId: widget.hotel.id,
          tinhTrang: true,
          moTa: 'Phòng tiêu chuẩn với giường đôi, điều hòa, TV',
          tenLoaiPhong: 'Standard Room',
          giaPhong: basePrice,
          sucChua: 2,
          hinhAnhPhong: widget.hotel.hinhAnh != null ? [widget.hotel.hinhAnh!] : null,
          tenKhachSan: widget.hotel.ten,
          tienNghi: ['WiFi miễn phí', 'Điều hòa', 'TV', 'Bãi đỗ xe'],
          soGiuongDoi: 1,
          soGiuongDon: 0,
        ),
        Room(
          id: 2,
          soPhong: '102',
          loaiPhongId: 2,
          khachSanId: widget.hotel.id,
          tinhTrang: true,
          moTa: 'Phòng cao cấp với view biển, ban công riêng',
          tenLoaiPhong: 'Deluxe Room',
          giaPhong: basePrice * 1.5,
          sucChua: 3,
          hinhAnhPhong: widget.hotel.hinhAnh != null ? [widget.hotel.hinhAnh!] : null,
          tenKhachSan: widget.hotel.ten,
          tienNghi: ['WiFi miễn phí', 'Điều hòa', 'TV', 'Bãi đỗ xe', 'Ban công riêng', 'Minibar'],
          soGiuongDoi: 1,
          soGiuongDon: 1,
        ),
        Room(
          id: 3,
          soPhong: '103',
          loaiPhongId: 3,
          khachSanId: widget.hotel.id,
          tinhTrang: true,
          moTa: 'Suite sang trọng với phòng khách riêng',
          tenLoaiPhong: 'Suite Room',
          giaPhong: basePrice * 2,
          sucChua: 4,
          hinhAnhPhong: widget.hotel.hinhAnh != null ? [widget.hotel.hinhAnh!] : null,
          tenKhachSan: widget.hotel.ten,
          tienNghi: ['WiFi miễn phí', 'Điều hòa', 'TV', 'Bãi đỗ xe', 'Phòng khách riêng', 'Minibar', 'Spa', 'Hồ bơi'],
          soGiuongDoi: 2,
          soGiuongDon: 0,
        ),
      ];
      _selectedRoom = _availableRooms.first;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text('Lỗi: $_error'))
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        // Header
                        _buildHeader(),
                        
                        // Hotel Info Card
                        _buildHotelInfoCard(),
                        
                        // Room Selection
                        _buildRoomSelection(),
                        
                        // Payment Button
                        _buildPaymentButton(),
                        
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.black),
          ),
          
          const Spacer(),
          
          // Share button
          IconButton(
            onPressed: () {
              // TODO: Implement share functionality
            },
            icon: const Icon(Icons.share, color: Colors.black),
          ),
          
          // Favorite button
          IconButton(
            onPressed: () {
              // TODO: Implement favorite functionality
            },
            icon: const Icon(Icons.favorite_border, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildHotelInfoCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hotel Image
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: HotelImageWidget(
              imageUrl: widget.hotel.hinhAnh,
              width: double.infinity,
              height: 200,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Hotel Name
          Text(
            widget.hotel.ten,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Rating
          Row(
            children: [
              ...List.generate(5, (index) {
                return Icon(
                  index < (widget.hotel.soSao ?? 4)
                      ? Icons.star
                      : Icons.star_border,
                  color: Colors.amber,
                  size: 20,
                );
              }),
              const SizedBox(width: 8),
              Text(
                '${widget.hotel.soSao ?? 4} sao',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Review Score
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${widget.hotel.diemDanhGiaTrungBinh ?? 4.5}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          const SizedBox(height: 4),
          
          Text(
            'Trung bình (128 đánh giá)',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Location
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.grey[600], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.hotel.diaChi ?? 'Địa chỉ không xác định',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // View on Map Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openExternalMap(context),
              icon: const Icon(Icons.map, color: Colors.white),
              label: const Text(
                'Xem trên bản đồ',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Icon(
          Icons.image_not_supported,
          size: 48,
          color: Colors.grey,
        ),
      ),
    );
  }


  Widget _buildRoomSelection() {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text(
                'Lựa chọn phòng và giá',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${_checkOutDate!.difference(_checkInDate!).inDays} đêm',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        
        // Room List
        ..._availableRooms.map((room) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildRoomCard(room),
        )).toList(),
        
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildPaymentButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Selected Room Summary
          if (_selectedRoom != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Phòng đã chọn: ${_selectedRoom!.tenLoaiPhong ?? 'Standard Room'}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Giá cơ bản: ${(_selectedRoom!.giaPhong?.isFinite == true ? _selectedRoom!.giaPhong! : 500000).toStringAsFixed(0)} ₫/đêm',
                        style: const TextStyle(fontSize: 14),
                      ),
                      if (_selectedPriceOption == 'breakfast')
                        Text(
                          '+ Bữa sáng: ${((_selectedRoom!.giaPhong?.isFinite == true ? _selectedRoom!.giaPhong! : 500000) * 0.2).toStringAsFixed(0)} ₫/đêm',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tổng: ${_getFinalPrice().toStringAsFixed(0)} ₫/đêm',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Payment Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedRoom != null ? _navigateToPayment : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedRoom != null ? Colors.blue : Colors.grey,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                _selectedRoom != null 
                    ? 'Tiếp tục thanh toán - ${_getFinalPrice().toStringAsFixed(0)} ₫/đêm'
                    : 'Vui lòng chọn phòng',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getFinalPrice() {
    if (_selectedRoom == null) return 0;
    
    double basePrice = (_selectedRoom!.giaPhong?.isFinite == true) ? _selectedRoom!.giaPhong! : 500000;
    if (_selectedPriceOption == 'breakfast') {
      return basePrice * 1.2; // 20% more for breakfast
    }
    return basePrice;
  }

  Widget _buildRoomCard(Room room) {
    final isSelected = _selectedRoom?.id == room.id;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRoom = room;
          _selectedPriceOption = 'standard'; // Reset to standard option
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      child: Column(
        children: [
          // Room Image
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: RoomImageWidget(
              imageUrl: room.hinhAnhPhong != null && room.hinhAnhPhong!.isNotEmpty 
                  ? room.hinhAnhPhong!.first 
                  : null,
              width: double.infinity,
              height: 200,
            ),
          ),
          
          // Room Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Room Name & Availability
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        room.tenLoaiPhong ?? 'Standard Room',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    RoomAvailabilityBadge(room: room),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Capacity
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Tối đa ${room.sucChua ?? 2} khách',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Description
                Text(
                  room.moTa ?? 'Phòng tiêu chuẩn với đầy đủ tiện nghi',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Từ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '${(room.giaPhong?.isFinite == true ? room.giaPhong! : 500000).toStringAsFixed(0)} ₫/đêm',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    
                    // Expand button
                    IconButton(
                      onPressed: () => _showRoomDetails(room),
                      icon: const Icon(Icons.keyboard_arrow_down),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildRoomImagePlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.bed,
          size: 32,
          color: Colors.grey,
        ),
      ),
    );
  }

  void _showRoomDetails(Room room) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildRoomDetailsSheet(room),
    );
  }

  Widget _buildRoomDetailsSheet(Room room) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Room Image
            Container(
              height: 200,
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: RoomImageWidget(
                imageUrl: room.hinhAnhPhong != null && room.hinhAnhPhong!.isNotEmpty 
                    ? room.hinhAnhPhong!.first 
                    : null,
                width: double.infinity,
                height: 200,
              ),
            ),
            
            // Room Features
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Đặc điểm phòng',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Display amenities from backend or fallback
                  ..._buildRoomAmenities(room),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Price Options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tùy chọn giá',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildPriceOption(
                    'standard',
                    'Không hoàn tiền',
                    'Giá tốt nhất • Không thể hủy',
                    room.giaPhong ?? 500000,
                    Colors.blue,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildPriceOption(
                    'breakfast',
                    'Kèm bữa sáng',
                    'Hủy miễn phí • Bao gồm bữa sáng',
                    (room.giaPhong ?? 500000) * 1.2,
                    Colors.orange,
                    isRecommended: true,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Select Button
            Container(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedRoom = room;
                      _selectedPriceOption = 'standard';
                    });
                    Navigator.pop(context);
                    _navigateToPayment();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Chọn phòng này',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20), // Bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRoomAmenities(Room room) {
    List<Widget> amenities = [];
    
    // Add bed information
    if (room.soGiuongDoi != null && room.soGiuongDoi! > 0) {
      amenities.add(_buildFeatureItem(Icons.bed, '${room.soGiuongDoi} giường đôi'));
    } else if (room.soGiuongDon != null && room.soGiuongDon! > 0) {
      amenities.add(_buildFeatureItem(Icons.bed, '${room.soGiuongDon} giường đơn'));
    } else {
      amenities.add(_buildFeatureItem(Icons.bed, 'Giường đôi'));
    }
    
    // Add capacity information
    if (room.sucChua != null) {
      amenities.add(_buildFeatureItem(Icons.person, 'Tối đa ${room.sucChua} khách'));
    }
    
    // Add amenities from backend
    if (room.tienNghi != null && room.tienNghi!.isNotEmpty) {
      for (String amenity in room.tienNghi!) {
        amenities.add(_buildFeatureItem(_getAmenityIcon(amenity), amenity));
      }
    } else {
      // Fallback amenities
      amenities.addAll([
        _buildFeatureItem(Icons.wifi, 'WiFi miễn phí'),
        _buildFeatureItem(Icons.ac_unit, 'Điều hòa'),
        _buildFeatureItem(Icons.tv, 'TV'),
        _buildFeatureItem(Icons.local_parking, 'Bãi đỗ xe'),
        _buildFeatureItem(Icons.restaurant, 'Nhà hàng'),
      ]);
    }
    
    return amenities;
  }

  IconData _getAmenityIcon(String amenity) {
    final amenityLower = amenity.toLowerCase();
    if (amenityLower.contains('wifi') || amenityLower.contains('internet')) {
      return Icons.wifi;
    } else if (amenityLower.contains('điều hòa') || amenityLower.contains('air')) {
      return Icons.ac_unit;
    } else if (amenityLower.contains('tv') || amenityLower.contains('tivi')) {
      return Icons.tv;
    } else if (amenityLower.contains('đỗ xe') || amenityLower.contains('parking')) {
      return Icons.local_parking;
    } else if (amenityLower.contains('nhà hàng') || amenityLower.contains('restaurant')) {
      return Icons.restaurant;
    } else if (amenityLower.contains('hồ bơi') || amenityLower.contains('pool')) {
      return Icons.pool;
    } else if (amenityLower.contains('gym') || amenityLower.contains('thể dục')) {
      return Icons.fitness_center;
    } else if (amenityLower.contains('spa')) {
      return Icons.spa;
    } else if (amenityLower.contains('bar')) {
      return Icons.local_bar;
    } else if (amenityLower.contains('sân bay') || amenityLower.contains('airport')) {
      return Icons.flight;
    } else {
      return Icons.check_circle;
    }
  }

  Widget _buildPriceOption(
    String optionId,
    String title,
    String description,
    double price,
    Color color, {
    bool isRecommended = false,
  }) {
    final isSelected = _selectedPriceOption == optionId;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPriceOption = optionId;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? color : Colors.black,
                        ),
                      ),
                      if (isRecommended) ...[
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
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${price.toStringAsFixed(0)} ₫/đêm',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedPriceOption = optionId;
                    });
                    _navigateToPayment();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text(
                    'Chọn',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Open external Google Maps
  void _openExternalMap(BuildContext context) async {
    try {
      // Build search query including hotel name for better results
      String searchQuery = widget.hotel.ten;
      
      // Build full address
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
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không có địa chỉ để hiển thị trên bản đồ'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      print('🗺️ Mở bản đồ cho: $searchQuery');
      
      // Encode the search query
      final encodedQuery = Uri.encodeComponent(searchQuery);
      
      // Try Google Maps app first (geo: scheme), then fallback to web
      final geoUri = Uri.parse('geo:0,0?q=$encodedQuery');
      final webUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedQuery');
      
      bool launched = false;
      
      // Try Google Maps app with geo: scheme
      try {
        if (await canLaunchUrl(geoUri)) {
          launched = await launchUrl(geoUri, mode: LaunchMode.externalApplication);
          print('✅ Launched with geo: scheme: $launched');
        }
      } catch (e) {
        print('❌ Cannot launch geo: URI: $e');
      }
      
      // If Google Maps app didn't work, try web version
      if (!launched) {
        try {
          if (await canLaunchUrl(webUri)) {
            launched = await launchUrl(webUri, mode: LaunchMode.externalApplication);
            print('✅ Launched with web URL: $launched');
          }
        } catch (e) {
          print('❌ Cannot launch web URI: $e');
        }
      }
      
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Không thể mở bản đồ. Vui lòng cài đặt Google Maps hoặc trình duyệt.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Thử lại',
              textColor: Colors.white,
              onPressed: () => _openExternalMap(context),
            ),
          ),
        );
      } else if (launched) {
        print('✅ Đã mở bản đồ thành công');
      }
    } catch (e) {
      print('❌ Lỗi _openExternalMap: $e');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi mở bản đồ: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildMapWidget() {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _getHotelLocation(),
        zoom: 15.0,
      ),
      markers: {
        Marker(
          markerId: const MarkerId('hotel'),
          position: _getHotelLocation(),
          infoWindow: InfoWindow(
            title: widget.hotel.ten,
            snippet: widget.hotel.diaChi ?? 'Địa chỉ không xác định',
          ),
        ),
      },
      mapType: MapType.normal,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: true,
      onMapCreated: (GoogleMapController controller) {
        // Map created successfully
        print('✅ Google Maps created successfully');
      },
      onCameraMove: (CameraPosition position) {
        // Camera moved
      },
      onTap: (LatLng position) {
        // Map tapped
      },
    );
  }

  Future<bool> _checkMapsAvailability() async {
    try {
      // Check if Google Maps services are available
      // For now, we'll assume it's available and let GoogleMap handle errors gracefully
      return true;
    } catch (e) {
      print('❌ Google Maps not available: $e');
      return false;
    }
  }

  Widget _buildMapFallback() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.location_on,
            size: 64,
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          const Text(
            'Vị trí khách sạn',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.hotel.ten,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            widget.hotel.diaChi ?? "Địa chỉ không xác định",
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  _openExternalMaps();
                },
                icon: const Icon(Icons.map, size: 18),
                label: const Text('Google Maps'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  _copyLocationToClipboard();
                },
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Sao chép'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openExternalMaps() {
    final location = _getHotelLocation();
    final url = 'https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}';
    
    // You can use url_launcher package here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Mở bản đồ: $url'),
        action: SnackBarAction(
          label: 'Sao chép',
          onPressed: () {
            _copyLocationToClipboard();
          },
        ),
      ),
    );
  }

  void _copyLocationToClipboard() {
    final location = _getHotelLocation();
    final locationText = '${widget.hotel.ten}\n${widget.hotel.diaChi ?? "Địa chỉ không xác định"}\nTọa độ: ${location.latitude}, ${location.longitude}';
    
    // Copy to clipboard
    Clipboard.setData(ClipboardData(text: locationText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép thông tin vị trí vào clipboard'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  LatLng _getHotelLocation() {
    // Default location for Ho Chi Minh City
    // In a real app, you would get this from the hotel's coordinates
    if (widget.hotel.diaChi?.contains('TP.HCM') == true || 
        widget.hotel.diaChi?.contains('Quận 1') == true) {
      return const LatLng(10.7769, 106.7009); // District 1, HCMC
    } else if (widget.hotel.diaChi?.contains('Hà Nội') == true) {
      return const LatLng(21.0285, 105.8542); // Hanoi
    } else if (widget.hotel.diaChi?.contains('Đà Nẵng') == true) {
      return const LatLng(16.0544, 108.2022); // Da Nang
    } else {
      return const LatLng(10.7769, 106.7009); // Default to HCMC
    }
  }



  void _navigateToPayment() {
    if (_selectedRoom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn phòng trước khi thanh toán'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Calculate the final price based on selected option
    double finalPrice = (_selectedRoom!.giaPhong?.isFinite == true) ? _selectedRoom!.giaPhong! : 500000;
    if (_selectedPriceOption == 'breakfast') {
      finalPrice = finalPrice * 1.2; // 20% more for breakfast
    }

    // Calculate nights
    final nights = _checkOutDate!.difference(_checkInDate!).inDays;

    // ✅ Reload room availability sau khi quay lại từ payment screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          hotel: widget.hotel,
          room: _selectedRoom!,
          checkInDate: _checkInDate!,
          checkOutDate: _checkOutDate!,
          guestCount: _adults,
          nights: nights,
          roomPrice: finalPrice,
          roomCount: _rooms,
        ),
      ),
    ).then((_) {
      // Reload room availability sau khi quay lại (có thể đã đặt phòng thành công)
      print('🔄 Reloading room availability after returning from payment...');
      _loadAvailableRooms();
    });
  }
}

