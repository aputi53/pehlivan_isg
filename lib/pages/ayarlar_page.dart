import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart'; // ← Link açma işlemleri için eklendi
import '../services/biometric_service.dart';
import '../screens/security/change_pin_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TEMA YÖNETİCİSİ  (main.dart'taki MaterialApp'e bağlanır)
// ─────────────────────────────────────────────────────────────────────────────
class ThemeNotifier extends ValueNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.dark);
}

final themeNotifier = ThemeNotifier();

class AyarlarPage extends StatefulWidget {
  const AyarlarPage({super.key});

  @override
  State<AyarlarPage> createState() => _AyarlarPageState();
}

class _AyarlarPageState extends State<AyarlarPage>
    with SingleTickerProviderStateMixin {
  final BiometricService _bio = BiometricService();

  // ── Toggle state'leri ────────────────────────────────────────────────────
  bool bildirimler = true;
  bool bildirimSesi = true;
  bool titresim = true;
  bool otomatikRapor = true;
  bool darkMode = false;
  bool biyometrik = false;
  bool konum = false;
  bool _biyometrikMevcut = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
            CurvedAnimation(parent: _animController, curve: Curves.easeOut));
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
          reason: 'Biyometrik kiliti etkinleştirmek için doğrulayın');
      if (result != BiometricResult.success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(_snack(
          'Biyometrik doğrulama başarısız',
          Icons.error_outline,
          Colors.redAccent,
        ));
        return;
      }
    }
    await _bio.setBiometricEnabled(value);
    setState(() => biyometrik = value);
  }

  // ── Konum izni ───────────────────────────────────────────────────────────
  Future<void> _konumDegistir(bool value) async {
    if (value) {
      const channel = MethodChannel('com.pehlivanisg.pehlivan_isg/location');
      try {
        final granted =
            await channel.invokeMethod<bool>('requestPermission') ?? false;
        setState(() => konum = granted);
        if (!granted && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(_snack(
            'Konum izni verilmedi',
            Icons.location_off_outlined,
            Colors.orange,
          ));
        }
      } catch (_) {
        setState(() => konum = value);
      }
    } else {
      setState(() => konum = false);
    }
  }

  // ── Harici Link Açma Yardımcı Fonksiyonu ───────────────────────────────────
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(_snack(
          'Bağlantı açılamadı',
          Icons.link_off,
          Colors.redAccent,
        ));
      }
    } catch (_) {}
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
          'AYARLAR',
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 4,
              color: Color(0xFFE8B84B)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: Colors.white54),
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
              // ── BİLDİRİMLER ─────────────────────────────────────────────
              _sectionLabel('Bildirim Ayarları', Icons.notifications_outlined),
              const SizedBox(height: 10),
              _settingsCard([
                _toggleTile(
                  icon: Icons.notifications_active_outlined,
                  title: 'Bildirimler',
                  subtitle: 'Tüm sistem bildirimlerini aç/kapat',
                  value: bildirimler,
                  onChanged: (v) => setState(() => bildirimler = v),
                ),
                _divider(),
                _toggleTile(
                  icon: Icons.music_note_outlined,
                  title: 'Bildirim Sesi',
                  subtitle: bildirimSesi ? 'Açık' : 'Sessiz',
                  value: bildirimSesi,
                  onChanged: bildirimler
                      ? (v) => setState(() => bildirimSesi = v)
                      : null,
                ),
                _divider(),
                _toggleTile(
                  icon: Icons.vibration_outlined,
                  title: 'Titreşim',
                  subtitle: 'Bildirim titreşimi',
                  value: titresim,
                  onChanged: bildirimler
                      ? (v) => setState(() => titresim = v)
                      : null,
                ),
                _divider(),
                _toggleTile(
                  icon: Icons.summarize_outlined,
                  title: 'Otomatik Rapor',
                  subtitle: 'Günlük İSG raporu bildirimi',
                  value: otomatikRapor,
                  onChanged: (v) => setState(() => otomatikRapor = v),
                ),
              ]),

              const SizedBox(height: 22),

              // ── GÜVENLİK ────────────────────────────────────────────────
              _sectionLabel('Güvenlik & Gizlilik', Icons.shield_outlined),
              const SizedBox(height: 10),
              _settingsCard([
                _toggleTile(
                  icon: Icons.fingerprint_outlined,
                  title: 'Biyometrik Kilit',
                  subtitle: _biyometrikMevcut
                      ? 'Parmak izi veya yüz tanıma'
                      : 'Bu cihazda desteklenmiyor',
                  value: biyometrik,
                  onChanged: _biyometrikMevcut ? _biyometrikDegistir : null,
                ),
                _divider(),
                _toggleTile(
                  icon: Icons.location_on_outlined,
                  title: 'Konum Erişimi',
                  subtitle: konum ? 'Saha takibi etkin' : 'Saha takibi için izin verin',
                  value: konum,
                  onChanged: _konumDegistir,
                ),
                _divider(),
                _navTile(
                  icon: Icons.lock_reset_outlined,
                  title: 'Şifre Değiştir',
                  subtitle: 'Uygulama PIN kodunuzu güncelleyin',
                  onTap: () async {
                    await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ChangePinScreen()));
                    _loadBiyometrik();
                  },
                ),
                _divider(),
                _navTile(
                  icon: Icons.admin_panel_settings_outlined,
                  title: 'İki Faktörlü Doğrulama',
                  subtitle: 'Hesap güvenliğini artırın',
                  onTap: () => _showComingSoon('2FA'),
                  badge: 'ÖNERİLİR',
                ),
              ]),

              const SizedBox(height: 22),

              // ── GÖRÜNÜM ──────────────────────────────────────────────────
              _sectionLabel('Görünüm', Icons.palette_outlined),
              const SizedBox(height: 10),
              _settingsCard([
                _toggleTile(
                  icon: Icons.dark_mode_outlined,
                  title: 'Karanlık Mod',
                  subtitle: 'Yakında aktif olacak',
                  value: true,
                  onChanged: null,
                ),
              ]),

              const SizedBox(height: 22),

              // ── UYGULAMA ─────────────────────────────────────────────────
              _sectionLabel('Uygulama', Icons.info_outline),
              const SizedBox(height: 10),
              _settingsCard([
                _navTile(
                  icon: Icons.help_outline,
                  title: 'Yardım & Destek',
                  subtitle: 'SSS ve iletişim',
                  onTap: _showDestek,
                ),
                _divider(),
                _navTile(
                  icon: Icons.policy_outlined,
                  title: 'Gizlilik Politikası',
                  subtitle: 'Veri kullanım koşulları',
                  onTap: _showGizlilik,
                ),
                _divider(),
                _navTile(
                  icon: Icons.system_update_outlined,
                  title: 'Güncellemeler',
                  subtitle: 'Mevcut sürüm: v1.0.0',
                  onTap: () => _showComingSoon('Güncelleme kontrolü'),
                  badge: 'GÜNCEL',
                  badgeColor: const Color(0xFF4ADE80),
                ),
                _divider(),
                _navTile(
                  icon: Icons.info_outline,
                  title: 'Uygulama Hakkında',
                  subtitle: 'PehlivanİSG · © 2026',
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

  // ─────────────────────────────────────────────────────────────────────────
  // YARDIMCI WIDGET'LAR
  // ─────────────────────────────────────────────────────────────────────────

  Widget _sectionLabel(String text, IconData icon) {
    // SÜREÇ ANALİZİ: Hataya sebep olan argüman temizlendi.
    // İngilizce yereldeki 'i' -> 'BİLDIRIM' sorununu aşmak için harfleri manuel eşliyoruz.
    final String duzgunMetin = text
        .replaceAll('i', 'İ')
        .replaceAll('ı', 'I')
        .toUpperCase();

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
        Text(duzgunMetin,
            style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.5)),
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
    final disabled = onChanged == null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8B84B)
                  .withOpacity(disabled ? 0.04 : 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon,
                color: disabled ? Colors.white24 : const Color(0xFFE8B84B),
                size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: disabled ? Colors.white24 : Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: (badgeColor ?? const Color(0xFFE8B84B))
                                .withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: (badgeColor ?? const Color(0xFFE8B84B))
                                    .withOpacity(0.4)),
                          ),
                          child: Text(badge,
                              style: TextStyle(
                                  color: badgeColor ?? const Color(0xFFE8B84B),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8)),
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

  Widget _divider() => Divider(
      height: 1,
      color: Colors.white.withOpacity(0.05),
      indent: 56,
      endIndent: 16);

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
            Text('Çıkış Yap',
                style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DIALOGLAR
  // ─────────────────────────────────────────────────────────────────────────

  SnackBar _snack(String msg, IconData icon, Color color) {
    return SnackBar(
      backgroundColor: const Color(0xFF151C2E),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Text(msg, style: const TextStyle(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(_snack(
      '$feature yakında aktif olacak',
      Icons.info_outline,
      const Color(0xFFE8B84B),
    ));
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => _dialog(
        icon: Icons.logout_outlined,
        iconColor: Colors.redAccent,
        title: 'Çıkış Yap',
        body: 'Hesabınızdan çıkış yapmak istediğinizden emin misiniz?',
        actions: Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.white.withOpacity(0.1))),
                ),
                child: const Text('İptal',
                    style: TextStyle(
                        color: Colors.white54, fontWeight: FontWeight.w600)),
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
                child: const Text('Çıkış Yap',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDestek() {
    showDialog(
      context: context,
      builder: (_) => _dialog(
        icon: Icons.support_agent_outlined,
        iconColor: const Color(0xFFE8B84B),
        title: 'Yardım & Destek',
        body: null,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _destekSatir(Icons.email_outlined, 'E-posta', 'destek@pehlivanisg.com'),
            const SizedBox(height: 12),
            _destekSatir(Icons.phone_outlined, 'Telefon', '+90 (XXX) XXX XX XX'),
            const SizedBox(height: 12),
            _destekSatir(Icons.access_time_outlined, 'Çalışma Saatleri', 'Pzt – Cum, 09:00 – 18:00'),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8B84B).withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE8B84B).withOpacity(0.2)),
              ),
              child: const Text(
                'Uygulama ile ilgili sorun yaşıyorsanız yukarıdaki kanallardan bize ulaşabilirsiniz.',
                style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.6),
              ),
            ),
            const SizedBox(height: 12),
            // ── Kullanım Şartları Link Entegrasyonu ──────────────────────────
            Center(
              child: TextButton(
                onPressed: () => _launchURL('https://www.pehlivanisg.com/kullanim-sartlari'),
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Kullanım Şartları ve Sözleşmesi',
                  style: TextStyle(
                    color: Color(0xFFE8B84B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: _kapatButon(),
      ),
    );
  }

  Widget _destekSatir(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFE8B84B), size: 16),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }

  void _showGizlilik() {
    showDialog(
      context: context,
      builder: (_) => _dialog(
        icon: Icons.policy_outlined,
        iconColor: const Color(0xFFE8B84B),
        title: 'Gizlilik Politikası',
        body: null,
        content: SizedBox(
          height: MediaQuery.of(context).size.height * 0.45, // Kaydırma alanı optimize edildi
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _gizlilikBaslik('Veri Toplama'),
                _gizlilikMetin('PehlivanİSG uygulaması yalnızca İSG denetim süreçleri için gerekli verileri toplar.'),
                const SizedBox(height: 12),
                _gizlilikBaslik('Veri Depolama'),
                _gizlilikMetin('Tüm verileriniz cihazınızda şifreli olarak saklanır. Sunucuya aktarım yalnızca sizin onayınızla gerçekleşir.'),
                const SizedBox(height: 12),
                _gizlilikBaslik('Biyometrik Veriler'),
                _gizlilikMetin('Parmak izi ve yüz tanıma verileri yalnızca cihazınızın güvenli donanımında işlenir, uygulamamız bu verilere erişemez.'),
                const SizedBox(height: 12),
                _gizlilikBaslik('Konum Verisi'),
                _gizlilikMetin('Konum erişimi yalnızca saha denetim kayıtları için kullanılır ve üçüncü taraflarla paylaşılmaz.'),
                const SizedBox(height: 12),
                // ── Veri Silme Maddesi Entegrasyonu ──────────────────────────
                _gizlilikBaslik('Veri Silme ve Haklarınız'),
                _gizlilikMetin('Kanunlar kapsamındaki haklarınızı kullanmak veya verilerinizin kalıcı olarak silmesini talep etmek için destek kanallarımızdan bize ulaşabilirsiniz.'),
                const SizedBox(height: 12),
                _gizlilikBaslik('İletişim'),
                _gizlilikMetin('Gizlilik ile ilgili sorularınız için: gizlilik@pehlivanisg.com'),
                const SizedBox(height: 16),
                // ── Web Politikası Link Entegrasyonu ──────────────────────────
                Center(
                  child: TextButton(
                    onPressed: () => _launchURL('https://www.pehlivanisg.com/gizlilik-politikasi'),
                    style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    ),
                    child: const Text(
                      'Tam metni web sitemizden okumak için tıklayınız',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFE8B84B),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: _kapatButon(),
      ),
    );
  }

  Widget _gizlilikBaslik(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(text,
        style: const TextStyle(
            color: Color(0xFFE8B84B),
            fontWeight: FontWeight.w700,
            fontSize: 13)),
  );

  Widget _gizlilikMetin(String text) => Text(text,
      style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.6));

  void _showAbout() {
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
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                      color: const Color(0xFFE8B84B).withOpacity(0.35),
                      width: 1.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset('assets/yeni_ikon.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFF0A0E1A),
                        child: const Icon(Icons.health_and_safety,
                            color: Color(0xFFE8B84B), size: 44),
                      )),
                ),
              ),
              const SizedBox(height: 14),
              const Text('PEHLİVAN',
                  style: TextStyle(
                      color: Color(0xFFE8B84B),
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      letterSpacing: 4)),
              const SizedBox(height: 4),
              const Text('PROFESYONEL İSG\nYÖNETİM SİSTEMİ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 1.5,
                      height: 1.4)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8B84B).withOpacity(0.10),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE8B84B).withOpacity(0.25)),
                    ),
                    child: const Text('v1.0.0',
                        style: TextStyle(
                            color: Color(0xFFE8B84B),
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // ── Açık Kaynak Lisansları Buton Entegrasyonu ────────────────────
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(context); // Önce mevcut diyaloğu kapatıyoruz
                  showLicensePage(
                    context: context,
                    applicationName: 'PehlivanİSG',
                    applicationVersion: '1.0.0',
                    applicationIcon: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Icon(Icons.health_and_safety, color: const Color(0xFFE8B84B), size: 48),
                    ),
                  );
                },
                icon: const Icon(Icons.assignment_outlined, size: 14, color: Color(0xFFE8B84B)),
                label: const Text(
                  'Açık Kaynak Lisansları',
                  style: TextStyle(color: Color(0xFFE8B84B), fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'İş Sağlığı ve Güvenliği profesyonelleri için geliştirilmiş mobil yönetim platformu.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '© 2026 PehlivanİSG · Tüm hakları saklıdır.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8B84B),
                    foregroundColor: const Color(0xFF0A0E1A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Kapat', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dialog({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? body,
    Widget? content,
    required Widget actions,
  }) {
    return Dialog(
      backgroundColor: const Color(0xFF151C2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 14),
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 17)),
            const SizedBox(height: 10),
            if (body != null)
              Text(body,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 13, height: 1.5)),
            if (content != null) ...[
              const SizedBox(height: 10),
              content,
            ],
            const SizedBox(height: 20),
            actions,
          ],
        ),
      ),
    );
  }

  Widget _kapatButon() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE8B84B),
          foregroundColor: const Color(0xFF0A0E1A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: const Text('Kapat', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}