import 'package:flutter/material.dart';
import '../../../data/services/hotel_manager_service.dart';
import '../../../data/services/backend_auth_service.dart';
import '../../../data/models/hotel_manager_models.dart';

class ProfileManagementScreen extends StatefulWidget {
  final HotelManagerService hotelManagerService;

  const ProfileManagementScreen({
    super.key,
    required this.hotelManagerService,
  });

  @override
  State<ProfileManagementScreen> createState() => _ProfileManagementScreenState();
}

class _ProfileManagementScreenState extends State<ProfileManagementScreen> {
  final BackendAuthService _backendAuthService = BackendAuthService();
  HotelInfo? _hotelInfo;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHotelInfo();
  }

  Future<void> _loadHotelInfo() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final hotelInfoData = await widget.hotelManagerService.getAssignedHotel();
      setState(() {
        _hotelInfo = HotelInfo.fromJson(hotelInfoData);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // ⚠️ REMOVED: Hotel Manager cannot change hotel status (only Admin can)
  // The toggle status button has been disabled in the UI

  @override
  Widget build(BuildContext context) {
    final user = _backendAuthService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ quản lý'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _hotelInfo != null ? _showEditHotelDialog : null,
          ),
        ],
      ),
      body: _buildBody(user),
    );
  }

  Widget _buildBody(user) {
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
              onPressed: _loadHotelInfo,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHotelInfo,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildUserInfoCard(user),
            const SizedBox(height: 16),
            if (_hotelInfo != null) _buildHotelInfoCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoCard(user) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person,
                  color: Colors.blue[700],
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thông tin cá nhân',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user?.hoTen ?? 'Hotel Manager',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Email', user?.email ?? 'N/A'),
            _buildInfoRow('Chức vụ', user?.chucVu ?? 'Hotel Manager'),
            _buildInfoRow('Trạng thái', user?.trangThai == 1 ? 'Hoạt động' : 'Tạm dừng'),
          ],
        ),
      ),
    );
  }

  Widget _buildHotelInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hotel Image
            if (_hotelInfo!.hinhAnh.isNotEmpty) ...[
              Container(
                height: 180,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _hotelInfo!.hinhAnh,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.hotel, size: 64, color: Colors.grey),
                    ),
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
                ),
              ),
            ],
            Row(
              children: [
                Icon(
                  Icons.hotel,
                  color: Colors.green[700],
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thông tin khách sạn',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _hotelInfo!.tenKhachSan,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                // ⚠️ DISABLED: Hotel Manager cannot change hotel status (only Admin can)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (_hotelInfo!.trangThai == 'active' || 
                            _hotelInfo!.trangThai == 'Hoạt động') 
                        ? Colors.green 
                        : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        (_hotelInfo!.trangThai == 'active' || 
                         _hotelInfo!.trangThai == 'Hoạt động')
                            ? Icons.check_circle 
                            : Icons.pause_circle,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        (_hotelInfo!.trangThai == 'active' || 
                         _hotelInfo!.trangThai == 'Hoạt động')
                            ? 'Hoạt động' 
                            : 'Tạm dừng',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStarRating(_hotelInfo!.soSao),
            const SizedBox(height: 16),
            _buildInfoRow('Địa chỉ', _hotelInfo!.diaChi),
            _buildInfoRow('Vị trí', '${_hotelInfo!.tenViTri}, ${_hotelInfo!.tenTinhThanh}, ${_hotelInfo!.tenQuocGia}'),
            if (_hotelInfo!.emailLienHe != null)
              _buildInfoRow('Email liên hệ', _hotelInfo!.emailLienHe!),
            if (_hotelInfo!.sdtLienHe != null)
              _buildInfoRow('SĐT liên hệ', _hotelInfo!.sdtLienHe!),
            if (_hotelInfo!.website != null)
              _buildInfoRow('Website', _hotelInfo!.website!),
            if (_hotelInfo!.gioNhanPhong != null)
              _buildInfoRow('Giờ nhận phòng', _hotelInfo!.gioNhanPhong!),
            if (_hotelInfo!.gioTraPhong != null)
              _buildInfoRow('Giờ trả phòng', _hotelInfo!.gioTraPhong!),
            if (_hotelInfo!.tongSoPhong != null)
              _buildInfoRow('Tổng số phòng', '${_hotelInfo!.tongSoPhong}'),
            if (_hotelInfo!.diemDanhGiaTrungBinh != null)
              _buildInfoRow('Đánh giá TB', '${_hotelInfo!.diemDanhGiaTrungBinh!.toStringAsFixed(1)}/5'),
            if (_hotelInfo!.soLuotDanhGia != null)
              _buildInfoRow('Số lượt đánh giá', '${_hotelInfo!.soLuotDanhGia}'),
            if (_hotelInfo!.moTa.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Mô tả:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _hotelInfo!.moTa,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarRating(int stars) {
    return Row(
      children: [
        Text(
          'Xếp hạng: ',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        ...List.generate(5, (index) {
          return Icon(
            index < stars ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 20,
          );
        }),
      ],
    );
  }

  void _showEditHotelDialog() {
    showDialog(
      context: context,
      builder: (context) => _HotelEditDialog(
        hotelManagerService: widget.hotelManagerService,
        hotelInfo: _hotelInfo!,
        onHotelUpdated: () {
          _loadHotelInfo();
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

class _HotelEditDialog extends StatefulWidget {
  final HotelManagerService hotelManagerService;
  final HotelInfo hotelInfo;
  final VoidCallback onHotelUpdated;

  const _HotelEditDialog({
    required this.hotelManagerService,
    required this.hotelInfo,
    required this.onHotelUpdated,
  });

  @override
  State<_HotelEditDialog> createState() => _HotelEditDialogState();
}

class _HotelEditDialogState extends State<_HotelEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _moTaController = TextEditingController();
  final _emailLienHeController = TextEditingController();
  final _sdtLienHeController = TextEditingController();
  final _websiteController = TextEditingController();
  final _gioNhanPhongController = TextEditingController();
  final _gioTraPhongController = TextEditingController();
  final _chinhSachHuyController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _moTaController.text = widget.hotelInfo.moTa;
    _emailLienHeController.text = widget.hotelInfo.emailLienHe ?? '';
    _sdtLienHeController.text = widget.hotelInfo.sdtLienHe ?? '';
    _websiteController.text = widget.hotelInfo.website ?? '';
    _gioNhanPhongController.text = widget.hotelInfo.gioNhanPhong ?? '';
    _gioTraPhongController.text = widget.hotelInfo.gioTraPhong ?? '';
    _chinhSachHuyController.text = widget.hotelInfo.chinhSachHuy ?? '';
  }

  @override
  void dispose() {
    _moTaController.dispose();
    _emailLienHeController.dispose();
    _sdtLienHeController.dispose();
    _websiteController.dispose();
    _gioNhanPhongController.dispose();
    _gioTraPhongController.dispose();
    _chinhSachHuyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Chỉnh sửa thông tin khách sạn'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _moTaController,
                decoration: const InputDecoration(
                  labelText: 'Mô tả',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailLienHeController,
                decoration: const InputDecoration(
                  labelText: 'Email liên hệ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _sdtLienHeController,
                decoration: const InputDecoration(
                  labelText: 'SĐT liên hệ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _websiteController,
                decoration: const InputDecoration(
                  labelText: 'Website',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _gioNhanPhongController,
                decoration: const InputDecoration(
                  labelText: 'Giờ nhận phòng (HH:MM)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _gioTraPhongController,
                decoration: const InputDecoration(
                  labelText: 'Giờ trả phòng (HH:MM)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _chinhSachHuyController,
                decoration: const InputDecoration(
                  labelText: 'Chính sách hủy',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
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
          onPressed: _isLoading ? null : _saveHotel,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Cập nhật'),
        ),
      ],
    );
  }

  Future<void> _saveHotel() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final hotelData = {
        'mo_ta': _moTaController.text,
        'email_lien_he': _emailLienHeController.text,
        'sdt_lien_he': _sdtLienHeController.text,
        'website': _websiteController.text,
        'gio_nhan_phong': _gioNhanPhongController.text,
        'gio_tra_phong': _gioTraPhongController.text,
        'chinh_sach_huy': _chinhSachHuyController.text,
      };

      await widget.hotelManagerService.updateHotel(hotelData);
      widget.onHotelUpdated();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã cập nhật thông tin khách sạn'),
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
