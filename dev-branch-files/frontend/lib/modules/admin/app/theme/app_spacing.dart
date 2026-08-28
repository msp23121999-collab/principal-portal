import 'package:flutter/material.dart';

/// 8pt Grid System Tokens
class AppSpacing {
  AppSpacing._();

  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;
  static const double space40 = 40;
  static const double space48 = 48;
  static const double space64 = 64;

  // Backward compatibility aliases
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  // Border Radii
  static const double borderRadiusSm = 8;
  static const double borderRadiusMd = 16;
  static const double borderRadiusLg = 24;

  // Gap Widgets
  static const SizedBox gapXs = SizedBox(width: 4, height: 4);
  static const SizedBox gapSm = SizedBox(width: 8, height: 8);
  static const SizedBox gapMd = SizedBox(width: 16, height: 16);
  static const SizedBox gapLg = SizedBox(width: 24, height: 24);
  static const SizedBox gapXl = SizedBox(width: 32, height: 32);
}
