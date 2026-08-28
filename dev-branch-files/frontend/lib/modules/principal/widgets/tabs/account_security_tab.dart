import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_spacing.dart';
import '.././buttons/secondary_button.dart';
import '.././cards/analytics_card.dart';
import '.././cards/info_tile.dart';
import '.././feedback/confirmation_dialog.dart';

/// Local-only UI state for the two-factor-authentication toggle — there is
/// no auth backend yet, so this simply reflects the switch position.
final twoFactorEnabledProvider = StateProvider<bool>((ref) => true);

/// Account security settings: password policy, 2FA, and login session info.
class AccountSecurityTab extends ConsumerWidget {
  const AccountSecurityTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final twoFactorEnabled = ref.watch(twoFactorEnabledProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnalyticsCard(
          title: 'Password',
          subtitle: 'Last changed 45 days ago',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: InfoTile(
                  label: 'Password Policy',
                  value:
                      'Minimum 12 characters, upper/lowercase, number, symbol',
                  icon: AppIcons.security,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              SecondaryButton(
                label: 'Change Password',
                icon: AppIcons.security,
                onPressed: () => ConfirmationDialog.show(
                  context,
                  title: 'Change Password',
                  message:
                      'A password reset link will be sent to your registered email address.',
                  confirmLabel: 'Send Link',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        AnalyticsCard(
          title: 'Two-Factor Authentication',
          subtitle: 'Adds an extra verification step at login',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  twoFactorEnabled
                      ? 'Two-factor authentication is currently enabled.'
                      : 'Two-factor authentication is currently disabled.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
              Switch(
                value: twoFactorEnabled,
                onChanged: (value) =>
                    ref.read(twoFactorEnabledProvider.notifier).state = value,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const AnalyticsCard(
          title: 'Recent Login Activity',
          child: Column(
            children: [
              InfoTile(
                label: 'Last Login',
                value: 'Today, 09:14 AM — Chrome on Windows',
              ),
              SizedBox(height: AppSpacing.lg),
              InfoTile(
                label: 'Previous Login',
                value: 'Yesterday, 06:48 PM — Chrome on Windows',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
