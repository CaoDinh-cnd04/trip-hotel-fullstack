import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../data/services/hotel_manager_service.dart';
import '../../../data/models/hotel_manager_models.dart';
import 'package:dio/dio.dart';

class HotelManagementScreen extends StatefulWidget {
  final HotelManagerService hotelManagerService;

  const HotelManagementScreen({
    super.key,
    required this.hotelManagerService,
  });

  @override
  State<HotelManagementScreen> createState() => _HotelManagementScreenState();
}

class _HotelManagementScreenState extends State<HotelManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tenController = TextEditingController();
  final _moTaController = TextEditingController();
  final _diaChiController = TextEditingController();
  final _gioNhanPhongController = TextEditingController();
  final _gioTraPhongController = TextEditingController();
  final _chinhSachHuyController = TextEditingController();
  final _emailLienHeController = TextEditingController();
  final _sdtLienHeController = TextEditingController();
  final _websiteController = TextEditingController();

  HotelInfo? _hotelInfo;
  List<Map<String, dynamic>> _allAmenities = [];
  List<Map<String, dynamic>> _hotelAmenitiesWithPricing = []; // ✅ NEW: Amenities with pricing
  List<int> _selectedAmenities = [];
  Map<String, List<Map<String, dynamic>>> _groupedAmenities = {};
  
  File? _imageFile;
  String? _imagePreviewUrl;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _tenController.dispose();
    _moTaController.dispose();
    _diaChiController.dispose();
    _gioNhanPhongController.dispose();
    _gioTraPhongController.dispose();
    _chinhSachHuyController.dispose();
    _emailLienHeController.dispose();
    _sdtLienHeController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load hotel info, all amenities, and hotel amenities with pricing in parallel
      final results = await Future.wait([
        widget.hotelManagerService.getAssignedHotel(),
        widget.hotelManagerService.getAllAmenities(),
        widget.hotelManagerService.getHotelAmenitiesWithPricing(),
      ]);

      final hotelData = results[0] as Map<String, dynamic>;
      final amenities = results[1] as List<Map<String, dynamic>>;
      final hotelAmenities = results[2] as List<Map<String, dynamic>>;

      setState(() {
        _hotelInfo = HotelInfo.fromJson(hotelData);
        _allAmenities = amenities;
        _hotelAmenitiesWithPricing = hotelAmenities; // ✅ NEW
        
        // Populate form fields
        _tenController.text = _hotelInfo!.tenKhachSan;
        _moTaController.text = _hotelInfo!.moTa;
        _diaChiController.text = _hotelInfo!.diaChi;
        _gioNhanPhongController.text = _hotelInfo!.gioNhanPhong ?? '';
        _gioTraPhongController.text = _hotelInfo!.gioTraPhong ?? '';
        _chinhSachHuyController.text = _hotelInfo!.chinhSachHuy ?? '';
        _emailLienHeController.text = _hotelInfo!.emailLienHe ?? '';
        _sdtLienHeController.text = _hotelInfo!.sdtLienHe ?? '';
        _websiteController.text = _hotelInfo!.website ?? '';
        _imagePreviewUrl = _hotelInfo!.hinhAnh;

        // Set selected amenities
        if (hotelData['tien_nghi'] != null && hotelData['tien_nghi'] is List) {
          final hotelAmenities = hotelData['tien_nghi'] as List;
          _selectedAmenities = hotelAmenities
              .map((a) => a['id'] as int? ?? (a is Map ? a['id'] as int? : null))
              .whereType<int>()
              .toList();
        }

        // Group amenities by category
        _groupedAmenities = {};
        for (var amenity in _allAmenities) {
          final group = amenity['nhom'] ?? 'Khác';
          if (!_groupedAmenities.containsKey(group)) {
            _groupedAmenities[group] = [];
          }
          _groupedAmenities[group]!.add(amenity);
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

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
          _imagePreviewUrl = image.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chọn ảnh: $e')),
        );
      }
    }
  }

  void _toggleAmenity(int amenityId) {
    setState(() {
      if (_selectedAmenities.contains(amenityId)) {
        _selectedAmenities.remove(amenityId);
      } else {
        _selectedAmenities.add(amenityId);
      }
    });
  }

  void _showAddAmenityDialog() {
    final tenController = TextEditingController();
    final moTaController = TextEditingController();
    String selectedNhom = 'Khác';
    bool isCreating = false;

    // Get unique groups from existing amenities
    final availableGroups = _groupedAmenities.keys.toList()..add('Khác');
    final uniqueGroups = availableGroups.toSet().toList()..sort();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Thêm tiện nghi mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: tenController,
                  decoration: const InputDecoration(
                    labelText: 'Tên tiện nghi *',
                    border: OutlineInputBorder(),
                    hintText: 'VD: WiFi miễn phí, Bể bơi, Gym...',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: moTaController,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả (tùy chọn)',
                    border: OutlineInputBorder(),
                    hintText: 'Mô tả chi tiết về tiện nghi...',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedNhom,
                  decoration: const InputDecoration(
                    labelText: 'Nhóm tiện nghi',
                    border: OutlineInputBorder(),
                  ),
                  items: uniqueGroups.map((group) {
                    return DropdownMenuItem(
                      value: group,
                      child: Text(group),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() {
                        selectedNhom = value;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isCreating
                  ? null
                  : () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: isCreating
                  ? null
                  : () async {
                      if (tenController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Vui lòng nhập tên tiện nghi'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setDialogState(() {
                        isCreating = true;
                      });

                      try {
                        final result = await widget.hotelManagerService.createAmenity(
                          ten: tenController.text.trim(),
                          moTa: moTaController.text.trim().isEmpty
                              ? null
                              : moTaController.text.trim(),
                          nhom: selectedNhom,
                        );

                        if (mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Thêm tiện nghi thành công!'),
                              backgroundColor: Colors.green,
                            ),
                          );

                          // Reload data to show new amenity
                          await _loadData();

                          // Auto-select the newly created amenity
                          if (result['amenity'] != null &&
                              result['amenity']['id'] != null) {
                            setState(() {
                              _selectedAmenities.add(result['amenity']['id'] as int);
                            });
                          }
                        }
                      } catch (e) {
                        if (mounted) {
                          setDialogState(() {
                            isCreating = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Lỗi: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              child: isCreating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Thêm'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveHotel() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_tenController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên khách sạn')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Prepare update data
      final updateData = <String, dynamic>{
        'ten': _tenController.text.trim(),
        'mo_ta': _moTaController.text.trim(),
        'dia_chi': _diaChiController.text.trim(),
        'gio_nhan_phong': _gioNhanPhongController.text.trim(),
        'gio_tra_phong': _gioTraPhongController.text.trim(),
        'chinh_sach_huy': _chinhSachHuyController.text.trim(),
        'email_lien_he': _emailLienHeController.text.trim(),
        'sdt_lien_he': _sdtLienHeController.text.trim(),
        'website': _websiteController.text.trim(),
      };

      // Update hotel info
      await widget.hotelManagerService.updateHotel(updateData);

      // Update amenities
      await widget.hotelManagerService.updateHotelAmenities(_selectedAmenities);

      // TODO: Upload image if selected
      // if (_imageFile != null) {
      //   await widget.hotelManagerService.uploadHotelImage(_imageFile!);
      // }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật thông tin khách sạn thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Reload data
        await _loadData();
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
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildStatusBadge(String status) {
    final isActive = status == 'Hoạt động' || status == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.pause_circle,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            status,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Quản lý khách sạn'),
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Quản lý khách sạn'),
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text('Lỗi: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý khách sạn'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          if (_hotelInfo != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(child: _buildStatusBadge(_hotelInfo!.trangThai)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information Section
              _buildSection(
                title: 'Thông tin cơ bản',
                icon: Icons.business,
                children: [
                  TextFormField(
                    controller: _tenController,
                    decoration: const InputDecoration(
                      labelText: 'Tên khách sạn *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập tên khách sạn';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _moTaController,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _diaChiController,
                    decoration: const InputDecoration(
                      labelText: 'Địa chỉ',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Hotel Image Section
              _buildSection(
                title: 'Ảnh khách sạn',
                icon: Icons.image,
                children: [
                  if (_imagePreviewUrl != null)
                    Container(
                      height: 200,
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[200],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _imageFile != null
                            ? Image.file(_imageFile!, fit: BoxFit.cover)
                            : Image.network(
                                _imagePreviewUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.hotel, size: 64),
                              ),
                      ),
                    ),
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.upload),
                    label: const Text('Chọn ảnh mới'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[50],
                      foregroundColor: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Định dạng: JPG, PNG. Kích thước tối đa: 5MB',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Check-in/Check-out Times Section
              _buildSection(
                title: 'Giờ check-in / check-out',
                icon: Icons.access_time,
                children: [
                  TextFormField(
                    controller: _gioNhanPhongController,
                    decoration: const InputDecoration(
                      labelText: 'Giờ nhận phòng',
                      hintText: 'VD: 14:00',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _gioTraPhongController,
                    decoration: const InputDecoration(
                      labelText: 'Giờ trả phòng',
                      hintText: 'VD: 12:00',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Cancellation Policy Section
              _buildSection(
                title: 'Chính sách hủy phòng',
                icon: Icons.description,
                children: [
                  TextFormField(
                    controller: _chinhSachHuyController,
                    decoration: const InputDecoration(
                      labelText: 'Chính sách hủy phòng',
                      hintText: 'Nhập chính sách hủy phòng của khách sạn...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 6,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Amenities Section
              _buildSection(
                title: 'Tiện nghi',
                icon: Icons.room_service,
                children: [
                  // Add new amenity button
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _showAddAmenityDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Thêm tiện nghi mới'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[50],
                              foregroundColor: Colors.green[700],
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _showManagePricingDialog,
                            icon: const Icon(Icons.attach_money),
                            label: const Text('Quản lý giá'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange[50],
                              foregroundColor: Colors.orange[700],
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ..._groupedAmenities.entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            entry.key,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: entry.value.map((amenity) {
                            final amenityId = amenity['id'] as int;
                            final isSelected = _selectedAmenities.contains(amenityId);
                            return FilterChip(
                              label: Text(amenity['ten'] ?? ''),
                              selected: isSelected,
                              onSelected: (_) => _toggleAmenity(amenityId),
                              selectedColor: Colors.blue[100],
                              checkmarkColor: Colors.blue[700],
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  }),
                ],
              ),

              const SizedBox(height: 24),

              // Contact Information Section
              _buildSection(
                title: 'Thông tin liên hệ',
                icon: Icons.contact_mail,
                children: [
                  TextFormField(
                    controller: _emailLienHeController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _sdtLienHeController,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _websiteController,
                    decoration: const InputDecoration(
                      labelText: 'Website',
                      hintText: 'https://...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.language),
                    ),
                    keyboardType: TextInputType.url,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveHotel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save),
                            SizedBox(width: 8),
                            Text(
                              'Lưu thay đổi',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue[700], size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  void _showManagePricingDialog() {
    showDialog(
      context: context,
      builder: (context) => _AmenityPricingDialog(
        hotelManagerService: widget.hotelManagerService,
        hotelAmenities: _hotelAmenitiesWithPricing,
        onPricingUpdated: () async {
          // Reload hotel amenities with pricing
          try {
            final updated = await widget.hotelManagerService.getHotelAmenitiesWithPricing();
            setState(() {
              _hotelAmenitiesWithPricing = updated;
            });
          } catch (e) {
            print('Error reloading amenities: $e');
          }
        },
      ),
    );
  }
}

// Dialog để quản lý giá cho từng amenity
class _AmenityPricingDialog extends StatefulWidget {
  final HotelManagerService hotelManagerService;
  final List<Map<String, dynamic>> hotelAmenities;
  final VoidCallback onPricingUpdated;

  const _AmenityPricingDialog({
    required this.hotelManagerService,
    required this.hotelAmenities,
    required this.onPricingUpdated,
  });

  @override
  State<_AmenityPricingDialog> createState() => _AmenityPricingDialogState();
}

class _AmenityPricingDialogState extends State<_AmenityPricingDialog> {
  final Map<int, TextEditingController> _priceControllers = {};
  final Map<int, bool> _isFreeMap = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers and free status
    for (var amenity in widget.hotelAmenities) {
      final id = amenity['id'] as int;
      final giaPhi = amenity['gia_phi'];
      final mienPhi = amenity['mien_phi'] == true || amenity['mien_phi'] == 1;
      
      _priceControllers[id] = TextEditingController(
        text: giaPhi != null ? giaPhi.toString() : '',
      );
      _isFreeMap[id] = mienPhi;
    }
  }

  @override
  void dispose() {
    for (var controller in _priceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _savePricing(int amenityId) async {
    final controller = _priceControllers[amenityId];
    if (controller == null) return; // Safety check
    
    final isFree = _isFreeMap[amenityId] ?? true;
    final priceText = controller.text.trim();
    
    double? price;
    if (!isFree && priceText.isNotEmpty) {
      price = double.tryParse(priceText);
      if (price == null || price < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Giá không hợp lệ'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.hotelManagerService.updateAmenityPricing(
        amenityId: amenityId,
        mienPhi: isFree,
        giaPhi: price,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật giá thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onPricingUpdated();
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
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Group amenities by category
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (var amenity in widget.hotelAmenities) {
      final group = amenity['nhom'] ?? 'Khác';
      if (!grouped.containsKey(group)) {
        grouped[group] = [];
      }
      grouped[group]!.add(amenity);
    }

    return Dialog(
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[700],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.attach_money, color: Colors.white),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Quản lý giá dịch vụ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thiết lập giá cho các dịch vụ tiện nghi. Dịch vụ miễn phí sẽ tự động được thêm khi khách đặt phòng giá cao.',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    ...grouped.entries.map((entry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12, top: 8),
                            child: Text(
                              entry.key,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                          ),
                          ...entry.value.map((amenity) {
                            final id = amenity['id'] as int;
                            final ten = amenity['ten'] ?? '';
                            final isFree = _isFreeMap[id] ?? true;
                            final controller = _priceControllers[id]!;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            ten,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Switch(
                                          value: !isFree,
                                          onChanged: (value) {
                                            setState(() {
                                              _isFreeMap[id] = !value;
                                              if (!value) {
                                                controller.clear();
                                              }
                                            });
                                          },
                                        ),
                                        Text(
                                          isFree ? 'Miễn phí' : 'Có phí',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isFree ? Colors.green : Colors.orange,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (!isFree) ...[
                                      const SizedBox(height: 12),
                                      TextField(
                                        controller: controller,
                                        decoration: const InputDecoration(
                                          labelText: 'Giá (VNĐ)',
                                          hintText: 'VD: 500000',
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(Icons.attach_money),
                                        ),
                                        keyboardType: TextInputType.number,
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: _isSaving ? null : () => _savePricing(id),
                                        icon: _isSaving
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              )
                                            : const Icon(Icons.save, size: 18),
                                        label: const Text('Lưu'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue[700],
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    }),
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

