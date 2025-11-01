import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SearchHistoryService {
  static const String _searchHistoryKey = 'search_history';
  static const String _lastSearchKey = 'last_search';

  // Lưu lịch sử tìm kiếm
  static Future<void> saveSearchHistory({
    required String location,
    required DateTime checkInDate,
    required DateTime checkOutDate,
    required int rooms,
    required int adults,
    required int children,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Tạo search data
      final searchData = {
        'location': location,
        'checkInDate': checkInDate.toIso8601String(),
        'checkOutDate': checkOutDate.toIso8601String(),
        'rooms': rooms,
        'adults': adults,
        'children': children,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Lưu search gần nhất
      await prefs.setString(_lastSearchKey, jsonEncode(searchData));

      // Lấy lịch sử hiện tại
      final historyJson = prefs.getString(_searchHistoryKey);
      List<Map<String, dynamic>> history = [];
      
      if (historyJson != null) {
        final List<dynamic> historyList = jsonDecode(historyJson);
        history = historyList.cast<Map<String, dynamic>>();
      }

      // Thêm search mới vào đầu danh sách
      history.insert(0, searchData);

      // Giới hạn tối đa 10 lần tìm kiếm
      if (history.length > 10) {
        history = history.take(10).toList();
      }

      // Lưu lại lịch sử
      await prefs.setString(_searchHistoryKey, jsonEncode(history));
      
      print('✅ Đã lưu lịch sử tìm kiếm: $location');
    } catch (e) {
      print('❌ Lỗi lưu lịch sử tìm kiếm: $e');
    }
  }

  // Lấy lần tìm kiếm gần nhất
  static Future<Map<String, dynamic>?> getLastSearch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSearchJson = prefs.getString(_lastSearchKey);
      
      if (lastSearchJson != null) {
        return jsonDecode(lastSearchJson);
      }
      return null;
    } catch (e) {
      print('❌ Lỗi lấy lịch sử tìm kiếm: $e');
      return null;
    }
  }

  // Lấy toàn bộ lịch sử tìm kiếm
  static Future<List<Map<String, dynamic>>> getSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_searchHistoryKey);
      
      if (historyJson != null) {
        final List<dynamic> historyList = jsonDecode(historyJson);
        return historyList.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('❌ Lỗi lấy lịch sử tìm kiếm: $e');
      return [];
    }
  }

  // Xóa lịch sử tìm kiếm
  static Future<void> clearSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_searchHistoryKey);
      await prefs.remove(_lastSearchKey);
      print('✅ Đã xóa lịch sử tìm kiếm');
    } catch (e) {
      print('❌ Lỗi xóa lịch sử tìm kiếm: $e');
    }
  }

  // Format ngày tháng cho hiển thị
  static String formatDateRange(DateTime checkIn, DateTime checkOut) {
    final weekdays = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    final months = ['thg 1', 'thg 2', 'thg 3', 'thg 4', 'thg 5', 'thg 6', 
                   'thg 7', 'thg 8', 'thg 9', 'thg 10', 'thg 11', 'thg 12'];
    
    final checkInStr = '${weekdays[checkIn.weekday % 7]}, ${checkIn.day} ${months[checkIn.month - 1]}';
    final checkOutStr = '${weekdays[checkOut.weekday % 7]}, ${checkOut.day} ${months[checkOut.month - 1]}';
    
    return '$checkInStr - $checkOutStr';
  }

  // Format thông tin khách
  static String formatGuestInfo(int rooms, int adults, int children) {
    String result = '$rooms Phòng $adults Người lớn';
    if (children > 0) {
      result += ' $children Trẻ em';
    }
    return result;
  }
}
