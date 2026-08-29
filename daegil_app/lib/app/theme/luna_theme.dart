import 'package:flutter/material.dart';

abstract final class LunaColors {
  // The mascot artwork is painted on this warm paper tone. Keeping the page
  // and image canvas identical makes the raster edges disappear naturally.
  static const paper = Color(0xFFFBEACD);
  static const imageCanvas = Color(0xFFFBEACD);
  static const paperRaised = Color(0xFFFFF7E8);
  static const cream = Color(0xFFFFFAEF);
  static const peach = Color(0xFFF1C8AE);
  static const peachSoft = Color(0xFFF7DED0);
  static const blush = Color(0xFFF3C8C3);
  static const butter = Color(0xFFF4DEA4);
  static const jadeSoft = Color(0xFFDDE5D1);
  static const ink = Color(0xFF4A281D);
  static const secondary = Color(0xFF755144);
  static const muted = Color(0xFFA48673);
  static const seal = Color(0xFFB65B38);
  static const gold = Color(0xFFD58A45);
  static const jade = Color(0xFF87986C);
  static const plum = Color(0xFF8D5C56);
  static const subtleBorder = Color(0xFF9B755F);
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
  static const button = 18.0;
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
    splashFactory: InkSparkle.splashFactory,
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
      color: LunaColors.cream,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LunaRadii.card),
        side: const BorderSide(color: LunaColors.subtleBorder, width: 1.15),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: LunaColors.paper,
      foregroundColor: LunaColors.ink,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: LunaColors.ink,
        fontSize: 21,
        height: 1.3,
        fontWeight: FontWeight.w700,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: LunaColors.paperRaised,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: LunaColors.subtleBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: LunaColors.subtleBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: LunaColors.seal, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        backgroundColor: LunaColors.blush,
        foregroundColor: LunaColors.ink,
        elevation: 0,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LunaRadii.button),
          side: const BorderSide(color: LunaColors.subtleBorder, width: 1.15),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        foregroundColor: LunaColors.ink,
        side: const BorderSide(color: LunaColors.subtleBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LunaRadii.button),
        ),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 76,
      backgroundColor: LunaColors.cream,
      indicatorColor: LunaColors.blush,
      elevation: 0,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        return IconThemeData(
          color: states.contains(WidgetState.selected)
              ? LunaColors.seal
              : LunaColors.secondary,
          size: states.contains(WidgetState.selected) ? 25 : 23,
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        return TextStyle(
          color: states.contains(WidgetState.selected)
              ? LunaColors.seal
              : LunaColors.secondary,
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
        );
      }),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: LunaColors.peachSoft,
      selectedColor: LunaColors.blush,
      side: const BorderSide(color: LunaColors.subtleBorder),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      labelStyle: const TextStyle(
        color: LunaColors.ink,
        fontWeight: FontWeight.w600,
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? LunaColors.seal
            : Colors.transparent,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      side: const BorderSide(color: LunaColors.secondary, width: 1.5),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? LunaColors.cream
            : LunaColors.muted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? LunaColors.seal
            : LunaColors.blush,
      ),
    ),
    dividerTheme: const DividerThemeData(color: LunaColors.subtleBorder),
  );
}
