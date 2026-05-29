import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'database_service.dart';

class BackupService {
  static Future<String> _dbPath() async {
    final dir = await getDatabasesPath();
    return p.join(dir, 'pehlivan_isg.db');
  }

  static String _backupFileName() {
    final now = DateTime.now();
    final y = now.year;
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return 'pehlivan_yedek_$y$m$d.db';
  }

  /// Yedeği kaydeder.
  /// Masaüstünde "Farklı Kaydet" dialogu açar.
  /// Mobilde Downloads klasörüne kaydeder, kaydedilen yolu döner.
  /// Başarılıysa (kaydedilen yol, null) döner; hata olursa exception fırlatır.
  static Future<String?> backup() async {
    final src = await _dbPath();
    if (!File(src).existsSync()) throw Exception('Veritabanı bulunamadı');

    final fname = _backupFileName();

    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Yedeği Kaydet',
        fileName: fname,
      );
      if (savePath == null) return null; // kullanıcı iptal etti
      await File(src).copy(savePath);
      return savePath;
    } else {
      // Android/iOS: Downloads klasörüne kaydet
      final dir = await getExternalStorageDirectory();
      final downloadsPath = dir != null
          ? p.join(dir.path.split('Android').first, 'Download')
          : (await getApplicationDocumentsDirectory()).path;
      final dest = p.join(downloadsPath, fname);
      await File(src).copy(dest);
      return dest;
    }
  }

  /// Yedekten geri yükle.
  /// Kullanıcıdan .db dosyası seçtirip mevcut DB'nin üzerine yazar.
  /// Başarılıysa true döner.
  static Future<bool> restore() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Yedek Dosyası Seç (.db)',
      type: FileType.any,
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return false;
    final srcPath = result.files.first.path;
    if (srcPath == null) return false;

    final dest = await _dbPath();
    await DatabaseService.closeDb();
    await File(srcPath).copy(dest);
    await DatabaseService.db; // yeniden aç
    return true;
  }
}
