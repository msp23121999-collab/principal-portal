import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';

/// Small icon-only button used in table row actions and the top bar
/// (notification bell, search trigger).
///
/// [tooltip] is required, and doubles as the control's accessible name. An
/// icon-only button with no label is silent to a screen reader — the icon is a
/// glyph in a font, so there is nothing else to announce — and it was optional
/// here, which meant nothing but review stood between the portal and a row of
/// unnameable buttons. Every existing call site already passed one.
class IconActionButton extends StatelessWidget {
  const IconActionButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.badgeCount,
    this.color,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  /// Shown on hover and read out by assistive technology.
  final String tooltip;
  final int? badgeCount;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: Colors.transparent,
      borderRadius: AppRadius.smRadius,
      child: InkWell(
        borderRadius: AppRadius.smRadius,
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 22, color: color ?? AppColors.secondaryText),
        ),
      ),
    );

    final withBadge = badgeCount == null || badgeCount == 0
        ? button
        : Stack(
            clipBehavior: Clip.none,
            children: [
              button,
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          );

    // Tooltip supplies the semantic label as well as the hover text, so the
    // button announces itself without a second annotation to keep in step.
    return Tooltip(message: tooltip, child: withBadge);
  }
}
