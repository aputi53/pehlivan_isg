import 'package:flutter/material.dart';

import 'saha_denetim_screen.dart';
import '../pages/raporlar_page.dart';
import '../widgets/app_drawer.dart';

class AnaEkran extends StatelessWidget {
  const AnaEkran({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      drawer: const AppDrawer(),
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 0.5),

              // ANA LOGO
              Center(
                child: Image.asset(
                  'assets/logo.png',
                  width: 500,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.error_outline,
                        color: Colors.red, size: 50);
                  },
                ),
              ),

              const SizedBox(height: 10),

              /* ---------- ANA KART ---------- */
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 23, horizontal: 24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1C2333), Color(0xFF161B22)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.50),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:Colors.amber.withValues(alpha: 0.06),
                      blurRadius: 30,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Center(
                        child: Image.asset(
                          'assets/logo_sari.png',
                          width: 75,
                          height: 75,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.shield_outlined,
                              color: Colors.amber.withValues(alpha: 0.38),
                              size: 50,
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(width: 25),

                    Expanded(
                      flex: 2,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            "İSG",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Colors.amber,
                              letterSpacing: 2,
                            ),
                          ),
                          const Text(
                            "YÖNETİM",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            "MODÜLLERİ",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: 45,
                            height: 4,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.amber.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              /* ---------- MODÜLLER BAŞLIĞI ---------- */
              Row(
                children: [
                  Container(
                    width: 3,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "MODÜLLER",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white60,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              _ModulKart(
                baslik: "Saha Denetim",
                aciklama: "Grup ve firma bazlı saha ziyaret takibi",
                icon: Icons.location_on_outlined,
                renk: Colors.amber,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SahaDenetimScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              _ModulKart(
                baslik: "Raporlar",
                aciklama: "Denetim sonuçları ve istatistikler",
                icon: Icons.bar_chart_outlined,
                renk: Colors.blueAccent,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RaporlarPage()),
                  );
                },
              ),
              const SizedBox(height: 10),
              _ModulKart(
                baslik: "Belgeler",
                aciklama: "İSG dökümanları ve sertifikalar",
                icon: Icons.folder_outlined,
                renk: Colors.purpleAccent,
                onTap: () {},
                pasif: true,
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

/* ---------- MODÜL KART WIDGET ---------- */
class _ModulKart extends StatelessWidget {
  final String baslik;
  final String aciklama;
  final IconData icon;
  final Color renk;
  final VoidCallback onTap;
  final bool pasif;

  const _ModulKart({
    required this.baslik,
    required this.aciklama,
    required this.icon,
    required this.renk,
    required this.onTap,
    this.pasif = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: pasif
                ? Colors.grey.withValues(alpha:0.12)
                : renk.withValues(alpha:0.35),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: renk.withValues(alpha:pasif ? 0.06 : 0.13),
                borderRadius: BorderRadius.circular(12),
              ),
              child:
              Icon(icon, color: pasif ? Colors.grey[600] : renk, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        baslik,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: pasif ? Colors.grey[600] : Colors.white,
                        ),
                      ),
                      if (pasif) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha:0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "Yakında",
                            style:
                            TextStyle(fontSize: 10, color: Colors.grey[600]),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    aciklama,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: pasif ? Colors.grey[800] : Colors.grey[500],
            ),
          ],
        ),
      ),
    );
  }
}