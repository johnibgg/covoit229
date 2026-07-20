import 'package:flutter/material.dart';

// Palette inspirée des applis de mobilité béninoises : vert vif + bleu nuit.
class CvColors {
  static const Color green = Color(0xFF00B140);
  static const Color greenDark = Color(0xFF008F34);
  static const Color navy = Color(0xFF0B1B33);
  static const Color navySoft = Color(0xFF16294A);
  static const Color amber = Color(0xFFFFB800);
  static const Color bg = Color(0xFFF4F7F5);
  static const Color card = Colors.white;
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: CvColors.green,
      primary: CvColors.green,
      secondary: CvColors.amber,
      surface: CvColors.bg,
    ),
    scaffoldBackgroundColor: CvColors.bg,
  );
  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: CvColors.navy,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: CvColors.green,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}
