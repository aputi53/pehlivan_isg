import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:pehlivan_isg/pages/aksiyon_page.dart';
import 'package:pehlivan_isg/pages/firmalar_page.dart';
import 'package:pehlivan_isg/pages/raporlar_page.dart';
import 'package:pehlivan_isg/pages/takvim_page.dart';
import 'package:pehlivan_isg/screens/saha_denetim_screen.dart';
import 'package:pehlivan_isg/services/database_service.dart';
import 'package:pehlivan_isg/services/theme_service.dart';
import 'package:pehlivan_isg/widgets/app_drawer.dart';

class AnaEkran extends StatefulWidget {
  const AnaEkran({super.key});

  @override
  State<AnaEkran> createState() => _AnaEkranState();
}

class _AnaEkranState extends State<AnaEkran> {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      sharedPreferencesName: 'PehlivanISG_Storage',
    ),
  );

  String _kullaniciAdi = '';
  int _firmaCount = 0;
  int _surenDolan = 0;
  int _bekleyenGorev = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final name = await _storage.read(key: 'user_name');
    final firmalar = await DatabaseService.getAllFirmalar();
    final expiring =
        await DatabaseService.getExpiringBelgeler(daysThreshold: 30);
    final aksiyonlar = await DatabaseService.getAksiyonlar();
    final bekleyen =
        aksiyonlar.where((a) => !(a['tamamlandi'] as bool)).length;

    if (mounted) {
      setState(() {
        _kullaniciAdi = name ?? '';
        _firmaCount = firmalar.length;
        _surenDolan = expiring.length;
        _bekleyenGorev = bekleyen;
      });
    }
  }

  String _selamlama() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Günaydın';
    if (h < 18) return 'İyi günler';
    return 'İyi akşamlar';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: _buildAppBar(context),
      body: RefreshIndicator(
        color: AppColors.of(context).accent,
        backgroundColor: AppColors.of(context).card,
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── LOGO ────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Image.asset(
                  'assets/logo.png',
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                  errorBuilder: (_, __, ___) => const SizedBox(height: 70),
                ),
              ),
              const SizedBox(height: 12),

              // ── CANLI İSTATİSTİK KARTI ──────────────
              _StatsCard(
                firmaCount: _firmaCount,
                surenDolan: _surenDolan,
                bekleyenGorev: _bekleyenGorev,
                onTapSuren: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TakvimPage()),
                ),
                onTapGorev: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AksiyanPage()),
                ),
                onTapFirma: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FirmalarPage()),
                ),
              ),
              const SizedBox(height: 20),

              // ── MODÜLLER BAŞLIĞI ─────────────────────
              Row(
                children: [
                  Container(
                    width: 3,
                    height: 15,
                    decoration: BoxDecoration(
                      color: AppColors.of(context).accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "MODÜLLER",
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.of(context).textMuted,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── 2 KOLONLU MODÜl GRİDİ ───────────────
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.1,
                children: [
                  _ModulKart(
                    baslik: "Saha Denetim",
                    aciklama: "Grup & firma ziyaret takibi",
                    icon: Icons.location_on_outlined,
                    renk: AppColors.of(context).accent,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => SahaDenetimScreen()),
                    ),
                  ),
                  _ModulKart(
                    baslik: "Firmalar",
                    aciklama: "Çalışan, belge & not yönetimi",
                    icon: Icons.business_outlined,
                    renk: const Color(0xFF4FC3F7),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const FirmalarPage()),
                    ),
                  ),
                  _ModulKart(
                    baslik: "Takvim",
                    aciklama: "Yaklaşan son tarihler",
                    icon: Icons.calendar_month_outlined,
                    renk: const Color(0xFF81C784),
                    badge: _surenDolan > 0 ? '$_surenDolan' : null,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const TakvimPage()),
                    ),
                  ),
                  _ModulKart(
                    baslik: "Görev Takibi",
                    aciklama: "Aksiyon ve hatırlatmalar",
                    icon: Icons.task_alt_outlined,
                    renk: const Color(0xFFFFB74D),
                    badge:
                        _bekleyenGorev > 0 ? '$_bekleyenGorev' : null,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AksiyanPage()),
                    ),
                  ),
                  _ModulKart(
                    baslik: "Raporlar",
                    aciklama: "Denetim özetleri & görseller",
                    icon: Icons.bar_chart_outlined,
                    renk: const Color(0xFFCE93D8),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RaporlarPage()),
                    ),
                  ),
                  _ModulKart(
                    baslik: "İSG Katip",
                    aciklama: "Bakanlık sistemi girişi",
                    icon: Icons.open_in_browser_outlined,
                    renk: const Color(0xFF80DEEA),
                    isExternal: true,
                    onTap: () async {
                      final uri = Uri.parse(
                          'https://isgkatip.csgb.gov.tr');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.of(context).card,
      elevation: 0,
      titleSpacing: 4,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: Icon(Icons.menu_rounded, color: AppColors.of(ctx).text),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: Row(
        children: [
          Image.asset(
            'assets/logo_sari.png',
            height: 30,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.shield_outlined,
              color: Colors.amber,
              size: 26,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _selamlama(),
                  style: TextStyle(
                      color: AppColors.of(context).textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.normal),
                ),
                Text(
                  _kullaniciAdi.isNotEmpty
                      ? _kullaniciAdi
                      : 'PehlivanİSG',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.of(context).text,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh_outlined,
              color: AppColors.of(context).textMuted, size: 20),
          onPressed: _loadStats,
          tooltip: "Yenile",
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// CANLI İSTATİSTİK KARTI
// ─────────────────────────────────────────────

class _StatsCard extends StatelessWidget {
  final int firmaCount;
  final int surenDolan;
  final int bekleyenGorev;
  final VoidCallback onTapFirma;
  final VoidCallback onTapSuren;
  final VoidCallback onTapGorev;

  const _StatsCard({
    required this.firmaCount,
    required this.surenDolan,
    required this.bekleyenGorev,
    required this.onTapFirma,
    required this.onTapSuren,
    required this.onTapGorev,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.cardDark, colors.card],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: colors.accent.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: colors.accent.withValues(alpha: 0.05),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              ikon: Icons.business_outlined,
              renk: const Color(0xFF4FC3F7),
              deger: '$firmaCount',
              etiket: 'Firma',
              onTap: onTapFirma,
            ),
          ),
          _dikey(context),
          Expanded(
            child: _StatItem(
              ikon: Icons.warning_amber_outlined,
              renk: surenDolan > 0 ? Colors.orange : Colors.green,
              deger: '$surenDolan',
              etiket: '30 gün uyarı',
              onTap: onTapSuren,
            ),
          ),
          _dikey(context),
          Expanded(
            child: _StatItem(
              ikon: Icons.task_alt_outlined,
              renk: bekleyenGorev > 0
                  ? colors.accent
                  : const Color(0xFF81C784),
              deger: '$bekleyenGorev',
              etiket: 'Bekleyen görev',
              onTap: onTapGorev,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dikey(BuildContext context) => Container(
        width: 1,
        height: 44,
        color: AppColors.of(context).border,
      );
}

class _StatItem extends StatelessWidget {
  final IconData ikon;
  final Color renk;
  final String deger;
  final String etiket;
  final VoidCallback onTap;

  const _StatItem({
    required this.ikon,
    required this.renk,
    required this.deger,
    required this.etiket,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ikon, color: renk, size: 20),
          const SizedBox(height: 4),
          Text(
            deger,
            style: TextStyle(
              color: renk,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            etiket,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.of(context).textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// MODÜl KART (Grid için)
// ─────────────────────────────────────────────

class _ModulKart extends StatelessWidget {
  final String baslik;
  final String aciklama;
  final IconData icon;
  final Color renk;
  final VoidCallback onTap;
  final String? badge;
  final bool isExternal;

  const _ModulKart({
    required this.baslik,
    required this.aciklama,
    required this.icon,
    required this.renk,
    required this.onTap,
    this.badge,
    this.isExternal = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.of(context).card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: renk.withValues(alpha: 0.25), width: 1),
          boxShadow: [
            BoxShadow(
              color: renk.withValues(alpha: 0.04),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: renk.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: renk, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          baslik,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.of(context).text,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge!,
                            style: const TextStyle(
                                color: Colors.red,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      if (isExternal)
                        Icon(Icons.open_in_new,
                            color: Colors.grey[700], size: 11),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    aciklama,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: AppColors.of(context).textMuted, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
