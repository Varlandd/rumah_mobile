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
  final Set<String> _selectedIds = {};
  bool _isBulkMode = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => context.read<RumahProvider>().fetchRumah(),
    );
  }

  void _confirmDelete(String id, String nama) {
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

  void _confirmDeleteSelected() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Masal'),
        content: Text('Yakin ingin menghapus ${_selectedIds.length} data rumah yang dipilih?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteSelected();
            },
            child: const Text('Hapus Semua', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _deleteRumah(String id) async {
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

  void _deleteSelected() async {
    final success = await context.read<AdminProvider>().deleteMultipleRumah(_selectedIds.toList());
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_selectedIds.length} rumah berhasil dihapus'), backgroundColor: Colors.green),
      );
      setState(() {
        _selectedIds.clear();
        _isBulkMode = false;
      });
      context.read<RumahProvider>().fetchRumah(); // Refresh list
    } else {
      final error = context.read<AdminProvider>().errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Gagal menghapus rumah'), backgroundColor: Colors.red),
      );
    }
  }

  void _toggleSelection(String id) {
    debugPrint("Toggle Selection for ID: $id");
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
      if (_selectedIds.isEmpty) _isBulkMode = false;
      else _isBulkMode = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final rumahProvider = context.watch<RumahProvider>();
    final list = rumahProvider.rumahList;
    final isAnySelected = _selectedIds.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            isAnySelected 
                ? Text('${_selectedIds.length} dipilih') 
                : const Text('Kelola Rumah (VERSI BARU)'),
            const Text('Mode Pilih Banyak Aktif', style: TextStyle(fontSize: 10, color: Colors.black54)),
          ],
        ),
        backgroundColor: isAnySelected ? Colors.red.shade800 : Colors.amber, // Warna kuning mencolok
        foregroundColor: Colors.black,
        leading: isAnySelected 
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() {
                  _selectedIds.clear();
                  _isBulkMode = false;
                }),
              )
            : null,
        actions: [
          if (isAnySelected)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.white),
              onPressed: _confirmDeleteSelected,
              tooltip: 'Hapus yang dipilih',
            )
          else ...[
            IconButton(
              icon: Icon(_isBulkMode ? Icons.check_box : Icons.check_box_outline_blank, color: Colors.black),
              onPressed: () {
                setState(() => _isBulkMode = !_isBulkMode);
                if (!_isBulkMode) _selectedIds.clear();
              },
              tooltip: 'Mode Pilih Banyak',
            ),
          ]
        ],
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
                        final isSelected = _selectedIds.contains(rumah.id);
                        
                        return _RumahAdminCard(
                          rumah: rumah,
                          isSelected: isSelected,
                          isBulkMode: _isBulkMode,
                          onToggle: () => _toggleSelection(rumah.id),
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
      floatingActionButton: isAnySelected 
        ? null 
        : FloatingActionButton(
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
  final bool isSelected;
  final bool isBulkMode;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RumahAdminCard({
    required this.rumah,
    required this.isSelected,
    required this.isBulkMode,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected 
          ? const BorderSide(color: Colors.red, width: 2)
          : BorderSide.none,
      ),
      elevation: isSelected ? 4 : 1,
      child: InkWell(
        onTap: isBulkMode ? onToggle : null,
        onLongPress: onToggle,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Checkbox Area
              if (isBulkMode || isSelected)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (_) => onToggle(),
                    activeColor: Colors.red,
                  ),
                ),

              // Gambar
              GestureDetector(
                onTap: onToggle,
                child: Container(
                  width: 70,
                  height: 70,
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
              ),
              const SizedBox(width: 12),

              // Detail
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rumah.nama,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rp ${(rumah.harga / 1000000).toStringAsFixed(0)} Jt',
                      style: const TextStyle(color: Color(0xFF0f766e), fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),

              // Aksi
              if (!isSelected && !isBulkMode)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                      constraints: const BoxConstraints(),
                    ),
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
