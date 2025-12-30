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
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFFE0F2F1), Color(0xFFB2DFDB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category == null ? 'Thêm Category' : 'Chỉnh sửa Category',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên danh mục',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: colorController,
                    decoration: const InputDecoration(
                      labelText: 'Màu (#RRGGBB)',
                      prefixIcon: Icon(Icons.color_lens_outlined),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Hủy'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                        child: const Text('Lưu'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        title: const Text('Quản lý Category'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE0F2F1), Color(0xFFB2DFDB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
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
                    return _CategoryCard(
                      name: cat['categoryName'] ?? '',
                      colorCode: cat['colorCode'] ?? '',
                      color: color,
                      onEdit: () => _showCategoryDialog(category: cat),
                      onDelete: () => _deleteCategory(cat['id']),
                    );
                  },
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategoryDialog(),
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.add),
        label: const Text('Thêm category'),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String name;
  final String colorCode;
  final Color color;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryCard({
    required this.name,
    required this.colorCode,
    required this.color,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [color.withOpacity(0.15), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            offset: Offset(0, 10),
            blurRadius: 20,
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: color, child: const Icon(Icons.palette, color: Colors.white)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(colorCode, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined)),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          ),
        ],
      ),
    );
  }
}
