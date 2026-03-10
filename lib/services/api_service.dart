import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../models/rumah.dart';
import '../models/budget_result.dart';

class ApiService {
  // UNTUK EMULATOR: http://10.0.2.2:8000/api
  // UNTUK HP FISIK (WiFi sama): http://192.168.x.x:8000/api (ganti IP komputer Anda)
  static const String baseUrl = 'http://10.0.2.2:8000/api';
  
  final storage = const FlutterSecureStorage();

  Future<String?> getToken() async {
    return await storage.read(key: 'auth_token');
  }

  Future<Map<String, String>> getHeaders({bool needsAuth = false}) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (needsAuth) {
      String? token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // ========== AUTH ==========

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: await getHeaders(),
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
          'phone': phone,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success']) {
        await storage.write(key: 'auth_token', value: data['data']['token']);
        return {'success': true, 'user': User.fromJson(data['data']['user'])};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Registrasi gagal'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: await getHeaders(),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        await storage.write(key: 'auth_token', value: data['data']['token']);
        return {'success': true, 'user': User.fromJson(data['data']['user'])};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Login gagal'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<void> logout() async {
    try {
      await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: await getHeaders(needsAuth: true),
      );
    } catch (e) {
      // Ignore
    } finally {
      await storage.delete(key: 'auth_token');
    }
  }

  // ========== RUMAH ==========

  Future<List<Rumah>> getRumah({int page = 1, int perPage = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/rumah?page=$page&per_page=$perPage'),
        headers: await getHeaders(needsAuth: true),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return (data['data']['data'] as List)
              .map((json) => Rumah.fromJson(json))
              .toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Rumah?> getRumahDetail(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/rumah/$id'),
        headers: await getHeaders(needsAuth: true),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return Rumah.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<Rumah>> searchRumah({
    String? lokasi,
    int? budgetMin,
    int? budgetMax,
    String? tipe,
    List<int>? fasilitas,
  }) async {
    try {
      Map<String, dynamic> body = {};
      if (lokasi != null) body['lokasi'] = lokasi;
      if (budgetMin != null) body['budget_min'] = budgetMin;
      if (budgetMax != null) body['budget_max'] = budgetMax;
      if (tipe != null) body['tipe'] = tipe;
      if (fasilitas != null) body['fasilitas'] = fasilitas;

      final response = await http.post(
        Uri.parse('$baseUrl/rumah/search'),
        headers: await getHeaders(needsAuth: true),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return (data['data']['data'] as List)
              .map((json) => Rumah.fromJson(json))
              .toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ========== KALKULATOR ==========

  Future<BudgetResult?> hitungBudget({
    required int penghasilan,
    required int uangMuka,
    int cicilanLain = 0,
    required int tenor,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/kalkulator'),
        headers: await getHeaders(needsAuth: true),
        body: jsonEncode({
          'penghasilan': penghasilan,
          'uang_muka': uangMuka,
          'cicilan_lain': cicilanLain,
          'tenor': tenor,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return BudgetResult.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ========== FAVORIT ==========

  Future<List<Rumah>> getFavorit() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/favorit'),
        headers: await getHeaders(needsAuth: true),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return (data['data'] as List)
              .map((json) => Rumah.fromJson(json))
              .toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> toggleFavorit(int rumahId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/favorit/$rumahId'),
        headers: await getHeaders(needsAuth: true),
      );

      if (response.statusCode == 200) {
        return true;
      }

      if (response.statusCode == 400) {
        final deleteResponse = await http.delete(
          Uri.parse('$baseUrl/favorit/$rumahId'),
          headers: await getHeaders(needsAuth: true),
        );
        return deleteResponse.statusCode == 200;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  // ========== STATS ==========

  Future<Map<String, dynamic>?> getStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/stats'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ========== LOKASI & FASILITAS ==========

  Future<List<String>> getLokasi() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/lokasi'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return List<String>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Fasilitas>> getFasilitas() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/fasilitas'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return (data['data'] as List)
              .map((json) => Fasilitas.fromJson(json))
              .toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
