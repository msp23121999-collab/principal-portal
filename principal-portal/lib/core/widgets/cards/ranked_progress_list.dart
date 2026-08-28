import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_spacing.dart';
import '../feedback/empty_state.dart';

/// One ranked row: an ordinal, a name, a proportional bar, and the
/// formatted figure the bar represents.
class RankedEntry {
  const RankedEntry({
    required this.label,
    required this.value,
    required this.displayValue,
    this.color,
  });

  final String label;

  /// Magnitude used for bar width, on the same scale as its siblings.
  final double value;

  /// Pre-formatted figure shown at the row's end, e.g. "93.41%".
  final String displayValue;
  final Color? color;
}

/// Ordered leaderboard with inline progress bars — "Top Performing
/// Departments", research output rankings, placement leaders. Bars are
/// scaled against [maxValue], or the largest entry when that is omitted.
class RankedProgressList extends StatelessWidget {
  const RankedProgressList({
    super.key,
    required this.entries,
    this.maxValue,
    this.emptyMessage = 'No rankings available.',
  });

  final List<RankedEntry> entries;
  final double? maxValue;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return EmptyState(message: emptyMessage);

    final scale =
        maxValue ??
        entries.map((e) => e.value).fold<double>(0, (a, b) => a > b ? a : b);

    return Column(
      children: [
        for (int i = 0; i < entries.length; i++) ...[
          if (i != 0) const SizedBox(height: AppSpacing.md),
          _RankedRow(rank: i + 1, entry: entries[i], scale: scale),
        ],
      ],
    );
  }
}

class _RankedRow extends StatelessWidget {
  const _RankedRow({
    required this.rank,
    required this.entry,
    required this.scale,
  });

  final int rank;
  final RankedEntry entry;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final fraction = scale <= 0 ? 0.0 : (entry.value / scale).clamp(0.0, 1.0);
    final accent = entry.color ?? AppColors.primaryBlue;

    return Row(
      children: [
        // The leaders get a filled chip, the rest a plain numeral. A column of
        // identical grey numbers made a ranked list look like an unordered one,
        // and the top three are the entries a Principal actually acts on.
        SizedBox(
          width: 26,
          child: rank <= 3
              ? Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$rank',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : Text(
                  '$rank',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
        ),
        Expanded(
          flex: 4,
          child: Text(
            entry.label,
            style: Theme.of(context).textTheme.titleSmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          flex: 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            // The bars grow to their length rather than appearing at it, which
            // is what makes a ranking read as a comparison instead of a table
            // of coloured rectangles. Collapses to a static bar under
            // reduce-motion.
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: fraction),
              duration: AppMotion.adaptive(context, AppMotion.slow),
              curve: AppMotion.enter,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: AppColors.background,
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 62,
          child: Text(
            entry.displayValue,
            textAlign: TextAlign.right,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(color: accent),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
