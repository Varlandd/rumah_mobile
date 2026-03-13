import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/rumah_provider.dart';
import '../../models/rumah.dart';
import 'detail_rumah_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _budgetMinController = TextEditingController();
  final _budgetMaxController = TextEditingController();
  String? _selectedLokasi;
  String? _selectedTipe;

  final List<String> _tipeList = ['Baru', 'Tanah', 'Sewa', 'Subsidi', 'Lelang'];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<RumahProvider>().fetchLokasi();
    });
  }

  @override
  void dispose() {
    _budgetMinController.dispose();
    _budgetMaxController.dispose();
    super.dispose();
  }

  void _doSearch() {
    final budgetMin = int.tryParse(_budgetMinController.text.replaceAll(RegExp(r'[^0-9]'), ''));
    final budgetMax = int.tryParse(_budgetMaxController.text.replaceAll(RegExp(r'[^0-9]'), ''));

    context.read<RumahProvider>().searchRumah(
          lokasi: _selectedLokasi,
          budgetMin: budgetMin,
          budgetMax: budgetMax,
          tipe: _selectedTipe,
        );
  }

  String _formatHarga(int harga) {
    if (harga >= 1000000000) {
      return 'Rp ${(harga / 1000000000).toStringAsFixed(1)} M';
    } else if (harga >= 1000000) {
      return 'Rp ${(harga / 1000000).toStringAsFixed(0)} Jt';
    }
    return 'Rp $harga';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RumahProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Cari Properti'),
        backgroundColor: const Color(0xFF0f766e),
      ),
      body: Column(
        children: [
          // Filter Form
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdownLabel(
                        label: 'Lokasi',
                        value: _selectedLokasi,
                        items: provider.lokasiList,
                        onChanged: (val) => setState(() => _selectedLokasi = val),
                        hint: 'Semua Lokasi',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDropdownLabel(
                        label: 'Tipe',
                        value: _selectedTipe,
                        items: _tipeList,
                        onChanged: (val) => setState(() => _selectedTipe = val),
                        hint: 'Semua Tipe',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildPriceInput(
                        label: 'Budget Min',
                        controller: _budgetMinController,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 20),
                      child: Text('-', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      child: _buildPriceInput(
                        label: 'Budget Max',
                        controller: _budgetMaxController,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton.icon(
                    onPressed: _doSearch,
                    icon: const Icon(Icons.search),
                    label: const Text(
                      'Terapkan Filter',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0f766e),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Results
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF0f766e)))
                : provider.searchResults.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'Gunakan filter di atas\nuntuk mencari rumah',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.searchResults.length,
                        itemBuilder: (context, index) {
                          final rumah = provider.searchResults[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DetailRumahScreen(
                                      rumahId: rumah.id,
                                      namaRumah: rumah.nama,
                                    ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: rumah.foto != null
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.network(
                                                rumah.foto!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    const Icon(Icons.home_outlined),
                                              ),
                                            )
                                          : const Icon(Icons.home_outlined),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            rumah.nama,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            rumah.lokasi,
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _formatHarga(rumah.harga),
                                            style: const TextStyle(
                                              color: Color(0xFF0f766e),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              _chip(Icons.bed_outlined, '${rumah.kamarTidur}'),
                                              const SizedBox(width: 8),
                                              _chip(Icons.bathroom_outlined, '${rumah.kamarMandi}'),
                                              const SizedBox(width: 8),
                                              _chip(Icons.straighten_outlined, '${rumah.luasBangunan}m²'),
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownLabel({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              hint: Text(hint, style: const TextStyle(fontSize: 14)),
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF0f766e)),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Semua', style: TextStyle(fontSize: 14)),
                ),
                ...items.map(
                  (i) => DropdownMenuItem(
                    value: i,
                    child: Text(i, style: const TextStyle(fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceInput({
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 40,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              prefixText: 'Rp ',
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF0f766e)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _chip(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 12, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
