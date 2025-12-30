import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../services/api_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final ApiService _api = ApiService();
  final Map<String, String> _roleSelections = {};
  final Set<String> _updatingUsers = {};
  List<AppUser> _users = [];
  bool _isLoading = false;
  String? _currentUsername;

  static const List<String> _editableRoles = ['User', 'Staff'];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final username = await _api.getUserName();
    if (!mounted) return;
    setState(() => _currentUsername = username);
    await _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _api.getUsersWithRoles();
      if (!mounted) return;
      setState(() {
        _users = users;
        // Giữ lại lựa chọn đã chọn chỉ khi người dùng vẫn còn trong danh sách
        _roleSelections.removeWhere(
          (key, value) => !_users.any((user) => user.userName == key),
        );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải người dùng: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _selectionFor(AppUser user) {
    return _roleSelections[user.userName] ?? user.role;
  }

  bool _isCurrentUser(AppUser user) {
    final current = _currentUsername;
    if (current == null) return false;
    return user.userName.toLowerCase() == current.toLowerCase();
  }

  bool _isEditable(AppUser user) {
    final role = user.role.toLowerCase();
    return !_isCurrentUser(user) && role != 'admin';
  }

  Future<void> _updateRole(AppUser user) async {
    final desiredRole = _selectionFor(user);
    if (desiredRole == user.role) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vai trò chưa thay đổi.')),
      );
      return;
    }

    setState(() => _updatingUsers.add(user.userName));
    try {
      await _api.updateUserRole(user.userName, desiredRole);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã chuyển ${user.userName} sang $desiredRole.')),
      );
      await _loadUsers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi cập nhật vai trò: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _updatingUsers.remove(user.userName));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _users.isEmpty
        ? ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.4,
                child: Center(
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Chưa có người dùng nào.'),
                ),
              ),
            ],
          )
        : ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: _users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _buildUserCard(_users[index]),
          );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách người dùng'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadUsers,
        child: _isLoading && _users.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
                ],
              )
            : body,
      ),
    );
  }

  Widget _buildUserCard(AppUser user) {
    final isEditable = _isEditable(user);
    final isUpdating = _updatingUsers.contains(user.userName);
    final avatarLabel = user.userName.isNotEmpty ? user.userName[0].toUpperCase() : '?';

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  child: Text(avatarLabel),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.userName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        user.email ?? 'Không có email',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                _buildRoleChip(user),
              ],
            ),
            if (!isEditable)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _isCurrentUser(user)
                      ? 'Bạn đang đăng nhập bằng tài khoản này (vai trò Admin).'
                      : 'Không thể thay đổi vai trò Admin.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey[600]),
                ),
              )
            else ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectionFor(user),
                      decoration: const InputDecoration(
                        labelText: 'Chọn vai trò mới',
                        border: OutlineInputBorder(),
                      ),
                      items: _editableRoles
                          .map(
                            (role) => DropdownMenuItem(
                              value: role,
                              child: Text(role),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _roleSelections[user.userName] = value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isUpdating ? null : () => _updateRole(user),
                      child: isUpdating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Lưu'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRoleChip(AppUser user) {
    final role = user.role;
    final roleLower = role.toLowerCase();
    Color color;
    switch (roleLower) {
      case 'admin':
        color = Colors.redAccent;
        break;
      case 'staff':
        color = Colors.blueAccent;
        break;
      default:
        color = Colors.grey;
    }
    return Chip(
      label: Text(
        role,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
      backgroundColor: color.withOpacity(0.15),
    );
  }
}
