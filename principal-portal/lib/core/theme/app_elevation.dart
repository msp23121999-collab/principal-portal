import 'package:flutter/material.dart';

import 'app_colors.dart';

/// The portal's shadow scale.
///
/// Three cards each carried their own hand-written `BoxShadow` with slightly
/// different blur, offset and opacity, so surfaces that should have read as the
/// same material sat at subtly different heights. These are the shared steps.
///
/// The shadow is tinted with the brand navy rather than black. Black shadows
/// over a cool grey page read as grey smudges; a navy-tinted shadow keeps the
/// surface looking lit rather than dirty, which is most of the difference
/// between "flat" and "premium" at this scale.
class AppElevation {
  AppElevation._();

  static const Color _tint = AppColors.darkBlue;

  /// Flush with the page. For surfaces that are grouped by a border alone.
  static const List<BoxShadow> none = <BoxShadow>[];

  /// The resting state of a card. Barely visible — it separates the surface
  /// from the background without announcing itself.
  static List<BoxShadow> get card => [
    BoxShadow(
      color: _tint.withValues(alpha: 0.03),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  /// A card under the pointer. Lifts enough to feel responsive, not enough to
  /// shift the eye away from the data.
  static List<BoxShadow> get cardHover => [
    BoxShadow(
      color: _tint.withValues(alpha: 0.10),
      blurRadius: 18,
      offset: const Offset(0, 6),
    ),
  ];

  /// Raised panels: chart containers, table containers, the sticky page header.
  static List<BoxShadow> get raised => [
    BoxShadow(
      color: _tint.withValues(alpha: 0.05),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  /// Dialogs and menus, which float clear of the page entirely.
  static List<BoxShadow> get overlay => [
    BoxShadow(
      color: _tint.withValues(alpha: 0.16),
      blurRadius: 32,
      offset: const Offset(0, 12),
    ),
  ];

  /// The resting or hovered shadow for an interactive surface.
  static List<BoxShadow> forHover({required bool isHovered}) =>
      isHovered ? cardHover : card;

  /// Hover shadow with a subtle accent tint.
  static List<BoxShadow> forHoverAccent({
    required bool isHovered,
    Color? accentColor,
  }) {
    if (accentColor == null) return forHover(isHovered: isHovered);
    if (isHovered) {
      return [
        BoxShadow(
          color: accentColor.withValues(alpha: 0.12),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: _tint.withValues(alpha: 0.04),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];
    }
    return [
      BoxShadow(
        color: accentColor.withValues(alpha: 0.035),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ];
  }
}
