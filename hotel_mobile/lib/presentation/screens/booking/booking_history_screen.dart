import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hotel_mobile/data/models/booking_model.dart';
import 'package:hotel_mobile/data/services/booking_history_service.dart';
import 'package:hotel_mobile/presentation/widgets/booking_card.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/skeleton_loading_widget.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/message_service.dart';
import '../../../core/theme/vip_theme_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../chat/modern_conversation_list_screen.dart';
import '../chat/modern_chat_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:intl/intl.dart';
import 'dart:async';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({Key? key}) : super(key: key);

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> with SingleTickerProviderStateMixin {
  final BookingHistoryService _bookingService = BookingHistoryService();
  final ApiService _apiService = ApiService();
  final MessageService _messageService = MessageService();
  List<BookingModel> _bookings = [];
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;
  bool _isCreatingConversation = false;

  @override
  void initState() {
    super.initState();
    print('📖 === BookingHistoryScreen initState ===');
    _tabController = TabController(length: 3, vsync: this);
    print('📖 TabController created, calling _loadBookings()...');
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings({String? status}) async {
    print('📖 === LOADING BOOKINGS ===');
    print('📖 Status filter: $status');
    print('📖 Current state: isLoading=$_isLoading, bookings=${_bookings.length}, error=$_error');
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('📖 Calling _bookingService.getBookingHistory()...');
      final bookings = await _bookingService.getBookingHistory(status: status);
      print('📖 ✅ Loaded ${bookings.length} bookings from service');
      
      if (bookings.isNotEmpty) {
        print('📖 First booking details:');
        print('   - ID: ${bookings[0].id}');
        print('   - Code: ${bookings[0].bookingCode}');
        print('   - Hotel: ${bookings[0].hotelName}');
        print('   - Status: ${bookings[0].bookingStatus}');
      }
      
      if (mounted) {
        print('📖 Widget is mounted, updating state...');
        print('📖 Setting bookings: ${bookings.length} items');
        setState(() {
          _bookings = bookings;
          _isLoading = false;
          _error = null; // Clear any previous errors
        });
        print('📖 ✅ State updated successfully!');
        print('   - bookings.length: ${_bookings.length}');
        print('   - isLoading: $_isLoading');
        print('   - error: $_error');
        print('   - Will show: ${_bookings.isEmpty ? "Empty state" : "Booking list"}');
      } else {
        print('⚠️ Widget not mounted, skipping state update');
      }
    } catch (e, stackTrace) {
      print('❌ === BOOKING LOAD ERROR ===');
      print('❌ Error: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Stack trace: $stackTrace');
      print('❌ ========================');
      
      if (mounted) {
        setState(() {
          // Check if error is 401 (unauthorized)
          final errorStr = e.toString();
          if (errorStr.contains('401') || errorStr.contains('Unauthorized')) {
            _error = 'login_required';
          } else if (errorStr.contains('404')) {
            _error = 'Không tìm thấy dữ liệu đặt phòng';
          } else if (errorStr.contains('500') || errorStr.contains('server')) {
            _error = 'Lỗi server - Vui lòng thử lại sau';
          } else {
            _error = 'Không thể tải lịch sử: ${e.toString()}';
          }
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshBookings() async {
    final currentTab = _tabController.index;
    String? status;
    if (currentTab == 1) status = 'confirmed';
    if (currentTab == 2) status = 'cancelled';
    await _loadBookings(status: status);
  }

  Future<void> _showCancelConfirmation(BookingModel booking) async {
    final l10n = AppLocalizations.of(context)!;
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmCancelBooking),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.confirmCancelBookingMessage(booking.bookingCode)),
            const SizedBox(height: 12),
            if (booking.paymentMethod != 'cash') ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Hoàn tiền tự động',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[900],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Số tiền ${CurrencyFormatter.format(booking.finalPrice)} sẽ được hoàn lại qua ${booking.paymentMethodText} trong vòng 3-5 ngày làm việc.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[800],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.goBack),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.confirmCancel),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _cancelBooking(booking);
    }
  }

  Future<void> _cancelBooking(BookingModel booking) async {
    try {
      // Show loading
      final l10n = AppLocalizations.of(context)!;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(l10n.processingCancel),
                ],
              ),
            ),
          ),
        ),
      );

      final result = await _bookingService.cancelBooking(booking.id);
      
      if (mounted) {
        Navigator.pop(context); // Close loading
        
        final refundInfo = result['refund'];
        final refundSuccess = refundInfo?['success'] == true;
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  refundSuccess ? Icons.check_circle : Icons.info,
                  color: refundSuccess ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(l10n.cancelSuccess),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.bookingCancelled(booking.bookingCode)),
                const SizedBox(height: 12),
                if (refundSuccess) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '✓ Hoàn tiền thành công',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[900],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Số tiền: ${CurrencyFormatter.format(refundInfo['amount'])}',
                          style: TextStyle(color: Colors.green[800]),
                        ),
                        Text(
                          'Mã GD: ${refundInfo['transactionId']}',
                          style: TextStyle(fontSize: 12, color: Colors.green[700]),
                        ),
                      ],
                    ),
                  ),
                ] else if (refundInfo != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      refundInfo['message'] ?? 'Hoàn tiền đang được xử lý',
                      style: TextStyle(color: Colors.orange[900]),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _refreshBookings();
                },
                child: Text(l10n.close),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        
        // Parse error message để hiển thị thông báo rõ ràng hơn
        String errorMessage = e.toString();
        if (errorMessage.contains('cancellation_allowed') || 
            errorMessage.contains('không cho phép hủy') ||
            errorMessage.contains('chính sách')) {
          errorMessage = 'Đơn đặt phòng này không cho phép hủy theo chính sách khách sạn (giá ưu đãi không hoàn tiền)';
        } else if (errorMessage.contains('24') || 
                   errorMessage.contains('giờ') ||
                   errorMessage.contains('24 giờ')) {
          errorMessage = 'Chỉ có thể hủy phòng trước 24 giờ so với thời gian nhận phòng.\n\n'
              'Thời gian nhận phòng: ${DateFormat('dd/MM/yyyy HH:mm').format(booking.checkInDate)}';
        } else if (errorMessage.contains('status') || 
                   errorMessage.contains('trạng thái')) {
          errorMessage = 'Đơn đặt phòng này không thể hủy do trạng thái hiện tại';
        }
        
        showDialog(
          context: context,
          builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(l10n.cannotCancelBooking),
                ],
              ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  errorMessage,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                // Hiển thị thông tin booking để debug
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thông tin đặt phòng:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Có thể hủy: ${booking.cancellationAllowed ? "Có" : "Không"}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      Text(
                        '• Trạng thái: ${booking.bookingStatus}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      Text(
                        '• Nhận phòng: ${DateFormat('dd/MM/yyyy HH:mm').format(booking.checkInDate)}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      Text(
                        '• Thời gian còn lại: ${booking.secondsLeftToCancel ~/ 3600} giờ',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.close),
                ),
              ],
            );
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Debug log
    print('📖 === BUILD CALLED ===');
    print('   - isLoading: $_isLoading');
    print('   - error: $_error');
    print('   - bookings.length: ${_bookings.length}');
    print('   - Will show: ${_isLoading ? "Loading" : (_error != null ? "Error" : (_bookings.isEmpty ? "Empty" : "List"))}');
    
    // ✅ Sử dụng VIP theme colors
    final vipTheme = Provider.of<VipThemeProvider>(context, listen: false);
    
    return Scaffold(
      backgroundColor: vipTheme.backgroundColor,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.bookingHistory),
        backgroundColor: vipTheme.primaryColor, // ✅ VIP theme color
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          onTap: (index) {
            String? status;
            if (index == 1) status = 'confirmed';
            if (index == 2) status = 'cancelled';
            _loadBookings(status: status);
          },
          tabs: const [
            Tab(text: 'Tất cả'),
            Tab(text: 'Đã xác nhận'),
            Tab(text: 'Đã hủy'),
          ],
        ),
      ),
      body: _isLoading
          ? SkeletonLoadingWidget(
              itemType: LoadingItemType.bookingCard,
              itemCount: 5,
            )
              : _error != null
                  ? _buildErrorWidget()
              : _bookings.isEmpty
                  ? _buildEmptyState()
                  : _buildBookingList(),
    );
  }

  Widget _buildErrorWidget() {
    // Check if error is login required
    if (_error == 'login_required') {
      return LoginRequiredWidget(
        onLogin: () {
          Navigator.pushNamed(context, '/login').then((_) {
            // Reload bookings after login
            _loadBookings();
          });
        },
      );
    }

    // Check if error is network related
    if (_error != null && 
        (_error!.toLowerCase().contains('network') || 
         _error!.toLowerCase().contains('kết nối') ||
         _error!.toLowerCase().contains('timeout'))) {
      return NetworkErrorWidget(
        onRetry: _refreshBookings,
      );
    }

    // Check if error is server related
    if (_error != null && 
        (_error!.contains('500') || 
         _error!.toLowerCase().contains('server') ||
         _error!.toLowerCase().contains('máy chủ'))) {
      return ServerErrorWidget(
        message: _error,
        onRetry: _refreshBookings,
      );
    }

    // Generic error
    return ErrorStateWidget(
      title: 'Có lỗi xảy ra',
      message: _error,
      onRetry: _refreshBookings,
    );
  }

  Widget _buildEmptyState() {
      return EmptyBookingsWidget(
        onExplore: () {
          Navigator.pushNamed(context, '/home');
        },
      );
  }

  Widget _buildOldEmptyState() {
      return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.hotel_outlined,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có đơn đặt phòng nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy khám phá và đặt khách sạn yêu thích của bạn',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBookingList() {
    return RefreshIndicator(
      onRefresh: _refreshBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _bookings.length,
        itemBuilder: (context, index) {
          final booking = _bookings[index];
          return BookingCard(
            booking: booking,
            onCancel: () => _showCancelConfirmation(booking),
            onRefresh: _refreshBookings,
            onChatWithHotel: () => _chatWithHotel(booking),
          );
        },
      ),
    );
  }

  Future<void> _chatWithHotel(BookingModel booking) async {
    if (_isCreatingConversation) return;
    
    setState(() => _isCreatingConversation = true);

    try {
      // Fetch hotel details to get manager info
      print('🏨 Fetching hotel details for booking: ${booking.bookingCode}');
      print('   - Hotel ID: ${booking.hotelId}');
      
      final hotelResponse = await _apiService.getHotelById(booking.hotelId);
      final hotel = hotelResponse.data;
      
      if (hotel == null) {
        throw Exception('Không tìm thấy thông tin khách sạn');
      }
      
      print('   - Hotel Name: ${hotel.ten}');
      print('   - Manager ID: ${hotel.nguoiQuanLyId}');
      print('   - Manager Name: ${hotel.tenNguoiQuanLy}');
      
      if (hotel.nguoiQuanLyId == null) {
        // Hotel has no manager
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(l10n.contactSupport),
                ],
              ),
              content: Text(
                'Khách sạn "${hotel.ten}" chưa có quản lý trên hệ thống.\n\n'
                'Bạn có thể:\n'
                '• Liên hệ trực tiếp qua số điện thoại: ${hotel.sdtLienHe ?? "Đang cập nhật"}\n'
                '• Email: ${hotel.emailLienHe ?? "Đang cập nhật"}\n'
                '• Chat với bộ phận hỗ trợ của chúng tôi',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.close),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ModernConversationListScreen(),
                      ),
                    );
                  },
                  child: Text(l10n.supportChat),
                ),
              ],
            ),
          );
        }
        return;
      }

      // Create conversation with hotel manager
      print('✅ Creating conversation with manager...');
      print('🔍 Firebase Auth Status:');
      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      print('   - Logged in: ${firebaseUser != null}');
      print('   - Firebase UID: ${firebaseUser?.uid ?? "N/A"}');
      print('   - Email: ${firebaseUser?.email ?? "N/A"}');
      
      if (firebaseUser == null) {
        throw Exception('Bạn cần đăng nhập lại để sử dụng chức năng chat');
      }
      
      // Get manager's Firebase UID FIRST (same logic as createBookingConversation)
      String managerFirebaseUid;
      try {
        final doc = await FirebaseFirestore.instance
            .collection('user_mapping')
            .doc(hotel.nguoiQuanLyId.toString())
            .get();
        
        if (doc.exists && doc.data()?['firebase_uid'] != null) {
          managerFirebaseUid = doc.data()!['firebase_uid'];
          print('✅ Manager Firebase UID from mapping: $managerFirebaseUid');
        } else {
          // Manager not in Firebase yet - use placeholder
          managerFirebaseUid = 'offline_${hotel.nguoiQuanLyId}';
          print('⚠️ Manager not in Firebase, using placeholder: $managerFirebaseUid');
        }
      } catch (e) {
        print('❌ Error getting manager UID: $e');
        managerFirebaseUid = 'offline_${hotel.nguoiQuanLyId}';
      }
      
      print('🔍 Will use manager UID for conversation: $managerFirebaseUid');
      
      // Create conversation (this will use the SAME UID internally)
      await _messageService.createBookingConversation(
        hotelManagerId: hotel.nguoiQuanLyId.toString(),
        hotelManagerName: hotel.tenNguoiQuanLy ?? 'Quản lý',
        hotelManagerEmail: hotel.emailNguoiQuanLy ?? '',
        hotelName: hotel.ten,
        bookingId: booking.bookingCode,
      );

      print('✅ Conversation created with manager UID: $managerFirebaseUid');
      
      if (mounted) {
        // Navigate directly to chat screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ModernChatScreen(
              otherUserId: managerFirebaseUid,
              otherUserName: hotel.tenNguoiQuanLy ?? 'Quản lý khách sạn',
              otherUserEmail: hotel.emailNguoiQuanLy ?? '',
              otherUserRole: 'hotel_manager',
            ),
          ),
        );
        
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('💬 ${l10n.openingChat(hotel.tenNguoiQuanLy ?? "khách sạn")}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Error creating conversation: $e');
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('⚠️ ${l10n.errorCreatingConversation}'),
            content: Text('${l10n.cannotCreateConversation}: ${e.toString()}\n\n'
                '${l10n.tryAgain}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.close),
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
}
