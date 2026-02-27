import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../../custom_slider.dart';

class ThemeState {
  final ThemeMode themeMode;
  final FlexScheme scheme;
  final Color? customSeed;

  ThemeState({
    required this.themeMode,
    required this.scheme,
    this.customSeed,
  });
  ThemeData get lightTheme {
    final base = customSeed != null
        ? FlexThemeData.light(
      colors: FlexSchemeColor.from(primary: customSeed!),
      useMaterial3: true,
    )
        : FlexThemeData.light(
      scheme: scheme,
      useMaterial3: true,
    );

    final primary = base.colorScheme.primaryFixedDim;
    print(primary);
    print("😅😅😅😅 light color at controller");

    return base.copyWith(
      scaffoldBackgroundColor: primary,

      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: SlidePageTransitionsBuilder(),
          TargetPlatform.iOS: SlidePageTransitionsBuilder(),
        },
      ),
    );
  }

  ThemeData get darkTheme {
    final baseTheme = customSeed != null
        ? FlexThemeData.dark(
      colors: FlexSchemeColor.from(primary: customSeed!),
      useMaterial3: true,
    )
        : FlexThemeData.dark(
      scheme: scheme,
      useMaterial3: true,
    );

    final primary = baseTheme.colorScheme.primary;

    return baseTheme.copyWith(
      scaffoldBackgroundColor: Colors.black, // solid black background
      cardTheme: CardThemeData(
        color: Colors.grey.shade600, // dark grey card
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: SlidePageTransitionsBuilder(),
          TargetPlatform.iOS: SlidePageTransitionsBuilder(),
        },
      ),
    );
  }
  ThemeState copyWith({
    ThemeMode? themeMode,
    FlexScheme? scheme,
    Color? customSeed,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      scheme: scheme ?? this.scheme,
      customSeed: customSeed,
    );
  }
}

class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier()
      : super(ThemeState(
    themeMode: ThemeMode.system,
    scheme: FlexScheme.blue,
  )) {
    _load();
  }

  void changeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _save();
  }

  void changeScheme(FlexScheme scheme) {
    state = state.copyWith(scheme: scheme, customSeed: null);
    _save();
  }

  void setCustomSeed(Color color) {
    state = state.copyWith(customSeed: color);
    _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("themeMode", state.themeMode.index);
    await prefs.setInt("scheme", state.scheme.index);
    if (state.customSeed != null) {
      await prefs.setInt("customSeed", state.customSeed!.value);
    }
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getInt("themeMode");
    final scheme = prefs.getInt("scheme");
    final seed = prefs.getInt("customSeed");

    state = ThemeState(
      themeMode: ThemeMode.values[mode ?? 0],
      scheme: FlexScheme.values[scheme ?? 0],
      customSeed: seed != null ? Color(seed) : null,
    );
  }
}

final themeProvider =
StateNotifierProvider<ThemeNotifier, ThemeState>(
        (ref) => ThemeNotifier());