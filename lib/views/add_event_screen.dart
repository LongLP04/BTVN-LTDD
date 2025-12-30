import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
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
      backgroundColor: Colors.indigo.shade50,
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        title: const Text('Thêm lịch trình mới'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE8EAF6), Color(0xFFEEF2FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildSectionHeader(
                context,
                icon: Icons.event_note,
                title: 'Thông tin sự kiện',
                subtitle: 'Đặt tiêu đề, mô tả và phân loại chi tiết',
              ),
              const SizedBox(height: 16),
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Tiêu đề',
                        prefixIcon: Icon(Icons.title_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Mô tả',
                        prefixIcon: Icon(Icons.notes_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Chọn loại sự kiện',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    _categories.isEmpty
                        ? const Center(child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: CircularProgressIndicator(),
                          ))
                        : DropdownButtonFormField<int>(
                            value: _selectedCategoryId,
                            decoration: const InputDecoration(
                              labelText: 'Danh mục',
                              prefixIcon: Icon(Icons.category_outlined),
                            ),
                            items: _categories.map((cat) {
                              final color = Color(
                                int.parse(cat['colorCode'].replaceAll('#', '0xff')),
                              );
                              return DropdownMenuItem<int>(
                                value: cat['id'],
                                child: Row(
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
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
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(
                context,
                icon: Icons.calendar_today,
                title: 'Thời gian diễn ra',
                subtitle: 'Thiết lập ngày giờ chính xác cho lịch trình',
              ),
              const SizedBox(height: 16),
              _buildCard(
                child: Column(
                  children: [
                    _InputChipButton(
                      label: 'Ngày: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                      icon: Icons.calendar_month_outlined,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setState(() => _selectedDate = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    _InputChipButton(
                      label: 'Giờ: ${_selectedTime.format(context)}',
                      icon: Icons.schedule,
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _selectedTime,
                        );
                        if (picked != null) {
                          setState(() => _selectedTime = picked);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: _isSaving ? null : _saveEvent,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    _isSaving ? 'Đang lưu...' : 'Lưu sự kiện & đặt nhắc nhở',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: Colors.indigo.withOpacity(0.1),
          child: Icon(icon, color: Colors.indigo),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.blueGrey,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            offset: Offset(0, 10),
            blurRadius: 24,
          ),
        ],
      ),
      child: child,
    );
  }
}

class _InputChipButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _InputChipButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.indigo.withOpacity(0.05),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.indigo),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.indigo),
          ],
        ),
      ),
    );
  }
}