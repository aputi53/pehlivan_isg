import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../../services/biometric_service.dart';

class LockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;

  const LockScreen({super.key, required this.onUnlocked});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen>
    with TickerProviderStateMixin {
  final BiometricService _bio = BiometricService();

  final List<String> _enteredPin = [];
  static const int _pinLength = 6;

  bool _isLoading = false;
  String _statusMessage = '';
  bool _showPin = false;
  bool _pinError = false;

  List<BiometricType> _biometrics = [];

  late AnimationController _shakeController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;

  late Animation<Offset> _shakeAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _shakeAnim = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.07, 0),
    ).animate(
      CurvedAnimation(
        parent: _shakeController,
        curve: Curves.elasticOut,
      ),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnim = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _fadeController.forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
      lowerBound: 0.94,
      upperBound: 1.0,
    )..repeat(reverse: true);

    _pulseAnim = _pulseController;

    _init();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    _biometrics = await _bio.getAvailableBiometrics();

    final biometricEnabled = await _bio.isBiometricEnabled();

    if (biometricEnabled && _biometrics.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 700));
      _authenticate();
    }
  }

  Future<void> _authenticate() async {
    setState(() => _isLoading = true);

    final result = await _bio.authenticate(
      reason: 'Pehlivan İSG uygulamasına giriş için doğrulayın',
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    switch (result) {
      case BiometricResult.success:
        HapticFeedback.lightImpact();
        widget.onUnlocked();
        break;

      case BiometricResult.failed:
        setState(() {
          _statusMessage = 'Doğrulama başarısız. PIN ile girin.';
          _showPin = true;
        });
        break;

      case BiometricResult.notAvailable:
        setState(() => _showPin = true);
        break;

      case BiometricResult.notEnrolled:
        setState(() {
          _statusMessage = 'Biyometrik doğrulama kayıtlı değil.';
          _showPin = true;
        });
        break;

      case BiometricResult.lockedOut:
        setState(() {
          _statusMessage = 'Çok fazla deneme yapıldı. PIN girin.';
          _showPin = true;
        });
        break;
    }
  }

  Future<void> _onPinDigit(String digit) async {
    if (_enteredPin.length >= _pinLength) return;

    HapticFeedback.selectionClick();

    setState(() {
      _enteredPin.add(digit);
      _pinError = false;
      _statusMessage = '';
    });

    if (_enteredPin.length == _pinLength) {
      await Future.delayed(const Duration(milliseconds: 120));

      final pin = _enteredPin.join();

      final correct = await _bio.verifyPin(pin);

      if (correct) {
        HapticFeedback.lightImpact();
        widget.onUnlocked();
      } else {
        HapticFeedback.heavyImpact();

        _shakeController.forward(from: 0);

        setState(() {
          _enteredPin.clear();
          _pinError = true;
          _statusMessage = 'Hatalı PIN. Tekrar deneyin.';
        });
      }
    }
  }

  void _onDelete() {
    if (_enteredPin.isEmpty) return;

    HapticFeedback.selectionClick();

    setState(() {
      _enteredPin.removeLast();
      _pinError = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: const Color(0xFF060913),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Stack(
          children: [
            _buildBackground(),

            SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: Column(
                children: [
                  // Logo ve altındaki metnin daha aşağıda durması için boşluk artırıldı
                  SizedBox(height: padding.top + 70),

                  _buildLogo(),

                  const SizedBox(height: 20),

                  Text(
                    _showPin ? 'PIN KODUNUZU GİRİN' : 'GÜVENLİ GİRİŞ',
                    style: TextStyle(
                      color: const Color(0xFFE8B84B).withOpacity(0.45),
                      fontSize: 11,
                      letterSpacing: 5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const Spacer(),

                  if (_showPin) ...[
                    _buildPinDots(),

                    const SizedBox(height: 14),

                    _buildStatusText(),

                    const SizedBox(height: 36),

                    _buildNumPad(),

                    const SizedBox(height: 18),

                    _buildBiometricFallback(),
                  ] else ...[
                    _buildBiometricPrompt(),
                  ],

                  SizedBox(height: padding.bottom + 42),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.94, end: 1),
      duration: const Duration(milliseconds: 1400),
      curve: Curves.easeOutExpo,
      builder: (context, value, child) {
        return Transform.scale(
            scale: value,
            child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Image.asset(
          'assets/logo.png',
          width: 280,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.health_and_safety_outlined,
            color: Color(0xFFE8B84B),
            size: 120,
          ),
        ),
      ),
    );
  }

  Widget _buildBiometricPrompt() {
    final isFace = _biometrics.contains(BiometricType.face);

    return Column(
      children: [
        GestureDetector(
          onTap: _isLoading ? null : _authenticate,
          child: ScaleTransition(
            scale: _pulseAnim,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFE8B84B).withOpacity(0.18),
                  width: 1,
                ),
              ),
              child: Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.03),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _isLoading
                        ? [
                      const Color(0xFF1C2236),
                      const Color(0xFF0F1420),
                    ]
                        : [
                      const Color(0xFFE8B84B).withOpacity(0.18),
                      const Color(0xFF121829),
                    ],
                  ),
                  border: Border.all(
                    color: _isLoading
                        ? Colors.white12
                        : const Color(0xFFE8B84B).withOpacity(0.85),
                    width: 1.4,
                  ),
                  boxShadow: _isLoading
                      ? []
                      : [
                    BoxShadow(
                      color:
                      const Color(0xFFE8B84B).withOpacity(0.22),
                      blurRadius: 26,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: _isLoading
                    ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(
                    color: Color(0xFFE8B84B),
                    strokeWidth: 2,
                  ),
                )
                    : Icon(
                  isFace
                      ? Icons.face_unlock_outlined
                      : Icons.fingerprint_rounded,
                  color: const Color(0xFFE8B84B),
                  size: 34,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        Text(
          _isLoading
              ? 'Doğrulanıyor...'
              : isFace
              ? 'Yüz Tanıma ile Giriş'
              : 'Parmak İzi ile Giriş',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),

        const SizedBox(height: 28),

        TextButton(
          onPressed: () => setState(() => _showPin = true),
          child: const Text(
            'PIN ile giriş yap',
            style: TextStyle(
              color: Color(0xFFE8B84B),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPinDots() {
    return SlideTransition(
      position: _shakeAnim,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_pinLength, (i) {
          final filled = i < _enteredPin.length;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _pinError
                  ? const Color(0xFFf85149)
                  : filled
                  ? const Color(0xFFE8B84B)
                  : Colors.transparent,
              border: Border.all(
                color: _pinError
                    ? const Color(0xFFf85149)
                    : filled
                    ? const Color(0xFFE8B84B)
                    : Colors.white24,
                width: 1.5,
              ),
              boxShadow: filled && !_pinError
                  ? [
                BoxShadow(
                  color:
                  const Color(0xFFE8B84B).withOpacity(0.45),
                  blurRadius: 8,
                ),
              ]
                  : [],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStatusText() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: _statusMessage.isNotEmpty
          ? Text(
        _statusMessage,
        key: ValueKey(_statusMessage),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: _pinError
              ? const Color(0xFFf85149)
              : Colors.white38,
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
            if (key.isEmpty) {
              return const SizedBox(width: 88, height: 70);
            }

            return _buildKey(key);
          }).toList(),
        );
      }).toList(),
    );
  }

  Widget _buildKey(String key) {
    final isDel = key == 'del';

    return GestureDetector(
      onTap: isDel ? _onDelete : () => _onPinDigit(key),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 88,
        height: 70,
        alignment: Alignment.center,
        child: isDel
            ? const Icon(
          Icons.backspace_outlined,
          color: Colors.white38,
          size: 22,
        )
            : Text(
          key,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w300,
          ),
        ),
      ),
    );
  }

  Widget _buildBiometricFallback() {
    if (_biometrics.isEmpty) {
      return const SizedBox.shrink();
    }

    final isFace = _biometrics.contains(BiometricType.face);

    return TextButton.icon(
      onPressed: _authenticate,
      icon: Icon(
        isFace
            ? Icons.face_unlock_outlined
            : Icons.fingerprint_rounded,
        color: const Color(0xFFE8B84B),
        size: 18,
      ),
      label: Text(
        isFace
            ? 'Yüz tanıma ile giriş'
            : 'Parmak izi ile giriş',
        style: const TextStyle(
          color: Color(0xFFE8B84B),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: CustomPaint(
        painter: _BgPainter(),
      ),
    );
  }
}

class _BgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Logonun yeni dikey konumuna (height * 0.23 -> height * 0.28) göre parlamanın merkezi de senkronize olarak aşağı çekildi.
    final centerTop = Offset(size.width * 0.5, size.height * 0.28);

    final centerBottom = Offset(
      size.width * 0.5,
      size.height * 0.76,
    );

    final bgPaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFF10162A),
          Color(0xFF060913),
        ],
        radius: 1.15,
      ).createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      bgPaint,
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke;

    // Üst taraftaki logo etrafındaki keskin altın halkalar kaldırıldı.

    final bottomRings = [
      {'radius': 90.0, 'opacity': 0.06, 'width': 1.0},
      {'radius': 160.0, 'opacity': 0.02, 'width': 1.0},
    ];

    for (var ring in bottomRings) {
      paint
        ..color = const Color(0xFFE8B84B)
            .withOpacity(ring['opacity'] as double)
        ..strokeWidth = ring['width'] as double;

      canvas.drawCircle(
        centerBottom,
        ring['radius'] as double,
        paint,
      );
    }

    // Yumuşak parlamanın (glow) konumu da logo ile birlikte aşağı alındı
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFE8B84B).withOpacity(0.10),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: centerTop,
          radius: 180,
        ),
      );

    canvas.drawCircle(
      centerTop,
      180,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}