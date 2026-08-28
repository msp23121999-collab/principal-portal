import 'package:flutter/material.dart';

/// Two-level elevation system — subtle shadows only, per the enterprise
/// "no flashy effects" design directive.
class AppElevation {
  AppElevation._();

  /// Resting elevation for cards sitting on the page background.
  static List<BoxShadow> resting = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      offset: const Offset(0, 1),
      blurRadius: 2,
    ),
  ];

  /// Raised elevation for popovers, dropdown menus, and dialogs.
  static List<BoxShadow> raised = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      offset: const Offset(0, 2),
      blurRadius: 6,
    ),
  ];
}
