import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/api_service.dart';

class PrediksiScreen extends StatefulWidget {
  const PrediksiScreen({super.key});

  @override
  State<PrediksiScreen> createState() => _PrediksiScreenState();
}

class _PrediksiScreenState extends State<PrediksiScreen> {
  static const _primary = Color(0xFF0f766e);

  final _formKey = GlobalKey<FormState>();
  String? _lokasi;
  final _luasTanahC = TextEditingController();
  final _luasBangunanC = TextEditingController();
  final _kamarTidurC = TextEditingController();
  final _kamarMandiC = TextEditingController();

  bool _loading = false;
  double? _predictedPrice;
  double? _minPrice;
  double? _maxPrice;
  String? _error;

  List<String> _lokasiList = [];

  @override
  void initState() {
    super.initState();
    _loadLokasi();
  }

  void _loadLokasi() async {
    final list = await ApiService().getLokasi();
    if (mounted) setState(() => _lokasiList = list);
  }

  String _formatRp(double value) {
    if (value >= 1000000000) {
      return 'Rp ${(value / 1000000000).toStringAsFixed(2)} Miliar';
    } else if (value >= 1000000) {
      return 'Rp ${(value / 1000000).toStringAsFixed(0)} Juta';
    }
    return 'Rp ${value.toStringAsFixed(0)}';
  }

  Future<void> _predict() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
      _predictedPrice = null;
    });

    try {
      final res = await ApiService().predict(
        lokasi: _lokasi!,
        luasTanah: int.parse(_luasTanahC.text),
        luasBangunan: int.parse(_luasBangunanC.text),
        kamarTidur: int.parse(_kamarTidurC.text),
        kamarMandi: int.parse(_kamarMandiC.text),
      );

      if (res['success'] == true) {
        final price = (res['data']['predicted_price'] as num).toDouble();
        setState(() {
          _predictedPrice = price;
          _minPrice = price * 0.85;
          _maxPrice = price * 1.15;
        });
      } else {
        setState(() => _error = res['message'] ?? 'Gagal memproses prediksi');
      }
    } catch (e) {
      setState(() => _error = 'Kesalahan jaringan: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _luasTanahC.dispose();
    _luasBangunanC.dispose();
    _kamarTidurC.dispose();
    _kamarMandiC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Prediksi Harga'),
        backgroundColor: _primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0f766e), Color(0xFF0d9488)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Icon(Icons.auto_graph_rounded, size: 40, color: Colors.white),
                  SizedBox(height: 8),
                  Text(
                    'Prediksi Harga Properti',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Estimasi harga berdasarkan AI/Machine Learning',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Form
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Spesifikasi Properti', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),

                      // Lokasi
                      DropdownButtonFormField<String>(
                        value: _lokasi,
                        decoration: _inputDecor('Lokasi', Icons.location_on_outlined),
                        items: _lokasiList.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                        onChanged: (v) => setState(() => _lokasi = v),
                        validator: (v) => v == null ? 'Pilih lokasi' : null,
                      ),
                      const SizedBox(height: 14),

                      // Luas
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _luasTanahC,
                              keyboardType: TextInputType.number,
                              decoration: _inputDecor('Luas Tanah (m²)', Icons.crop_square_outlined),
                              validator: (v) => (v == null || v.isEmpty) ? 'Wajib' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _luasBangunanC,
                              keyboardType: TextInputType.number,
                              decoration: _inputDecor('Luas Bangunan (m²)', Icons.home_work_outlined),
                              validator: (v) => (v == null || v.isEmpty) ? 'Wajib' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Kamar
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _kamarTidurC,
                              keyboardType: TextInputType.number,
                              decoration: _inputDecor('Kamar Tidur', Icons.bed_outlined),
                              validator: (v) => (v == null || v.isEmpty) ? 'Wajib' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _kamarMandiC,
                              keyboardType: TextInputType.number,
                              decoration: _inputDecor('Kamar Mandi', Icons.bathroom_outlined),
                              validator: (v) => (v == null || v.isEmpty) ? 'Wajib' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Submit
                      ElevatedButton.icon(
                        onPressed: _loading ? null : _predict,
                        icon: _loading
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.auto_awesome),
                        label: Text(_loading ? 'Memproses...' : 'Prediksi Harga'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(_error!, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
              ),
            ],

            // Result
            if (_predictedPrice != null) ...[
              const SizedBox(height: 20),
              _buildResult(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: _primary.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.analytics_outlined, size: 36, color: _primary),
            const SizedBox(height: 8),
            const Text('Estimasi Harga', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              _formatRp(_predictedPrice!),
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _primary),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _rangeBox('Batas Bawah', _formatRp(_minPrice!), Colors.orange),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _rangeBox('Batas Atas', _formatRp(_maxPrice!), Colors.blue),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '* Estimasi berdasarkan algoritma Multiple Linear Regression dari data properti Jabodetabek',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _rangeBox(String label, String value, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color.shade700)),
        ],
      ),
    );
  }

  InputDecoration _inputDecor(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: _primary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      isDense: true,
    );
  }
}
