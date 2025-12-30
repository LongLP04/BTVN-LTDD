import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/event.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final ApiService _api = ApiService();
  List<Event> _allTasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  // Chỉnh sửa để lấy tất cả sự kiện (bao gồm cả Completed)
  _loadTasks() async {
    setState(() => _isLoading = true);
    // Lưu ý: Đảm bảo Backend API GetMyEvents không còn lọc cứng e.Status == "Active" 
    // Hoặc bạn có thể tạo 1 API riêng lấy all.
    final data = await _api.getEvents(false); 
    setState(() {
      _allTasks = data.map((e) => Event.fromJson(e)).toList();
      _isLoading = false;
    });
  }

  _toggleComplete(int id) async {
    try {
      await _api.completeEvent(id);
      _loadTasks(); // Load lại để cập nhật danh sách
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lọc danh sách cho 2 tab
    final activeTasks = _allTasks.where((t) => t.status != "Completed").toList();
    final completedTasks = _allTasks.where((t) => t.status == "Completed").toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Danh sách công việc"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Chưa xong", icon: Icon(Icons.pending_actions)),
              Tab(text: "Đã xong", icon: Icon(Icons.check_circle_outline)),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildTaskList(activeTasks, false),    // Tab Chưa xong
                  _buildTaskList(completedTasks, true),   // Tab Đã xong
                ],
              ),
      ),
    );
  }

  Widget _buildTaskList(List<Event> tasks, bool isDone) {
    if (tasks.isEmpty) return const Center(child: Text("Không có dữ liệu"));
    
    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: ListTile(
            leading: IconButton(
              icon: Icon(
                isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isDone ? Colors.green : Colors.grey,
              ),
              onPressed: isDone ? null : () => _toggleComplete(task.id!),
            ),
            title: Text(
              task.title,
              style: TextStyle(
                decoration: isDone ? TextDecoration.lineThrough : null,
                color: isDone ? Colors.grey : Colors.black,
              ),
            ),
            subtitle: Text(task.categoryName ?? "Công việc"),
          ),
        );
      },
    );
  }
}