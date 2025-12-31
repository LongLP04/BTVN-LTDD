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
    (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      HttpClient client = HttpClient();
      client.badCertificateCallback = (cert, host, port) => true;
      return client;
    };
  }

  // --- HỆ THỐNG & AUTH ---

  Future<void> _setAuthHeader() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  Future<void> _saveLoginSession(dynamic data) async {
    final prefs = await SharedPreferences.getInstance();
    final token = data['token'] as String?;
    final role = data['role'] as String?;
    final userId = data['userId']?.toString();
    final userName = data['userName'] as String? ?? data['username'] as String?;

    if (token != null) await prefs.setString('token', token);
    if (role != null) await prefs.setString('role', role);
    if (userId != null) await prefs.setString('userId', userId);
    if (userName != null) await prefs.setString('userName', userName);

    if (token != null) _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  Future<Response?> login(String username, String password) async {
    try {
      final res = await _dio.post('/Auth/login', data: {'username': username, 'password': password});
      if (res.statusCode == 200 && res.data != null) {
        if (res.data['requiresTwoFactor'] != true) {
          await _saveLoginSession(res.data);
        }
      }
      return res;
    } catch (e) { return null; }
  }

  Future<Response?> register(String username, String password) async {
    try {
      return await _dio.post('/Auth/register', data: {'username': username, 'password': password, 'role': 'User'});
    } catch (e) { return null; }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _dio.options.headers.remove('Authorization');
  }

  // --- BẢO MẬT 2 LỚP (2FA) ---

  Future<Map<String, dynamic>?> setup2FA() async {
    await _setAuthHeader();
    try {
      final res = await _dio.get('/Auth/setup-2fa');
      return res.data;
    } catch (e) { return null; }
  }

  Future<bool> enable2FA(String code) async {
    await _setAuthHeader();
    try {
      final res = await _dio.post('/Auth/enable-2fa', data: {'code': code});
      return res.statusCode == 200;
    } catch (e) { return false; }
  }

  Future<Response?> verify2FALogin(String username, String code) async {
    try {
      final res = await _dio.post('/Auth/verify-2fa-login', data: {'username': username, 'code': code});
      if (res.statusCode == 200 && res.data != null) await _saveLoginSession(res.data);
      return res;
    } catch (e) { return null; }
  }

  // --- QUẢN LÝ DANH MỤC (CATEGORY) ---

  Future<List<dynamic>> getCategories() async {
    await _setAuthHeader();
    try {
      final res = await _dio.get('/Categories');
      return (res.data as List?) ?? [];
    } catch (e) { return []; }
  }

  Future<void> createCategory(String name, String color) async {
    await _setAuthHeader();
    await _dio.post('/Categories', data: {'categoryName': name, 'colorCode': color});
  }

  Future<void> updateCategory(int id, String name, String color) async {
    await _setAuthHeader();
    await _dio.put('/Categories/$id', data: {'categoryName': name, 'colorCode': color});
  }

  Future<void> deleteCategory(int id) async {
    await _setAuthHeader();
    await _dio.delete('/Categories/$id');
  }

  // --- QUẢN LÝ SỰ KIỆN (EVENT) ---

  Future<List<dynamic>> getEvents(bool refresh) async {
    await _setAuthHeader();
    try {
      final res = await _dio.get('/Events');
      return res.data;
    } catch (e) { return []; }
  }

  Future<void> createEvent(Map<String, dynamic> data) async {
    await _setAuthHeader();
    await _dio.post('/Events', data: data);
  }

  Future<void> completeEvent(int id) async {
    await _setAuthHeader();
    await _dio.put('/Events/$id/complete');
  }

  Future<bool> deleteEvent(int id) async {
    await _setAuthHeader();
    try {
      final res = await _dio.delete('/Events/$id');
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) { return false; }
  }

  // --- ADMIN & STAFF ---

  Future<List<dynamic>> getAllEventsForStaff() async {
    await _setAuthHeader();
    try {
      final res = await _dio.get('/Admin/all-data');
      return (res.data as List?) ?? [];
    } catch (e) { return []; }
  }

  Future<bool> adminHideEvent(int id) async {
    await _setAuthHeader();
    try {
      final res = await _dio.patch('/Admin/hide/$id');
      return res.statusCode == 200;
    } catch (e) { return false; }
  }

  Future<List<AppUser>> getUsersWithRoles() async {
    await _setAuthHeader();
    try {
      final res = await _dio.get('/Admin/users');
      return (res.data as List).map((i) => AppUser.fromJson(i)).toList();
    } catch (e) { return []; }
  }

  Future<void> updateUserRole(String username, String role) async {
    await _setAuthHeader();
    await _dio.post('/Admin/update-role', data: {'username': username, 'role': role});
  }

  // --- TIỆN ÍCH KHÁC ---

  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }

  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userName');
  }

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: "866783897282-bsb23df7hdmb5c9eddqlhd9ago85gpsd.apps.googleusercontent.com",
  );

  Future<Response?> loginWithGoogle() async {
    try {
      final user = await _googleSignIn.signIn();
      if (user == null) return null;
      final auth = await user.authentication;
      final res = await _dio.post('/Auth/google-login', data: {'idToken': auth.idToken});
      if (res.statusCode == 200) await _saveLoginSession(res.data);
      return res;
    } catch (e) { return null; }
  }
}