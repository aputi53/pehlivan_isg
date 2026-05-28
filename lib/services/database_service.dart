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
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) => db.execute('PRAGMA foreign_keys = ON'),
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
        grupId INTEGER,
        isim TEXT NOT NULL,
        telefon TEXT,
        mail TEXT,
        durum TEXT NOT NULL DEFAULT 'NORMAL',
        ziyaretTarihi TEXT,
        egitimGecerlilikYil INTEGER DEFAULT 1,
        muayeneGecerlilikYil INTEGER DEFAULT 1,
        evrakGecerlilikYil INTEGER DEFAULT 1,
        FOREIGN KEY (grupId) REFERENCES gruplar(id) ON DELETE SET NULL
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
        calisanId INTEGER,
        baslik TEXT NOT NULL,
        dosyaYolu TEXT NOT NULL,
        tur TEXT NOT NULL DEFAULT 'Diğer',
        eklemeTarihi TEXT NOT NULL,
        gecerlilikTarihi TEXT,
        FOREIGN KEY (firmaId) REFERENCES firmalar(id) ON DELETE CASCADE,
        FOREIGN KEY (calisanId) REFERENCES calisanlar(id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE calisanlar (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        firmaId INTEGER NOT NULL,
        ad TEXT NOT NULL,
        pozisyon TEXT,
        FOREIGN KEY (firmaId) REFERENCES firmalar(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE calisan_belgeleri (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        calisanId INTEGER NOT NULL,
        firmaId INTEGER NOT NULL,
        tur TEXT NOT NULL,
        baslik TEXT NOT NULL,
        belgeTarihi TEXT NOT NULL,
        gecerlilikYil INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (calisanId) REFERENCES calisanlar(id) ON DELETE CASCADE
      )
    ''');

    // Onboarding
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

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('PRAGMA foreign_keys = OFF');

      await db.execute('''
        CREATE TABLE firmalar_v2 (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          grupId INTEGER,
          isim TEXT NOT NULL,
          telefon TEXT,
          mail TEXT,
          durum TEXT NOT NULL DEFAULT 'NORMAL',
          ziyaretTarihi TEXT,
          FOREIGN KEY (grupId) REFERENCES gruplar(id) ON DELETE SET NULL
        )
      ''');
      await db.execute('''
        INSERT INTO firmalar_v2 (id, grupId, isim, telefon, mail, durum)
        SELECT id, grupId, isim, telefon, mail, durum FROM firmalar
      ''');
      await db.execute('DROP TABLE firmalar');
      await db.execute('ALTER TABLE firmalar_v2 RENAME TO firmalar');
      await db.execute('ALTER TABLE belgeler ADD COLUMN gecerlilikTarihi TEXT');

      await db.execute('PRAGMA foreign_keys = ON');
    }

    if (oldVersion < 3) {
      await db.execute('ALTER TABLE firmalar ADD COLUMN egitimGecerlilikYil INTEGER DEFAULT 1');
      await db.execute('ALTER TABLE firmalar ADD COLUMN muayeneGecerlilikYil INTEGER DEFAULT 1');
      await db.execute('ALTER TABLE firmalar ADD COLUMN evrakGecerlilikYil INTEGER DEFAULT 1');


      await db.execute('''
        CREATE TABLE IF NOT EXISTS calisanlar (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          firmaId INTEGER NOT NULL,
          ad TEXT NOT NULL,
          pozisyon TEXT,
          FOREIGN KEY (firmaId) REFERENCES firmalar(id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS calisan_belgeleri (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          calisanId INTEGER NOT NULL,
          firmaId INTEGER NOT NULL,
          tur TEXT NOT NULL,
          baslik TEXT NOT NULL,
          belgeTarihi TEXT NOT NULL,
          gecerlilikYil INTEGER NOT NULL DEFAULT 1,
          FOREIGN KEY (calisanId) REFERENCES calisanlar(id) ON DELETE CASCADE
        )
      ''');
    }

    if (oldVersion < 4) {
      await db.execute('ALTER TABLE belgeler ADD COLUMN calisanId INTEGER');
    }
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
    // ON DELETE SET NULL → firmalar grupsuz kalır, silinmez
    await database.delete('gruplar', where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<String>> getGrupAdlari() async {
    final database = await db;
    final rows = await database.query('gruplar', columns: ['id', 'grupAdi'], orderBy: 'grupAdi ASC');
    return rows.map((r) => r['grupAdi'] as String).toList();
  }

  static Future<List<Map<String, dynamic>>> getGruplarSimple() async {
    final database = await db;
    final rows = await database.query('gruplar', columns: ['id', 'grupAdi', 'tarih'], orderBy: 'grupAdi ASC');
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
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
        'ziyaretTarihi': row['ziyaretTarihi'] != null
            ? DateTime.parse(row['ziyaretTarihi'] as String)
            : null,
        'egitimGecerlilikYil': (row['egitimGecerlilikYil'] as int?) ?? 1,
        'muayeneGecerlilikYil': (row['muayeneGecerlilikYil'] as int?) ?? 1,
        'evrakGecerlilikYil': (row['evrakGecerlilikYil'] as int?) ?? 1,
        'notlar': notlar,
        'raporlar': raporlar,
        'belgeler': belgeler,
      });
    }
    return result;
  }

  // Tüm firmalar (Firma Paneli için) — grup adıyla birlikte
  static Future<List<Map<String, dynamic>>> getAllFirmalar() async {
    final database = await db;
    final rows = await database.rawQuery('''
      SELECT f.*, g.grupAdi
      FROM firmalar f
      LEFT JOIN gruplar g ON f.grupId = g.id
      ORDER BY f.isim COLLATE NOCASE ASC
    ''');
    return rows.map((row) => {
      'id': row['id'],
      'grupId': row['grupId'],
      'grupAdi': row['grupAdi'],
      'isim': row['isim'],
      'telefon': row['telefon'] ?? '',
      'mail': row['mail'] ?? '',
      'durum': row['durum'],
      'ziyaretTarihi': row['ziyaretTarihi'] != null
          ? DateTime.parse(row['ziyaretTarihi'] as String)
          : null,
    }).toList();
  }

  static Future<Map<String, dynamic>?> getFirmaById(int id) async {
    final database = await db;
    final rows = await database.rawQuery('''
      SELECT f.*, g.grupAdi
      FROM firmalar f
      LEFT JOIN gruplar g ON f.grupId = g.id
      WHERE f.id = ?
    ''', [id]);
    if (rows.isEmpty) return null;
    final row = rows.first;
    final notlar = await getNotlar(id);
    final raporlar = await getGorselRaporlar(id);
    final belgeler = await getBelgeler(id);
    return {
      'id': row['id'],
      'grupId': row['grupId'],
      'grupAdi': row['grupAdi'],
      'isim': row['isim'],
      'telefon': row['telefon'] ?? '',
      'mail': row['mail'] ?? '',
      'durum': row['durum'],
      'ziyaretTarihi': row['ziyaretTarihi'] != null
          ? DateTime.parse(row['ziyaretTarihi'] as String)
          : null,
      'egitimGecerlilikYil': (row['egitimGecerlilikYil'] as int?) ?? 1,
      'muayeneGecerlilikYil': (row['muayeneGecerlilikYil'] as int?) ?? 1,
      'evrakGecerlilikYil': (row['evrakGecerlilikYil'] as int?) ?? 1,
      'notlar': notlar,
      'raporlar': raporlar,
      'belgeler': belgeler,
    };
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

  // Grupsuz firma oluştur (Firma Paneli için)
  static Future<int> insertFirmaStandalone(
      String isim, String telefon, String mail) async {
    final database = await db;
    return database.insert('firmalar', {
      'grupId': null,
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

  static Future<void> assignFirmaToGrup(int firmaId, int? grupId) async {
    final database = await db;
    await database.update(
      'firmalar',
      {'grupId': grupId},
      where: 'id = ?',
      whereArgs: [firmaId],
    );
  }

  static Future<void> updateFirmaZiyaretTarihi(
      int firmaId, DateTime? tarih) async {
    final database = await db;
    await database.update(
      'firmalar',
      {'ziyaretTarihi': tarih?.toIso8601String()},
      where: 'id = ?',
      whereArgs: [firmaId],
    );
  }

  static Future<void> deleteFirma(int id) async {
    final database = await db;
    await database.delete('firmalar', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> deleteAllFirmalar() async {
    final database = await db;
    await database.delete('firmalar');
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
      final paths =
          (jsonDecode(row['fotoPaths'] as String) as List).cast<String>();
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
      final paths =
          (jsonDecode(row['fotoPaths'] as String) as List).cast<String>();
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

  static Future<List<Map<String, dynamic>>> getAllGorselRaporlar() async {
    final database = await db;
    final rows = await database.rawQuery('''
      SELECT gr.*, f.isim as firmaIsim
      FROM gorsel_raporlar gr
      JOIN firmalar f ON gr.firmaId = f.id
      ORDER BY gr.tarih DESC
    ''');
    return rows.map((row) {
      final paths =
          (jsonDecode(row['fotoPaths'] as String) as List).cast<String>();
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
    final rows = await database.rawQuery('''
      SELECT b.*, c.ad AS calisanAd
      FROM belgeler b
      LEFT JOIN calisanlar c ON b.calisanId = c.id
      WHERE b.firmaId = ?
      ORDER BY b.eklemeTarihi DESC
    ''', [firmaId]);
    return rows.map((row) => {
          'id': row['id'],
          'firmaId': row['firmaId'],
          'calisanId': row['calisanId'],
          'calisanAd': row['calisanAd'],
          'baslik': row['baslik'],
          'dosyaYolu': row['dosyaYolu'],
          'tur': row['tur'],
          'eklemeTarihi': DateTime.parse(row['eklemeTarihi'] as String),
          'gecerlilikTarihi': row['gecerlilikTarihi'] != null
              ? DateTime.parse(row['gecerlilikTarihi'] as String)
              : null,
        }).toList();
  }

  static Future<List<Map<String, dynamic>>> getBelgelerByCalisan(
      int calisanId) async {
    final database = await db;
    final rows = await database.query(
      'belgeler',
      where: 'calisanId = ?',
      whereArgs: [calisanId],
      orderBy: 'eklemeTarihi DESC',
    );
    return rows.map((row) => {
          'id': row['id'],
          'firmaId': row['firmaId'],
          'calisanId': row['calisanId'],
          'baslik': row['baslik'],
          'dosyaYolu': row['dosyaYolu'],
          'tur': row['tur'],
          'eklemeTarihi': DateTime.parse(row['eklemeTarihi'] as String),
          'gecerlilikTarihi': row['gecerlilikTarihi'] != null
              ? DateTime.parse(row['gecerlilikTarihi'] as String)
              : null,
        }).toList();
  }

  static Future<int> insertBelge({
    required int firmaId,
    required String baslik,
    required String dosyaYolu,
    required String tur,
    DateTime? gecerlilikTarihi,
    int? calisanId,
  }) async {
    final database = await db;
    return database.insert('belgeler', {
      'firmaId': firmaId,
      'baslik': baslik,
      'dosyaYolu': dosyaYolu,
      'tur': tur,
      'eklemeTarihi': DateTime.now().toIso8601String(),
      'gecerlilikTarihi': gecerlilikTarihi?.toIso8601String(),
      'calisanId': calisanId,
    });
  }

  static Future<void> deleteBelge(int id) async {
    final database = await db;
    await database.delete('belgeler', where: 'id = ?', whereArgs: [id]);
  }

  // ─── ÇALIŞANLAR ────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getCalisanlar(int firmaId) async {
    final database = await db;
    final rows = await database.query(
      'calisanlar',
      where: 'firmaId = ?',
      whereArgs: [firmaId],
      orderBy: 'ad COLLATE NOCASE ASC',
    );

    final List<Map<String, dynamic>> result = [];
    for (final row in rows) {
      final calisanId = row['id'] as int;
      final egitimCount = Sqflite.firstIntValue(await database.rawQuery(
        "SELECT COUNT(*) FROM calisan_belgeleri WHERE calisanId = ? AND tur = 'egitim'",
        [calisanId],
      )) ?? 0;
      final muayeneCount = Sqflite.firstIntValue(await database.rawQuery(
        "SELECT COUNT(*) FROM calisan_belgeleri WHERE calisanId = ? AND tur = 'muayene'",
        [calisanId],
      )) ?? 0;
      result.add({
        'id': calisanId,
        'firmaId': row['firmaId'],
        'ad': row['ad'],
        'pozisyon': row['pozisyon'],
        'egitimCount': egitimCount,
        'muayeneCount': muayeneCount,
      });
    }
    return result;
  }

  static Future<int> insertCalisan(
      int firmaId, String ad, String? pozisyon) async {
    final database = await db;
    return database.insert('calisanlar', {
      'firmaId': firmaId,
      'ad': ad,
      'pozisyon': pozisyon,
    });
  }

  static Future<void> deleteCalisan(int id) async {
    final database = await db;
    await database.delete('calisanlar', where: 'id = ?', whereArgs: [id]);
  }

  // ─── ÇALIŞAN BELGELERİ ────────────────────────────

  static Future<List<Map<String, dynamic>>> getCalisanBelgeleri(
      int calisanId) async {
    final database = await db;
    final rows = await database.query(
      'calisan_belgeleri',
      where: 'calisanId = ?',
      whereArgs: [calisanId],
      orderBy: 'belgeTarihi DESC',
    );
    return rows.map((row) => {
          'id': row['id'],
          'calisanId': row['calisanId'],
          'firmaId': row['firmaId'],
          'tur': row['tur'],
          'baslik': row['baslik'],
          'belgeTarihi': row['belgeTarihi'] as String,
          'gecerlilikYil': row['gecerlilikYil'],
        }).toList();
  }

  static Future<int> insertCalisanBelge({
    required int calisanId,
    required int firmaId,
    required String tur,
    required String baslik,
    required DateTime belgeTarihi,
    required int gecerlilikYil,
  }) async {
    final database = await db;
    return database.insert('calisan_belgeleri', {
      'calisanId': calisanId,
      'firmaId': firmaId,
      'tur': tur,
      'baslik': baslik,
      'belgeTarihi': belgeTarihi.toIso8601String(),
      'gecerlilikYil': gecerlilikYil,
    });
  }

  static Future<void> deleteCalisanBelge(int id) async {
    final database = await db;
    await database.delete('calisan_belgeleri',
        where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> updateFirmaGecerlilikAyarlari(
      int firmaId, int egitim, int muayene, int evrak) async {
    final database = await db;
    await database.update(
      'firmalar',
      {
        'egitimGecerlilikYil': egitim,
        'muayeneGecerlilikYil': muayene,
        'evrakGecerlilikYil': evrak,
      },
      where: 'id = ?',
      whereArgs: [firmaId],
    );
  }

  static Future<List<Map<String, dynamic>>> getExpiringBelgeler({
    int daysThreshold = 30,
  }) async {
    final database = await db;
    final rows = await database.rawQuery('''
      SELECT cb.id, cb.tur, cb.baslik, cb.belgeTarihi, cb.gecerlilikYil,
             c.ad AS calisanAd, f.isim AS firmaIsim
      FROM calisan_belgeleri cb
      JOIN calisanlar c ON cb.calisanId = c.id
      JOIN firmalar f ON cb.firmaId = f.id
    ''');

    final today = DateTime.now();
    final todayNorm =
        DateTime(today.year, today.month, today.day);
    final List<Map<String, dynamic>> result = [];

    for (final row in rows) {
      final belgeTarihi =
          DateTime.parse(row['belgeTarihi'] as String);
      final gecerlilikYil = row['gecerlilikYil'] as int;
      final expiry = DateTime(
        belgeTarihi.year + gecerlilikYil,
        belgeTarihi.month,
        belgeTarihi.day,
      );
      final daysLeft = expiry.difference(todayNorm).inDays;

      if (daysLeft >= 0 && daysLeft <= daysThreshold) {
        result.add({
          'id': row['id'],
          'tur': row['tur'],
          'baslik': row['baslik'],
          'calisanAd': row['calisanAd'],
          'firmaIsim': row['firmaIsim'],
          'daysLeft': daysLeft,
          'expiry': expiry,
        });
      }
    }
    return result;
  }

  // ─── RAPORLAR MODÜLü ────────────────────────────────

  static Future<Map<String, int>> getDenetimOzeti() async {
    final database = await db;
    final rows = await database
        .rawQuery('SELECT durum, COUNT(*) as sayi FROM firmalar GROUP BY durum');
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
