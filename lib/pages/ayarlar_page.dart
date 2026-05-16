import 'package:flutter/material.dart';
import '../services/biometric_service.dart';
import '../screens/security/change_pin_screen.dart';

class AyarlarPage extends StatefulWidget {
  const AyarlarPage({super.key});

  @override
  State<AyarlarPage> createState() => _AyarlarPageState();
}

class _AyarlarPageState extends State<AyarlarPage> with SingleTickerProviderStateMixin {
  final BiometricService _bio = BiometricService();

  bool bildirimler = true;
  bool sesliUyari = false;
  bool titresim = true;
  bool otomatikRapor = true;
  bool darkMode = true;
  bool biyometrik = false;
  bool konum = true;
  bool _biyometrikMevcut = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
    _loadBiyometrik();
  }

  Future<void> _loadBiyometrik() async {
    final destekleniyor = await _bio.isDeviceSupported();
    final biyometrikler = await _bio.getAvailableBiometrics();
    final etkin = await _bio.isBiometricEnabled();
    if (!mounted) return;
    setState(() {
      _biyometrikMevcut = destekleniyor && biyometrikler.isNotEmpty;
      biyometrik = etkin;
    });
  }

  Future<void> _biyometrikDegistir(bool value) async {
    if (value) {
      final result = await _bio.authenticate(
        reason: 'Biyometrik kilidi etkinleştirmek için doğrulayın',
      );
      if (result != BiometricResult.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF151C2E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                SizedBox(width: 10),
                Text("Biyometrik doğrulama başarısız",
                    style: TextStyle(color: Colors.white, fontSize: 13)),
              ],
            ),
          ),
        );
        return;
      }
    }
    await _bio.setBiometricEnabled(value);
    setState(() => biyometrik = value);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E1A),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "AYARLAR",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 4,
            color: Color(0xFFE8B84B),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white54),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [

              _sectionLabel("Bildirim Ayarları", Icons.notifications_outlined),
              const SizedBox(height: 10),

              _settingsCard([
                _toggleTile(
                  icon: Icons.notifications_active_outlined,
                  title: "Bildirimler",
                  subtitle: "Tüm sistem bildirimlerini aç/kapat",
                  value: bildirimler,
                  onChanged: (v) => setState(() => bildirimler = v),
                ),
                _divider(),
                _toggleTile(
                  icon: Icons.volume_up_outlined,
                  title: "Sesli Uyarı",
                  subtitle: "Acil durum sesli alarmları",
                  value: sesliUyari,
                  onChanged: (v) => setState(() => sesliUyari = v),
                ),
                _divider(),
                _toggleTile(
                  icon: Icons.vibration_outlined,
                  title: "Titreşim",
                  subtitle: "Bildirim titreşimi",
                  value: titresim,
                  onChanged: (v) => setState(() => titresim = v),
                ),
                _divider(),
                _toggleTile(
                  icon: Icons.summarize_outlined,
                  title: "Otomatik Rapor",
                  subtitle: "Günlük ISG raporu bildirimi",
                  value: otomatikRapor,
                  onChanged: (v) => setState(() => otomatikRapor = v),
                ),
              ]),

              const SizedBox(height: 22),

              _sectionLabel("Güvenlik & Gizlilik", Icons.shield_outlined),
              const SizedBox(height: 10),

              _settingsCard([
                _toggleTile(
                  icon: Icons.fingerprint_outlined,
                  title: "Biyometrik Kilit",
                  subtitle: _biyometrikMevcut
                      ? "Parmak izi veya yüz tanıma"
                      : "Bu cihazda desteklenmiyor",
                  value: biyometrik,
                  onChanged: _biyometrikMevcut ? _biyometrikDegistir : null,
                ),
                _divider(),
                _toggleTile(
                  icon: Icons.location_on_outlined,
                  title: "Konum Erişimi",
                  subtitle: "Saha takibi için konum izni",
                  value: konum,
                  onChanged: (v) => setState(() => konum = v),
                ),
                _divider(),
                _navTile(
                  icon: Icons.lock_reset_outlined,
                  title: "Şifre Değiştir",
                  subtitle: "Uygulama PIN kodunuzu güncelleyin",
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ChangePinScreen()),
                    );
                    _loadBiyometrik();
                  },
                ),
                _divider(),
                _navTile(
                  icon: Icons.admin_panel_settings_outlined,
                  title: "İki Faktörlü Doğrulama",
                  subtitle: "Hesap güvenliğini artırın",
                  onTap: () => _showComingSoon("2FA"),
                  badge: "ÖNERİLİR",
                ),
              ]),

              const SizedBox(height: 22),

              _sectionLabel("Görünüm", Icons.palette_outlined),
              const SizedBox(height: 10),

              _settingsCard([
                _toggleTile(
                  icon: Icons.dark_mode_outlined,
                  title: "Karanlık Mod",
                  subtitle: "Koyu tema kullan",
                  value: darkMode,
                  onChanged: (v) => setState(() => darkMode = v),
                ),
                _divider(),
                _navTile(
                  icon: Icons.language_outlined,
                  title: "Dil",
                  subtitle: "Türkçe",
                  onTap: () => _showComingSoon("Dil"),
                ),
              ]),

              const SizedBox(height: 22),

              _sectionLabel("Uygulama", Icons.info_outline),
              const SizedBox(height: 10),

              _settingsCard([
                _navTile(
                  icon: Icons.help_outline,
                  title: "Yardım & Destek",
                  subtitle: "SSS ve iletişim",
                  onTap: () => _showComingSoon("Yardım"),
                ),
                _divider(),
                _navTile(
                  icon: Icons.policy_outlined,
                  title: "Gizlilik Politikası",
                  subtitle: "Veri kullanım koşulları",
                  onTap: () => _showComingSoon("Gizlilik"),
                ),
                _divider(),
                _navTile(
                  icon: Icons.system_update_outlined,
                  title: "Güncellemeler",
                  subtitle: "Mevcut sürüm: v1.0.0",
                  onTap: () => _showComingSoon("Güncelleme"),
                  badge: "GÜNCEL",
                  badgeColor: const Color(0xFF4ADE80),
                ),
                _divider(),
                _navTile(
                  icon: Icons.info_outline,
                  title: "Uygulama Hakkında",
                  subtitle: "ISG Uzman Pro · © 2024",
                  onTap: _showAbout,
                ),
              ]),

              const SizedBox(height: 22),

              _logoutButton(),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFE8B84B).withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFFE8B84B), size: 14),
        ),
        const SizedBox(width: 10),
        Text(
          text.toUpperCase(),
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.5,
          ),
        ),
      ],
    );
  }

  Widget _settingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF10151F),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(children: children),
    );
  }

  Widget _toggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    ValueChanged<bool>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8B84B).withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFFE8B84B), size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: const Color(0xFFE8B84B),
              activeTrackColor: const Color(0xFFE8B84B).withOpacity(0.25),
              inactiveThumbColor: Colors.white24,
              inactiveTrackColor: Colors.white10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _navTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? badge,
    Color? badgeColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8B84B).withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFFE8B84B), size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: (badgeColor ?? const Color(0xFFE8B84B)).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: (badgeColor ?? const Color(0xFFE8B84B)).withOpacity(0.4),
                            ),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              color: badgeColor ?? const Color(0xFFE8B84B),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ]
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      color: Colors.white.withOpacity(0.05),
      indent: 56,
      endIndent: 16,
    );
  }

  Widget _logoutButton() {
    return GestureDetector(
      onTap: _showLogoutDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_outlined, color: Colors.redAccent, size: 18),
            SizedBox(width: 10),
            Text(
              "Çıkış Yap",
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF151C2E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFFE8B84B), size: 18),
            const SizedBox(width: 10),
            Text("$feature yakında aktif olacak",
                style: const TextStyle(color: Colors.white, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF151C2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout_outlined,
                    color: Colors.redAccent, size: 32),
              ),
              const SizedBox(height: 16),
              const Text("Çıkış Yap",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18)),
              const SizedBox(height: 8),
              const Text(
                "Hesabınızdan çıkış yapmak istediğinizden emin misiniz?",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.white.withOpacity(0.1)),
                        ),
                      ),
                      child: const Text("İptal",
                          style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text("Çıkış Yap",
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF151C2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: const Color(0xFFE8B84B).withOpacity(0.35),
                    width: 1.5,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/yeni_ikon.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF0A0E1A),
                      child: const Icon(Icons.health_and_safety,
                          color: Color(0xFFE8B84B), size: 48),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text("PEHLİVAN",
                  style: TextStyle(
                    color: Color(0xFFE8B84B),
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    letterSpacing: 4,
                  )),
              const SizedBox(height: 5),
              const Text("PROFESYONEL İSG\nYÖNETİM SİSTEMİ",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 1.5,
                    height: 1.5,
                  )),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8B84B).withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE8B84B).withOpacity(0.25)),
                ),
                child: const Text("v1.0.0",
                    style: TextStyle(
                        color: Color(0xFFE8B84B),
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8B84B),
                    foregroundColor: const Color(0xFF0A0E1A),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text("Kapat",
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}