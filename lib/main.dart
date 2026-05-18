import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:pehlivan_isg/screens/home_screen.dart';
import 'package:pehlivan_isg/screens/security/app_lock_wrapper.dart';
import 'package:pehlivan_isg/pages/ayarlar_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const PehlivanISGApp());
}

class PehlivanISGApp extends StatelessWidget {
  const PehlivanISGApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: ThemeData.light().copyWith(
            scaffoldBackgroundColor: const Color(0xFFF5F5F5),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFE8B84B),
              secondary: Color(0xFFE8B84B),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFF5F5F5),
              elevation: 0,
              iconTheme: IconThemeData(color: Color(0xFF0D1117)),
              titleTextStyle: TextStyle(
                color: Color(0xFF0D1117),
                fontWeight: FontWeight.w700,
                fontSize: 16,
                letterSpacing: 2,
              ),
            ),
            cardColor: const Color(0xFFFFFFFF),
            dividerColor: Colors.black12,
          ),
          darkTheme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: const Color(0xFF0D1117),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFE8B84B),
              secondary: Color(0xFFE8B84B),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF0D1117),
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.white70),
              titleTextStyle: TextStyle(
                color: Color(0xFFE8B84B),
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 4,
              ),
            ),
            cardColor: const Color(0xFF10151F),
            dividerColor: Colors.white12,
          ),
          home: AppLockWrapper(
            child: AnaEkran(),
          ),
        );
      },
    );
  }
}

/* ====================================================
   NOT MODELİ
   ==================================================== */
class FirmaNot {
  final String metin;
  final DateTime zaman;
  final List<String> fotoPaths;

  FirmaNot({
    required this.metin,
    required this.zaman,
    required this.fotoPaths,
  });
}