import 'package:flutter/material.dart';

/// KSRCE Enterprise ERP Brand Design Tokens
class AppColors {
  AppColors._();

  // Official KSRCE Brand Color Palette
  static const Color primary = Color(0xFF0056A6);       // Primary Blue
  static const Color darkBlue = Color(0xFF003B73);      // Dark Blue
  static const Color primaryDark = Color(0xFF003B73);   // Dark Blue Alias
  static const Color primaryLight = Color(0xFFEBF3FA);  // Light Blue Tint
  static const Color gold = Color(0xFFF4B400);          // Gold Accent
  static const Color accentGold = Color(0xFFF4B400);

  // Backgrounds & Neutrals
  static const Color background = Color(0xFFF8FAFC);    // Background Light Gray
  static const Color cardBg = Color(0xFFFFFFFF);        // White Card
  static const Color border = Color(0xFFE5E7EB);        // Border Gray
  static const Color divider = Color(0xFFE5E7EB);

  // Typography Palette
  static const Color textPrimary = Color(0xFF1F2937);   // Primary Text (Slate 800)
  static const Color textSecondary = Color(0xFF6B7280); // Secondary Text (Slate 500)
  static const Color textMuted = Color(0xFF9CA3AF);     // Muted Text

  // Sidebar Palette
  static const Color sidebarBg = Color(0xFF003B73);     // Dark Blue Sidebar
  static const Color sidebarText = Color(0xFFE5E7EB);
  static const Color sidebarTextActive = Colors.white;
  static const Color sidebarActiveBg = Color(0xFF0056A6); // Primary Blue Active Pill
  static const Color sidebarDivider = Color(0xFF0C244A);
  static const Color sidebarSection = Color(0xFF94A3B8);
  static const Color footerBg = Color(0xFF002247);

  // Semantic Colors
  static const Color success = Color(0xFF16A34A);       // Success Green
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFF59E0B);       // Warning Amber
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color danger = Color(0xFFDC2626);        // Danger Red
  static const Color error = Color(0xFFDC2626);         // Error Red
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF0056A6);
  static const Color infoLight = Color(0xFFE0F2FE);

  // Stat Accents
  static const Color statBlue = Color(0xFF0056A6);
  static const Color statDarkBlue = Color(0xFF003B73);
  static const Color statGold = Color(0xFFF4B400);
  static const Color statGreen = Color(0xFF16A34A);
  static const Color statRed = Color(0xFFDC2626);
  static const Color statOrange = Color(0xFFF59E0B);
}
