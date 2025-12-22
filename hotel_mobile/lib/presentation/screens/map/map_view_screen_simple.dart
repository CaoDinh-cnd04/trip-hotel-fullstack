import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/hotel.dart';
import 'widgets/hotel_info_card.dart';
import '../property/property_detail_screen.dart';

/// Màn hình bản đồ đơn giản sử dụng Google Maps Static API
/// Tránh các vấn đề với GoogleMap widget và FrameEvents
class MapViewScreenSimple extends StatefulWidget {
  final List<Hotel> hotels;
  final String location;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int guestCount;
  final int roomCount;

  const MapViewScreenSimple({
    Key? key,
    required this.hotels,
    required this.location,
    required this.checkInDate,
    required this.checkOutDate,
    required this.guestCount,
    required this.roomCount,
  }) : super(key: key);

  @override
  State<MapViewScreenSimple> createState() => _MapViewScreenSimpleState();
}

class _MapViewScreenSimpleState extends State<MapViewScreenSimple> {
  Hotel? _selectedHotel;
  bool _isLoading = true;

  // Default locations for major cities in Vietnam
  static const Map<String, LatLng> _cityLocations = {
    'Hồ Chí Minh': LatLng(10.8231, 106.6297),
    'TP. Hồ Chí Minh': LatLng(10.8231, 106.6297),
    'Hà Nội': LatLng(21.0285, 105.8542),
    'Đà Nẵng': LatLng(16.0544, 108.2022),
    'Vũng Tàu': LatLng(10.3460, 107.0843),
    'Nha Trang': LatLng(12.2388, 109.1967),
    'Phú Quốc': LatLng(10.2899, 103.9840),
    'Huế': LatLng(16.4637, 107.5909),
    'Hội An': LatLng(15.8801, 108.3380),
    'Quận 1': LatLng(10.7769, 106.7009),
    'Quận 3': LatLng(10.7830, 106.6888),
    'Hoàn Kiếm': LatLng(21.0285, 105.8542),
  };

  static const LatLng _defaultLocation = LatLng(10.8231, 106.6297);
  static const String _apiKey = 'AIzaSyDMD4-HmDKQMgQeN_Hk1kJPyqUuGFP6LYE';

  @override
  void initState() {
    super.initState();
    // Simulate loading
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  /// Get coordinates from address
  LatLng _getHotelLocation(Hotel hotel) {
    final address = hotel.diaChi ?? hotel.tenViTri ?? hotel.tenTinhThanh ?? '';
    if (address.isNotEmpty) {
      for (var entry in _cityLocations.entries) {
        if (address.contains(entry.key)) {
          return entry.value;
        }
      }
    }
    return _defaultLocation;
  }

  /// Build Google Maps Static API URL
  String _buildStaticMapUrl() {
    if (widget.hotels.isEmpty) {
      final location = _defaultLocation;
      return 'https://maps.googleapis.com/maps/api/staticmap?'
          'center=${location.latitude},${location.longitude}'
          '&zoom=13'
          '&size=600x400'
          '&maptype=roadmap'
          '&markers=color:blue%7C${location.latitude},${location.longitude}'
          '&key=$_apiKey';
    }

    // If multiple hotels, center on first one
    final firstHotel = widget.hotels.first;
    final location = _getHotelLocation(firstHotel);
    
    // Build markers for all hotels
    final markers = widget.hotels.map((hotel) {
      final loc = _getHotelLocation(hotel);
      return 'color:blue%7Clabel:${hotel.id}%7C${loc.latitude},${loc.longitude}';
    }).join('%7C');

    return 'https://maps.googleapis.com/maps/api/staticmap?'
        'center=${location.latitude},${location.longitude}'
        '&zoom=13'
        '&size=600x400'
        '&maptype=roadmap'
        '&markers=$markers'
        '&key=$_apiKey';
  }

  /// Open Google Maps app or web
  Future<void> _openGoogleMaps(Hotel hotel) async {
    try {
      // Build search query
      String searchQuery = hotel.ten;
      List<String> addressParts = [];
      
      if (hotel.diaChi != null && hotel.diaChi!.isNotEmpty) {
        addressParts.add(hotel.diaChi!);
      }
      if (hotel.tenViTri != null && hotel.tenViTri!.isNotEmpty) {
        addressParts.add(hotel.tenViTri!);
      }
      if (hotel.tenTinhThanh != null && hotel.tenTinhThanh!.isNotEmpty) {
        addressParts.add(hotel.tenTinhThanh!);
      }
      
      if (addressParts.isNotEmpty) {
        searchQuery += ', ${addressParts.join(', ')}';
      }

      final encodedQuery = Uri.encodeComponent(searchQuery);
      final geoUri = Uri.parse('geo:0,0?q=$encodedQuery');
      final webUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedQuery');

      bool launched = false;

      // Try Google Maps app
      try {
        if (await canLaunchUrl(geoUri)) {
          launched = await launchUrl(geoUri, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        print('⚠️ Cannot launch geo URI: $e');
      }

      // Fallback to web
      if (!launched) {
        try {
          if (await canLaunchUrl(webUri)) {
            launched = await launchUrl(webUri, mode: LaunchMode.externalApplication);
          }
        } catch (e) {
          print('⚠️ Cannot launch web URI: $e');
        }
      }

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể mở Google Maps. Vui lòng cài đặt Google Maps hoặc trình duyệt.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('❌ Error opening Google Maps: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewHotelDetails(Hotel hotel) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PropertyDetailScreen(
          hotel: hotel,
          checkInDate: widget.checkInDate,
          checkOutDate: widget.checkOutDate,
          guestCount: widget.guestCount,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Static Map Image
          Column(
            children: [
              // Header
              _buildHeader(),
              
              // Map Image
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                        ),
                        child: Stack(
                          children: [
                            // Static map image
                            Image.network(
                              _buildStaticMapUrl(),
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildMapErrorFallback();
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                            ),
                            
                            // Overlay buttons
                            Positioned(
                              bottom: 16,
                              right: 16,
                              child: Column(
                                children: [
                                  // Open in Google Maps button
                                  FloatingActionButton(
                                    onPressed: () {
                                      if (widget.hotels.isNotEmpty) {
                                        _openGoogleMaps(widget.hotels.first);
                                      }
                                    },
                                    backgroundColor: const Color(0xFF003580),
                                    child: const Icon(Icons.open_in_new, color: Colors.white),
                                  ),
                                  const SizedBox(height: 8),
                                  // Zoom in
                                  FloatingActionButton.small(
                                    onPressed: () {
                                      // Could implement zoom by rebuilding with different zoom level
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Nhấn nút "Mở Google Maps" để xem chi tiết'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                    backgroundColor: Colors.white,
                                    child: const Icon(Icons.add, color: Colors.black87),
                                  ),
                                  const SizedBox(height: 8),
                                  // Zoom out
                                  FloatingActionButton.small(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Nhấn nút "Mở Google Maps" để xem chi tiết'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                    backgroundColor: Colors.white,
                                    child: const Icon(Icons.remove, color: Colors.black87),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),

          // Hotel Info Card
          if (_selectedHotel != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: HotelInfoCard(
                hotel: _selectedHotel!,
                checkInDate: widget.checkInDate,
                checkOutDate: widget.checkOutDate,
                guestCount: widget.guestCount,
                onClose: () {
                  setState(() {
                    _selectedHotel = null;
                  });
                },
                onViewDetails: () => _viewHotelDetails(_selectedHotel!),
              ),
            ),

          // Hotels List (if multiple)
          if (widget.hotels.length > 1 && _selectedHotel == null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 100,
              child: Container(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.hotels.length,
                  itemBuilder: (context, index) {
                    final hotel = widget.hotels[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedHotel = hotel;
                        });
                      },
                      child: Container(
                        width: 200,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hotel.ten,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              hotel.diaChi ?? hotel.tenViTri ?? '',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Spacer(),
                            ElevatedButton(
                              onPressed: () => _openGoogleMaps(hotel),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF003580),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                minimumSize: const Size(0, 32),
                              ),
                              child: const Text(
                                'Xem trên Maps',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
          ),
          Column(
            children: [
              const Text(
                'Bản đồ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                '${widget.hotels.length} chỗ nghỉ',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.list, color: Color(0xFF003580)),
          ),
        ],
      ),
    );
  }

  Widget _buildMapErrorFallback() {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Không thể tải bản đồ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                if (widget.hotels.isNotEmpty) {
                  _openGoogleMaps(widget.hotels.first);
                }
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('Mở Google Maps'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003580),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple LatLng class
class LatLng {
  final double latitude;
  final double longitude;

  const LatLng(this.latitude, this.longitude);
}

