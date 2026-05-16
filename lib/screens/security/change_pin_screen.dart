import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/biometric_service.dart';

/// Şifre değiştir ekranı — 3 adımlı akış:
///   1. Mevcut PIN doğrula
///   2. Yeni PIN gir
///   3. Yeni PIN'i onayla
class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen>
    with SingleTickerProviderStateMixin {
  final BiometricService _bio = BiometricService();
  static const int _pinLength = 6;

  _PinStep _step = _PinStep.current;
  final List<String> _entered = [];
  List<String> _newPin = [];

  bool _error = false;
  String _errorMessage = '';

  late AnimationController _shakeCtrl;
  late Animation<Offset> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _shakeAnim = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.06, 0),
    ).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticOut));
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  // -------------------------------------------------------
  // Dokunuş
  // -------------------------------------------------------
  Future<void> _onKey(String key) async {
    if (key == 'del') {
      if (_entered.isEmpty) return;
      setState(() {
        _entered.removeLast();
        _error = false;
      });
      return;
    }
    if (_entered.length >= _pinLength) return;
    setState(() {
      _entered.add(key);
      _error = false;
    });
    if (_entered.length == _pinLength) {
      await Future.delayed(const Duration(milliseconds: 150));
      _evaluate();
    }
  }

  Future<void> _evaluate() async {
    final pin = _entered.join();

    switch (_step) {
      case _PinStep.current:
        final hasPin = await _bio.hasPin();
        if (!hasPin) {
          // İlk kez PIN oluşturuluyorsa mevcut kontrolü atla
          setState(() {
            _entered.clear();
            _step = _PinStep.newPin;
          });
          return;
        }
        final ok = await _bio.verifyPin(pin);
        if (ok) {
          setState(() {
            _entered.clear();
            _step = _PinStep.newPin;
          });
        } else {
          _shakeError('Mevcut PIN hatalı. Tekrar deneyin.');
        }
        break;

      case _PinStep.newPin:
        _newPin = List.from(_entered);
        setState(() {
          _entered.clear();
          _step = _PinStep.confirm;
        });
        break;

      case _PinStep.confirm:
        if (pin == _newPin.join()) {
          await _bio.setPin(pin);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('PIN başarıyla güncellendi'),
                backgroundColor: Color(0xFF238636),
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.pop(context);
          }
        } else {
          _shakeError('PIN\'ler eşleşmiyor. Tekrar deneyin.');
          setState(() {
            _newPin = [];
            _step = _PinStep.newPin;
          });
        }
        break;
    }
  }

  void _shakeError(String msg) {
    HapticFeedback.heavyImpact();
    _shakeCtrl.forward(from: 0);
    setState(() {
      _entered.clear();
      _error = true;
      _errorMessage = msg;
    });
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
          'Şifre Değiştir',
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
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 32),
            _buildStepIndicator(),
            const SizedBox(height: 40),
            _buildTitle(),
            const SizedBox(height: 32),
            _buildPinDots(),
            const SizedBox(height: 12),
            _buildErrorText(),
            const Spacer(),
            _buildNumPad(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------
  // Step indicator — 3 adımlı
  // -------------------------------------------------------
  Widget _buildStepIndicator() {
    final steps = [_PinStep.current, _PinStep.newPin, _PinStep.confirm];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: steps.asMap().entries.map((e) {
        final idx = e.key;
        final s = e.value;
        final isActive = _step == s;
        final isDone = steps.indexOf(_step) > idx;
        return Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: isActive ? 28 : 8,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: isDone
                    ? const Color(0xFF238636)
                    : isActive
                        ? const Color(0xFF58a6ff)
                        : const Color(0xFF21262d),
              ),
            ),
            if (idx < 2)
              Container(
                width: 20,
                height: 1,
                color: const Color(0xFF21262d),
                margin: const EdgeInsets.symmetric(horizontal: 4),
              ),
          ],
        );
      }).toList(),
    );
  }

  // -------------------------------------------------------
  // Başlık
  // -------------------------------------------------------
  Widget _buildTitle() {
    final titles = {
      _PinStep.current: ('Mevcut PIN', 'Güvenlik için mevcut şifrenizi girin'),
      _PinStep.newPin: ('Yeni PIN', '6 haneli yeni şifrenizi belirleyin'),
      _PinStep.confirm: ('PIN Onayla', 'Yeni şifrenizi tekrar girin'),
    };
    final (title, sub) = titles[_step]!;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Column(
        key: ValueKey(_step),
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFe6edf3),
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            sub,
            style: const TextStyle(color: Color(0xFF8b949e), fontSize: 13),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------
  // PIN noktaları
  // -------------------------------------------------------
  Widget _buildPinDots() {
    return SlideTransition(
      position: _shakeAnim,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_pinLength, (i) {
          final filled = i < _entered.length;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            margin: const EdgeInsets.symmetric(horizontal: 9),
            width: 13,
            height: 13,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _error
                  ? const Color(0xFFf85149)
                  : filled
                      ? const Color(0xFF58a6ff)
                      : Colors.transparent,
              border: Border.all(
                color: _error
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

  Widget _buildErrorText() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: _error
          ? Padding(
              key: ValueKey(_errorMessage),
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Color(0xFFf85149), fontSize: 13, height: 1.5),
              ),
            )
          : const SizedBox(height: 20),
    );
  }

  // -------------------------------------------------------
  // Sayı pedi
  // -------------------------------------------------------
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
            if (key.isEmpty) return const SizedBox(width: 90, height: 72);
            return _buildKey(key);
          }).toList(),
        );
      }).toList(),
    );
  }

  Widget _buildKey(String key) {
    final isDel = key == 'del';
    return GestureDetector(
      onTap: () => _onKey(key),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 90,
        height: 72,
        alignment: Alignment.center,
        child: isDel
            ? const Icon(Icons.backspace_outlined,
                color: Color(0xFF8b949e), size: 22)
            : Text(
                key,
                style: const TextStyle(
                  color: Color(0xFFe6edf3),
                  fontSize: 26,
                  fontWeight: FontWeight.w300,
                ),
              ),
      ),
    );
  }
}

enum _PinStep { current, newPin, confirm }
