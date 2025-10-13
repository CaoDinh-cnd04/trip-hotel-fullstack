import 'package:flutter/material.dart';
import 'package:hotel_mobile/data/models/promotion.dart';
import 'package:hotel_mobile/data/services/api_service.dart';
import 'package:hotel_mobile/data/services/auth_service.dart';
import 'package:hotel_mobile/presentation/screens/promotion/promotion_form_screen.dart';

class PromotionManagementScreen extends StatefulWidget {
  const PromotionManagementScreen({super.key});

  @override
  State<PromotionManagementScreen> createState() =>
      _PromotionManagementScreenState();
}

class _PromotionManagementScreenState extends State<PromotionManagementScreen> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();

  List<Promotion> _promotions = [];
  List<Promotion> _filteredPromotions = [];
  bool _isLoading = true;
  String? _error;
  bool _showActiveOnly = false;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _apiService.initialize();
    _checkUserRole();
    _loadPromotions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkUserRole() async {
    try {
      final isLoggedIn = await _authService.isSignedIn();
      final currentUser = _authService.currentUser;

      setState(() {
        // Giả sử chỉ admin mới có quyền quản lý khuyến mãi
        // Bạn có thể thay đổi logic này theo yêu cầu
        _isAdmin =
            isLoggedIn && (currentUser?.email.contains('admin') ?? false);
      });
    } catch (e) {
      print('Error checking user role: $e');
      setState(() {
        _isAdmin = false;
      });
    }
  }

  Future<void> _loadPromotions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('Loading promotions from API...');
      final response = await _apiService.getPromotions(
        limit: 100,
        active: _showActiveOnly ? true : null,
      );

      print(
        'Promotions API response: ${response.success}, data: ${response.data?.length}',
      );

      if (response.success && response.data != null) {
        setState(() {
          _promotions = response.data!;
          _filteredPromotions = _promotions;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterPromotions(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredPromotions = _promotions;
      } else {
        _filteredPromotions = _promotions
            .where(
              (promotion) =>
                  promotion.ten.toLowerCase().contains(query.toLowerCase()) ||
                  (promotion.moTa?.toLowerCase().contains(
                        query.toLowerCase(),
                      ) ??
                      false),
            )
            .toList();
      }
    });
  }

  Future<void> _deletePromotion(Promotion promotion) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc chắn muốn xóa khuyến mãi "${promotion.ten}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true && promotion.id != null) {
      try {
        final response = await _apiService.deletePromotion(promotion.id!);
        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa khuyến mãi thành công')),
          );
          _loadPromotions();
        } else {
          throw Exception(response.message);
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi khi xóa: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Khuyến mãi'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPromotions,
          ),
        ],
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton(
              onPressed: () => _navigateToPromotionForm(),
              backgroundColor: Colors.blue,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: Column(
        children: [
          // Search and Filter
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm khuyến mãi...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _filterPromotions('');
                            },
                          )
                        : null,
                  ),
                  onChanged: _filterPromotions,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: CheckboxListTile(
                        title: const Text(
                          'Chỉ hiển thị khuyến mãi đang hoạt động',
                        ),
                        value: _showActiveOnly,
                        onChanged: (value) {
                          setState(() {
                            _showActiveOnly = value ?? false;
                          });
                          _loadPromotions();
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadPromotions,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  )
                : _filteredPromotions.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_offer, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Không có khuyến mãi nào'),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadPromotions,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredPromotions.length,
                      itemBuilder: (context, index) {
                        final promotion = _filteredPromotions[index];
                        return _buildPromotionCard(promotion);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionCard(Promotion promotion) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Column(
        children: [
          // Header with image and basic info
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Promotion Image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[300],
                  ),
                  child:
                      promotion.hinhAnh != null && promotion.hinhAnh!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            promotion.hinhAnh!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.local_offer, size: 40),
                          ),
                        )
                      : const Icon(Icons.local_offer, size: 40),
                ),
                const SizedBox(width: 12),
                // Promotion Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              promotion.ten,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: promotion.isActive
                                  ? Colors.green
                                  : Colors.grey,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              promotion.isActive
                                  ? 'Hoạt động'
                                  : 'Không hoạt động',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          promotion.discountText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (promotion.moTa != null &&
                          promotion.moTa!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          promotion.moTa!,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        'Từ ${_formatDate(promotion.ngayBatDau)} đến ${_formatDate(promotion.ngayKetThuc)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Action Buttons - Only show for admin
          if (_isAdmin)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () =>
                        _navigateToPromotionForm(promotion: promotion),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Sửa'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _deletePromotion(promotion),
                    icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                    label: const Text(
                      'Xóa',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _navigateToPromotionForm({Promotion? promotion}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PromotionFormScreen(promotion: promotion),
      ),
    );

    if (result == true) {
      _loadPromotions();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
