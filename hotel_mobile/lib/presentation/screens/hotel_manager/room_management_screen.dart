import 'package:flutter/material.dart';
import '../../../data/services/booking_service.dart';
import '../../../data/services/api_service.dart';
import '../../../data/models/image_model.dart';
import '../../../data/models/room.dart';
import '../../../data/services/image_upload_service.dart';
import '../../widgets/image_picker_widget.dart';
import '../../widgets/image_display_widget.dart';

class RoomManagementScreen extends StatefulWidget {
  const RoomManagementScreen({super.key});

  @override
  State<RoomManagementScreen> createState() => _RoomManagementScreenState();
}

class _RoomManagementScreenState extends State<RoomManagementScreen> {
  final BookingService _bookingService = BookingService();
  final ApiService _apiService = ApiService();
  final ImageUploadService _imageService = ImageUploadService();
  List<Room> _rooms = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _imageService.initialize();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Sử dụng hotel ID mặc định cho hotel manager (có thể thay đổi sau)
      final roomsResponse = await _bookingService.getRooms(1);
      setState(() {
        if (roomsResponse.success && roomsResponse.data != null) {
          _rooms = roomsResponse.data!;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Quản lý Phòng',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _showAddRoomDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadRooms,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorWidget()
          : _buildRoomsGrid(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Có lỗi xảy ra',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Không thể tải dữ liệu',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadRooms, child: const Text('Thử lại')),
        ],
      ),
    );
  }

  Widget _buildRoomsGrid() {
    if (_rooms.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.room_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Chưa có phòng nào',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRooms,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: _rooms.length,
        itemBuilder: (context, index) {
          final room = _rooms[index];
          return _buildRoomCard(room);
        },
      ),
    );
  }

  Widget _buildRoomCard(Room room) {
    final roomNumber = room.soPhong;
    final roomType = room.tenLoaiPhong ?? 'N/A';
    final price = room.giaPhong ?? 0.0;
    final status = room.tinhTrang ? 'available' : 'occupied';
    final imageUrls = room.hinhAnhPhong ?? [];
    final primaryImageUrl = imageUrls.isNotEmpty ? imageUrls.first : null;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showRoomDetail(room),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Room image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  color: Colors.grey[200],
                ),
                child: primaryImageUrl != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: Image.network(
                          primaryImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildPlaceholderImage(),
                        ),
                      )
                    : _buildPlaceholderImage(),
              ),
            ),
            // Room info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Phòng $roomNumber',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getStatusText(status),
                            style: TextStyle(
                              color: _getStatusColor(status),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      roomType,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${price.toStringAsFixed(0)} VNĐ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) => _handleRoomAction(value, room),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 16),
                                  SizedBox(width: 8),
                                  Text('Chỉnh sửa'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete,
                                    size: 16,
                                    color: Colors.red,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Xóa',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          child: const Icon(Icons.more_vert, size: 16),
                        ),
                      ],
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

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: const Center(
        child: Icon(Icons.room, size: 48, color: Colors.grey),
      ),
    );
  }

  void _showRoomDetail(Room room) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
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
              const SizedBox(height: 20),
              // Title
              Text(
                'Chi tiết phòng',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Số phòng', room.soPhong),
                      _buildDetailRow('Loại phòng', room.tenLoaiPhong ?? 'N/A'),
                      _buildDetailRow(
                        'Giá',
                        '${room.giaPhong?.toStringAsFixed(0) ?? '0'} VNĐ',
                      ),
                      _buildDetailRow(
                        'Trạng thái',
                        _getStatusText(room.tinhTrang ? 'available' : 'occupied'),
                      ),

                      // Room images section
                      if (room.hinhAnhPhong != null &&
                          room.hinhAnhPhong!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Hình ảnh (${room.hinhAnhPhong!.length})',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: room.hinhAnhPhong!.length,
                            itemBuilder: (context, index) {
                              final imageUrl = room.hinhAnhPhong![index];
                              return Container(
                                width: 120,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              color: Colors.grey[200],
                                              child: const Icon(
                                                Icons.error,
                                                color: Colors.red,
                                              ),
                                            ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      _buildDetailRow(
                        'Mô tả',
                        room.moTa ?? 'Không có mô tả',
                      ),
                      _buildDetailRow(
                        'Sức chứa',
                        '${room.sucChua ?? 2} khách',
                      ),
                    ],
                  ),
                ),
              ),
              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showEditRoomDialog(room);
                      },
                      child: const Text('Chỉnh sửa'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Đóng'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddRoomDialog() {
    showDialog(
      context: context,
      builder: (context) => _RoomDialog(
        onSave: (roomData) async {
          await _createRoom(roomData);
        },
      ),
    );
  }

  Future<void> _createRoom(Map<String, dynamic> roomData) async {
    try {
      // Convert to Room object
      final room = Room(
        id: 0, // Will be assigned by backend
        soPhong: roomData['roomNumber'] ?? '',
        loaiPhongId: roomData['roomTypeId'] ?? 1,
        khachSanId: roomData['hotelId'] ?? 1,
        tinhTrang: (roomData['status'] ?? 'available') == 'available',
        moTa: roomData['description'] ?? '',
        sucChua: roomData['guestCount'] ?? 2,
        giaPhong: (roomData['price'] ?? 0.0).toDouble(),
        hinhAnhPhong: List<String>.from(roomData['images'] ?? []),
      );

      final response = await _apiService.createRoom(room);

      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thêm phòng thành công')),
          );
          _loadRooms(); // Reload rooms
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Lỗi: ${response.message}')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tạo phòng: $e')));
      }
    }
  }

  void _showEditRoomDialog(Room room) {
    showDialog(
      context: context,
      builder: (context) => _RoomDialog(
        room: room,
        onSave: (roomData) async {
          await _updateRoom(room.id!, roomData);
        },
      ),
    );
  }

  Future<void> _updateRoom(int roomId, Map<String, dynamic> roomData) async {
    try {
      // Convert to Room object
      final room = Room(
        id: roomId,
        soPhong: roomData['roomNumber'] ?? '',
        loaiPhongId: roomData['roomTypeId'] ?? 1,
        khachSanId: roomData['hotelId'] ?? 1,
        tinhTrang: (roomData['status'] ?? 'available') == 'available',
        moTa: roomData['description'] ?? '',
        sucChua: roomData['guestCount'] ?? 2,
        giaPhong: (roomData['price'] ?? 0.0).toDouble(),
        hinhAnhPhong: List<String>.from(roomData['images'] ?? []),
      );

      final response = await _apiService.updateRoom(room);

      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật phòng thành công')),
          );
          _loadRooms(); // Reload rooms
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Lỗi: ${response.message}')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi cập nhật phòng: $e')));
      }
    }
  }

  void _handleRoomAction(String action, Room room) {
    switch (action) {
      case 'edit':
        _showEditRoomDialog(room);
        break;
      case 'delete':
        _showDeleteConfirmation(room);
        break;
    }
  }

  void _showDeleteConfirmation(Room room) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa phòng ${room.soPhong}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteRoom(room.id!);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRoom(int roomId) async {
    try {
      final response = await _apiService.deleteRoom(roomId);

      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Xóa phòng thành công')));
          _loadRooms(); // Reload rooms
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Lỗi: ${response.message}')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi xóa phòng: $e')));
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'available':
        return Colors.green;
      case 'occupied':
        return Colors.red;
      case 'maintenance':
        return Colors.orange;
      case 'cleaning':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'available':
        return 'Trống';
      case 'occupied':
        return 'Có khách';
      case 'maintenance':
        return 'Bảo trì';
      case 'cleaning':
        return 'Dọn dẹp';
      default:
        return 'Không xác định';
    }
  }
}

class _RoomDialog extends StatefulWidget {
  final Room? room;
  final Function(Map<String, dynamic>) onSave;

  const _RoomDialog({this.room, required this.onSave});

  @override
  State<_RoomDialog> createState() => _RoomDialogState();
}

class _RoomDialogState extends State<_RoomDialog> {
  final _formKey = GlobalKey<FormState>();
  final _roomNumberController = TextEditingController();
  final _roomTypeController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amenitiesController = TextEditingController();
  String _selectedStatus = 'available';
  List<ImageModel> _roomImages = [];

  @override
  void initState() {
    super.initState();
    if (widget.room != null) {
      _roomNumberController.text = widget.room!.soPhong;
      _roomTypeController.text = widget.room!.tenLoaiPhong ?? '';
      _priceController.text = widget.room!.giaPhong?.toString() ?? '';
      _descriptionController.text = widget.room!.moTa ?? '';
      _amenitiesController.text = '';
      _selectedStatus = widget.room!.tinhTrang ? 'available' : 'occupied';
    }
  }

  @override
  void dispose() {
    _roomNumberController.dispose();
    _roomTypeController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _amenitiesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.room == null ? 'Thêm phòng mới' : 'Chỉnh sửa phòng'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _roomNumberController,
                decoration: const InputDecoration(
                  labelText: 'Số phòng',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập số phòng';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _roomTypeController,
                decoration: const InputDecoration(
                  labelText: 'Loại phòng',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập loại phòng';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Giá phòng (VNĐ)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập giá phòng';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Vui lòng nhập số hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Trạng thái',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'available', child: Text('Trống')),
                  DropdownMenuItem(value: 'occupied', child: Text('Có khách')),
                  DropdownMenuItem(
                    value: 'maintenance',
                    child: Text('Bảo trì'),
                  ),
                  DropdownMenuItem(value: 'cleaning', child: Text('Dọn dẹp')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Mô tả',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amenitiesController,
                decoration: const InputDecoration(
                  labelText: 'Tiện ích',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              // Image upload section
              ImagePickerWidget(
                title: 'Ảnh phòng',
                description: 'Tải lên ảnh của phòng (tối đa 5 ảnh)',
                category: 'room',
                entityType: 'room',
                entityId: widget.room?.id?.toString(),
                allowMultiple: true,
                maxWidth: 1200,
                maxHeight: 800,
                quality: 85,
                onImageUploaded: (image) {
                  setState(() {
                    _roomImages.add(image);
                  });
                },
                onError: (error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi tải ảnh: $error'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
              ),
              if (_roomImages.isNotEmpty) ...[
                const SizedBox(height: 16),
                ImageGalleryWidget(
                  images: _roomImages,
                  crossAxisCount: 3,
                  showInfo: true,
                  showDeleteButton: true,
                  onImageDelete: (image) {
                    setState(() {
                      _roomImages.remove(image);
                    });
                  },
                  onImageTap: (image) {
                    ImageViewerDialog.show(
                      context,
                      images: _roomImages,
                      initialIndex: _roomImages.indexOf(image),
                      title: 'Ảnh phòng',
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _saveRoom,
          child: Text(widget.room == null ? 'Thêm' : 'Cập nhật'),
        ),
      ],
    );
  }

  void _saveRoom() {
    if (_formKey.currentState!.validate()) {
      final roomData = {
        'roomNumber': _roomNumberController.text,
        'roomType': _roomTypeController.text,
        'price': double.parse(_priceController.text),
        'status': _selectedStatus,
        'description': _descriptionController.text,
        'amenities': _amenitiesController.text,
        'images': _roomImages.map((image) => image.id).toList(),
        'imageUrls': _roomImages.map((image) => image.url).toList(),
      };

      widget.onSave(roomData);
      Navigator.pop(context);
    }
  }
}
