import 'package:flutter/material.dart';

abstract final class LunaColors {
  static const paper = Color(0xFFF4EFE5);
  static const paperRaised = Color(0xFFFBF8F1);
  static const ink = Color(0xFF222622);
  static const secondary = Color(0xFF66645E);
  static const muted = Color(0xFF8A867D);
  static const seal = Color(0xFFA14B3F);
  static const gold = Color(0xFFB49A67);
  static const jade = Color(0xFF6F8978);
  static const plum = Color(0xFF725F6B);
  static const subtleBorder = Color(0xFFD8D0C3);
  static const disabled = Color(0xFFB8B3AA);
  static const danger = Color(0xFFA6534A);
  static const success = Color(0xFF66806F);
}

abstract final class LunaSpacing {
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
}

abstract final class LunaRadii {
  static const card = 18.0;
  static const button = 16.0;
  static const sheet = 24.0;
}

ThemeData buildLunaTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: LunaColors.seal,
        brightness: Brightness.light,
      ).copyWith(
        surface: LunaColors.paperRaised,
        onSurface: LunaColors.ink,
        primary: LunaColors.seal,
        onPrimary: Colors.white,
        secondary: LunaColors.jade,
      );

  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: LunaColors.paper,
    useMaterial3: true,
    textTheme: const TextTheme(
      displaySmall: TextStyle(
        fontSize: 28,
        height: 36 / 28,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        fontSize: 24,
        height: 32 / 24,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        fontSize: 20,
        height: 28 / 20,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(fontSize: 16, height: 26 / 16),
      bodyMedium: TextStyle(fontSize: 14, height: 22 / 14),
      labelSmall: TextStyle(fontSize: 12, height: 18 / 12),
    ).apply(bodyColor: LunaColors.ink, displayColor: LunaColors.ink),
    cardTheme: CardThemeData(
      color: LunaColors.paperRaised,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LunaRadii.card),
        side: const BorderSide(color: LunaColors.subtleBorder),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LunaRadii.button),
        ),
      ),
    ),
  );
}
