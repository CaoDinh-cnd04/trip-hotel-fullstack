import 'package:flutter/material.dart';
import '../../../data/services/hotel_registration_service.dart';
import '../../../data/services/backend_auth_service.dart';
import '../../../core/constants/app_constants.dart';
import 'package:intl/intl.dart';

class HotelRegistrationManagementScreen extends StatefulWidget {
  const HotelRegistrationManagementScreen({Key? key}) : super(key: key);

  @override
  State<HotelRegistrationManagementScreen> createState() =>
      _HotelRegistrationManagementScreenState();
}

class _HotelRegistrationManagementScreenState
    extends State<HotelRegistrationManagementScreen> with SingleTickerProviderStateMixin {
  final _hotelRegistrationService = HotelRegistrationService();
  final _backendAuthService = BackendAuthService();
  
  late TabController _tabController;
  List<HotelRegistration> _allRegistrations = [];
  List<HotelRegistration> _pendingRegistrations = [];
  List<HotelRegistration> _approvedRegistrations = [];
  List<HotelRegistration> _rejectedRegistrations = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadRegistrations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Load tất cả đơn đăng ký khách sạn từ API
  /// 
  /// Gọi API lấy tất cả đơn đăng ký
  /// Phân loại theo status: pending, approved, rejected
  /// Update state để hiển thị trong từng tab
  Future<void> _loadRegistrations() async {
    setState(() => _isLoading = true);

    try {
      final token = _backendAuthService.getToken();
      if (token == null) {
        throw Exception('No token found');
      }

      final registrations = await _hotelRegistrationService.getAllRegistrations(token);

      setState(() {
        _allRegistrations = registrations;
        _pendingRegistrations = registrations.where((r) => r.status == 'pending').toList();
        _approvedRegistrations = registrations.where((r) => r.status == 'approved').toList();
        _rejectedRegistrations = registrations.where((r) => r.status == 'rejected').toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải dữ liệu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Cập nhật trạng thái đơn đăng ký (Duyệt hoặc Từ chối)
  /// 
  /// Flow:
  /// 1. Show dialog nhập ghi chú admin
  /// 2. Gọi API cập nhật trạng thái
  /// 3. Khi duyệt (approved): Backend tự động tạo tài khoản Hotel Manager
  /// 4. Reload danh sách để cập nhật UI
  /// 
  /// Parameters:
  ///   - registration: Đơn đăng ký cần cập nhật
  ///   - newStatus: Trạng thái mới (approved/rejected)
  Future<void> _updateStatus(HotelRegistration registration, String newStatus) async {
    // Show confirmation dialog
    final adminNote = await _showStatusDialog(newStatus);
    if (adminNote == null) return; // User cancelled

    final token = _backendAuthService.getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập lại')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await _hotelRegistrationService.updateRegistrationStatus(
        registrationId: registration.id,
        status: newStatus,
        token: token,
        adminNote: adminNote.isNotEmpty ? adminNote : null,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã cập nhật trạng thái thành "$newStatus"'),
              backgroundColor: Colors.green,
            ),
          );
          _loadRegistrations(); // Reload data
        }
      } else {
        throw Exception('Failed to update status');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Hiển thị dialog để nhập ghi chú admin
  /// 
  /// Nếu approved: Ghi chú optional
  /// Nếu rejected: Ghi chú bắt buộc (lý do từ chối)
  /// 
  /// Returns: Ghi chú của admin, null nếu user cancel
  Future<String?> _showStatusDialog(String status) async {
    final controller = TextEditingController();
    String title = '';
    String hint = '';

    switch (status) {
      case 'approved':
        title = 'Duyệt đơn đăng ký';
        hint = 'Ghi chú cho chủ khách sạn (tùy chọn)';
        break;
      case 'rejected':
        title = 'Từ chối đơn đăng ký';
        hint = 'Lý do từ chối (bắt buộc)';
        break;
      default:
        title = 'Cập nhật trạng thái';
        hint = 'Ghi chú';
    }

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: hint,
                border: const OutlineInputBorder(),
              ),
            ),
            if (status == 'approved')
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'Hệ thống sẽ tự động tạo tài khoản quản lý cho chủ khách sạn.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (status == 'rejected' && controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập lý do từ chối')),
                );
                return;
              }
              Navigator.pop(context, controller.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: status == 'approved' ? Colors.green : Colors.red,
            ),
            child: Text(status == 'approved' ? 'Duyệt' : 'Từ chối'),
          ),
        ],
      ),
    );
  }

  /// Hiển thị full-screen chi tiết đơn đăng ký
  /// 
  /// Show đầy đủ thông tin:
  /// - Header với ảnh khách sạn (placeholder)
  /// - Thông tin khách sạn: Tên, loại hình, địa chỉ, hạng sao
  /// - Thông tin chủ: Tên, email, SĐT, mã số thuế
  /// - Danh sách phòng (nếu có)
  /// - Mô tả, trạng thái, ngày đăng ký
  /// - Ghi chú admin (nếu có)
  /// - Bottom actions: Duyệt/Từ chối (nếu pending)
  void _showDetailDialog(HotelRegistration registration) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _HotelRegistrationDetailScreen(
          registration: registration,
          onApprove: () {
            Navigator.pop(context);
            _updateStatus(registration, 'approved');
          },
          onReject: () {
            Navigator.pop(context);
            _updateStatus(registration, 'rejected');
          },
        ),
      ),
    );
  }

  /// Build một row hiển thị label : value trong detail dialog
  /// 
  /// Format: "Label: Value"
  /// Label có width cố định 100, value tự động wrap
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý đăng ký khách sạn'),
        backgroundColor: const Color(0xFF2C5AA0),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            Tab(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Tất cả'),
                  Text(
                    '(${_allRegistrations.length})',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            Tab(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Chờ duyệt'),
                  Text(
                    '(${_pendingRegistrations.length})',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            Tab(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Đã duyệt'),
                  Text(
                    '(${_approvedRegistrations.length})',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            Tab(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Từ chối'),
                  Text(
                    '(${_rejectedRegistrations.length})',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadRegistrations,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildRegistrationList(_allRegistrations),
                  _buildRegistrationList(_pendingRegistrations),
                  _buildRegistrationList(_approvedRegistrations),
                  _buildRegistrationList(_rejectedRegistrations),
                ],
              ),
            ),
    );
  }

  /// Build danh sách đơn đăng ký dạng list
  /// 
  /// Nếu rỗng: Show empty state với icon inbox
  /// Nếu có data: Show ListView với các registration card
  Widget _buildRegistrationList(List<HotelRegistration> registrations) {
    if (registrations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Không có đơn đăng ký nào',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: registrations.length,
      itemBuilder: (context, index) {
        final registration = registrations[index];
        return _buildRegistrationCard(registration);
      },
    );
  }

  /// Build card hiển thị thông tin tóm tắt của một đơn đăng ký
  /// 
  /// Hiển thị:
  /// - Header: Icon khách sạn, tên, loại hình, badge trạng thái
  /// - Info: Địa chỉ, chủ sở hữu, email, SĐT, ngày đăng ký
  /// - Actions: Button Duyệt/Từ chối (nếu status = pending)
  /// 
  /// Tap vào card → Show detail dialog
  Widget _buildRegistrationCard(HotelRegistration registration) {
    Color statusColor;
    IconData statusIcon;

    switch (registration.status) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showDetailDialog(registration),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE65100).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.business,
                      color: Color(0xFFE65100),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          registration.hotelName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          registration.hotelTypeText,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          registration.statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Info
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      registration.address,
                      style: const TextStyle(fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    registration.ownerName,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.email, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    registration.ownerEmail,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.phone, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    registration.ownerPhone,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(registration.createdAt),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),

              // Actions
              if (registration.status == 'pending') ...[
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _updateStatus(registration, 'rejected'),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Từ chối'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _updateStatus(registration, 'approved'),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Duyệt'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// ✨ Full-screen detail screen for hotel registration
/// 
/// Hiển thị chi tiết đầy đủ với thiết kế đẹp:
/// - Hero header với placeholder image
/// - Info cards cho hotel & owner info
/// - Room list with images (if available)
/// - Bottom action buttons
class _HotelRegistrationDetailScreen extends StatelessWidget {
  final HotelRegistration registration;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _HotelRegistrationDetailScreen({
    required this.registration,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    // Parse rooms data if available
    List<Map<String, dynamic>> rooms = [];
    if (registration.roomsData != null && registration.roomsData!.isNotEmpty) {
      try {
        final dynamic decoded = registration.roomsData;
        if (decoded is List) {
          rooms = List<Map<String, dynamic>>.from(decoded);
        }
      } catch (e) {
        print('⚠️ Error parsing rooms data: $e');
      }
    }

    Color statusColor;
    IconData statusIcon;
    switch (registration.status) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero Header with Image
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF2C5AA0),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Hotel image (real or placeholder)
                  if (registration.hotelImages != null && registration.hotelImages!.isNotEmpty)
                    Image.network(
                      '${AppConstants.baseUrl}${registration.hotelImages!.first}',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                const Color(0xFF2C5AA0).withOpacity(0.7),
                                const Color(0xFF2C5AA0),
                              ],
                            ),
                          ),
                          child: Icon(
                            Icons.hotel,
                            size: 80,
                            color: Colors.white.withOpacity(0.3),
                          ),
                        );
                      },
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF2C5AA0).withOpacity(0.7),
                            const Color(0xFF2C5AA0),
                          ],
                        ),
                      ),
                      child: Icon(
                        Icons.hotel,
                        size: 80,
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                  // Dark overlay for text readability
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  // Hotel name overlay
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          registration.hotelName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 3,
                                color: Colors.black45,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          registration.hotelTypeText,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  Positioned(
                    top: 50,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 16, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            registration.statusText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 16),

                // Hotel Info Card
                _buildInfoCard(
                  context,
                  title: 'Thông tin khách sạn',
                  icon: Icons.business,
                  iconColor: const Color(0xFFE65100),
                  children: [
                    _buildInfoRow(Icons.hotel, 'Tên khách sạn', registration.hotelName),
                    _buildInfoRow(Icons.category, 'Loại hình', registration.hotelTypeText),
                    _buildInfoRow(Icons.location_on, 'Địa chỉ', registration.address),
                    _buildInfoRow(Icons.location_city, 'Tỉnh/TP', registration.provinceName ?? 'N/A'),
                    if (registration.district != null && registration.district!.isNotEmpty)
                      _buildInfoRow(Icons.map, 'Quận/Huyện', registration.district!),
                    if (registration.starRating != null)
                      _buildInfoRow(Icons.star, 'Hạng sao', '⭐ ${registration.starRating}'),
                    if (registration.totalRooms != null)
                      _buildInfoRow(Icons.meeting_room, 'Tổng số phòng', '${registration.totalRooms} phòng'),
                    if (registration.description != null && registration.description!.isNotEmpty) ...[
                      const Divider(height: 24),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(Icons.description, size: 18, color: Colors.grey),
                            SizedBox(width: 8),
                            Text(
                              'Mô tả:',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 26),
                        child: Text(
                          registration.description!,
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ),
                    ],
                  ],
                ),

                // Owner Info Card
                _buildInfoCard(
                  context,
                  title: 'Thông tin chủ sở hữu',
                  icon: Icons.person,
                  iconColor: const Color(0xFF1976D2),
                  children: [
                    _buildInfoRow(Icons.person_outline, 'Họ tên', registration.ownerName),
                    _buildInfoRow(Icons.email_outlined, 'Email', registration.ownerEmail),
                    _buildInfoRow(Icons.phone_outlined, 'Số điện thoại', registration.ownerPhone),
                    if (registration.taxId != null)
                      _buildInfoRow(Icons.badge_outlined, 'Mã số thuế', registration.taxId!),
                  ],
                ),

                // Rooms Section (if available)
                if (rooms.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.king_bed, color: Colors.purple, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Danh sách phòng',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${rooms.length} loại',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...rooms.map((room) => _buildRoomCard(room)).toList(),
                ],

                // Additional Info Card
                _buildInfoCard(
                  context,
                  title: 'Thông tin bổ sung',
                  icon: Icons.info_outline,
                  iconColor: Colors.teal,
                  children: [
                    if (registration.checkInTime != null)
                      _buildInfoRow(Icons.login, 'Giờ nhận phòng', registration.checkInTime!),
                    if (registration.checkOutTime != null)
                      _buildInfoRow(Icons.logout, 'Giờ trả phòng', registration.checkOutTime!),
                    if (registration.website != null)
                      _buildInfoRow(Icons.language, 'Website', registration.website!),
                    _buildInfoRow(
                      Icons.calendar_today,
                      'Ngày đăng ký',
                      DateFormat('dd/MM/yyyy HH:mm').format(registration.createdAt),
                    ),
                  ],
                ),

                // Admin Note (if any)
                if (registration.adminNote != null)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.admin_panel_settings, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Ghi chú từ Admin',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          registration.adminNote!,
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ],
                    ),
                  ),

                // Bottom spacing for action buttons
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),

      // Bottom Action Buttons
      bottomNavigationBar: registration.status == 'pending'
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onReject,
                        icon: const Icon(Icons.close, size: 20),
                        label: const Text('Từ chối'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onApprove,
                        icon: const Icon(Icons.check, size: 20),
                        label: const Text('Duyệt'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomCard(Map<String, dynamic> room) {
    final roomName = room['name'] ?? 'Phòng';
    final roomType = _getRoomTypeName(room['room_type']);
    final roomTypeId = room['room_type']?.toString() ?? '1';
    final quantity = room['quantity'] ?? 1;
    final price = room['price']?.toString() ?? '0';
    final area = room['area']?.toString();
    final description = room['description'];

    // Get color for room type
    final roomColor = _getRoomTypeColor(roomTypeId);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Room Image Placeholder với gradient đẹp
          Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  roomColor.withOpacity(0.7),
                  roomColor,
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Icon phòng với shadow
                Center(
                  child: Icon(
                    Icons.king_bed,
                    size: 50,
                    color: Colors.white.withOpacity(0.9),
                    shadows: const [
                      Shadow(
                        offset: Offset(0, 2),
                        blurRadius: 4,
                        color: Colors.black26,
                      ),
                    ],
                  ),
                ),
                // Room type badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      roomType,
                      style: TextStyle(
                        color: roomColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Quantity badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'x$quantity',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Room Info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  roomName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  roomType,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.attach_money, size: 16, color: Colors.green[700]),
                    const SizedBox(width: 4),
                    Text(
                      '${_formatPrice(price)} VNĐ/đêm',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[700],
                      ),
                    ),
                    if (area != null) ...[
                      const Spacer(),
                      Icon(Icons.straighten, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '$area m²',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
                if (description != null && description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getRoomTypeName(dynamic roomType) {
    final typeStr = roomType?.toString() ?? '';
    switch (typeStr) {
      case '1':
        return 'Standard';
      case '2':
        return 'Superior';
      case '3':
        return 'Double';
      case '4':
        return 'Family';
      case '5':
        return 'Suite';
      case '6':
        return 'Deluxe';
      default:
        return 'Standard';
    }
  }

  Color _getRoomTypeColor(String roomType) {
    switch (roomType) {
      case '1': // Standard
        return const Color(0xFF2196F3); // Blue
      case '2': // Superior
        return const Color(0xFF4CAF50); // Green
      case '3': // Double
        return const Color(0xFFFF9800); // Orange
      case '4': // Family
        return const Color(0xFF9C27B0); // Purple
      case '5': // Suite
        return const Color(0xFFE91E63); // Pink
      case '6': // Deluxe
        return const Color(0xFFD4AF37); // Dark Gold
      default:
        return const Color(0xFF2196F3); // Blue
    }
  }

  String _formatPrice(String price) {
    try {
      final num = double.parse(price);
      return num.toStringAsFixed(0).replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},',
          );
    } catch (e) {
      return price;
    }
  }
}

