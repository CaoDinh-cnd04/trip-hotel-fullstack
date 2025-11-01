import 'package:flutter/material.dart';
import '../saved/saved_items_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Sử dụng SavedItemsScreen thay vì tạo màn hình riêng
    return const SavedItemsScreen();
  }
}