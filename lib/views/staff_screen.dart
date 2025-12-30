import 'package:flutter/material.dart';
import '../widgets/logout_button.dart';
import 'all_events_view_screen.dart';
import 'category_management_screen.dart';

class StaffScreen extends StatelessWidget {
  const StaffScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _StaffCardData(
        title: 'Quản lý Category',
        subtitle: 'Tạo, sửa, xóa danh mục sự kiện',
        icon: Icons.category_outlined,
        colors: const [Color(0xFF00695C), Color(0xFF26A69A)],
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CategoryManagementScreen()),
          );
        },
      ),
      _StaffCardData(
        title: 'Giám sát hệ thống',
        subtitle: 'Xem tất cả lịch trình ở chế độ đọc',
        icon: Icons.timeline,
        colors: const [Color(0xFF004D40), Color(0xFF009688)],
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AllEventsViewScreen(isAdmin: false),
            ),
          );
        },
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        title: const Text('Staff Dashboard'),
        actions: const [LogoutButton()],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE0F2F1), Color(0xFFB2DFDB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 1.05,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children:
                  tiles.map((data) => _StaffGradientCard(data: data)).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _StaffCardData {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  const _StaffCardData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    required this.onTap,
  });
}

class _StaffGradientCard extends StatelessWidget {
  final _StaffCardData data;

  const _StaffGradientCard({required this.data});

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
              color: Color(0x22000000),
              offset: Offset(0, 10),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: Icon(data.icon, color: Colors.white),
            ),
            const Spacer(),
            Text(
              data.title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              data.subtitle,
              style:
                  Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
