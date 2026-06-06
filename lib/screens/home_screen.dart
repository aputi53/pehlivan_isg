import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:pehlivan_isg/pages/ai_asistan_page.dart';
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
    if (h >= 5 && h < 12) return 'Günaydın! ☀️';
    if (h >= 12 && h < 18) return 'İyi günler! 👋';
    return 'İyi akşamlar! 🌙';
  }

  String _selamlamaMesaj() {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 12) return 'Güvenli ve verimli bir gün dileriz.';
    if (h >= 12 && h < 18) return 'Saha denetimleriniz nasıl gidiyor?';
    return 'Bugünü başarıyla kapattınız.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentRoute: 'home'),
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
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.of(context).accent,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.of(context)
                              .accent
                              .withValues(alpha: 0.6),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "MODÜLLER",
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.of(context)
                          .text
                          .withValues(alpha: 0.85),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.5,
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
                childAspectRatio: 1.85,
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
              const SizedBox(height: 10),

              // ── AI ASISTAN KARTI (tam genişlik) ──────
              _AiAsistanKarti(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AiAsistanPage()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final colors = AppColors.of(context);
    final mq = MediaQuery.of(context);
    // Küçük ekran eşiği: 360dp altı (örn. eski Samsung/Xiaomi modeller)
    final isSmallScreen = mq.size.width < 360;
    // Metin ölçeği büyükse toolbar yüksekliğini orantılı artır
    final textScale = mq.textScaler.scale(1.0).clamp(1.0, 1.4);
    final toolbarH = (isSmallScreen ? 70.0 : 80.0) * textScale;
    final logoSize = isSmallScreen ? 46.0 : 54.0;
    final logoRadius = isSmallScreen ? 11.0 : 13.0;

    return AppBar(
      backgroundColor: colors.card,
      toolbarHeight: toolbarH,
      elevation: 0,
      titleSpacing: 0,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      surfaceTintColor: Colors.transparent,
      shape: Border(
        bottom: BorderSide(
            color: colors.accent.withValues(alpha: 0.15), width: 1),
      ),
      // ── Hamburger menü ──
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: Icon(Icons.menu_rounded, color: colors.text, size: 24),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
          padding: const EdgeInsets.only(left: 16),
        ),
      ),
      // ── Logo + Metin ──
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo: çerçeve + gölge, boyut ekrana göre
          Container(
            width: logoSize,
            height: logoSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(logoRadius),
              border: Border.all(
                color: colors.accent.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.accent.withValues(alpha: 0.28),
                  blurRadius: 12,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(logoRadius - 1),
              child: Image.asset(
                'assets/ana ekran logo.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                    Icons.shield_outlined,
                    color: colors.accent,
                    size: 26),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Metin sütunu — Expanded ile kalan genişliği tam kapla
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // PehlivanİSG görseli
                Image.asset(
                  'assets/ana ekran isim.png',
                  height: isSmallScreen ? 17.0 : 20.0,
                  fit: BoxFit.fitHeight,
                  alignment: Alignment.centerLeft,
                  errorBuilder: (_, __, ___) => Text(
                    'PehlivanİSG',
                    style: TextStyle(
                        color: colors.accent,
                        fontSize: isSmallScreen ? 11 : 13,
                        fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 2),
                // Kullanıcı adı — her zaman tek satır
                Text(
                  _kullaniciAdi.isNotEmpty ? _kullaniciAdi : 'Kullanıcı',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.text,
                    fontSize: isSmallScreen ? 12.0 : 14.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                // Selamlama — taşma güvenli: maxLines:2 + ellipsis
                // Küçük ekranda sadece selamlama kelimesi göster
                Text(
                  isSmallScreen
                      ? _selamlama()
                      : '${_selamlama()} ${_selamlamaMesaj()}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.text.withValues(alpha: 0.65),
                    fontSize: isSmallScreen ? 10.5 : 11.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      // ── Yenile butonu ──
      actions: [
        IconButton(
          icon: Icon(Icons.refresh_outlined,
              color: colors.textMuted, size: 20),
          onPressed: _loadStats,
          padding: const EdgeInsets.only(right: 12),
          tooltip: 'Yenile',
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
// AI ASISTAN KARTI (tam genişlik, gradient)
// ─────────────────────────────────────────────

class _AiAsistanKarti extends StatelessWidget {
  final VoidCallback onTap;
  const _AiAsistanKarti({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4527A0), Color(0xFF7C4DFF), Color(0xFF9C6DFF)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C4DFF).withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AI İSG Asistanı',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Kanun, yönetmelik, risk değerlendirmesi sorularınız için',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.circle, color: Color(0xFF69FF47), size: 7),
                  const SizedBox(width: 4),
                  Text(
                    'Çevrimiçi',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
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
              color: renk.withValues(alpha: 0.28), width: 1),
          boxShadow: [
            BoxShadow(
              color: renk.withValues(alpha: 0.13),
              blurRadius: 16,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, 2),
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
                      color: AppColors.of(context)
                          .textMuted
                          .withValues(alpha: 0.9),
                      fontSize: 11,
                    ),
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
