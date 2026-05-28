import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:pehlivan_isg/screens/home_screen.dart';
import 'package:pehlivan_isg/screens/security/app_lock_wrapper.dart';
import 'package:pehlivan_isg/services/notification_service.dart';
import 'package:pehlivan_isg/services/theme_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await NotificationService.initialize();
  NotificationService.checkExpiringDocuments();

  runApp(const PehlivanISGApp());
}

class PehlivanISGApp extends StatelessWidget {
  const PehlivanISGApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeConfig>(
      valueListenable: themeService,
      builder: (_, config, __) => MaterialApp(
        debugShowCheckedModeBanner: false,
        themeMode: config.mode,
        theme: buildThemeData(config.accent, Brightness.light),
        darkTheme: buildThemeData(config.accent, Brightness.dark),
        home: AppLockWrapper(child: AnaEkran()),
      ),
    );
  }
}

