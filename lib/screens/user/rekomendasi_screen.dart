import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/rumah_provider.dart';
import '../../models/rumah.dart';
import 'detail_rumah_screen.dart';

class RekomendasiScreen extends StatefulWidget {
  const RekomendasiScreen({super.key});

  @override
  State<RekomendasiScreen> createState() => _RekomendasiScreenState();
}

class _RekomendasiScreenState extends State<RekomendasiScreen> {
  static const _primary = Color(0xFF0f766e);

  double _wHarga = 3;
  double _wTanah = 3;
  double _wBangunan = 3;
  double _wKT = 3;
  double _wKM = 2;

  String? _filterLokasi;
  final _budgetC = TextEditingController();

  List<_RankedRumah>? _results;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<RumahProvider>().fetchRumah());
  }

  @override
  void dispose() {
    _budgetC.dispose();
    super.dispose();
  }

  void _calculate() {
    final allRumah = context.read<RumahProvider>().rumahList;
    if (allRumah.isEmpty) return;

    // Filter
    var data = List<Rumah>.from(allRumah);
    if (_filterLokasi != null && _filterLokasi!.isNotEmpty) {
      data = data.where((r) => r.lokasi == _filterLokasi).toList();
    }
    final budget = int.tryParse(_budgetC.text) ?? 0;
    if (budget > 0) {
      data = data.where((r) => r.harga <= budget).toList();
    }

    if (data.isEmpty) {
      setState(() => _results = []);
      return;
    }

    // Normalize weights
    final totalW = _wHarga + _wTanah + _wBangunan + _wKT + _wKM;
    final nwH = _wHarga / totalW;
    final nwT = _wTanah / totalW;
    final nwB = _wBangunan / totalW;
    final nwKT = _wKT / totalW;
    final nwKM = _wKM / totalW;

    // Find min/max for normalization
    final minHarga = data.map((r) => r.harga).reduce(min);
    final maxTanah = data.map((r) => r.luasTanah).reduce(max);
    final maxBangunan = data.map((r) => r.luasBangunan).reduce(max);
    final maxKT = data.map((r) => r.kamarTidur).reduce(max);
    final maxKM = data.map((r) => r.kamarMandi).reduce(max);

    // Calculate SAW score
    final ranked = data.map((r) {
      final nHarga = (minHarga > 0 && r.harga > 0) ? minHarga / r.harga : 0.0;
      final nTanah = maxTanah > 0 ? r.luasTanah / maxTanah : 0.0;
      final nBangunan = maxBangunan > 0 ? r.luasBangunan / maxBangunan : 0.0;
      final nKT2 = maxKT > 0 ? r.kamarTidur / maxKT : 0.0;
      final nKM2 = maxKM > 0 ? r.kamarMandi / maxKM : 0.0;

      final score = (nwH * nHarga) + (nwT * nTanah) + (nwB * nBangunan) + (nwKT * nKT2) + (nwKM * nKM2);
      return _RankedRumah(rumah: r, score: score);
    }).toList();

    ranked.sort((a, b) => b.score.compareTo(a.score));

    setState(() => _results = ranked);
  }

  String _formatHarga(int harga) {
    if (harga >= 1000000000) return 'Rp ${(harga / 1000000000).toStringAsFixed(1)}M';
    if (harga >= 1000000) return 'Rp ${(harga / 1000000).toStringAsFixed(0)}Jt';
    return 'Rp $harga';
  }

  @override
  Widget build(BuildContext context) {
    final rumahProvider = context.watch<RumahProvider>();
    final lokasiSet = rumahProvider.rumahList.map((r) => r.lokasi).toSet().toList()..sort();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(title: const Text('Rekomendasi'), backgroundColor: _primary),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF0f766e), Color(0xFF0d9488)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Icon(Icons.stars_rounded, size: 40, color: Colors.white),
                  SizedBox(height: 8),
                  Text('Rekomendasi Personal', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Atur prioritas dan dapatkan ranking terbaik', style: TextStyle(color: Colors.white70, fontSize: 13), textAlign: TextAlign.center),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Weights Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.tune, color: _primary, size: 20),
                        SizedBox(width: 8),
                        Text('Prioritas Kriteria', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Geser slider (1=rendah, 5=sangat penting)', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    const SizedBox(height: 16),

                    _sliderRow('💰 Harga Terjangkau', _wHarga, (v) => setState(() => _wHarga = v)),
                    _sliderRow('📐 Luas Tanah', _wTanah, (v) => setState(() => _wTanah = v)),
                    _sliderRow('🏗️ Luas Bangunan', _wBangunan, (v) => setState(() => _wBangunan = v)),
                    _sliderRow('🛏️ Kamar Tidur', _wKT, (v) => setState(() => _wKT = v)),
                    _sliderRow('🚿 Kamar Mandi', _wKM, (v) => setState(() => _wKM = v)),

                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),

                    // Filters
                    DropdownButtonFormField<String>(
                      value: _filterLokasi,
                      decoration: InputDecoration(
                        labelText: 'Filter Lokasi (Opsional)',
                        prefixIcon: const Icon(Icons.location_on_outlined, size: 20, color: _primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      items: [
                        const DropdownMenuItem(value: '', child: Text('Semua Lokasi')),
                        ...lokasiSet.map((l) => DropdownMenuItem(value: l, child: Text(l))),
                      ],
                      onChanged: (v) => setState(() => _filterLokasi = v),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _budgetC,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Budget Maks (Opsional)',
                        prefixIcon: const Icon(Icons.attach_money, size: 20, color: _primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 20),

                    ElevatedButton.icon(
                      onPressed: rumahProvider.isLoading ? null : _calculate,
                      icon: const Icon(Icons.stars_rounded),
                      label: const Text('Dapatkan Rekomendasi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Results
            if (_results != null) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: _primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Text('Metode SAW', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _primary)),
                  ),
                  const Spacer(),
                  Text('${_results!.length} properti', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
              const SizedBox(height: 12),

              if (_results!.isEmpty)
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: const Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.search_off, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Tidak ada properti cocok', style: TextStyle(fontWeight: FontWeight.w600)),
                        Text('Coba ubah filter', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  ),
                )
              else
                ..._results!.asMap().entries.map((entry) {
                  final rank = entry.key + 1;
                  final item = entry.value;
                  return _rankCard(rank, item);
                }),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sliderRow(String label, double value, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Slider(
              value: value,
              min: 1, max: 5,
              divisions: 4,
              activeColor: _primary,
              onChanged: onChanged,
            ),
          ),
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(color: _primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text('${value.toInt()}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _primary))),
          ),
        ],
      ),
    );
  }

  Widget _rankCard(int rank, _RankedRumah item) {
    final medal = rank == 1 ? '🥇' : rank == 2 ? '🥈' : rank == 3 ? '🥉' : '#$rank';
    final MaterialColor badgeColor = rank == 1
        ? Colors.amber
        : rank == 2
            ? Colors.blueGrey
            : rank == 3
                ? Colors.brown
                : Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: rank == 1 ? const BorderSide(color: _primary, width: 2) : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => DetailRumahScreen(rumahId: item.rumah.id, namaRumah: item.rumah.nama),
        )),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
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

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.rumah.nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      '${item.rumah.lokasi} · ${item.rumah.luasTanah}m² · ${item.rumah.kamarTidur}KT · ${_formatHarga(item.rumah.harga)}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Score
              Column(
                children: [
                  Text(
                    (item.score * 100).toStringAsFixed(1),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _primary),
                  ),
                  Text('Skor', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RankedRumah {
  final Rumah rumah;
  final double score;
  _RankedRumah({required this.rumah, required this.score});
}
