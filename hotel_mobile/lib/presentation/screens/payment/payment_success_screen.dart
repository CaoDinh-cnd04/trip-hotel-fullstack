import 'package:flutter/material.dart';
import 'package:hotel_mobile/data/models/hotel.dart';
import 'package:hotel_mobile/data/models/room.dart';
import 'package:hotel_mobile/presentation/screens/main_navigation_screen.dart';
import 'package:hotel_mobile/data/services/message_service.dart';
import 'package:hotel_mobile/presentation/screens/chat/modern_conversation_list_screen.dart';
import 'package:hotel_mobile/presentation/screens/chat/modern_chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentSuccessScreen extends StatefulWidget {
  final Hotel hotel;
  final Room room;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int guestCount;
  final int nights;
  final double totalAmount;
  final String orderId;

  const PaymentSuccessScreen({
    super.key,
    required this.hotel,
    required this.room,
    required this.checkInDate,
    required this.checkOutDate,
    required this.guestCount,
    required this.nights,
    required this.totalAmount,
    required this.orderId,
  });

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen> {
  final MessageService _messageService = MessageService();
  bool _isCreatingConversation = false;

  Future<void> _chatWithHotel() async {
    print('🏨 Chat with hotel:');
    print('   - Hotel ID: ${widget.hotel.id}');
    print('   - Hotel Name: ${widget.hotel.ten}');
    print('   - Manager ID: ${widget.hotel.nguoiQuanLyId}');
    print('   - Manager Name: ${widget.hotel.tenNguoiQuanLy}');
    print('   - Manager Email: ${widget.hotel.emailNguoiQuanLy}');
    
    setState(() => _isCreatingConversation = true);

    try {
      // If hotel has no manager, show dialog to contact support
      if (widget.hotel.nguoiQuanLyId == null) {
        print('❌ Hotel has no manager assigned');
        setState(() => _isCreatingConversation = false);
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Liên hệ hỗ trợ'),
                ],
              ),
              content: Text(
                'Khách sạn "${widget.hotel.ten}" chưa có quản lý trên hệ thống.\n\n'
                'Bạn có thể:\n'
                '• Liên hệ trực tiếp qua số điện thoại: ${widget.hotel.sdtLienHe ?? "Đang cập nhật"}\n'
                '• Email: ${widget.hotel.emailLienHe ?? "Đang cập nhật"}\n'
                '• Chat với bộ phận hỗ trợ của chúng tôi',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Đóng'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Navigate to conversation list to chat with support/admin
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ModernConversationListScreen(),
                      ),
                    );
                  },
                  child: const Text('Chat hỗ trợ'),
                ),
              ],
            ),
          );
        }
        return;
      }

      // Create conversation with hotel manager
      print('✅ Hotel has manager, creating conversation...');
      print('   - Manager ID to chat: ${widget.hotel.nguoiQuanLyId}');
      print('   - Booking ID: ${widget.orderId}');
      
      // Check Firebase Auth
      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      print('🔍 Firebase Auth Status:');
      print('   - Logged in: ${firebaseUser != null}');
      print('   - Firebase UID: ${firebaseUser?.uid ?? "N/A"}');
      
      if (firebaseUser == null) {
        throw Exception('Bạn cần đăng nhập lại để sử dụng chức năng chat');
      }
      
      // Get manager's Firebase UID FIRST (same logic as createBookingConversation)
      String managerFirebaseUid;
      try {
        final doc = await FirebaseFirestore.instance
            .collection('user_mapping')
            .doc(widget.hotel.nguoiQuanLyId.toString())
            .get();
        
        if (doc.exists && doc.data()?['firebase_uid'] != null) {
          managerFirebaseUid = doc.data()!['firebase_uid'];
          print('✅ Manager Firebase UID from mapping: $managerFirebaseUid');
        } else {
          // Manager not in Firebase yet - use placeholder
          managerFirebaseUid = 'offline_${widget.hotel.nguoiQuanLyId}';
          print('⚠️ Manager not in Firebase, using placeholder: $managerFirebaseUid');
        }
      } catch (e) {
        print('❌ Error getting manager UID: $e');
        managerFirebaseUid = 'offline_${widget.hotel.nguoiQuanLyId}';
      }
      
      print('🔍 Will use manager UID for conversation: $managerFirebaseUid');
      
      // Create conversation (this will use the SAME UID internally)
      await _messageService.createBookingConversation(
        hotelManagerId: widget.hotel.nguoiQuanLyId.toString(),
        hotelManagerName: widget.hotel.tenNguoiQuanLy ?? 'Quản lý',
        hotelManagerEmail: widget.hotel.emailNguoiQuanLy ?? '',
        hotelName: widget.hotel.ten,
        bookingId: widget.orderId,
      );
      
      print('✅ Conversation created with manager UID: $managerFirebaseUid');

      if (mounted) {
        // Navigate directly to chat screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ModernChatScreen(
              otherUserId: managerFirebaseUid,
              otherUserName: widget.hotel.tenNguoiQuanLy ?? 'Quản lý khách sạn',
              otherUserEmail: widget.hotel.emailNguoiQuanLy ?? '',
              otherUserRole: 'hotel_manager',
            ),
          ),
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('💬 Đang mở chat với ${widget.hotel.tenNguoiQuanLy ?? "khách sạn"}...'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Error creating conversation: $e');
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('⚠️ Lỗi tạo cuộc trò chuyện'),
            content: Text('Không thể tạo cuộc trò chuyện: ${e.toString()}\n\n'
                'Vui lòng thử lại sau hoặc liên hệ trực tiếp với khách sạn.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Đóng'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreatingConversation = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Thanh toán thành công'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        automaticallyImplyLeading: false, // Remove back button
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              // Navigate to home screen safely with post frame callback
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const MainNavigationScreen(),
                    ),
                    (route) => false,
                  );
                }
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Success Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.green[50],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.green[200]!, width: 2),
              ),
              child: Icon(
                Icons.check_circle,
                size: 80,
                color: Colors.green[600],
              ),
            ),

            const SizedBox(height: 24),

            // Success Message
            Text(
              'Thanh toán thành công!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Text(
              'Đặt phòng của bạn đã được xác nhận',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Booking Details Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.receipt_long, color: Colors.blue[600], size: 24),
                      const SizedBox(width: 12),
                      const Text(
                        'Chi tiết đặt phòng',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Hotel Info
                  _buildInfoRow('Khách sạn', widget.hotel.ten),
                  _buildInfoRow('Phòng', widget.room.tenLoaiPhong ?? 'Standard Room'),
                  _buildInfoRow('Địa chỉ', widget.hotel.diaChi ?? ''),
                  _buildInfoRow('Ngày nhận phòng', _formatDate(widget.checkInDate)),
                  _buildInfoRow('Ngày trả phòng', _formatDate(widget.checkOutDate)),
                  _buildInfoRow('Số đêm', '${widget.nights} đêm'),
                  _buildInfoRow('Số khách', '${widget.guestCount} khách'),
                  _buildInfoRow('Mã đặt phòng', widget.orderId),
                  
                  const SizedBox(height: 16),
                  
                  // Divider
                  Container(height: 1, color: Colors.grey[300]),
                  
                  const SizedBox(height: 16),
                  
                  // Total Amount
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tổng tiền',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '${widget.totalAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} VNĐ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Important Notes
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue[600], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Thông tin quan trọng',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '• Email xác nhận đã được gửi đến địa chỉ email của bạn\n'
                    '• Vui lòng mang theo CMND/CCCD khi nhận phòng\n'
                    '• Thời gian check-in: 14:00 - 22:00\n'
                    '• Thời gian check-out: 06:00 - 12:00',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue[700],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Action Buttons
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to booking history safely with post frame callback
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) => const MainNavigationScreen(),
                            ),
                            (route) => false,
                          );
                        }
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Xem lịch sử đặt phòng',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Chat với khách sạn button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isCreatingConversation ? null : _chatWithHotel,
                    icon: _isCreatingConversation
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.chat_bubble_outline),
                    label: Text(
                      _isCreatingConversation ? 'Đang kết nối...' : 'Chat với khách sạn',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () {
                      // Navigate to home screen safely with post frame callback
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) => const MainNavigationScreen(),
                            ),
                            (route) => false,
                          );
                        }
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue[600],
                      side: BorderSide(color: Colors.blue[600]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Về trang chủ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
