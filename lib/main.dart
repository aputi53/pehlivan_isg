import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:pehlivan_isg/screens/home_screen.dart';
import 'package:pehlivan_isg/screens/security/app_lock_wrapper.dart';
import 'package:pehlivan_isg/services/notification_service.dart';

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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE8B84B),
          secondary: Color(0xFFE8B84B),
        ),
      ),

      home: AppLockWrapper(
        child: AnaEkran(),
      ),
    );
  }
}

