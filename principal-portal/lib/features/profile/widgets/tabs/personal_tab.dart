import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/cards/analytics_card.dart';
import '../../../../core/widgets/cards/info_tile.dart';
import '../../../../core/widgets/feedback/error_state.dart';
import '../../../../core/widgets/feedback/loading_skeleton.dart';
import '../../providers/principal_profile_providers.dart';

/// Personal demographics and contact details.
class PersonalTab extends ConsumerWidget {
  const PersonalTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(principalProfileProvider);

    return profileAsync.when(
      loading: () => const CardSkeleton(height: 320),
      error: (err, st) => const ErrorState(),
      data: (profile) => AnalyticsCard(
        title: 'Personal Demographics & Contacts',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.xl,
                crossAxisSpacing: AppSpacing.xl,
                childAspectRatio: 5.4,
              ),
              children: [
                InfoTile(label: 'Full Legal Name', value: profile.name),
                InfoTile(
                  label: 'Date of Birth',
                  value: DateFormatter.shortDate(profile.dateOfBirth),
                ),
                InfoTile(label: 'Gender', value: profile.gender),
                InfoTile(label: 'Employee ID', value: profile.employeeId),
                InfoTile(
                  label: 'Email',
                  value: profile.contactInfo.email,
                  icon: AppIcons.mail,
                ),
                InfoTile(
                  label: 'Phone',
                  value: profile.contactInfo.phone,
                  icon: AppIcons.phone,
                ),
                InfoTile(
                  label: 'Office Cabin',
                  value: profile.officeDetails.cabinLocation,
                  icon: AppIcons.location,
                ),
                InfoTile(
                  label: 'Office Hours',
                  value: profile.officeDetails.officeHours,
                  icon: AppIcons.clock,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            InfoTile(
              label: 'Address',
              value: profile.contactInfo.address,
              icon: AppIcons.location,
            ),
          ],
        ),
      ),
    );
  }
}
