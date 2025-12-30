import 'package:flutter/material.dart';
import 'package:lephuoclong_btvn/views/add_event_screen.dart';
import 'package:lephuoclong_btvn/views/task_list_screen.dart';
import 'package:lephuoclong_btvn/views/statistics_screen.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/api_service.dart';
import '../models/event.dart';
import '../widgets/logout_button.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final ApiService _api = ApiService();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Event> _allEvents = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchEvents();
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

  List<Event> _getEventsForDay(DateTime day) {
    return _allEvents.where((e) => isSameDay(e.eventDate, day)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final selectedEvents = _selectedDay != null ? _getEventsForDay(_selectedDay!) : [];

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        title: const Text('Lịch của tôi'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.pie_chart_outline),
            tooltip: 'Thống kê',
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
            icon: const Icon(Icons.list_alt_outlined),
            tooltip: 'Danh sách công việc',
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F2FD), Color(0xFFF1F8FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Phần 1: Lịch (Kích thước cố định hoặc tự co giãn)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Colors.white,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x12000000),
                      offset: Offset(0, 8),
                      blurRadius: 18,
                    ),
                  ],
                ),
                child: TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2035, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onFormatChanged: (format) {
                    setState(() => _calendarFormat = format);
                  },
                  eventLoader: _getEventsForDay,
                  calendarStyle: const CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: Color(0xFFFFB300),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Color(0xFF1E88E5),
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: BoxDecoration(
                      color: Color(0xFFEF5350),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
            
            // Phần 2: Danh sách sự kiện (Dùng Expanded để tránh lỗi child.hasSize)
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : selectedEvents.isEmpty
                      ? const Center(child: Text('Không có sự kiện nào trong ngày này.'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: selectedEvents.length,
                          itemBuilder: (context, index) {
                            final event = selectedEvents[index];
                            final status = event.status.toLowerCase();
                            final isHidden = status == 'hidden';

                            if (isHidden) {
                              return _HiddenEventCard(key: ValueKey('hidden-${event.id}'));
                            }

                            return Dismissible(
                              key: ValueKey(event.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                              confirmDismiss: (_) async {
                                return await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Xác nhận xóa'),
                                    content: Text("Bạn có chắc muốn xóa '${event.title}' không?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Hủy'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('Xóa', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                ) ?? false;
                              },
                              onDismissed: (_) async {
                                final success = await _api.deleteEvent(event.id!);
                                if (success) {
                                  setState(() {
                                    _allEvents.removeWhere((e) => e.id == event.id);
                                  });
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Đã xóa công việc')),
                                  );
                                } else {
                                  _fetchEvents();
                                }
                              },
                              child: _CalendarEventCard(event: event),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEventScreen()),
          ).then((value) {
            if (value == true) _fetchEvents();
          });
        },
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.add),
        label: const Text('Thêm sự kiện'),
      ),
    );
  }
}

class _CalendarEventCard extends StatelessWidget {
  final Event event;
  const _CalendarEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final isCompleted = event.status.toLowerCase() == 'completed';
    final accentColor = event.colorCode != null
        ? Color(int.parse(event.colorCode!.replaceAll('#', '0xff')))
        : Colors.blueAccent;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            offset: Offset(0, 8),
            blurRadius: 18,
          ),
        ],
      ),
      child: ClipRRect( // Đảm bảo thanh màu bo góc khớp với Card
        borderRadius: BorderRadius.circular(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start, // Tránh lỗi chiều cao của Row
          children: [
            Container(
              width: 8,
              constraints: const BoxConstraints(minHeight: 80), // Chiều cao tối thiểu
              color: isCompleted ? Colors.grey : accentColor,
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
                              decoration: isCompleted ? TextDecoration.lineThrough : null,
                              color: isCompleted ? Colors.grey : Colors.black,
                            ),
                          ),
                        ),
                        _StatusPill(status: event.status),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(event.categoryName ?? 'Chưa phân loại',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: accentColor)),
                    if (event.description != null && event.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          event.description!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.blueGrey.shade700),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HiddenEventCard extends StatelessWidget {
  const _HiddenEventCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.grey.shade200,
      ),
      child: Row(
        children: [
          const Icon(Icons.visibility_off_outlined, color: Colors.grey),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sự kiện đã bị admin ẩn',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54),
                ),
                SizedBox(height: 4),
                Text(
                  'Liên hệ admin để khôi phục.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toLowerCase()) {
      case 'completed': color = Colors.green; break;
      case 'hidden': color = Colors.grey; break;
      default: color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 10),
      ),
    );
  }
}