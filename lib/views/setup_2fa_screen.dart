import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/api_service.dart';

class Setup2FAScreen extends StatefulWidget {
  const Setup2FAScreen({super.key});

  @override
  State<Setup2FAScreen> createState() => _Setup2FAScreenState();
}

class _Setup2FAScreenState extends State<Setup2FAScreen> {
  final _api = ApiService();
  final _codeController = TextEditingController();
  String? _qrCodeUri;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSetupData();
  }

  void _loadSetupData() async {
    final data = await _api.setup2FA();
    if (data != null) {
      setState(() {
        _qrCodeUri = data['qrCodeUri'];
        _isLoading = false;
      });
    }
  }

  void _handleEnable() async {
    final success = await _api.enable2FA(_codeController.text);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã bật 2FA thành công!")));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mã xác nhận không đúng")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Thiết lập bảo mật 2 lớp")),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text("1. Cài đặt ứng dụng Google Authenticator trên điện thoại."),
                const SizedBox(height: 10),
                const Text("2. Quét mã QR dưới đây:"),
                const SizedBox(height: 20),
                Center(
                  child: QrImageView(
                    data: _qrCodeUri!,
                    version: QrVersions.auto,
                    size: 250.0,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _codeController,
                  decoration: const InputDecoration(labelText: "Nhập mã 6 số từ ứng dụng"),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                ElevatedButton(onPressed: _handleEnable, child: const Text("Kích hoạt ngay"))
              ],
            ),
          ),
    );
  }
}