import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AllEventsViewScreen extends StatefulWidget {
  final bool isAdmin;
  const AllEventsViewScreen({super.key, required this.isAdmin});

  @override
  State<AllEventsViewScreen> createState() => _AllEventsViewScreenState();
}

class _AllEventsViewScreenState extends State<AllEventsViewScreen> {
  final ApiService _api = ApiService();
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.getAllEventsForStaff();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _api.getAllEventsForStaff();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isAdmin ? 'Quản lý lịch trình' : 'Danh sách lịch trình',
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }
          final events = snapshot.data ?? [];
          if (events.isEmpty) {
            return const Center(child: Text('Chưa có sự kiện.'));
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: events.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final event = events[index];
                return Card(
                  child: ListTile(
                    title: Text(event['title'] ?? 'Không tên'),
                    subtitle: Text(
                      'Người tạo: ${event['userName'] ?? 'N/A'}\nTrạng thái: ${event['status'] ?? 'Unknown'}',
                    ),
                    trailing: widget.isAdmin
                        ? IconButton(
                            icon: const Icon(
                              Icons.visibility_off,
                              color: Colors.orange,
                            ),
                            onPressed: () => _confirmHide(event['id']),
                          )
                        : null,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmHide(dynamic eventId) async {
    if (eventId == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ẩn sự kiện'),
        content: const Text('Bạn chắc chắn muốn ẩn sự kiện này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ẩn'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _api.adminHideEvent(eventId as int);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Đã ẩn sự kiện.' : 'Ẩn thất bại.'),
        ),
      );
      if (success) {
        _refresh();
      }
    }
  }
}
