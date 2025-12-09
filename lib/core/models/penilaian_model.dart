import 'package:cloud_firestore/cloud_firestore.dart';

class PenilaianTahfidz {
  final String id;
  final String santriId;
  final DateTime minggu;
  final String surah;
  final int ayatSetor;
  final int targetAyat;
  final int tajwid;
  final int? syncStatus;

  PenilaianTahfidz({
    required this.id,
    required this.santriId,
    required this.minggu,
    required this.surah,
    required this.ayatSetor,
    required this.targetAyat,
    required this.tajwid,
    this.syncStatus,
  });

  // SQLite
  factory PenilaianTahfidz.fromMap(Map<String, dynamic> map) {
    return PenilaianTahfidz(
      id: map['id'],
      santriId: map['santriId'],
      minggu: DateTime.fromMillisecondsSinceEpoch(map['minggu']),
      surah: map['surah'],
      ayatSetor: map['ayat_setor'],
      targetAyat: map['target_ayat'],
      tajwid: map['tajwid'],
      syncStatus: map['syncStatus'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'santriId': santriId,
      'minggu': minggu.millisecondsSinceEpoch,
      'surah': surah,
      'ayat_setor': ayatSetor,
      'target_ayat': targetAyat,
      'tajwid': tajwid,
      if (syncStatus != null) 'syncStatus': syncStatus,
    };
  }

  factory PenilaianTahfidz.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PenilaianTahfidz(
      id: doc.id,
      santriId: data['santriId'] ?? '',
      minggu: (data['minggu'] as Timestamp).toDate(),
      surah: data['surah'] ?? '',
      ayatSetor: data['ayat_setor'] ?? 0,
      targetAyat: data['target_ayat'] ?? 50,
      tajwid: data['tajwid'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'santriId': santriId,
      'minggu': Timestamp.fromDate(minggu),
      'surah': surah,
      'ayat_setor': ayatSetor,
      'target_ayat': targetAyat,
      'tajwid': tajwid,
    };
  }

  double get nilaiAkhir {
    double capaian = (ayatSetor / targetAyat) * 100;
    if (capaian > 100) capaian = 100;
    return (0.5 * capaian + 0.5 * tajwid).roundToDouble();
  }
}

class PenilaianMapel {
  final String id;
  final String santriId;
  final String mapel;
  final int formatif;
  final int sumatif;
  final int? syncStatus;

  PenilaianMapel({
    required this.id,
    required this.santriId,
    required this.mapel,
    required this.formatif,
    required this.sumatif,
    this.syncStatus,
  });

  // SQLite
  factory PenilaianMapel.fromMap(Map<String, dynamic> map) {
    return PenilaianMapel(
      id: map['id'],
      santriId: map['santriId'],
      mapel: map['mapel'],
      formatif: map['formatif'],
      sumatif: map['sumatif'],
      syncStatus: map['syncStatus'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'santriId': santriId,
      'mapel': mapel,
      'formatif': formatif,
      'sumatif': sumatif,
      if (syncStatus != null) 'syncStatus': syncStatus,
    };
  }

  factory PenilaianMapel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PenilaianMapel(
      id: doc.id,
      santriId: data['santriId'] ?? '',
      mapel: data['mapel'] ?? '',
      formatif: data['formatif'] ?? 0,
      sumatif: data['sumatif'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'santriId': santriId,
      'mapel': mapel,
      'formatif': formatif,
      'sumatif': sumatif,
    };
  }

  double get nilaiAkhir {
    return (0.4 * formatif + 0.6 * sumatif).roundToDouble();
  }
}

class PenilaianAkhlak {
  final String id;
  final String santriId;
  final int disiplin;
  final int adab;
  final int kebersihan;
  final int kerjasama;
  final String catatan;
  final int? syncStatus;

  PenilaianAkhlak({
    required this.id,
    required this.santriId,
    required this.disiplin,
    required this.adab,
    required this.kebersihan,
    required this.kerjasama,
    required this.catatan,
    this.syncStatus,
  });

  // SQLite
  factory PenilaianAkhlak.fromMap(Map<String, dynamic> map) {
    return PenilaianAkhlak(
      id: map['id'],
      santriId: map['santriId'],
      disiplin: map['disiplin'],
      adab: map['adab'],
      kebersihan: map['kebersihan'],
      kerjasama: map['kerjasama'],
      catatan: map['catatan'],
      syncStatus: map['syncStatus'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'santriId': santriId,
      'disiplin': disiplin,
      'adab': adab,
      'kebersihan': kebersihan,
      'kerjasama': kerjasama,
      'catatan': catatan,
      if (syncStatus != null) 'syncStatus': syncStatus,
    };
  }

  factory PenilaianAkhlak.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PenilaianAkhlak(
      id: doc.id,
      santriId: data['santriId'] ?? '',
      disiplin: data['disiplin'] ?? 1,
      adab: data['adab'] ?? 1,
      kebersihan: data['kebersihan'] ?? 1,
      kerjasama: data['kerjasama'] ?? 1,
      catatan: data['catatan'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'santriId': santriId,
      'disiplin': disiplin,
      'adab': adab,
      'kebersihan': kebersihan,
      'kerjasama': kerjasama,
      'catatan': catatan,
    };
  }

  double get nilaiAkhir {
    double avg = (disiplin + adab + kebersihan + kerjasama) / 4.0;
    return ((avg / 4.0) * 100).roundToDouble();
  }
}

class Kehadiran {
  final String id;
  final String santriId;
  final DateTime tanggal;
  final String status;
  final int? syncStatus;

  Kehadiran({
    required this.id,
    required this.santriId,
    required this.tanggal,
    required this.status,
    this.syncStatus,
  });

  // SQLite
  factory Kehadiran.fromMap(Map<String, dynamic> map) {
    return Kehadiran(
      id: map['id'],
      santriId: map['santriId'],
      tanggal: DateTime.fromMillisecondsSinceEpoch(map['tanggal']),
      status: map['status'],
      syncStatus: map['syncStatus'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'santriId': santriId,
      'tanggal': tanggal.millisecondsSinceEpoch,
      'status': status,
      if (syncStatus != null) 'syncStatus': syncStatus,
    };
  }

  factory Kehadiran.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Kehadiran(
      id: doc.id,
      santriId: data['santriId'] ?? '',
      tanggal: (data['tanggal'] as Timestamp).toDate(),
      status: data['status'] ?? 'A',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'santriId': santriId,
      'tanggal': Timestamp.fromDate(tanggal),
      'status': status,
    };
  }
}
