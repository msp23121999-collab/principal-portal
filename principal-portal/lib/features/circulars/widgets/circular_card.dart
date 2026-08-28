import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/buttons/secondary_button.dart';
import '../models/circular.dart';

/// Category accents, so a notice's subject reads before its text does.
Color _categoryColor(CircularCategory category) {
  switch (category) {
    case CircularCategory.academic:
      return AppColors.primaryBlue;
    case CircularCategory.administrative:
      return AppColors.secondaryText;
    case CircularCategory.examination:
      return AppColors.accentGold;
    case CircularCategory.event:
      return AppColors.success;
    case CircularCategory.urgent:
      return AppColors.danger;
  }
}

/// A single notice on the board: reference and category, the text, who
/// it went to, how widely it has been read, and the available actions.
class CircularCard extends StatelessWidget {
  const CircularCard({
    super.key,
    required this.circular,
    this.onPublish,
    this.onArchive,
    this.onTogglePin,
  });

  final Circular circular;
  final VoidCallback? onPublish;
  final VoidCallback? onArchive;
  final VoidCallback? onTogglePin;

  @override
  Widget build(BuildContext context) {
    final accent = _categoryColor(circular.category);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: AppRadius.smRadius,
                      ),
                      child: Text(
                        circular.category.label,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      circular.reference,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    if (circular.isPinned)
                      const Icon(
                        Icons.push_pin_outlined,
                        size: 14,
                        color: AppColors.accentGold,
                      ),
                  ],
                ),
              ),
              if (onTogglePin != null)
                IconButton(
                  icon: Icon(
                    circular.isPinned
                        ? Icons.push_pin
                        : Icons.push_pin_outlined,
                    size: 18,
                    color: circular.isPinned
                        ? AppColors.accentGold
                        : AppColors.secondaryText,
                  ),
                  tooltip: circular.isPinned ? 'Unpin notice' : 'Pin notice',
                  onPressed: onTogglePin,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(circular.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            circular.body,
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.xs,
            children: [
              _Meta(icon: AppIcons.faculty, text: circular.audience.label),
              _Meta(icon: AppIcons.profile, text: circular.author),
              _Meta(
                icon: AppIcons.calendar,
                text: circular.publishedAt == null
                    ? 'Drafted ${DateFormatter.shortDate(circular.createdAt)}'
                    : 'Published ${DateFormatter.shortDate(circular.publishedAt!)}',
              ),
            ],
          ),
          if (circular.status == CircularStatus.published) ...[
            const SizedBox(height: AppSpacing.md),
            _Readership(circular: circular),
          ],
          if (onPublish != null || onArchive != null) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                if (onArchive != null)
                  SecondaryButton(label: 'Archive', onPressed: onArchive),
                if (onPublish != null)
                  PrimaryButton(label: 'Publish', onPressed: onPublish),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.secondaryText),
        const SizedBox(width: AppSpacing.xs),
        Text(text, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _Readership extends StatelessWidget {
  const _Readership({required this.circular});

  final Circular circular;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Read by ${circular.acknowledgements} of '
                '${circular.recipients} recipients',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
            Text(
              '${circular.readPercent.toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: circular.readPercent / 100,
            minHeight: 6,
            backgroundColor: AppColors.background,
            valueColor: AlwaysStoppedAnimation<Color>(
              circular.readPercent >= 80
                  ? AppColors.success
                  : AppColors.accentGold,
            ),
          ),
        ),
      ],
    );
  }
}
