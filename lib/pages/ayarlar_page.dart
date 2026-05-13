import 'package:flutter/material.dart';

class AyarlarPage extends StatelessWidget {
  const AyarlarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ayarlar")),
      body: ListView(
        children: [

          const ListTile(
            leading: Icon(Icons.notifications),
            title: Text("Bildirimler"),
            subtitle: Text("Uyarı sistemini yönet"),
          ),

          SwitchListTile(
            title: const Text("Bildirimleri Aç"),
            value: true,
            onChanged: (val) {},
          ),

          const ListTile(
            leading: Icon(Icons.lock),
            title: Text("Gizlilik"),
            subtitle: Text("Hesap güvenliği ayarları"),
          ),

          const ListTile(
            leading: Icon(Icons.info),
            title: Text("Uygulama Hakkında"),
            subtitle: Text("Versiyon 1.0.0"),
          ),
        ],
      ),
    );
  }
}