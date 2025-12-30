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
        backgroundColor: Colors.blueGrey.shade50,
        appBar: AppBar(
          backgroundColor: Colors.blueGrey,
          foregroundColor: Colors.white,
          title: const Text('Danh sách công việc'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: Colors.white.withOpacity(0.2),
              ),
              child: const TabBar(
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                ),
                labelColor: Colors.blueGrey,
                unselectedLabelColor: Colors.white70,
                tabs: [
                  Tab(text: 'Chưa xong', icon: Icon(Icons.pending_actions)),
                  Tab(text: 'Đã xong', icon: Icon(Icons.check_circle_outline)),
                ],
              ),
            ),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFECEFF1), Color(0xFFE8F5E9)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  children: [
                    _buildTaskList(activeTasks, false),
                    _buildTaskList(completedTasks, true),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildTaskList(List<Event> tasks, bool isDone) {
    if (tasks.isEmpty) {
      return const Center(child: Text('Không có dữ liệu'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white,
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F000000),
                offset: Offset(0, 8),
                blurRadius: 18,
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isDone ? Colors.green : Colors.grey,
                ),
                onPressed: isDone ? null : () => _toggleComplete(task.id!),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                        color: isDone ? Colors.grey : Colors.black,
                      ),
                    ),
                    Text(
                      task.categoryName ?? 'Công việc',
                      style: TextStyle(
                        color: isDone ? Colors.grey : Colors.blueGrey,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.blueGrey),
            ],
          ),
        );
      },
    );
  }
}