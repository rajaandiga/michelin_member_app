import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const blue = Color(0xFF27509B);
  static const navy = Color(0xFF0F1B33);
  static const yellow = Color(0xFFFCE500);
  static const bg = Color(0xFFF4F6FA);
  static const text = Color(0xFF1B2433);
  static const muted = Color(0xFF6B7588);
  static const line = Color(0xFFE3E8F1);

  static Color tier(String t) {
    switch (t) {
      case 'Silver':
        return const Color(0xFF8E9AAF);
      case 'Gold':
        return const Color(0xFFC99700);
      case 'Platinum':
        return const Color(0xFF3B4A6B);
      default:
        return const Color(0xFFA8703F);
    }
  }
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.blue,
      primary: AppColors.blue,
      secondary: AppColors.yellow,
    ),
  );
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    textTheme: GoogleFonts.poppinsTextTheme(base.textTheme)
        .apply(bodyColor: AppColors.text, displayColor: AppColors.text),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      foregroundColor: AppColors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
  );
}
