import 'package:flutter/material.dart';

class DenetimlerPage extends StatelessWidget {
  const DenetimlerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Denetimler")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [

          Card(
            child: ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green),
              title: Text("Tamamlanan Denetim"),
              subtitle: Text("İnşaat alanı kontrol edildi"),
            ),
          ),

          Card(
            child: ListTile(
              leading: Icon(Icons.warning, color: Colors.orange),
              title: Text("Ramak Kala"),
              subtitle: Text("Elektrik riski tespit edildi"),
            ),
          ),

          Card(
            child: ListTile(
              leading: Icon(Icons.error, color: Colors.red),
              title: Text("Acil Durum"),
              subtitle: Text("Yangın tüpü eksik"),
            ),
          ),
        ],
      ),
    );
  }
}