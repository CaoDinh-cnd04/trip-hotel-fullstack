import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../data/models/saved_item.dart';
import '../../../data/models/hotel.dart';
import '../../../data/services/saved_items_service.dart';
import '../../../data/services/api_service.dart';
import '../../widgets/improved_image_widget.dart';
import '../property/property_detail_screen.dart';

class SavedItemsScreen extends StatefulWidget {
  const SavedItemsScreen({Key? key}) : super(key: key);

  @override
  State<SavedItemsScreen> createState() => _SavedItemsScreenState();
}

class _SavedItemsScreenState extends State<SavedItemsScreen> {
  final SavedItemsService _savedItemsService = SavedItemsService();
  List<SavedItem> _savedItems = [];
  bool _isLoading = true;
  String? _error;
  bool _hasLoadedOnce = false;

  @override
  void initState() {
    super.initState();
    print('🔄 SavedItemsScreen: initState');
    _loadSavedItems();
  }

  Future<void> _loadSavedItems() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _savedItemsService.getSavedItems();
      
      if (mounted) {
        setState(() {
          if (response.success && response.data != null) {
            _savedItems = response.data!;
          } else {
            _error = response.message ?? 'Không thể tải danh sách';
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _navigateToHotelDetail(SavedItem item) async {
    if (item.type != 'hotel') return;
    
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    try {
      // Fetch hotel details from API
      final apiService = ApiService();
      final hotelId = int.tryParse(item.itemId);
      
      if (hotelId == null) {
        throw Exception('ID khách sạn không hợp lệ');
      }
      
      final response = await apiService.getHotelById(hotelId);
      
      if (mounted) {
        Navigator.pop(context); // Close loading
        
        if (response.success && response.data != null) {
          final hotel = response.data!;
          
          // Navigate to PropertyDetailScreen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PropertyDetailScreen(hotel: hotel),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Không tìm thấy thông tin khách sạn'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Lỗi load hotel detail: $e');
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải dữ liệu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeItem(SavedItem item) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa khỏi danh sách đã lưu'),
        content: Text('Bạn có chắc muốn xóa "${item.name}" khỏi danh sách?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (shouldRemove != true) return;

    try {
      // Use removeFromSavedByItemId instead of removeFromSaved
      final response = await _savedItemsService.removeFromSavedByItemId(
        item.itemId, 
        item.type,
      );
      
      // Always reload to refresh the list, regardless of success
      _loadSavedItems();
      
      if (mounted) {
        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('Đã xóa "${item.name}"'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          // Don't show error, just reload
          print('⚠️ Xóa failed: ${response.message}');
        }
      }
    } catch (e) {
      print('❌ Lỗi xóa: $e');
      // Still reload the list
      _loadSavedItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Đã lưu',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_savedItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Thông tin'),
                    content: Text('Bạn đã lưu ${_savedItems.length} mục'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Đóng'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _savedItems.isEmpty
                  ? _buildEmptyWidget()
                  : _buildSavedItemsList(),
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
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: const TextStyle(fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadSavedItems,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return EmptySavedItemsWidget(
      onExplore: () {
        Navigator.pushNamed(context, '/home');
      },
    );
  }

  Widget _buildSavedItemsList() {
    return RefreshIndicator(
      onRefresh: _loadSavedItems,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _savedItems.length,
        itemBuilder: (context, index) {
          final item = _savedItems[index];
          return _buildSavedItemCard(item);
        },
      ),
    );
  }

  Widget _buildSavedItemCard(SavedItem item) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToHotelDetail(item),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: HotelImageWidget(
                    imageUrl: item.imageUrl,
                    width: double.infinity,
                    height: 180,
                    onTap: () => _navigateToHotelDetail(item),
                  ),
                ),
                
                // Type badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getTypeColor(item.type),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getTypeName(item.type),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                
                // Remove button
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => _removeItem(item),
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ),
              ],
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  if (item.location != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.location!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  if (item.price != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      item.price!,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Đã lưu ${_formatDate(item.savedAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _navigateToHotelDetail(item),
                        icon: const Icon(Icons.arrow_forward, size: 16),
                        label: const Text('Xem'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'hotel':
        return Colors.blue;
      case 'activity':
        return Colors.green;
      case 'destination':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getTypeName(String type) {
    switch (type) {
      case 'hotel':
        return 'Khách sạn';
      case 'activity':
        return 'Hoạt động';
      case 'destination':
        return 'Điểm đến';
      default:
        return type;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }
}
