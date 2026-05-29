import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
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

  /// Veritabanını dışa aktar.
  /// Windows/Linux/macOS: "Farklı Kaydet" dialogu açar.
  /// Android/iOS: Paylaşım seçenekleri sunar.
  /// Başarılıysa true döner.
  static Future<bool> backup() async {
    final src = await _dbPath();
    if (!File(src).existsSync()) return false;

    final fname = _backupFileName();

    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Yedeği Kaydet',
        fileName: fname,
      );
      if (savePath == null) return false;
      await File(src).copy(savePath);
      return true;
    } else {
      final temp = await getTemporaryDirectory();
      final dest = p.join(temp.path, fname);
      await File(src).copy(dest);
      await Share.shareXFiles(
        [XFile(dest)],
        subject: 'PehlivanİSG Veritabanı Yedeği',
      );
      return true;
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
