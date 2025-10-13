import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../data/models/hotel.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'widgets/hotel_info_card.dart';

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

  // Default location (Ho Chi Minh City)
  static const LatLng _defaultLocation = LatLng(10.8231, 106.6297);

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
      await _getCurrentLocation();
      await _createHotelMarkers();
    } catch (e) {
      print('Error initializing map: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied');
        return;
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _createHotelMarkers() async {
    Set<Marker> markers = {};

    for (int i = 0; i < widget.hotels.length; i++) {
      final hotel = widget.hotels[i];

      // Generate mock coordinates around the default location
      final lat = _defaultLocation.latitude + (i * 0.01) - 0.05;
      final lng = _defaultLocation.longitude + ((i % 3) * 0.01) - 0.01;

      final markerId = MarkerId('hotel_${hotel.id}');

      // Create custom marker with price
      final markerIcon = await _createPriceMarker(
        hotel.yeuCauCoc?.toInt() ?? 500000,
      );

      final marker = Marker(
        markerId: markerId,
        position: LatLng(lat, lng),
        icon: markerIcon,
        onTap: () => _onMarkerTapped(hotel),
        infoWindow: InfoWindow(
          title: hotel.ten,
          snippet:
              '${hotel.yeuCauCoc?.toStringAsFixed(0) ?? '500,000'} VND/đêm',
        ),
      );

      markers.add(marker);
    }

    setState(() {
      _markers = markers;
    });
  }

  Future<BitmapDescriptor> _createPriceMarker(int price) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Marker dimensions
    const double width = 100.0;
    const double height = 40.0;
    const double borderRadius = 20.0;

    // Draw background
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.blue[600]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, width, height),
      const Radius.circular(borderRadius),
    );

    canvas.drawRRect(rrect, paint);
    canvas.drawRRect(rrect, borderPaint);

    // Draw price text
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${(price / 1000).toStringAsFixed(0)}K',
        style: TextStyle(
          color: Colors.blue[600],
          fontSize: 12.0,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    final textOffset = Offset(
      (width - textPainter.width) / 2,
      (height - textPainter.height) / 2,
    );
    textPainter.paint(canvas, textOffset);

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
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    // Move camera to show all markers
    if (_markers.isNotEmpty) {
      _fitMarkersInView();
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

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100.0, // padding
      ),
    );
  }

  void _toggleToListView() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Map Widget Area
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition != null
                        ? LatLng(
                            _currentPosition!.latitude,
                            _currentPosition!.longitude,
                          )
                        : _defaultLocation,
                    zoom: 12.0,
                  ),
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  mapType: MapType.normal,
                  zoomControlsEnabled: false,
                  onTap: (_) {
                    // Hide info card when tapping on map
                    setState(() {
                      _selectedHotel = null;
                    });
                  },
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
                onViewDetails: () {
                  Navigator.pushNamed(
                    context,
                    '/property-detail',
                    arguments: {
                      'hotel': _selectedHotel!,
                      'checkInDate': widget.checkInDate,
                      'checkOutDate': widget.checkOutDate,
                      'guestCount': widget.guestCount,
                    },
                  );
                },
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
              Text(
                'Bản đồ',
                style: const TextStyle(
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
              color: Colors.blue[600],
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
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
        onPressed: () async {
          if (_currentPosition != null && _mapController != null) {
            await _mapController!.animateCamera(
              CameraUpdate.newLatLng(
                LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
              ),
            );
          }
        },
        icon: const Icon(Icons.my_location, color: Colors.blue, size: 24),
      ),
    );
  }
}
