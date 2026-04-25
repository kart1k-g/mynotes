import 'package:flutter/material.dart';

/// Brand colors aligned with auth screens (teal + calm neutrals).
abstract final class MyNotesColors {
  static const Color teal = Color(0xFF009C8A);
  static const Color tealDark = Color(0xFF007A6C);
  static const Color charcoal = Color(0xFF162543);
  static const Color navy = Color(0xFF17264C);
  static const Color muted = Color(0xFF66799A);
  static const Color hint = Color(0xFF96A2B4);
  static const Color pageGrey = Color(0xFFF4F6F9);
  static const Color divider = Color(0xFFE4EDF5);
  static const Color cardBorder = Color(0xFFE1E8F0);
  static const Color archiveBg = Color(0xFFF3F4F6);
  static const Color archiveCard = Color(0xFFF6F7FA);
  static const Color archiveText = Color(0xFF4B596F);
  static const Color archiveHint = Color(0xFF8C98AA);

  static const List<Color> palette = [
    Color(0xFF14B8A6),
    Color(0xFF10B981),
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFFF97316),
    Color(0xFFEAB308),
    Color(0xFFEF4444),
    Color(0xFF6366F1),
    Color(0xFF06B6D4),
    Color(0xFF84CC16),
    Color(0xFFF59E0B),
    Color(0xFF0EA5E9),
    Color(0xFFA855F7),
    Color(0xFF22C55E),
    Color(0xFFF43F5E),
  ];
}

ThemeData buildMyNotesTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: MyNotesColors.teal,
      brightness: Brightness.light,
      primary: MyNotesColors.teal,
      surface: Colors.white,
    ),
  );

  return base.copyWith(
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: MyNotesColors.charcoal,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: MyNotesColors.charcoal,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: MyNotesColors.teal,
      foregroundColor: Colors.white,
      elevation: 2,
      shape: CircleBorder(),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF0F3F7),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      hintStyle: const TextStyle(color: MyNotesColors.hint),
    ),
    chipTheme: base.chipTheme.copyWith(
      side: const BorderSide(color: MyNotesColors.divider, width: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dividerTheme: const DividerThemeData(
      color: MyNotesColors.divider,
      thickness: 0.5,
      space: 1,
    ),
    listTileTheme: const ListTileThemeData(iconColor: MyNotesColors.muted),
  );
}
