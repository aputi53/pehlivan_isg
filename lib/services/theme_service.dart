import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ─── Accent renk presetleri ──────────────────────────────
class AppAccent {
  final String key;
  final String ad;
  final Color renk;
  const AppAccent(this.key, this.ad, this.renk);
}

const List<AppAccent> accentPresetler = [
  AppAccent('altin',   'Altın',      Color(0xFFE8B84B)),
  AppAccent('yesil',   'ISG Yeşil',  Color(0xFF4CAF50)),
  AppAccent('mavi',    'Okyanus',    Color(0xFF29B6F6)),
  AppAccent('kirmizi', 'Kırmızı',    Color(0xFFEF5350)),
  AppAccent('mor',     'Mor',        Color(0xFF9C27B0)),
  AppAccent('gumus',   'Gümüş',      Color(0xFFB0BEC5)),
];

// ─── Tema konfigürasyonu ──────────────────────────────────
class ThemeConfig {
  final ThemeMode mode;
  final Color accent;
  const ThemeConfig({required this.mode, required this.accent});
}

// ─── Tema servisi (ValueNotifier) ────────────────────────
class ThemeService extends ValueNotifier<ThemeConfig> {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      sharedPreferencesName: 'PehlivanISG_Storage',
    ),
  );

  ThemeService()
      : super(const ThemeConfig(
          mode: ThemeMode.dark,
          accent: Color(0xFFE8B84B),
        )) {
    _load();
  }

  Future<void> _load() async {
    final modeStr = await _storage.read(key: 'theme_mode') ?? 'dark';
    final accentKey = await _storage.read(key: 'theme_accent') ?? 'altin';
    final mode = modeStr == 'light' ? ThemeMode.light : ThemeMode.dark;
    final preset = accentPresetler.firstWhere(
      (c) => c.key == accentKey,
      orElse: () => accentPresetler.first,
    );
    value = ThemeConfig(mode: mode, accent: preset.renk);
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    await _storage.write(
        key: 'theme_mode',
        value: mode == ThemeMode.light ? 'light' : 'dark');
    value = ThemeConfig(mode: mode, accent: value.accent);
    notifyListeners();
  }

  Future<void> setAccent(AppAccent preset) async {
    await _storage.write(key: 'theme_accent', value: preset.key);
    value = ThemeConfig(mode: value.mode, accent: preset.renk);
    notifyListeners();
  }

  // Kolay erişim
  ThemeMode get mode => value.mode;
  Color get accent => value.accent;
  bool get isDark => value.mode == ThemeMode.dark;
}

final themeService = ThemeService();

// ─── Semantik renk uzantısı ──────────────────────────────
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color bg;
  final Color card;
  final Color cardDark;
  final Color input;
  final Color accent;
  final Color text;
  final Color textMuted;
  final Color border;

  const AppColors._({
    required this.bg,
    required this.card,
    required this.cardDark,
    required this.input,
    required this.accent,
    required this.text,
    required this.textMuted,
    required this.border,
  });

  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>() ??
      AppColors.dark(const Color(0xFFE8B84B));

  factory AppColors.dark(Color accent) => AppColors._(
        bg: const Color(0xFF0D1117),
        card: const Color(0xFF161B22),
        cardDark: const Color(0xFF1C2333),
        input: const Color(0xFF0D1117),
        accent: accent,
        text: Colors.white,
        textMuted: const Color(0xFF8B949E),
        border: Colors.white.withValues(alpha: 0.08),
      );

  factory AppColors.light(Color accent) => AppColors._(
        bg: const Color(0xFFF0F2F5),
        card: Colors.white,
        cardDark: const Color(0xFFE8EAF0),
        input: const Color(0xFFE8EAF0),
        accent: accent,
        text: const Color(0xFF1A1A2E),
        textMuted: const Color(0xFF6B7280),
        border: Colors.black.withValues(alpha: 0.08),
      );

  @override
  AppColors copyWith({
    Color? bg, Color? card, Color? cardDark, Color? input,
    Color? accent, Color? text, Color? textMuted, Color? border,
  }) =>
      AppColors._(
        bg: bg ?? this.bg, card: card ?? this.card,
        cardDark: cardDark ?? this.cardDark, input: input ?? this.input,
        accent: accent ?? this.accent, text: text ?? this.text,
        textMuted: textMuted ?? this.textMuted, border: border ?? this.border,
      );

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) =>
      t < 0.5 ? this : (other as AppColors? ?? this);
}

// ─── ThemeData üreteci ───────────────────────────────────
ThemeData buildThemeData(Color accent, Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final cs = ColorScheme.fromSeed(
    seedColor: accent,
    brightness: brightness,
  ).copyWith(primary: accent, secondary: accent);

  final appColors =
      isDark ? AppColors.dark(accent) : AppColors.light(accent);

  return ThemeData(
    brightness: brightness,
    colorScheme: cs,
    useMaterial3: false,
    extensions: [appColors],
    scaffoldBackgroundColor: appColors.bg,
    appBarTheme: AppBarTheme(
      backgroundColor: appColors.card,
      foregroundColor: appColors.text,
      elevation: 0,
    ),
    cardColor: appColors.card,
    drawerTheme: DrawerThemeData(backgroundColor: appColors.bg),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? accent : null),
      trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? accent.withValues(alpha: 0.4)
              : null),
    ),
    floatingActionButtonTheme:
        FloatingActionButtonThemeData(backgroundColor: accent),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.black,
      ),
    ),
    textTheme: (isDark
            ? ThemeData.dark().textTheme
            : ThemeData.light().textTheme)
        .apply(
      bodyColor: isDark ? Colors.white : const Color(0xFF1A1A2E),
      displayColor: isDark ? Colors.white : const Color(0xFF1A1A2E),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFE8EAF0),
      labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
  );
}
