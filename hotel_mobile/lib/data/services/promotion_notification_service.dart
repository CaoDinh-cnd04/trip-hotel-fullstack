import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/promotion.dart';
import 'api_service.dart';

/// Service to check for new promotions and notify users
class PromotionNotificationService {
  static const String _lastCheckedKey = 'last_promotion_check';
  static const String _seenPromotionsKey = 'seen_promotions';

  final ApiService _apiService = ApiService();

  /// Check for new promotions since last check
  /// Returns list of new promotions
  Future<List<Promotion>> checkForNewPromotions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get list of previously seen promotion IDs
      final seenPromotionIds = _getSeenPromotionIds(prefs);
      
      // Fetch current active promotions
      final response = await _apiService.getPromotions(
        active: true,
        limit: 50,
      );

      if (!response.success || response.data == null) {
        return [];
      }

      final allPromotions = response.data!;
      
      // Filter for new promotions (not in seen list)
      final newPromotions = allPromotions.where((promo) {
        return !seenPromotionIds.contains(promo.id);
      }).toList();

      // Update last checked time
      await prefs.setInt(_lastCheckedKey, DateTime.now().millisecondsSinceEpoch);

      // Mark new promotions as seen
      if (newPromotions.isNotEmpty) {
        await _markPromotionsAsSeen(prefs, newPromotions);
      }

      return newPromotions;
    } catch (e) {
      print('❌ Error checking for new promotions: $e');
      return [];
    }
  }

  /// Get list of seen promotion IDs
  Set<int> _getSeenPromotionIds(SharedPreferences prefs) {
    final seenJson = prefs.getString(_seenPromotionsKey);
    if (seenJson == null) {
      return {};
    }
    
    try {
      final List<dynamic> seenList = jsonDecode(seenJson);
      return seenList.map((id) => id as int).toSet();
    } catch (e) {
      return {};
    }
  }

  /// Mark promotions as seen
  Future<void> _markPromotionsAsSeen(
    SharedPreferences prefs,
    List<Promotion> promotions,
  ) async {
    final currentSeenIds = _getSeenPromotionIds(prefs);
    final newIds = promotions.map((p) => p.id).whereType<int>().toSet();
    final updatedSeenIds = currentSeenIds.union(newIds);
    
    await prefs.setString(
      _seenPromotionsKey,
      jsonEncode(updatedSeenIds.toList()),
    );
  }

  /// Get time since last check (in minutes)
  Future<int?> getMinutesSinceLastCheck() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastChecked = prefs.getInt(_lastCheckedKey);
      
      if (lastChecked == null) {
        return null;
      }
      
      final lastCheckedDate = DateTime.fromMillisecondsSinceEpoch(lastChecked);
      final now = DateTime.now();
      final difference = now.difference(lastCheckedDate);
      
      return difference.inMinutes;
    } catch (e) {
      return null;
    }
  }

  /// Clear all seen promotions (for testing)
  Future<void> clearSeenPromotions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_seenPromotionsKey);
    await prefs.remove(_lastCheckedKey);
  }

  /// Should check for new promotions?
  /// Returns true if last check was more than 30 minutes ago or never checked
  Future<bool> shouldCheckForNewPromotions() async {
    final minutesSinceLastCheck = await getMinutesSinceLastCheck();
    
    if (minutesSinceLastCheck == null) {
      return true; // Never checked before
    }
    
    return minutesSinceLastCheck >= 30; // Check every 30 minutes
  }
}

