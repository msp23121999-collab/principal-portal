import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../core/widgets/cards/highlight_list_card.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_skeleton.dart';
import '../../placements/providers/placement_providers.dart';
import '../../research/providers/research_providers.dart';
import '../providers/institution_providers.dart';

const List<Color> _accents = [
  AppColors.accentGold,
  AppColors.primaryBlue,
  AppColors.success,
  AppColors.darkBlue,
  AppColors.warning,
];

/// Side-rail summary of the institution's standout figures for the year.
///
/// Two kinds of highlight, and they come from different places on purpose.
/// Accreditations and rankings are awarded and recorded, so they are read from
/// `principal.institution_highlights`. Placements and research funding are
/// countable, and were being read from there too — stating 2,412 offers and 34
/// funded projects while the database held 60 and 10. Those two are counted
/// here, which is the only way they stay true as offers and grants are added.
class KeyHighlightsSection extends ConsumerWidget {
  const KeyHighlightsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final highlightsAsync = ref.watch(institutionHighlightsProvider);
    final placements = ref.watch(placementRecordsProvider).valueOrNull;
    final projects = ref.watch(fundedProjectsProvider).valueOrNull;

    return highlightsAsync.when(
      loading: () => const CardSkeleton(height: 360),
      error: (err, st) => const ErrorState(),
      data: (highlights) {
        final counted = <HighlightEntry>[
          if (placements != null && placements.isNotEmpty)
            HighlightEntry(
              icon: AppIcons.placements,
              title: 'Placements Recorded',
              detail:
                  '${placements.length} offers across '
                  '${placements.map((p) => p.companyName).toSet().length} '
                  'companies',
              color: AppColors.success,
            ),
          if (projects != null && projects.isNotEmpty)
            HighlightEntry(
              icon: AppIcons.research,
              title: 'Research Funding',
              detail:
                  '${NumberFormatter.rupees(projects.fold(0.0, (sum, p) => sum + p.sanctionedAmount))} '
                  'sanctioned across ${projects.length} funded projects',
              color: AppColors.accentGold,
            ),
        ];

        return HighlightListCard(
          title: 'Key Highlights',
          subtitle: 'Leading figures this academic year',
          entries: [
            ...counted,
            for (int i = 0; i < highlights.length; i++)
              HighlightEntry(
                icon: highlights[i].icon,
                title: highlights[i].title,
                detail: highlights[i].detail,
                color: _accents[i % _accents.length],
              ),
          ],
        );
      },
    );
  }
}
