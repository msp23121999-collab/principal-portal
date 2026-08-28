import 'package:flutter/material.dart';

/// Centralized KSRCE ERP brand palette for the Enterprise UI.
class AppColors {
  AppColors._();

  // Primary KSRCE Brand & Master Palette
  static const Color primaryBlue = Color(0xFF2563EB); // Vibrant Primary Blue
  static const Color deepNavy = Color(0xFF0A192F); // Deep Enterprise Navy
  static const Color secondaryBlue = Color(0xFF2563EB); // Vibrant Secondary Blue

  // Refined Accent Palette
  static const Color accentBlue = Color(0xFF2563EB); // Students & Primary Accent
  static const Color accentGreen = Color(0xFF059669); // Faculty & Success Accent
  static const Color accentPurple = Color(0xFF7C3AED); // Departments & Academic Accent
  static const Color accentOrange = Color(0xFFD97706); // Attendance & Pending Accent
  static const Color accentCyan = Color(0xFF0891B2); // Results & Analytics Accent
  static const Color accentPink = Color(0xFFDB2777); // Placement & Highlight Accent

  // Soft Accent Tints
  static const Color softBlue = Color(0xFFEFF6FF);
  static const Color softPurple = Color(0xFFF5F3FF);
  static const Color softGreen = Color(0xFFECFDF5);
  static const Color softOrange = Color(0xFFFFFBEB);
  static const Color softCyan = Color(0xFFECFEFF);
  static const Color softPink = Color(0xFFFDF2F8);
  static const Color softRed = Color(0xFFFEF2F2);

  /// Returns the corresponding soft background color for any component accent.
  static Color getSoftBackgroundFor(Color accentColor) {
    if (accentColor == accentBlue || accentColor == primaryBlue || accentColor == secondaryBlue) {
      return softBlue;
    } else if (accentColor == accentPurple) {
      return softPurple;
    } else if (accentColor == accentGreen || accentColor == success) {
      return softGreen;
    } else if (accentColor == accentOrange || accentColor == warning || accentColor == accentGold) {
      return softOrange;
    } else if (accentColor == accentCyan || accentColor == info) {
      return softCyan;
    } else if (accentColor == accentPink) {
      return softPink;
    } else if (accentColor == danger) {
      return softRed;
    }
    return accentColor.withValues(alpha: 0.10);
  }

  // Semantic Status Colors
  static const Color success = Color(0xFF059669);
  static const Color successBackground = Color(0xFFECFDF5);
  static const Color warning = Color(0xFFD97706);
  static const Color warningBackground = Color(0xFFFFFBEB);
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerBackground = Color(0xFFFEF2F2);
  static const Color info = Color(0xFF0891B2);
  static const Color infoBackground = Color(0xFFECFEFF);

  // Neutrals and Surfaces
  static const Color neutral = Color(0xFF64748B);
  static const Color background = Color(0xFFF1F5F9); // Sleek page background
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color tableHeader = Color(0xFFF8FAFC);
  static const Color elevatedSurface = Color(0xFFF8FAFC);
  static const Color border = Color(0xFFE2E8F0);
  
  // Text Hierarchy
  static const Color primaryText = Color(0xFF0F172A);
  static const Color secondaryText = Color(0xFF64748B);
  static const Color mutedText = Color(0xFF94A3B8);

  // Accent & Specific Use
  static const Color accentGold = Color(0xFFD97706);
  
  // Fallbacks for existing references
  static const Color darkBlue = deepNavy;
  static const Color darkNavy = deepNavy;
  static const Color sidebarNavy = deepNavy;
  static const Color secondaryNavy = deepNavy;
  static const Color deepBlue = deepNavy;
  static const Color brightBlue = secondaryBlue;
  static const Color activeBlue = secondaryBlue;
  static const Color lightBlue = Color(0xFFEFF6FF);
  static const Color veryLightBlue = elevatedSurface;
  static const Color special = accentOrange;

  // Soft Accent Tints
  static Color primaryBlueTint = primaryBlue.withValues(alpha: 0.08);
  static Color accentGoldTint = accentGold.withValues(alpha: 0.12);
  static Color accentBlueTint = accentBlue.withValues(alpha: 0.06);
  static Color accentGreenTint = accentGreen.withValues(alpha: 0.06);
  static Color accentPurpleTint = accentPurple.withValues(alpha: 0.06);
  static Color accentOrangeTint = accentOrange.withValues(alpha: 0.06);
  static Color accentCyanTint = accentCyan.withValues(alpha: 0.06);
  static Color accentPinkTint = accentPink.withValues(alpha: 0.06);

  static Color successTint = successBackground;
  static Color warningTint = warningBackground;
  static Color dangerTint = dangerBackground;
  static Color infoTint = infoBackground;
  static Color specialTint = special.withValues(alpha: 0.12);
  static Color secondaryTint = secondaryText.withValues(alpha: 0.10);

  static const Color onAccentGoldTint = Color(0xFFB45309);
  static const Color darkSuccess = successBackground;
  static const Color darkDanger = dangerBackground;
}

