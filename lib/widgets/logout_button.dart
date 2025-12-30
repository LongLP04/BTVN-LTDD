import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../views/login_screen.dart';

class LogoutButton extends StatefulWidget {
  const LogoutButton({super.key});

  @override
  State<LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<LogoutButton> {
  final ApiService _apiService = ApiService();
  bool _isProcessing = false;

  Future<void> _handleLogout() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    await _apiService.logout();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Đăng xuất',
      onPressed: _isProcessing ? null : _handleLogout,
      icon: _isProcessing
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.logout),
    );
  }
}
