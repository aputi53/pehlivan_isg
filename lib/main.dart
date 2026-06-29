import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:pehlivan_isg/firebase_options.dart';
import 'package:pehlivan_isg/screens/home_screen.dart';
import 'package:pehlivan_isg/screens/security/app_lock_wrapper.dart';
import 'package:pehlivan_isg/services/notification_service.dart';
import 'package:pehlivan_isg/services/theme_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await NotificationService.initialize();
  NotificationService.checkExpiringDocuments();

  runApp(const PehlivanISGApp());
}

// Masaüstünde mobil içeriği ortalar ve genişliği sınırlar.
// Mobil/web'de hiçbir şey değişmez.
class _DesktopShell extends StatelessWidget {
  final Widget child;
  const _DesktopShell({required this.child});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      return Scaffold(
        backgroundColor: AppColors.of(context).bg,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ClipRect(child: child),
          ),
        ),
      );
    }
    return child;
  }
}

class PehlivanISGApp extends StatelessWidget {
  const PehlivanISGApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeConfig>(
      valueListenable: themeService,
      builder: (_, config, __) => MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: const Locale('tr', 'TR'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('tr', 'TR'),
          Locale('en', 'US'),
        ],
        themeMode: config.mode,
        theme: buildThemeData(config.accent, Brightness.light),
        darkTheme: buildThemeData(config.accent, Brightness.dark),
        home: const _DesktopShell(child: AppLockWrapper(child: AnaEkran())),
      ),
    );
  }
}

