import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pehlivan_isg/pages/aksiyon_page.dart';
import 'package:pehlivan_isg/pages/ayarlar_page.dart';
import 'package:pehlivan_isg/pages/firmalar_page.dart';
import 'package:pehlivan_isg/pages/profil_page.dart';
import 'package:pehlivan_isg/pages/takvim_page.dart';
import 'package:pehlivan_isg/services/theme_service.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      sharedPreferencesName: 'PehlivanISG_Storage',
    ),
  );

  String _userName = "Yükleniyor...";
  String _userTitle = "İSG Uzmanı";
  String? _profileImageBase64;

  @override
  void initState() {
    super.initState();
    _loadDrawerData();
  }

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

  void _navigate(Widget page, {bool await_ = false}) async {
    Navigator.pop(context);
    if (await_) {
      await Navigator.push(context,
          MaterialPageRoute(builder: (_) => page));
      _loadDrawerData();
    } else {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => page));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Drawer(
      child: Container(
        color: colors.bg,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // ── PROFİL BAŞLIĞI ──────────────────────
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                  color: colors.card),
              accountName: Text(
                _userName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colors.text,
                  fontSize: 15,
                ),
              ),
              accountEmail: Text(
                _userTitle,
                style: TextStyle(
                    color: colors.text.withValues(alpha: 0.6),
                    fontSize: 13),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: colors.accent,
                backgroundImage: _profileImageBase64 != null
                    ? MemoryImage(
                        base64Decode(_profileImageBase64!))
                    : null,
                child: _profileImageBase64 == null
                    ? Icon(Icons.person,
                        color: colors.bg, size: 36)
                    : null,
              ),
            ),

            // ── ANA SAYFA ──────────────────────────
            _menuItem(
              icon: Icons.home_outlined,
              label: "Ana Sayfa",
              onTap: () => Navigator.pop(context),
            ),

            // ── FİRMALAR ───────────────────────────
            _menuItem(
              icon: Icons.business_outlined,
              label: "Firmalar",
              onTap: () => _navigate(const FirmalarPage()),
            ),

            // ── TAKVİM / AJANDA ────────────────────
            _menuItem(
              icon: Icons.calendar_month_outlined,
              label: "Takvim / Ajanda",
              badge: null,
              onTap: () => _navigate(const TakvimPage()),
              highlight: true,
            ),

            // ── GÖREV TAKİBİ ───────────────────────
            _menuItem(
              icon: Icons.task_alt_outlined,
              label: "Görev Takibi",
              onTap: () => _navigate(const AksiyanPage()),
              highlight: true,
            ),

            // ── İSG KATİP ─────────────────────────
            _menuItem(
              icon: Icons.open_in_browser_outlined,
              label: "İSG Katip",
              sublabel: "isgkatip.csgb.gov.tr",
              onTap: () async {
                Navigator.pop(context);
                final uri = Uri.parse(
                    'https://isgkatip.csgb.gov.tr');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri,
                      mode: LaunchMode.externalApplication);
                }
              },
              isExternal: true,
            ),

            // ── RAMAK KALA (yakında) ───────────────
            _menuItem(
              icon: Icons.warning_amber_outlined,
              label: "Ramak Kala",
              sublabel: "Yakında",
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text("Ramak Kala modülü yakında aktif olacak."),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              disabled: true,
            ),

            const Divider(color: Colors.white12, height: 24),

            // ── PROFİL ─────────────────────────────
            _menuItem(
              icon: Icons.person_outline,
              label: "Profil",
              color: AppColors.of(context).accent,
              onTap: () => _navigate(const ProfilPage(),
                  await_: true),
            ),

            // ── AYARLAR ────────────────────────────
            _menuItem(
              icon: Icons.settings_outlined,
              label: "Ayarlar",
              color: AppColors.of(context).accent,
              onTap: () => _navigate(const AyarlarPage()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String label,
    String? sublabel,
    String? badge,
    Color? color,
    bool highlight = false,
    bool disabled = false,
    bool isExternal = false,
    required VoidCallback onTap,
  }) {
    final colors = AppColors.of(context);
    final itemColor = disabled
        ? Colors.grey[700]!
        : (color ?? (highlight ? colors.accent : Colors.white70));

    return ListTile(
      leading: Icon(icon, color: itemColor, size: 22),
      title: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: disabled ? Colors.grey[700] : colors.text,
                fontSize: 14,
              ),
            ),
          ),
          if (isExternal) ...[
            const SizedBox(width: 4),
            Icon(Icons.open_in_new,
                color: Colors.grey[600], size: 12),
          ],
          if (badge != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                    color: Colors.red,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
      subtitle: sublabel != null
          ? Text(sublabel,
              style: TextStyle(
                  color: colors.textMuted, fontSize: 11))
          : null,
      onTap: disabled ? null : onTap,
      dense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}
