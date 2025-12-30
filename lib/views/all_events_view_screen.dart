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
      backgroundColor: widget.isAdmin ? Colors.deepPurple.shade50 : Colors.teal.shade50,
      appBar: AppBar(
        backgroundColor: widget.isAdmin ? Colors.deepPurple : Colors.teal,
        foregroundColor: Colors.white,
        title: Text(widget.isAdmin ? 'Điều hành dữ liệu' : 'Giám sát hệ thống'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: widget.isAdmin
                ? const [Color(0xFFF3E5F5), Color(0xFFEDE7F6)]
                : const [Color(0xFFE0F7FA), Color(0xFFD0ECE7)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FutureBuilder<List<dynamic>>(
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
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(
                      height: 300,
                      child: Center(child: Text('Chưa có sự kiện.')),
                    ),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: events.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final event = events[index];
                  final status = (event['status'] ?? 'Unknown').toString();
                  return _EventAdminCard(
                    event: event,
                    status: status,
                    isAdmin: widget.isAdmin,
                    onHide: () => _confirmHide(event['id']),
                  );
                },
              ),
            );
          },
        ),
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

class _EventAdminCard extends StatelessWidget {
  final Map<String, dynamic> event;
  final String status;
  final bool isAdmin;
  final VoidCallback onHide;

  const _EventAdminCard({
    required this.event,
    required this.status,
    required this.isAdmin,
    required this.onHide,
  });

  @override
  Widget build(BuildContext context) {
    final creator = event['userName'] ?? 'N/A';
    final category = event['categoryName'] ?? 'Không phân loại';
    final color = _resolveColor(event['colorCode']) ?? (isAdmin ? Colors.deepPurple : Colors.teal);
    final subtitle = event['description'] ?? '';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [color.withOpacity(0.15), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            offset: Offset(0, 10),
            blurRadius: 22,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    event['title'] ?? 'Không tên',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                _StatusChip(status: status),
              ],
            ),
            const SizedBox(height: 8),
            Text('Người tạo: $creator', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text('Danh mục: $category', style: Theme.of(context).textTheme.bodySmall),
            if (subtitle.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ),
            if (isAdmin)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.deepOrange,
                  ),
                  onPressed: onHide,
                  icon: const Icon(Icons.visibility_off_outlined),
                  label: const Text('Ẩn sự kiện'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color? _resolveColor(dynamic code) {
    if (code is String && code.isNotEmpty) {
      final value = code.replaceAll('#', '');
      if (value.length == 6) return Color(int.parse('0xFF$value'));
      if (value.length == 8) return Color(int.parse('0x$value'));
    }
    return null;
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toLowerCase()) {
      case 'completed':
        color = Colors.green;
        break;
      case 'hidden':
        color = Colors.grey;
        break;
      default:
        color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
