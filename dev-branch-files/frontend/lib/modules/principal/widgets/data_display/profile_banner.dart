import 'package:flutter/material.dart';
import '../../core/principal_compat.dart';
import '../../core/principal_compat.dart';
import '../../core/principal_compat.dart';
import '../buttons/primary_button.dart';
import '../buttons/secondary_button.dart';

/// A single badge shown under the name in a ProfileBanner (designation,
/// department, ID, status).
class ProfileBadge {
  const ProfileBadge({required this.label, this.icon});

  final String label;
  final IconData? icon;
}

/// Dark navy hero banner used at the top of profile pages — photo/avatar,
/// name, active-status pill, badges row, and trailing actions. Matches the
/// HOD Portal reference banner styling.
class ProfileBanner extends StatelessWidget {
  const ProfileBanner({
    super.key,
    required this.name,
    required this.badges,
    this.avatarInitial,
    this.statusLabel = 'Active',
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  final String name;
  final List<ProfileBadge> badges;
  final String? avatarInitial;
  final String statusLabel;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.darkBlue,
        borderRadius: AppRadius.mdRadius,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              avatarInitial ?? (name.isEmpty ? '' : name[0]),
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Welcome back,',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.2),
                        borderRadius: AppRadius.smRadius,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.circle,
                            size: 8,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            statusLabel.toUpperCase(),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: AppColors.success),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  name,
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final b in badges)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: AppRadius.smRadius,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (b.icon != null) ...[
                              Icon(b.icon, size: 13, color: Colors.white),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              b.label,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (secondaryActionLabel != null || primaryActionLabel != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (secondaryActionLabel != null)
                  SecondaryButton(
                    label: secondaryActionLabel!,
                    onPressed: onSecondaryAction,
                  ),
                if (secondaryActionLabel != null && primaryActionLabel != null)
                  const SizedBox(height: AppSpacing.sm),
                if (primaryActionLabel != null)
                  PrimaryButton(
                    label: primaryActionLabel!,
                    onPressed: onPrimaryAction,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
