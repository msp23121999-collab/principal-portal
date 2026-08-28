import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/data_display/profile_banner.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_skeleton.dart';
import '../../../core/widgets/layout/tabbed_page.dart';
import '../providers/principal_profile_providers.dart';
import '../widgets/profile_stat_strip.dart';
import '../widgets/tabs/documents_tab.dart';
import '../widgets/tabs/personal_tab.dart';
import '../widgets/tabs/professional_degrees_tab.dart';
import '../widgets/tabs/research_teaching_tab.dart';
import '../widgets/tabs/responsibilities_tab.dart';

class PrincipalProfileScreen extends ConsumerWidget {
  const PrincipalProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(principalProfileProvider);

    return TabbedPage(
      header: profileAsync.when(
        loading: () => const CardSkeleton(height: 140),
        error: (err, st) => const ErrorState(),
        data: (profile) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProfileBanner(
              name: profile.name,
              badges: [
                ProfileBadge(
                  label: profile.designation,
                  icon: AppIcons.profile,
                ),
                ProfileBadge(
                  label: profile.employeeId,
                  icon: AppIcons.security,
                ),
                ProfileBadge(
                  label: '${profile.experienceYears} yrs experience',
                  icon: AppIcons.trendUp,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const ProfileStatStrip(),
          ],
        ),
      ),
      tabs: const [
        PageTab(label: 'Personal Profile', content: PersonalTab()),
        PageTab(
          label: 'Professional & Degrees',
          content: ProfessionalDegreesTab(),
        ),
        PageTab(label: 'Research & Teaching', content: ResearchTeachingTab()),
        PageTab(label: 'Responsibilities', content: ResponsibilitiesTab()),
        PageTab(label: 'Documents (Verified)', content: DocumentsTab()),
      ],
    );
  }
}
