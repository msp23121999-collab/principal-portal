import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/department_normalizer.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/buttons/secondary_button.dart';
import '../../../core/widgets/cards/info_tile.dart';
import '../../../core/widgets/data_display/status_chip.dart';
import '../models/faculty.dart';
import '../models/faculty_detail.dart';

/// Full profile for one faculty member: identity, workload, appraisal,
/// research output, and any recognitions on record.
class FacultyProfileDialog extends StatelessWidget {
  const FacultyProfileDialog({
    super.key,
    required this.faculty,
    required this.detail,
  });

  final Faculty faculty;
  final FacultyDetail detail;

  String _getSupportReason() {
    final reasons = <String>[];
    if (faculty.attendancePercent < 75) {
      reasons.add(
        'Low attendance (${faculty.attendancePercent.toStringAsFixed(1)}%)',
      );
    }
    if (detail.appraisalScore != null && detail.appraisalScore! < 60) {
      reasons.add(
        'Low appraisal (${detail.appraisalScore!.toStringAsFixed(0)}/100)',
      );
    }
    if (detail.feedbackScore != null && detail.feedbackScore! < 3.0) {
      reasons.add(
        'Low student feedback (${detail.feedbackScore!.toStringAsFixed(1)}/5.0)',
      );
    }
    if (detail.isOverloaded) {
      reasons.add('Workload exceeds norm');
    }

    if (reasons.isEmpty) {
      return 'Overall performance score is below expectation.';
    }
    return reasons.join(' • ');
  }

  static Future<void> show(
    BuildContext context, {
    required Faculty faculty,
    required FacultyDetail detail,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => FacultyProfileDialog(faculty: faculty, detail: detail),
    );
  }

  @override
  Widget build(BuildContext context) {
    final departmentName = DepartmentNormalizer.displayName(
      DepartmentNormalizer.codeFor(faculty.departmentId),
    );

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
              faculty.name.isEmpty ? '?' : faculty.name[0],
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
                  faculty.name,
                  style: Theme.of(context).textTheme.titleLarge,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${faculty.designation.label} · $departmentName',
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
                    label: 'Qualification',
                    value: NumberFormatter.orDash(detail.qualification),
                    icon: AppIcons.education,
                  ),
                  InfoTile(
                    label: 'Email',
                    value: NumberFormatter.orDash(detail.email),
                    icon: AppIcons.mail,
                  ),
                  InfoTile(
                    label: 'Attendance',
                    value: '${faculty.attendancePercent.toStringAsFixed(1)}%',
                    icon: AppIcons.attendance,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _Section(
                title: 'Teaching Workload',
                children: [
                  _MetricRow(
                    label: 'Weekly contact hours',
                    value: NumberFormatter.orDash(
                      detail.weeklyTeachingHours,
                      (hours) => '$hours hrs',
                    ),
                    // No chip at all when the workload is unrecorded. "Within
                    // norm" against an em dash would be a verdict on a figure
                    // nobody has entered.
                    trailing: detail.weeklyTeachingHours == null
                        ? null
                        : StatusChip(
                            status: detail.isOverloaded
                                ? AppStatus.rejected
                                : AppStatus.approved,
                            customLabel: detail.isOverloaded
                                ? 'Above norm'
                                : 'Within norm',
                          ),
                  ),
                  _MetricRow(
                    label: 'Subjects handled',
                    value: NumberFormatter.orDash(detail.subjectsHandled),
                  ),
                  _MetricRow(
                    label: 'Students mentored',
                    value: NumberFormatter.orDash(detail.mentees),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _Section(
                title: 'Appraisal & Feedback',
                children: [
                  _MetricRow(
                    label: 'Annual appraisal score',
                    value: NumberFormatter.orDash(
                      detail.appraisalScore,
                      (score) => '${score.toStringAsFixed(0)} / 100',
                    ),
                  ),
                  _MetricRow(
                    label: 'Student feedback',
                    value: NumberFormatter.orDash(
                      detail.feedbackScore,
                      (score) => '${score.toStringAsFixed(1)} / 5.0',
                    ),
                  ),
                  _MetricRow(
                    label: 'Performance score',
                    value: faculty.performanceScore.toStringAsFixed(0),
                  ),
                ],
              ),
              if (faculty.performanceScore < 70) ...[
                const SizedBox(height: AppSpacing.lg),
                _Section(
                  title: 'Attention Required',
                  children: [
                    const _MetricRow(
                      label: 'Status',
                      value: '',
                      trailing: StatusChip(
                        status: AppStatus.rejected,
                        customLabel: 'Needs Support',
                      ),
                    ),
                    _MetricRow(label: 'Reason', value: _getSupportReason()),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              _Section(
                title: 'Research Output',
                children: [
                  _MetricRow(
                    label: 'Publications',
                    value: '${faculty.researchPapersCount}',
                  ),
                  _MetricRow(
                    label: 'Funded projects',
                    // 'None' only when a zero was actually recorded; an em dash
                    // when nobody has said either way.
                    value: NumberFormatter.orDash(
                      detail.fundedProjects,
                      (count) => count == 0 ? 'None' : '$count',
                    ),
                  ),
                ],
              ),
              if (detail.achievements.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                _Section(
                  title: 'Recognitions',
                  children: [
                    for (final achievement in detail.achievements)
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
                                achievement,
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
