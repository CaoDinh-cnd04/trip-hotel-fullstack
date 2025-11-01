import 'package:flutter/material.dart';
import 'package:hotel_mobile/data/services/hotel_registration_service.dart';
import 'package:dio/dio.dart';
import 'package:hotel_mobile/core/constants/app_constants.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

/// Model cho Room Type trong form đăng ký
class RoomTypeData {
  String id; // Unique ID for editing
  String name;
  String type; // Standard, Deluxe, Suite, Family, Presidential, Executive
  double pricePerNight;
  double area;
  int quantity;
  String description;
  List<File> images; // Local images
  List<String> amenities; // Room amenities

  RoomTypeData({
    required this.id,
    required this.name,
    required this.type,
    required this.pricePerNight,
    required this.area,
    required this.quantity,
    required this.description,
    required this.images,
    this.amenities = const [],
  });
}

class HotelRegistrationScreen extends StatefulWidget {
  const HotelRegistrationScreen({super.key});

  @override
  State<HotelRegistrationScreen> createState() => _HotelRegistrationScreenState();
}

class _HotelRegistrationScreenState extends State<HotelRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hotelRegistrationService = HotelRegistrationService();
  final _imagePicker = ImagePicker();

  // ===== STEP 1: Basic Info Controllers =====
  final _ownerNameController = TextEditingController();
  final _ownerEmailController = TextEditingController();
  final _ownerPhoneController = TextEditingController();
  final _hotelNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _districtController = TextEditingController();
  final _descriptionController = TextEditingController();

  // ===== STEP 1: State Variables =====
  int _currentStep = 0;
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _provinces = [];
  Map<String, dynamic>? _selectedProvince;
  String _selectedHotelType = 'hotel';
  int _selectedStarRating = 3;

  // ===== HOTEL AMENITIES =====
  final List<Map<String, dynamic>> _hotelAmenities = [
    {'id': 'wifi', 'name': 'WiFi miễn phí', 'icon': Icons.wifi, 'selected': false},
    {'id': 'pool', 'name': 'Hồ bơi', 'icon': Icons.pool, 'selected': false},
    {'id': 'parking', 'name': 'Bãi đậu xe', 'icon': Icons.local_parking, 'selected': false},
    {'id': 'gym', 'name': 'Phòng gym', 'icon': Icons.fitness_center, 'selected': false},
    {'id': 'restaurant', 'name': 'Nhà hàng', 'icon': Icons.restaurant, 'selected': false},
    {'id': 'bar', 'name': 'Quầy bar', 'icon': Icons.local_bar, 'selected': false},
    {'id': 'spa', 'name': 'Spa', 'icon': Icons.spa, 'selected': false},
    {'id': 'airport_shuttle', 'name': 'Đưa đón sân bay', 'icon': Icons.airport_shuttle, 'selected': false},
    {'id': 'laundry', 'name': 'Giặt là', 'icon': Icons.local_laundry_service, 'selected': false},
    {'id': 'room_service', 'name': 'Dịch vụ phòng 24/7', 'icon': Icons.room_service, 'selected': false},
    {'id': 'concierge', 'name': 'Lễ tân 24/7', 'icon': Icons.person, 'selected': false},
    {'id': 'elevator', 'name': 'Thang máy', 'icon': Icons.elevator, 'selected': false},
  ];
  final TextEditingController _customHotelAmenityController = TextEditingController();
  final List<String> _customHotelAmenities = [];

  // ===== ROOM AMENITIES =====
  final List<Map<String, dynamic>> _roomAmenities = [
    {'id': 'ac', 'name': 'Điều hòa', 'icon': Icons.ac_unit, 'selected': false},
    {'id': 'tv', 'name': 'TV', 'icon': Icons.tv, 'selected': false},
    {'id': 'minibar', 'name': 'Minibar', 'icon': Icons.local_bar, 'selected': false},
    {'id': 'balcony', 'name': 'Ban công', 'icon': Icons.balcony, 'selected': false},
    {'id': 'sea_view', 'name': 'View biển', 'icon': Icons.beach_access, 'selected': false},
    {'id': 'city_view', 'name': 'View thành phố', 'icon': Icons.location_city, 'selected': false},
    {'id': 'bathtub', 'name': 'Bồn tắm', 'icon': Icons.bathtub, 'selected': false},
    {'id': 'hair_dryer', 'name': 'Máy sấy tóc', 'icon': Icons.dry, 'selected': false},
    {'id': 'safe', 'name': 'Két an toàn', 'icon': Icons.lock, 'selected': false},
    {'id': 'kettle', 'name': 'Ấm đun nước', 'icon': Icons.coffee_maker, 'selected': false},
  ];

  // ===== STEP 2: Hotel Images =====
  List<File> _hotelImages = [];

  // ===== STEP 2: Room Types =====
  List<RoomTypeData> _roomTypes = [];

  @override
  void initState() {
    super.initState();
    _loadProvinces();
  }

  @override
  void dispose() {
    _ownerNameController.dispose();
    _ownerEmailController.dispose();
    _ownerPhoneController.dispose();
    _hotelNameController.dispose();
    _addressController.dispose();
    _districtController.dispose();
    _descriptionController.dispose();
    _customHotelAmenityController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Load danh sách tỉnh/thành phố từ API
  /// Fallback về danh sách mặc định nếu lỗi
  Future<void> _loadProvinces() async {
    try {
      final dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));
      final response = await dio.get('/api/v2/reference/countries/1/provinces');

      if (mounted && response.data['success'] == true) {
        setState(() {
          _provinces = List<Map<String, dynamic>>.from(response.data['data']);
        });
      }
    } catch (e) {
      print('❌ Lỗi load provinces: $e');
      // Fallback data
      if (mounted) {
        setState(() {
          _provinces = [
            {'id': 1, 'ten': 'Hà Nội'}, {'id': 2, 'ten': 'Hồ Chí Minh'}, {'id': 3, 'ten': 'Đà Nẵng'},
            {'id': 4, 'ten': 'Vũng Tàu'}, {'id': 5, 'ten': 'Nha Trang'}, {'id': 6, 'ten': 'Huế'},
            {'id': 7, 'ten': 'Đà Lạt'}, {'id': 8, 'ten': 'Phú Quốc'}, {'id': 9, 'ten': 'Cần Thơ'},
            {'id': 10, 'ten': 'Hải Phòng'}, {'id': 11, 'ten': 'Bình Dương'}, {'id': 12, 'ten': 'Bình Thuận'},
          ];
        });
      }
    }
  }

  // ===== IMAGE PICKER: Hotel Images =====
  /// Chọn nhiều ảnh khách sạn từ thư viện
  Future<void> _pickHotelImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _hotelImages.addAll(images.map((xFile) => File(xFile.path)));
        });
      }
    } catch (e) {
      _showSnackBar('Lỗi chọn ảnh: ${e.toString()}', isError: true);
    }
  }

  /// Xóa ảnh khách sạn theo index
  void _removeHotelImage(int index) {
    setState(() {
      _hotelImages.removeAt(index);
    });
  }

  // ===== ROOM TYPE MANAGEMENT =====
  /// Hiển thị dialog thêm/sửa loại phòng
  /// [editingRoom] nếu không null thì là chế độ edit
  void _showAddRoomTypeDialog({RoomTypeData? editingRoom}) {
    final isEditing = editingRoom != null;
    
    final nameController = TextEditingController(text: editingRoom?.name ?? '');
    final priceController = TextEditingController(text: editingRoom?.pricePerNight.toString() ?? '');
    final areaController = TextEditingController(text: editingRoom?.area.toString() ?? '');
    final quantityController = TextEditingController(text: editingRoom?.quantity.toString() ?? '');
    final descController = TextEditingController(text: editingRoom?.description ?? '');
    
    String selectedType = editingRoom?.type ?? 'standard';
    List<File> roomImages = List.from(editingRoom?.images ?? []);
    List<String> selectedRoomAmenities = List.from(editingRoom?.amenities ?? []);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(isEditing ? 'Chỉnh sửa loại phòng' : 'Thêm loại phòng mới'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tên phòng
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên phòng (*)',
                      hintText: 'VD: Deluxe Ocean View',
                      prefixIcon: Icon(Icons.bed),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Loại phòng
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Loại phòng (*)',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'standard', child: Text('Standard')),
                      DropdownMenuItem(value: 'deluxe', child: Text('Deluxe')),
                      DropdownMenuItem(value: 'suite', child: Text('Suite')),
                      DropdownMenuItem(value: 'family', child: Text('Family')),
                      DropdownMenuItem(value: 'presidential', child: Text('Presidential')),
                      DropdownMenuItem(value: 'executive', child: Text('Executive')),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedType = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // Giá
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Giá mỗi đêm (VND) (*)',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Diện tích
                  TextField(
                    controller: areaController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Diện tích (m²) (*)',
                      prefixIcon: Icon(Icons.square_foot),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Số lượng
                  TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Số lượng phòng (*)',
                      prefixIcon: Icon(Icons.numbers),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Mô tả
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả',
                      hintText: 'Mô tả chi tiết về phòng...',
                      prefixIcon: Icon(Icons.description),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Room amenities
                  _buildRoomAmenitiesSelector(
                    selectedRoomAmenities,
                    (newAmenities) {
                      setDialogState(() {
                        selectedRoomAmenities = newAmenities;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Upload hình ảnh phòng
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              final List<XFile> images = await _imagePicker.pickMultiImage();
                              if (images.isNotEmpty) {
                                setDialogState(() {
                                  roomImages.addAll(images.map((xFile) => File(xFile.path)));
                                });
                              }
                            } catch (e) {
                              _showSnackBar('Lỗi chọn ảnh: ${e.toString()}', isError: true);
                            }
                          },
                          icon: const Icon(Icons.add_photo_alternate),
                          label: const Text('Thêm ảnh phòng'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Preview ảnh phòng
                  if (roomImages.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: roomImages.asMap().entries.map((entry) {
                        final index = entry.key;
                        final image = entry.value;
                        return Stack(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: FileImage(image),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: () {
                                  setDialogState(() {
                                    roomImages.removeAt(index);
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  
                  if (roomImages.isEmpty)
                    const Text(
                      'Chưa có ảnh nào (Tối thiểu 2 ảnh)',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Validation
                  if (nameController.text.trim().isEmpty) {
                    _showSnackBar('Vui lòng nhập tên phòng', isError: true);
                    return;
                  }
                  final price = double.tryParse(priceController.text.trim());
                  if (price == null || price <= 0) {
                    _showSnackBar('Giá phòng phải lớn hơn 0', isError: true);
                    return;
                  }
                  final area = double.tryParse(areaController.text.trim());
                  if (area == null || area <= 0) {
                    _showSnackBar('Diện tích phải lớn hơn 0', isError: true);
                    return;
                  }
                  final quantity = int.tryParse(quantityController.text.trim());
                  if (quantity == null || quantity <= 0) {
                    _showSnackBar('Số lượng phải lớn hơn 0', isError: true);
                    return;
                  }
                  if (roomImages.length < 2) {
                    _showSnackBar('Vui lòng thêm ít nhất 2 ảnh phòng', isError: true);
                    return;
                  }

                  // Check duplicate name (if not editing)
                  if (!isEditing) {
                    final duplicate = _roomTypes.any((room) => 
                      room.name.toLowerCase() == nameController.text.trim().toLowerCase()
                    );
                    if (duplicate) {
                      _showSnackBar('Tên phòng đã tồn tại', isError: true);
                      return;
                    }
                  }

                  setState(() {
                    if (isEditing) {
                      // Update existing
                      final index = _roomTypes.indexWhere((r) => r.id == editingRoom.id);
                      _roomTypes[index] = RoomTypeData(
                        id: editingRoom.id,
                        name: nameController.text.trim(),
                        type: selectedType,
                        pricePerNight: price,
                        area: area,
                        quantity: quantity,
                        description: descController.text.trim(),
                        images: roomImages,
                        amenities: selectedRoomAmenities,
                      );
                    } else {
                      // Add new
                      _roomTypes.add(RoomTypeData(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: nameController.text.trim(),
                        type: selectedType,
                        pricePerNight: price,
                        area: area,
                        quantity: quantity,
                        description: descController.text.trim(),
                        images: roomImages,
                        amenities: selectedRoomAmenities,
                      ));
                    }
                  });

                  Navigator.pop(context);
                  _showSnackBar(isEditing ? 'Đã cập nhật phòng' : 'Đã thêm phòng mới');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: Text(isEditing ? 'Cập nhật' : 'Thêm'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Xóa loại phòng khỏi danh sách
  void _removeRoomType(String id) {
    setState(() {
      _roomTypes.removeWhere((room) => room.id == id);
    });
    _showSnackBar('Đã xóa loại phòng');
  }

  // ===== SUBMIT REGISTRATION =====
  /// Gửi form đăng ký khách sạn lên server
  /// Validate tất cả dữ liệu trước khi gửi
  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedProvince == null) {
      _showSnackBar('Vui lòng chọn tỉnh/thành phố', isError: true);
      return;
    }
    if (_hotelImages.length < 3) {
      _showSnackBar('Vui lòng thêm ít nhất 3 ảnh khách sạn', isError: true);
      return;
    }
    if (_roomTypes.isEmpty) {
      _showSnackBar('Vui lòng thêm ít nhất 1 loại phòng', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Collect selected hotel amenities
      final List<String> selectedHotelAmenities = [
        ..._hotelAmenities
            .where((a) => a['selected'] == true)
            .map((a) => a['name'] as String),
        ..._customHotelAmenities,
      ];

      // Convert room types to backend format
      final List<Map<String, dynamic>> roomsData = _roomTypes.map((room) {
        // Map room type string to loai_phong_id (1-6)
        int roomTypeId = 1; // Default: Standard
        switch (room.type) {
          case 'standard':
            roomTypeId = 1;
            break;
          case 'superior':
            roomTypeId = 2;
            break;
          case 'deluxe':
            roomTypeId = 6;
            break;
          case 'double':
            roomTypeId = 3;
            break;
          case 'family':
            roomTypeId = 4;
            break;
          case 'suite':
            roomTypeId = 5;
            break;
          case 'executive':
            roomTypeId = 2; // Map to Superior
            break;
          case 'presidential':
            roomTypeId = 5; // Map to Suite
            break;
        }

        return {
          'name': room.name,
          'room_type': roomTypeId.toString(), // Backend expects string for loai_phong_id
          'price': room.pricePerNight,
          'area': room.area,
          'quantity': room.quantity,
          'description': room.description,
          'amenities': room.amenities, // Room amenities
          // TODO: Upload images to server and get URLs
          // For now, send number of images
          'image_count': room.images.length,
        };
      }).toList();

      print('📝 Submitting registration with ${roomsData.length} room types');
      print('📸 Hotel images: ${_hotelImages.length}');
      print('🏨 Hotel amenities: ${selectedHotelAmenities.length}');
      
      // ✅ Upload images to server using multipart/form-data
      final registrationData = {
        'owner_name': _ownerNameController.text.trim(),
        'owner_email': _ownerEmailController.text.trim(),
        'owner_phone': _ownerPhoneController.text.trim(),
        'hotel_name': _hotelNameController.text.trim(),
        'hotel_type': _selectedHotelType,
        'address': _addressController.text.trim(),
        'province_id': _selectedProvince!['id'],
        'district': _districtController.text.trim(),
        'description': _descriptionController.text.trim(),
        'star_rating': _selectedStarRating,
        'total_rooms': _roomTypes.fold<int>(0, (sum, room) => sum + room.quantity),
        'rooms': roomsData,
        'hotel_amenities': selectedHotelAmenities,
      };

      final result = await _hotelRegistrationService.createRegistrationWithImages(
        registrationData: registrationData,
        hotelImages: _hotelImages,
        roomImages: _roomTypes.expand((room) => room.images).toList(),
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (result.success) {
          _showSuccessDialog();
        } else {
          _showSnackBar(result.message ?? 'Đăng ký thất bại', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Lỗi: ${e.toString()}', isError: true);
      }
    }
  }

  /// Hiển thị thông báo SnackBar
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Hiển thị dialog thông báo đăng ký thành công
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('Đăng ký thành công!'),
          ],
        ),
        content: const Text(
          'Yêu cầu đăng ký khách sạn của bạn đã được gửi.\n\n'
          'Admin sẽ xem xét và phản hồi trong vòng 24-48 giờ.\n'
          'Sau khi được duyệt, khách sạn và phòng sẽ tự động được lưu vào hệ thống.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close screen
            },
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  /// Xây dựng danh sách các bước (steps) cho Stepper
  List<Step> _buildSteps() {
    return [
      Step(
        title: Text(
          'Thông tin cơ bản',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: _currentStep >= 0 ? Colors.blue[700] : Colors.grey[600],
          ),
        ),
        subtitle: const Text('Nhập thông tin chủ sở hữu và khách sạn'),
        content: _buildStep1Content(),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: Text(
          'Hình ảnh & Phòng',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: _currentStep >= 1 ? Colors.blue[700] : Colors.grey[600],
          ),
        ),
        subtitle: const Text('Upload ảnh và thêm các loại phòng'),
        content: _buildStep2Content(),
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: Text(
          'Xác minh & Duyệt',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: _currentStep >= 2 ? Colors.blue[700] : Colors.grey[600],
          ),
        ),
        subtitle: const Text('Thông tin về quy trình duyệt'),
        content: _buildStep3Content(),
        isActive: _currentStep >= 2,
        state: _currentStep > 2 ? StepState.complete : StepState.indexed,
      ),
    ];
  }

  /// Xây dựng nội dung Bước 1: Thông tin cơ bản
  /// Bao gồm thông tin chủ sở hữu, khách sạn, và tiện nghi
  Widget _buildStep1Content() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Owner Information Card
        Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
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
              _buildSectionHeader('Thông tin chủ sở hữu'),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _ownerNameController,
                label: 'Họ tên chủ sở hữu (*)',
                icon: Icons.person,
                validator: (value) => value!.isEmpty ? 'Vui lòng nhập họ tên' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _ownerEmailController,
                label: 'Email (*)',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Vui lòng nhập email';
                  // Regex đầy đủ cho email validation
                  final emailRegex = RegExp(
                    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
                  );
                  if (!emailRegex.hasMatch(value)) {
                    return 'Email không đúng định dạng (VD: name@gmail.com)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _ownerPhoneController,
                label: 'Số điện thoại (*)',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value!.isEmpty) return 'Vui lòng nhập số điện thoại';
                  if (value.length != 10) return 'Số điện thoại phải có 10 số';
                  return null;
                },
              ),
            ],
          ),
        ),
        // Hotel Information Card
        Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
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
              _buildSectionHeader('Thông tin cơ sở lưu trú'),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _hotelNameController,
                label: 'Tên cơ sở (*)',
                icon: Icons.hotel,
                validator: (value) => value!.isEmpty ? 'Vui lòng nhập tên cơ sở' : null,
              ),
              const SizedBox(height: 16),
              _buildDropdown(
                label: 'Loại hình (*)',
                value: _selectedHotelType,
                icon: Icons.category,
                items: const [
                  {'value': 'hotel', 'label': 'Khách sạn'},
                  {'value': 'resort', 'label': 'Resort'},
                  {'value': 'homestay', 'label': 'Homestay'},
                  {'value': 'apartment', 'label': 'Căn hộ'},
                  {'value': 'villa', 'label': 'Villa'},
                ],
                onChanged: (value) => setState(() => _selectedHotelType = value!),
              ),
              const SizedBox(height: 16),
              _buildStarRating(),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _addressController,
                label: 'Địa chỉ đầy đủ (*)',
                icon: Icons.location_on,
                validator: (value) => value!.isEmpty ? 'Vui lòng nhập địa chỉ' : null,
              ),
              const SizedBox(height: 16),
              _buildProvinceDropdown(),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _districtController,
                label: 'Quận/Huyện',
                icon: Icons.map,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _descriptionController,
                label: 'Mô tả chi tiết (*)',
                icon: Icons.description,
                maxLines: 5,
                validator: (value) => value!.isEmpty ? 'Vui lòng nhập mô tả' : null,
              ),
            ],
          ),
        ),
        // Amenities Card
        Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
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
              _buildSectionHeader('Tiện nghi khách sạn'),
              const SizedBox(height: 20),
              _buildHotelAmenitiesSelector(),
            ],
          ),
        ),
      ],
    );
  }

  /// Xây dựng nội dung Bước 2: Hình ảnh và Phòng
  /// Bao gồm upload ảnh khách sạn và quản lý các loại phòng
  Widget _buildStep2Content() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSectionHeader('Hình ảnh khách sạn'),
        const SizedBox(height: 16),
        
        // Upload hotel images button
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _pickHotelImages,
                icon: const Icon(Icons.add_photo_alternate),
                label: Text('Thêm ảnh khách sạn (${_hotelImages.length}/min 3)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Hotel images preview
        if (_hotelImages.isEmpty)
          _buildInfoCard(
            icon: Icons.info_outline,
            title: 'Chưa có ảnh',
            description: 'Vui lòng thêm ít nhất 3 ảnh khách sạn (bên ngoài, sảnh, tiện ích,...)',
            color: Colors.orange.shade50,
            iconColor: Colors.orange,
          ),

        if (_hotelImages.isNotEmpty)
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _hotelImages.asMap().entries.map((entry) {
              final index = entry.key;
              final image = entry.value;
              return Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: FileImage(image),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeHotelImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),

        const SizedBox(height: 32),
        const Divider(),
        const SizedBox(height: 16),

        // Room Types Section
        _buildSectionHeader('Loại phòng (${_roomTypes.length})'),
        const SizedBox(height: 16),

        // Add room button
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showAddRoomTypeDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Thêm loại phòng mới'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Room types list
        if (_roomTypes.isEmpty)
          _buildInfoCard(
            icon: Icons.warning_amber,
            title: 'Chưa có phòng nào',
            description: 'Vui lòng thêm ít nhất 1 loại phòng để hoàn tất đăng ký',
            color: Colors.red.shade50,
            iconColor: Colors.red,
          ),

        if (_roomTypes.isNotEmpty)
          ..._roomTypes.map((room) => _buildRoomTypeCard(room)).toList(),
      ],
    );
  }

  /// Xây dựng card hiển thị thông tin loại phòng
  /// Bao gồm tên, giá, diện tích, số lượng, tiện nghi, và ảnh
  Widget _buildRoomTypeCard(RoomTypeData room) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    room.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _showAddRoomTypeDialog(editingRoom: room),
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  tooltip: 'Chỉnh sửa',
                ),
                IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Xác nhận xóa'),
                        content: Text('Bạn có chắc muốn xóa phòng "${room.name}"?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Hủy'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              _removeRoomType(room.id);
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            child: const Text('Xóa'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Xóa',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildRoomInfoChip(Icons.category, room.type.toUpperCase()),
                const SizedBox(width: 8),
                _buildRoomInfoChip(Icons.attach_money, '${room.pricePerNight.toStringAsFixed(0)} VND/đêm'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildRoomInfoChip(Icons.square_foot, '${room.area} m²'),
                const SizedBox(width: 8),
                _buildRoomInfoChip(Icons.meeting_room, 'x${room.quantity} phòng'),
              ],
            ),
            if (room.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                room.description,
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
              ),
            ],
            if (room.amenities.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: room.amenities.map((amenity) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Text(
                      amenity,
                      style: const TextStyle(fontSize: 11, color: Colors.green),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 12),
            // Room images preview
            if (room.images.isNotEmpty)
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: room.images.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 80,
                      height: 80,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: FileImage(room.images[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.blue),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  /// Xây dựng nội dung Bước 3: Xác minh và Duyệt
  /// Hiển thị thông tin về quy trình xét duyệt của admin
  Widget _buildStep3Content() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSectionHeader('Xác minh & Duyệt'),
        const SizedBox(height: 16),
        _buildInfoCard(
          icon: Icons.admin_panel_settings,
          title: 'Admin xem xét hồ sơ',
          description: 'Đội ngũ admin của TripHotel sẽ xem xét nội dung (hình ảnh, mô tả, vị trí, giá phòng) để đảm bảo chất lượng và tính chính xác.',
          color: Colors.green.shade50,
          iconColor: Colors.green,
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          icon: Icons.timer,
          title: 'Thời gian xử lý: 24-48 giờ',
          description: 'Chúng tôi sẽ thông báo cho bạn qua email khi hồ sơ được duyệt.',
          color: Colors.orange.shade50,
          iconColor: Colors.orange,
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          icon: Icons.check_circle,
          title: 'Tự động lưu vào SQL Server',
          description: 'Sau khi admin duyệt, khách sạn và tất cả phòng sẽ tự động được tạo trong database và hiển thị công khai trên app.',
          color: Colors.blue.shade50,
          iconColor: Colors.blue,
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          icon: Icons.dashboard,
          title: 'Bảng điều khiển quản lý',
          description: 'Bạn sẽ nhận được quyền truy cập vào dashboard để quản lý đặt phòng, cập nhật giá, trả lời tin nhắn khách hàng.',
          color: Colors.purple.shade50,
          iconColor: Colors.purple,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    try {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            'Đăng ký cơ sở lưu trú',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue[700]!,
                  Colors.blue[500]!,
                ],
              ),
            ),
          ),
          foregroundColor: Colors.white,
        ),
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Stepper(
                              type: StepperType.vertical,
                              currentStep: _currentStep,
                              onStepContinue: () {
                                if (_currentStep < _buildSteps().length - 1) {
                                  // Validate current step
                                  if (_currentStep == 0 && !_formKey.currentState!.validate()) {
                                    return;
                                  }
                                  if (_currentStep == 0 && _selectedProvince == null) {
                                    _showSnackBar('Vui lòng chọn tỉnh/thành phố', isError: true);
                                    return;
                                  }
                                  if (_currentStep == 1 && _hotelImages.length < 3) {
                                    _showSnackBar('Vui lòng thêm ít nhất 3 ảnh khách sạn', isError: true);
                                    return;
                                  }
                                  if (_currentStep == 1 && _roomTypes.isEmpty) {
                                    _showSnackBar('Vui lòng thêm ít nhất 1 loại phòng', isError: true);
                                    return;
                                  }
                                  setState(() => _currentStep += 1);
                                } else {
                                  _submitRegistration();
                                }
                              },
                              onStepCancel: () {
                                if (_currentStep > 0) {
                                  setState(() => _currentStep -= 1);
                                } else {
                                  Navigator.of(context).pop();
                                }
                              },
                              controlsBuilder: (context, details) {
                              return Container(
                                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, -2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    if (_currentStep > 0) ...[
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: details.onStepCancel,
                                          icon: const Icon(Icons.arrow_back, size: 18),
                                          label: const Text('Quay lại'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.blue[700],
                                            side: BorderSide(color: Colors.blue[300]!, width: 1.5),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                    ],
                                    Expanded(
                                      flex: _currentStep > 0 ? 1 : 1,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [Colors.blue[600]!, Colors.blue[700]!],
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.blue.withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: ElevatedButton.icon(
                                          onPressed: details.onStepContinue,
                                          icon: Icon(
                                            _currentStep == _buildSteps().length - 1
                                                ? Icons.check_circle
                                                : Icons.arrow_forward,
                                            size: 20,
                                          ),
                                          label: Text(
                                            _currentStep == _buildSteps().length - 1
                                                ? 'Hoàn tất đăng ký'
                                                : 'Tiếp tục',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            shadowColor: Colors.transparent,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              },
                              steps: _buildSteps(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      );
    } catch (e, stackTrace) {
      print('❌ Lỗi build HotelRegistrationScreen: $e');
      print('Stack trace: $stackTrace');
      return Scaffold(
        appBar: AppBar(
          title: const Text('Đăng ký cơ sở lưu trú'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Lỗi hiển thị màn hình',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    e.toString(),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {});
                    },
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }

  // ===== AMENITIES SELECTOR =====
  /// Xây dựng UI chọn tiện nghi khách sạn
  /// Bao gồm 12 tiện nghi có sẵn và input tùy chỉnh
  Widget _buildHotelAmenitiesSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chọn tiện nghi có sẵn (có thể chọn nhiều):',
          style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _hotelAmenities.map((amenity) {
            final isSelected = amenity['selected'] == true;
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    amenity['selected'] = !isSelected;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [Colors.blue[400]!, Colors.blue[600]!],
                          )
                        : null,
                    color: isSelected ? null : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.blue[700]! : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        amenity['icon'],
                        size: 18,
                        color: isSelected ? Colors.white : Colors.grey[700],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        amenity['name'],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? Colors.white : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Thêm tiện nghi tùy chỉnh',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customHotelAmenityController,
                      style: TextStyle(color: Colors.grey[800], fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'VD: Sân tennis, BBQ ngoài trời...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green[400]!, Colors.green[600]!],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          final text = _customHotelAmenityController.text.trim();
                          if (text.isNotEmpty && !_customHotelAmenities.contains(text)) {
                            setState(() {
                              _customHotelAmenities.add(text);
                              _customHotelAmenityController.clear();
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          child: const Icon(Icons.add, color: Colors.white, size: 22),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_customHotelAmenities.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _customHotelAmenities.map((amenity) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green[400]!, Colors.green[600]!],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      amenity,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _customHotelAmenities.remove(amenity);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  /// Xây dựng UI chọn tiện nghi phòng
  /// [selectedAmenities] danh sách tiện nghi đã chọn
  /// [onChanged] callback khi thay đổi selection
  Widget _buildRoomAmenitiesSelector(
    List<String> selectedAmenities,
    void Function(List<String>) onChanged,
  ) {
    // Tạo bản sao có thể chỉnh sửa của room amenities cho phòng này
    final roomAmenitiesCopy = _roomAmenities.map((a) {
      return {
        'id': a['id'],
        'name': a['name'],
        'icon': a['icon'],
        'selected': selectedAmenities.contains(a['name']),
      };
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tiện nghi trong phòng:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: roomAmenitiesCopy.map((amenity) {
            return FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(amenity['icon'], size: 14),
                  const SizedBox(width: 4),
                  Text(
                    amenity['name'],
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              selected: amenity['selected'],
              onSelected: (selected) {
                if (selected) {
                  selectedAmenities.add(amenity['name']);
                } else {
                  selectedAmenities.remove(amenity['name']);
                }
                onChanged(selectedAmenities);
              },
              selectedColor: Colors.green.shade100,
              checkmarkColor: Colors.green,
            );
          }).toList(),
        ),
      ],
    );
  }

  // ===== UI HELPER WIDGETS =====
  Widget _buildSectionHeader(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.blue[400]!,
                  Colors.blue[600]!,
                ],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: TextStyle(color: Colors.grey[800], fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blue[700], size: 20),
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required IconData icon,
    required List<Map<String, String>> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: DropdownButtonFormField<String>(
        value: value,
        style: TextStyle(color: Colors.grey[800], fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blue[700], size: 20),
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item['value'],
            child: Text(item['label']!),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildProvinceDropdown() {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: DropdownButtonFormField<Map<String, dynamic>>(
        value: _selectedProvince,
        style: TextStyle(color: Colors.grey[800], fontSize: 15),
        decoration: InputDecoration(
          labelText: 'Tỉnh/Thành phố (*)',
          labelStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.location_city, color: Colors.blue[700], size: 20),
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        isExpanded: true,
        items: _provinces.map((province) {
          return DropdownMenuItem<Map<String, dynamic>>(
            value: province,
            child: Text(
              province['ten'] ?? '',
              style: const TextStyle(fontSize: 15),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          );
        }).toList(),
        onChanged: (value) => setState(() => _selectedProvince = value),
        validator: (value) => value == null ? 'Vui lòng chọn tỉnh/thành phố' : null,
      ),
    );
  }

  Widget _buildStarRating() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.star, color: Colors.amber, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'Hạng sao (*)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (index) {
              final star = index + 1;
              final isSelected = _selectedStarRating == star;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => setState(() => _selectedStarRating = star),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: [Colors.amber[400]!, Colors.amber[600]!],
                                )
                              : null,
                          color: isSelected ? null : Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? Colors.amber[700]! : Colors.grey[300]!,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Text(
                          '$star★',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isSelected ? Colors.white : Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
    Color? color,
    Color? iconColor,
  }) {
    return Card(
      color: color ?? Colors.grey.shade50,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor ?? Colors.blue, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
