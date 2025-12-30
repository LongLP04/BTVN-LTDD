import 'package:flutter/material.dart';
import 'package:lephuoclong_btvn/views/admin_screen.dart';
import 'package:lephuoclong_btvn/views/calendar_screen.dart';
import 'package:lephuoclong_btvn/views/register_screen.dart';
import 'package:lephuoclong_btvn/views/staff_screen.dart';
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
          destination = const CalendarScreen();
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
      appBar: AppBar(title: const Text("Đăng Nhập")), // Thêm const
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Thêm const
        child: Column(
          children: [
            TextField(
              controller: _userController,
              decoration: const InputDecoration(
                labelText: "Tài khoản",
              ), // Thêm const
            ),
            TextField(
              controller: _passController,
              decoration: const InputDecoration(
                labelText: "Mật khẩu",
              ), // Thêm const
              obscureText: true,
            ),
            const SizedBox(height: 20), // Thêm const
            ElevatedButton(
              onPressed: _handleLogin,
              child: const Text("Đăng Nhập"),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                );
              },
              child: const Text('Chưa có tài khoản? Đăng ký'),
            ),
          ],
        ),
      ),
    );
  }
}
