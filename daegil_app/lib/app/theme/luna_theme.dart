import 'package:flutter/material.dart';

abstract final class LunaColors {
  static const paper = Color(0xFFF5E6C8);
  static const paperRaised = Color(0xFFFFF4DE);
  static const ink = Color(0xFF4A281D);
  static const secondary = Color(0xFF755144);
  static const muted = Color(0xFFA48673);
  static const seal = Color(0xFFB65B38);
  static const gold = Color(0xFFD58A45);
  static const jade = Color(0xFF87986C);
  static const plum = Color(0xFF8D5C56);
  static const subtleBorder = Color(0xFF6D4231);
  static const disabled = Color(0xFFCDB9A1);
  static const danger = Color(0xFFB24A30);
  static const success = Color(0xFF66805B);
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
        side: const BorderSide(color: LunaColors.subtleBorder, width: 1.2),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: LunaColors.paperRaised,
      foregroundColor: LunaColors.ink,
      elevation: 0,
      centerTitle: true,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: LunaColors.paperRaised,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: LunaColors.subtleBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: LunaColors.subtleBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: LunaColors.seal, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        backgroundColor: LunaColors.gold,
        foregroundColor: LunaColors.ink,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LunaRadii.button),
        ),
      ),
    ),
  );
}
