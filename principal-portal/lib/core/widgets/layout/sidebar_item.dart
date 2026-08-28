import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

/// A single sidebar navigation row: icon, label, active indicator.
/// Collapses to icon-only when [expanded] is false.
class SidebarItem extends StatelessWidget {
  const SidebarItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.expanded = true,
    this.isDestructive = false,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool expanded;
  final bool isDestructive;

  /// Pending-item count shown as a red pill. Hidden when zero.
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? AppColors.danger
        : (selected ? Colors.white : Colors.white70);

    final row = Row(
      children: [
        _Glyph(icon: icon, color: color, badgeCount: expanded ? 0 : badgeCount),
        if (expanded) ...[
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (badgeCount > 0) _CountBadge(count: badgeCount),
        ],
      ],
    );

    // The rail is the portal's primary navigation, so each row has to announce
    // what it is, whether it is the current page, and how many items are
    // waiting on it.
    //
    // It previously relied on the Tooltip alone, whose message is `''` while
    // the rail is expanded — the common case. That left every visible
    // destination without a usable accessible name, and the badge count was
    // announced as a bare number with nothing to attach it to.
    //
    // MergeSemantics collapses the icon, the label, the badge and the InkWell's
    // own button node into a single node. Without it the annotation below sits
    // above the InkWell's node rather than joining it, and a reader lands on an
    // unlabelled button — which is what `tester.getSemantics` reported.
    final semanticLabel = badgeCount > 0
        ? '$label, $badgeCount pending'
        : label;

    return MergeSemantics(
      child: Semantics(
        label: semanticLabel,
        button: true,
        selected: selected,
        child: Tooltip(
          // Only when the label is not on screen. A tooltip repeating text the
          // reader can already see is noise.
          message: expanded ? '' : label,
          excludeFromSemantics: true,
          child: Material(
            color: Colors.transparent,
            borderRadius: AppRadius.smRadius,
            child: InkWell(
              borderRadius: AppRadius.smRadius,
              hoverColor: AppColors.primaryBlue.withValues(alpha: 0.08),
              onTap: onTap,
              child: Ink(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: isDestructive
                      ? AppColors.dangerTint
                      : (selected
                            ? AppColors.activeBlue.withValues(alpha: 0.15)
                            : Colors.transparent),
                  borderRadius: AppRadius.smRadius,
                  border: selected
                      ? const Border(
                          left: BorderSide(
                            color: AppColors.brightBlue,
                            width: 3,
                          ),
                        )
                      : const Border(
                          left: BorderSide(color: Colors.transparent, width: 3),
                        ),
                ),
                child: row,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The row icon, with the count collapsed onto it as a dot when the
/// sidebar is icon-only and there is no room for the pill.
class _Glyph extends StatelessWidget {
  const _Glyph({
    required this.icon,
    required this.color,
    required this.badgeCount,
  });

  final IconData icon;
  final Color color;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final glyph = Icon(icon, size: 20, color: color);
    if (badgeCount == 0) return glyph;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        glyph,
        Positioned(
          right: -2,
          top: -2,
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
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 20),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.danger,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        count > 99 ? '99+' : '$count',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
