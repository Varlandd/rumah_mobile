import '../services/api_service.dart';

class Rumah {
  final int id;
  final String nama;
  final String lokasi;
  final int harga;
  final int luasTanah;
  final int luasBangunan;
  final int kamarTidur;
  final int kamarMandi;
  final String tipe;
  final String? foto;
  final String? deskripsi;
  final List<Fasilitas>? fasilitas;
  final double? skor;
  final int? rank;
  final bool? isFavorit;

  Rumah({
    required this.id,
    required this.nama,
    required this.lokasi,
    required this.harga,
    required this.luasTanah,
    required this.luasBangunan,
    required this.kamarTidur,
    required this.kamarMandi,
    required this.tipe,
    this.foto,
    this.deskripsi,
    this.fasilitas,
    this.skor,
    this.rank,
    this.isFavorit,
  });

  factory Rumah.fromJson(Map<String, dynamic> json) {
    return Rumah(
      id: json['id'],
      nama: json['nama'],
      lokasi: json['lokasi'],
      harga: json['harga'],
      luasTanah: json['luas_tanah'],
      luasBangunan: json['luas_bangunan'],
      kamarTidur: json['kamar_tidur'],
      kamarMandi: json['kamar_mandi'],
      tipe: json['tipe'],
      foto: json['foto'] != null ? ApiService.getImageUrl(json['foto']) : null,
      deskripsi: json['deskripsi'],
      fasilitas: json['fasilitas'] != null
          ? (json['fasilitas'] as List)
              .map((f) => Fasilitas.fromJson(f))
              .toList()
          : null,
      skor: json['skor']?.toDouble(),
      rank: json['rank'],
      isFavorit: json['is_favorit'],
    );
  }
}

class Fasilitas {
  final int id;
  final String nama;

  Fasilitas({
    required this.id,
    required this.nama,
  });

  factory Fasilitas.fromJson(Map<String, dynamic> json) {
    return Fasilitas(
      id: json['id'],
      nama: json['nama'],
    );
  }
}
