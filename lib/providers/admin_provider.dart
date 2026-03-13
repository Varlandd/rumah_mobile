import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/rumah.dart';
import '../services/api_service.dart';

class AdminProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // --- STATS ---
  Map<String, dynamic>? _dashboardStats;
  Map<String, dynamic>? get dashboardStats => _dashboardStats;

  Future<void> fetchDashboardStats() async {
    _setLoading(true);
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/admin/dashboard'),
        headers: await _api.getHeaders(needsAuth: true),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          _dashboardStats = data['data'];
        }
      }
    } catch (e) {
      _errorMessage = 'Gagal memuat statistik';
    }
    _setLoading(false);
  }

  // --- USERS ---
  List<User> _users = [];
  List<User> get users => _users;

  Future<void> fetchUsers() async {
    _setLoading(true);
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/admin/users'),
        headers: await _api.getHeaders(needsAuth: true),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          _users = (data['data'] as List).map((u) => User.fromJson(u)).toList();
        }
      }
    } catch (e) {
      _errorMessage = 'Gagal memuat pengguna';
    }
    _setLoading(false);
  }

  Future<bool> updateUserRole(int userId, String role) async {
    _setLoading(true);
    try {
      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/admin/users/$userId/role'),
        headers: await _api.getHeaders(needsAuth: true),
        body: jsonEncode({'role': role}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          await fetchUsers();
          return true;
        }
      }
      _errorMessage = 'Gagal mengubah role';
      return false;
    } catch (e) {
      _errorMessage = 'Error: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteUser(int userId) async {
    _setLoading(true);
    try {
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/admin/users/$userId'),
        headers: await _api.getHeaders(needsAuth: true),
      );

      if (response.statusCode == 200) {
        await fetchUsers();
        return true;
      }
      _errorMessage = 'Gagal menghapus user';
      return false;
    } catch (e) {
      _errorMessage = 'Error: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // --- RUMAH CRUD ---
  Future<bool> createRumah(Map<String, String> fields, {String? imagePath}) async {
    _setLoading(true);
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/admin/rumah'),
      );
      request.headers.addAll(await _api.getHeaders(needsAuth: true));
      request.fields.addAll(fields);

      if (imagePath != null) {
        request.files.add(await http.MultipartFile.fromPath('foto', imagePath));
      }

      var streamResponse = await request.send();
      var response = await http.Response.fromStream(streamResponse);

      if (response.statusCode == 201) {
        return true;
      }
      _errorMessage = jsonDecode(response.body)['message'] ?? 'Gagal menambah rumah';
      return false;
    } catch (e) {
      _errorMessage = 'Error: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateRumah(int id, Map<String, String> fields, {String? imagePath}) async {
    _setLoading(true);
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/admin/rumah/$id'),
      );
      request.headers.addAll(await _api.getHeaders(needsAuth: true));
      
      // Use hidden method override for PUT if needed, but since we rely on file upload, we registered the route as POST
      
      request.fields.addAll(fields);

      if (imagePath != null) {
        request.files.add(await http.MultipartFile.fromPath('foto', imagePath));
      }

      var streamResponse = await request.send();
      var response = await http.Response.fromStream(streamResponse);

      if (response.statusCode == 200) {
        return true;
      }
      _errorMessage = jsonDecode(response.body)['message'] ?? 'Gagal mengubah rumah';
      return false;
    } catch (e) {
      _errorMessage = 'Error: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteRumah(int id) async {
    _setLoading(true);
    try {
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/admin/rumah/$id'),
        headers: await _api.getHeaders(needsAuth: true),
      );

      if (response.statusCode == 200) {
        return true;
      }
      _errorMessage = 'Gagal menghapus rumah';
      return false;
    } catch (e) {
      _errorMessage = 'Error: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
