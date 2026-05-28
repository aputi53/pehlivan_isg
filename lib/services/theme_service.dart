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

// ─── ThemeData üreteci ───────────────────────────────────
ThemeData buildThemeData(Color accent, Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final cs = ColorScheme.fromSeed(
    seedColor: accent,
    brightness: brightness,
  ).copyWith(primary: accent, secondary: accent);

  return ThemeData(
    brightness: brightness,
    colorScheme: cs,
    useMaterial3: false,
    scaffoldBackgroundColor:
        isDark ? const Color(0xFF0D1117) : const Color(0xFFF0F2F5),
    appBarTheme: AppBarTheme(
      backgroundColor:
          isDark ? const Color(0xFF161B22) : const Color(0xFFFFFFFF),
      foregroundColor: isDark ? Colors.white : const Color(0xFF1A1A2E),
      elevation: 0,
    ),
    cardColor:
        isDark ? const Color(0xFF161B22) : const Color(0xFFFFFFFF),
    drawerTheme: DrawerThemeData(
      backgroundColor:
          isDark ? const Color(0xFF0D1117) : const Color(0xFFFFFFFF),
    ),
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
