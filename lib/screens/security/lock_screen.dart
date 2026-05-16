import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
// ÇÖZÜM: Yanlış göreceli yol yerine mutlak package yolu tanımlandı.
import 'package:pehlivan_isg/services/biometric_service.dart';

/// Uygulama açılırken gösterilen kilit ekranı.
/// Biyometrik (parmak izi / yüz) ile ya da PIN ile açılır.
class LockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  const LockScreen({super.key, required this.onUnlocked});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with SingleTickerProviderStateMixin {
  final BiometricService _bio = BiometricService();
  final List<String> _enteredPin = [];
  static const int _pinLength = 6;

  bool _isLoading = false;
  String _statusMessage = '';
  bool _showPin = false;
  bool _pinError = false;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  List<BiometricType> _biometrics = [];

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticOut),
    );
    _init();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    _biometrics = await _bio.getAvailableBiometrics();
    final biometricEnabled = await _bio.isBiometricEnabled();
    if (biometricEnabled && _biometrics.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 600));
      _authenticate();
    }
  }

  Future<void> _authenticate() async {
    setState(() => _isLoading = true);
    final result = await _bio.authenticate(
      reason: 'Uygulamaya giriş yapmak için kimliğinizi doğrulayın',
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    // ÇÖZÜM: 'const' ifadeleri switch-case bloklarında enum yapılarıyla çakışmaması için kaldırıldı.
    if (result == BiometricResult.success) {
      widget.onUnlocked();
    } else if (result == BiometricResult.failed) {
      setState(() => _statusMessage = 'Doğrulama başarısız. PIN ile deneyin.');
      _showPinPad();
    } else if (result == BiometricResult.notAvailable) {
      _showPinPad();
    } else if (result == BiometricResult.notEnrolled) {
      setState(() => _statusMessage = 'Biyometri kayıtlı değil. PIN girin.');
      _showPinPad();
    } else if (result == BiometricResult.lockedOut) {
      setState(() => _statusMessage = 'Çok fazla hatalı deneme. PIN ile girin.');
      _showPinPad();
    }
  }

  void _showPinPad() => setState(() => _showPin = true);

  Future<void> _onPinDigit(String digit) async {
    if (_enteredPin.length >= _pinLength) return;
    setState(() {
      _enteredPin.add(digit);
      _pinError = false;
    });

    if (_enteredPin.length == _pinLength) {
      await Future.delayed(const Duration(milliseconds: 120));
      final pin = _enteredPin.join();
      final correct = await _bio.verifyPin(pin);
      if (correct) {
        widget.onUnlocked();
      } else {
        _shakeController.forward(from: 0);
        setState(() {
          _enteredPin.clear();
          _pinError = true;
          _statusMessage = 'Hatalı PIN. Tekrar deneyin.';
        });
        HapticFeedback.heavyImpact();
      }
    }
  }

  void _onDelete() {
    if (_enteredPin.isEmpty) return;
    setState(() {
      _enteredPin.removeLast();
      _pinError = false;
    });
  }

  // -------------------------------------------------------
  // BUILD
  // -------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0d1117),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            _buildHeader(),
            const Spacer(),
            if (_showPin) ...[
              _buildPinDots(),
              const SizedBox(height: 12),
              _buildStatus(),
              const SizedBox(height: 32),
              _buildNumPad(),
              const SizedBox(height: 24),
              _buildBiometricFallback(),
            ] else ...[
              _buildBiometricPrompt(),
            ],
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF161b22),
            border: Border.all(color: const Color(0xFF30363d), width: 1.5),
          ),
          child: const Icon(Icons.lock_outline_rounded, color: Color(0xFF58a6ff), size: 32),
        ),
        const SizedBox(height: 20),
        const Text(
          'Pehlivan İSG',
          style: TextStyle(
            color: Color(0xFFe6edf3),
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _showPin ? 'PIN kodunuzu girin' : 'Devam etmek için kimliğinizi doğrulayın',
          style: const TextStyle(color: Color(0xFF8b949e), fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildBiometricPrompt() {
    return Column(
      children: [
        if (_isLoading)
          const CircularProgressIndicator(color: Color(0xFF58a6ff), strokeWidth: 2)
        else
          GestureDetector(
            onTap: _authenticate,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF161b22),
                border: Border.all(color: const Color(0xFF58a6ff), width: 1.5),
              ),
              child: Icon(
                _biometrics.contains(BiometricType.face)
                    ? Icons.face_unlock_outlined
                    : Icons.fingerprint_rounded,
                color: const Color(0xFF58a6ff),
                size: 36,
              ),
            ),
          ),
        const SizedBox(height: 16),
        Text(
          _biometrics.contains(BiometricType.face) ? 'Yüz Tanıma' : 'Parmak İzi',
          style: const TextStyle(color: Color(0xFF8b949e), fontSize: 13),
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: _showPinPad,
          child: const Text(
            'PIN ile giriş yap',
            style: TextStyle(color: Color(0xFF58a6ff), fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildPinDots() {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        final offset = _pinError
            ? 12 * (0.5 - (_shakeAnimation.value - 0.5).abs())
            : 0.0;
        return Transform.translate(
          offset: Offset(offset * 8, 0),
          child: child,
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_pinLength, (i) {
          final filled = i < _enteredPin.length;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(horizontal: 8),
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _pinError
                  ? const Color(0xFFf85149)
                  : filled
                  ? const Color(0xFF58a6ff)
                  : Colors.transparent,
              border: Border.all(
                color: _pinError
                    ? const Color(0xFFf85149)
                    : filled
                    ? const Color(0xFF58a6ff)
                    : const Color(0xFF30363d),
                width: 1.5,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStatus() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: _statusMessage.isNotEmpty
          ? Text(
        _statusMessage,
        key: ValueKey(_statusMessage),
        style: TextStyle(
          color: _pinError ? const Color(0xFFf85149) : const Color(0xFF8b949e),
          fontSize: 13,
        ),
      )
          : const SizedBox(height: 18),
    );
  }

  Widget _buildNumPad() {
    const keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'del'],
    ];
    return Column(
      children: keys.map((row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: row.map((key) {
            if (key.isEmpty) return const SizedBox(width: 88, height: 72);
            return _NumKey(
              label: key,
              onTap: key == 'del' ? _onDelete : () => _onPinDigit(key),
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  Widget _buildBiometricFallback() {
    if (_biometrics.isEmpty) return const SizedBox.shrink();
    return TextButton.icon(
      onPressed: _authenticate,
      icon: Icon(
        _biometrics.contains(BiometricType.face)
            ? Icons.face_unlock_outlined
            : Icons.fingerprint_rounded,
        color: const Color(0xFF58a6ff),
        size: 18,
      ),
      label: const Text(
        'Biyometrik ile giriş',
        style: TextStyle(color: Color(0xFF58a6ff), fontSize: 13),
      ),
    );
  }
}

class _NumKey extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _NumKey({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDel = label == 'del';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 88,
        height: 72,
        alignment: Alignment.center,
        child: isDel
            ? const Icon(Icons.backspace_outlined, color: Color(0xFF8b949e), size: 22)
            : Text(
          label,
          style: const TextStyle(
            color: Color(0xFFe6edf3),
            fontSize: 24,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}