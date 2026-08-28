import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_skeleton.dart';
import '../providers/principal_profile_providers.dart';

/// Row of small stat chips beneath the ProfileBanner (experience, HOD
/// tenure, research output, awards) — matches the HOD Portal reference
/// profile page's stat-strip styling.
class ProfileStatStrip extends ConsumerWidget {
  const ProfileStatStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(principalProfileProvider);

    return profileAsync.when(
      loading: () => Row(
        children: List.generate(
          4,
          (_) => const Expanded(
            child: Padding(
              padding: EdgeInsets.all(4),
              child: CardSkeleton(height: 72),
            ),
          ),
        ),
      ),
      error: (err, st) => const ErrorState(),
      data: (profile) => DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.mdRadius,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            _StatChip(
              icon: AppIcons.trendUp,
              value: '${profile.experienceYears} Years',
              label: 'Teaching Experience',
            ),
            _divider(),
            _StatChip(
              icon: AppIcons.faculty,
              value: '${profile.hodExperienceYears} Yrs',
              label: 'HOD Leadership',
            ),
            _divider(),
            _StatChip(
              icon: AppIcons.research,
              value: '${profile.researchPapers.length}',
              label: 'Research Papers',
            ),
            _divider(),
            _StatChip(
              icon: AppIcons.award,
              value: '${profile.awards.length}',
              label: 'Awards',
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() => const SizedBox(
    height: 48,
    child: VerticalDivider(width: 1, color: AppColors.border),
  );
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primaryBlue),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
