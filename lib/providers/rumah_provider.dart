import 'package:flutter/material.dart';
import '../models/rumah.dart';
import '../models/budget_result.dart';
import '../services/api_service.dart';

class RumahProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Rumah> _rumahList = [];
  List<Rumah> _searchResults = [];
  List<Rumah> _favoritList = [];
  Rumah? _selectedRumah;
  BudgetResult? _budgetResult;
  Map<String, dynamic>? _stats;
  List<String> _lokasiList = [];
  List<Fasilitas> _fasilitasList = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Rumah> get rumahList => _rumahList;
  List<Rumah> get searchResults => _searchResults;
  List<Rumah> get favoritList => _favoritList;
  Rumah? get selectedRumah => _selectedRumah;
  BudgetResult? get budgetResult => _budgetResult;
  Map<String, dynamic>? get stats => _stats;
  List<String> get lokasiList => _lokasiList;
  List<Fasilitas> get fasilitasList => _fasilitasList;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ── Rumah ──

  Future<void> fetchRumah({int page = 1, int perPage = 10}) async {
    _isLoading = true;
    notifyListeners();

    _rumahList = await _api.getRumah(page: page, perPage: perPage);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchRumahDetail(int id) async {
    _isLoading = true;
    notifyListeners();

    _selectedRumah = await _api.getRumahDetail(id);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> searchRumah({
    String? lokasi,
    int? budgetMin,
    int? budgetMax,
    String? tipe,
    List<int>? fasilitas,
  }) async {
    _isLoading = true;
    notifyListeners();

    _searchResults = await _api.searchRumah(
      lokasi: lokasi,
      budgetMin: budgetMin,
      budgetMax: budgetMax,
      tipe: tipe,
      fasilitas: fasilitas,
    );

    _isLoading = false;
    notifyListeners();
  }

  // ── Kalkulator ──

  Future<void> hitungBudget({
    required int penghasilan,
    required int uangMuka,
    int cicilanLain = 0,
    required int tenor,
  }) async {
    _isLoading = true;
    notifyListeners();

    _budgetResult = await _api.hitungBudget(
      penghasilan: penghasilan,
      uangMuka: uangMuka,
      cicilanLain: cicilanLain,
      tenor: tenor,
    );

    _isLoading = false;
    notifyListeners();
  }

  // ── Favorit ──

  Future<void> fetchFavorit() async {
    _isLoading = true;
    notifyListeners();

    _favoritList = await _api.getFavorit();

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> toggleFavorit(int rumahId) async {
    final success = await _api.toggleFavorit(rumahId);
    if (success) {
      await fetchFavorit(); // Refresh favorit list
    }
    return success;
  }

  // ── Stats ──

  Future<void> fetchStats() async {
    _stats = await _api.getStats();
    notifyListeners();
  }

  // ── Lokasi & Fasilitas ──

  Future<void> fetchLokasi() async {
    _lokasiList = await _api.getLokasi();
    notifyListeners();
  }

  Future<void> fetchFasilitas() async {
    _fasilitasList = await _api.getFasilitas();
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
