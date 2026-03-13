import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';

class AdminStatsScreen extends StatefulWidget {
  const AdminStatsScreen({super.key});

  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => context.read<AdminProvider>().fetchDashboardStats(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final stats = admin.dashboardStats;

    return Scaffold(
      backgroundColor: const Color(0xFF1E293B), // Dark theme
      appBar: AppBar(
        title: const Text('Dashboard Statistik'),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
      ),
      body: admin.isLoading && stats == null
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : RefreshIndicator(
              onRefresh: () => admin.fetchDashboardStats(),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (stats != null) ...[
                    // Grid summary
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.25,
                      children: [
                        _StatCard(
                          title: 'Total Rumah',
                          value: stats['total_rumah'].toString(),
                          icon: Icons.home_rounded,
                          color: Colors.blueAccent,
                        ),
                        _StatCard(
                          title: 'Total Pengguna',
                          value: stats['total_user'].toString(),
                          icon: Icons.people_alt,
                          color: Colors.orangeAccent,
                        ),
                        _StatCard(
                          title: 'Total Favorit',
                          value: stats['total_favorit'].toString(),
                          icon: Icons.favorite,
                          color: Colors.pinkAccent,
                        ),
                        _StatCard(
                          title: 'Upload Baru',
                          value: (stats['recent_rumah'] as List?)?.length.toString() ?? '0',
                          icon: Icons.upload_file,
                          color: Colors.greenAccent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Recent list
                    const Text(
                      'Properti Terbaru',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    if (stats['recent_rumah'] == null || (stats['recent_rumah'] as List).isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Belum ada properti',
                            style: TextStyle(color: Colors.white.withOpacity(0.5)),
                          ),
                        ),
                      )
                    else
                      ...List.generate(
                        (stats['recent_rumah'] as List).length,
                        (index) {
                          final r = stats['recent_rumah'][index];
                          return Card(
                            color: const Color(0xFF334155),
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.black26,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: r['foto'] != null 
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        'http://192.168.1.22:8000/${r['foto']}', // temporary hardcoded based on url
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Icon(Icons.home, color: Colors.white54),
                                      )
                                    )
                                  : const Icon(Icons.image_not_supported, color: Colors.white54),
                              ),
                              title: Text(
                                r['nama'],
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                r['lokasi'],
                                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Text(
                                'Rp ${(r['harga'] / 1000000).toStringAsFixed(0)} Jt',
                                style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
                              ),
                            ),
                          );
                        },
                      ),
                  ] else ...[
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'Data tidak tersedia.\nTarik ke bawah untuk memuat ulang.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF334155),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 28),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
