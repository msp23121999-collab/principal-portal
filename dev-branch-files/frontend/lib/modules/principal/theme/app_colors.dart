import 'package:flutter/material.dart';

/// Centralized KSRCE ERP brand palette. No other colors should be used
/// anywhere in the app — always reference these constants.
class AppColors {
  AppColors._();

  static const Color primaryBlue = Color(0xFF0056A6);
  static const Color darkBlue = Color(0xFF003B73);
  static const Color accentGold = Color(0xFFF4B400);

  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);

  static const Color primaryText = Color(0xFF1F2937);
  static const Color secondaryText = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);

  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFDC2626);

  // Derived low-opacity tints for chip/badge backgrounds — kept here (not
  // ad hoc withOpacity() calls scattered across widgets) so every status
  // surface uses an identical tint.
  static Color primaryBlueTint = primaryBlue.withValues(alpha: 0.08);
  static Color accentGoldTint = accentGold.withValues(alpha: 0.14);
  static Color successTint = success.withValues(alpha: 0.12);
  static Color warningTint = warning.withValues(alpha: 0.12);
  static Color dangerTint = danger.withValues(alpha: 0.12);
  static Color secondaryTint = secondaryText.withValues(alpha: 0.10);
}
