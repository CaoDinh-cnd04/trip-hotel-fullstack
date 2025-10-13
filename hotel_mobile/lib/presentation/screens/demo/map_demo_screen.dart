import 'package:flutter/material.dart';
import '../../../data/models/hotel.dart';
import '../map/map_view_screen.dart';

class MapDemoScreen extends StatelessWidget {
  const MapDemoScreen({Key? key}) : super(key: key);

  List<Hotel> _createMockHotels() {
    return [
      Hotel(
        id: 1,
        ten: 'Hotel Continental Saigon',
        diaChi: 'Quận 1, TP. Hồ Chí Minh',
        soSao: 5,
        yeuCauCoc: 2500000,
        hinhAnh:
            'https://images.unsplash.com/photo-1564501049412-61c2a3083791?w=300',
        diemDanhGiaTrungBinh: 4.8,
        soLuotDanhGia: 245,
      ),
      Hotel(
        id: 2,
        ten: 'Lotte Legend Hotel Saigon',
        diaChi: 'Quận 1, TP. Hồ Chí Minh',
        soSao: 5,
        yeuCauCoc: 3200000,
        hinhAnh:
            'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=300',
        diemDanhGiaTrungBinh: 4.9,
        soLuotDanhGia: 189,
      ),
      Hotel(
        id: 3,
        ten: 'Park Hyatt Saigon',
        diaChi: 'Quận 1, TP. Hồ Chí Minh',
        soSao: 5,
        yeuCauCoc: 4500000,
        hinhAnh:
            'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=300',
        diemDanhGiaTrungBinh: 4.7,
        soLuotDanhGia: 156,
      ),
      Hotel(
        id: 4,
        ten: 'Sheraton Saigon Hotel',
        diaChi: 'Quận 1, TP. Hồ Chí Minh',
        soSao: 4,
        yeuCauCoc: 1800000,
        hinhAnh:
            'https://images.unsplash.com/photo-1571003123894-1f0594d2b5d9?w=300',
        diemDanhGiaTrungBinh: 4.5,
        soLuotDanhGia: 312,
      ),
      Hotel(
        id: 5,
        ten: 'Liberty Central Saigon Citypoint',
        diaChi: 'Quận 1, TP. Hồ Chí Minh',
        soSao: 4,
        yeuCauCoc: 1200000,
        hinhAnh:
            'https://images.unsplash.com/photo-1590490360182-c33d57733427?w=300',
        diemDanhGiaTrungBinh: 4.3,
        soLuotDanhGia: 287,
      ),
      Hotel(
        id: 6,
        ten: 'Pullman Saigon Centre',
        diaChi: 'Quận 1, TP. Hồ Chí Minh',
        soSao: 5,
        yeuCauCoc: 2800000,
        hinhAnh:
            'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=300',
        diemDanhGiaTrungBinh: 4.6,
        soLuotDanhGia: 198,
      ),
    ];
  }

  void _openMapView(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapViewScreen(
          hotels: _createMockHotels(),
          location: 'TP. Hồ Chí Minh',
          checkInDate: DateTime.now().add(const Duration(days: 1)),
          checkOutDate: DateTime.now().add(const Duration(days: 3)),
          guestCount: 2,
          roomCount: 1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mockHotels = _createMockHotels();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Demo Map View',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[600]!, Colors.green[400]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.map, color: Colors.white, size: 24),
                      SizedBox(width: 12),
                      Text(
                        'Trang Bản Đồ',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Xem vị trí các khách sạn trên bản đồ với marker hiển thị giá',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Features List
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.featured_play_list,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Tính năng',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  ...[
                    'Header với nút Back và toggle Danh sách',
                    'Google Maps widget với zoom controls',
                    'Custom markers hiển thị giá phòng',
                    'Tap marker để xem thông tin khách sạn',
                    'Hotel info card dưới dạng bottom sheet',
                    'My location button',
                    'Auto fit tất cả markers trong view',
                  ].map(
                    (feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green[600],
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              feature,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
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

            const SizedBox(height: 24),

            // Hotel List Preview
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.hotel, color: Colors.blue[600], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Khách sạn mẫu (${mockHotels.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Column(
                    children: mockHotels
                        .take(3)
                        .map(
                          (hotel) => Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.blue[100],
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    Icons.location_on,
                                    color: Colors.blue[600],
                                    size: 20,
                                  ),
                                ),

                                const SizedBox(width: 12),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        hotel.ten,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        hotel.diaChi ?? '',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.green[200]!,
                                    ),
                                  ),
                                  child: Text(
                                    '${(hotel.yeuCauCoc! / 1000).toStringAsFixed(0)}K',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green[600],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),

                  if (mockHotels.length > 3)
                    Text(
                      '... và ${mockHotels.length - 3} khách sạn khác',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Open Map Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _openMapView(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, color: Colors.white, size: 20),
                    SizedBox(width: 12),
                    Text(
                      'Mở Bản Đồ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
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
}
