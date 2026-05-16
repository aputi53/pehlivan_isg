import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const String _pinKey = 'app_pin';
  static const String _biometricEnabledKey = 'biometric_enabled';

  // -------------------------------------------------------
  // Cihazın biyometrik destekleyip desteklemediğini kontrol et
  // -------------------------------------------------------
  Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  // -------------------------------------------------------
  // Kayıtlı biyometri türlerini döndür (parmak izi / yüz)
  // -------------------------------------------------------
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }

  // -------------------------------------------------------
  // Biyometri etkin mi? (kullanıcı tercihi)
  // -------------------------------------------------------
  Future<bool> isBiometricEnabled() async {
    final val = await _storage.read(key: _biometricEnabledKey);
    return val == 'true';
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _biometricEnabledKey, value: enabled.toString());
  }

  // -------------------------------------------------------
  // Biyometrik kimlik doğrulama (parmak izi veya yüz tanıma)
  // -------------------------------------------------------
  Future<BiometricResult> authenticate({
    String reason = 'Kimliğinizi doğrulayın',
  }) async {
    try {
      final canAuth = await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
      if (!canAuth) return BiometricResult.notAvailable;

      final biometrics = await getAvailableBiometrics();
      if (biometrics.isEmpty) return BiometricResult.notEnrolled;

      final authenticated = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // false = PIN/şifre yedek olarak izin ver
          useErrorDialogs: true,
        ),
      );

      return authenticated ? BiometricResult.success : BiometricResult.failed;
    } on PlatformException catch (e) {
      if (e.code == 'NotEnrolled') return BiometricResult.notEnrolled;
      if (e.code == 'LockedOut' || e.code == 'PermanentlyLockedOut') {
        return BiometricResult.lockedOut;
      }
      return BiometricResult.failed;
    }
  }

  // -------------------------------------------------------
  // PIN yönetimi (şifreli depolama)
  // -------------------------------------------------------
  Future<bool> hasPin() async {
    final pin = await _storage.read(key: _pinKey);
    return pin != null && pin.isNotEmpty;
  }

  Future<void> setPin(String pin) async {
    await _storage.write(key: _pinKey, value: pin);
  }

  Future<bool> verifyPin(String pin) async {
    final stored = await _storage.read(key: _pinKey);
    return stored == pin;
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}

enum BiometricResult {
  success,
  failed,
  notAvailable,
  notEnrolled,
  lockedOut,
}
