import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../data/models/hotel.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'widgets/hotel_info_card.dart';
import '../property/property_detail_screen.dart';

class MapViewScreen extends StatefulWidget {
  final List<Hotel> hotels;
  final String location;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int guestCount;
  final int roomCount;

  const MapViewScreen({
    Key? key,
    required this.hotels,
    required this.location,
    required this.checkInDate,
    required this.checkOutDate,
    required this.guestCount,
    required this.roomCount,
  }) : super(key: key);

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Hotel? _selectedHotel;
  Position? _currentPosition;
  bool _isLoading = true;
  String? _errorMessage;

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

  static const LatLng _defaultLocation = LatLng(10.8231, 106.6297); // Ho Chi Minh City

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      print('🗺️ Initializing map with ${widget.hotels.length} hotels');

      // Create markers for hotels
      await _createHotelMarkers();
      
      print('✅ Created ${_markers.length} markers');
      
      // Get current location in background (don't wait for it)
      _getCurrentLocation().catchError((e) {
        print('⚠️ Could not get current location: $e');
        // This is not critical, continue without current location
      });
      
    } catch (e, stackTrace) {
      print('❌ Error initializing map: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _errorMessage = 'Không thể khởi tạo bản đồ. Vui lòng kiểm tra kết nối internet và thử lại.';
        _isLoading = false;
      });
    } finally {
      // Only set loading to false if we didn't set an error
      if (_errorMessage == null) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('⚠️ Location services are disabled');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('⚠️ Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('⚠️ Location permissions are permanently denied');
        return;
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      
      print('✅ Current location: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
      
      // Update map camera if controller is ready
      if (_mapController != null && mounted) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          ),
        );
      }
    } catch (e) {
      print('❌ Error getting location: $e');
    }
  }

  /// Get coordinates from address using geocoding
  Future<LatLng?> _geocodeAddress(String address) async {
    try {
      print('🔍 Geocoding address: $address');
      
      // First, try using geocoding package
      try {
        List<Location> locations = await locationFromAddress(address);
        if (locations.isNotEmpty) {
          final location = locations.first;
          print('✅ Geocoded successfully: ${location.latitude}, ${location.longitude}');
          return LatLng(location.latitude, location.longitude);
        }
      } catch (e) {
        print('⚠️ Geocoding package failed: $e');
        // Continue to fallback methods
      }

      // Fallback: Try to find in city locations
      for (var entry in _cityLocations.entries) {
        if (address.contains(entry.key)) {
          print('✅ Found in city locations: ${entry.key}');
          return entry.value;
        }
      }

      // Fallback: Use keyword matching
      final lowerAddress = address.toLowerCase();
      if (lowerAddress.contains('hồ chí minh') || 
          lowerAddress.contains('sài gòn') ||
          lowerAddress.contains('quận 1') ||
          lowerAddress.contains('quận 3') ||
          lowerAddress.contains('quận 2') ||
          lowerAddress.contains('quận 4') ||
          lowerAddress.contains('quận 5') ||
          lowerAddress.contains('quận 6') ||
          lowerAddress.contains('quận 7') ||
          lowerAddress.contains('quận 8') ||
          lowerAddress.contains('quận 9') ||
          lowerAddress.contains('quận 10') ||
          lowerAddress.contains('quận 11') ||
          lowerAddress.contains('quận 12')) {
        return _cityLocations['Hồ Chí Minh']!;
      } else if (lowerAddress.contains('hà nội') ||
                 lowerAddress.contains('hoàn kiếm') ||
                 lowerAddress.contains('ba đình') ||
                 lowerAddress.contains('đống đa')) {
        return _cityLocations['Hà Nội']!;
      } else if (lowerAddress.contains('đà nẵng')) {
        return _cityLocations['Đà Nẵng']!;
      } else if (lowerAddress.contains('vũng tàu')) {
        return _cityLocations['Vũng Tàu']!;
      } else if (lowerAddress.contains('nha trang')) {
        return _cityLocations['Nha Trang']!;
      } else if (lowerAddress.contains('phú quốc')) {
        return _cityLocations['Phú Quốc']!;
      } else if (lowerAddress.contains('huế')) {
        return _cityLocations['Huế']!;
      } else if (lowerAddress.contains('hội an')) {
        return _cityLocations['Hội An']!;
      }

      // Last fallback: return null to use default location
      print('⚠️ Could not geocode address, using fallback');
      return null;
    } catch (e) {
      print('❌ Error geocoding address: $e');
      return null;
    }
  }

  Future<void> _createHotelMarkers() async {
    Set<Marker> markers = {};
    List<LatLng> hotelPositions = [];

    print('📍 Creating markers for ${widget.hotels.length} hotels');

    for (int i = 0; i < widget.hotels.length; i++) {
      final hotel = widget.hotels[i];
      LatLng? position;

      // Try to get coordinates from address
      final address = hotel.diaChi ?? hotel.tenViTri ?? hotel.tenTinhThanh ?? '';
      if (address.isNotEmpty) {
        position = await _geocodeAddress(address);
        print('📍 Hotel ${hotel.id}: $address -> ${position?.latitude}, ${position?.longitude}');
      }

      // If geocoding failed, use fallback based on hotel ID
      if (position == null) {
        // Spread hotels around default location
        final spread = 0.05; // ~5km spread
        final angle = (i * 2 * math.pi) / (widget.hotels.length > 1 ? widget.hotels.length : 1);
        final distance = (i % 3 + 1) * spread / 3;
        position = LatLng(
          _defaultLocation.latitude + distance * math.cos(angle),
          _defaultLocation.longitude + distance * math.sin(angle),
        );
        print('📍 Hotel ${hotel.id}: Using fallback position ${position.latitude}, ${position.longitude}');
      }

      hotelPositions.add(position);

      final markerId = MarkerId('hotel_${hotel.id}');

      // Create custom marker with hotel icon
      BitmapDescriptor markerIcon;
      try {
        markerIcon = await _createHotelMarker(hotel);
      } catch (e) {
        print('⚠️ Error creating custom marker for hotel ${hotel.id}: $e');
        markerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      }

      final marker = Marker(
        markerId: markerId,
        position: position,
        icon: markerIcon,
        onTap: () {
          print('📍 Marker tapped: ${hotel.ten}');
          _onMarkerTapped(hotel);
        },
        infoWindow: InfoWindow(
          title: hotel.ten,
          snippet: hotel.diaChi ?? hotel.tenViTri ?? 'Địa chỉ không xác định',
        ),
      );

      markers.add(marker);
    }

    print('✅ Created ${markers.length} markers');

    setState(() {
      _markers = markers;
    });

    // Fit all markers in view after a delay to ensure map is ready
    if (markers.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted && _mapController != null) {
          _fitMarkersInView();
        }
      });
    }
  }

  Future<BitmapDescriptor> _createHotelMarker(Hotel hotel) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Marker dimensions
    const double width = 60.0;
    const double height = 60.0;

    // Draw background circle
    final paint = Paint()
      ..color = const Color(0xFF003580) // Agoda blue
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(width / 2, height / 2),
      width / 2,
      paint,
    );

    // Draw white border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawCircle(
      Offset(width / 2, height / 2),
      width / 2 - 1.5,
      borderPaint,
    );

    // Draw hotel icon (simplified)
    final iconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Draw a simple hotel icon shape
    final path = Path();
    // Draw a house-like shape
    path.moveTo(width / 2, height * 0.25);
    path.lineTo(width * 0.3, height * 0.4);
    path.lineTo(width * 0.3, height * 0.7);
    path.lineTo(width * 0.7, height * 0.7);
    path.lineTo(width * 0.7, height * 0.4);
    path.close();
    canvas.drawPath(path, iconPaint);

    // Convert to image
    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final uint8List = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(uint8List);
  }

  void _onMarkerTapped(Hotel hotel) {
    setState(() {
      _selectedHotel = hotel;
    });
    
    // Animate camera to marker
    final marker = _markers.firstWhere(
      (m) => m.markerId.value == 'hotel_${hotel.id}',
      orElse: () => _markers.first,
    );
    
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(marker.position, 16.0),
      );
    }
  }

  void _onMapCreated(GoogleMapController controller) async {
    try {
      _mapController = controller;
      print('✅ Google Maps controller created successfully');

      // Wait a bit for map to fully initialize
      await Future.delayed(const Duration(milliseconds: 800));
      
      if (!mounted) return;
      
      // Check if controller is still valid
      if (_mapController == null) {
        print('⚠️ Map controller is null after delay');
        return;
      }
      
      // Move camera to show all markers
      if (_markers.isNotEmpty) {
        try {
          // Use a timeout for camera operations
          _fitMarkersInView();
          // Wait a bit to ensure camera update completes
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          print('⚠️ Error fitting markers in view: $e');
          // Fallback: center on first marker
          if (_markers.isNotEmpty && _mapController != null) {
            try {
              await _mapController!.animateCamera(
                CameraUpdate.newLatLngZoom(_markers.first.position, 13.0),
              );
            } catch (e2) {
              print('⚠️ Error centering on marker: $e2');
            }
          }
        }
      } else {
        // If no markers, center on default location or first hotel location
        LatLng targetLocation = _defaultLocation;
        if (widget.hotels.isNotEmpty) {
          final firstHotel = widget.hotels.first;
          final address = firstHotel.diaChi ?? firstHotel.tenViTri ?? firstHotel.tenTinhThanh ?? '';
          if (address.isNotEmpty) {
            for (var entry in _cityLocations.entries) {
              if (address.contains(entry.key)) {
                targetLocation = entry.value;
                break;
              }
            }
          }
        }
        try {
          await _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(targetLocation, 13.0),
          );
        } catch (e) {
          print('⚠️ Error centering on default location: $e');
        }
      }
      
      // Hide loading after map is ready
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('❌ Error in onMapCreated: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _errorMessage = 'Không thể tải bản đồ. Vui lòng kiểm tra:\n- Kết nối internet\n- Google Play Services\n- API key Google Maps';
          _isLoading = false;
        });
      }
    }
  }

  void _fitMarkersInView() {
    if (_markers.isEmpty || _mapController == null) return;

    double minLat = _markers.first.position.latitude;
    double maxLat = _markers.first.position.latitude;
    double minLng = _markers.first.position.longitude;
    double maxLng = _markers.first.position.longitude;

    for (final marker in _markers) {
      minLat = math.min(minLat, marker.position.latitude);
      maxLat = math.max(maxLat, marker.position.latitude);
      minLng = math.min(minLng, marker.position.longitude);
      maxLng = math.max(maxLng, marker.position.longitude);
    }

    // Add padding
    final latPadding = (maxLat - minLat) * 0.1;
    final lngPadding = (maxLng - minLng) * 0.1;

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat - latPadding, minLng - lngPadding),
          northeast: LatLng(maxLat + latPadding, maxLng + lngPadding),
        ),
        100.0, // padding in pixels
      ),
    );
  }

  void _goToMyLocation() async {
    if (_currentPosition != null && _mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          15.0,
        ),
      );
    } else {
      // Request location again
      await _getCurrentLocation();
      if (_currentPosition != null && _mapController != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            15.0,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể lấy vị trí hiện tại'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _toggleToListView() {
    Navigator.pop(context);
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
    // Calculate initial position
    LatLng initialPosition = _defaultLocation;
    if (widget.hotels.isNotEmpty) {
      // Try to get location from first hotel
      final firstHotel = widget.hotels.first;
      final address = firstHotel.diaChi ?? firstHotel.tenViTri ?? firstHotel.tenTinhThanh ?? '';
      if (address.isNotEmpty) {
        for (var entry in _cityLocations.entries) {
          if (address.contains(entry.key)) {
            initialPosition = entry.value;
            break;
          }
        }
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Google Map - Wrap in error boundary
          _errorMessage == null
              ? Builder(
                  builder: (context) {
                    try {
                      return GoogleMap(
                        onMapCreated: _onMapCreated,
                        initialCameraPosition: CameraPosition(
                          target: initialPosition,
                          zoom: 13.0,
                        ),
                        markers: _markers,
                        myLocationEnabled: false, // Disable to avoid permission issues
                        myLocationButtonEnabled: false,
                        mapType: MapType.normal,
                        zoomControlsEnabled: true,
                        compassEnabled: true,
                        mapToolbarEnabled: false,
                        buildingsEnabled: false, // Disable to reduce rendering issues
                        trafficEnabled: false,
                        liteModeEnabled: false,
                        onTap: (_) {
                          // Hide info card when tapping on map
                          setState(() {
                            _selectedHotel = null;
                          });
                        },
                        onCameraMove: (position) {
                          // Camera moved
                        },
                        onCameraIdle: () {
                          // Camera stopped moving
                        },
                      );
                    } catch (e, stackTrace) {
                      print('❌ Error creating GoogleMap widget: $e');
                      print('Stack trace: $stackTrace');
                      // Schedule error handling in next frame
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            _errorMessage = 'Không thể khởi tạo bản đồ. Vui lòng kiểm tra cấu hình Google Maps API.';
                            _isLoading = false;
                          });
                        }
                      });
                      return _buildMapErrorFallback();
                    }
                  },
                )
              : _buildMapErrorFallback(),
          
          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.white.withOpacity(0.9),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Color(0xFF003580),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Đang tải bản đồ...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Error message
          if (_errorMessage != null && !_isLoading)
            Positioned(
              top: MediaQuery.of(context).padding.top + 80,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.red[700]),
                      onPressed: () {
                        setState(() {
                          _errorMessage = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

          // Header
          Positioned(top: 0, left: 0, right: 0, child: _buildHeader()),

          // My Location Button
          Positioned(
            right: 16,
            bottom: _selectedHotel != null ? 200 : 100,
            child: _buildMyLocationButton(),
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
          // Back Button
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.black87,
                size: 24,
              ),
            ),
          ),

          // Title
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

          // List View Toggle Button
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF003580), // Agoda blue
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF003580).withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: IconButton(
              onPressed: _toggleToListView,
              icon: const Icon(Icons.list, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyLocationButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: IconButton(
        onPressed: _goToMyLocation,
        icon: const Icon(
          Icons.my_location,
          color: Color(0xFF003580),
          size: 24,
        ),
      ),
    );
  }

  Widget _buildMapErrorFallback() {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.map_outlined,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 24),
              Text(
                'Không thể tải bản đồ',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _errorMessage = null;
                    _isLoading = true;
                  });
                  _initializeMap();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003580),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Show hotel info even when map fails
              if (widget.hotels.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thông tin khách sạn',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...widget.hotels.map((hotel) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  hotel.ten,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  hotel.diaChi ?? hotel.tenViTri ?? 'Địa chỉ không xác định',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
