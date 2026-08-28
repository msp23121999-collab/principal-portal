import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/feedback/empty_state.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_skeleton.dart';
import '../providers/department_providers.dart';

/// Highlights specific issues across departments that need Principal attention.
class DepartmentAttentionRequired extends ConsumerWidget {
  const DepartmentAttentionRequired({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsAsync = ref.watch(departmentInsightsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            bottom: AppSpacing.md,
            top: AppSpacing.lg,
          ),
          child: Text(
            'Attention Required',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        insightsAsync.when(
          loading: () => const CardSkeleton(height: 100),
          error: (err, st) => const ErrorState(),
          data: (insights) {
            final allMessages = <String>[];
            for (final d in insights) {
              allMessages.addAll(d.attentionRequired);
            }

            if (allMessages.isEmpty) {
              return const EmptyState(
                message: 'No department-level issues require attention.',
                icon: AppIcons.approve,
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final msg in allMessages)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _AttentionMessageCard(message: msg),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _AttentionMessageCard extends StatelessWidget {
  const _AttentionMessageCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    // Determine sentiment based on the message string to color code correctly
    final isPositive = message.contains('strong improvement');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(
          color: isPositive ? AppColors.successTint : AppColors.warningTint,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isPositive ? AppIcons.trendUp : AppIcons.warning,
            size: 20,
            color: isPositive ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
