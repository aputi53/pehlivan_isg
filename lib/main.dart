import 'package:flutter/material.dart';
import 'package:pehlivan_isg/screens/home_screen.dart';
import 'package:pehlivan_isg/screens/security/app_lock_wrapper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0D1117),
          elevation: 0,
        ),
      ),
      home: AppLockWrapper(
        // ÇÖZÜM: 'const' kelimesini buradan kaldırdık, çünkü AnaEkran dinamik veriler içerebilir.
        child: AnaEkran(),
      ),
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