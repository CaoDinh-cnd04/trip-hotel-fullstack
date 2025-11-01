import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/services/message_service.dart';
import 'modern_chat_screen.dart';

/// Screen cho Hotel Manager tạo chat mới với Admin hoặc Users
class HotelManagerNewChatScreen extends StatefulWidget {
  const HotelManagerNewChatScreen({super.key});

  @override
  State<HotelManagerNewChatScreen> createState() => _HotelManagerNewChatScreenState();
}

class _HotelManagerNewChatScreenState extends State<HotelManagerNewChatScreen> {
  final MessageService _messageService = MessageService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _allContacts = [];
  List<Map<String, dynamic>> _filteredContacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _searchController.addListener(_filterContacts);
  }

  void _showFirebaseAuthRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cần đăng nhập lại'),
        content: const Text(
          'Để sử dụng tính năng chat, bạn cần đăng xuất và đăng nhập lại.\n\n'
          'Điều này sẽ đồng bộ tài khoản của bạn với hệ thống chat.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close this screen
            },
            child: const Text('Quay lại'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close this screen
              // Navigate to profile to logout
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/profile',
                (route) => route.isFirst,
              );
            },
            child: const Text('Đăng xuất ngay'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);

    try {
      final contacts = <Map<String, dynamic>>[];

      // Load Admins from Firestore
      final adminSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();

      for (var doc in adminSnapshot.docs) {
        final data = doc.data();
        contacts.add({
          'id': doc.id,
          'name': data['display_name'] ?? 'Admin',
          'email': data['email'] ?? '',
          'role': 'Admin',
          'photo_url': data['photo_url'],
        });
      }

      // Load Users who booked at this hotel (from user_mapping)
      // Note: Lọc users dựa trên booking history nếu cần
      // Hiện tại chỉ load tất cả users để đơn giản
      final userSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'user')
          .limit(50) // Limit to avoid loading too many
          .get();

      for (var doc in userSnapshot.docs) {
        final data = doc.data();
        contacts.add({
          'id': doc.id,
          'name': data['display_name'] ?? 'Người dùng',
          'email': data['email'] ?? '',
          'role': 'Khách hàng',
          'photo_url': data['photo_url'],
        });
      }

      setState(() {
        _allContacts = contacts;
        _filteredContacts = contacts;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading contacts: $e');
      setState(() => _isLoading = false);
      
      if (mounted) {
        final errorMessage = e.toString();
        
        // Check if error is about Firebase authentication
        if (errorMessage.contains('admin-restricted-operation') || 
            errorMessage.contains('PERMISSION_DENIED') ||
            errorMessage.contains('chưa đăng nhập Firebase')) {
          _showFirebaseAuthRequiredDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi tải danh sách: $e')),
          );
        }
      }
    }
  }

  void _filterContacts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredContacts = _allContacts.where((contact) {
        return contact['name']!.toLowerCase().contains(query) ||
               contact['email']!.toLowerCase().contains(query) ||
               contact['role']!.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _startChat(Map<String, dynamic> contact) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModernChatScreen(
          otherUserId: contact['id']!,
          otherUserName: contact['name']!,
          otherUserEmail: contact['email']!,
          otherUserRole: contact['role'] == 'Admin' ? 'admin' : 'user',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Tin nhắn mới',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo tên, email...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          
          // Contacts list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredContacts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_search, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'Không tìm thấy liên hệ',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _filteredContacts.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, indent: 72),
                        itemBuilder: (context, index) {
                          final contact = _filteredContacts[index];
                          return _buildContactTile(contact);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile(Map<String, dynamic> contact) {
    final isAdmin = contact['role'] == 'Admin';
    
    return InkWell(
      onTap: () => _startChat(contact),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundColor: isAdmin 
                  ? Colors.red.withOpacity(0.1)
                  : Colors.blue.withOpacity(0.1),
              backgroundImage: contact['photo_url'] != null
                  ? NetworkImage(contact['photo_url']!)
                  : null,
              child: contact['photo_url'] == null
                  ? Icon(
                      isAdmin ? Icons.admin_panel_settings : Icons.person,
                      color: isAdmin ? Colors.red : Colors.blue,
                      size: 28,
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            
            // Name and email
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact['name']!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    contact['email']!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Role badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isAdmin 
                    ? Colors.red.withOpacity(0.1)
                    : Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                contact['role']!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isAdmin ? Colors.red : Colors.green,
                ),
              ),
            ),
            
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}

