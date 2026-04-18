import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/rumah_provider.dart';
import '../../models/rumah.dart';
import 'detail_rumah_screen.dart';

class BandingkanScreen extends StatefulWidget {
  const BandingkanScreen({super.key});

  @override
  State<BandingkanScreen> createState() => _BandingkanScreenState();
}

class _BandingkanScreenState extends State<BandingkanScreen> {
  static const _primary = Color(0xFF0f766e);

  final List<Rumah?> _selected = [null, null, null];
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<RumahProvider>().fetchRumah());
  }

  String _formatHarga(int harga) {
    if (harga >= 1000000000) return 'Rp ${(harga / 1000000000).toStringAsFixed(2)}M';
    if (harga >= 1000000) return 'Rp ${(harga / 1000000).toStringAsFixed(0)}Jt';
    return 'Rp $harga';
  }

  void _compare() {
    final count = _selected.where((s) => s != null).length;
    if (count < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal 2 properti'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _showResults = true);
  }

  @override
  Widget build(BuildContext context) {
    final rumahProvider = context.watch<RumahProvider>();
    final rumahList = rumahProvider.rumahList;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(title: const Text('Bandingkan'), backgroundColor: _primary),
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
                  Icon(Icons.compare_arrows_rounded, size: 40, color: Colors.white),
                  SizedBox(height: 8),
                  Text('Bandingkan Properti', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Pilih hingga 3 properti untuk perbandingan', style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Selectors
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pilih Properti', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),

                    for (int i = 0; i < 3; i++) ...[
                      _selectorRow(i, rumahList),
                      if (i < 2) const SizedBox(height: 12),
                    ],

                    const SizedBox(height: 20),

                    ElevatedButton.icon(
                      onPressed: _compare,
                      icon: const Icon(Icons.compare_arrows),
                      label: const Text('Bandingkan'),
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
            if (_showResults) ...[
              const SizedBox(height: 20),
              _buildComparisonTable(),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _selectorRow(int index, List<Rumah> rumahList) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: _selected[index] != null ? _primary : Colors.grey.shade300, width: _selected[index] != null ? 2 : 1),
        borderRadius: BorderRadius.circular(12),
        color: _selected[index] != null ? _primary.withOpacity(0.04) : null,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selected[index]?.id.toString(),
          isExpanded: true,
          hint: Text('Properti ${index + 1}', style: TextStyle(color: Colors.grey.shade500)),
          items: [
            DropdownMenuItem(value: '', child: Text('— Kosongkan —', style: TextStyle(color: Colors.grey.shade400))),
            ...rumahList.map((r) => DropdownMenuItem(
              value: r.id.toString(),
              child: Text('${r.nama} (${r.lokasi})', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
            )),
          ],
          onChanged: (v) {
            setState(() {
              if (v == null || v.isEmpty) {
                _selected[index] = null;
              } else {
                final id = int.parse(v);
                _selected[index] = rumahList.firstWhere((r) => r.id == id);
              }
              _showResults = false;
            });
          },
        ),
      ),
    );
  }

  Widget _buildComparisonTable() {
    final items = _selected.where((s) => s != null).toList().cast<Rumah>();
    if (items.length < 2) return const SizedBox();

    final criteria = <_CompareRow>[
      _CompareRow('Lokasi', items.map((r) => r.lokasi).toList()),
      _CompareRow('Tipe', items.map((r) => r.tipe).toList()),
      _CompareRow('Harga', items.map((r) => _formatHarga(r.harga)).toList(),
        numValues: items.map((r) => r.harga.toDouble()).toList(), best: 'min'),
      _CompareRow('Luas Tanah', items.map((r) => '${r.luasTanah} m²').toList(),
        numValues: items.map((r) => r.luasTanah.toDouble()).toList(), best: 'max'),
      _CompareRow('Luas Bangunan', items.map((r) => '${r.luasBangunan} m²').toList(),
        numValues: items.map((r) => r.luasBangunan.toDouble()).toList(), best: 'max'),
      _CompareRow('Kamar Tidur', items.map((r) => '${r.kamarTidur} KT').toList(),
        numValues: items.map((r) => r.kamarTidur.toDouble()).toList(), best: 'max'),
      _CompareRow('Kamar Mandi', items.map((r) => '${r.kamarMandi} KM').toList(),
        numValues: items.map((r) => r.kamarMandi.toDouble()).toList(), best: 'max'),
      _CompareRow('Harga/m²', items.map((r) => r.luasTanah > 0 ? _formatHarga((r.harga / r.luasTanah).round()) : '-').toList(),
        numValues: items.map((r) => r.luasTanah > 0 ? r.harga / r.luasTanah : 0.0).toList(), best: 'min'),
    ];

    // Calculate scores
    final minH = items.map((r) => r.harga).reduce(min).toDouble();
    final maxLT = items.map((r) => r.luasTanah).reduce(max).toDouble();
    final maxLB = items.map((r) => r.luasBangunan).reduce(max).toDouble();
    final maxKT = items.map((r) => r.kamarTidur).reduce(max).toDouble();
    final maxKM = items.map((r) => r.kamarMandi).reduce(max).toDouble();

    final scores = items.map((r) {
      return (0.30 * (minH / r.harga)) +
          (0.20 * (maxLT > 0 ? r.luasTanah / maxLT : 0)) +
          (0.20 * (maxLB > 0 ? r.luasBangunan / maxLB : 0)) +
          (0.15 * (maxKT > 0 ? r.kamarTidur / maxKT : 0)) +
          (0.15 * (maxKM > 0 ? r.kamarMandi / maxKM : 0));
    }).toList();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header row
          Container(
            color: _primary.withOpacity(0.05),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                const SizedBox(width: 90, child: Text('Kriteria', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.grey))),
                ...items.map((r) => Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => DetailRumahScreen(rumahId: r.id, namaRumah: r.nama),
                    )),
                    child: Text(r.nama, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: _primary),
                      textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
                )),
              ],
            ),
          ),

          // Data rows
          ...criteria.map((row) => _dataRow(row)),

          // Score row
          Container(
            color: _primary.withOpacity(0.1),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Row(
              children: [
                const SizedBox(width: 90, child: Text('🏆 Hasil Akhir', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: _primary))),
                ...scores.asMap().entries.map((entry) {
                  final i = entry.key;
                  final s = entry.value;
                  final isWinner = s == scores.reduce(max);
                  final pct = (s * 100).round();
                  
                  return Expanded(
                    child: Column(
                      children: [
                        if (isWinner) const Icon(Icons.workspace_premium, color: Colors.amber, size: 24),
                        Text('$pct', style: TextStyle(
                          fontSize: 22, 
                          fontWeight: FontWeight.w900, 
                          color: isWinner ? Colors.amber.shade700 : _primary
                        )),
                        const SizedBox(height: 4),
                        Text(isWinner ? 'REKOMENDASI' : 'SKOR', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dataRow(_CompareRow row) {
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(row.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
          ),
          ...row.values.asMap().entries.map((entry) {
            final i = entry.key;
            Color? bg;
            Color textColor = Colors.black87;

            if (row.numValues != null && row.best != null && row.numValues!.where((v) => v > 0).length >= 2) {
              final positiveVals = row.numValues!.where((v) => v > 0).toList();
              final bestVal = row.best == 'max' ? positiveVals.reduce(max) : positiveVals.reduce(min);
              final worstVal = row.best == 'max' ? positiveVals.reduce(min) : positiveVals.reduce(max);

              if (row.numValues![i] == bestVal && bestVal != worstVal) {
                bg = Colors.green.shade50;
                textColor = Colors.green.shade800;
              } else if (row.numValues![i] == worstVal && bestVal != worstVal) {
                bg = Colors.red.shade50;
                textColor = Colors.red.shade700;
              }
            }

            return Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                decoration: bg != null ? BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)) : null,
                child: Text(
                  entry.value,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textColor),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _CompareRow {
  final String label;
  final List<String> values;
  final List<double>? numValues;
  final String? best; // 'min' or 'max'

  _CompareRow(this.label, this.values, {this.numValues, this.best});
}
