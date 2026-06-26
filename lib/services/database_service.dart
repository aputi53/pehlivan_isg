import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static Database? _db;

  static Future<Database> get db async {
    _db ??= await _init();
    return _db!;
  }

  static Future<void> closeDb() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }

  static Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'pehlivan_isg.db');

    return openDatabase(
      path,
      version: 7,
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
        sgkNo TEXT,
        tehlikeSinifi TEXT,
        uzmanIsim TEXT,
        uzmanUnvan TEXT,
        uzmanBelgeNo TEXT,
        hekimIsim TEXT,
        hekimUnvan TEXT,
        hekimBelgeNo TEXT,
        katipSertifikaNo TEXT,
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

    await db.execute('''
      CREATE TABLE aksiyonlar (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        firmaId INTEGER,
        baslik TEXT NOT NULL,
        aciklama TEXT,
        sonTarih TEXT,
        tamamlandi INTEGER NOT NULL DEFAULT 0,
        olusturmaTarihi TEXT NOT NULL,
        FOREIGN KEY (firmaId) REFERENCES firmalar(id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sertifikalar (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        firmaId INTEGER NOT NULL,
        sertifikaTuru TEXT NOT NULL,
        tehlikeSinifi TEXT NOT NULL,
        ozelKonu TEXT,
        egitimTarihi TEXT NOT NULL,
        egitimTarihi2 TEXT,
        egitimSuresi INTEGER NOT NULL,
        egitimTipi TEXT NOT NULL DEFAULT 'ILK',
        egitimciIsim TEXT,
        egitimciUnvan TEXT,
        uzmanIsim TEXT,
        uzmanUnvan TEXT,
        hekimIsim TEXT,
        hekimUnvan TEXT,
        sertifikaNo TEXT,
        imzaPath TEXT,
        gecerlilikTarihi TEXT,
        katilimcilar TEXT NOT NULL DEFAULT '[]',
        olusturmaTarihi TEXT NOT NULL,
        FOREIGN KEY (firmaId) REFERENCES firmalar(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE egitim_katilim (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        firmaId INTEGER NOT NULL,
        egitimTuru TEXT NOT NULL,
        tehlikeSinifi TEXT,
        ozelRiskler TEXT NOT NULL DEFAULT '[]',
        egitimTarihi TEXT NOT NULL,
        egitimSuresi INTEGER NOT NULL,
        egitimciIsim TEXT,
        egitimciUnvan TEXT,
        hekimIsim TEXT,
        hekimUnvan TEXT,
        katilimcilar TEXT NOT NULL DEFAULT '[]',
        olusturmaTarihi TEXT NOT NULL,
        FOREIGN KEY (firmaId) REFERENCES firmalar(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE personel_havuzu (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tip TEXT NOT NULL,
        isim TEXT NOT NULL,
        unvan TEXT,
        belgeNo TEXT,
        dipNo TEXT,
        aktif INTEGER NOT NULL DEFAULT 1
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

    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS aksiyonlar (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          firmaId INTEGER,
          baslik TEXT NOT NULL,
          aciklama TEXT,
          sonTarih TEXT,
          tamamlandi INTEGER NOT NULL DEFAULT 0,
          olusturmaTarihi TEXT NOT NULL,
          FOREIGN KEY (firmaId) REFERENCES firmalar(id) ON DELETE SET NULL
        )
      ''');
    }

    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sertifikalar (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          firmaId INTEGER NOT NULL,
          sertifikaTuru TEXT NOT NULL,
          tehlikeSinifi TEXT NOT NULL,
          ozelKonu TEXT,
          egitimTarihi TEXT NOT NULL,
          egitimSuresi INTEGER NOT NULL,
          egitimTipi TEXT NOT NULL DEFAULT 'ILK',
          egitimciIsim TEXT,
          egitimciUnvan TEXT,
          gecerlilikTarihi TEXT,
          katilimcilar TEXT NOT NULL DEFAULT '[]',
          olusturmaTarihi TEXT NOT NULL,
          FOREIGN KEY (firmaId) REFERENCES firmalar(id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS egitim_katilim (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          firmaId INTEGER NOT NULL,
          egitimTuru TEXT NOT NULL,
          tehlikeSinifi TEXT,
          ozelRiskler TEXT NOT NULL DEFAULT '[]',
          egitimTarihi TEXT NOT NULL,
          egitimSuresi INTEGER NOT NULL,
          egitimciIsim TEXT,
          egitimciUnvan TEXT,
          hekimIsim TEXT,
          hekimUnvan TEXT,
          katilimcilar TEXT NOT NULL DEFAULT '[]',
          olusturmaTarihi TEXT NOT NULL,
          FOREIGN KEY (firmaId) REFERENCES firmalar(id) ON DELETE CASCADE
        )
      ''');
    }

    if (oldVersion < 7) {
      // firmalar: ISG-Katip ve personel alanları
      await db.execute('ALTER TABLE firmalar ADD COLUMN sgkNo TEXT');
      await db.execute('ALTER TABLE firmalar ADD COLUMN tehlikeSinifi TEXT');
      await db.execute('ALTER TABLE firmalar ADD COLUMN uzmanIsim TEXT');
      await db.execute('ALTER TABLE firmalar ADD COLUMN uzmanUnvan TEXT');
      await db.execute('ALTER TABLE firmalar ADD COLUMN uzmanBelgeNo TEXT');
      await db.execute('ALTER TABLE firmalar ADD COLUMN hekimIsim TEXT');
      await db.execute('ALTER TABLE firmalar ADD COLUMN hekimUnvan TEXT');
      await db.execute('ALTER TABLE firmalar ADD COLUMN hekimBelgeNo TEXT');
      await db.execute('ALTER TABLE firmalar ADD COLUMN katipSertifikaNo TEXT');

      // sertifikalar: 2. tarih, uzman/hekim, sertifika no, imza
      await db.execute('ALTER TABLE sertifikalar ADD COLUMN egitimTarihi2 TEXT');
      await db.execute('ALTER TABLE sertifikalar ADD COLUMN uzmanIsim TEXT');
      await db.execute('ALTER TABLE sertifikalar ADD COLUMN uzmanUnvan TEXT');
      await db.execute('ALTER TABLE sertifikalar ADD COLUMN hekimIsim TEXT');
      await db.execute('ALTER TABLE sertifikalar ADD COLUMN hekimUnvan TEXT');
      await db.execute('ALTER TABLE sertifikalar ADD COLUMN sertifikaNo TEXT');
      await db.execute('ALTER TABLE sertifikalar ADD COLUMN imzaPath TEXT');

      // personel havuzu: uzman ve hekimler listesi
      await db.execute('''
        CREATE TABLE IF NOT EXISTS personel_havuzu (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          tip TEXT NOT NULL,
          isim TEXT NOT NULL,
          unvan TEXT,
          belgeNo TEXT,
          dipNo TEXT,
          aktif INTEGER NOT NULL DEFAULT 1
        )
      ''');
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
      'sgkNo': row['sgkNo'] ?? '',
      'tehlikeSinifi': row['tehlikeSinifi'] ?? '',
      'uzmanIsim': row['uzmanIsim'] ?? '',
      'uzmanUnvan': row['uzmanUnvan'] ?? '',
      'uzmanBelgeNo': row['uzmanBelgeNo'] ?? '',
      'hekimIsim': row['hekimIsim'] ?? '',
      'hekimUnvan': row['hekimUnvan'] ?? '',
      'hekimBelgeNo': row['hekimBelgeNo'] ?? '',
      'katipSertifikaNo': row['katipSertifikaNo'] ?? '',
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

  // SGK sicil no ile firma bul
  static Future<Map<String, dynamic>?> getFirmaBySgkNo(String sgkNo) async {
    if (sgkNo.isEmpty) return null;
    final database = await db;
    final rows = await database.query(
      'firmalar',
      where: 'sgkNo = ?',
      whereArgs: [sgkNo.trim()],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
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

  // ─── TAKVİM ETKİNLİKLERİ ──────────────────────────────

  static Future<List<Map<String, dynamic>>> getTakvimEtkinlikleri() async {
    final database = await db;
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);
    final List<Map<String, dynamic>> result = [];

    // 1. calisan_belgeleri → expiry hesapla
    final cRows = await database.rawQuery('''
      SELECT cb.id, cb.tur, cb.baslik, cb.belgeTarihi, cb.gecerlilikYil,
             c.ad AS calisanAd, f.isim AS firmaIsim, f.id AS firmaId
      FROM calisan_belgeleri cb
      JOIN calisanlar c ON cb.calisanId = c.id
      JOIN firmalar f ON cb.firmaId = f.id
    ''');

    for (final row in cRows) {
      final belgeTarihi = DateTime.parse(row['belgeTarihi'] as String);
      final gecerlilikYil = row['gecerlilikYil'] as int;
      final expiry = DateTime(
        belgeTarihi.year + gecerlilikYil,
        belgeTarihi.month,
        belgeTarihi.day,
      );
      final daysLeft = expiry.difference(todayNorm).inDays;
      result.add({
        'tip': row['tur'] == 'egitim' ? 'Eğitim' : 'Muayene',
        'baslik': row['baslik'],
        'firmaIsim': row['firmaIsim'],
        'firmaId': row['firmaId'],
        'calisanAd': row['calisanAd'],
        'daysLeft': daysLeft,
        'tarih': expiry,
      });
    }

    // 2. belgeler.gecerlilikTarihi
    final bRows = await database.rawQuery('''
      SELECT b.id, b.baslik, b.tur, b.gecerlilikTarihi,
             f.isim AS firmaIsim, f.id AS firmaId
      FROM belgeler b
      JOIN firmalar f ON b.firmaId = f.id
      WHERE b.gecerlilikTarihi IS NOT NULL
    ''');

    for (final row in bRows) {
      final expiry =
          DateTime.parse(row['gecerlilikTarihi'] as String);
      final daysLeft = expiry.difference(todayNorm).inDays;
      result.add({
        'tip': row['tur'] ?? 'Belge',
        'baslik': row['baslik'],
        'firmaIsim': row['firmaIsim'],
        'firmaId': row['firmaId'],
        'calisanAd': null,
        'daysLeft': daysLeft,
        'tarih': expiry,
      });
    }

    result.sort((a, b) =>
        (a['daysLeft'] as int).compareTo(b['daysLeft'] as int));
    return result;
  }

  // ─── AKSİYONLAR ──────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getAksiyonlar() async {
    final database = await db;
    final rows = await database.rawQuery('''
      SELECT a.*, f.isim AS firmaIsim
      FROM aksiyonlar a
      LEFT JOIN firmalar f ON a.firmaId = f.id
      ORDER BY a.tamamlandi ASC, a.sonTarih ASC NULLS LAST
    ''');
    return rows.map((r) => {
          'id': r['id'],
          'firmaId': r['firmaId'],
          'firmaIsim': r['firmaIsim'],
          'baslik': r['baslik'],
          'aciklama': r['aciklama'],
          'sonTarih': r['sonTarih'] != null
              ? DateTime.parse(r['sonTarih'] as String)
              : null,
          'tamamlandi': (r['tamamlandi'] as int) == 1,
          'olusturmaTarihi':
              DateTime.parse(r['olusturmaTarihi'] as String),
        }).toList();
  }

  static Future<int> insertAksiyon({
    int? firmaId,
    required String baslik,
    String? aciklama,
    DateTime? sonTarih,
  }) async {
    final database = await db;
    return database.insert('aksiyonlar', {
      'firmaId': firmaId,
      'baslik': baslik,
      'aciklama': aciklama,
      'sonTarih': sonTarih?.toIso8601String(),
      'tamamlandi': 0,
      'olusturmaTarihi': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> toggleAksiyon(int id, bool tamamlandi) async {
    final database = await db;
    await database.update(
      'aksiyonlar',
      {'tamamlandi': tamamlandi ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> deleteAksiyon(int id) async {
    final database = await db;
    await database.delete('aksiyonlar',
        where: 'id = ?', whereArgs: [id]);
  }

  // ─── SERTİFİKA MODÜLÜ ───────────────────────────────

  static Future<List<Map<String, dynamic>>> getSertifikalar({int? firmaId}) async {
    final database = await db;
    final rows = firmaId != null
        ? await database.query('sertifikalar',
            where: 'firmaId = ?', whereArgs: [firmaId], orderBy: 'egitimTarihi DESC')
        : await database.query('sertifikalar', orderBy: 'egitimTarihi DESC');

    return rows.map((r) => {
      ...r,
      'egitimTarihi': DateTime.parse(r['egitimTarihi'] as String),
      'egitimTarihi2': r['egitimTarihi2'] != null
          ? DateTime.parse(r['egitimTarihi2'] as String)
          : null,
      'gecerlilikTarihi': r['gecerlilikTarihi'] != null
          ? DateTime.parse(r['gecerlilikTarihi'] as String)
          : null,
      'olusturmaTarihi': DateTime.parse(r['olusturmaTarihi'] as String),
      'katilimcilar': jsonDecode(r['katilimcilar'] as String) as List<dynamic>,
    }).toList();
  }

  static Future<int> insertSertifika({
    required int firmaId,
    required String sertifikaTuru,
    required String tehlikeSinifi,
    String? ozelKonu,
    required DateTime egitimTarihi,
    DateTime? egitimTarihi2,
    required int egitimSuresi,
    String egitimTipi = 'ILK',
    String? egitimciIsim,
    String? egitimciUnvan,
    String? uzmanIsim,
    String? uzmanUnvan,
    String? hekimIsim,
    String? hekimUnvan,
    String? sertifikaNo,
    String? imzaPath,
    DateTime? gecerlilikTarihi,
    List<Map<String, dynamic>> katilimcilar = const [],
  }) async {
    final database = await db;
    return database.insert('sertifikalar', {
      'firmaId': firmaId,
      'sertifikaTuru': sertifikaTuru,
      'tehlikeSinifi': tehlikeSinifi,
      'ozelKonu': ozelKonu,
      'egitimTarihi': egitimTarihi.toIso8601String(),
      'egitimTarihi2': egitimTarihi2?.toIso8601String(),
      'egitimSuresi': egitimSuresi,
      'egitimTipi': egitimTipi,
      'egitimciIsim': egitimciIsim,
      'egitimciUnvan': egitimciUnvan,
      'uzmanIsim': uzmanIsim,
      'uzmanUnvan': uzmanUnvan,
      'hekimIsim': hekimIsim,
      'hekimUnvan': hekimUnvan,
      'sertifikaNo': sertifikaNo,
      'imzaPath': imzaPath,
      'gecerlilikTarihi': gecerlilikTarihi?.toIso8601String(),
      'katilimcilar': jsonEncode(katilimcilar),
      'olusturmaTarihi': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> updateSertifika(int id, Map<String, dynamic> fields) async {
    final database = await db;
    final data = Map<String, dynamic>.from(fields);
    for (final key in ['egitimTarihi', 'egitimTarihi2', 'gecerlilikTarihi']) {
      if (data[key] is DateTime) {
        data[key] = (data[key] as DateTime).toIso8601String();
      }
    }
    if (data['katilimcilar'] is List) {
      data['katilimcilar'] = jsonEncode(data['katilimcilar']);
    }
    await database.update('sertifikalar', data, where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> deleteSertifika(int id) async {
    final database = await db;
    await database.delete('sertifikalar', where: 'id = ?', whereArgs: [id]);
  }

  // ─── PERSONEL HAVUZU ─────────────────────────────────

  static Future<List<Map<String, dynamic>>> getPersonelHavuzu({String? tip}) async {
    final database = await db;
    final rows = tip != null
        ? await database.query('personel_havuzu',
            where: 'tip = ? AND aktif = 1', whereArgs: [tip], orderBy: 'isim COLLATE NOCASE ASC')
        : await database.query('personel_havuzu',
            where: 'aktif = 1', orderBy: 'tip ASC, isim COLLATE NOCASE ASC');
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  static Future<int> insertPersonel({
    required String tip,
    required String isim,
    String? unvan,
    String? belgeNo,
    String? dipNo,
  }) async {
    final database = await db;
    return database.insert('personel_havuzu', {
      'tip': tip,
      'isim': isim,
      'unvan': unvan,
      'belgeNo': belgeNo,
      'dipNo': dipNo,
      'aktif': 1,
    });
  }

  static Future<void> updatePersonel(int id, Map<String, dynamic> fields) async {
    final database = await db;
    await database.update('personel_havuzu', fields, where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> deletePersonel(int id) async {
    final database = await db;
    await database.delete('personel_havuzu', where: 'id = ?', whereArgs: [id]);
  }

  // ─── FİRMA ISG-KATİP BİLGİLERİ ──────────────────────

  static Future<void> updateFirmaKatipBilgi(int firmaId, {
    String? sgkNo,
    String? tehlikeSinifi,
    String? uzmanIsim,
    String? uzmanUnvan,
    String? uzmanBelgeNo,
    String? hekimIsim,
    String? hekimUnvan,
    String? hekimBelgeNo,
    String? katipSertifikaNo,
  }) async {
    final database = await db;
    final data = <String, dynamic>{};
    if (sgkNo != null) data['sgkNo'] = sgkNo;
    if (tehlikeSinifi != null) data['tehlikeSinifi'] = tehlikeSinifi;
    if (uzmanIsim != null) data['uzmanIsim'] = uzmanIsim;
    if (uzmanUnvan != null) data['uzmanUnvan'] = uzmanUnvan;
    if (uzmanBelgeNo != null) data['uzmanBelgeNo'] = uzmanBelgeNo;
    if (hekimIsim != null) data['hekimIsim'] = hekimIsim;
    if (hekimUnvan != null) data['hekimUnvan'] = hekimUnvan;
    if (hekimBelgeNo != null) data['hekimBelgeNo'] = hekimBelgeNo;
    if (katipSertifikaNo != null) data['katipSertifikaNo'] = katipSertifikaNo;
    if (data.isEmpty) return;
    await database.update('firmalar', data, where: 'id = ?', whereArgs: [firmaId]);
  }

  // ─── EĞİTİM KATILIM MODÜLÜ ──────────────────────────

  static Future<List<Map<String, dynamic>>> getEgitimKatilimlar({int? firmaId}) async {
    final database = await db;
    final rows = firmaId != null
        ? await database.query('egitim_katilim',
            where: 'firmaId = ?', whereArgs: [firmaId], orderBy: 'egitimTarihi DESC')
        : await database.query('egitim_katilim', orderBy: 'egitimTarihi DESC');

    return rows.map((r) => {
      ...r,
      'egitimTarihi': DateTime.parse(r['egitimTarihi'] as String),
      'olusturmaTarihi': DateTime.parse(r['olusturmaTarihi'] as String),
      'ozelRiskler': jsonDecode(r['ozelRiskler'] as String) as List<dynamic>,
      'katilimcilar': jsonDecode(r['katilimcilar'] as String) as List<dynamic>,
    }).toList();
  }

  static Future<int> insertEgitimKatilim({
    required int firmaId,
    required String egitimTuru,
    String? tehlikeSinifi,
    List<String> ozelRiskler = const [],
    required DateTime egitimTarihi,
    required int egitimSuresi,
    String? egitimciIsim,
    String? egitimciUnvan,
    String? hekimIsim,
    String? hekimUnvan,
    List<Map<String, dynamic>> katilimcilar = const [],
  }) async {
    final database = await db;
    return database.insert('egitim_katilim', {
      'firmaId': firmaId,
      'egitimTuru': egitimTuru,
      'tehlikeSinifi': tehlikeSinifi,
      'ozelRiskler': jsonEncode(ozelRiskler),
      'egitimTarihi': egitimTarihi.toIso8601String(),
      'egitimSuresi': egitimSuresi,
      'egitimciIsim': egitimciIsim,
      'egitimciUnvan': egitimciUnvan,
      'hekimIsim': hekimIsim,
      'hekimUnvan': hekimUnvan,
      'katilimcilar': jsonEncode(katilimcilar),
      'olusturmaTarihi': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> deleteEgitimKatilim(int id) async {
    final database = await db;
    await database.delete('egitim_katilim', where: 'id = ?', whereArgs: [id]);
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
