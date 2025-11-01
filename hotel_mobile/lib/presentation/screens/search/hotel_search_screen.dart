import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/services/search_history_service.dart';
import '../hotel/hotel_list_screen.dart';

class HotelSearchScreen extends StatefulWidget {
  final String? initialLocation;
  final DateTime? initialCheckInDate;
  final DateTime? initialCheckOutDate;
  final int? initialRooms;
  final int? initialAdults;
  final int? initialChildren;

  const HotelSearchScreen({
    super.key,
    this.initialLocation,
    this.initialCheckInDate,
    this.initialCheckOutDate,
    this.initialRooms,
    this.initialAdults,
    this.initialChildren,
  });

  @override
  State<HotelSearchScreen> createState() => _HotelSearchScreenState();
}

class _HotelSearchScreenState extends State<HotelSearchScreen> {
  int _selectedTab = 0;
  final TextEditingController _searchController = TextEditingController();
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  int _rooms = 1;
  int _adults = 2;
  int _children = 0;
  bool _showPromotions = false;

  @override
  void initState() {
    super.initState();
    
    // Use initial values if provided
    if (widget.initialLocation != null) {
      _searchController.text = widget.initialLocation!;
    }
    
    _checkInDate = widget.initialCheckInDate ?? DateTime.now().add(const Duration(days: 1));
    _checkOutDate = widget.initialCheckOutDate ?? DateTime.now().add(const Duration(days: 2));
    _rooms = widget.initialRooms ?? 1;
    _adults = widget.initialAdults ?? 2;
    _children = widget.initialChildren ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5), // Light pink background
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              _buildHeader(),
              
              // Search Card
              _buildSearchCard(),
              
              // Popular Accommodations
              _buildPopularAccommodations(),
              
              // Discount Offers
              _buildDiscountOffers(),
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
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          
          const Spacer(),
          
          // Title
          const Text(
            'Tất cả phòng',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          
          const Spacer(),
          
          // Currency button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('¥', style: TextStyle(fontSize: 16)),
                Text('VND', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Tabs
          Row(
            children: [
              Expanded(
                child: _buildTab('Qua đêm', 0),
              ),
              Expanded(
                child: _buildTab('Ở trong ngày', 1),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'The Sóng Apartment Vũng Tàu - Gr...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const Icon(Icons.send, color: Colors.blue),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Date Selection
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  'Th 7, 18 thg 10',
                  Icons.calendar_today,
                  () => _selectDate(true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateField(
                  'CN, 19 thg 10',
                  Icons.calendar_today,
                  () => _selectDate(false),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Guest Selection
          _buildGuestField(),
          
          const SizedBox(height: 16),
          
          // Promotions Option
          Row(
            children: [
              Checkbox(
                value: _showPromotions,
                onChanged: (value) {
                  setState(() {
                    _showPromotions = value ?? false;
                  });
                },
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              const Icon(Icons.access_time, color: Colors.grey, size: 18),
              const SizedBox(width: 4),
              const Expanded(
                child: Text(
                  'Cho xem các khuyến mải có thời hạn trước',
                  style: TextStyle(fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Tiết kiệm tới 20%',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Search Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _performSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.location_on, color: Colors.white),
              label: const Text(
                'Khám phá ưu đãi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.blue : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.blue : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildDateField(String text, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey, size: 20),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.person, color: Colors.grey, size: 20),
          const SizedBox(width: 12),
          Text(
            '$_rooms phòng $_adults người lớn $_children trẻ em',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularAccommodations() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Cơ sở lưu trú nổi tiếng ở Vũng Tàu',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    const Text(
                      'Được tài trợ',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildAccommodationCard(),
        ],
      ),
    );
  }

  Widget _buildAccommodationCard() {
    return Container(
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
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'MELIÁ',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'MELIÁ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Spanish warmth awaits',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountOffers() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nhiều chiết khấu hơn',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildDiscountCard(),
        ],
      ),
    );
  }

  Widget _buildDiscountCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFDC143C), Color(0xFFB22222)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber, width: 2),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left side
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(12),
                child: const Center(
                  child: Text(
                    'UP TO\n8% OFF',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ),
            // Right side
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Giảm tới ₫1,000,000...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Chi tiêu tối thiểu ₫760,000 | Hết hạn trong 3 ngày',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: _collectOffer,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Thu thập',
                            style: TextStyle(
                              color: Color(0xFFDC143C),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
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
  }

  void _selectDate(bool isCheckIn) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isCheckIn ? _checkInDate! : _checkOutDate!,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkInDate = picked;
        } else {
          _checkOutDate = picked;
        }
      });
    }
  }

  void _performSearch() async {
    // Lưu lịch sử tìm kiếm
    await SearchHistoryService.saveSearchHistory(
      location: _searchController.text.isNotEmpty ? _searchController.text : 'Vũng Tàu',
      checkInDate: _checkInDate!,
      checkOutDate: _checkOutDate!,
      rooms: _rooms,
      adults: _adults,
      children: _children,
    );
    
    // Navigate to hotel list screen with search parameters
    final searchLocation = _searchController.text.isNotEmpty ? _searchController.text : 'Vũng Tàu';
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HotelListScreen(
          title: 'Khách sạn tại $searchLocation',
          location: searchLocation,
          checkInDate: _checkInDate,
          checkOutDate: _checkOutDate,
          roomCount: _rooms,
          guestCount: _adults,
        ),
      ),
    );
  }

  void _collectOffer() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã thu thập ưu đãi!'),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
