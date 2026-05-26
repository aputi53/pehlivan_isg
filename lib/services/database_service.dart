import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static Database? _db;

  static Future<Database> get db async {
    _db ??= await _init();
    return _db!;
  }

  static Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'pehlivan_isg.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE gruplar (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        grupAdi TEXT NOT NULL,
        tarih TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE firmalar (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        grupId INTEGER NOT NULL,
        isim TEXT NOT NULL,
        telefon TEXT,
        mail TEXT,
        durum TEXT NOT NULL DEFAULT 'NORMAL',
        FOREIGN KEY (grupId) REFERENCES gruplar(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE notlar (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        firmaId INTEGER NOT NULL,
        metin TEXT NOT NULL,
        zaman TEXT NOT NULL,
        fotoPaths TEXT NOT NULL DEFAULT '[]',
        FOREIGN KEY (firmaId) REFERENCES firmalar(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE gorsel_raporlar (
        id TEXT PRIMARY KEY,
        firmaId INTEGER NOT NULL,
        baslik TEXT NOT NULL,
        rapor TEXT NOT NULL,
        tarih TEXT NOT NULL,
        fotoPaths TEXT NOT NULL DEFAULT '[]',
        FOREIGN KEY (firmaId) REFERENCES firmalar(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE belgeler (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        firmaId INTEGER NOT NULL,
        baslik TEXT NOT NULL,
        dosyaYolu TEXT NOT NULL,
        tur TEXT NOT NULL DEFAULT 'diger',
        eklemeTarihi TEXT NOT NULL,
        FOREIGN KEY (firmaId) REFERENCES firmalar(id) ON DELETE CASCADE
      )
    ''');

    // Onboarding: örnek grup ve firma
    await db.insert('gruplar', {
      'grupAdi': 'ÖRNEK GRUP',
      'tarih': DateTime(2026, 6, 1).toIso8601String(),
    });
    await db.insert('firmalar', {
      'grupId': 1,
      'isim': 'ÖRNEK FİRMA',
      'telefon': '5001234567',
      'mail': 'ornek@firma.com',
      'durum': 'NORMAL',
    });
  }

  // ─── GRUPLAR ───────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getGruplar() async {
    final database = await db;
    final grupRows = await database.query('gruplar', orderBy: 'id ASC');
    final List<Map<String, dynamic>> result = [];

    for (final grup in grupRows) {
      final firmalar = await getFirmalar(grup['id'] as int);
      result.add({
        'id': grup['id'],
        'grupAdi': grup['grupAdi'],
        'tarih': DateTime.parse(grup['tarih'] as String),
        'firmalar': firmalar,
      });
    }
    return result;
  }

  static Future<int> insertGrup(String grupAdi, DateTime tarih) async {
    final database = await db;
    return database.insert('gruplar', {
      'grupAdi': grupAdi,
      'tarih': tarih.toIso8601String(),
    });
  }

  static Future<void> updateGrup(int id, String grupAdi, DateTime tarih) async {
    final database = await db;
    await database.update(
      'gruplar',
      {'grupAdi': grupAdi, 'tarih': tarih.toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> deleteGrup(int id) async {
    final database = await db;
    await database.delete('gruplar', where: 'id = ?', whereArgs: [id]);
  }

  // ─── FİRMALAR ──────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getFirmalar(int grupId) async {
    final database = await db;
    final rows = await database.query(
      'firmalar',
      where: 'grupId = ?',
      whereArgs: [grupId],
      orderBy: 'id ASC',
    );

    final List<Map<String, dynamic>> result = [];
    for (final row in rows) {
      final firmaId = row['id'] as int;
      final notlar = await getNotlar(firmaId);
      final raporlar = await getGorselRaporlar(firmaId);
      final belgeler = await getBelgeler(firmaId);
      result.add({
        'id': firmaId,
        'grupId': row['grupId'],
        'isim': row['isim'],
        'telefon': row['telefon'] ?? '',
        'mail': row['mail'] ?? '',
        'durum': row['durum'],
        'notlar': notlar,
        'raporlar': raporlar,
        'belgeler': belgeler,
      });
    }
    return result;
  }

  static Future<int> insertFirma(
      int grupId, String isim, String telefon, String mail) async {
    final database = await db;
    return database.insert('firmalar', {
      'grupId': grupId,
      'isim': isim,
      'telefon': telefon,
      'mail': mail,
      'durum': 'NORMAL',
    });
  }

  static Future<void> updateFirma(
      int id, String isim, String telefon, String mail) async {
    final database = await db;
    await database.update(
      'firmalar',
      {'isim': isim, 'telefon': telefon, 'mail': mail},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> updateFirmaDurum(int id, String durum) async {
    final database = await db;
    await database.update(
      'firmalar',
      {'durum': durum},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> deleteFirma(int id) async {
    final database = await db;
    await database.delete('firmalar', where: 'id = ?', whereArgs: [id]);
  }

  // ─── NOTLAR ────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getNotlar(int firmaId) async {
    final database = await db;
    final rows = await database.query(
      'notlar',
      where: 'firmaId = ?',
      whereArgs: [firmaId],
      orderBy: 'id ASC',
    );
    return rows.map((row) {
      final paths = (jsonDecode(row['fotoPaths'] as String) as List)
          .cast<String>();
      return {
        'id': row['id'],
        'firmaId': row['firmaId'],
        'metin': row['metin'],
        'zaman': DateTime.parse(row['zaman'] as String),
        'fotoPaths': paths,
      };
    }).toList();
  }

  static Future<int> insertNot(
      int firmaId, String metin, DateTime zaman, List<String> fotoPaths) async {
    final database = await db;
    return database.insert('notlar', {
      'firmaId': firmaId,
      'metin': metin,
      'zaman': zaman.toIso8601String(),
      'fotoPaths': jsonEncode(fotoPaths),
    });
  }

  static Future<void> deleteNot(int id) async {
    final database = await db;
    await database.delete('notlar', where: 'id = ?', whereArgs: [id]);
  }

  // ─── GÖRSEL RAPORLAR ───────────────────────────────

  static Future<List<Map<String, dynamic>>> getGorselRaporlar(
      int firmaId) async {
    final database = await db;
    final rows = await database.query(
      'gorsel_raporlar',
      where: 'firmaId = ?',
      whereArgs: [firmaId],
      orderBy: 'tarih DESC',
    );
    return rows.map((row) {
      final paths = (jsonDecode(row['fotoPaths'] as String) as List)
          .cast<String>();
      return {
        'id': row['id'],
        'firmaId': row['firmaId'],
        'baslik': row['baslik'],
        'rapor': row['rapor'],
        'tarih': DateTime.parse(row['tarih'] as String),
        'fotoPaths': paths,
      };
    }).toList();
  }

  static Future<void> insertGorselRapor({
    required String id,
    required int firmaId,
    required String baslik,
    required String rapor,
    required DateTime tarih,
    required List<String> fotoPaths,
  }) async {
    final database = await db;
    await database.insert('gorsel_raporlar', {
      'id': id,
      'firmaId': firmaId,
      'baslik': baslik,
      'rapor': rapor,
      'tarih': tarih.toIso8601String(),
      'fotoPaths': jsonEncode(fotoPaths),
    });
  }

  static Future<void> deleteGorselRapor(String id) async {
    final database = await db;
    await database.delete('gorsel_raporlar', where: 'id = ?', whereArgs: [id]);
  }

  // Tüm görsel raporlar (Raporlar modülü için)
  static Future<List<Map<String, dynamic>>> getAllGorselRaporlar() async {
    final database = await db;
    final rows = await database.rawQuery('''
      SELECT gr.*, f.isim as firmaIsim
      FROM gorsel_raporlar gr
      JOIN firmalar f ON gr.firmaId = f.id
      ORDER BY gr.tarih DESC
    ''');
    return rows.map((row) {
      final paths = (jsonDecode(row['fotoPaths'] as String) as List)
          .cast<String>();
      return {
        'id': row['id'],
        'firmaId': row['firmaId'],
        'firmaIsim': row['firmaIsim'],
        'baslik': row['baslik'],
        'rapor': row['rapor'],
        'tarih': DateTime.parse(row['tarih'] as String),
        'fotoPaths': paths,
      };
    }).toList();
  }

  // ─── BELGELER ──────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getBelgeler(int firmaId) async {
    final database = await db;
    final rows = await database.query(
      'belgeler',
      where: 'firmaId = ?',
      whereArgs: [firmaId],
      orderBy: 'eklemeTarihi DESC',
    );
    return rows.map((row) => {
          'id': row['id'],
          'firmaId': row['firmaId'],
          'baslik': row['baslik'],
          'dosyaYolu': row['dosyaYolu'],
          'tur': row['tur'],
          'eklemeTarihi': DateTime.parse(row['eklemeTarihi'] as String),
        }).toList();
  }

  static Future<int> insertBelge({
    required int firmaId,
    required String baslik,
    required String dosyaYolu,
    required String tur,
  }) async {
    final database = await db;
    return database.insert('belgeler', {
      'firmaId': firmaId,
      'baslik': baslik,
      'dosyaYolu': dosyaYolu,
      'tur': tur,
      'eklemeTarihi': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> deleteBelge(int id) async {
    final database = await db;
    await database.delete('belgeler', where: 'id = ?', whereArgs: [id]);
  }

  // Denetim özeti (Raporlar modülü için)
  static Future<Map<String, int>> getDenetimOzeti() async {
    final database = await db;
    final rows = await database.rawQuery('''
      SELECT durum, COUNT(*) as sayi FROM firmalar GROUP BY durum
    ''');
    final Map<String, int> ozet = {
      'NORMAL': 0,
      'GİDİLDİ': 0,
      'GİDİLMEDİ': 0,
      'KİMSE_YOK': 0,
    };
    for (final row in rows) {
      ozet[row['durum'] as String] = row['sayi'] as int;
    }
    return ozet;
  }
}
