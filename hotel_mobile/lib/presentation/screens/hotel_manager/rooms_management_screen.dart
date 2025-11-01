import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/services/hotel_manager_service.dart';
import '../../../data/models/hotel_manager_models.dart';

class RoomsManagementScreen extends StatefulWidget {
  final HotelManagerService hotelManagerService;

  const RoomsManagementScreen({
    super.key,
    required this.hotelManagerService,
  });

  @override
  State<RoomsManagementScreen> createState() => _RoomsManagementScreenState();
}

class _RoomsManagementScreenState extends State<RoomsManagementScreen> {
  List<Room> _rooms = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final roomsData = await widget.hotelManagerService.getHotelRooms();
      setState(() {
        _rooms = roomsData.map((data) => Room.fromJson(data)).toList();
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
      appBar: AppBar(
        title: const Text('Quản lý phòng'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRooms,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRoomDialog,
        backgroundColor: Colors.blue[700],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text('Lỗi: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadRooms,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_rooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bed_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Chưa có phòng nào',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Nhấn nút + để thêm phòng mới',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRooms,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _rooms.length,
        itemBuilder: (context, index) {
          final room = _rooms[index];
          return _buildRoomCard(room);
        },
      ),
    );
  }

  Widget _buildRoomCard(Room room) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Room image
            if (room.hinhAnh != null && room.hinhAnh!.isNotEmpty) ...[
              Container(
                height: 150,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    room.hinhAnh!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.bed, size: 48, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ],
            
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Phòng ${room.soPhong}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        room.tenLoaiPhong,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: room.trangThai == 'Trống' ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    room.trangThai == 'Trống' ? 'Trống' : 'Đã thuê',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.bed, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${room.soGiuong} giường'),
                const SizedBox(width: 16),
                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${room.soNguoiMax} người'),
                const Spacer(),
                Text(
                  '${_formatCurrency(room.giaPhong)}/đêm',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            if (room.moTa.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                room.moTa,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showEditRoomDialog(room),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Sửa'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue[700],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showDeleteRoomDialog(room),
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Xóa'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showUploadImagesDialog(room),
                icon: const Icon(Icons.add_photo_alternate, size: 16),
                label: const Text('Thêm ảnh'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}đ';
  }

  void _showAddRoomDialog() {
    showDialog(
      context: context,
      builder: (context) => _RoomFormDialog(
        hotelManagerService: widget.hotelManagerService,
        onRoomAdded: () async {
          await _loadRooms();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã thêm phòng mới'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      ),
    );
  }

  void _showEditRoomDialog(Room room) {
    showDialog(
      context: context,
      builder: (context) => _RoomFormDialog(
        hotelManagerService: widget.hotelManagerService,
        room: room,
        onRoomAdded: () async {
          await _loadRooms();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã thêm phòng mới'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        onRoomUpdated: () async {
          await _loadRooms();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã cập nhật phòng'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      ),
    );
  }

  void _showDeleteRoomDialog(Room room) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa phòng'),
        content: Text('Bạn có chắc chắn muốn xóa phòng ${room.soPhong}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteRoom(room);
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRoom(Room room) async {
    try {
      await widget.hotelManagerService.deleteRoom(room.maPhong);
      _loadRooms();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xóa phòng ${room.soPhong}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showUploadImagesDialog(Room room) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Thêm ảnh cho phòng ${room.soPhong}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Chụp ảnh'),
              onTap: () async {
                Navigator.pop(context);
                await _pickAndUploadImages(room, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: const Text('Chọn từ thư viện'),
              onTap: () async {
                Navigator.pop(context);
                await _pickAndUploadImages(room, ImageSource.gallery);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadImages(Room room, ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      List<XFile>? images = [];
      
      if (source == ImageSource.camera) {
        final XFile? photo = await picker.pickImage(source: source);
        if (photo != null) images = [photo];
      } else {
        images = await picker.pickMultiImage();
      }
      
      if (images.isEmpty) return;
      
      if (!mounted) return;
      
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      // Upload images
      final imagePaths = images.map((e) => e.path).toList();
      await widget.hotelManagerService.uploadRoomImages(room.maPhong, imagePaths);
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      
      // Reload rooms to show new images
      await _loadRooms();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã upload ${images.length} ảnh'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog if still open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi upload ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _RoomFormDialog extends StatefulWidget {
  final HotelManagerService hotelManagerService;
  final Room? room;
  final Future<void> Function() onRoomAdded;
  final Future<void> Function()? onRoomUpdated;

  const _RoomFormDialog({
    required this.hotelManagerService,
    this.room,
    required this.onRoomAdded,
    this.onRoomUpdated,
  });

  @override
  State<_RoomFormDialog> createState() => _RoomFormDialogState();
}

class _RoomFormDialogState extends State<_RoomFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _soPhongController = TextEditingController();
  final _giaPhongController = TextEditingController();
  final _moTaController = TextEditingController();
  String _trangThai = 'available';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.room != null) {
      _soPhongController.text = widget.room!.soPhong;
      _giaPhongController.text = widget.room!.giaPhong.toString();
      _moTaController.text = widget.room!.moTa;
      // Map SQL status to dropdown values
      _trangThai = widget.room!.trangThai == 'Trống' ? 'available' : 'occupied';
    }
  }

  @override
  void dispose() {
    _soPhongController.dispose();
    _giaPhongController.dispose();
    _moTaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.room == null ? 'Thêm phòng mới' : 'Sửa phòng'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _soPhongController,
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
                controller: _giaPhongController,
                decoration: const InputDecoration(
                  labelText: 'Giá phòng (VNĐ/đêm)',
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
              TextFormField(
                controller: _moTaController,
                decoration: const InputDecoration(
                  labelText: 'Mô tả (tùy chọn)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _trangThai,
                decoration: const InputDecoration(
                  labelText: 'Trạng thái',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'available',
                    child: Text('Trống'),
                  ),
                  DropdownMenuItem(
                    value: 'occupied',
                    child: Text('Đã thuê'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _trangThai = value!;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveRoom,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.room == null ? 'Thêm' : 'Cập nhật'),
        ),
      ],
    );
  }

  Future<void> _saveRoom() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Map dropdown values back to SQL status
      final sqlStatus = _trangThai == 'available' ? 'Trống' : 'Đã thuê';
      
      final roomData = {
        'so_phong': _soPhongController.text,
        'gia_phong': double.parse(_giaPhongController.text),
        'trang_thai': sqlStatus,
        'mo_ta': _moTaController.text,
      };

      final isNewRoom = widget.room == null;
      
      if (isNewRoom) {
        await widget.hotelManagerService.addRoom(roomData);
      } else {
        await widget.hotelManagerService.updateRoom(widget.room!.maPhong, roomData);
      }

      if (!mounted) return;
      
      // Close dialog first
      Navigator.of(context).pop();
      
      // Call callbacks to reload data and show success message
      if (isNewRoom) {
        await widget.onRoomAdded();
      } else {
        await widget.onRoomUpdated?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
