import 'package:flutter/material.dart';
import 'package:hotel_mobile/data/models/promotion.dart';
import 'package:hotel_mobile/presentation/widgets/promotion_card.dart';
import 'package:hotel_mobile/presentation/screens/property/property_detail_screen.dart';
import 'package:hotel_mobile/data/models/hotel.dart';
import 'package:hotel_mobile/data/services/api_service.dart';

class DealsHeader extends StatelessWidget {
  final List<Promotion> promotions;
  
  const DealsHeader({
    super.key,
    required this.promotions,
  });

  void _handleSearch(BuildContext context) {
    showSearch(
      context: context,
      delegate: PromotionSearchDelegate(promotions: promotions),
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
  final List<Promotion> promotions;
  
  PromotionSearchDelegate({required this.promotions});
  
  @override
  String get searchFieldLabel => 'Tìm ưu đãi...';
  
  // Tìm kiếm trong danh sách promotions
  List<Promotion> _searchPromotions(String query) {
    if (query.isEmpty) {
      return [];
    }
    
    final lowerQuery = query.toLowerCase();
    return promotions.where((promotion) {
      // Tìm theo tên promotion
      if (promotion.ten.toLowerCase().contains(lowerQuery)) {
        return true;
      }
      
      // Tìm theo mô tả
      if (promotion.moTa?.toLowerCase().contains(lowerQuery) ?? false) {
        return true;
      }
      
      // Tìm theo tên khách sạn (nếu có)
      if (promotion.hotelName?.toLowerCase().contains(lowerQuery) ?? false) {
        return true;
      }
      
      // Tìm theo địa chỉ khách sạn
      if (promotion.hotelAddress?.toLowerCase().contains(lowerQuery) ?? false) {
        return true;
      }
      
      // Tìm theo location
      if (promotion.location?.toLowerCase().contains(lowerQuery) ?? false) {
        return true;
      }
      
      // Tìm theo phần trăm giảm giá
      if (lowerQuery.contains('%') || lowerQuery.contains('giảm')) {
        final percentMatch = RegExp(r'(\d+)').firstMatch(lowerQuery);
        if (percentMatch != null) {
          final percent = int.tryParse(percentMatch.group(1) ?? '');
          if (percent != null && promotion.phanTramGiam >= percent) {
            return true;
          }
        }
      }
      
      // Tìm theo số phần trăm (ví dụ: "20", "28")
      final numberMatch = RegExp(r'(\d+)').firstMatch(lowerQuery);
      if (numberMatch != null) {
        final number = int.tryParse(numberMatch.group(1) ?? '');
        if (number != null && promotion.phanTramGiam.toInt() == number) {
          return true;
        }
      }
      
      return false;
    }).toList();
  }
  
  String _getTimeLeft(DateTime endDate) {
    final now = DateTime.now();
    final difference = endDate.difference(now);

    if (difference.isNegative) {
      return 'Đã hết hạn';
    }

    final days = difference.inDays;
    final hours = difference.inHours % 24;

    if (days > 0) {
      return 'Còn lại: ${days}d ${hours}h';
    } else if (hours > 0) {
      return 'Còn lại: ${hours}h';
    } else {
      return 'Sắp hết hạn';
    }
  }
  
  void _handlePromotionTap(BuildContext context, Promotion promotion) async {
    // Nếu có khachSanId, fetch hotel details và navigate
    if (promotion.khachSanId != null) {
      try {
        // Show loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        // Import ApiService để fetch hotel
        final apiService = ApiService();
        final hotelResponse = await apiService.getHotelById(promotion.khachSanId!);

        if (context.mounted) {
          Navigator.pop(context); // Close loading

          if (hotelResponse.success && hotelResponse.data != null) {
            final hotel = hotelResponse.data!;
            
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PropertyDetailScreen(
                  hotel: hotel,
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Không tìm thấy thông tin khách sạn'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context); // Close loading if still open
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ưu đãi này không áp dụng cho khách sạn cụ thể'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

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
    if (query.isEmpty) {
      return _buildSearchSuggestions();
    }
    
    final results = _searchPromotions(query);
    
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy ưu đãi: "$query"',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
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
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final promotion = results[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: PromotionCard(
            promotion: promotion,
            timeLeft: _getTimeLeft(promotion.ngayKetThuc),
            onTap: () => _handlePromotionTap(context, promotion),
          ),
        );
      },
    );
  }
}
