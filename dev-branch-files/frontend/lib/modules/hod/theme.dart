import 'package:flutter/material.dart';

class AppTheme {
  // Primary Palette
  static const Color primaryNavy = Color(0xFF0F223D);
  static const Color sidebarNavy = Color(0xFF0B192C);
  static const Color bgCanvas = Color(0xFFF8FAFC);
  static const Color cardBg = Color(0xFFFFFFFF);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  // Accents & Badges
  static const Color accentBlue = Color(0xFF2563EB);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color accentOrange = Color(0xFFF97316);
  static const Color accentPurple = Color(0xFF9333EA);
  static const Color accentTeal = Color(0xFF14B8A6);
  static const Color accentRose = Color(0xFFF43F5E);
  static const Color accentAmber = Color(0xFFF59E0B);
  static const Color accentIndigo = Color(0xFF6366F1);

  // Badge Tints
  static const Color badgeGreenBg = Color(0xFFDCFCE7);
  static const Color badgeGreenText = Color(0xFF15803D);
  static const Color badgeBlueBg = Color(0xFFEFF6FF);
  static const Color badgeBlueText = Color(0xFF1D4ED8);
  static const Color badgeOrangeBg = Color(0xFFFFF7ED);
  static const Color badgeOrangeText = Color(0xFFC2410C);
  static const Color badgeRedBg = Color(0xFFFEF2F2);
  static const Color badgeRedText = Color(0xFFB91C1C);
  static const Color badgePurpleBg = Color(0xFFF3E8FF);
  static const Color badgePurpleText = Color(0xFF6B21A8);

  // Navigation
  static const Color activeNavBg = Color(0xFFEFF6FF);
  static const Color activeNavText = Color(0xFF1D4ED8);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bgCanvas,
      primaryColor: primaryNavy,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryNavy,
        primary: primaryNavy,
        secondary: accentGreen,
        surface: cardBg,
      ),
      fontFamily: 'Inter',
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
      ),
    );
  }
}
