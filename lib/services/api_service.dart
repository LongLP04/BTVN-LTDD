import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_user.dart';
import '../utils/constants.dart';

class ApiService {
  late Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
    // Bỏ qua kiểm tra SSL cho Conveyor/Localhost
    (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      HttpClient client = HttpClient();
      client.badCertificateCallback = (cert, host, port) => true;
      return client;
    };
  }

  // Thêm Token vào Header cho mỗi Request
  Future<void> _setAuthHeader() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  Future<List<dynamic>> getCategories() async {
    await _setAuthHeader();
    try {
      final res = await _dio.get('/Categories');
      return (res.data as List?) ?? [];
    } catch (e) {
      debugPrint('Lỗi tải categories: $e');
      return [];
    }
  }

  Future<void> createCategory(String name, String colorCode) async {
    await _setAuthHeader();
    await _dio.post(
      '/Categories',
      data: {'categoryName': name, 'colorCode': colorCode},
    );
  }

  Future<void> updateCategory(int id, String name, String colorCode) async {
    await _setAuthHeader();
    await _dio.put(
      '/Categories/$id',
      data: {'categoryName': name, 'colorCode': colorCode},
    );
  }

  Future<void> deleteCategory(int id) async {
    await _setAuthHeader();
    await _dio.delete('/Categories/$id');
  }

  Future<void> completeEvent(int id) async {
    await _setAuthHeader();
    try {
      await _dio.put('/Events/$id/complete');
    } on DioException catch (e) {
      debugPrint('Chi tiết lỗi 400: ${e.response?.data}');
      throw Exception('Không thể cập nhật trạng thái');
    }
  }

  Future<bool> deleteEvent(int id) async {
    await _setAuthHeader();
    try {
      final res = await _dio.delete('/Events/$id');
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      debugPrint('Lỗi xóa sự kiện: $e');
      return false;
    }
  }

  Future<List<dynamic>> getAllEventsForStaff() async {
    await _setAuthHeader();
    try {
      final res = await _dio.get('/Admin/all-data');
      return (res.data as List?) ?? [];
    } catch (e) {
      debugPrint('Lỗi lấy dữ liệu tổng hợp: $e');
      return [];
    }
  }

  Future<bool> adminHideEvent(int id) async {
    await _setAuthHeader();
    try {
      final res = await _dio.patch('/Admin/hide/$id');
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('Lỗi khi ẩn sự kiện: $e');
      return false;
    }
  }

  Future<Response?> login(String username, String password) async {
    try {
      final res = await _dio.post(
        '/Auth/login',
        data: {'username': username, 'password': password},
      );

      if (res.statusCode == 200 && res.data != null) {
        final prefs = await SharedPreferences.getInstance();
        final token = res.data['token'] as String?;
        final role = res.data['role'] as String?;
        final userId = res.data['userId']?.toString();
        final userName =
            res.data['userName'] as String? ?? res.data['username'] as String?;

        if (token != null) {
          await prefs.setString('token', token);
        }

        if (role != null) {
          await prefs.setString('role', role);
        }

        if (userId != null) {
          await prefs.setString('userId', userId);
        }

        if (userName != null) {
          await prefs.setString('userName', userName);
        }
      }

      return res;
    } catch (e) {
      return null;
    }
  }

  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userName');
  }

  Future<Response?> register(String username, String password) async {
    try {
      final res = await _dio.post(
        '/Auth/register',
        data: {'username': username, 'password': password, 'role': 'User'},
      );
      return res;
    } catch (e) {
      return null;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('role');
    await prefs.remove('userId');
    await prefs.remove('userName');
    _dio.options.headers.remove('Authorization');
  }

  Future<void> createEvent(Map<String, dynamic> eventData) async {
    await _setAuthHeader();
    final prefs = await SharedPreferences.getInstance();
    final payload = Map<String, dynamic>.from(eventData);
    payload['userId'] ??= prefs.getString('userId');
    payload['userName'] ??= prefs.getString('userName');
    payload['status'] ??= 'Active';
    payload.removeWhere((key, value) => value == null);

    try {
      await _dio.post('/Events', data: payload);
    } on DioException catch (e) {
      throw Exception(_resolveServerError(e));
    }
  }

  Future<List<dynamic>> getEvents(bool bool) async {
    await _setAuthHeader();
    final res = await _dio.get('/Events');
    return res.data;
  }

  Future<bool> hideEvent(int id) async {
    await _setAuthHeader();
    final res = await _dio.patch('/Admin/hide/$id');
    return res.statusCode == 200;
  }

  Future<List<AppUser>> getUsersWithRoles() async {
    await _setAuthHeader();
    try {
      final res = await _dio.get('/Admin/users');
      final payload = res.data as List?;
      if (payload == null) return [];
      return payload
          .map((item) => AppUser.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      debugPrint('Lỗi tải danh sách người dùng: $e');
      return [];
    }
  }

  Future<void> updateUserRole(String username, String role) async {
    await _setAuthHeader();
    await _dio.post(
      '/Admin/update-role',
      data: {
        'username': username,
        'role': role,
      },
    );
  }

  String _resolveServerError(DioException exception) {
    final data = exception.response?.data;
    if (data is Map<String, dynamic>) {
      final keys = ['message', 'error', 'title', 'detail'];
      for (final key in keys) {
        final value = data[key];
        if (value != null) {
          return value.toString();
        }
      }

      final errors = data['errors'];
      if (errors is Map) {
        final buffer = StringBuffer();
        errors.forEach((key, value) {
          if (buffer.isNotEmpty) buffer.write('\n');
          final valueText = value is Iterable
              ? value.map((item) => item.toString()).join(', ')
              : value.toString();
          buffer.write('$key: $valueText');
        });
        if (buffer.isNotEmpty) {
          return buffer.toString();
        }
      }
    }

    return exception.message ?? 'Không thể tạo sự kiện.';
  }
  // Khởi tạo GoogleSignIn với WEB Client ID (Ảnh image_4a7a72.png)
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: "866783897282-bsb23df7hdmb5c9eddqlhd9ago85gpsd.apps.googleusercontent.com",
  );

  Future<Response?> loginWithGoogle() async {
    try {
      // 1. Kích hoạt cửa sổ chọn tài khoản của Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      // 2. Lấy thông tin xác thực
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // 3. Gửi idToken lên Backend ASP.NET Core
      final response = await _dio.post(
        '/Auth/google-login',
        data: {
          'idToken': googleAuth.idToken,
        },
      );

      // --- PHẦN QUAN TRỌNG: Lưu Token và thông tin vào máy (Sửa lỗi 401) ---
      if (response.statusCode == 200 && response.data != null) {
        final prefs = await SharedPreferences.getInstance();
        final data = response.data;
        
        // Lưu các thông tin cần thiết giống như hàm login thông thường
        if (data['token'] != null) await prefs.setString('token', data['token']);
        if (data['role'] != null) await prefs.setString('role', data['role']);
        if (data['userId'] != null) await prefs.setString('userId', data['userId'].toString());
        if (data['userName'] != null) await prefs.setString('userName', data['userName']);
        
        // Cập nhật ngay lập tức vào header của Dio để dùng luôn
        _dio.options.headers['Authorization'] = 'Bearer ${data['token']}';
      }

      return response;
    } catch (e) {
      print("Lỗi chi tiết Google Login: $e");
      return null;
    }
  }
}
