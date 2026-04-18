import 'package:flutter/material.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../models/rumah.dart';
import 'detail_rumah_screen.dart';

class WizardScreen extends StatefulWidget {
  const WizardScreen({super.key});

  @override
  State<WizardScreen> createState() => _WizardScreenState();
}

class _WizardScreenState extends State<WizardScreen> {
  static const _primary = Color(0xFF0f766e);
  final _api = ApiService();

  int _currentStep = 1;
  double _progress = 0.25;

  // Step 1 Data (Financial)
  final _penghasilanC = TextEditingController(text: '10000000');
  final _dpC = TextEditingController(text: '50000000');
  final _cicilanC = TextEditingController(text: '0');
  int _tenor = 15;
  int _maxBudget = 0;

  // Step 2 Data (Criteria)
  String? _selectedLokasi;
  List<String> _lokasiList = [];
  double _wHarga = 3;
  double _wTanah = 3;
  double _wBangunan = 3;
  double _wKamar = 3;

  // Step 3/4 Results
  bool _isAnalyzing = false;
  List<Rumah> _recommendations = [];

  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadLokasi();
    _calculateBudget();
  }

  void _loadLokasi() async {
    final list = await _api.getLokasi();
    if (mounted) setState(() => _lokasiList = list);
  }

  void _calculateBudget() {
    final income = int.tryParse(_penghasilanC.text) ?? 0;
    final dp = int.tryParse(_dpC.text) ?? 0;
    final cicilan = int.tryParse(_cicilanC.text) ?? 0;

    final maxCicilan = (income * 0.3) - cicilan;
    if (maxCicilan <= 0) {
      setState(() => _maxBudget = 0);
      return;
    }

    const bungaBulanan = 0.08 / 12;
    final jumlahBulan = _tenor * 12;
    final pokokPinjaman = maxCicilan * ((1 - pow(1 + bungaBulanan, -jumlahBulan)) / bungaBulanan);
    
    setState(() => _maxBudget = (pokokPinjaman + dp).round());
  }

  void _nextStep() {
    if (_currentStep == 1 && _maxBudget <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Budget Anda tidak mencukupi untuk KPR.')),
      );
      return;
    }
    
    if (_currentStep == 2) {
      _runAnalysis();
      return;
    }

    setState(() {
      _currentStep++;
      _progress = _currentStep / 4;
    });
  }

  void _runAnalysis() async {
    setState(() {
      _currentStep = 3;
      _progress = 0.75;
      _isAnalyzing = true;
    });

    // Simulate analysis delay for UX
    await Future.delayed(const Duration(seconds: 2));

    final results = await _api.recommend(
      lokasi: _selectedLokasi,
      budgetMax: _maxBudget,
      wHarga: _wHarga.toInt(),
      wTanah: _wTanah.toInt(),
      wBangunan: _wBangunan.toInt(),
      wKamar: _wKamar.toInt(),
    );

    if (mounted) {
      setState(() {
        _recommendations = results;
        _isAnalyzing = false;
        _currentStep = 4;
        _progress = 1.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Temukan Rumah Impian'),
        backgroundColor: _primary,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildProgressBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildStepContent(),
            ),
          ),
          if (_currentStep < 3) _buildBottomNavbar(),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        LinearProgressIndicator(
          value: _progress,
          backgroundColor: Colors.grey.shade200,
          color: _primary,
          minHeight: 6,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _stepText('1. Finansial', _currentStep >= 1),
            _stepText('2. Kriteria', _currentStep >= 2),
            _stepText('3. Analisis', _currentStep >= 3),
            _stepText('4. Hasil', _currentStep >= 4),
          ],
        ),
      ],
    );
  }

  Widget _stepText(String label, bool active) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: active ? _primary : Colors.grey,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildStepContent() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0.1, 0), end: Offset.zero).animate(animation),
          child: child,
        ));
      },
      child: Container(
        key: ValueKey<int>(_currentStep),
        child: _buildStepInner(),
      ),
    );
  }

  Widget _buildStepInner() {
    switch (_currentStep) {
      case 1: return _step1Finansial();
      case 2: return _step2Kriteria();
      case 3: return _step3Analisis();
      case 4: return _step4Hasil();
      default: return const SizedBox();
    }
  }

  // STEP 1: FINANSIAL
  Widget _step1Finansial() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Profil Kemampuan Keuangan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Masukkan data Anda untuk mendapatkan batas budget rumah yang realistis.', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 24),

        _inputField('Penghasilan Bulanan', _penghasilanC, Icons.account_balance_wallet_outlined),
        const SizedBox(height: 16),
        _inputField('Uang Muka (DP) Tersedia', _dpC, Icons.payments_outlined),
        const SizedBox(height: 16),
        _inputField('Cicilan Aktif Lainnya', _cicilanC, Icons.credit_card_outlined),
        const SizedBox(height: 16),
        
        const Text('Tenor KPR (Tahun)', style: TextStyle(fontWeight: FontWeight.bold)),
        Slider(
          value: _tenor.toDouble(),
          min: 5, max: 20,
          divisions: 3,
          label: '$_tenor Tahun',
          activeColor: _primary,
          onChanged: (v) => setState(() { _tenor = v.toInt(); _calculateBudget(); }),
        ),

        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _primary.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              const Text('Estimasi Maksimal Budget Rumah', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _primary)),
              const SizedBox(height: 4),
              Text(
                _maxBudget > 0 ? currencyFormatter.format(_maxBudget) : 'Tidak Mencukupi',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: _primary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // STEP 2: KRITERIA
  Widget _step2Kriteria() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Kriteria Rumah Impian', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Tentukan lokasi dan seberapa penting kriteria berikut bagi Anda.', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 24),

        DropdownButtonFormField<String>(
          value: _selectedLokasi,
          decoration: _inputDecor('Pilih Lokasi', Icons.location_on_outlined),
          items: [
            const DropdownMenuItem(value: null, child: Text('Semua Lokasi')),
            ..._lokasiList.map((l) => DropdownMenuItem(value: l, child: Text(l))),
          ],
          onChanged: (v) => setState(() => _selectedLokasi = v),
        ),
        const SizedBox(height: 24),

        _sliderRow('Harga Murah', _wHarga, (v) => setState(() => _wHarga = v)),
        _sliderRow('Luas Tanah', _wTanah, (v) => setState(() => _wTanah = v)),
        _sliderRow('Luas Bangunan', _wBangunan, (v) => setState(() => _wBangunan = v)),
        _sliderRow('Jumlah Kamar', _wKamar, (v) => setState(() => _wKamar = v)),
      ],
    );
  }

  // STEP 3: ANALISIS
  Widget _step3Analisis() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            const SizedBox(
              width: 80, height: 80,
              child: CircularProgressIndicator(strokeWidth: 8, color: _primary),
            ),
            const SizedBox(height: 32),
            const Text('Sedang Menganalisis...', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Sistem sedang mencocokkan profil Anda dengan ${_recommendations.isEmpty ? 'data' : _recommendations.length} properti terbaik.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // STEP 4: HASIL
  Widget _step4Hasil() {
    if (_recommendations.isEmpty) {
      return Center(
        child: Column(
          children: [
            const Icon(Icons.sentiment_dissatisfied, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Maaf, Tidak Ada Hasil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Tidak ada rumah yang sesuai dengan budget Anda di lokasi ini.', textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => setState(() => _currentStep = 1),
              style: ElevatedButton.styleFrom(backgroundColor: _primary),
              child: const Text('Hitung Ulang'),
            )
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ditemukan ${_recommendations.length} Rekomendasi',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const Text('Berikut adalah properti yang paling sesuai dengan profil Anda.', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 20),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _recommendations.length,
          itemBuilder: (context, index) {
            final r = _recommendations[index];
            return _buildHouseCard(r, index + 1);
          },
        ),
      ],
    );
  }

  Widget _buildHouseCard(Rumah r, int rank) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            color: rank == 1 ? Colors.amber : _primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              rank == 1 ? '🥇' : '#$rank',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: rank == 1 ? Colors.white : _primary,
              ),
            ),
          ),
        ),
        title: Text(r.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${r.lokasi} • ${currencyFormatter.format(r.harga)}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => DetailRumahScreen(rumahId: r.id, namaRumah: r.nama),
        )),
      ),
    );
  }

  // Common UI helpers
  Widget _inputField(String label, TextEditingController controller, IconData icon) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: _inputDecor(label, icon),
      onChanged: (_) => _calculateBudget(),
    );
  }

  InputDecoration _inputDecor(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _primary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      isDense: true,
    );
  }

  Widget _sliderRow(String label, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MediaQuery.of(context).size.width > 300 ? MainAxisAlignment.spaceBetween : MainAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text('${value.toInt()}', style: const TextStyle(color: _primary, fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: value,
          min: 1, max: 5,
          divisions: 4,
          activeColor: _primary,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildBottomNavbar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: ElevatedButton(
        onPressed: _nextStep,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(_currentStep == 2 ? 'Mulai Analisis' : 'Lanjutkan'),
      ),
    );
  }
}
