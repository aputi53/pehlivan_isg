import 'package:flutter/material.dart';
// Proje adın pehlivan_isg olduğu için mutlak yollarla (package:) çağırmak her zaman en güvenli yoldur:
import 'package:pehlivan_isg/screens/security/lock_screen.dart';

// UYARI: Eğer biometric_service.dart dosyan tam olarak hangi klasördeyse
// aşağıdaki yollardan uygun olanının önündeki yorum satırını kaldır, diğerini sil:
// Eğer lib/utils/ veya lib/services/ altındaysa ona göre güncelle. Şimdilik lib/ altındaki varsayılan yola çektim:
import 'package:pehlivan_isg/services/biometric_service.dart';

/// Ana uygulama sarmalayıcı.
/// Uygulama arka plandan döndüğünde (resume) otomatik kilit ekranı gösterir.
class AppLockWrapper extends StatefulWidget {
  final Widget child;
  const AppLockWrapper({super.key, required this.child});

  @override
  State<AppLockWrapper> createState() => _AppLockWrapperState();
}

class _AppLockWrapperState extends State<AppLockWrapper>
    with WidgetsBindingObserver {
  // Yukarıdaki import doğru olunca buradaki hatalar kendiliğinden çözülecek
  final BiometricService _bio = BiometricService();

  bool _locked = false;
  bool _initialized = false;
  DateTime? _backgroundTime;

  // Arka planda bu kadar saniye geçince yeniden kilitle
  static const int _lockAfterSeconds = 30;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkInitialLock();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _checkInitialLock() async {
    final hasPin = await _bio.hasPin();
    final biometricEnabled = await _bio.isBiometricEnabled();
    setState(() {
      _locked = hasPin || biometricEnabled;
      _initialized = true;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _backgroundTime = DateTime.now();
        break;
      case AppLifecycleState.resumed:
        if (_backgroundTime != null) {
          final elapsed = DateTime.now().difference(_backgroundTime!).inSeconds;
          if (elapsed >= _lockAfterSeconds) {
            _requireLock();
          }
        }
        break;
      default:
        break;
    }
  }

  Future<void> _requireLock() async {
    final hasPin = await _bio.hasPin();
    final biometricEnabled = await _bio.isBiometricEnabled();
    if (hasPin || biometricEnabled) {
      setState(() => _locked = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        backgroundColor: Color(0xFF0d1117),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF58a6ff),
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (_locked) {
      return LockScreen(
        onUnlocked: () => setState(() => _locked = false),
      );
    }

    return widget.child;
  }
}