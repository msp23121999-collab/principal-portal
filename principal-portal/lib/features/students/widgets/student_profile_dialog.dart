import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/department_normalizer.dart';
import '../../../core/utils/program_level.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/buttons/secondary_button.dart';
import '../../../core/widgets/cards/info_tile.dart';
import '../../../core/widgets/data_display/status_chip.dart';
import '../../placements/providers/placement_providers.dart';
import '../models/student.dart';
import '../models/student_achievement.dart';
import '../providers/student_providers.dart';

/// Full profile for one student: academic performance, attendance, and achievements.
class StudentProfileDialog extends ConsumerWidget {
  const StudentProfileDialog({super.key, required this.student});

  final Student student;

  static Future<void> show(BuildContext context, {required Student student}) {
    return showDialog<void>(
      context: context,
      builder: (_) => StudentProfileDialog(student: student),
    );
  }

  String _getAtRiskReason() {
    final reasons = <String>[];
    if (student.attendancePercent < 75) {
      reasons.add(
        'Low attendance (${student.attendancePercent.toStringAsFixed(1)}%)',
      );
    }
    if (student.cgpa < 6.0) {
      reasons.add('Low CGPA (${student.cgpa.toStringAsFixed(2)})');
    }
    if (reasons.isEmpty) {
      return 'Flagged for academic intervention.';
    }
    return reasons.join(' • ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final departmentName = DepartmentNormalizer.displayName(
      DepartmentNormalizer.codeFor(student.departmentId),
    );

    final allAchievements =
        ref.watch(allStudentAchievementsProvider).valueOrNull ?? [];
    final studentAchievements = allAchievements
        .where((a) => a.studentName == student.name)
        .toList();

    final allPlacements =
        ref.watch(filteredPlacementsProvider).valueOrNull ?? [];
    final studentPlacements = allPlacements
        .where((p) => p.rollNumber == student.rollNumber)
        .toList();

    return AlertDialog(
      title: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.primaryBlue,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              student.name.isEmpty ? '?' : student.name[0],
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  student.name,
                  style: Theme.of(context).textTheme.titleLarge,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${student.rollNumber} · $departmentName',
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ResponsiveGrid(
                minTileWidth: 170,
                gutter: 12,
                children: [
                  InfoTile(
                    label: 'Programme',
                    value: student.programLevel?.label ?? '—',
                    icon: AppIcons.education,
                  ),
                  InfoTile(
                    label: 'Batch',
                    value: student.batch ?? '—',
                    icon: AppIcons.clock,
                  ),
                  InfoTile(
                    label: 'Year / Sem',
                    value:
                        '${student.yearOfStudy ?? '—'} / ${student.semester}',
                    icon: AppIcons.department,
                  ),
                  InfoTile(
                    label: 'Attendance',
                    value: '${student.attendancePercent.toStringAsFixed(1)}%',
                    icon: AppIcons.attendance,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _Section(
                title: 'Academic Performance',
                children: [
                  _MetricRow(
                    label: 'CGPA',
                    value: student.cgpa.toStringAsFixed(2),
                    trailing: student.isTopPerformer
                        ? const StatusChip(
                            status: AppStatus.passed,
                            customLabel: 'Top Performer',
                          )
                        : null,
                  ),
                  _MetricRow(
                    label: 'Result Status',
                    value: student.cgpa >= 5.0 ? 'Pass' : 'Fail',
                  ),
                ],
              ),
              if (student.isAtRisk) ...[
                const SizedBox(height: AppSpacing.lg),
                _Section(
                  title: 'Attention Required',
                  children: [
                    const _MetricRow(
                      label: 'Status',
                      value: '',
                      trailing: StatusChip(
                        status: AppStatus.rejected,
                        customLabel: 'At Risk',
                      ),
                    ),
                    _MetricRow(label: 'Reason', value: _getAtRiskReason()),
                  ],
                ),
              ],
              if (studentPlacements.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                _Section(
                  title: 'Placements',
                  children: [
                    for (final placement in studentPlacements) ...[
                      _MetricRow(
                        label: 'Company',
                        value: placement.companyName,
                        trailing: const StatusChip(
                          status: AppStatus.approved,
                          customLabel: 'Placed',
                        ),
                      ),
                      _MetricRow(
                        label: 'Package',
                        value:
                            '₹${placement.packageLpa.toStringAsFixed(1)} LPA',
                      ),
                    ],
                  ],
                ),
              ],
              if (studentAchievements.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                _Section(
                  title: 'Achievements',
                  children: [
                    for (final achievement in studentAchievements)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              AppIcons.award,
                              size: 16,
                              color: AppColors.accentGold,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                '${achievement.title} (${achievement.level.label})',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      actions: [
        SecondaryButton(
          label: 'Close',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadius.smRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          ...children,
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value, this.trailing});

  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Text(value, style: Theme.of(context).textTheme.titleSmall),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}
