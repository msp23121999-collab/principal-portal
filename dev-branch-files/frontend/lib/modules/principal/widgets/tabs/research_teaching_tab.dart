import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '.././cards/analytics_card.dart';
import '.././feedback/error_state.dart';
import '.././feedback/loading_skeleton.dart';
import '../../providers/principal_profile_providers.dart';

/// Research publications and academic awards/recognitions.
class ResearchTeachingTab extends ConsumerWidget {
  const ResearchTeachingTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(principalProfileProvider);

    return profileAsync.when(
      loading: () => const CardSkeleton(height: 320),
      error: (err, st) => const ErrorState(),
      data: (profile) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnalyticsCard(
            title: 'Research Publications',
            subtitle: '${profile.researchPapers.length} papers published',
            child: Column(
              children: [
                for (final p in profile.researchPapers)
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
                            AppIcons.research,
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
                                p.title,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              Text(
                                '${p.journalOrConference} · ${p.year}${p.doiOrLink != null ? ' · ${p.doiOrLink}' : ''}',
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
          ),
          const SizedBox(height: 20),
          AnalyticsCard(
            title: 'Awards & Recognitions',
            child: Column(
              children: [
                for (final a in profile.awards)
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
                            color: AppColors.accentGoldTint,
                            borderRadius: AppRadius.smRadius,
                          ),
                          child: const Icon(
                            AppIcons.award,
                            size: 18,
                            color: AppColors.accentGold,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                a.title,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              Text(
                                '${a.issuedBy} · ${a.year}',
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
          ),
        ],
      ),
    );
  }
}
