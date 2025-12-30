import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart'; // MỚI: Thêm để quản lý quyền
import '../services/api_service.dart';
import '../services/notification_service.dart';

class AddEventScreen extends StatefulWidget {
  const AddEventScreen({super.key});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  final ApiService _api = ApiService();
  bool _isSaving = false;

  List<dynamic> _categories = [];
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final data = await _api.getCategories();
      setState(() {
        _categories = data;
        if (_categories.isNotEmpty) {
          _selectedCategoryId = _categories[0]['id'];
        }
      });
    } catch (e) {
      debugPrint("Lỗi tải Categories: $e");
    }
  }

  Future<void> _saveEvent() async {
    // --- BƯỚC MỚI: KIỂM TRA QUYỀN TRƯỚC KHI LÀM BẤT CỨ ĐIỀU GÌ ---
    // var status = await Permission.scheduleExactAlarm.status;
    // if (status.isDenied || status.isPermanentlyDenied) {
    //   if (mounted) {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       const SnackBar(content: Text('Vui lòng cấp quyền "Báo thức & nhắc nhở" để dùng thông báo.')),
    //     );
    //   }
    //   await openAppSettings(); // Mở cài đặt hệ thống
    //   return;
    // }
    // --------------------------------------------------------

    final title = _titleController.text.trim();
    if (title.isEmpty || _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tiêu đề và chọn loại.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final startTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    final endTime = startTime.add(const Duration(hours: 1));

    final payload = {
      'title': title,
      'description': _descController.text.trim(),
      'eventDate': startTime.toIso8601String(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'categoryId': _selectedCategoryId,
      'status': 'Active',
    };

    try {
      await _api.createEvent(payload);

      int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // A. Nhắc nhở trước 15 phút
      DateTime reminder15Min = startTime.subtract(const Duration(minutes: 15));
      if (reminder15Min.isAfter(DateTime.now())) {
        await NotificationService.scheduleNotification(
          id: notificationId,
          title: "Sắp đến hạn: $title",
          body: "Công việc này sẽ bắt đầu sau 15 phút nữa!",
          scheduledDate: reminder15Min,
        );
      }

      // B. Nhắc nhở đúng giờ bắt đầu
      if (startTime.isAfter(DateTime.now())) {
        await NotificationService.scheduleNotification(
          id: notificationId + 1,
          title: "Bắt đầu ngay: $title",
          body: "Đã đến giờ thực hiện công việc: $title",
          scheduledDate: startTime,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu sự kiện và đặt nhắc nhở!')),
      );
      Navigator.pop(context, true);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Thêm lịch trình mới")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: "Tiêu đề",
                hintText: "Nhập tên công việc...",
              ),
            ),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: "Mô tả",
                hintText: "Ghi chú thêm...",
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Chọn loại sự kiện:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _categories.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<int>(
                    value: _selectedCategoryId,
                    items: _categories.map((cat) {
                      final color = Color(
                        int.parse(cat['colorCode'].replaceAll('#', '0xff')),
                      );
                      return DropdownMenuItem<int>(
                        value: cat['id'],
                        child: Row(
                          children: [
                            Container(
                              width: 15,
                              height: 15,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(cat['categoryName']),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedCategoryId = val),
                  ),
            const SizedBox(height: 10),
            ListTile(
              title: Text("Ngày: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}"),
              trailing: const Icon(Icons.calendar_month),
              onTap: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) setState(() => _selectedDate = picked);
              },
            ),
            ListTile(
              title: Text("Giờ: ${_selectedTime.format(context)}"),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                TimeOfDay? picked = await showTimePicker(
                  context: context,
                  initialTime: _selectedTime,
                );
                if (picked != null) setState(() => _selectedTime = picked);
              },
            ),
            const SizedBox(height: 30),
            Center(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(15)),
                  onPressed: _isSaving ? null : _saveEvent,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Lưu sự kiện & Đặt nhắc nhở"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}