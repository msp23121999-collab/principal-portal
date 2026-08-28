import 'package:flutter/material.dart';

class DeanTheme {
  // Brand & Palette Tokens matching Student Module Dark Navy theme
  static const Color primaryNavy = Color(0xFF0B192C);
  static const Color darkNavyHeader = Color(0xFF0F172A);
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color lightBlueBg = Color(0xFFEFF6FF);
  
  static const Color bgCanvas = Color(0xFFF8FAFC);
  static const Color cardBg = Colors.white;
  static const Color cardBorder = Color(0xFFE2E8F0);
  
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textSubtle = Color(0xFF94A3B8);

  static const Color successGreen = Color(0xFF10B981);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color dangerRose = Color(0xFFEF4444);
  static const Color infoPurple = Color(0xFF8B5CF6);
  static const Color tealAccent = Color(0xFF14B8A6);

  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bgCanvas,
      fontFamily: 'Inter',
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryBlue,
        secondary: accentBlue,
        background: bgCanvas,
        surface: cardBg,
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: cardBorder, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFF1F5F9),
        thickness: 1,
      ),
    );
  }
}
