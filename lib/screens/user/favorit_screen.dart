import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/rumah_provider.dart';
import '../../models/rumah.dart';
import 'detail_rumah_screen.dart';

class FavoritScreen extends StatefulWidget {
  const FavoritScreen({super.key});

  @override
  State<FavoritScreen> createState() => _FavoritScreenState();
}

class _FavoritScreenState extends State<FavoritScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<RumahProvider>().fetchFavorit());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RumahProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Favorit Saya'),
        backgroundColor: const Color(0xFF0f766e),
      ),
      body: _buildBody(provider),
    );
  }

  Widget _buildBody(RumahProvider provider) {
    if (provider.isLoading && provider.favoritList.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF0f766e)),
      );
    }

    if (provider.favoritList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Belum ada properti favorit',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tekan ikon hati pada detail properti\nuntuk menyimpannya di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.fetchFavorit(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.favoritList.length,
        itemBuilder: (context, index) {
          final rumah = provider.favoritList[index];
          return _FavoritCard(rumah: rumah, provider: provider);
        },
      ),
    );
  }
}

class _FavoritCard extends StatelessWidget {
  final Rumah rumah;
  final RumahProvider provider;

  const _FavoritCard({required this.rumah, required this.provider});

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
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailRumahScreen(
                rumahId: rumah.id,
                namaRumah: rumah.nama,
              ),
            ),
          );
          // Refresh favorites when returning in case it was unfavorited
          provider.fetchFavorit();
        },
        borderRadius: BorderRadius.circular(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Header with absolute favorite button
              Stack(
                children: [
                   Container(
                    height: 180,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: rumah.foto != null
                        ? Image.network(
                            rumah.foto!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.home_outlined, size: 60, color: Colors.grey),
                          )
                        : const Icon(Icons.home_outlined, size: 60, color: Colors.grey),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      elevation: 2,
                      child: IconButton(
                        icon: const Icon(Icons.favorite, color: Colors.red, size: 24),
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        padding: EdgeInsets.zero,
                        onPressed: () async {
                          // Remove from favorite
                          final success = await provider.toggleFavorit(rumah.id);
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Dihapus dari favorit'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                  Positioned(
                     bottom: 12,
                     left: 12,
                     child: Container(
                       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                       decoration: BoxDecoration(
                         color: const Color(0xFF0f766e),
                         borderRadius: BorderRadius.circular(6),
                       ),
                       child: Text(
                         rumah.tipe.toUpperCase(),
                         style: const TextStyle(
                           color: Colors.white,
                           fontSize: 12,
                           fontWeight: FontWeight.bold,
                         ),
                       ),
                     )
                  )
                ],
              ),
              
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            rumah.nama,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatHarga(rumah.harga),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0f766e),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            rumah.lokasi,
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildFeature(Icons.bed_outlined, '${rumah.kamarTidur}'),
                        const SizedBox(width: 16),
                        _buildFeature(Icons.bathroom_outlined, '${rumah.kamarMandi}'),
                        const SizedBox(width: 16),
                        _buildFeature(Icons.straighten_outlined, '${rumah.luasBangunan}m²'),
                        const SizedBox(width: 16),
                        _buildFeature(Icons.landscape_outlined, '${rumah.luasTanah}m²'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeature(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
