import 'package:flutter/material.dart';
import '../widgets/logout_button.dart';

class StaffScreen extends StatelessWidget {
  const StaffScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Dashboard'),
        actions: const [LogoutButton()],
      ),
      body: const Center(child: Text('Welcome, Staff!')),
    );
  }
}
