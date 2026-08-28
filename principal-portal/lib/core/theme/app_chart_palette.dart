import 'package:flutter/material.dart';

import 'app_colors.dart';

/// The ordered colour sequence for multi-series charts.
///
/// Series colours were previously chosen at each call site. Three screens
/// happened to agree on blue/green/gold; nothing enforced it, and a fourth
/// chart could quietly introduce a fifth colour with no meaning attached to it.
///
/// Take colours from here in order. Position carries no semantics — series 1 is
/// simply the first thing plotted — which is exactly why it must not be mixed
/// with the semantic colours below.
///
/// ## Semantic colours are not series colours
///
/// [AppColors.success], [AppColors.warning] and [AppColors.danger] mean
/// something: passed, pending, failed. Use them when a series *is* that thing —
/// an approved/rejected split — and never merely because a chart needs a third
/// colour. A green bar that does not mean "good" spends meaning the portal
/// needs elsewhere.
class AppChartPalette {
  AppChartPalette._();

  /// Categorical sequence for unrelated series.
  ///
  /// Ordered so the first two — the common case — are the furthest apart in
  /// both hue and lightness, which keeps them distinguishable in greyscale and
  /// for the most common forms of colour blindness.
  static const List<Color> series = <Color>[
    AppColors.accentBlue,   // 0 — Blue (Students)
    AppColors.accentGreen,  // 1 — Green (Faculty)
    AppColors.accentPurple, // 2 — Purple (Departments)
    AppColors.accentOrange, // 3 — Orange (Today's Attendance)
    AppColors.accentCyan,   // 4 — Cyan/Teal (Result Pass %)
    AppColors.accentPink,   // 5 — Pink/Magenta (Placement %)
  ];

  /// The colour for series [index], wrapping if a chart has more series than
  /// the palette has entries.
  static Color at(int index) => series[index % series.length];

  /// The first [count] colours, for a chart that wants the list up front.
  static List<Color> take(int count) =>
      List<Color>.generate(count, at, growable: false);

  /// A comparison of "before" against "now", where the earlier value should
  /// recede and the current one should lead.
  static const List<Color> comparison = <Color>[
    AppColors.border, // prior period — deliberately inert
    AppColors.primaryBlue, // current period
  ];

  /// Grid lines and axis rules. Light enough to sit behind the data rather
  /// than compete with it.
  static Color get grid => AppColors.border.withValues(alpha: 0.55);
}
