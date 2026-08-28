import 'package:flutter/widgets.dart';

/// The portal's motion scale.
///
/// Durations were previously written inline, so a hover on one card settled in
/// 200ms and on another in 150ms. Motion that is not consistent reads as
/// jitter rather than polish.
///
/// Everything here is short on purpose. This is an administrator's daily tool:
/// animation should confirm that something responded, never make anyone wait.
/// Nothing exceeds 300ms, and nothing loops.
class AppMotion {
  AppMotion._();

  /// Hover, focus, colour and border changes. Fast enough to feel immediate.
  static const Duration fast = Duration(milliseconds: 150);

  /// The default. Card lift, tab switch, filter changes, expanding sections.
  static const Duration normal = Duration(milliseconds: 220);

  /// Entrances: a screen's first paint, a chart drawing itself, a dialog.
  static const Duration slow = Duration(milliseconds: 300);

  /// Deceleration for anything entering the screen.
  static const Curve enter = Curves.easeOutCubic;

  /// Symmetric easing for state changes on something already on screen.
  static const Curve standard = Curves.easeInOut;

  /// Exits, which should get out of the way promptly.
  static const Curve exit = Curves.easeInCubic;

  /// Staggers a list or grid so items arrive in sequence rather than together.
  ///
  /// Capped deliberately: with 30 rows an uncapped stagger would leave the last
  /// one arriving nearly a second late, which is a delay pretending to be a
  /// flourish. After the eighth item everything lands at once.
  static Duration stagger(int index, {int cap = 8}) =>
      Duration(milliseconds: 40 * (index < cap ? index : cap));

  /// True when the reader has asked the platform to reduce motion.
  ///
  /// Animation is decoration here — every one of them can be skipped without
  /// losing information, so honouring this costs nothing.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// [normal], or [Duration.zero] when motion is reduced.
  static Duration adaptive(BuildContext context, [Duration? duration]) =>
      reduced(context) ? Duration.zero : (duration ?? normal);
}
