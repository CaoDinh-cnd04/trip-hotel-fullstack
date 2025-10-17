import 'package:flutter/material.dart';

class SearchHistoryScreen extends StatefulWidget {
  const SearchHistoryScreen({super.key});

  @override
  State<SearchHistoryScreen> createState() => _SearchHistoryScreenState();
}

class _SearchHistoryScreenState extends State<SearchHistoryScreen> {
  List<SearchHistoryItem> _searchHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
  }

  Future<void> _loadSearchHistory() async {
    // Simulate loading
    await Future.delayed(const Duration(seconds: 1));
    
    // Mock data for search history
    setState(() {
      _searchHistory = [
        SearchHistoryItem(
          id: 1,
          query: 'Khách sạn ở Hồ Chí Minh',
          location: 'TP. Hồ Chí Minh',
          checkInDate: DateTime.now().add(const Duration(days: 7)),
          checkOutDate: DateTime.now().add(const Duration(days: 10)),
          guestCount: 2,
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        SearchHistoryItem(
          id: 2,
          query: 'Resort biển Nha Trang',
          location: 'Nha Trang',
          checkInDate: DateTime.now().add(const Duration(days: 15)),
          checkOutDate: DateTime.now().add(const Duration(days: 18)),
          guestCount: 4,
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
        ),
        SearchHistoryItem(
          id: 3,
          query: 'Khách sạn gần sân bay',
          location: 'Hà Nội',
          checkInDate: DateTime.now().add(const Duration(days: 3)),
          checkOutDate: DateTime.now().add(const Duration(days: 5)),
          guestCount: 1,
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
        ),
        SearchHistoryItem(
          id: 4,
          query: 'Hotel 5 sao Đà Nẵng',
          location: 'Đà Nẵng',
          checkInDate: DateTime.now().add(const Duration(days: 20)),
          checkOutDate: DateTime.now().add(const Duration(days: 23)),
          guestCount: 2,
          timestamp: DateTime.now().subtract(const Duration(days: 3)),
        ),
        SearchHistoryItem(
          id: 5,
          query: 'Khách sạn giá rẻ',
          location: 'Phú Quốc',
          checkInDate: DateTime.now().add(const Duration(days: 30)),
          checkOutDate: DateTime.now().add(const Duration(days: 33)),
          guestCount: 2,
          timestamp: DateTime.now().subtract(const Duration(days: 5)),
        ),
      ];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Lịch sử tìm kiếm'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (_searchHistory.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _showClearAllDialog,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _searchHistory.isEmpty
              ? _buildEmptyState()
              : _buildSearchHistoryList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có lịch sử tìm kiếm',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Các tìm kiếm của bạn sẽ được lưu ở đây',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to home screen
            },
            icon: const Icon(Icons.search),
            label: const Text('Bắt đầu tìm kiếm'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHistoryList() {
    return Column(
      children: [
        // Header with count
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Text(
            '${_searchHistory.length} tìm kiếm gần đây',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        const Divider(height: 1),
        
        // Search history list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _searchHistory.length,
            itemBuilder: (context, index) {
              final item = _searchHistory[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildSearchHistoryItem(item),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchHistoryItem(SearchHistoryItem item) {
    return Card(
      child: InkWell(
        onTap: () => _repeatSearch(item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.search, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.query,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              item.location,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        _removeSearchItem(item);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Xóa'),
                          ],
                        ),
                      ),
                    ],
                    child: const Icon(Icons.more_vert, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(
                    Icons.calendar_today,
                    '${item.checkInDate.day}/${item.checkInDate.month} - ${item.checkOutDate.day}/${item.checkOutDate.month}',
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    Icons.person,
                    '${item.guestCount} khách',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _formatTimestamp(item.timestamp),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.blue),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.blue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  void _repeatSearch(SearchHistoryItem item) {
    // TODO: Navigate to search results with the same parameters
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tìm kiếm lại: ${item.query}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _removeSearchItem(SearchHistoryItem item) {
    setState(() {
      _searchHistory.removeWhere((h) => h.id == item.id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã xóa tìm kiếm'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tất cả lịch sử'),
        content: const Text('Bạn có chắc chắn muốn xóa tất cả lịch sử tìm kiếm?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _searchHistory.clear();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã xóa tất cả lịch sử tìm kiếm'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa tất cả'),
          ),
        ],
      ),
    );
  }
}

class SearchHistoryItem {
  final int id;
  final String query;
  final String location;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int guestCount;
  final DateTime timestamp;

  SearchHistoryItem({
    required this.id,
    required this.query,
    required this.location,
    required this.checkInDate,
    required this.checkOutDate,
    required this.guestCount,
    required this.timestamp,
  });
}
