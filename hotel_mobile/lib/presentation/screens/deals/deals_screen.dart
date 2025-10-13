import 'package:flutter/material.dart';
import 'package:hotel_mobile/data/models/promotion.dart';
import 'package:hotel_mobile/data/services/api_service.dart';
import 'package:hotel_mobile/presentation/widgets/deals_header.dart';
import 'package:hotel_mobile/presentation/widgets/personal_offers_card.dart';
import 'package:hotel_mobile/presentation/widgets/deals_tab_bar.dart';
import 'package:hotel_mobile/presentation/widgets/promotion_card.dart';

class DealsScreen extends StatefulWidget {
  const DealsScreen({super.key});

  @override
  State<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends State<DealsScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;

  List<Promotion> _allPromotions = [];
  List<Promotion> _filteredPromotions = [];
  bool _isLoading = true;
  String? _error;
  int _selectedTabIndex = 0;

  // Mock data for personal offers
  final int _personalPoints = 1250;
  final String _personalPromoCode = 'SUMMER2024';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadPromotions();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
      _filterPromotions();
    }
  }

  Future<void> _loadPromotions() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await _apiService.getPromotions(active: true);

      if (response.success) {
        setState(() {
          _allPromotions = response.data ?? [];
          _filterPromotions();
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
        _error = 'Lỗi kết nối: $e';
        _isLoading = false;
      });
    }
  }

  void _filterPromotions() {
    final now = DateTime.now();

    setState(() {
      switch (_selectedTabIndex) {
        case 0: // Giờ chót
          _filteredPromotions = _allPromotions.where((promotion) {
            // Filter for promotions ending within 24 hours
            final hoursLeft = promotion.ngayKetThuc.difference(now).inHours;
            return hoursLeft <= 24 && hoursLeft > 0;
          }).toList();
          break;
        case 1: // Gần tôi
          _filteredPromotions = _allPromotions.where((promotion) {
            // For demo, show all active promotions
            // In real app, filter by location
            return promotion.ngayKetThuc.isAfter(now);
          }).toList();
          break;
        case 2: // Khuyến mãi theo điểm đến
          _filteredPromotions = _allPromotions.where((promotion) {
            // Show promotions with higher discount rates
            return promotion.phanTramGiam >= 10;
          }).toList();
          break;
        default:
          _filteredPromotions = _allPromotions;
      }

      // Sort by discount percentage (highest first)
      _filteredPromotions.sort(
        (a, b) => b.phanTramGiam.compareTo(a.phanTramGiam),
      );
    });
  }

  String _getTimeLeft(DateTime endDate) {
    final now = DateTime.now();
    final difference = endDate.difference(now);

    if (difference.isNegative) {
      return 'Đã hết hạn';
    }

    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;

    if (days > 0) {
      return 'Còn lại: ${days}d ${hours}h';
    } else if (hours > 0) {
      return 'Còn lại: ${hours}h ${minutes}m';
    } else {
      return 'Còn lại: ${minutes}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Header
            const DealsHeader(),

            // Personal Offers Card
            PersonalOffersCard(
              points: _personalPoints,
              promoCode: _personalPromoCode,
            ),

            const SizedBox(height: 16),

            // Tab Bar
            DealsTabBar(
              tabController: _tabController,
              tabs: const ['Giờ chót', 'Gần tôi', 'Theo điểm đến'],
            ),

            const SizedBox(height: 16),

            // Content
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPromotions,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_filteredPromotions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_offer_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Không có ưu đãi nào',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy quay lại sau để xem ưu đãi mới',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPromotions,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filteredPromotions.length,
        itemBuilder: (context, index) {
          final promotion = _filteredPromotions[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: PromotionCard(
              promotion: promotion,
              timeLeft: _getTimeLeft(promotion.ngayKetThuc),
              onTap: () => _handlePromotionTap(promotion),
            ),
          );
        },
      ),
    );
  }

  void _handlePromotionTap(Promotion promotion) {
    // Navigate to promotion detail or apply promotion
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(promotion.ten),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (promotion.moTa != null) ...[
              Text(promotion.moTa!),
              const SizedBox(height: 16),
            ],
            Text(
              'Giảm ${promotion.phanTramGiam.toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Có hiệu lực đến: ${promotion.ngayKetThuc.day}/${promotion.ngayKetThuc.month}/${promotion.ngayKetThuc.year}',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Apply promotion logic here
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã áp dụng ưu đãi ${promotion.ten}'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Áp dụng'),
          ),
        ],
      ),
    );
  }
}
