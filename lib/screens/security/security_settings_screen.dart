import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../../services/biometric_service.dart';
import 'change_pin_screen.dart';

/// Güvenlik ayarları ekranı.
/// Biyometrik kilit açma/kapama + PIN oluşturma/değiştirme.
class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  final BiometricService _bio = BiometricService();

  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  bool _hasPin = false;
  List<BiometricType> _biometrics = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final supported = await _bio.isDeviceSupported();
    final biometrics = await _bio.getAvailableBiometrics();
    final enabled = await _bio.isBiometricEnabled();
    final hasPin = await _bio.hasPin();

    if (!mounted) return;
    setState(() {
      _biometricAvailable = supported && biometrics.isNotEmpty;
      _biometrics = biometrics;
      _biometricEnabled = enabled;
      _hasPin = hasPin;
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      // Açmadan önce biyometrik doğrula
      final result = await _bio.authenticate(
        reason: 'Biyometrik kilidi etkinleştirmek için doğrulayın',
      );
      if (result != BiometricResult.success) return;
    }
    await _bio.setBiometricEnabled(value);
    setState(() => _biometricEnabled = value);
  }

  void _goChangePin() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChangePinScreen()),
    );
    _load();
  }

  // -------------------------------------------------------
  // Build
  // -------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0d1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0d1117),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF8b949e), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Güvenlik',
          style: TextStyle(
            color: Color(0xFFe6edf3),
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 0.5, color: const Color(0xFF21262d)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          _sectionHeader('KİLİT AÇMA'),
          if (_biometricAvailable) ...[
            _buildBiometricTile(),
            _divider(),
          ],
          _buildPinTile(),
          const SizedBox(height: 32),
          _sectionHeader('BİLGİ'),
          _buildInfoCard(),
        ],
      ),
    );
  }

  // -------------------------------------------------------
  // Tiles
  // -------------------------------------------------------
  Widget _buildBiometricTile() {
    final hasFace = _biometrics.contains(BiometricType.face);
    final hasFingerprint = _biometrics.contains(BiometricType.fingerprint) ||
        _biometrics.contains(BiometricType.strong);

    String label = 'Biyometrik Kilit';
    IconData icon = Icons.fingerprint_rounded;

    if (hasFace && hasFingerprint) {
      label = 'Parmak İzi ve Yüz Tanıma';
      icon = Icons.security_rounded;
    } else if (hasFace) {
      label = 'Yüz Tanıma';
      icon = Icons.face_unlock_outlined;
    } else {
      label = 'Parmak İzi';
      icon = Icons.fingerprint_rounded;
    }

    return _SettingsTile(
      icon: icon,
      iconColor: const Color(0xFF58a6ff),
      title: label,
      subtitle: _biometricEnabled ? 'Etkin' : 'Devre dışı',
      trailing: Switch.adaptive(
        value: _biometricEnabled,
        onChanged: _biometricAvailable ? _toggleBiometric : null,
        activeColor: const Color(0xFF238636),
        activeTrackColor: const Color(0xFF238636).withOpacity(0.3),
        inactiveThumbColor: const Color(0xFF8b949e),
        inactiveTrackColor: const Color(0xFF21262d),
      ),
    );
  }

  Widget _buildPinTile() {
    return _SettingsTile(
      icon: Icons.pin_outlined,
      iconColor: const Color(0xFFd29922),
      title: _hasPin ? 'PIN Değiştir' : 'PIN Oluştur',
      subtitle: _hasPin ? '6 haneli şifrenizi güncelleyin' : 'Uygulama kilidi için PIN belirleyin',
      trailing: const Icon(Icons.chevron_right_rounded,
          color: Color(0xFF30363d), size: 20),
      onTap: _goChangePin,
    );
  }

  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161b22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF21262d)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              color: Color(0xFF8b949e), size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'PIN kodunuz yalnızca bu cihazda şifreli olarak saklanır. '
              'Biyometrik doğrulama cihazınızın güvenli donanımını kullanır.',
              style: const TextStyle(
                color: Color(0xFF8b949e),
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------
  // Helpers
  // -------------------------------------------------------
  Widget _sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF8b949e),
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _divider() => Container(
        height: 0.5,
        margin: const EdgeInsets.only(left: 60),
        color: const Color(0xFF21262d),
      );
}

// -------------------------------------------------------
// Reusable settings tile
// -------------------------------------------------------
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF161b22),
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.white.withOpacity(0.03),
        highlightColor: Colors.white.withOpacity(0.02),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFFe6edf3),
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF8b949e),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}
