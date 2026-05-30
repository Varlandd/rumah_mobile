import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../models/rumah.dart';
import 'detail_rumah_screen.dart';
import 'package:intl/intl.dart';

class RekomendasiFinansialScreen extends StatefulWidget {
  const RekomendasiFinansialScreen({super.key});

  @override
  State<RekomendasiFinansialScreen> createState() => _RekomendasiFinansialScreenState();
}

class _RekomendasiFinansialScreenState extends State<RekomendasiFinansialScreen> {
  final _formKey = GlobalKey<FormState>();
  final _kprFormKey = GlobalKey<FormState>();
  final ApiService _api = ApiService();

  // Form Controllers
  final _pendapatanC = TextEditingController();
  final _pengeluaranC = TextEditingController();
  final _kamarTidurC = TextEditingController(text: "3");
  final _kamarMandiC = TextEditingController(text: "2");
  final _luasTanahC = TextEditingController(text: "120");
  final _luasBangunanC = TextEditingController(text: "80");

  String? _kota;
  String? _posisiKota;

  final List<String> _listKota = ['Jakarta', 'Bogor', 'Depok', 'Tangerang', 'Bekasi'];
  final List<String> _listPosisi = ['Pusat Kota', 'Dekat Pusat Kota', 'Pinggiran Kota'];

  // KPR Form Controllers
  final _kprHargaC = TextEditingController();
  final _kprBungaC = TextEditingController(text: "8.5");
  int _kprDpPercent = 30;
  int _kprTenorTahun = 15;

  bool _isLoading = false;
  Map<String, dynamic>? _resultData;
  Map<String, dynamic>? _kprResult;

  @override
  void dispose() {
    _pendapatanC.dispose();
    _pengeluaranC.dispose();
    _kamarTidurC.dispose();
    _kamarMandiC.dispose();
    _luasTanahC.dispose();
    _luasBangunanC.dispose();
    _kprHargaC.dispose();
    _kprBungaC.dispose();
    super.dispose();
  }

  String _formatCurrency(num amount) {
    return NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  Future<void> _hitungRekomendasi() async {
    if (!_formKey.currentState!.validate()) return;
    if (_kota == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih Kota terlebih dahulu')));
      return;
    }
    if (_posisiKota == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih Posisi Kota terlebih dahulu')));
      return;
    }

    final pendapatan = int.tryParse(_pendapatanC.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final pengeluaran = int.tryParse(_pengeluaranC.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    
    if (pendapatan <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pendapatan harus lebih dari 0')));
      return;
    }
    if (pengeluaran >= pendapatan) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengeluaran harus lebih kecil dari pendapatan')));
      return;
    }

    setState(() {
      _isLoading = true;
      _resultData = null;
      _kprResult = null;
    });

    final payload = {
      'pendapatan': pendapatan,
      'pengeluaran': pengeluaran,
      'kamar_tidur': int.tryParse(_kamarTidurC.text) ?? 1,
      'kamar_mandi': int.tryParse(_kamarMandiC.text) ?? 1,
      'luas_tanah': int.tryParse(_luasTanahC.text) ?? 1,
      'luas_bangunan': int.tryParse(_luasBangunanC.text) ?? 1,
      'kota': _kota,
      'posisi_kota': _posisiKota,
    };

    final result = await _api.hitungRekomendasiFinansial(payload);
    
    if (!mounted) return;

    if (result != null && result['success'] == true) {
      setState(() {
        _resultData = result;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result?['message'] ?? 'Gagal menghubungi server.'),
        backgroundColor: Colors.red,
      ));
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _hitungKpr() {
    if (!_kprFormKey.currentState!.validate()) return;
    if (_resultData == null) return;

    final hargaRumah = int.tryParse(_kprHargaC.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final bungaTahunan = double.tryParse(_kprBungaC.text) ?? 8.5;
    
    if (hargaRumah <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harga rumah tidak valid')));
      return;
    }

    // Pendapatan dari data finansial
    final pendapatanBulanan = int.tryParse(_pendapatanC.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final pengeluaranBulanan = int.tryParse(_pengeluaranC.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    final dpAmount = hargaRumah * (_kprDpPercent / 100);
    final pokokPinjaman = hargaRumah - dpAmount;
    final tenorBulan = _kprTenorTahun * 12;
    final bungaBulanan = (bungaTahunan / 100) / 12;

    double cicilanBulanan = 0;
    if (bungaBulanan == 0) {
      cicilanBulanan = pokokPinjaman / tenorBulan;
    } else {
      final factor = pow(1 + bungaBulanan, tenorBulan);
      cicilanBulanan = pokokPinjaman * (bungaBulanan * factor) / (factor - 1);
    }

    final totalBayar = cicilanBulanan * tenorBulan;
    final totalBunga = totalBayar - pokokPinjaman;
    final dsr = (cicilanBulanan / pendapatanBulanan) * 100;
    final isLayak = dsr <= 30;
    final sisaPendapatan = pendapatanBulanan - pengeluaranBulanan - cicilanBulanan;

    setState(() {
      _kprResult = {
        'hargaRumah': hargaRumah,
        'dpAmount': dpAmount,
        'pokokPinjaman': pokokPinjaman,
        'cicilanBulanan': cicilanBulanan,
        'dsr': dsr,
        'isLayak': isLayak,
        'totalBayar': totalBayar,
        'totalBunga': totalBunga,
        'sisaPendapatan': sisaPendapatan,
        'bungaTahunan': bungaTahunan,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDFA),
      appBar: AppBar(
        title: const Text('Rekomendasi Finansial', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: const Color(0xFF0f766e),
        elevation: 0,
      ),
      body: _resultData == null 
          ? _buildForm() 
          : _buildResult(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF0d9488), Color(0xFF115e59)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('💰 Rekomendasi Rumah\nSesuai Kemampuan Finansial', 
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, height: 1.3)),
                  SizedBox(height: 8),
                  Text('Sistem akan menghitung budget ideal dan menggunakan AI untuk menemukan properti yang cocok.', 
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Form Data Keuangan
            _buildSectionTitle('💵 Data Keuangan', 'Wajib'),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade300)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildCurrencyInput('Pendapatan Total / Bulan', _pendapatanC, Icons.payments),
                    const SizedBox(height: 16),
                    _buildCurrencyInput('Total Pengeluaran / Bulan', _pengeluaranC, Icons.receipt_long),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Form Kriteria
            _buildSectionTitle('🏠 Kriteria Rumah Impian', 'Kriteria AI'),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade300)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildNumberInput('Kamar Tidur', _kamarTidurC, Icons.bed)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildNumberInput('Kamar Mandi', _kamarMandiC, Icons.shower)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildNumberInput('L. Tanah (m²)', _luasTanahC, Icons.landscape)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildNumberInput('L. Bangunan (m²)', _luasBangunanC, Icons.foundation)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown('Kota', _kota, _listKota, (val) => setState(() => _kota = val), Icons.location_city),
                    const SizedBox(height: 16),
                    _buildDropdown('Posisi Kota', _posisiKota, _listPosisi, (val) => setState(() => _posisiKota = val), Icons.place),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isLoading ? null : _hitungRekomendasi,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0f766e),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isLoading 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome),
                      SizedBox(width: 8),
                      Text('Hitung & Cari dengan AI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    final data = _resultData!;
    final budget = data['budget'];
    final pendapatanBersih = data['pendapatan_bersih'];
    final totalRumah = data['total_rumah'];
    final listRumah = (data['data'] as List).map((e) => Rumah.fromJson(e)).toList();
    final isFallback = data['is_fallback'];
    final reqKota = data['req_kota'];
    
    // ML Data
    final isOnline = data['ml_status'] == 'online';
    final clusterId = data['predicted_cluster'];
    final kategori = data['kategori'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Budget Summary
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0d9488), Color(0xFF115e59)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text('💎 Budget Rumah Ideal Kamu', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(_formatCurrency(budget), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          children: [
                            const Text('Pendapatan Bersih/Bulan', style: TextStyle(color: Colors.white70, fontSize: 11), textAlign: TextAlign.center),
                            const SizedBox(height: 4),
                            Text(_formatCurrency(pendapatanBersih), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          children: [
                            const Text('Rumus Budget', style: TextStyle(color: Colors.white70, fontSize: 11), textAlign: TextAlign.center),
                            const SizedBox(height: 4),
                            const Text('3 × (Bersih × 12)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ML Cluster Badge
          if (isOnline && clusterId != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: clusterId == 0 ? Colors.green.shade200 : Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: clusterId == 0 ? Colors.green.shade100 : Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      clusterId == 0 ? '🏡 Ekonomis' : '🏰 Premium',
                      style: TextStyle(fontWeight: FontWeight.bold, color: clusterId == 0 ? Colors.green.shade800 : Colors.blue.shade800),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'AI merekomendasikan properti kategori ${kategori ?? (clusterId==0?"Ekonomis":"Premium")}.',
                      style: const TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
            
          const SizedBox(height: 24),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('🏠 Rekomendasi Properti', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF0f766e).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Text('$totalRumah Properti', style: const TextStyle(color: Color(0xFF0f766e), fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (isFallback)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.amber.shade50, border: Border.all(color: Colors.amber.shade200), borderRadius: BorderRadius.circular(8)),
              child: Text('⚠️ Belum ada properti yang cocok di $reqKota dengan kriteria tersebut. Menampilkan properti dari kota lain yang sesuai budget.', style: TextStyle(color: Colors.amber.shade900, fontSize: 12)),
            ),

          if (listRumah.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text('Belum Ada Properti Sesuai', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    const Text('Coba ubah kriteria atau tingkatkan pendapatan untuk melihat lebih banyak pilihan.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: listRumah.length,
              itemBuilder: (context, index) => _RumahCard(rumah: listRumah[index]),
            ),
          
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 24),

          // KPR SECTION
          _buildSectionTitle('🏦 Simulasi KPR', 'Opsional'),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.amber.shade600, width: 2)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _kprFormKey,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8)),
                      child: const Text('Cek apakah kamu layak mengajukan KPR berdasarkan standar OJK/BI (Max DSR 30%, Min DP 20%).', style: TextStyle(fontSize: 12, color: Colors.black87)),
                    ),
                    _buildCurrencyInput('Harga Rumah Pilihan', _kprHargaC, Icons.home),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: _kprDpPercent,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Uang Muka (DP) %',
                        prefixIcon: const Icon(Icons.payments_outlined, color: Color(0xFFd97706)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: [20, 25, 30, 35, 40, 50].map((e) => DropdownMenuItem(value: e, child: Text('$e%'))).toList(),
                      onChanged: (v) => setState(() => _kprDpPercent = v ?? 30),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _kprTenorTahun,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Tenor (Tahun)',
                              prefixIcon: const Icon(Icons.calendar_today, color: Color(0xFFd97706)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            items: [5, 10, 15, 20, 25, 30].map((e) => DropdownMenuItem(value: e, child: Text('$e Tahun'))).toList(),
                            onChanged: (v) => setState(() => _kprTenorTahun = v ?? 15),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(child: _buildNumberInput('Bunga %/Thn', _kprBungaC, Icons.percent, color: const Color(0xFFd97706))),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _hitungKpr,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFd97706),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('🧮 Hitung Kelayakan KPR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (_kprResult != null) _buildKprResult(),

          const SizedBox(height: 40),
          Center(
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _resultData = null;
                  _kprResult = null;
                  _kprHargaC.clear();
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Hitung Ulang'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0f766e),
                side: const BorderSide(color: Color(0xFF0f766e)),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKprResult() {
    final k = _kprResult!;
    final isLayak = k['isLayak'];
    final dsr = k['dsr'] as double;
    final color = isLayak ? Colors.green : Colors.red;
    final icon = isLayak ? Icons.check_circle : Icons.cancel;
    final title = isLayak ? 'LAYAK KPR' : 'TIDAK LAYAK KPR';
    final desc = isLayak 
        ? 'Selamat! DSR kamu ${dsr.toStringAsFixed(1)}% (di bawah batas 30%). Memenuhi syarat standar OJK/BI.'
        : 'Maaf, DSR kamu ${dsr.toStringAsFixed(1)}% (melebihi batas 30%). Cicilan terlalu besar. Coba tambah DP atau perpanjang tenor.';

    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.shade300, width: 2),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, spreadRadius: 2)],
      ),
      child: Column(
        children: [
          Icon(icon, size: 64, color: color),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(desc, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),
          _buildKprDetailRow('Harga Rumah', _formatCurrency(k['hargaRumah'])),
          _buildKprDetailRow('Uang Muka (DP)', _formatCurrency(k['dpAmount'])),
          _buildKprDetailRow('Pokok Pinjaman', _formatCurrency(k['pokokPinjaman'])),
          _buildKprDetailRow('Tenor', '$_kprTenorTahun Tahun (${_kprTenorTahun*12} bln)'),
          _buildKprDetailRow('Suku Bunga', '${k['bungaTahunan']}% / Tahun'),
          const Divider(),
          _buildKprDetailRow('Cicilan per Bulan', _formatCurrency(k['cicilanBulanan']), isBold: true, valueColor: color),
          _buildKprDetailRow('Rasio DSR', '${dsr.toStringAsFixed(1)}%', isBold: true, valueColor: color),
        ],
      ),
    );
  }

  Widget _buildKprDetailRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(color: valueColor ?? Colors.black87, fontSize: 14, fontWeight: isBold ? FontWeight.w900 : FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String badge) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1f2937))),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: const Color(0xFF0f766e).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
          child: Text(badge, style: const TextStyle(color: Color(0xFF0f766e), fontSize: 10, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildCurrencyInput(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF0f766e), size: 18),
            prefixText: 'Rp ',
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
        ),
      ],
    );
  }

  Widget _buildNumberInput(String label, TextEditingController controller, IconData icon, {Color color = const Color(0xFF0f766e)}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: color, size: 18),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          validator: (val) => val == null || val.isEmpty ? '*' : null,
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, String? value, List<String> items, Function(String?) onChanged, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF0f766e), size: 18),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
          validator: (val) => val == null ? 'Pilih salah satu' : null,
        ),
      ],
    );
  }
}

class _RumahCard extends StatelessWidget {
  final Rumah rumah;
  const _RumahCard({required this.rumah});

  String _formatHarga(int harga) {
    if (harga >= 1000000000) return 'Rp ${(harga / 1000000000).toStringAsFixed(1)} M';
    if (harga >= 1000000) return 'Rp ${(harga / 1000000).toStringAsFixed(0)} Jt';
    return 'Rp $harga';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailRumahScreen(rumahId: rumah.id, namaRumah: rumah.nama))),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                  child: rumah.foto != null && rumah.foto!.isNotEmpty
                      ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(ApiService.getImageUrl(rumah.foto), fit: BoxFit.cover, errorBuilder: (_,__,___)=>const Icon(Icons.home, color: Colors.grey)))
                      : const Icon(Icons.home, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rumah.nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 12, color: Colors.grey),
                          const SizedBox(width: 2),
                          Expanded(child: Text(rumah.lokasi, style: const TextStyle(color: Colors.grey, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(_formatHarga(rumah.harga), style: const TextStyle(color: Color(0xFF0f766e), fontWeight: FontWeight.w800, fontSize: 15)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
