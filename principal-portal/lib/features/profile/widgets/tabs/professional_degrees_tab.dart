import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_chart_palette.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/widgets/cards/analytics_card.dart';
import '../../../../core/widgets/cards/statistics_card.dart';
import '../../../../core/widgets/feedback/error_state.dart';
import '../../../../core/widgets/feedback/loading_skeleton.dart';
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
                iconColor: AppChartPalette.at(0),
                iconBackground: AppChartPalette.at(0).withValues(alpha: 0.10),
              ),
              StatisticsCard(
                label: 'HOD Experience',
                value: '${profile.hodExperienceYears} yrs',
                icon: AppIcons.faculty,
                iconColor: AppChartPalette.at(1),
                iconBackground: AppChartPalette.at(1).withValues(alpha: 0.10),
              ),
              StatisticsCard(
                label: 'Highest Qualification',
                value: 'Ph.D.',
                icon: AppIcons.education,
                iconColor: AppChartPalette.at(2),
                iconBackground: AppChartPalette.at(2).withValues(alpha: 0.10),
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
