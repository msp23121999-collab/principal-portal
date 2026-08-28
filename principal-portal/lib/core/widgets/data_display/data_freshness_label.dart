import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/refresh_on_focus.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_spacing.dart';
import '../../utils/date_formatter.dart';

/// States when the figures beside it were read.
///
/// The portal is a snapshot, not a monitor: providers fetch once and hold until
/// something invalidates them. The top bar meanwhile shows a live clock, so a
/// dashboard opened at nine and glanced at four looked current to the minute.
/// One dated line resolves that without pretending to a freshness the portal
/// does not have.
///
/// Kept deliberately quiet — muted, small, no background — because it is
/// context for the numbers, not one of them. Renders nothing at all until the
/// first fetch is stamped, rather than showing a placeholder time.
class DataFreshnessLabel extends ConsumerWidget {
  const DataFreshnessLabel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final at = ref.watch(lastRefreshedAtProvider);
    if (at == null) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(AppIcons.clock, size: 14, color: AppColors.mutedText),
        const SizedBox(width: AppSpacing.xs),
        Text(
          'Updated ${DateFormatter.time(at)}',
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: AppColors.mutedText),
        ),
      ],
    );
  }
}
