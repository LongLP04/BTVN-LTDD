import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; //
import 'services/notification_service.dart'; //
import 'views/login_screen.dart';

void main() async {
  // Đảm bảo các ràng buộc của Flutter đã được khởi tạo trước khi gọi async code
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Khởi tạo Notification Service
  await NotificationService.init(); 

  // 2. Xin quyền thông báo (Đặc biệt quan trọng cho Android 13+ trên máy ảo)
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lê Phước Long Calendar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LoginScreen(), // Luôn bắt đầu từ màn hình Login
    );
  }
}