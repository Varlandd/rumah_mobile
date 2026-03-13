import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/admin_provider.dart';
import '../../models/rumah.dart';

class AdminRumahFormScreen extends StatefulWidget {
  final Rumah? rumah; // Jika null = Tambah, Jika ada = Edit

  const AdminRumahFormScreen({super.key, this.rumah});

  @override
  State<AdminRumahFormScreen> createState() => _AdminRumahFormScreenState();
}

class _AdminRumahFormScreenState extends State<AdminRumahFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _namaController;
  late TextEditingController _hargaController;
  late TextEditingController _lokasiController;
  late TextEditingController _kamarTidurController;
  late TextEditingController _kamarMandiController;
  late TextEditingController _luasTanahController;
  late TextEditingController _luasBangunanController;
  late TextEditingController _deskripsiController;
  
  String _selectedTipe = 'Subsidi';
  final List<String> _tipeOptions = ['Subsidi', 'Komersial'];

  File? _selectedImage;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final r = widget.rumah;
    
    _namaController = TextEditingController(text: r?.nama ?? '');
    _hargaController = TextEditingController(text: r != null ? r.harga.toString() : '');
    _lokasiController = TextEditingController(text: r?.lokasi ?? '');
    _kamarTidurController = TextEditingController(text: r != null ? r.kamarTidur.toString() : '');
    _kamarMandiController = TextEditingController(text: r != null ? r.kamarMandi.toString() : '');
    _luasTanahController = TextEditingController(text: r?.luasTanah?.toString() ?? '');
    _luasBangunanController = TextEditingController(text: r?.luasBangunan?.toString() ?? '');
    _deskripsiController = TextEditingController(text: r?.deskripsi ?? '');

    if (r != null && _tipeOptions.contains(r.tipe)) {
      _selectedTipe = r.tipe;
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _hargaController.dispose();
    _lokasiController.dispose();
    _kamarTidurController.dispose();
    _kamarMandiController.dispose();
    _luasTanahController.dispose();
    _luasBangunanController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    final fields = {
      'nama': _namaController.text.trim(),
      'harga': _hargaController.text.trim(),
      'lokasi': _lokasiController.text.trim(),
      'kamar_tidur': _kamarTidurController.text.trim(),
      'kamar_mandi': _kamarMandiController.text.trim(),
      'tipe': _selectedTipe,
    };

    if (_luasTanahController.text.isNotEmpty) {
      fields['luas_tanah'] = _luasTanahController.text.trim();
    }
    if (_luasBangunanController.text.isNotEmpty) {
      fields['luas_bangunan'] = _luasBangunanController.text.trim();
    }
    if (_deskripsiController.text.isNotEmpty) {
      fields['deskripsi'] = _deskripsiController.text.trim();
    }

    final admin = context.read<AdminProvider>();
    bool success;

    if (widget.rumah == null) {
      // Create
      success = await admin.createRumah(fields, imagePath: _selectedImage?.path);
    } else {
      // Update
      success = await admin.updateRumah(widget.rumah!.id, fields, imagePath: _selectedImage?.path);
    }

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.rumah == null ? 'Rumah ditambahkan' : 'Rumah diperbarui'), 
          backgroundColor: Colors.green
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(admin.errorMessage ?? 'Gagal menyimpan'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.rumah != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Rumah' : 'Tambah Rumah'),
        backgroundColor: const Color(0xFF0f766e),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Gambar
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
                    ),
                    child: _selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(_selectedImage!, fit: BoxFit.cover),
                          )
                        : (isEdit && widget.rumah!.foto != null)
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(widget.rumah!.foto!, fit: BoxFit.cover),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo, size: 48, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('Pilih Gambar', style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(labelText: 'Nama Properti*', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _hargaController,
                decoration: const InputDecoration(labelText: 'Harga*', prefixText: 'Rp ', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _lokasiController,
                decoration: const InputDecoration(labelText: 'Lokasi*', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _kamarTidurController,
                      decoration: const InputDecoration(labelText: 'Kamar Tidur*', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Wajib' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _kamarMandiController,
                      decoration: const InputDecoration(labelText: 'Kamar Mandi*', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Wajib' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _luasTanahController,
                      decoration: const InputDecoration(labelText: 'Luas Tanah (m2)', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _luasBangunanController,
                      decoration: const InputDecoration(labelText: 'Luas Bangunan', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedTipe,
                decoration: const InputDecoration(labelText: 'Tipe*', border: OutlineInputBorder()),
                items: _tipeOptions.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedTipe = v);
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _deskripsiController,
                decoration: const InputDecoration(labelText: 'Deskripsi', border: OutlineInputBorder()),
                maxLines: 4,
              ),
              const SizedBox(height: 32),

              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: context.watch<AdminProvider>().isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0f766e),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: context.watch<AdminProvider>().isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(isEdit ? 'Simpan' : 'Tambah Properti', style: const TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
