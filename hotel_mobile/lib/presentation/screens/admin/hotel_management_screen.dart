import 'package:flutter/material.dart';
import 'package:hotel_mobile/data/models/hotel.dart';
import 'package:hotel_mobile/data/services/admin_service.dart';
import 'package:intl/intl.dart';

class HotelManagementScreen extends StatefulWidget {
  const HotelManagementScreen({super.key});

  @override
  State<HotelManagementScreen> createState() => _HotelManagementScreenState();
}

class _HotelManagementScreenState extends State<HotelManagementScreen> {
  final AdminService _adminService = AdminService();
  final TextEditingController _searchController = TextEditingController();
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  List<Map<String, dynamic>> _hotels = [];
  List<Map<String, dynamic>> _filteredHotels = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _adminService.initialize();
    _loadHotels();
    _searchController.addListener(_filterHotels);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHotels() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final hotels = await _adminService.getHotels(limit: 100);
      
      setState(() {
        _hotels = hotels;
        _filteredHotels = hotels;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Không thể kết nối đến server. Vui lòng thử lại sau.';
        _isLoading = false;
      });
    }
  }

  void _filterHotels() {
    setState(() {
      final searchText = _searchController.text.toLowerCase();
      _filteredHotels = _hotels.where((hotel) {
        final ten = (hotel['ten'] ?? '').toString().toLowerCase();
        final diaChi = (hotel['dia_chi'] ?? '').toString().toLowerCase();
        return ten.contains(searchText) || diaChi.contains(searchText);
      }).toList();
    });
  }

  Future<void> _editHotel(Map<String, dynamic> hotel) async {
    final id = hotel['id']?.toString() ?? '';
    final tenController = TextEditingController(text: hotel['ten'] ?? '');
    final diaChiController = TextEditingController(text: hotel['dia_chi'] ?? '');
    final moTaController = TextEditingController(text: hotel['mo_ta'] ?? '');
    int soSao = hotel['so_sao'] ?? 3;
    String trangThai = hotel['trang_thai'] ?? 'Hoạt động';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Chỉnh sửa khách sạn'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: tenController,
                  decoration: const InputDecoration(
                    labelText: 'Tên khách sạn',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: diaChiController,
                  decoration: const InputDecoration(
                    labelText: 'Địa chỉ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: moTaController,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: soSao,
                  decoration: const InputDecoration(
                    labelText: 'Số sao',
                    border: OutlineInputBorder(),
                  ),
                  items: [1, 2, 3, 4, 5].map((star) {
                    return DropdownMenuItem(
                      value: star,
                      child: Row(
                        children: List.generate(
                          star,
                          (index) => const Icon(Icons.star, size: 16, color: Colors.amber),
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => soSao = value!);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: trangThai,
                  decoration: const InputDecoration(
                    labelText: 'Trạng thái',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Hoạt động', child: Text('Hoạt động')),
                    DropdownMenuItem(value: 'Ngừng hoạt động', child: Text('Ngừng hoạt động')),
                  ],
                  onChanged: (value) {
                    setState(() => trangThai = value!);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      try {
        final updateData = {
          'ten': tenController.text,
          'dia_chi': diaChiController.text,
          'mo_ta': moTaController.text,
          'so_sao': soSao,
          'trang_thai': trangThai,
        };
        
        await _adminService.updateHotel(id, updateData);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cập nhật khách sạn thành công'),
              backgroundColor: Colors.green,
            ),
          );
          _loadHotels();
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

    tenController.dispose();
    diaChiController.dispose();
    moTaController.dispose();
  }

  Future<void> _deleteHotel(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa khách sạn "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _adminService.deleteHotel(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Xóa khách sạn thành công'),
              backgroundColor: Colors.green,
            ),
          );
          _loadHotels();
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Quản lý Khách sạn',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.purple[700],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadHotels,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorWidget()
                    : _buildHotelsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Tìm kiếm khách sạn...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _searchController.clear(),
                )
              : null,
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
            borderSide: BorderSide(color: Colors.purple[700]!),
          ),
        ),
      ),
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
          ElevatedButton(
            onPressed: _loadHotels,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildHotelsList() {
    if (_filteredHotels.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hotel_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Không có khách sạn nào',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHotels,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredHotels.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final hotel = _filteredHotels[index];
          return _buildHotelCard(hotel);
        },
      ),
    );
  }

  Widget _buildHotelCard(Map<String, dynamic> hotel) {
    final id = hotel['id']?.toString() ?? '';
    final ten = hotel['ten'] ?? 'N/A';
    final diaChi = hotel['dia_chi'] ?? 'N/A';
    final soSao = hotel['so_sao'] ?? 0;
    final trangThai = hotel['trang_thai'] ?? 'active';
    final giaTb = hotel['gia_tb'];
    final tongSoPhong = hotel['tong_so_phong'] ?? 0;
    final diemDanhGia = hotel['diem_danh_gia_trung_binh'];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.purple[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.hotel, color: Colors.purple[700]),
        ),
        title: Text(
          ten,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    diaChi,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                // Star rating
                ...List.generate(
                  soSao,
                  (index) => Icon(Icons.star, size: 14, color: Colors.amber[600]),
                ),
                const SizedBox(width: 8),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(trangThai).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getStatusText(trangThai),
                    style: TextStyle(
                      color: _getStatusColor(trangThai),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Tổng số phòng', tongSoPhong.toString()),
                if (giaTb != null)
                  _buildDetailRow('Giá trung bình', currencyFormat.format(giaTb)),
                if (diemDanhGia != null)
                  _buildDetailRow('Điểm đánh giá', '$diemDanhGia/10'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _editHotel(hotel),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Chỉnh sửa'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _deleteHotel(id, ten),
                        icon: const Icon(Icons.delete, size: 18),
                        label: const Text('Xóa'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.orange;
      case 'pending':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Hoạt động';
      case 'inactive':
        return 'Tạm dừng';
      case 'pending':
        return 'Chờ duyệt';
      default:
        return status;
    }
  }
}

