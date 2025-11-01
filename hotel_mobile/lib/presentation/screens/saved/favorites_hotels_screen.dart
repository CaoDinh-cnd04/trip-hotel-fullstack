/**
 * Favorites Hotels Screen
 * 
 * Màn hình hiển thị danh sách khách sạn đã lưu
 * Sử dụng SavedItemsService (lưu local bằng SharedPreferences)
 */

import 'package:flutter/material.dart';
import '../saved/saved_items_screen.dart';

class FavoritesHotelsScreen extends StatelessWidget {
  const FavoritesHotelsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Tạo mới SavedItemsScreen mỗi lần rebuild để force reload data
    print('🔄 FavoritesHotelsScreen: Tạo SavedItemsScreen mới');
    return const SavedItemsScreen();
  }
}
