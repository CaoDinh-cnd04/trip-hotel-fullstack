import 'package:flutter/material.dart';

class DealsHeader extends StatelessWidget {
  const DealsHeader({super.key});

  void _handleSearch(BuildContext context) {
    showSearch(
      context: context,
      delegate: PromotionSearchDelegate(),
    );
  }

  void _handleNotifications(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chức năng thông báo đang được phát triển'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade600,
            Colors.blue.shade400,
          ],
        ),
      ),
      child: Row(
        children: [
          // Back button - compact
          IconButton(
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Ưu Đãi Đặc Biệt',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          // Search button - compact
          IconButton(
            onPressed: () => _handleSearch(context),
            icon: const Icon(Icons.search, color: Colors.white, size: 22),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
          ),
          // Notification button - compact
          IconButton(
            onPressed: () => _handleNotifications(context),
            icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

// Search delegate for promotions
class PromotionSearchDelegate extends SearchDelegate<String> {
  @override
  String get searchFieldLabel => 'Tìm ưu đãi...';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return _buildSearchSuggestions();
    }
    return _buildSearchResults();
  }

  Widget _buildSearchSuggestions() {
    final suggestions = [
      'Giảm 20%',
      'Flash Sale',
      'Hà Nội',
      'Đà Nẵng',
      'Nha Trang',
      'Suite',
      'Family Room',
    ];

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = suggestions[index];
        return ListTile(
          leading: const Icon(Icons.search, color: Colors.grey),
          title: Text(suggestion),
          onTap: () {
            query = suggestion;
            showResults(context);
          },
        );
      },
    );
  }

  Widget _buildSearchResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            query.isEmpty 
                ? 'Nhập từ khóa để tìm kiếm'
                : 'Không tìm thấy ưu đãi: "$query"',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Thử tìm kiếm: Hà Nội, Đà Nẵng, Suite...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
