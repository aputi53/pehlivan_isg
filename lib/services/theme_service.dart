import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';

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

// ─── ThemeData üreteci (Material 3 + Google Fonts) ───────
ThemeData buildThemeData(Color accent, Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final appColors = isDark ? AppColors.dark(accent) : AppColors.light(accent);

  final cs = ColorScheme.fromSeed(
    seedColor: accent,
    brightness: brightness,
  ).copyWith(
    primary: accent,
    secondary: accent,
    surface: appColors.card,
    onSurface: appColors.text,
    surfaceContainerHighest: appColors.cardDark,
  );

  final baseTextTheme =
      isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme;

  final textTheme = GoogleFonts.interTextTheme(baseTextTheme).copyWith(
    displayLarge: GoogleFonts.outfit(
        color: appColors.text, fontWeight: FontWeight.bold, fontSize: 32),
    displayMedium: GoogleFonts.outfit(
        color: appColors.text, fontWeight: FontWeight.bold, fontSize: 26),
    displaySmall: GoogleFonts.outfit(
        color: appColors.text, fontWeight: FontWeight.bold, fontSize: 22),
    headlineLarge: GoogleFonts.outfit(
        color: appColors.text, fontWeight: FontWeight.w700, fontSize: 20),
    headlineMedium: GoogleFonts.outfit(
        color: appColors.text, fontWeight: FontWeight.w700, fontSize: 18),
    headlineSmall: GoogleFonts.outfit(
        color: appColors.text, fontWeight: FontWeight.w600, fontSize: 16),
    titleLarge: GoogleFonts.inter(
        color: appColors.text, fontWeight: FontWeight.w600, fontSize: 16),
    titleMedium: GoogleFonts.inter(
        color: appColors.text, fontWeight: FontWeight.w600, fontSize: 14),
    titleSmall: GoogleFonts.inter(
        color: appColors.text, fontWeight: FontWeight.w500, fontSize: 13),
    bodyLarge: GoogleFonts.inter(color: appColors.text, fontSize: 16),
    bodyMedium: GoogleFonts.inter(color: appColors.text, fontSize: 14),
    bodySmall: GoogleFonts.inter(color: appColors.textMuted, fontSize: 12),
    labelLarge: GoogleFonts.inter(
        color: appColors.text, fontWeight: FontWeight.w500, fontSize: 14),
    labelMedium: GoogleFonts.inter(color: appColors.textMuted, fontSize: 12),
    labelSmall: GoogleFonts.inter(color: appColors.textMuted, fontSize: 11),
  );

  return ThemeData(
    brightness: brightness,
    colorScheme: cs,
    useMaterial3: true,
    extensions: [appColors],
    scaffoldBackgroundColor: appColors.bg,
    textTheme: textTheme,

    // AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: appColors.card,
      foregroundColor: appColors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.outfit(
        color: appColors.text,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),

    // Card
    cardTheme: CardThemeData(
      color: appColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: appColors.border, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),

    // Drawer
    drawerTheme: DrawerThemeData(backgroundColor: appColors.bg),

    // NavigationBar (Bottom Nav — Material 3)
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: appColors.card,
      indicatorColor: accent.withValues(alpha: 0.15),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 68,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: accent, size: 24);
        }
        return IconThemeData(
            color: appColors.textMuted.withValues(alpha: 0.8), size: 22);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.inter(
              color: accent, fontSize: 11, fontWeight: FontWeight.w600);
        }
        return GoogleFonts.inter(
            color: appColors.textMuted.withValues(alpha: 0.8), fontSize: 11);
      }),
    ),

    // Switch
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? accent : null),
      trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? accent.withValues(alpha: 0.4)
              : null),
    ),

    // FAB
    floatingActionButtonTheme:
        FloatingActionButtonThemeData(backgroundColor: accent),

    // ElevatedButton
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    ),

    // FilledButton (M3)
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),

    // Input
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFE8EAF0),
      labelStyle:
          TextStyle(color: isDark ? Colors.white54 : Colors.black54),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: accent, width: 1.5),
      ),
    ),

    // Divider
    dividerTheme: DividerThemeData(
      color: appColors.border,
      thickness: 1,
      space: 1,
    ),

    // ListTile
    listTileTheme: ListTileThemeData(
      tileColor: Colors.transparent,
      iconColor: appColors.textMuted,
      textColor: appColors.text,
    ),

    // Chip
    chipTheme: ChipThemeData(
      backgroundColor: appColors.cardDark,
      selectedColor: accent.withValues(alpha: 0.2),
      labelStyle: GoogleFonts.inter(color: appColors.text, fontSize: 12),
      side: BorderSide(color: appColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),

    // SnackBar
    snackBarTheme: SnackBarThemeData(
      backgroundColor: appColors.cardDark,
      contentTextStyle: GoogleFonts.inter(color: appColors.text),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    // BottomSheet
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: appColors.card,
      modalBackgroundColor: appColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),

    // Dialog
    dialogTheme: DialogThemeData(
      backgroundColor: appColors.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: GoogleFonts.outfit(
          color: appColors.text, fontSize: 18, fontWeight: FontWeight.bold),
    ),
  );
}
