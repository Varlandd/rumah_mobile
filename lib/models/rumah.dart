import '../services/api_service.dart';

class Rumah {
  final String id;
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
  final double? score;
  final int? rank;
  final bool? isFavorit;
  final double? latitude;
  final double? longitude;

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
    this.score,
    this.rank,
    this.isFavorit,
    this.latitude,
    this.longitude,
  });

  factory Rumah.fromJson(Map<String, dynamic> json) {
    return Rumah(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      nama: json['nama']?.toString() ?? '',
      lokasi: json['lokasi']?.toString() ?? '',
      harga: (json['harga'] is int) ? json['harga'] : int.tryParse(json['harga']?.toString() ?? '0') ?? 0,
      luasTanah: (json['luas_tanah'] is int) ? json['luas_tanah'] : int.tryParse(json['luas_tanah']?.toString() ?? '0') ?? 0,
      luasBangunan: (json['luas_bangunan'] is int) ? json['luas_bangunan'] : int.tryParse(json['luas_bangunan']?.toString() ?? '0') ?? 0,
      kamarTidur: (json['kamar_tidur'] is int) ? json['kamar_tidur'] : int.tryParse(json['kamar_tidur']?.toString() ?? '0') ?? 0,
      kamarMandi: (json['kamar_mandi'] is int) ? json['kamar_mandi'] : int.tryParse(json['kamar_mandi']?.toString() ?? '0') ?? 0,
      tipe: json['tipe']?.toString() ?? '',
      foto: json['foto'] != null ? ApiService.getImageUrl(json['foto']) : null,
      deskripsi: json['deskripsi']?.toString(),
      fasilitas: json['fasilitas'] != null
          ? (json['fasilitas'] as List)
              .map((f) => Fasilitas.fromJson(f is Map<String, dynamic> ? f : {'nama': f.toString()}))
              .toList()
          : null,
      score: (json['score'] as num?)?.toDouble(),
      rank: json['rank'] is int ? json['rank'] : int.tryParse(json['rank']?.toString() ?? ''),
      isFavorit: json['is_favorit'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}

class Fasilitas {
  final String id;
  final String nama;

  Fasilitas({
    required this.id,
    required this.nama,
  });

  factory Fasilitas.fromJson(Map<String, dynamic> json) {
    return Fasilitas(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      nama: json['nama'],
    );
  }
}

