import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../feedback/empty_state.dart';
import 'analytics_card.dart';

/// One row in a [HighlightListCard]: a tinted icon badge, a headline, and
/// the supporting detail beneath it.
class HighlightEntry {
  const HighlightEntry({
    required this.icon,
    required this.title,
    required this.detail,
    this.color,
  });

  final IconData icon;
  final String title;
  final String detail;

  /// Accent for the icon badge. Defaults to the primary blue tint.
  final Color? color;
}

/// Side-rail card listing standout facts — "Key Highlights" on Institution
/// Overview, "Upcoming Deadlines" on Accreditation, and similar summaries
/// that are read rather than interacted with.
class HighlightListCard extends StatelessWidget {
  const HighlightListCard({
    super.key,
    required this.title,
    required this.entries,
    this.subtitle,
    this.trailing,
    this.emptyMessage = 'Nothing to highlight yet.',
  });

  final String title;
  final String? subtitle;
  final List<HighlightEntry> entries;
  final Widget? trailing;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return AnalyticsCard(
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      child: entries.isEmpty
          ? EmptyState(message: emptyMessage)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < entries.length; i++) ...[
                  if (i != 0) const SizedBox(height: AppSpacing.lg),
                  _HighlightRow(entry: entries[i]),
                ],
              ],
            ),
    );
  }
}

class _HighlightRow extends StatelessWidget {
  const _HighlightRow({required this.entry});

  final HighlightEntry entry;

  @override
  Widget build(BuildContext context) {
    final accent = entry.color ?? AppColors.primaryBlue;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: AppRadius.smRadius,
          ),
          alignment: Alignment.center,
          child: Icon(entry.icon, size: 18, color: accent),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                entry.title,
                style: Theme.of(context).textTheme.titleSmall,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              const SizedBox(height: 2),
              Text(
                entry.detail,
                style: Theme.of(context).textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
