import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => context.read<AdminProvider>().fetchUsers(),
    );
  }

  void _showRoleDialog(int userId, String currentRole) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubah Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Admin'),
              leading: Radio<String>(
                value: 'admin',
                groupValue: currentRole,
                onChanged: (v) {
                  Navigator.pop(ctx);
                  if (v != null && v != currentRole) _changeRole(userId, v);
                },
              ),
            ),
            ListTile(
              title: const Text('User'),
              leading: Radio<String>(
                value: 'user',
                groupValue: currentRole,
                onChanged: (v) {
                  Navigator.pop(ctx);
                  if (v != null && v != currentRole) _changeRole(userId, v);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _changeRole(int userId, String newRole) async {
    final success = await context.read<AdminProvider>().updateUserRole(userId, newRole);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Role berhasil diubah menjadi $newRole'), backgroundColor: Colors.green),
      );
    } else {
      final error = context.read<AdminProvider>().errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Gagal mengubah role'), backgroundColor: Colors.red),
      );
    }
  }

  void _confirmDelete(int userId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Pengguna'),
        content: Text('Yakin ingin menghapus pengguna "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteUser(userId);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _deleteUser(int userId) async {
    final success = await context.read<AdminProvider>().deleteUser(userId);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengguna dihapus'), backgroundColor: Colors.green),
      );
    } else {
      final error = context.read<AdminProvider>().errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Gagal menghapus pengguna'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Kelola Pengguna'),
        backgroundColor: const Color(0xFF0f766e),
        foregroundColor: Colors.white,
      ),
      body: admin.isLoading && admin.users.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => admin.fetchUsers(),
              child: admin.users.isEmpty
                  ? const Center(child: Text('Tidak ada pengguna'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: admin.users.length,
                      itemBuilder: (context, index) {
                        final user = admin.users[index];
                        final isAdmin = user.role == 'admin';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: isAdmin ? Colors.amber.shade100 : Colors.teal.shade50,
                                      child: Icon(
                                        isAdmin ? Icons.admin_panel_settings : Icons.person,
                                        color: isAdmin ? Colors.amber.shade800 : Colors.teal,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            user.name,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          Text(user.email, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isAdmin ? Colors.amber.shade100 : Colors.teal.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        (user.role ?? 'user').toUpperCase(),
                                        style: TextStyle(
                                          color: isAdmin ? Colors.amber.shade800 : Colors.teal,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Divider(height: 1),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () => _showRoleDialog(user.id, user.role ?? 'user'),
                                      icon: const Icon(Icons.manage_accounts, size: 18),
                                      label: const Text('Ubah Role'),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton.icon(
                                      onPressed: () => _confirmDelete(user.id, user.name),
                                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                      label: const Text('Hapus', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
