import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/rumah_provider.dart';

class KalkulatorScreen extends StatefulWidget {
  final int? initialHargaRumah;

  const KalkulatorScreen({super.key, this.initialHargaRumah});

  @override
  State<KalkulatorScreen> createState() => _KalkulatorScreenState();
}

class _KalkulatorScreenState extends State<KalkulatorScreen> {
  final _formKey = GlobalKey<FormState>();

  final _penghasilanController = TextEditingController();
  final _uangMukaController = TextEditingController();
  final _cicilanLainController = TextEditingController();

  int _tenor = 15;

  String _formatCurrency(int amount) {
    return 'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialHargaRumah != null) {
      // If we came from a specific house, we might set Uang Muka to 20% of the price as suggestion
      final suggestedDownPayment = widget.initialHargaRumah! * 0.2;
      _uangMukaController.text = suggestedDownPayment.toInt().toString();
    }
  }

  @override
  void dispose() {
    _penghasilanController.dispose();
    _uangMukaController.dispose();
    _cicilanLainController.dispose();
    super.dispose();
  }

  void _hitung() {
    if (!_formKey.currentState!.validate()) return;

    final penghasilan = int.tryParse(_penghasilanController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final uangMuka = int.tryParse(_uangMukaController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final cicilanLain = int.tryParse(_cicilanLainController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    context.read<RumahProvider>().hitungBudget(
          penghasilan: penghasilan,
          uangMuka: uangMuka,
          cicilanLain: cicilanLain,
          tenor: _tenor,
        );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RumahProvider>();
    final result = provider.budgetResult;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Simulasi KPR'),
        backgroundColor: const Color(0xFF0f766e),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF0f766e),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kalkulator Budget',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Hitung Kemampuan\nBeli Rumah Kamu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            // Form
            Padding(
              padding: const EdgeInsets.all(20),
              child: Card(
                elevation: 4,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputField(
                          label: 'Penghasilan / Bulan',
                          controller: _penghasilanController,
                          hint: 'Contoh: 10000000',
                          icon: Icons.payments_outlined,
                        ),
                        const SizedBox(height: 16),
                        _buildInputField(
                          label: 'Uang Muka Tersedia',
                          controller: _uangMukaController,
                          hint: 'Contoh: 50000000',
                          icon: Icons.savings_outlined,
                        ),
                        const SizedBox(height: 16),
                        _buildInputField(
                          label: 'Cicilan Bulanan Lain',
                          controller: _cicilanLainController,
                          hint: 'Opsional, contoh: 2000000',
                          icon: Icons.receipt_long_outlined,
                          isOptional: true,
                        ),
                        const SizedBox(height: 16),
                        
                        // Tenor Dropdown
                        const Text(
                          'Tenor KPR',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _tenor,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF0f766e)),
                              items: const [
                                DropdownMenuItem(value: 5, child: Text('5 Tahun')),
                                DropdownMenuItem(value: 10, child: Text('10 Tahun')),
                                DropdownMenuItem(value: 15, child: Text('15 Tahun')),
                                DropdownMenuItem(value: 20, child: Text('20 Tahun')),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _tenor = val);
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Tombol Hitung
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: provider.isLoading ? null : _hitung,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0f766e),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: provider.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Hitung Kemampuan Saya',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Result
            if (result != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFF0f766e).withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.analytics_outlined, color: Color(0xFF0f766e)),
                          SizedBox(width: 8),
                          Text(
                            'Hasil Analisis Budget',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0f766e),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      _buildResultItem('Budget Rumah Maksimal', result.budgetRumah),
                      const Divider(height: 30),
                      _buildResultItem('Estimasi Cicilan / Bulan', result.cicilanPerBulan),
                      const Divider(height: 30),
                      _buildResultItem('Sisa Pendapatan / Bulan', result.sisaPendapatan),
                      
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: OutlinedButton(
                          onPressed: () {
                            // Navigate to search with this budget max
                            // TODO
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0f766e),
                            side: const BorderSide(color: Color(0xFF0f766e)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Cari Rumah Sesuai Budget',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
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

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isOptional = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: const Color(0xFF0f766e), size: 20),
            prefixText: 'Rp ',
            prefixStyle: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF0f766e), width: 1.5),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          validator: (val) {
            if (!isOptional && (val == null || val.isEmpty)) {
              return 'Wajib diisi';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildResultItem(String label, int value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _formatCurrency(value),
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
