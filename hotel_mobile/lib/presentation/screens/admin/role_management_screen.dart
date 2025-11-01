import 'package:flutter/material.dart';
import 'package:hotel_mobile/data/models/user_role_model.dart';
import 'package:hotel_mobile/data/services/user_role_service.dart';

class RoleManagementScreen extends StatefulWidget {
  const RoleManagementScreen({super.key});

  @override
  State<RoleManagementScreen> createState() => _RoleManagementScreenState();
}

class _RoleManagementScreenState extends State<RoleManagementScreen> {
  final UserRoleService _userRoleService = UserRoleService();
  List<UserRoleModel> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';
  UserRole? _selectedRoleFilter;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _userRoleService.getAllUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _users = [];
        _isLoading = false;
      });
      _showErrorSnackBar('Không thể kết nối đến server. Vui lòng thử lại sau.');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _updateUserRole(UserRoleModel user, UserRole newRole) async {
    try {
      final success = await _userRoleService.updateUserRole(
        uid: user.uid,
        newRole: newRole,
      );

      if (success) {
        _showSuccessSnackBar('Cập nhật quyền thành công');
        _loadUsers(); // Reload users
      } else {
        _showErrorSnackBar('Cập nhật quyền thất bại');
      }
    } catch (e) {
      _showErrorSnackBar('Lỗi: $e');
    }
  }

  Future<void> _showRoleUpdateDialog(UserRoleModel user) async {
    final newRole = await showDialog<UserRole>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cập nhật quyền cho ${user.displayName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: UserRole.values.map((role) {
            return RadioListTile<UserRole>(
              title: Text(role.displayName),
              subtitle: Text(_getRoleDescription(role)),
              value: role,
              groupValue: user.role,
              onChanged: (value) {
                Navigator.pop(context, value);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );

    if (newRole != null && newRole != user.role) {
      _updateUserRole(user, newRole);
    }
  }

  String _getRoleDescription(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Toàn quyền quản trị hệ thống';
      case UserRole.hotelManager:
        return 'Quản lý khách sạn và đặt phòng';
      case UserRole.user:
        return 'Người dùng thông thường';
    }
  }

  List<UserRoleModel> get _filteredUsers {
    var filtered = _users.where((user) {
      final matchesSearch = user.displayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.email.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesRole = _selectedRoleFilter == null || user.role == _selectedRoleFilter;
      
      return matchesSearch && matchesRole;
    }).toList();

    // Sort by role priority (admin first, then hotel manager, then user)
    filtered.sort((a, b) {
      final roleOrder = {UserRole.admin: 0, UserRole.hotelManager: 1, UserRole.user: 2};
      return roleOrder[a.role]!.compareTo(roleOrder[b.role]!);
    });

    return filtered;
  }

  Widget _buildRoleChip(UserRole role) {
    Color color;
    IconData icon;
    
    switch (role) {
      case UserRole.admin:
        color = Colors.red;
        icon = Icons.admin_panel_settings;
        break;
      case UserRole.hotelManager:
        color = Colors.orange;
        icon = Icons.hotel;
        break;
      case UserRole.user:
        color = Colors.blue;
        icon = Icons.person;
        break;
    }

    return Chip(
      label: Text(
        role.displayName,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
      avatar: Icon(icon, color: Colors.white, size: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý quyền người dùng'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              children: [
                // Search bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm theo tên hoặc email...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
                const SizedBox(height: 12),
                
                // Role filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('Tất cả'),
                        selected: _selectedRoleFilter == null,
                        onSelected: (selected) {
                          setState(() => _selectedRoleFilter = null);
                        },
                      ),
                      const SizedBox(width: 8),
                      ...UserRole.values.map((role) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(role.displayName),
                            selected: _selectedRoleFilter == role,
                            onSelected: (selected) {
                              setState(() {
                                _selectedRoleFilter = selected ? role : null;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Users list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? const Center(
                        child: Text(
                          'Không tìm thấy người dùng nào',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage: user.photoURL != null
                                    ? NetworkImage(user.photoURL!)
                                    : null,
                                child: user.photoURL == null
                                    ? Icon(Icons.person)
                                    : null,
                              ),
                              title: Text(
                                user.displayName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(user.email),
                                  const SizedBox(height: 4),
                                  _buildRoleChip(user.role),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _showRoleUpdateDialog(user),
                                    tooltip: 'Cập nhật quyền',
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      user.isActive ? Icons.check_circle : Icons.cancel,
                                      color: user.isActive ? Colors.green : Colors.red,
                                    ),
                                    onPressed: () {
                                      // TODO: Implement activate/deactivate
                                    },
                                    tooltip: user.isActive ? 'Vô hiệu hóa' : 'Kích hoạt',
                                  ),
                                ],
                              ),
                              onTap: () => _showRoleUpdateDialog(user),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
