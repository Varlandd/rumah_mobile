import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/user.dart';
import '../models/rumah.dart';
import '../models/budget_result.dart';

class ApiService {
  // UNTUK EMULATOR: http://10.0.2.2:8000/api
  // UNTUK HP FISIK: http://192.168.x.x:8000/api
  static const String baseUrl = kIsWeb 
      ? 'http://127.0.0.1:8000/api' 
      : 'http://10.10.186.109:8000/api';

  static String getImageUrl(String? foto) {
    if (foto == null) return '';
    if (foto.startsWith('http')) return foto;
    final base = baseUrl.replaceAll('/api', '');
    final path = foto.startsWith('/') ? foto : '/$foto';
    return '$base$path';
  }

  final storage = const FlutterSecureStorage();

  Future<String?> getToken() async {
    print("API: getToken started");
    try {
      final token = await storage
          .read(key: 'auth_token')
          .timeout(const Duration(seconds: 3));
      print("API: storage.read completed");
      return token;
    } catch (e) {
      print("API: getToken caught error: $e");
      return null;
    }
  }

  Future<Map<String, String>> getHeaders({bool needsAuth = false}) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (needsAuth) {
      String? token = await getToken();
      print("API: getHeaders - token found: ${token != null}");
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    print("API: Request Headers: $headers");
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
        return {
          'success': false,
          'message': data['message'] ?? 'Registrasi gagal',
        };
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
        body: jsonEncode({'email': email, 'password': password}),
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

  Future<User?> getProfile() async {
    print("API: getProfile started");
    try {
      print("API: getProfile making request to $baseUrl/user");
      final response = await http
          .get(
            Uri.parse('$baseUrl/user'),
            headers: await getHeaders(needsAuth: true),
          )
          .timeout(const Duration(seconds: 8));

      print("API: getProfile received response ${response.statusCode}");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return User.fromJson(
          data['data'],
        ); // Adjusted because my Laravel API returns ['data' => $user]
      }
      return null;
    } catch (e) {
      print("API: getProfile caught error: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
    String? phone,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/user/profile'),
        headers: await getHeaders(needsAuth: true),
        body: jsonEncode({'name': name, 'email': email, 'phone': phone}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success']) {
        return {'success': true, 'user': User.fromJson(data['data'])};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Gagal update profil',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> updatePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/user/password'),
        headers: await getHeaders(needsAuth: true),
        body: jsonEncode({
          'current_password': currentPassword,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success']) {
        return {'success': true};
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Gagal update password',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ========== RUMAH ==========

  Future<List<Rumah>> getRumah({int page = 1, int perPage = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/rumah?page=$page&per_page=$perPage'),
        headers: await getHeaders(needsAuth: false),
      ).timeout(const Duration(seconds: 10));

      print("API: getRumah URL: ${baseUrl}/rumah");
      print("API: getRumah status ${response.statusCode}");
      print("API: getRumah body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // CASE 1: Laravel Paginate { success: true, data: { data: [...] } }
        if (data['data'] is Map && data['data']['data'] is List) {
          return (data['data']['data'] as List)
              .map((json) => Rumah.fromJson(json))
              .toList();
        }

        // CASE 2: { success: true, data: [...] }
        if (data['data'] is List) {
          return (data['data'] as List)
              .map((json) => Rumah.fromJson(json))
              .toList();
        }

        // CASE 3: langsung array
        if (data is List) {
          return data.map((json) => Rumah.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print("API ERROR getRumah: $e");
      return [];
    }
  }

  Future<Rumah?> getRumahDetail(String id) async {
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
    List<String>? fasilitas,
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

  Future<bool> toggleFavorit(String rumahId) async {
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
      print("API ERROR getLokasi: $e");
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

  // ========== ANALITIK (MLR & SAW) ==========

  Future<Map<String, dynamic>> predict({
    required String lokasi,
    required int luasTanah,
    required int luasBangunan,
    required int kamarTidur,
    required int kamarMandi,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/predict'),
        headers: await getHeaders(needsAuth: true),
        body: jsonEncode({
          'lokasi': lokasi,
          'luas_tanah': luasTanah,
          'luas_bangunan': luasBangunan,
          'kamar_tidur': kamarTidur,
          'kamar_mandi': kamarMandi,
        }),
      );

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan jaringan: $e'};
    }
  }

  Future<List<Rumah>> recommend({
    String? lokasi,
    int? budgetMax,
    int? wHarga,
    int? wTanah,
    int? wBangunan,
    int? wKamar,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/recommend'),
        headers: await getHeaders(needsAuth: true),
        body: jsonEncode({
          'lokasi': lokasi,
          'budget_max': budgetMax,
          'w_harga': wHarga,
          'w_tanah': wTanah,
          'w_bangunan': wBangunan,
          'w_kamar': wKamar,
        }),
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
}
