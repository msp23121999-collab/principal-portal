import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/date_formatter.dart';
import './cards/analytics_card.dart';
import './cards/notification_card.dart';
import './feedback/empty_state.dart';
import './feedback/error_state.dart';
import './feedback/loading_skeleton.dart';
import '../providers/dashboard_providers.dart';

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
      data: (activities) => AnalyticsCard(
        title: 'Recent Activities',
        child: activities.isEmpty
            ? const EmptyState(message: 'No recent activity.')
            : Column(
                children: [
                  for (final activity in activities)
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
