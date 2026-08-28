import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/cards/notification_card.dart';
import '../../../core/widgets/feedback/empty_state.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_skeleton.dart';
import '../providers/dashboard_providers.dart';
import 'dashboard_card.dart';
import 'pending_approvals_section.dart';

/// Recent institution-wide activity feed (approvals, results, placements,
/// onboarding, circulars).
class RecentActivitiesSection extends ConsumerWidget {
  const RecentActivitiesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(recentActivitiesProvider);

    return activitiesAsync.when(
      loading: () => const CardSkeleton(height: 320),
      error: (err, st) => const ErrorState(),
      data: (activities) => DashboardCard(
        minHeight: kDashboardPairMinHeight,
        title: 'Recent Activities',
        icon: Icons.notifications_active_outlined,
        iconColor: AppColors.info,
        child: activities.isEmpty
            ? const EmptyState(message: 'No recent activity.')
            : Column(
                children: [
                  for (final activity in activities.take(
                    kDashboardActivityRows,
                  ))
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: NotificationCard(
                        icon: activity.icon,
                        title: activity.title,
                        message: activity.subtitle,
                        timestamp: DateFormatter.relative(activity.timestamp),
                        iconColor: AppColors.primaryBlue,
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
