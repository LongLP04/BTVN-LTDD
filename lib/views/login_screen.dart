import 'package:flutter/material.dart';
import 'package:lephuoclong_btvn/views/admin_screen.dart';
import 'package:lephuoclong_btvn/views/register_screen.dart';
import 'package:lephuoclong_btvn/views/staff_screen.dart';
import 'package:lephuoclong_btvn/views/user_home_screen.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  // Thêm key parameter để hết cảnh báo Problem
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  final _apiService = ApiService();

  void _handleLogin() async {
    final response = await _apiService.login(
      _userController.text,
      _passController.text,
    );

    if (!mounted) return;

    if (response?.statusCode == 200 && response?.data != null) {
      final roleFromResponse = response!.data['role'] as String?;
      final storedRole = roleFromResponse ?? await _apiService.getUserRole();
      if (!mounted) return;

      if (storedRole == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không xác định quyền người dùng.')),
        );
        return;
      }

      Widget? destination;
      switch (storedRole) {
        case 'Admin':
          destination = const AdminScreen();
          break;
        case 'Staff':
          destination = const StaffScreen();
          break;
        case 'User':
          destination = const UserHomeScreen();
          break;
      }

      if (destination != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => destination!),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Quyền $storedRole chưa được hỗ trợ.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tài khoản hoặc mật khẩu không chính xác'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1565C0), Color(0xFF5E92F3)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),
                Text(
                  'Chào mừng trở lại',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Đăng nhập để tiếp tục quản lý lịch của bạn',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 32),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22000000),
                        offset: Offset(0, 16),
                        blurRadius: 32,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _userController,
                        decoration: const InputDecoration(
                          labelText: 'Tài khoản',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passController,
                        decoration: const InputDecoration(
                          labelText: 'Mật khẩu',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _handleLogin,
                        child: const Text(
                          'Đăng nhập',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const RegisterScreen()),
                          );
                        },
                        child: const Text('Chưa có tài khoản? Đăng ký ngay'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
