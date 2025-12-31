import 'package:flutter/material.dart';
import 'package:lephuoclong_btvn/views/statistics_screen.dart';
import 'package:lephuoclong_btvn/views/task_list_screen.dart';
import '../models/event.dart';
import '../services/api_service.dart';
import '../widgets/logout_button.dart';
import 'calendar_screen.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  final ApiService _api = ApiService();
  List<Event> _events = [];
  bool _isLoading = false;
  String? _userName;
  List<Event> _allEvents = [];

  @override
  void initState() {
    super.initState();
    _fetchEvents();
    _loadData();
  }

  Future<void> _fetchEvents() async {
    setState(() => _isLoading = true);
    try {
      final data = await _api.getEvents(false);
      setState(() {
        _allEvents = data.map((e) => Event.fromJson(e)).toList();
      });
    } catch (e) {
      debugPrint("Lỗi tải sự kiện: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final username = await _api.getUserName();
      final rawEvents = await _api.getEvents(false);
      final events = rawEvents.map((e) => Event.fromJson(e)).toList()
        ..sort((a, b) => a.eventDate.compareTo(b.eventDate));
      
      if (!mounted) return;
      setState(() {
        _userName = username;
        _events = events;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể tải lịch: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        title: const Text('Lịch cá nhân'),
        actions: [
          IconButton(
            icon: const Icon(Icons.pie_chart),
            tooltip: "Thống kê",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StatisticsScreen(allEvents: _allEvents),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: "Danh sách công việc",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TaskListScreen()),
              ).then((_) => _fetchEvents());
            },
          ),
          const LogoutButton(),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Column( // Sử dụng Column kết hợp Expanded để tránh lỗi layout
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildHeroCard(context),
            ),
            Expanded( // Bọc danh sách vào Expanded để sửa lỗi child.hasSize
              child: _isLoading && _events.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _events.isEmpty
                      ? Center(
                          child: Text(
                            'Chưa có sự kiện nào, hãy thêm lịch để bắt đầu.',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _events.length,
                          itemBuilder: (context, index) => _buildEventTile(context, _events[index]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    final greetingName = _userName ?? 'bạn';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF64B5F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            offset: Offset(0, 12),
            blurRadius: 28,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Xin chào, $greetingName',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Theo dõi mọi sự kiện quan trọng trong ngày của bạn.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white70),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CalendarScreen()),
                );
              },
              icon: const Icon(Icons.calendar_today_outlined, size: 18),
              label: const Text('Mở lịch chi tiết'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventTile(BuildContext context, Event event) {
    // XỬ LÝ GIAO DIỆN KHI SỰ KIỆN BỊ ẨN (Giống CalendarScreen)
    if (event.status.toLowerCase() == 'hidden') {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFFF5F5F5), Color(0xFFE0E0E0)],
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.visibility_off_outlined, color: Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Sự kiện đã bị admin ẩn',
                    style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Liên hệ admin để được hỗ trợ khôi phục hoặc xem chi tiết.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // GIAO DIỆN SỰ KIỆN BÌNH THƯỜNG
    final accentColor = _resolveColor(event.colorCode) ?? Colors.blueAccent;
    final statusColor = event.status.toLowerCase() == 'completed'
        ? Colors.green
        : Colors.orange;
    final subtitle = _formatDateRange(event.eventDate, event.endTime);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: IntrinsicHeight(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFFFFFFFF), Color(0xFFE3F2FD)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                offset: Offset(0, 8),
                blurRadius: 18,
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 8,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              event.title,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              event.status,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.blueGrey.shade600),
                      ),
                      if (event.categoryName != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            event.categoryName!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: accentColor, fontWeight: FontWeight.bold),
                          ),
                        ),
                      if (event.description != null && event.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            event.description!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.blueGrey.shade700),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateRange(DateTime start, DateTime? end) {
    final day = _twoDigits(start.day);
    final month = _twoDigits(start.month);
    final startTime = '${_twoDigits(start.hour)}:${_twoDigits(start.minute)}';
    if (end == null) {
      return '$day/$month · $startTime';
    }
    final endTime = '${_twoDigits(end.hour)}:${_twoDigits(end.minute)}';
    return '$day/$month · $startTime - $endTime';
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  Color? _resolveColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final value = hex.replaceAll('#', '');
    if (value.length == 6) {
      return Color(int.parse('0xFF$value'));
    }
    if (value.length == 8) {
      return Color(int.parse('0x$value'));
    }
    return null;
  }
}