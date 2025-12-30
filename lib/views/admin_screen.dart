import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/logout_button.dart';
import 'all_events_view_screen.dart';
import 'category_management_screen.dart';
import 'user_management_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _usernameController = TextEditingController();
  String _selectedRole = 'Staff';
  bool _isUpdatingRole = false;
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
    final cards = [
      _AdminCardData(
        title: 'Quản lý Hệ thống',
        subtitle: 'Danh mục & cấu hình sự kiện',
        icon: Icons.auto_mode,
        colors: const [Color(0xFF7B1FA2), Color(0xFFAB47BC)],
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CategoryManagementScreen()),
          );
        },
      ),
      _AdminCardData(
        title: 'Điều hành Dữ liệu',
        subtitle: 'Giám sát & ẩn lịch hệ thống',
        icon: Icons.event_available,
        colors: const [Color(0xFF512DA8), Color(0xFF9575CD)],
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AllEventsViewScreen(isAdmin: true),
            ),
          );
        },
      ),
      _AdminCardData(
        title: 'An ninh',
        subtitle: 'Quản trị người dùng & vai trò',
        icon: Icons.verified_user,
        colors: const [Color(0xFF4527A0), Color(0xFF7E57C2)],
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const UserManagementScreen(),
            ),
          );
        },
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        title: const Text('Bảng điều khiển Admin'),
        actions: [
          IconButton(
            onPressed: _isRefreshing ? null : _loadAllSystemData,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const LogoutButton(),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF3E5F5), Color(0xFFEDE7F6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Điều hướng nhanh',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: Colors.deepPurple.shade900),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 1.05,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children:
                      cards.map((data) => _GradientDashboardCard(data: data)).toList(),
                ),
                const SizedBox(height: 24),
                Text(
                  'An ninh hệ thống',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: Colors.deepPurple.shade900),
                ),
                const SizedBox(height: 12),
                _buildSecurityPanel(context),
              ],
            ),
          ),
        ),
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
  Widget _buildSecurityPanel(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF5E35B1), Color(0xFF9575CD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            offset: Offset(0, 8),
            blurRadius: 24,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cập nhật vai trò trực tiếp',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _usernameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Nhập username',
              labelStyle: const TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedRole,
            dropdownColor: Colors.deepPurple,
            iconEnabledColor: Colors.white,
            decoration: InputDecoration(
              labelText: 'Vai trò đích',
              labelStyle: const TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.deepPurple,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _isUpdatingRole ? null : _handleRoleUpdate,
              icon: _isUpdatingRole
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.security_update_good),
              label: const Text('Cập nhật vai trò'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminCardData {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  const _AdminCardData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    required this.onTap,
  });
}

class _GradientDashboardCard extends StatelessWidget {
  final _AdminCardData data;

  const _GradientDashboardCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: data.onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: data.colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              offset: Offset(0, 12),
              blurRadius: 24,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: Icon(data.icon, color: Colors.white, size: 24),
            ),
            const Spacer(),
            Text(
              data.title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              data.subtitle,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
