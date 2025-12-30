import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/logout_button.dart';
import 'category_management_screen.dart';
import 'all_events_view_screen.dart';
import 'user_management_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _usernameController = TextEditingController();
  bool _isUpdatingRole = false;
  String _selectedRole = 'Staff';
  bool _isRefreshing = false;
  String? _currentUsername;

  @override
  void initState() {
    super.initState();
    _loadCurrentUsername();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hệ thống Quản trị (Admin)"),
        backgroundColor: Colors.redAccent,
        actions: [
          IconButton(
            onPressed: _isRefreshing ? null : _loadAllSystemData,
            icon: const Icon(Icons.refresh),
          ),
          const LogoutButton(),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DashboardCard(
            title: 'Quản lý Category',
            description: 'Tùy chỉnh tất cả danh mục sự kiện',
            icon: Icons.category,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CategoryManagementScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _DashboardCard(
            title: 'Quản lý lịch trình hệ thống',
            description: 'Toàn quyền giám sát và ẩn sự kiện',
            icon: Icons.event_available,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AllEventsViewScreen(isAdmin: true),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _DashboardCard(
            title: 'Danh sách người dùng',
            description: 'Xem và cập nhật User/Staff',
            icon: Icons.people,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const UserManagementScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Phân quyền người dùng',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Nhập username',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Chọn vai trò đích',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Staff', child: Text('Staff')),
                      DropdownMenuItem(value: 'User', child: Text('User')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedRole = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isUpdatingRole ? null : _handleRoleUpdate,
                      icon: _isUpdatingRole
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.swap_horiz),
                      label: const Text('Cập nhật vai trò'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRoleUpdate() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng nhập username.')));
      return;
    }

    final current = _currentUsername;
    if (current != null && current.toLowerCase() == username.toLowerCase()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể tự thay đổi vai trò của bạn.')),
      );
      return;
    }

    setState(() => _isUpdatingRole = true);
    try {
      await _api.updateUserRole(username, _selectedRole);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(content: Text('Đã chuyển $username sang vai trò $_selectedRole.')),
      );
      _usernameController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _isUpdatingRole = false);
    }
  }

  Future<void> _loadAllSystemData() async {
    setState(() => _isRefreshing = true);
    try {
      final data = await _api.getAllEventsForStaff();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã đồng bộ ${data.length} sự kiện.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
      );
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Future<void> _loadCurrentUsername() async {
    final username = await _api.getUserName();
    if (!mounted) return;
    setState(() => _currentUsername = username);
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.redAccent.withOpacity(0.1),
                child: Icon(icon, size: 28, color: Colors.redAccent),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
