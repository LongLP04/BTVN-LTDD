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
  bool _isGoogleLoading = false;

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

  // --- MỚI: Hộp thoại nhập mã OTP 2FA ---
  void _showTwoFactorDialog(String username) {
    final otpController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false, // Bắt buộc người dùng phải nhập hoặc nhấn Hủy
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xác thực 2 lớp'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Vui lòng nhập mã 6 số từ ứng dụng Google Authenticator của bạn.'),
            const SizedBox(height: 20),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Mã xác thực',
                prefixIcon: Icon(Icons.security),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final response = await _apiService.verify2FALogin(
                username,
                otpController.text,
              );
              if (!mounted) return;

              if (response != null && response.statusCode == 200) {
                Navigator.pop(context); // Đóng Dialog
                final role = response.data['role'] as String? ?? 'User';
                _navigateToDashboard(role);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mã xác thực không chính xác')),
                );
              }
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  void _handleLogin() async {
    final response = await _apiService.login(
      _userController.text,
      _passController.text,
    );

    if (!mounted) return;

    if (response?.statusCode == 200 && response?.data != null) {
      // KIỂM TRA NẾU BACKEND YÊU CẦU 2FA
      if (response!.data['requiresTwoFactor'] == true) {
        _showTwoFactorDialog(response.data['username']);
      } else {
        final role = response.data['role'] as String? ?? await _apiService.getUserRole();
        if (role != null) {
          _navigateToDashboard(role);
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tài khoản hoặc mật khẩu không chính xác')),
      );
    }
  }

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
    // Giữ nguyên phần UI build của bạn
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
                        const SizedBox(height: 16),
                        Center(
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                                side: const BorderSide(color: Colors.grey),
                              ),
                              onPressed:
                                  _isGoogleLoading ? null : _handleGoogleLogin,
                              icon: _isGoogleLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : Image.network(
                                      'https://www.gstatic.com/images/branding/product/2x/googleg_48dp.png',
                                      height: 24,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(Icons.login),
                                    ),
                              label: const Text('Tiếp tục với Google',
                                  style: TextStyle(color: Colors.black87)),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const RegisterScreen()),
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
      ),
    );
  }
}