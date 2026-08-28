import 'package:flutter/material.dart';
import '../../core/principal_compat.dart';
import '../../core/principal_compat.dart';
import '../../core/principal_compat.dart';

/// Semantic status meaning driving a StatusChip's color — covers every
/// status word used across the app (attendance, leave, results, ...).
enum AppStatus {
  present,
  absent,
  pending,
  approved,
  rejected,
  active,
  inactive,
  onLeave,
  passed,
  failed,
  info,
}

extension AppStatusX on AppStatus {
  String get label {
    switch (this) {
      case AppStatus.present:
        return 'Present';
      case AppStatus.absent:
        return 'Absent';
      case AppStatus.pending:
        return 'Pending';
      case AppStatus.approved:
        return 'Approved';
      case AppStatus.rejected:
        return 'Rejected';
      case AppStatus.active:
        return 'Active';
      case AppStatus.inactive:
        return 'Inactive';
      case AppStatus.onLeave:
        return 'On Leave';
      case AppStatus.passed:
        return 'Passed';
      case AppStatus.failed:
        return 'Failed';
      case AppStatus.info:
        return 'Info';
    }
  }

  Color get color {
    switch (this) {
      case AppStatus.present:
      case AppStatus.approved:
      case AppStatus.active:
      case AppStatus.passed:
        return AppColors.success;
      case AppStatus.absent:
      case AppStatus.rejected:
      case AppStatus.failed:
        return AppColors.danger;
      case AppStatus.pending:
      case AppStatus.onLeave:
        return AppColors.warning;
      case AppStatus.inactive:
      case AppStatus.info:
        return AppColors.secondaryText;
    }
  }
}

/// Colored status badge (Present/Absent/Pending/Approved/Rejected/...).
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, this.customLabel});

  final AppStatus status;
  final String? customLabel;

  @override
  Widget build(BuildContext context) {
    final color = status.color;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.smRadius,
      ),
      child: Text(
        customLabel ?? status.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
