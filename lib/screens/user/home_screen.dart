import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/rumah_provider.dart';
import '../../models/rumah.dart';
import '../login_screen.dart';
import 'detail_rumah_screen.dart';
import 'search_screen.dart';
import 'favorit_screen.dart';
import 'profile_edit_screen.dart';
import 'kalkulator_screen.dart';
import 'prediksi_screen.dart';
import 'rekomendasi_screen.dart';
import 'bandingkan_screen.dart';
import '../../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load data rumah saat pertama kali buka
    Future.microtask(() {
      context.read<RumahProvider>().fetchRumah();
    });
  }

  void _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Yakin ingin keluar dari akun?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final List<Widget> pages = [
      _buildBeranda(auth),
      const SearchScreen(),
      const FavoritScreen(),
      _buildProfil(auth),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Cari',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favorit',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _buildBeranda(AuthProvider auth) {
    final rumahProvider = context.watch<RumahProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.home_rounded, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text('RumahKu'),
          ],
        ),
        backgroundColor: const Color(0xFF0f766e),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Keluar',
            onPressed: _logout,
          ),
        ],
      ),
      body: RefreshIndicator(
      onRefresh: () => rumahProvider.fetchRumah(),
      child: CustomScrollView(
        slivers: [
          // Greeting Banner
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),

              decoration: const BoxDecoration(
                color: Color(0xFF0f766e),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Halo, ${auth.user?.name ?? 'Pengguna'} 👋',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Temukan rumah impianmu hari ini',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ── Quick Actions ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fitur Utama',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1a1a1a)),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.85,
                    children: [
                      _quickAction(
                        icon: Icons.auto_graph_rounded,
                        label: 'Prediksi\nHarga',
                        color: const Color(0xFF6366f1),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrediksiScreen())),
                      ),
                      _quickAction(
                        icon: Icons.stars_rounded,
                        label: 'Rekomen-\ndasi',
                        color: const Color(0xFFf59e0b),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RekomendasiScreen())),
                      ),
                      _quickAction(
                        icon: Icons.compare_arrows_rounded,
                        label: 'Bandingan\nProperti',
                        color: const Color(0xFF10b981),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BandingkanScreen())),
                      ),
                      _quickAction(
                        icon: Icons.calculate_rounded,
                        label: 'Kalkulator\nBudget',
                        color: const Color(0xFFec4899),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KalkulatorScreen())),
                      ),
                      _quickAction(
                        icon: Icons.favorite_rounded,
                        label: 'Favorit\nSaya',
                        color: const Color(0xFFef4444),
                        onTap: () => setState(() => _selectedIndex = 2),
                      ),
                      _quickAction(
                        icon: Icons.search_rounded,
                        label: 'Cari\nProperti',
                        color: const Color(0xFF3b82f6),
                        onTap: () => setState(() => _selectedIndex = 1),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // Header daftar rumah
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Daftar Rumah',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1a1a1a),
                    ),
                  ),
                  if (rumahProvider.isLoading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // Konten
          if (rumahProvider.isLoading && rumahProvider.rumahList.isEmpty)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (rumahProvider.rumahList.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.home_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(
                      'Belum ada data rumah',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      _RumahCard(rumah: rumahProvider.rumahList[index]),
                  childCount: rumahProvider.rumahList.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
      ),
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfil(AuthProvider auth) {
    final user = auth.user;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Profil Saya'),
        backgroundColor: const Color(0xFF0f766e),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
      children: [
        // Avatar
        Center(
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: const Color(0xFF0f766e).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, size: 50, color: Color(0xFF0f766e)),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            user?.name ?? '-',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        Center(
          child: Text(
            user?.email ?? '-',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
        const SizedBox(height: 28),

        // Info card
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _profilItem(Icons.person_outlined, 'Nama', user?.name ?? '-'),
                const Divider(),
                _profilItem(Icons.email_outlined, 'Email', user?.email ?? '-'),
                const Divider(),
                _profilItem(Icons.phone_outlined, 'No. HP', user?.phone ?? '-'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Tombol Edit Profil
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
            );
          },
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Edit Profil'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0f766e),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Tombol Logout
        OutlinedButton.icon(
          onPressed: _logout,
          icon: const Icon(Icons.logout, color: Colors.red),
          label: const Text('Keluar', style: TextStyle(color: Colors.red)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.red),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
      ),
    );
  }

  Widget _profilItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF0f766e), size: 20),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _RumahCard extends StatelessWidget {
  final Rumah rumah;
  const _RumahCard({required this.rumah});

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
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailRumahScreen(
                rumahId: rumah.id,
                namaRumah: rumah.nama,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Foto / placeholder
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF0f766e).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: rumah.foto != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          ApiService.getImageUrl(rumah.foto),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.home_outlined,
                            size: 36,
                            color: Color(0xFF0f766e),
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.home_outlined,
                        size: 36,
                        color: Color(0xFF0f766e),
                      ),
              ),
              const SizedBox(width: 14),

              // Info
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
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            rumah.lokasi,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatHarga(rumah.harga),
                      style: const TextStyle(
                        color: Color(0xFF0f766e),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _chip(Icons.bed_outlined, '${rumah.kamarTidur} KT'),
                        const SizedBox(width: 6),
                        _chip(Icons.bathroom_outlined, '${rumah.kamarMandi} KM'),
                        const SizedBox(width: 6),
                        _chip(
                          Icons.straighten_outlined,
                          '${rumah.luasBangunan}m²',
                        ),
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

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF0f766e).withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(icon, size: 11, color: const Color(0xFF0f766e)),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF0f766e),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
