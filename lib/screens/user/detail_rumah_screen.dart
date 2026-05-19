import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../providers/rumah_provider.dart';
import '../../models/rumah.dart';
import 'package:url_launcher/url_launcher.dart';
import 'kalkulator_screen.dart';

class DetailRumahScreen extends StatefulWidget {
  final String rumahId;
  final String namaRumah;

  const DetailRumahScreen({
    super.key,
    required this.rumahId,
    required this.namaRumah,
  });

  @override
  State<DetailRumahScreen> createState() => _DetailRumahScreenState();
}

class _DetailRumahScreenState extends State<DetailRumahScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<RumahProvider>().fetchRumahDetail(widget.rumahId);
    });
  }

  String _formatHarga(int harga) {
    if (harga >= 1000000000) {
      return 'Rp ${(harga / 1000000000).toStringAsFixed(2)} Milyar';
    } else if (harga >= 1000000) {
      return 'Rp ${(harga / 1000000).toStringAsFixed(0)} Juta';
    }
    return 'Rp ${harga.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RumahProvider>();
    final isLoading = provider.isLoading;
    final rumah = provider.selectedRumah; // Assuming we use selectedRumah state

    // If still loading or the detail is not fetched yet
    if (isLoading || rumah == null || rumah.id != widget.rumahId) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.namaRumah),
          backgroundColor: const Color(0xFF0f766e),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF0f766e)),
        ),
      );
    }

    final bool isFavorit = rumah.isFavorit ?? false;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Header Image
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: const Color(0xFF0f766e),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  rumah.foto != null
                      ? Image.network(
                          rumah.foto!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholder(),
                        )
                      : _buildPlaceholder(),
                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.4),
                          Colors.transparent,
                          Colors.black.withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  isFavorit ? Icons.favorite : Icons.favorite_border,
                  color: isFavorit ? Colors.red : Colors.white,
                  size: 28,
                ),
                onPressed: () async {
                  final bool success = await provider.toggleFavorit(rumah.id);
                  if (success) {
                    // Update current detail specifically to reflect UI immediately
                    await provider.fetchRumahDetail(rumah.id);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            (!isFavorit)
                                ? 'Ditambahkan ke favorit'
                                : 'Dihapus dari favorit',
                          ),
                          duration: const Duration(seconds: 2),
                          backgroundColor:
                              (!isFavorit) ? Colors.green : Colors.grey[700],
                        ),
                      );
                    }
                  }
                },
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0f766e).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                rumah.tipe.toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xFF0f766e),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              rumah.nama,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1a1a1a),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        _formatHarga(rumah.harga),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0f766e),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFF0f766e), size: 20),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          rumah.lokasi,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          final query = Uri.encodeComponent('${rumah.nama} ${rumah.lokasi}');
                          final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          }
                        },
                        icon: const Icon(Icons.map_outlined, size: 16),
                        label: const Text('Buka Peta', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF0f766e),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          backgroundColor: const Color(0xFF0f766e).withOpacity(0.05),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 20),

                  // Key Specs
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSpecItem(
                        icon: Icons.bed_outlined,
                        label: 'Kamar',
                        value: '${rumah.kamarTidur}',
                      ),
                      _buildSpecItem(
                        icon: Icons.bathroom_outlined,
                        label: 'K. Mandi',
                        value: '${rumah.kamarMandi}',
                      ),
                      _buildSpecItem(
                        icon: Icons.straighten_outlined,
                        label: 'L. Bangunan',
                        value: '${rumah.luasBangunan}m²',
                      ),
                      _buildSpecItem(
                        icon: Icons.landscape_outlined,
                        label: 'L. Tanah',
                        value: '${rumah.luasTanah}m²',
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 20),

                  // Deskripsi
                  const Text(
                    'Deskripsi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    rumah.deskripsi ?? 'Tidak ada deskripsi tersedia.',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[800],
                      height: 1.5,
                    ),
                  ),

                  // Peta Lokasi
                  if (rumah.latitude != null && rumah.longitude != null) ...[
                    const Text(
                      'Lokasi di Peta',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        height: 220,
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(rumah.latitude!, rumah.longitude!),
                            initialZoom: 15,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.app',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(rumah.latitude!, rumah.longitude!),
                                  child: const Icon(
                                    Icons.location_pin,
                                    color: Colors.red,
                                    size: 40,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  const SizedBox(height: 24),

                  // Fasilitas
                  if (rumah.fasilitas != null && rumah.fasilitas!.isNotEmpty) ...[
                    const Text(
                      'Fasilitas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: rumah.fasilitas!.map((f) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle,
                                size: 16,
                                color: Color(0xFF0f766e),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                f.nama,
                                style: TextStyle(
                                  color: Colors.grey[800],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 100), // spacing for bottom nav
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => KalkulatorScreen(
                        initialHargaRumah: rumah.harga,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0f766e),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calculate_outlined),
                    SizedBox(width: 8),
                    Text(
                      'Simulasi KPR',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFF134e4a),
      child: const Center(
        child: Icon(
          Icons.home_work_outlined,
          size: 80,
          color: Colors.white54,
        ),
      ),
    );
  }

  Widget _buildSpecItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0f766e).withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF0f766e), size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

