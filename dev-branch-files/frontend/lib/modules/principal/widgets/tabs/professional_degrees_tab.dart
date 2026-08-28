import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../utils/responsive_utils.dart';
import '.././cards/analytics_card.dart';
import '.././cards/statistics_card.dart';
import '.././feedback/error_state.dart';
import '.././feedback/loading_skeleton.dart';
import '../../providers/principal_profile_providers.dart';

/// Educational qualifications and career experience summary.
class ProfessionalDegreesTab extends ConsumerWidget {
  const ProfessionalDegreesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(principalProfileProvider);

    return profileAsync.when(
      loading: () => const CardSkeleton(height: 320),
      error: (err, st) => const ErrorState(),
      data: (profile) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ResponsiveGrid(
            children: [
              StatisticsCard(
                label: 'Total Experience',
                value: '${profile.experienceYears} yrs',
                icon: AppIcons.trendUp,
              ),
              StatisticsCard(
                label: 'HOD Experience',
                value: '${profile.hodExperienceYears} yrs',
                icon: AppIcons.faculty,
              ),
              StatisticsCard(
                label: 'Highest Qualification',
                value: 'Ph.D.',
                icon: AppIcons.education,
              ),
            ],
          ),
          const SizedBox(height: 20),
          AnalyticsCard(
            title: 'Educational Qualifications',
            child: Column(
              children: [
                for (final e in profile.education)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlueTint,
                            borderRadius: AppRadius.smRadius,
                          ),
                          child: const Icon(
                            AppIcons.education,
                            size: 18,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.degree,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              Text(
                                e.institution,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          e.yearCompleted.toString(),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
