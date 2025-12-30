import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/event.dart';
import '../widgets/logout_button.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final ApiService _api = ApiService();
  List<Event> _allEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllSystemData();
  }

  // Admin gọi API riêng để lấy toàn bộ dữ liệu
  _loadAllSystemData() async {
    setState(() => _isLoading = true);
    final data = await _api.getEvents(true); // true để xác định là admin gọi
    setState(() {
      _allEvents = data.map((e) => Event.fromJson(e)).toList();
      _isLoading = false;
    });
  }

  _handleHideEvent(int id) async {
    await _api.hideEvent(id); // Gọi API Patch /Admin/hide/{id}
    _loadAllSystemData(); // Reload lại danh sách
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Đã ẩn sự kiện thành công")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hệ thống Quản trị (Admin)"),
        backgroundColor: Colors.redAccent,
        actions: [
          IconButton(onPressed: _loadAllSystemData, icon: const Icon(Icons.refresh)),
          const LogoutButton(),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: _allEvents.length,
            itemBuilder: (context, index) {
              final event = _allEvents[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Người dùng: ${event.userId ?? 'N/A'}\nTrạng thái: ${event.status}"),
                  trailing: event.status == "Active" 
                    ? ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                        onPressed: () => _handleHideEvent(event.id!),
                        child: const Text("Ẩn"),
                      )
                    : const Icon(Icons.visibility_off, color: Colors.grey),
                ),
              );
            },
          ),
    );
  }
}