// lib/core/db_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() {
    return _instance;
  }

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = await getDatabasesPath();
    String databasePath = join(path, 'sipesantren.db');
    return await openDatabase(
      databasePath,
      version: 5,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
  }

  Future<void> _createTables(Database db) async {
    // Aktivitas Kelas Table
    await db.execute('''
      CREATE TABLE aktivitas_kelas(
        id TEXT PRIMARY KEY,
        kelasId TEXT,
        type TEXT,
        title TEXT,
        description TEXT,
        authorId TEXT,
        createdAt INTEGER,
        syncStatus INTEGER DEFAULT 0
      )
    ''');

    // Kelas Table
    await db.execute('''
      CREATE TABLE kelas(
        id TEXT PRIMARY KEY,
        name TEXT,
        waliKelasId TEXT,
        syncStatus INTEGER DEFAULT 0
      )
    ''');

    // Santri Table
    await db.execute('''
      CREATE TABLE santri(
        id TEXT PRIMARY KEY,
        nis TEXT,
        nama TEXT,
        kamarGedung TEXT,
        kamarNomor INTEGER,
        angkatan INTEGER,
        kelasId TEXT,
        waliSantriId TEXT,
        syncStatus INTEGER DEFAULT 0
      )
    ''');

    // Teaching Assignments Table
    await db.execute('''
      CREATE TABLE teaching_assignments(
        id TEXT PRIMARY KEY,
        kelasId TEXT,
        mapelId TEXT,
        ustadId TEXT,
        syncStatus INTEGER DEFAULT 0
      )
    ''');

    // Penilaian Tahfidz Table
    await db.execute('''
      CREATE TABLE penilaian_tahfidz(
        id TEXT PRIMARY KEY,
        santriId TEXT,
        minggu INTEGER, 
        surah TEXT,
        ayat_setor INTEGER,
        target_ayat INTEGER,
        tajwid INTEGER,
        syncStatus INTEGER DEFAULT 0
      )
    ''');

    // Penilaian Mapel Table
    await db.execute('''
      CREATE TABLE penilaian_mapel(
        id TEXT PRIMARY KEY,
        santriId TEXT,
        mapel TEXT,
        formatif INTEGER,
        sumatif INTEGER,
        syncStatus INTEGER DEFAULT 0
      )
    ''');

    // Penilaian Akhlak Table
    await db.execute('''
      CREATE TABLE penilaian_akhlak(
        id TEXT PRIMARY KEY,
        santriId TEXT,
        disiplin INTEGER,
        adab INTEGER,
        kebersihan INTEGER,
        kerjasama INTEGER,
        catatan TEXT,
        syncStatus INTEGER DEFAULT 0
      )
    ''');

    // Kehadiran Table
    await db.execute('''
      CREATE TABLE kehadiran(
        id TEXT PRIMARY KEY,
        santriId TEXT,
        tanggal INTEGER,
        status TEXT,
        syncStatus INTEGER DEFAULT 0
      )
    ''');

    // Mapel Table
    await db.execute('''
      CREATE TABLE mapel(
        id TEXT PRIMARY KEY,
        name TEXT,
        syncStatus INTEGER DEFAULT 0
      )
    ''');

    // Seed default Mapel
    await db.insert('mapel', {'id': 'mapel_fiqh', 'name': 'Fiqh', 'syncStatus': 1});
    await db.insert('mapel', {'id': 'mapel_ba', 'name': 'Bahasa Arab', 'syncStatus': 1});
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 5) {
      // Simple migration: Drop all and recreate for development phase
      await db.execute('DROP TABLE IF EXISTS aktivitas_kelas');
      await db.execute('DROP TABLE IF EXISTS kelas');
      await db.execute('DROP TABLE IF EXISTS teaching_assignments');
      await db.execute('DROP TABLE IF EXISTS santri');
      await db.execute('DROP TABLE IF EXISTS penilaian_tahfidz');
      await db.execute('DROP TABLE IF EXISTS penilaian_mapel');
      await db.execute('DROP TABLE IF EXISTS penilaian_akhlak');
      await db.execute('DROP TABLE IF EXISTS kehadiran');
      await db.execute('DROP TABLE IF EXISTS mapel');
      await _createTables(db);
    }
  }

  Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
  }
}
