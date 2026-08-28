import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

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
  review,
  important,
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
      case AppStatus.review:
        return 'Review';
      case AppStatus.important:
        return 'Important';
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
      case AppStatus.info:
        return AppColors.info;
      case AppStatus.review:
        return AppColors.accentPurple;
      case AppStatus.important:
        return AppColors.accentBlue;
      case AppStatus.inactive:
        return AppColors.secondaryText;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case AppStatus.present:
      case AppStatus.approved:
      case AppStatus.active:
      case AppStatus.passed:
        return AppColors.softGreen;
      case AppStatus.absent:
      case AppStatus.rejected:
      case AppStatus.failed:
        return AppColors.dangerBackground;
      case AppStatus.pending:
      case AppStatus.onLeave:
        return AppColors.softOrange;
      case AppStatus.info:
        return AppColors.softCyan;
      case AppStatus.review:
        return AppColors.softPurple;
      case AppStatus.important:
        return AppColors.softBlue;
      case AppStatus.inactive:
        return AppColors.secondaryTint;
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
        color: status.backgroundColor,
        // A pill, not a rounded square. Status is a label rather than a
        // container of content, and the stadium shape is what distinguishes
        // the two at a glance in a dense table.
        borderRadius: const BorderRadius.all(Radius.circular(999)),
        // A faint border of the status colour keeps the chip legible where the
        // tint alone is too pale to separate it from a white row.
        border: Border.all(color: color.withValues(alpha: 0.22)),
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
