import 'package:flutter/material.dart';
import 'package:pehlivan_isg/pages/denetimler_page.dart';
import 'package:pehlivan_isg/pages/profil_page.dart';
import 'package:pehlivan_isg/pages/ayarlar_page.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: const Color(0xFF0D1117),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [

            // 🔷 ÜST PROFİL ALANI
            const UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xFF161B22),
              ),
              accountName: Text("Abdurrahman Pehlivan"),
              accountEmail: Text("Kullanıcı Paneli"),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.amber,
                child: Icon(Icons.person, color: Colors.black),
              ),
            ),

            // 🏠 ANA SAYFA
            ListTile(
              leading: const Icon(Icons.home, color: Colors.white70),
              title: const Text('Ana Sayfa',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
              },
            ),

            // 📋 DENETİMLER
            ListTile(
              leading: const Icon(Icons.assignment, color: Colors.white70),
              title: const Text('Denetimler',
                  style: TextStyle(color: Colors.white)),
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

            // ⚠️ RAMAK KALA (şimdilik pasif)
            ListTile(
              leading: const Icon(Icons.warning, color: Colors.white70),
              title: const Text('Ramak Kala',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
              },
            ),

            const Divider(color: Colors.white12),

            // 👤 PROFİL
            ListTile(
              leading: const Icon(Icons.person_outline, color: Colors.amber),
              title: const Text('Profil',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfilPage(),
                  ),
                );
              },
            ),

            // ⚙️ AYARLAR
            ListTile(
              leading: const Icon(Icons.settings_outlined, color: Colors.amber),
              title: const Text('Ayarlar',
                  style: TextStyle(color: Colors.white)),
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