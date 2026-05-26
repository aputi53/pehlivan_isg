import 'dart:convert'; // Base64 resmi çözmek için eklendi
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Güvenli hafıza için eklendi
import 'package:pehlivan_isg/pages/denetimler_page.dart';
import 'package:pehlivan_isg/pages/firmalar_page.dart';
import 'package:pehlivan_isg/pages/profil_page.dart';
import 'package:pehlivan_isg/pages/ayarlar_page.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  // SÜREÇ ANALİZİ: Profil havuzuna erişmek için şifreli depolama nesnemiz
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      sharedPreferencesName: 'PehlivanISG_Storage',
    ),
  );

  String _userName = "Yükleniyor...";
  String _userTitle = "Kullanıcı Paneli";
  String? _profileImageBase64;

  @override
  void initState() {
    super.initState();
    _loadDrawerData();
  }

  // Hafızadaki güncel profil verilerini arka planda okuyan fonksiyon
  Future<void> _loadDrawerData() async {
    try {
      final name = await _storage.read(key: "user_name");
      final title = await _storage.read(key: "user_title");
      final image = await _storage.read(key: "user_image_base64");

      if (mounted) {
        setState(() {
          if (name != null && name.isNotEmpty) _userName = name;
          if (title != null && title.isNotEmpty) _userTitle = title;
          _profileImageBase64 = image;
        });
      }
    } catch (e) {
      debugPrint("Drawer veri yükleme hatası: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: const Color(0xFF0D1117),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [

            // 🔷 DİNAMİK ÜST PROFİL ALANI
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF161B22),
              ),
              accountName: Text(
                _userName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
              accountEmail: Text(
                _userTitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 13,
                ),
              ),
              // SÜREÇ ANALİZİ: Resim varsa Base64'ten çözer, yoksa varsayılan ikonu sarı arka planla gösterir
              currentAccountPicture: CircleAvatar(
                backgroundColor: const Color(0xFFE8B84B),
                backgroundImage: _profileImageBase64 != null
                    ? MemoryImage(base64Decode(_profileImageBase64!))
                    : null,
                child: _profileImageBase64 == null
                    ? const Icon(Icons.person, color: Color(0xFF0A0E1A), size: 36)
                    : null,
              ),
            ),

            // 🏠 ANA SAYFA
            ListTile(
              leading: const Icon(Icons.home, color: Colors.white70),
              title: const Text('Ana Sayfa', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
              },
            ),

            // 📋 DENETİMLER
            ListTile(
              leading: const Icon(Icons.assignment, color: Colors.white70),
              title: const Text('Denetimler', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DenetimlerPage(),
                  ),
                );
              },
            ),

            // 🏢 FİRMALAR
            ListTile(
              leading: const Icon(Icons.business, color: Colors.white70),
              title: const Text('Firmalar', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FirmalarPage(),
                  ),
                );
              },
            ),

            // ⚠️ RAMAK KALA (şimdilik pasif)
            ListTile(
              leading: const Icon(Icons.warning, color: Colors.white70),
              title: const Text('Ramak Kala', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
              },
            ),

            const Divider(color: Colors.white12),

            // 👤 PROFİL
            ListTile(
              leading: const Icon(Icons.person_outline, color: Color(0xFFE8B84B)),
              title: const Text('Profil', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                // SÜREÇ ANALİZİ: Profil sayfasından geri dönüldüğünde verileri anında tazelemek için await kullandık
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfilPage(),
                  ),
                );
                _loadDrawerData(); // Profil sayfasında değişiklik yapılıp dönülürse menüyü günceller
              },
            ),

            // ⚙️ AYARLAR
            ListTile(
              leading: const Icon(Icons.settings_outlined, color: Color(0xFFE8B84B)),
              title: const Text('Ayarlar', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AyarlarPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}