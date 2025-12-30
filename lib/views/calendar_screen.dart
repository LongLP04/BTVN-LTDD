import 'package:flutter/material.dart';
import 'package:lephuoclong_btvn/views/add_event_screen.dart';
import 'package:lephuoclong_btvn/views/task_list_screen.dart';
import 'package:lephuoclong_btvn/views/statistics_screen.dart'; // Import màn hình thống kê
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

  // Hàm tải dữ liệu từ Server
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

  // Lọc danh sách sự kiện theo ngày được chọn
  List<Event> _getEventsForDay(DateTime day) {
    return _allEvents.where((e) => isSameDay(e.eventDate, day)).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Lấy danh sách sự kiện của ngày đang chọn
    final selectedEvents = _selectedDay != null ? _getEventsForDay(_selectedDay!) : [];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Lịch của tôi"),
        centerTitle: true,
        actions: [
          // Nút Thống kê
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
          // Trong calendar_screen.dart -> AppBar -> actions
          
          // Nút danh sách công việc
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
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
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
              todayDecoration: BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
              selectedDecoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
              markerDecoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
            ),
          ),
          const Divider(),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : selectedEvents.isEmpty
                ? const Center(child: Text("Không có sự kiện nào trong ngày này."))
                : ListView.builder(
                    itemCount: selectedEvents.length,
                    itemBuilder: (context, index) {
                      final event = selectedEvents[index];
                      bool isCompleted = event.status == "Completed";

                      // Bọc Card trong Dismissible để thực hiện tính năng vuốt xóa
                      return Dismissible(
                        key: Key(event.id.toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          color: Colors.red,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Xác nhận xóa"),
                              content: Text("Bạn có chắc muốn xóa '${event.title}' không?"),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Hủy")),
                                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Xóa", style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          );
                        },
                        onDismissed: (direction) async {
                          final success = await _api.deleteEvent(event.id!);
                          if (success) {
                            setState(() {
                              _allEvents.removeWhere((e) => e.id == event.id);
                            });
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã xóa công việc")));
                          } else {
                            _fetchEvents(); // Tải lại nếu xóa thất bại ở server
                          }
                        },
                        child: Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            leading: Container(
                              width: 5,
                              height: 30,
                              decoration: BoxDecoration(
                                color: isCompleted 
                                    ? Colors.grey 
                                    : (event.colorCode != null 
                                        ? Color(int.parse(event.colorCode!.replaceAll('#', '0xff'))) 
                                        : Colors.blue),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            title: Text(
                              event.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                decoration: isCompleted ? TextDecoration.lineThrough : null,
                                color: isCompleted ? Colors.grey : Colors.black,
                              ),
                            ),
                            subtitle: Text(event.categoryName ?? "Chưa phân loại"),
                            trailing: isCompleted 
                                ? const Icon(Icons.check_circle, color: Colors.green, size: 22)
                                : Text(
                                    event.status, 
                                    style: const TextStyle(fontSize: 10, color: Colors.blueGrey)
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEventScreen()),
          ).then((value) {
            if (value == true) _fetchEvents();
          });
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}