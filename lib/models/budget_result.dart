class BudgetResult {
  final int budgetRumah;
  final int cicilanPerBulan;
  final int sisaPendapatan;
  final int maxCicilan;
  final int? pokokPinjaman;
  final int? uangMuka;
  final int? tenorTahun;

  BudgetResult({
    required this.budgetRumah,
    required this.cicilanPerBulan,
    required this.sisaPendapatan,
    required this.maxCicilan,
    this.pokokPinjaman,
    this.uangMuka,
    this.tenorTahun,
  });

  factory BudgetResult.fromJson(Map<String, dynamic> json) {
    return BudgetResult(
      budgetRumah: (json['budget_rumah'] is int) ? json['budget_rumah'] : int.tryParse(json['budget_rumah']?.toString() ?? '0') ?? 0,
      cicilanPerBulan: (json['cicilan_per_bulan'] is int) ? json['cicilan_per_bulan'] : int.tryParse(json['cicilan_per_bulan']?.toString() ?? '0') ?? 0,
      sisaPendapatan: (json['sisa_pendapatan'] is int) ? json['sisa_pendapatan'] : int.tryParse(json['sisa_pendapatan']?.toString() ?? '0') ?? 0,
      maxCicilan: (json['max_cicilan'] is int) ? json['max_cicilan'] : int.tryParse(json['max_cicilan']?.toString() ?? '0') ?? 0,
      pokokPinjaman: json['pokok_pinjaman'] is int ? json['pokok_pinjaman'] : int.tryParse(json['pokok_pinjaman']?.toString() ?? ''),
      uangMuka: json['uang_muka'] is int ? json['uang_muka'] : int.tryParse(json['uang_muka']?.toString() ?? ''),
      tenorTahun: json['tenor_tahun'] is int ? json['tenor_tahun'] : int.tryParse(json['tenor_tahun']?.toString() ?? ''),
    );
  }
}
