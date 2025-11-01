import 'package:flutter/material.dart';
import '../../../data/services/backend_auth_service.dart';
import '../../../data/services/hotel_manager_service.dart';
import '../../../data/models/user_role_model.dart';
import '../../../data/models/hotel_manager_models.dart';
import 'package:dio/dio.dart';
import 'rooms_management_screen.dart';
import 'bookings_management_screen.dart';
import 'reviews_management_screen.dart';
import 'profile_management_screen.dart';
import '../chat/modern_conversation_list_screen.dart';

class HotelManagerMainScreen extends StatefulWidget {
  const HotelManagerMainScreen({super.key});

  @override
  State<HotelManagerMainScreen> createState() => _HotelManagerMainScreenState();
}

class _HotelManagerMainScreenState extends State<HotelManagerMainScreen> {
  final BackendAuthService _backendAuthService = BackendAuthService();
  final HotelManagerService _hotelManagerService = HotelManagerService(Dio());
  int _currentIndex = 0;

  late final List<Widget> _screens;

  final List<BottomNavigationBarItem> _bottomNavItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.dashboard_outlined),
      activeIcon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.bed_outlined),
      activeIcon: Icon(Icons.bed),
      label: 'Phòng',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.book_online_outlined),
      activeIcon: Icon(Icons.book_online),
      label: 'Đặt phòng',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.star_outline),
      activeIcon: Icon(Icons.star),
      label: 'Đánh giá',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.person_outline),
      activeIcon: Icon(Icons.person),
      label: 'Hồ sơ',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.chat_outlined),
      activeIcon: Icon(Icons.chat),
      label: 'Tin nhắn',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeScreens();
    _setAuthToken();
  }

  void _setAuthToken() {
    final token = _backendAuthService.getToken();
    if (token != null) {
      _hotelManagerService.setAuthToken(token);
    }
  }

  void _initializeScreens() {
    _screens = [
      HotelManagerDashboard(hotelManagerService: _hotelManagerService),
      HotelManagerRooms(hotelManagerService: _hotelManagerService),
      HotelManagerBookings(hotelManagerService: _hotelManagerService),
      HotelManagerReviews(hotelManagerService: _hotelManagerService),
      HotelManagerProfile(hotelManagerService: _hotelManagerService),
      const ModernConversationListScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    try {
      final user = _backendAuthService.currentUser;
      final userRole = _backendAuthService.currentUserRole;

      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Hotel Manager',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (user != null)
                Text(
                  user.hoTen ?? 'Manager',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
            ],
          ),
          backgroundColor: Colors.blue[700],
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Colors.white),
              onPressed: () {
                // TODO: Navigate to notifications
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () {
                _showLogoutDialog();
              },
            ),
          ],
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.blue[700],
          unselectedItemColor: Colors.grey[600],
          backgroundColor: Colors.white,
          elevation: 8,
          items: _bottomNavItems,
        ),
      );
    } catch (e, stackTrace) {
      print('❌ Error building HotelManagerMainScreen: $e');
      print('Stack trace: $stackTrace');
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Hotel Manager'),
          backgroundColor: Colors.blue[700],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Lỗi hiển thị giao diện',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  e.toString(),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {});
                },
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Đăng xuất'),
          content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _backendAuthService.signOut();
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/',
                    (route) => false,
                  );
                }
              },
              child: const Text('Đăng xuất'),
            ),
          ],
        );
      },
    );
  }
}

// Hotel Manager Dashboard
class HotelManagerDashboard extends StatefulWidget {
  final HotelManagerService hotelManagerService;
  
  const HotelManagerDashboard({
    super.key,
    required this.hotelManagerService,
  });

  @override
  State<HotelManagerDashboard> createState() => _HotelManagerDashboardState();
}

class _HotelManagerDashboardState extends State<HotelManagerDashboard> {
  DashboardKpi? _kpiData;
  HotelInfo? _hotelInfo;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load hotel info and dashboard KPI
      final hotelInfoData = await widget.hotelManagerService.getAssignedHotel();
      final kpiData = await widget.hotelManagerService.getDashboardKpi();

      setState(() {
        _hotelInfo = HotelInfo.fromJson(hotelInfoData);
        _kpiData = DashboardKpi.fromJson(kpiData);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      if (_isLoading) {
        return Container(
          color: Colors.grey[50],
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      if (_error != null) {
        return Container(
          color: Colors.grey[50],
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Lỗi tải dữ liệu',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadDashboardData,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          ),
        );
      }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hotel Info Card
              if (_hotelInfo != null) ...[
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hotel image
                        if (_hotelInfo!.hinhAnh != null && _hotelInfo!.hinhAnh!.isNotEmpty) ...[
                          Container(
                            height: 200,
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey[200],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                _hotelInfo!.hinhAnh!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.hotel, size: 64, color: Colors.grey),
                                ),
                              ),
                            ),
                          ),
                        ],
                        
                        Row(
                          children: [
                            Icon(
                              Icons.hotel,
                              color: Colors.blue[700],
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _hotelInfo!.tenKhachSan,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_hotelInfo!.tenViTri}, ${_hotelInfo!.tenTinhThanh}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildStarRating(_hotelInfo!.soSao),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _isHotelActive(_hotelInfo!.trangThai) 
                                    ? Colors.green 
                                    : Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _isHotelActive(_hotelInfo!.trangThai) 
                                    ? 'Hoạt động' 
                                    : 'Tạm dừng',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              
              // KPI Cards
              Text(
                'Thống kê tổng quan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              
              const SizedBox(height: 16),
              
              if (_kpiData != null)
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
              
                  childAspectRatio: 1.2,
                  children: [
                    _buildKpiCard(
                      'Tổng phòng',
                      '${_kpiData!.totalRooms}',
                      Icons.bed,
                      Colors.blue,
                    ),
                    _buildKpiCard(
                      'Phòng trống',
                      '${_kpiData!.availableRooms}',
                      Icons.bed_outlined,
                      Colors.green,
                    ),
                    _buildKpiCard(
                      'Đặt phòng',
                      '${_kpiData!.totalBookings}',
                      Icons.book_online,
                      Colors.orange,
                    ),
                    _buildKpiCard(
                      'Doanh thu',
                      '${_formatCurrency(_kpiData!.totalRevenue)}',
                      Icons.attach_money,
                      Colors.purple,
                    ),
                  ],
                ),
              
              const SizedBox(height: 20),
              
              // Quick Actions
              Text(
                'Thao tác nhanh',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      'Thêm phòng',
                      Icons.add_box,
                      Colors.blue,
                      () {
                        // TODO: Navigate to add room
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildQuickActionCard(
                      'Xem đặt phòng',
                      Icons.list_alt,
                      Colors.green,
                      () {
                        // TODO: Navigate to bookings
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    } catch (e, stackTrace) {
      print('❌ Error building HotelManagerDashboard: $e');
      print('Stack trace: $stackTrace');
      return Container(
        color: Colors.grey[50],
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Lỗi hiển thị dashboard',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadDashboardData,
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildStarRating(int stars) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < stars ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 16,
        );
      }),
    );
  }

  /// Check if hotel is active (support multiple status formats)
  bool _isHotelActive(String? status) {
    if (status == null) return false;
    final statusLower = status.toLowerCase().trim();
    return statusLower == 'active' || 
           statusLower == 'hoạt động' || 
           statusLower == 'hoat dong';
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return amount.toStringAsFixed(0);
    }
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 32,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HotelManagerRooms extends StatelessWidget {
  final HotelManagerService hotelManagerService;
  
  const HotelManagerRooms({
    super.key,
    required this.hotelManagerService,
  });

  @override
  Widget build(BuildContext context) {
    return RoomsManagementScreen(
      hotelManagerService: hotelManagerService,
    );
  }
}

class HotelManagerBookings extends StatelessWidget {
  final HotelManagerService hotelManagerService;
  
  const HotelManagerBookings({
    super.key,
    required this.hotelManagerService,
  });

  @override
  Widget build(BuildContext context) {
    return BookingsManagementScreen(
      hotelManagerService: hotelManagerService,
    );
  }
}

class HotelManagerReviews extends StatelessWidget {
  final HotelManagerService hotelManagerService;
  
  const HotelManagerReviews({
    super.key,
    required this.hotelManagerService,
  });

  @override
  Widget build(BuildContext context) {
    return ReviewsManagementScreen(
      hotelManagerService: hotelManagerService,
    );
  }
}

class HotelManagerProfile extends StatelessWidget {
  final HotelManagerService hotelManagerService;
  
  const HotelManagerProfile({
    super.key,
    required this.hotelManagerService,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileManagementScreen(
      hotelManagerService: hotelManagerService,
    );
  }
}
