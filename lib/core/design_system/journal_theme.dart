import 'package:flutter/material.dart';

abstract final class JournalColors {
  static const paper = Color(0xFFFFF9F0);
  static const peach = Color(0xFFEAA28E);
  static const ink = Color(0xFF4C3C35);
  static const butter = Color(0xFFFFE7A3);
}

ThemeData journalTheme() {
  final colors = ColorScheme.fromSeed(
    seedColor: JournalColors.peach,
    surface: JournalColors.paper,
  );
  return ThemeData(
    colorScheme: colors,
    scaffoldBackgroundColor: JournalColors.paper,
    appBarTheme: const AppBarTheme(
      backgroundColor: JournalColors.paper,
      foregroundColor: JournalColors.ink,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: JournalColors.paper,
      indicatorColor: JournalColors.butter,
    ),
  );
}
