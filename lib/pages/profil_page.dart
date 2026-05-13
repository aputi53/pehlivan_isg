import 'package:flutter/material.dart';

class ProfilPage extends StatelessWidget {
  const ProfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profil")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Center(
              child: CircleAvatar(
                radius: 45,
                child: Icon(Icons.person, size: 50),
              ),
            ),

            const SizedBox(height: 20),

            const Text("Ad Soyad",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Text("Aputi"),

            const SizedBox(height: 10),

            const Text("E-posta",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Text("kullanici@isg.com"),

            const SizedBox(height: 10),

            const Text("Departman",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Text("İş Sağlığı ve Güvenliği"),

          ],
        ),
      ),
    );
  }
}