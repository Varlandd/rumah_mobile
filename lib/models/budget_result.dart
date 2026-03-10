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
      budgetRumah: json['budget_rumah'],
      cicilanPerBulan: json['cicilan_per_bulan'],
      sisaPendapatan: json['sisa_pendapatan'],
      maxCicilan: json['max_cicilan'],
      pokokPinjaman: json['pokok_pinjaman'],
      uangMuka: json['uang_muka'],
      tenorTahun: json['tenor_tahun'],
    );
  }
}
