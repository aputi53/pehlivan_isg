import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/backup_service.dart';
import '../services/biometric_service.dart';
import '../services/theme_service.dart';
import '../screens/security/change_pin_screen.dart';
import 'personel_havuzu_page.dart';

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
      appBar: AppBar(
        backgroundColor: AppColors.of(context).card,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Ayarlar',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.of(context).text,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: AppColors.of(context).textMuted),
          onPressed: () => Navigator.maybePop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
              height: 1, color: AppColors.of(context).border),
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

              // ── TEMA ─────────────────────────────────────────────────────
              _sectionLabel('Tema', Icons.palette_outlined),
              const SizedBox(height: 10),
              _TemaKarti(),

              const SizedBox(height: 22),

              // ── VERİ YÖNETİMİ ────────────────────────────────────────────
              _sectionLabel('Veri Yönetimi', Icons.storage_outlined),
              const SizedBox(height: 10),
              _settingsCard([
                _navTile(
                  icon: Icons.backup_outlined,
                  title: 'Veri Yedekle',
                  subtitle: 'Tüm verileri .db dosyası olarak dışa aktar',
                  onTap: _veriYedekle,
                ),
                _divider(),
                _navTile(
                  icon: Icons.restore_outlined,
                  title: 'Yedekten Geri Yükle',
                  subtitle: 'Daha önce alınan yedeği içe aktar',
                  onTap: _veriGeriYukle,
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

              // ── PERSONEL HAVUZU ──────────────────────────────────────────
              _sectionLabel('Personel Havuzu', Icons.badge_outlined),
              const SizedBox(height: 10),
              _settingsCard([
                _navTile(
                  icon: Icons.engineering_outlined,
                  title: 'Uzmanlar & Hekimler',
                  subtitle:
                      'Sertifikalarda kullanmak için uzman ve hekim listesi',
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PersonelHavuzuPage())),
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

    final accent = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: accent, size: 14),
        ),
        const SizedBox(width: 10),
        Text(duzgunMetin,
            style: TextStyle(
                color: AppColors.of(context).textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.5)),
      ],
    );
  }

  Widget _settingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.of(context).card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.of(context).border),
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
              color: AppColors.of(context).accent
                  .withValues(alpha: disabled ? 0.04 : 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon,
                color: disabled ? AppColors.of(context).textMuted.withValues(alpha: 0.35) : AppColors.of(context).accent,
                size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: disabled ? AppColors.of(context).textMuted.withValues(alpha: 0.5) : AppColors.of(context).text,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(color: AppColors.of(context).textMuted, fontSize: 12)),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: Theme.of(context).colorScheme.primary,
              activeTrackColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
              inactiveThumbColor: AppColors.of(context).textMuted.withValues(alpha: 0.4),
              inactiveTrackColor: AppColors.of(context).border,
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
                color: AppColors.of(context).accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.of(context).accent, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title,
                          style: TextStyle(
                              color: AppColors.of(context).text,
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: (badgeColor ?? AppColors.of(context).accent)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: (badgeColor ?? AppColors.of(context).accent)
                                    .withValues(alpha: 0.4)),
                          ),
                          child: Text(badge,
                              style: TextStyle(
                                  color: badgeColor ?? AppColors.of(context).accent,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8)),
                        ),
                      ]
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(color: AppColors.of(context).textMuted, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.of(context).textMuted.withValues(alpha: 0.5), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Divider(
      height: 1,
      color: AppColors.of(context).border,
      indent: 56,
      endIndent: 16);

  Widget _logoutButton() {
    return GestureDetector(
      onTap: _showLogoutDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
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

  SnackBar _snack(String msg, IconData icon, Color color, {String? subtitle}) {
    return SnackBar(
      backgroundColor: AppColors.of(context).card,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 72),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(msg, style: TextStyle(color: AppColors.of(context).text, fontSize: 13)),
                if (subtitle != null)
                  Text(subtitle, style: TextStyle(color: AppColors.of(context).textMuted, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _veriYedekle() async {
    try {
      final path = await BackupService.backup();
      if (!mounted) return;
      if (path != null) {
        final fileName = path.split('/').last.split('\\').last;
        ScaffoldMessenger.of(context).showSnackBar(_snack(
          fileName,
          Icons.check_circle_outline_rounded,
          Colors.green,
          subtitle: 'Downloads klasörüne kaydedildi',
        ));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(_snack(
        'Yedekleme başarısız: $e',
        Icons.error_outline,
        Colors.redAccent,
      ));
    }
  }

  Future<void> _veriGeriYukle() async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (_) => _dialog(
        icon: Icons.restore_outlined,
        iconColor: Colors.orange,
        title: 'Geri Yükleme',
        body:
            'Mevcut tüm veriler seçtiğiniz yedekle değiştirilecek. Devam etmek istiyor musunuz?',
        actions: Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.pop(context, false),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: AppColors.of(context).border)),
                ),
                child: Text('İptal',
                    style: TextStyle(
                        color: AppColors.of(context).textMuted,
                        fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Devam Et',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );

    if (onay != true) return;

    try {
      final ok = await BackupService.restore();
      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(_snack(
          'Geri yükleme tamamlandı. Uygulamayı yeniden başlatın.',
          Icons.check_circle_outline,
          Colors.green,
        ));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(_snack(
        'Geri yükleme başarısız: $e',
        Icons.error_outline,
        Colors.redAccent,
      ));
    }
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(_snack(
      '$feature yakında aktif olacak',
      Icons.info_outline,
      AppColors.of(context).accent,
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
                      side: BorderSide(color: AppColors.of(context).border)),
                ),
                child: Text('İptal',
                    style: TextStyle(
                        color: AppColors.of(context).textMuted, fontWeight: FontWeight.w600)),
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
        iconColor: AppColors.of(context).accent,
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
                color: AppColors.of(context).accent.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.of(context).accent.withValues(alpha: 0.2)),
              ),
              child: Text(
                'Uygulama ile ilgili sorun yaşıyorsanız yukarıdaki kanallardan bize ulaşabilirsiniz.',
                style: TextStyle(color: AppColors.of(context).textMuted, fontSize: 12, height: 1.6),
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
                child: Text(
                  'Kullanım Şartları ve Sözleşmesi',
                  style: TextStyle(
                    color: AppColors.of(context).accent,
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
        Icon(icon, color: AppColors.of(context).accent, size: 16),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: AppColors.of(context).textMuted, fontSize: 11)),
            Text(value,
                style: TextStyle(
                    color: AppColors.of(context).text,
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
        iconColor: AppColors.of(context).accent,
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
                    child: Text(
                      'Tam metni web sitemizden okumak için tıklayınız',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.of(context).accent,
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
        style: TextStyle(
            color: AppColors.of(context).accent,
            fontWeight: FontWeight.w700,
            fontSize: 13)),
  );

  Widget _gizlilikMetin(String text) => Text(text,
      style: TextStyle(color: AppColors.of(context).textMuted, fontSize: 12, height: 1.6));

  void _showAbout() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppColors.of(context).card,
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
                      color: AppColors.of(context).accent.withValues(alpha: 0.35),
                      width: 1.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset('assets/yeni_ikon.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.of(context).bg,
                        child: Icon(Icons.health_and_safety,
                            color: AppColors.of(context).accent, size: 44),
                      )),
                ),
              ),
              const SizedBox(height: 14),
              Text('PEHLİVAN',
                  style: TextStyle(
                      color: AppColors.of(context).accent,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      letterSpacing: 4)),
              const SizedBox(height: 4),
              Text('PROFESYONEL İSG\nYÖNETİM SİSTEMİ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.of(context).text,
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
                      color: AppColors.of(context).accent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.of(context).accent.withValues(alpha: 0.25)),
                    ),
                    child: Text('v1.0.0',
                        style: TextStyle(
                            color: AppColors.of(context).accent,
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
                      child: Icon(Icons.health_and_safety, color: AppColors.of(context).accent, size: 48),
                    ),
                  );
                },
                icon: Icon(Icons.assignment_outlined, size: 14, color: AppColors.of(context).accent),
                label: Text(
                  'Açık Kaynak Lisansları',
                  style: TextStyle(color: AppColors.of(context).accent, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'İş Sağlığı ve Güvenliği profesyonelleri için geliştirilmiş mobil yönetim platformu.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.of(context).textMuted, fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.of(context).border,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '© 2026 PehlivanİSG · Tüm hakları saklıdır.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.of(context).textMuted, fontSize: 11),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.of(context).accent,
                    foregroundColor: AppColors.of(context).bg,
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
      backgroundColor: AppColors.of(context).card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 14),
            Text(title,
                style: TextStyle(
                    color: AppColors.of(context).text,
                    fontWeight: FontWeight.w800,
                    fontSize: 17)),
            const SizedBox(height: 10),
            if (body != null)
              Text(body,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.of(context).textMuted, fontSize: 13, height: 1.5)),
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
          backgroundColor: AppColors.of(context).accent,
          foregroundColor: AppColors.of(context).bg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: const Text('Kapat', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TEMA KARTI
// ─────────────────────────────────────────────────────────────────────────────

class _TemaKarti extends StatefulWidget {
  @override
  State<_TemaKarti> createState() => _TemaKartiState();
}

class _TemaKartiState extends State<_TemaKarti> {
  @override
  void initState() {
    super.initState();
    themeService.addListener(_onThemeChange);
  }

  @override
  void dispose() {
    themeService.removeListener(_onThemeChange);
    super.dispose();
  }

  void _onThemeChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = themeService.isDark;
    final currentAccent = AppColors.of(context).accent;

    final colors = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18),
        border:
            Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          // ── KARANLK / AYDINLIK toggle ──────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isDark
                        ? Icons.dark_mode_outlined
                        : Icons.light_mode_outlined,
                    color: colors.accent,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isDark ? 'Karanlık Mod' : 'Aydınlık Mod',
                        style: TextStyle(
                            color: colors.text,
                            fontWeight: FontWeight.w600,
                            fontSize: 14),
                      ),
                      Text(
                        isDark
                            ? 'Koyu arka plan, gece dostu'
                            : 'Açık arka plan, gün ışığı',
                        style: TextStyle(
                            color: colors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Transform.scale(
                  scale: 0.85,
                  child: Switch(
                    value: !isDark,
                    onChanged: (v) => themeService.setMode(
                        v ? ThemeMode.light : ThemeMode.dark),
                    activeThumbColor: Theme.of(context).colorScheme.primary,
                    activeTrackColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
                    inactiveThumbColor: colors.textMuted.withValues(alpha: 0.4),
                    inactiveTrackColor: colors.border,
                  ),
                ),
              ],
            ),
          ),

          Divider(
              height: 1,
              color: colors.border,
              indent: 16,
              endIndent: 16),

          // ── ACCENT RENK SEÇİMİ ──────────────────────
          Padding(
            padding:
                const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Vurgu Rengi",
                  style: TextStyle(
                      color: colors.text,
                      fontWeight: FontWeight.w600,
                      fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  "Butonlar, ikonlar ve vurgu noktaları",
                  style: TextStyle(
                      color: colors.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: accentPresetler.map((preset) {
                    final isSelected =
                        currentAccent == preset.renk;
                    return GestureDetector(
                      onTap: () => themeService.setAccent(preset),
                      child: AnimatedContainer(
                        duration:
                            const Duration(milliseconds: 200),
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: preset.renk,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? Colors.white
                                : Colors.transparent,
                            width: 2.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: preset.renk
                                        .withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : [],
                        ),
                        child: isSelected
                            ? const Icon(Icons.check,
                                color: Colors.black,
                                size: 18)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                // Renk adı
                Center(
                  child: Text(
                    accentPresetler
                        .firstWhere(
                          (p) => p.renk == currentAccent,
                          orElse: () => accentPresetler.first,
                        )
                        .ad,
                    style: TextStyle(
                        color: currentAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}