import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/rumah_provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/rumah.dart';
import 'admin_rumah_form_screen.dart';

class AdminRumahScreen extends StatefulWidget {
  const AdminRumahScreen({super.key});

  @override
  State<AdminRumahScreen> createState() => _AdminRumahScreenState();
}

class _AdminRumahScreenState extends State<AdminRumahScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => context.read<RumahProvider>().fetchRumah(),
    );
  }

  void _confirmDelete(int id, String nama) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Rumah'),
        content: Text('Yakin ingin menghapus "$nama"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteRumah(id);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _deleteRumah(int id) async {
    final success = await context.read<AdminProvider>().deleteRumah(id);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rumah berhasil dihapus'), backgroundColor: Colors.green),
      );
      context.read<RumahProvider>().fetchRumah(); // Refresh list
    } else {
      final error = context.read<AdminProvider>().errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Gagal menghapus rumah'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final rumahProvider = context.watch<RumahProvider>();
    final list = rumahProvider.rumahList;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Kelola Rumah'),
        backgroundColor: const Color(0xFF0f766e),
        foregroundColor: Colors.white,
      ),
      body: rumahProvider.isLoading && list.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => rumahProvider.fetchRumah(),
              child: list.isEmpty
                  ? const Center(child: Text('Belum ada data rumah'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final rumah = list[index];
                        return _RumahAdminCard(
                          rumah: rumah,
                          onEdit: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AdminRumahFormScreen(rumah: rumah),
                              ),
                            ).then((_) => context.read<RumahProvider>().fetchRumah());
                          },
                          onDelete: () => _confirmDelete(rumah.id, rumah.nama),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AdminRumahFormScreen(),
            ),
          ).then((_) => context.read<RumahProvider>().fetchRumah());
        },
        backgroundColor: const Color(0xFF0f766e),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _RumahAdminCard extends StatelessWidget {
  final Rumah rumah;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RumahAdminCard({
    required this.rumah,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Gambar
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: rumah.foto != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        rumah.foto!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    )
                  : const Icon(Icons.image, color: Colors.grey),
            ),
            const SizedBox(width: 12),

            // Detail
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rumah.nama,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          rumah.lokasi,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rp ${(rumah.harga / 1000000).toStringAsFixed(0)} Jt',
                    style: const TextStyle(color: Color(0xFF0f766e), fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            // Aksi
            Column(
              children: [
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  tooltip: 'Edit',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Hapus',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
