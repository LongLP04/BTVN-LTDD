import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    // Thêm vào file lib/services/api_service.dart
    Future<List<dynamic>> getCategories() async {
      await _setAuthHeader();
      try {
        final res = await _dio.get('/Categories');
        return res.data;
      } catch (e) {
        return []; // Trả về danh sách trống nếu lỗi
      }
    }
    Future<void> completeEvent(int id) async {
      await _setAuthHeader();
      try {
        // Gọi trực tiếp vào endpoint chuyên biệt để tránh gửi thiếu dữ liệu model
        await _dio.put('/Events/$id/complete');
      } on DioException catch (e) {
        // In lỗi chi tiết ra console để dễ debug nếu vẫn lỗi
        print("Chi tiết lỗi 400: ${e.response?.data}");
        throw Exception("Không thể cập nhật trạng thái");
      }
    }
    // Trong lib/services/api_service.dart
    Future<bool> deleteEvent(int id) async {
      await _setAuthHeader();
      try {
        final res = await _dio.delete('/Events/$id');
        return res.statusCode == 200 || res.statusCode == 204;
      } catch (e) {
        debugPrint("Lỗi xóa sự kiện: $e");
        return false;
      }
    }
    // --- QUẢN LÝ CATEGORY (Dành cho Admin & Staff) ---

  Future<void> createCategory(Map<String, dynamic> data) async {
    await _setAuthHeader();
    try {
      await _dio.post('/Categories', data: data);
    } catch (e) {
      throw Exception("Không thể thêm loại mới");
    }
  }

  Future<void> updateCategory(int id, Map<String, dynamic> data) async {
    await _setAuthHeader();
    try {
      await _dio.put('/Categories/$id', data: data);
    } catch (e) {
      throw Exception("Không thể cập nhật loại");
    }
  }

  Future<void> deleteCategory(int id) async {
    await _setAuthHeader();
    try {
      await _dio.delete('/Categories/$id');
    } catch (e) {
      throw Exception("Không thể xóa loại này");
    }
  }

  // --- QUẢN LÝ EVENT TỔNG HỢP (Dành cho Admin & Staff) ---

  Future<List<dynamic>> getAllEventsForStaff() async {
    await _setAuthHeader();
    try {
      // Gọi vào AdminController như bạn đã viết ở Backend
      final res = await _dio.get('/Admin/all-data');
      return res.data;
    } catch (e) {
      debugPrint("Lỗi lấy dữ liệu tổng hợp: $e");
      return [];
    }
  }

  // Hàm ẩn Event (Chỉ Admin mới có quyền gọi thành công)
  Future<bool> adminHideEvent(int id) async {
    await _setAuthHeader();
    try {
      final res = await _dio.patch('/Admin/hide/$id');
      return res.statusCode == 200;
    } catch (e) {
      debugPrint("Lỗi khi ẩn sự kiện: $e");
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
}
