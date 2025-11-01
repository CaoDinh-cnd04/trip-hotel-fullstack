import 'package:flutter/material.dart';
import '../../../data/services/hotel_registration_service.dart';

class ApplicationReviewScreen extends StatefulWidget {
  const ApplicationReviewScreen({super.key});

  @override
  State<ApplicationReviewScreen> createState() => _ApplicationReviewScreenState();
}

class _ApplicationReviewScreenState extends State<ApplicationReviewScreen>
    with SingleTickerProviderStateMixin {
  final HotelRegistrationService _registrationService = HotelRegistrationService();
  late TabController _tabController;
  
  List<HotelRegistration> _pendingApplications = [];
  List<HotelRegistration> _approvedApplications = [];
  List<HotelRegistration> _rejectedApplications = [];
  
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadApplications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadApplications() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // ✅ FIX: Use HotelRegistrationService with proper token
      final allRegistrations = await _registrationService.getAllRegistrations('dummy'); // Token handled internally

      setState(() {
        _pendingApplications = allRegistrations.where((r) => r.status == 'pending').toList();
        _approvedApplications = allRegistrations.where((r) => r.status == 'approved').toList();
        _rejectedApplications = allRegistrations.where((r) => r.status == 'rejected').toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading applications: $e');
      setState(() {
        _pendingApplications = [];
        _approvedApplications = [];
        _rejectedApplications = [];
        _error = 'Không thể tải dữ liệu. Vui lòng kiểm tra kết nối mạng.';
        _isLoading = false;
      });
    }
  }

  Future<void> _approveApplication(String applicationId, {String? ghiChu}) async {
    try {
      await _adminService.approveApplication(applicationId, ghiChu: ghiChu);
      _loadApplications(); // Reload data
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Duyệt hồ sơ thành công'),
            backgroundColor: Colors.green,
          ),
        );
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
    }
  }

  Future<void> _rejectApplication(String applicationId, String lyDoTuChoi) async {
    try {
      await _adminService.rejectApplication(applicationId, lyDoTuChoi);
      _loadApplications(); // Reload data
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Từ chối hồ sơ thành công'),
            backgroundColor: Colors.orange,
          ),
        );
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Duyệt Hồ sơ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.purple[700],
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              text: 'Chờ duyệt (${_pendingApplications.length})',
              icon: const Icon(Icons.pending_actions),
            ),
            Tab(
              text: 'Đã duyệt (${_approvedApplications.length})',
              icon: const Icon(Icons.check_circle),
            ),
            Tab(
              text: 'Từ chối (${_rejectedApplications.length})',
              icon: const Icon(Icons.cancel),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadApplications,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildApplicationsList(_pendingApplications, 'pending'),
                    _buildApplicationsList(_approvedApplications, 'approved'),
                    _buildApplicationsList(_rejectedApplications, 'rejected'),
                  ],
                ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.cloud_off,
              size: 64,
              color: Colors.red[300],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Không thể tải dữ liệu',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              _error ?? 'Vui lòng kiểm tra kết nối mạng và thử lại',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _loadApplications,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationsList(List<ApplicationModel> applications, String status) {
    if (applications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _getStatusColor(status).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getStatusIcon(status),
                size: 64,
                color: _getStatusColor(status).withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _getEmptyMessage(status),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                _getEmptyDescription(status),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: _loadApplications,
              icon: const Icon(Icons.refresh),
              label: const Text('Làm mới'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadApplications,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: applications.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final application = applications[index];
          return ApplicationCard(
            application: application,
            onTap: () => _showApplicationDetail(application),
            onApprove: status == 'pending' 
                ? () => _showApprovalDialog(application)
                : null,
            onReject: status == 'pending' 
                ? () => _showRejectionDialog(application)
                : null,
          );
        },
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending_actions;
      case 'approved':
        return Icons.check_circle_outline;
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.description;
    }
  }

  String _getEmptyMessage(String status) {
    switch (status) {
      case 'pending':
        return 'Chưa có hồ sơ chờ duyệt';
      case 'approved':
        return 'Chưa có hồ sơ đã duyệt';
      case 'rejected':
        return 'Chưa có hồ sơ bị từ chối';
      default:
        return 'Chưa có dữ liệu';
    }
  }

  String _getEmptyDescription(String status) {
    switch (status) {
      case 'pending':
        return 'Khi có đơn đăng ký khách sạn mới,\nchúng sẽ hiển thị ở đây để bạn xét duyệt';
      case 'approved':
        return 'Các đơn đăng ký đã được phê duyệt\nsẽ hiển thị tại đây';
      case 'rejected':
        return 'Các đơn đăng ký bị từ chối\nsẽ hiển thị tại đây';
      default:
        return 'Chưa có dữ liệu để hiển thị';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showApplicationDetail(ApplicationModel application) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Title
              Text(
                'Chi tiết hồ sơ',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 20),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Tên khách sạn', application.tenKhachSan),
                      _buildDetailRow('Người đăng ký', application.tenNguoiDangKy),
                      _buildDetailRow('Số điện thoại', application.soDienThoai),
                      _buildDetailRow('Email', application.email),
                      _buildDetailRow('Địa chỉ', application.diaChi),
                      _buildDetailRow('Mô tả', application.moTa),
                      _buildDetailRow('Trạng thái', application.statusDisplayName),
                      _buildDetailRow('Ngày đăng ký', application.formattedNgayDangKy),
                      if (application.ngayDuyet != null)
                        _buildDetailRow('Ngày duyệt', application.formattedNgayDuyet),
                      if (application.nguoiDuyet != null)
                        _buildDetailRow('Người duyệt', application.nguoiDuyet!),
                      if (application.lyDoTuChoi != null)
                        _buildDetailRow('Lý do từ chối', application.lyDoTuChoi!),
                      if (application.hinhAnh.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Hình ảnh',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: application.hinhAnh.length,
                          itemBuilder: (context, index) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                application.hinhAnh[index],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.image_not_supported),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Actions for pending applications
              if (application.isPending) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showRejectionDialog(application);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        child: const Text('Từ chối'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showApprovalDialog(application);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: const Text('Duyệt', style: TextStyle(color: Colors.white)),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _showApprovalDialog(ApplicationModel application) {
    final ghiChuController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Duyệt hồ sơ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Bạn có chắc chắn muốn duyệt hồ sơ "${application.tenKhachSan}"?'),
            const SizedBox(height: 16),
            TextField(
              controller: ghiChuController,
              decoration: const InputDecoration(
                labelText: 'Ghi chú (tùy chọn)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
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
              Navigator.pop(context);
              _approveApplication(application.id, ghiChu: ghiChuController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Duyệt', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showRejectionDialog(ApplicationModel application) {
    final lyDoController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Từ chối hồ sơ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Bạn có chắc chắn muốn từ chối hồ sơ "${application.tenKhachSan}"?'),
            const SizedBox(height: 16),
            TextField(
              controller: lyDoController,
              decoration: const InputDecoration(
                labelText: 'Lý do từ chối *',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
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
              if (lyDoController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập lý do từ chối')),
                );
                return;
              }
              Navigator.pop(context);
              _rejectApplication(application.id, lyDoController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Từ chối', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class ApplicationCard extends StatelessWidget {
  final ApplicationModel application;
  final VoidCallback? onTap;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const ApplicationCard({
    super.key,
    required this.application,
    this.onTap,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      application.tenKhachSan,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(application.trangThai).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      application.statusDisplayName,
                      style: TextStyle(
                        color: _getStatusColor(application.trangThai),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Applicant info
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      application.tenNguoiDangKy,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(application.soDienThoai),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.email, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      application.email,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Description
              Text(
                application.shortMoTa,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // Date and actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Đăng ký: ${application.formattedNgayDangKy}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  if (application.isPending) ...[
                    Row(
                      children: [
                        IconButton(
                          onPressed: onReject,
                          icon: const Icon(Icons.close, color: Colors.red, size: 20),
                          tooltip: 'Từ chối',
                        ),
                        IconButton(
                          onPressed: onApprove,
                          icon: const Icon(Icons.check, color: Colors.green, size: 20),
                          tooltip: 'Duyệt',
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
