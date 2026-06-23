import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeProvider = StateNotifierProvider<ThemeController, AppThemeState>(
  (ref) => ThemeController(),
);

class AppThemeState {
  final ThemeMode themeMode;
  final FlexScheme scheme;
  final Color? customSeed;

  const AppThemeState({
    this.themeMode = ThemeMode.system,
    this.scheme = FlexScheme.deepPurple,
    this.customSeed,
  });

  AppThemeState copyWith({
    ThemeMode? themeMode,
    FlexScheme? scheme,
    Color? customSeed,
    bool clearCustomSeed = false,
  }) {
    return AppThemeState(
      themeMode: themeMode ?? this.themeMode,
      scheme: scheme ?? this.scheme,
      customSeed: clearCustomSeed ? null : customSeed ?? this.customSeed,
    );
  }

  ThemeData get lightTheme => _buildTheme(Brightness.light);

  ThemeData get darkTheme => _buildTheme(Brightness.dark);

  ThemeData _buildTheme(Brightness brightness) {
    final seed = customSeed ?? _seedForScheme(scheme);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
        ),
      ),
    );
  }

  static Color _seedForScheme(FlexScheme scheme) {
    switch (scheme) {
      case FlexScheme.deepPurple:
        return const Color(0xFF6334E3);
      case FlexScheme.material:
        return const Color(0xFF6750A4);
      case FlexScheme.blue:
        return const Color(0xFF0B65C2);
      case FlexScheme.green:
        return const Color(0xFF1B8A5A);
      case FlexScheme.red:
        return const Color(0xFFD92D20);
      case FlexScheme.mandyRed:
        return const Color(0xFFE43D59);
      case FlexScheme.indigo:
        return const Color(0xFF3F51B5);
      case FlexScheme.hippieBlue:
        return const Color(0xFF4C9BB0);
      case FlexScheme.aquaBlue:
        return const Color(0xFF00A6B4);
      case FlexScheme.brandBlue:
        return const Color(0xFF0052CC);
      case FlexScheme.gold:
        return const Color(0xFFE1A100);
      case FlexScheme.orangeM3:
        return const Color(0xFFFF7A1A);
      default:
        return const Color(0xFF6334E3);
    }
  }
}

class ThemeController extends StateNotifier<AppThemeState> {
  ThemeController() : super(const AppThemeState()) {
    _load();
  }

  static const _modeKey = 'appearance_theme_mode';
  static const _schemeKey = 'appearance_flex_scheme';
  static const _customSeedKey = 'appearance_custom_seed';

  Future<void> changeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, mode.name);
  }

  Future<void> changeScheme(FlexScheme scheme) async {
    state = state.copyWith(scheme: scheme);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_schemeKey, scheme.name);
  }

  Future<void> setCustomSeed(Color color) async {
    state = state.copyWith(customSeed: color);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_customSeedKey, color.value);
  }

  Future<void> clearCustomSeed() async {
    state = state.copyWith(clearCustomSeed: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_customSeedKey);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = _themeModeFromName(prefs.getString(_modeKey));
    final scheme = _schemeFromName(prefs.getString(_schemeKey));
    final seedValue = prefs.getInt(_customSeedKey);

    state = AppThemeState(
      themeMode: mode,
      scheme: scheme,
      customSeed: seedValue == null ? null : Color(seedValue),
    );
  }

  ThemeMode _themeModeFromName(String? value) {
    for (final mode in ThemeMode.values) {
      if (mode.name == value) return mode;
    }
    return ThemeMode.system;
  }

  FlexScheme _schemeFromName(String? value) {
    for (final scheme in FlexScheme.values) {
      if (scheme.name == value) return scheme;
    }
    return FlexScheme.deepPurple;
  }
}
