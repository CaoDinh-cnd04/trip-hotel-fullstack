/**
 * Màn hình chi tiết TriphotelVIP
 * Hiển thị thông tin VIP membership, benefits, và progress
 */

import 'package:flutter/material.dart';
import '../../../data/services/user_profile_service.dart';
import '../../../core/utils/currency_formatter.dart';

class TriphotelVipScreen extends StatefulWidget {
  const TriphotelVipScreen({Key? key}) : super(key: key);

  @override
  State<TriphotelVipScreen> createState() => _TriphotelVipScreenState();
}

class _TriphotelVipScreenState extends State<TriphotelVipScreen> {
  final UserProfileService _userProfileService = UserProfileService();
  
  bool _isLoading = true;
  Map<String, dynamic>? _vipInfo;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVipInfo();
  }

  Future<void> _loadVipInfo() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await _userProfileService.getVipStatus();
      if (response.success && response.data != null) {
        setState(() {
          _vipInfo = response.data;
          _error = null;
          _isLoading = false;
        });
      } else {
        setState(() {
          // Hiển thị message từ API hoặc message mặc định
          _error = response.message ?? 'Không thể tải thông tin VIP';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Lỗi: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'TriphotelVIP',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF8B4513),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadVipInfo,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : _vipInfo != null
                  ? SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildHeader(),
                          _buildProgressCard(),
                          _buildLevelsOverview(),
                          _buildBenefitsSection(),
                        ],
                      ),
                    )
                  : const Center(child: Text('Không có dữ liệu')),
    );
  }

  Widget _buildHeader() {
    final vipLevel = _vipInfo!['vipLevel'] ?? 'Bronze';
    final vipPoints = _vipInfo!['vipPoints'] ?? 0;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _getLevelColors(vipLevel),
        ),
      ),
      child: Column(
        children: [
          // VIP Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Colors.white, size: 28),
                const SizedBox(width: 8),
                Text(
                  'VIP ${_getLevelName(vipLevel)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Điểm hiện tại',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatPoints(vipPoints),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Điểm tích lũy',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    final vipLevel = _vipInfo!['vipLevel'] ?? 'Bronze';
    final vipPoints = _vipInfo!['vipPoints'] ?? 0;
    final nextLevelPoints = _vipInfo!['nextLevelPoints'];
    final progress = _vipInfo!['progressToNextLevel'] ?? 0;

    if (nextLevelPoints == null) {
      // Đã đạt hạng cao nhất
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            const Icon(Icons.emoji_events, size: 48, color: Colors.amber),
            const SizedBox(height: 12),
            const Text(
              'Bạn đã đạt hạng cao nhất!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tiếp tục tích điểm để nhận thêm ưu đãi đặc biệt',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final currentLevelMin = _getLevelMinPoints(vipLevel);
    final pointsNeeded = nextLevelPoints - vipPoints;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tiến độ đến ${_getLevelName(_getNextLevel(vipLevel))}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${progress}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress / 100,
            minHeight: 8,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              _getLevelColor(_getNextLevel(vipLevel)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_formatPoints(vipPoints - currentLevelMin)} / ${_formatPoints(nextLevelPoints - currentLevelMin)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                'Còn ${_formatPoints(pointsNeeded)} điểm',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLevelsOverview() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Các hạng thành viên',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildLevelItem('Bronze', 0, Colors.brown),
          _buildLevelItem('Silver', 1000, Colors.grey),
          _buildLevelItem('Gold', 5000, Colors.amber),
          _buildLevelItem('Diamond', 10000, Colors.cyan),
        ],
      ),
    );
  }

  Widget _buildLevelItem(String level, int minPoints, Color color) {
    final currentLevel = _vipInfo!['vipLevel'] ?? 'Bronze';
    final isCurrent = currentLevel == level;
    final isUnlocked = _isLevelUnlocked(currentLevel, level);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrent ? color.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isCurrent
            ? Border.all(color: color, width: 2)
            : Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isUnlocked ? color : Colors.grey[300],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              isUnlocked ? Icons.star : Icons.star_border,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _getLevelName(level),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                        color: isCurrent ? color : Colors.black87,
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'HIỆN TẠI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Từ ${_formatPoints(minPoints)} điểm',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (isUnlocked)
            Icon(Icons.check_circle, color: color, size: 20),
        ],
      ),
    );
  }

  Widget _buildBenefitsSection() {
    final benefits = _vipInfo!['benefits'] as List<dynamic>? ?? [];
    final vipLevel = _vipInfo!['vipLevel'] ?? 'Bronze';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.card_giftcard, color: _getLevelColor(vipLevel)),
              const SizedBox(width: 8),
              Text(
                'Quyền lợi ${_getLevelName(vipLevel)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...benefits.map((benefit) => _buildBenefitItem(benefit.toString())),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String benefit) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              benefit,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  List<Color> _getLevelColors(String level) {
    switch (level) {
      case 'Diamond':
        return [Colors.cyan[700]!, Colors.cyan[400]!];
      case 'Gold':
        return [Colors.amber[700]!, Colors.amber[400]!];
      case 'Silver':
        return [Colors.grey[700]!, Colors.grey[400]!];
      default:
        return [const Color(0xFF8B4513), const Color(0xFFA0522D)];
    }
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case 'Diamond':
        return Colors.cyan[700]!;
      case 'Gold':
        return Colors.amber[700]!;
      case 'Silver':
        return Colors.grey[700]!;
      default:
        return const Color(0xFF8B4513);
    }
  }

  String _getLevelName(String level) {
    switch (level) {
      case 'Diamond':
        return 'Kim Cương';
      case 'Gold':
        return 'Vàng';
      case 'Silver':
        return 'Bạc';
      default:
        return 'Đồng';
    }
  }

  int _getLevelMinPoints(String level) {
    switch (level) {
      case 'Diamond':
        return 10000;
      case 'Gold':
        return 5000;
      case 'Silver':
        return 1000;
      default:
        return 0;
    }
  }

  String _getNextLevel(String currentLevel) {
    switch (currentLevel) {
      case 'Bronze':
        return 'Silver';
      case 'Silver':
        return 'Gold';
      case 'Gold':
        return 'Diamond';
      default:
        return 'Diamond';
    }
  }

  bool _isLevelUnlocked(String currentLevel, String targetLevel) {
    final levels = ['Bronze', 'Silver', 'Gold', 'Diamond'];
    final currentIndex = levels.indexOf(currentLevel);
    final targetIndex = levels.indexOf(targetLevel);
    return targetIndex <= currentIndex;
  }

  String _formatPoints(int points) {
    if (points >= 1000000) {
      return '${(points / 1000000).toStringAsFixed(1)}M';
    } else if (points >= 1000) {
      return '${(points / 1000).toStringAsFixed(1)}K';
    }
    return points.toString();
  }
}

