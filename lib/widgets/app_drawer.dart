import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pehlivan_isg/pages/aksiyon_page.dart';
import 'package:pehlivan_isg/pages/ayarlar_page.dart';
import 'package:pehlivan_isg/pages/firmalar_page.dart';
import 'package:pehlivan_isg/pages/profil_page.dart';
import 'package:pehlivan_isg/pages/raporlar_page.dart';
import 'package:pehlivan_isg/pages/takvim_page.dart';
import 'package:pehlivan_isg/screens/saha_denetim_screen.dart';
import 'package:pehlivan_isg/services/theme_service.dart';

/// Geçerli routeKey değerleri:
/// 'home' | 'saha' | 'firmalar' | 'takvim' | 'gorevler' | 'raporlar' |
/// 'profil' | 'ayarlar'
class AppDrawer extends StatefulWidget {
  final String currentRoute;
  const AppDrawer({super.key, this.currentRoute = 'home'});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      sharedPreferencesName: 'PehlivanISG_Storage',
    ),
  );

  String _userName = '';
  String _userTitle = 'İSG Uzmanı';
  String? _profileImageBase64;

  @override
  void initState() {
    super.initState();
    _loadDrawerData();
  }

  Future<void> _loadDrawerData() async {
    try {
      final name  = await _storage.read(key: 'user_name');
      final title = await _storage.read(key: 'user_title');
      final image = await _storage.read(key: 'user_image_base64');
      if (mounted) {
        setState(() {
          _userName            = (name  != null && name.isNotEmpty)  ? name  : '';
          _userTitle           = (title != null && title.isNotEmpty) ? title : 'İSG Uzmanı';
          _profileImageBase64  = image;
        });
      }
    } catch (e) {
      debugPrint('Drawer veri yükleme: $e');
    }
  }

  // Drawer kapat → root'a dön → yeni sayfayı aç
  void _navigateTo(String routeKey, Widget Function()? pageBuilder) {
    if (routeKey == widget.currentRoute) {
      Navigator.pop(context);
      return;
    }
    // Navigator'ı önceden yakala; pop'tan sonra context geçersiz olabilir
    final nav = Navigator.of(context);
    Navigator.pop(context);
    nav.popUntil((r) => r.isFirst);
    if (routeKey != 'home' && pageBuilder != null) {
      nav.push(MaterialPageRoute(builder: (_) => pageBuilder()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Drawer(
      backgroundColor: colors.bg,
      width: MediaQuery.of(context).size.width * 0.78,
      child: Column(
        children: [
          _buildProfileHeader(colors),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
              children: [
                // ── GRUP 1: İSG YÖNETİMİ ─────────────────────
                _groupLabel('İSG YÖNETİMİ', colors),
                _item(
                  icon: Icons.home_outlined,
                  label: 'Ana Sayfa',
                  routeKey: 'home',
                  colors: colors,
                  onTap: () => _navigateTo('home', null),
                ),
                _item(
                  icon: Icons.location_on_outlined,
                  label: 'Saha Denetim',
                  routeKey: 'saha',
                  colors: colors,
                  onTap: () => _navigateTo('saha', () => const SahaDenetimScreen()),
                ),
                _item(
                  icon: Icons.business_outlined,
                  label: 'Firmalar',
                  routeKey: 'firmalar',
                  colors: colors,
                  onTap: () => _navigateTo('firmalar', () => const FirmalarPage()),
                ),
                _item(
                  icon: Icons.calendar_month_outlined,
                  label: 'Takvim',
                  routeKey: 'takvim',
                  colors: colors,
                  onTap: () => _navigateTo('takvim', () => const TakvimPage()),
                ),
                _item(
                  icon: Icons.task_alt_outlined,
                  label: 'Görev Takibi',
                  routeKey: 'gorevler',
                  colors: colors,
                  onTap: () => _navigateTo('gorevler', () => const AksiyanPage()),
                ),
                _item(
                  icon: Icons.bar_chart_outlined,
                  label: 'Raporlar',
                  routeKey: 'raporlar',
                  colors: colors,
                  onTap: () => _navigateTo('raporlar', () => const RaporlarPage()),
                ),

                // ── GRUP 2: ARAÇLAR ───────────────────────────
                _divider(colors),
                _groupLabel('ARAÇLAR', colors),
                _item(
                  icon: Icons.open_in_browser_outlined,
                  label: 'İSG Katip',
                  routeKey: 'isgkatip',
                  isExternal: true,
                  colors: colors,
                  onTap: () async {
                    Navigator.pop(context);
                    final uri = Uri.parse('https://isgkatip.csgb.gov.tr');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
                _item(
                  icon: Icons.warning_amber_outlined,
                  label: 'Ramak Kala',
                  sublabel: 'Yakında',
                  routeKey: 'ramakkala',
                  disabled: true,
                  colors: colors,
                  onTap: () {},
                ),

                // ── GRUP 3: KULLANICI ─────────────────────────
                _divider(colors),
                _groupLabel('KULLANICI', colors),
                _item(
                  icon: Icons.person_outline,
                  label: 'Profil',
                  routeKey: 'profil',
                  colors: colors,
                  onTap: () async {
                    Navigator.pop(context);
                    Navigator.of(context).popUntil((r) => r.isFirst);
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProfilPage()),
                    );
                    _loadDrawerData();
                  },
                ),
                _item(
                  icon: Icons.settings_outlined,
                  label: 'Ayarlar',
                  routeKey: 'ayarlar',
                  colors: colors,
                  onTap: () => _navigateTo('ayarlar', () => const AyarlarPage()),
                ),
                _item(
                  icon: Icons.rate_review_outlined,
                  label: 'Geri Bildirim',
                  routeKey: 'feedback',
                  colors: colors,
                  onTap: () async {
                    Navigator.pop(context);
                    final uri = Uri(
                      scheme: 'mailto',
                      path: 'fa.pehlivan53@gmail.com',
                      queryParameters: {
                        'subject': 'PehlivanİSG - Geri Bildirim',
                      },
                    );
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── PROFİL BAŞLIĞI ─────────────────────────────────────────────
  Widget _buildProfileHeader(AppColors colors) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0D1520),
            const Color(0xFF111827),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: colors.accent.withValues(alpha: 0.18),
            width: 1,
          ),
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRect(
              child: CustomPaint(painter: _DrawerHeaderPainter()),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, topPad + 20, 20, 22),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colors.accent.withValues(alpha: 0.55),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colors.accent.withValues(alpha: 0.22),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 34,
                    backgroundColor: colors.accent.withValues(alpha: 0.12),
                    backgroundImage: _profileImageBase64 != null
                        ? MemoryImage(base64Decode(_profileImageBase64!))
                        : null,
                    child: _profileImageBase64 == null
                        ? Icon(Icons.person, color: colors.accent, size: 30)
                        : null,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userName.isNotEmpty ? _userName : 'Kullanıcı',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.text,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: colors.accent.withValues(alpha: 0.13),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: colors.accent.withValues(alpha: 0.28),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          _userTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── GRUP ETİKETİ ───────────────────────────────────────────────
  Widget _groupLabel(String label, AppColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 11,
            decoration: BoxDecoration(
              color: colors.accent.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: colors.text.withValues(alpha: 0.65),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
            ),
          ),
        ],
      ),
    );
  }

  // ── AYRAÇ ──────────────────────────────────────────────────────
  Widget _divider(AppColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Divider(
        color: colors.accent.withValues(alpha: 0.18),
        height: 1,
        thickness: 0.8,
      ),
    );
  }

  // ── MENÜ SATIRI ────────────────────────────────────────────────
  Widget _item({
    required IconData icon,
    required String label,
    required String routeKey,
    required AppColors colors,
    required VoidCallback onTap,
    String? sublabel,
    bool disabled = false,
    bool isExternal = false,
  }) {
    final isActive = routeKey == widget.currentRoute;
    final iconColor = disabled
        ? colors.textMuted.withValues(alpha: 0.4)
        : isActive
            ? colors.accent
            : colors.text.withValues(alpha: 0.75);
    final textColor = disabled
        ? colors.textMuted.withValues(alpha: 0.4)
        : isActive
            ? colors.accent
            : colors.text;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: disabled ? null : onTap,
          splashColor: colors.accent.withValues(alpha: 0.08),
          highlightColor: colors.accent.withValues(alpha: 0.05),
          child: Container(
            decoration: BoxDecoration(
              color: isActive
                  ? colors.accent.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                // Aktif sol bar
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 3,
                  height: isActive ? 38 : 0,
                  margin: const EdgeInsets.only(right: 1),
                  decoration: BoxDecoration(
                    color: colors.accent,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(3),
                      bottomRight: Radius.circular(3),
                    ),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 0),
                    leading: Icon(icon, color: iconColor, size: 21),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 13.5,
                              fontWeight: isActive
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (isExternal) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.open_in_new,
                              color: colors.textMuted.withValues(alpha: 0.5),
                              size: 12),
                        ],
                      ],
                    ),
                    subtitle: sublabel != null
                        ? Text(
                            sublabel,
                            style: TextStyle(
                              color: colors.textMuted.withValues(alpha: 0.5),
                              fontSize: 10.5,
                            ),
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerHeaderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Sağ üstte yumuşak parlaklık
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.07),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.85, 0),
        radius: size.height * 1.4,
      ));
    canvas.drawRect(Offset.zero & size, glowPaint);

    // Çapraz amber şeritler (sol alttan sağ üste)
    final linePaint = Paint()
      ..color = const Color(0xFFE8B84B).withValues(alpha: 0.055)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const spacing = 22.0;
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, size.height),
        Offset(i + size.height, 0),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_DrawerHeaderPainter old) => false;
}
