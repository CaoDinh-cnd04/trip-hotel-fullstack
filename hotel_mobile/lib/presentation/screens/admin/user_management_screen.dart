import 'package:flutter/material.dart';
import 'dart:async';
import '../../../data/models/user_model.dart';
import '../../../data/services/admin_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final AdminService _adminService = AdminService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<UserModel> _users = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  String _selectedRole = 'all';
  String _selectedStatus = 'all';
  
  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = true;
  
  // Debounce search
  Timer? _debounce;

  final List<Map<String, String>> _roleOptions = [
    {'value': 'all', 'label': 'Tất cả'},
    {'value': 'admin', 'label': 'Quản trị viên'},
    {'value': 'hotelmanager', 'label': 'Quản lý khách sạn'},
    {'value': 'user', 'label': 'Người dùng'},
  ];

  final List<Map<String, String>> _statusOptions = [
    {'value': 'all', 'label': 'Tất cả'},
    {'value': 'active', 'label': 'Hoạt động'},
    {'value': 'inactive', 'label': 'Không hoạt động'},
    {'value': 'blocked', 'label': 'Bị khóa'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }
  
  /// Debounced search - chỉ search sau 500ms user ngừng gõ
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _resetAndLoad();
    });
  }
  
  /// Infinite scroll - load more khi scroll gần cuối
  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore) {
        _loadMoreUsers();
      }
    }
  }
  
  /// Reset về page 1 và load lại (dùng khi search/filter)
  Future<void> _resetAndLoad() async {
    setState(() {
      _currentPage = 1;
      _users = [];
      _hasMore = true;
    });
    await _loadUsers();
  }

  /// Load users với pagination và server-side filtering
  Future<void> _loadUsers() async {
    if (_currentPage > 1) return; // Chỉ load page 1
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      _adminService.initialize();
      
      final response = await _adminService.getUsersPaginated(
        page: _currentPage,
        limit: 20,
        chucVu: _selectedRole == 'all' ? null : _selectedRole,
        search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      );
      
      if (mounted) {
        setState(() {
          _users = response['users'] as List<UserModel>;
          _totalPages = response['totalPages'] as int;
          _hasMore = _currentPage < _totalPages;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading users: $e');
      
      if (mounted) {
        setState(() {
          _users = [];
          _error = 'Không thể tải danh sách người dùng.\n${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }
  
  /// Load more users (infinite scroll)
  Future<void> _loadMoreUsers() async {
    if (_isLoadingMore || !_hasMore) return;
    
    setState(() {
      _isLoadingMore = true;
    });
    
    try {
      final nextPage = _currentPage + 1;
      
      final response = await _adminService.getUsersPaginated(
        page: nextPage,
        limit: 20,
        chucVu: _selectedRole == 'all' ? null : _selectedRole,
        search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      );
      
      if (mounted) {
        setState(() {
          _users.addAll(response['users'] as List<UserModel>);
          _currentPage = nextPage;
          _totalPages = response['totalPages'] as int;
          _hasMore = _currentPage < _totalPages;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      print('❌ Error loading more users: $e');
      
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  // Filtering được xử lý ở server-side trong _loadUsers()
  // Không cần client-side filtering nữa

  Future<void> _updateUserStatus(String userId, int newStatus) async {
    try {
      await _adminService.updateUserStatus(userId, newStatus);
      await _resetAndLoad(); // Reload data
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật trạng thái thành công'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
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
          'Quản lý Người dùng',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.purple[700],
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _showAddUserDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? _buildErrorWidget()
                : _buildUsersTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm theo tên, email, tên đăng nhập...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.purple[700]!),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Filters
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: InputDecoration(
                    labelText: 'Chức vụ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: _roleOptions.map((option) {
                    return DropdownMenuItem<String>(
                      value: option['value'],
                      child: Text(option['label']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value!;
                    });
                    _resetAndLoad();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: InputDecoration(
                    labelText: 'Trạng thái',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: _statusOptions.map((option) {
                    return DropdownMenuItem<String>(
                      value: option['value'],
                      child: Text(option['label']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value!;
                    });
                    _resetAndLoad();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Có lỗi xảy ra',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Không thể tải dữ liệu',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadUsers, child: const Text('Thử lại')),
        ],
      ),
    );
  }

  Widget _buildUsersTable() {
    if (_users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline,
                size: 64,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Không có người dùng nào',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Danh sách người dùng trống\nhoặc không khớp với bộ lọc',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _resetAndLoad,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _users.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Loading indicator at bottom
          if (index == _users.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          final user = _users[index];
          return _buildUserCard(user);
        },
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Name and Status
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: _getRoleColor(user.chucVu),
                  child: Text(
                    user.hoTen.isNotEmpty ? user.hoTen[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.hoTen,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildRoleBadge(user.chucVu),
                          const SizedBox(width: 8),
                          _buildStatusBadge(user.trangThai),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            // User Details
            _buildInfoRow(Icons.email, user.email),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.phone, user.soDienThoai),
            const SizedBox(height: 16),
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showChangeRoleDialog(user),
                    icon: const Icon(Icons.admin_panel_settings, size: 18),
                    label: const Text('Đổi quyền'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.purple[700],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showEditUserDialog(user),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Sửa'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue[700],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _showDeleteUserDialog(user),
                  icon: const Icon(Icons.delete),
                  color: Colors.red[700],
                  tooltip: 'Xóa',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleBadge(String role) {
    String displayRole;
    Color color;
    
    switch (role.toLowerCase()) {
      case 'admin':
        displayRole = 'Admin';
        color = Colors.red;
        break;
      case 'hotelmanager':
        displayRole = 'Quản lý KS';
        color = Colors.orange;
        break;
      default:
        displayRole = 'Người dùng';
        color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        displayRole,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final isActive = status.toLowerCase() == 'active' || status == '1';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? Colors.green.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Text(
        isActive ? 'Hoạt động' : 'Không hoạt động',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isActive ? Colors.green : Colors.grey,
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red[700]!;
      case 'hotelmanager':
        return Colors.orange[700]!;
      default:
        return Colors.blue[700]!;
    }
  }

  // Dialog for changing user role
  void _showChangeRoleDialog(UserModel user) {
    String selectedRole = user.chucVu;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Đổi quyền người dùng'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Người dùng: ${user.hoTen}'),
              const SizedBox(height: 16),
              const Text(
                'Chọn quyền mới:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              RadioListTile<String>(
                title: const Text('Admin'),
                value: 'Admin',
                groupValue: selectedRole,
                onChanged: (value) => setState(() => selectedRole = value!),
              ),
              RadioListTile<String>(
                title: const Text('Quản lý khách sạn'),
                value: 'HotelManager',
                groupValue: selectedRole,
                onChanged: (value) => setState(() => selectedRole = value!),
              ),
              RadioListTile<String>(
                title: const Text('Người dùng'),
                value: 'User',
                groupValue: selectedRole,
                onChanged: (value) => setState(() => selectedRole = value!),
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
                _updateUserRole(user.id, selectedRole);
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateUserRole(String userId, String newRole) async {
    try {
      await _adminService.updateUser(userId, {'chuc_vu': newRole});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật quyền thành công'),
            backgroundColor: Colors.green,
          ),
        );
        await _resetAndLoad();
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

  // Dialog for editing user
  void _showEditUserDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => _UserDialog(
        user: user,
        onSave: (userData) async {
          await _updateUser(user.id, userData);
        },
      ),
    );
  }

  // Dialog for deleting user
  void _showDeleteUserDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa người dùng'),
        content: Text('Bạn có chắc chắn muốn xóa người dùng "${user.hoTen}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteUser(user.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser(String userId) async {
    try {
      await _adminService.deleteUser(userId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Xóa người dùng thành công'),
            backgroundColor: Colors.green,
          ),
        );
        await _resetAndLoad();
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

  // Show dialog to add new user
  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (context) => _UserDialog(
        onSave: (userData) async {
          await _createUser(userData);
        },
      ),
    );
  }

  // Create new user
  Future<void> _createUser(Map<String, dynamic> userData) async {
    try {
      await _adminService.createUser(userData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thêm người dùng thành công'),
            backgroundColor: Colors.green,
          ),
        );
        await _resetAndLoad();
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

  // Update existing user
  Future<void> _updateUser(String userId, Map<String, dynamic> userData) async {
    try {
      await _adminService.updateUser(userId, userData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật người dùng thành công'),
            backgroundColor: Colors.green,
          ),
        );
        await _resetAndLoad();
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
}

// Dialog widget for adding/editing users
class _UserDialog extends StatefulWidget {
  final UserModel? user;
  final Function(Map<String, dynamic>) onSave;

  const _UserDialog({this.user, required this.onSave});

  @override
  State<_UserDialog> createState() => _UserDialogState();
}

class _UserDialogState extends State<_UserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _hoTenController = TextEditingController();
  final _emailController = TextEditingController();
  final _tenDangNhapController = TextEditingController();
  final _soDienThoaiController = TextEditingController();
  final _diaChiController = TextEditingController();
  final _ghiChuController = TextEditingController();
  String _selectedRole = 'user';
  String _selectedStatus = 'active';

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _hoTenController.text = widget.user!.hoTen;
      _emailController.text = widget.user!.email;
      _tenDangNhapController.text = widget.user!.tenDangNhap;
      _soDienThoaiController.text = widget.user!.soDienThoai;
      _diaChiController.text = widget.user!.diaChi ?? '';
      _ghiChuController.text = widget.user!.ghiChu ?? '';
      
      // Normalize role to lowercase to match dropdown items
      _selectedRole = widget.user!.chucVu.toLowerCase();
      
      // Normalize status to lowercase
      _selectedStatus = widget.user!.trangThai.toLowerCase();
    }
  }

  @override
  void dispose() {
    _hoTenController.dispose();
    _emailController.dispose();
    _tenDangNhapController.dispose();
    _soDienThoaiController.dispose();
    _diaChiController.dispose();
    _ghiChuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.user == null ? 'Thêm người dùng mới' : 'Chỉnh sửa người dùng',
        style: const TextStyle(fontSize: 18),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              TextFormField(
                controller: _hoTenController,
                decoration: const InputDecoration(
                  labelText: 'Họ và tên',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập họ tên';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập email';
                  }
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(value)) {
                    return 'Email không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tenDangNhapController,
                decoration: const InputDecoration(
                  labelText: 'Tên đăng nhập',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập tên đăng nhập';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _soDienThoaiController,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập số điện thoại';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Chức vụ dropdown
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Chức vụ',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                isExpanded: true,
                items: const [
                  DropdownMenuItem(
                    value: 'admin',
                    child: Text('Admin', overflow: TextOverflow.ellipsis),
                  ),
                  DropdownMenuItem(
                    value: 'hotelmanager',
                    child: Text('Quản lý KS', overflow: TextOverflow.ellipsis),
                  ),
                  DropdownMenuItem(
                    value: 'user',
                    child: Text('Người dùng', overflow: TextOverflow.ellipsis),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              // Trạng thái dropdown
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Trạng thái',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                isExpanded: true,
                items: const [
                  DropdownMenuItem(
                    value: 'active',
                    child: Text('Hoạt động', overflow: TextOverflow.ellipsis),
                  ),
                  DropdownMenuItem(
                    value: 'inactive',
                    child: Text('Không hoạt động', overflow: TextOverflow.ellipsis),
                  ),
                  DropdownMenuItem(
                    value: 'blocked',
                    child: Text('Bị khóa', overflow: TextOverflow.ellipsis),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _diaChiController,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ghiChuController,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _saveUser,
          child: Text(widget.user == null ? 'Thêm' : 'Cập nhật'),
        ),
      ],
    );
  }

  void _saveUser() {
    if (_formKey.currentState!.validate()) {
      // Normalize role to PascalCase for backend
      String normalizedRole = _selectedRole;
      if (_selectedRole == 'hotelmanager') {
        normalizedRole = 'HotelManager';
      } else if (_selectedRole == 'admin') {
        normalizedRole = 'Admin';
      } else if (_selectedRole == 'user') {
        normalizedRole = 'User';
      }
      
      final userData = {
        'ho_ten': _hoTenController.text,
        'email': _emailController.text,
        'ten_dang_nhap': _tenDangNhapController.text,
        'so_dien_thoai': _soDienThoaiController.text,
        'chuc_vu': normalizedRole,
        'trang_thai': _selectedStatus,
        'dia_chi': _diaChiController.text,
        'ghi_chu': _ghiChuController.text,
      };

      widget.onSave(userData);
      Navigator.pop(context);
    }
  }
}
