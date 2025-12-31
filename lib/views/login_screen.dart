import 'package:flutter/material.dart';
import 'package:lephuoclong_btvn/views/admin_screen.dart';
import 'package:lephuoclong_btvn/views/register_screen.dart';
import 'package:lephuoclong_btvn/views/staff_screen.dart';
import 'package:lephuoclong_btvn/views/user_home_screen.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  final _apiService = ApiService();
  bool _isGoogleLoading = false; // Trạng thái chờ cho Google Login

  // Hàm điều hướng chung dựa trên Role
  void _navigateToDashboard(String role) {
    Widget destination;
    switch (role) {
      case 'Admin':
        destination = const AdminScreen();
        break;
      case 'Staff':
        destination = const StaffScreen();
        break;
      case 'User':
      default:
        destination = const UserHomeScreen();
        break;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  // Xử lý đăng nhập thông thường
  void _handleLogin() async {
    final response = await _apiService.login(
      _userController.text,
      _passController.text,
    );

    if (!mounted) return;

    if (response?.statusCode == 200 && response?.data != null) {
      final role = response!.data['role'] as String? ?? await _apiService.getUserRole();
      
      if (role != null) {
        _navigateToDashboard(role);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không xác định quyền người dùng.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tài khoản hoặc mật khẩu không chính xác')),
      );
    }
  }

  // --- MỚI: Xử lý đăng nhập Google ---
  void _handleGoogleLogin() async {
    setState(() => _isGoogleLoading = true);
    
    final response = await _apiService.loginWithGoogle();
    
    if (!mounted) return;
    setState(() => _isGoogleLoading = false);

    if (response != null && response.statusCode == 200) {
      final role = response.data['role'] as String? ?? 'User';
      _navigateToDashboard(role);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng nhập Google thất bại hoặc bị hủy')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1565C0), Color(0xFF5E92F3)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),
                  Text(
                    'Chào mừng trở lại',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Đăng nhập để tiếp tục quản lý lịch của bạn',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.white70),
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
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: _handleLogin,
                          child: const Text('Đăng nhập',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        
                        // --- MỚI: Nút Google Login ---
                        // Thay thế đoạn nút Google cũ bằng đoạn này:
const SizedBox(height: 16),
Center(
  child: SizedBox(
    width: double.infinity, // Giới hạn chiều rộng để tránh vạch vàng
    child: OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: const BorderSide(color: Colors.grey),
      ),
      onPressed: _isGoogleLoading ? null : _handleGoogleLogin,
      icon: _isGoogleLoading 
        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
        // Thay link ảnh này để tránh lỗi 404
        : Image.network(
            'https://www.gstatic.com/images/branding/product/2x/googleg_48dp.png',
            height: 24,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.login), // Hiện icon nếu link chết
          ),
      label: const Text('Tiếp tục với Google', style: TextStyle(color: Colors.black87)),
    ),
  ),
),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}