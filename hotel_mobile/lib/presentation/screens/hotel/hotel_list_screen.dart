import 'package:flutter/material.dart';
import 'package:hotel_mobile/data/models/hotel.dart';
import 'package:hotel_mobile/data/services/api_service.dart';
import 'package:hotel_mobile/presentation/screens/room/room_detail_screen.dart';
import 'package:hotel_mobile/presentation/widgets/hotel_card_with_favorite.dart';
import 'package:intl/intl.dart';

class HotelListScreen extends StatefulWidget {
  final String location;
  final DateTime? checkInDate;
  final DateTime? checkOutDate;
  final int guestCount;
  final int roomCount;

  const HotelListScreen({
    super.key,
    required this.location,
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
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _apiService.initialize();
    _loadHotels();
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

      if (widget.location.contains('đánh giá cao') ||
          widget.location.contains('rating') ||
          widget.location.contains('Đánh giá cao')) {
        searchQuery = ''; // Get all hotels to sort by rating
        sortByRating = true;
      } else if (widget.location.contains('Gần bạn') ||
          widget.location.contains('gần đây')) {
        searchQuery = 'Thành phố Hồ Chí Minh'; // Default to HCMC for nearby
      }

      final response = await _apiService.getHotels(
        search: searchQuery,
        limit: 50,
      );

      if (response.success && response.data != null) {
        List<Hotel> hotels = response.data!;

        // Sort by rating if needed
        if (sortByRating) {
          hotels.sort(
            (a, b) => (b.diemDanhGiaTrungBinh ?? 0.0).compareTo(
              a.diemDanhGiaTrungBinh ?? 0.0,
            ),
          );
        }

        setState(() {
          _hotels = hotels;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _viewHotelRooms(Hotel hotel) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final response = await _apiService.getRoomsByHotel(hotel.id);

      Navigator.pop(context); // Close loading dialog

      if (response.success &&
          response.data != null &&
          response.data!.isNotEmpty) {
        final firstRoom = response.data!.first;
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  RoomDetailScreen(room: firstRoom, hotel: hotel),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Khách sạn ${hotel.ten} hiện không có phòng khả dụng',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải thông tin phòng: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getAppBarTitle() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Info Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
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
                  ],
                ),
                if (widget.checkInDate != null &&
                    widget.checkOutDate != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${DateFormat('dd/MM/yyyy').format(widget.checkInDate!)} - ${DateFormat('dd/MM/yyyy').format(widget.checkOutDate!)}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.people, color: Colors.white70, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.guestCount} khách • ${widget.roomCount} phòng',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Hotels List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Lỗi: $_error'),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadHotels, child: const Text('Thử lại')),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.hotel_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Không tìm thấy khách sạn tại ${widget.location}',
            style: const TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Vui lòng thử tìm kiếm địa điểm khác',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Quay lại'),
          ),
        ],
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
        height: 320,
        onTap: () => _viewHotelRooms(hotel),
      ),
    );
  }
}
