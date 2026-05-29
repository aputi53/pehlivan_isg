import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pehlivan_isg/services/database_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      _initialized = true;
      return;
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const settings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(settings);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  static Future<void> checkExpiringDocuments() async {
    if (!_initialized) await initialize();

    final expiring =
        await DatabaseService.getExpiringBelgeler(daysThreshold: 30);

    for (final belge in expiring) {
      final daysLeft = belge['daysLeft'] as int;
      final baslik = belge['baslik'] as String;
      final calisanAd = belge['calisanAd'] as String;
      final firmaIsim = belge['firmaIsim'] as String;
      final id = belge['id'] as int;
      final tur = belge['tur'] == 'egitim' ? 'Eğitim' : 'Muayene';

      final String body;
      if (daysLeft == 0) {
        body = '$firmaIsim — $calisanAd\n"$baslik" belgesi BUGÜN sona eriyor!';
      } else {
        body =
            '$firmaIsim — $calisanAd\n"$baslik" belgesi $daysLeft gün içinde geçerliliğini yitirecek.';
      }

      await _showNotification(
        id: id,
        title: '⚠️ $tur Belgesi Uyarısı',
        body: body,
      );
    }
  }

  static Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'isg_belge_uyari',
      'İSG Belge Uyarıları',
      channelDescription:
          'Çalışan eğitim ve muayene belgelerinin geçerlilik süresi uyarıları',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(''),
    );

    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(id, title, body, details);
  }
}
