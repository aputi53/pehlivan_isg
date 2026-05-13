import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
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
      home: const AnaEkran(),
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

