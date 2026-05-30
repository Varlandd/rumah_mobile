import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/rumah.dart';
import 'detail_rumah_screen.dart';
import 'package:intl/intl.dart';

class RekomendasiScreen extends StatefulWidget {
  const RekomendasiScreen({super.key});

  @override
  State<RekomendasiScreen> createState() => _RekomendasiScreenState();
}

class _RekomendasiScreenState extends State<RekomendasiScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _api = ApiService();

  // Form Controllers
  final _hargaC = TextEditingController();
  final _kamarTidurC = TextEditingController(text: "3");
  final _kamarMandiC = TextEditingController(text: "2");
  final _luasTanahC = TextEditingController(text: "120");
  final _luasBangunanC = TextEditingController(text: "80");

  String? _kota;
  String? _posisiKota;

  final List<String> _listKota = ['Jakarta', 'Bogor', 'Depok', 'Tangerang', 'Bekasi'];
  final List<String> _listPosisi = ['Pusat Kota', 'Dekat Pusat Kota', 'Pinggiran Kota'];

  bool _isLoading = false;
  Map<String, dynamic>? _resultData;

  @override
  void dispose() {
    _hargaC.dispose();
    _kamarTidurC.dispose();
    _kamarMandiC.dispose();
    _luasTanahC.dispose();
    _luasBangunanC.dispose();
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

    final harga = int.tryParse(_hargaC.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    
    if (harga <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Target harga harus lebih dari 0')));
      return;
    }

    setState(() {
      _isLoading = true;
      _resultData = null;
    });

    final payload = {
      'harga': harga,
      'kamar_tidur': int.tryParse(_kamarTidurC.text) ?? 1,
      'kamar_mandi': int.tryParse(_kamarMandiC.text) ?? 1,
      'luas_tanah': int.tryParse(_luasTanahC.text) ?? 1,
      'luas_bangunan': int.tryParse(_luasBangunanC.text) ?? 1,
      'kota': _kota,
      'posisi_kota': _posisiKota,
    };

    final result = await _api.recommendML(payload);
    
    if (!mounted) return;

    if (result != null && result['success'] == true) {
      setState(() {
        _resultData = result;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result?['message']?.toString() ?? 'Gagal menghubungi server.'),
        backgroundColor: Colors.red,
      ));
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Rekomendasi Pintar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                gradient: const LinearGradient(colors: [Color(0xFF0f766e), Color(0xFF0d9488)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🤖 ML KNN Clustering', 
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, height: 1.3)),
                  SizedBox(height: 8),
                  Text('Masukkan kriteria idamanmu, sistem akan menggunakan Machine Learning untuk mencari cluster terbaik.', 
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Form Target
            _buildSectionTitle('🎯 Target & Lokasi'),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade300)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildCurrencyInput('Target Harga (Rp)', _hargaC, Icons.payments),
                    const SizedBox(height: 16),
                    _buildDropdown('Kota', _kota, _listKota, (val) => setState(() => _kota = val), Icons.location_city),
                    const SizedBox(height: 16),
                    _buildDropdown('Posisi Kota', _posisiKota, _listPosisi, (val) => setState(() => _posisiKota = val), Icons.place),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Form Spesifikasi Fisik
            _buildSectionTitle('🏠 Spesifikasi Fisik'),
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
                      Icon(Icons.search),
                      SizedBox(width: 8),
                      Text('Cari Properti via AI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
    final listRumah = (data['data'] as List).map((e) => Rumah.fromJson(e)).toList();
    final isFallback = data['is_fallback'] ?? false;
    final reqKota = data['req_kota'] ?? _kota;
    
    // ML Data
    final isOnline = data['ml_status'] == 'online';
    final clusterId = data['predicted_cluster'];
    final kategori = data['kategori'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          
          // ML Cluster Badge
          if (isOnline && clusterId != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: clusterId == 0 ? Colors.green.shade200 : Colors.blue.shade200),
                boxShadow: [BoxShadow(color: (clusterId == 0 ? Colors.green : Colors.blue).withOpacity(0.05), blurRadius: 10)],
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
                      'AI mengklasifikasikan kriteria ini sebagai properti ${kategori ?? (clusterId==0?"Ekonomis":"Premium")}.',
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
              const Text('Rekomendasi Properti', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF0f766e).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Text('${listRumah.length} Properti', style: const TextStyle(color: Color(0xFF0f766e), fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (isFallback)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.amber.shade50, border: Border.all(color: Colors.amber.shade200), borderRadius: BorderRadius.circular(8)),
              child: Text('⚠️ Belum ada properti yang cocok di $reqKota dengan kriteria ini. Menampilkan rekomendasi properti dari klaster/rentang harga yang sama.', style: TextStyle(color: Colors.amber.shade900, fontSize: 12)),
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
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: listRumah.length,
              itemBuilder: (context, index) => _RumahCard(rumah: listRumah[index], rank: index + 1),
            ),
          
          const SizedBox(height: 32),
          Center(
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _resultData = null;
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Ubah Kriteria'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0f766e),
                side: const BorderSide(color: Color(0xFF0f766e)),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1f2937))),
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

  Widget _buildNumberInput(String label, TextEditingController controller, IconData icon) {
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
  final int rank;
  const _RumahCard({required this.rumah, required this.rank});

  String _formatHarga(int harga) {
    if (harga >= 1000000000) return 'Rp ${(harga / 1000000000).toStringAsFixed(1)} M';
    if (harga >= 1000000) return 'Rp ${(harga / 1000000).toStringAsFixed(0)} Jt';
    return 'Rp $harga';
  }

  @override
  Widget build(BuildContext context) {
    final medal = rank == 1 ? '🥇' : rank == 2 ? '🥈' : rank == 3 ? '🥉' : '#$rank';
    final MaterialColor badgeColor = rank == 1 ? Colors.amber : rank == 2 ? Colors.blueGrey : rank == 3 ? Colors.brown : Colors.grey;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: rank == 1 ? const BorderSide(color: Color(0xFF0f766e), width: 2) : BorderSide.none,
      ),
      elevation: 0,
      color: Colors.white,
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailRumahScreen(rumahId: rumah.id, namaRumah: rumah.nama))),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Rank badge
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [badgeColor.shade400, badgeColor.shade600]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: rank <= 3
                      ? Text(medal, style: const TextStyle(fontSize: 20))
                      : Text('#$rank', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                ),
              ),
              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rumah.nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text('${rumah.lokasi} · ${rumah.luasTanah}m² · ${rumah.kamarTidur}KT', style: TextStyle(fontSize: 11, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(_formatHarga(rumah.harga), style: const TextStyle(color: Color(0xFF0f766e), fontWeight: FontWeight.w800, fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
