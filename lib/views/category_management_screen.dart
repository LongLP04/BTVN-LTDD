import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = false;
  List<dynamic> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    final data = await _api.getCategories();
    setState(() {
      _categories = data;
      _isLoading = false;
    });
  }

  Future<void> _showCategoryDialog({Map<String, dynamic>? category}) async {
    final nameController = TextEditingController(
      text: category?['categoryName'],
    );
    final colorController = TextEditingController(
      text: category?['colorCode'] ?? '#4285F4',
    );

    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
              category == null ? 'Thêm Category' : 'Chỉnh sửa Category',
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Tên'),
                ),
                TextField(
                  controller: colorController,
                  decoration:
                      const InputDecoration(labelText: 'Màu (#RRGGBB)'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                child: const Text('Lưu'),
              ),
            ],
          );
        },
      );

      if (result == true) {
        final name = nameController.text.trim();
        final color = colorController.text.trim();
        if (name.isEmpty || !_isValidHex(color)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tên hoặc mã màu chưa hợp lệ.')),
          );
          return;
        }

        setState(() => _isLoading = true);
        try {
          if (category == null) {
            await _api.createCategory(name, color);
          } else {
            await _api.updateCategory(category['id'], name, color);
          }
          await _loadCategories();
        } catch (e) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
        }
      }
    } finally {
      nameController.dispose();
      colorController.dispose();
    }
  }

  Future<void> _deleteCategory(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa Category'),
        content: const Text('Bạn có chắc chắn muốn xóa?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _api.deleteCategory(id);
        await _loadCategories();
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không thể xóa: $e')));
      }
    }
  }

  bool _isValidHex(String value) {
    final code = value.startsWith('#') ? value.substring(1) : value;
    if (code.length != 6) return false;
    return int.tryParse(code, radix: 16) != null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý Category')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCategories,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final color = Color(
                    int.parse(cat['colorCode'].replaceAll('#', '0xff')),
                  );
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(backgroundColor: color),
                      title: Text(cat['categoryName'] ?? ''),
                      subtitle: Text(cat['colorCode'] ?? ''),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showCategoryDialog(category: cat),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteCategory(cat['id']),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
