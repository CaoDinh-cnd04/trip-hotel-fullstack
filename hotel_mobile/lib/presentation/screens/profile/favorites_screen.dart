import 'package:flutter/material.dart';
import 'package:hotel_mobile/data/models/hotel.dart';
import 'package:hotel_mobile/presentation/widgets/search_result_card.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Hotel> _favoriteHotels = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavoriteHotels();
  }

  Future<void> _loadFavoriteHotels() async {
    // Simulate loading
    await Future.delayed(const Duration(seconds: 1));
    
    // Mock data for favorite hotels
    setState(() {
      _favoriteHotels = [
        Hotel(
          id: 1,
          ten: 'Khách sạn Grand Palace',
          diaChi: '123 Nguyễn Huệ, Quận 1, TP.HCM',
          moTa: 'Khách sạn 5 sao sang trọng với view đẹp',
          hinhAnh: 'https://via.placeholder.com/300x200',
        ),
        Hotel(
          id: 2,
          ten: 'Resort Seaside Paradise',
          diaChi: '456 Bãi biển, Nha Trang',
          moTa: 'Resort nghỉ dưỡng bên bờ biển',
          hinhAnh: 'https://via.placeholder.com/300x200',
        ),
        Hotel(
          id: 3,
          ten: 'Hotel Luxury Downtown',
          diaChi: '789 Lê Lợi, Quận 1, TP.HCM',
          moTa: 'Khách sạn cao cấp tại trung tâm thành phố',
          hinhAnh: 'https://via.placeholder.com/300x200',
        ),
      ];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Danh sách yêu thích'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (_favoriteHotels.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _showClearAllDialog,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favoriteHotels.isEmpty
              ? _buildEmptyState()
              : _buildFavoritesList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có khách sạn yêu thích',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy khám phá và lưu những khách sạn bạn thích!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to home screen
            },
            icon: const Icon(Icons.explore),
            label: const Text('Khám phá khách sạn'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList() {
    return Column(
      children: [
        // Header with count
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Text(
            '${_favoriteHotels.length} khách sạn yêu thích',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        const Divider(height: 1),
        
        // Hotels list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _favoriteHotels.length,
            itemBuilder: (context, index) {
              final hotel = _favoriteHotels[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Stack(
                  children: [
                    SearchResultCard(
                      hotel: hotel,
                      checkInDate: DateTime.now().add(const Duration(days: 1)),
                      checkOutDate: DateTime.now().add(const Duration(days: 2)),
                      guestCount: 1,
                      roomCount: 1,
                      onTap: () => _navigateToHotelDetail(hotel),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 20,
                          ),
                          onPressed: () => _removeFromFavorites(hotel),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _navigateToHotelDetail(Hotel hotel) {
    // TODO: Navigate to hotel detail screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Xem chi tiết ${hotel.ten}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _removeFromFavorites(Hotel hotel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa khỏi yêu thích'),
        content: Text('Bạn có chắc chắn muốn xóa "${hotel.ten}" khỏi danh sách yêu thích?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _favoriteHotels.removeWhere((h) => h.id == hotel.id);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã xóa "${hotel.ten}" khỏi yêu thích'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tất cả yêu thích'),
        content: const Text('Bạn có chắc chắn muốn xóa tất cả khách sạn khỏi danh sách yêu thích?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _favoriteHotels.clear();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã xóa tất cả khách sạn yêu thích'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa tất cả'),
          ),
        ],
      ),
    );
  }
}
