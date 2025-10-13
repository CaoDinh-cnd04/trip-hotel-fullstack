import 'package:flutter/material.dart';
import 'package:hotel_mobile/data/models/hotel.dart';
import 'package:hotel_mobile/data/models/room.dart';
import 'package:hotel_mobile/presentation/widgets/property_image_gallery.dart';
import 'package:hotel_mobile/presentation/widgets/property_info_section.dart';
import 'package:hotel_mobile/presentation/widgets/amenities_section.dart';
import 'package:hotel_mobile/presentation/widgets/room_selection_section.dart';
import 'package:hotel_mobile/presentation/widgets/bottom_cta_bar.dart';

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
  List<Room> _rooms = [];
  bool _isLoadingRooms = true;
  double? _lowestPrice;

  @override
  void initState() {
    super.initState();
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

      // Mock data for demonstration
      await Future.delayed(const Duration(milliseconds: 500));

      final mockRooms = [
        Room(
          id: 1,
          soPhong: '101',
          loaiPhongId: 1,
          khachSanId: widget.hotel.id,
          tenLoaiPhong: 'Standard Room',
          giaPhong: 1200000,
          sucChua: 2,
          moTa: 'Phòng tiêu chuẩn với giường đôi, điều hòa, TV',
          hinhAnhPhong: [
            'https://images.unsplash.com/photo-1566665797739-1674de7a421a',
            'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b',
          ],
        ),
        Room(
          id: 2,
          soPhong: '201',
          loaiPhongId: 2,
          khachSanId: widget.hotel.id,
          tenLoaiPhong: 'Deluxe Room',
          giaPhong: 1800000,
          sucChua: 3,
          moTa: 'Phòng cao cấp với view biển, ban công riêng',
          hinhAnhPhong: [
            'https://images.unsplash.com/photo-1590490360182-c33d57733427',
            'https://images.unsplash.com/photo-1591088398332-8a7791972843',
          ],
        ),
        Room(
          id: 3,
          soPhong: '301',
          loaiPhongId: 3,
          khachSanId: widget.hotel.id,
          tenLoaiPhong: 'Suite Room',
          giaPhong: 2500000,
          sucChua: 4,
          moTa: 'Phòng suite rộng rãi với phòng khách riêng',
          hinhAnhPhong: [
            'https://images.unsplash.com/photo-1578683010236-d716f9a3f461',
            'https://images.unsplash.com/photo-1584132967334-10e028bd69f7',
          ],
        ),
      ];

      _rooms = mockRooms;
      _lowestPrice = mockRooms
          .map((room) => room.giaPhong ?? 0)
          .reduce((a, b) => a < b ? a : b)
          .toDouble();

      setState(() => _isLoadingRooms = false);
    } catch (e) {
      print('Error loading rooms: $e');
      setState(() => _isLoadingRooms = false);
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

  Widget _buildRoomOptionsBottomSheet(Room room) {
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
          ),
          const SizedBox(height: 12),
          _buildPriceOption(
            'Kèm bữa sáng',
            (room.giaPhong ?? 0) + 200000,
            'Hủy miễn phí • Bao gồm bữa sáng',
            true,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to booking confirmation
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
  }

  Widget _buildPriceOption(
    String title,
    double price,
    String description,
    bool recommended,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: recommended ? Colors.blue : Colors.grey[300]!,
          width: recommended ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
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
            Text(
              '${_formatPrice(price)}/đêm',
              style: const TextStyle(
                color: Colors.blue,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
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
              // App Bar with back button
              SliverAppBar(
                expandedHeight: 0,
                floating: true,
                pinned: true,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () {
                      // Share functionality
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.favorite_border),
                    onPressed: () {
                      // Add to favorites
                    },
                  ),
                ],
              ),

              // Image Gallery
              SliverToBoxAdapter(
                child: PropertyImageGallery(hotel: widget.hotel),
              ),

              // Property Info Section
              SliverToBoxAdapter(
                child: PropertyInfoSection(hotel: widget.hotel),
              ),

              // Amenities Section
              SliverToBoxAdapter(child: AmenitiesSection(hotel: widget.hotel)),

              // Room Selection Section
              SliverToBoxAdapter(
                child: _isLoadingRooms
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : RoomSelectionSection(
                        rooms: _rooms,
                        onRoomSelected: _onRoomSelected,
                        checkInDate: widget.checkInDate,
                        checkOutDate: widget.checkOutDate,
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
