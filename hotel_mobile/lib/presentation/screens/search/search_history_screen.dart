import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/search_history.dart';

class SearchHistoryScreen extends StatefulWidget {
  const SearchHistoryScreen({Key? key}) : super(key: key);

  @override
  State<SearchHistoryScreen> createState() => _SearchHistoryScreenState();
}

class _SearchHistoryScreenState extends State<SearchHistoryScreen> {
  List<SearchHistory> searchHistories = [];

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
  }

  void _loadSearchHistory() {
    // Mock data for demonstration
    searchHistories = [
      SearchHistory(
        id: '1',
        location: 'Hồ Chí Minh',
        checkInDate: DateTime.now().subtract(const Duration(days: 30)),
        checkOutDate: DateTime.now().subtract(const Duration(days: 28)),
        guestCount: 2,
        roomCount: 1,
        searchDate: DateTime.now().subtract(const Duration(days: 30)),
        minPrice: 500000,
        maxPrice: 2000000,
      ),
      SearchHistory(
        id: '2',
        location: 'Hà Nội',
        checkInDate: DateTime.now().subtract(const Duration(days: 15)),
        checkOutDate: DateTime.now().subtract(const Duration(days: 13)),
        guestCount: 1,
        roomCount: 1,
        searchDate: DateTime.now().subtract(const Duration(days: 15)),
        minPrice: 800000,
        maxPrice: 1500000,
      ),
      SearchHistory(
        id: '3',
        location: 'Đà Nẵng',
        checkInDate: DateTime.now().subtract(const Duration(days: 7)),
        checkOutDate: DateTime.now().subtract(const Duration(days: 5)),
        guestCount: 4,
        roomCount: 2,
        searchDate: DateTime.now().subtract(const Duration(days: 7)),
        minPrice: 1000000,
        maxPrice: 3000000,
      ),
    ];
    setState(() {});
  }

  void _deleteSearchHistory(String id) {
    setState(() {
      searchHistories.removeWhere((history) => history.id == id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã xóa lịch sử tìm kiếm'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _clearAllHistory() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xóa tất cả lịch sử'),
          content: const Text(
            'Bạn có chắc chắn muốn xóa tất cả lịch sử tìm kiếm?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  searchHistories.clear();
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã xóa tất cả lịch sử tìm kiếm'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _reSearchWithHistory(SearchHistory history) {
    // Navigate back with search parameters
    Navigator.of(context).pop({
      'location': history.location,
      'checkInDate': history.checkInDate,
      'checkOutDate': history.checkOutDate,
      'guestCount': history.guestCount,
      'roomCount': history.roomCount,
      'minPrice': history.minPrice,
      'maxPrice': history.maxPrice,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lịch Sử Tìm Kiếm',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        shadowColor: Colors.black12,
        actions: [
          if (searchHistories.isNotEmpty)
            IconButton(
              onPressed: _clearAllHistory,
              icon: const Icon(Icons.clear_all),
              tooltip: 'Xóa tất cả',
            ),
        ],
      ),
      body: searchHistories.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.history, color: Colors.grey, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${searchHistories.length} lần tìm kiếm gần đây',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: searchHistories.length,
                    itemBuilder: (context, index) {
                      final history = searchHistories[index];
                      return _buildSearchHistoryCard(history, index);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Chưa có lịch sử tìm kiếm',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Các tìm kiếm của bạn sẽ xuất hiện ở đây',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHistoryCard(SearchHistory history, int index) {
    final isRecent = history.isRecent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRecent
              ? Colors.blue.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _reSearchWithHistory(history),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isRecent
                          ? Colors.blue.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isRecent ? 'GẦN ĐÂY' : 'CŨ HƠN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isRecent ? Colors.blue : Colors.grey[600],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('dd/MM/yyyy').format(history.searchDate),
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _deleteSearchHistory(history.id),
                    child: Icon(Icons.close, size: 18, color: Colors.grey[400]),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.blue[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      history.location,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.grey[600], size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${DateFormat('dd/MM').format(history.checkInDate)} - ${DateFormat('dd/MM/yyyy').format(history.checkOutDate)}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.people, color: Colors.grey[600], size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${history.guestCount} khách',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.hotel, color: Colors.grey[600], size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${history.roomCount} phòng',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.attach_money, color: Colors.grey[600], size: 16),
                  const SizedBox(width: 4),
                  Text(
                    history.minPrice != null && history.maxPrice != null
                        ? '${NumberFormat.currency(locale: 'vi_VN', symbol: '').format(history.minPrice!)} - ${NumberFormat.currency(locale: 'vi_VN', symbol: '').format(history.maxPrice!)} VND'
                        : 'Tất cả mức giá',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[400]!, Colors.blue[600]!],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _reSearchWithHistory(history),
                    borderRadius: BorderRadius.circular(8),
                    child: const Center(
                      child: Text(
                        'Tìm Kiếm Lại',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
