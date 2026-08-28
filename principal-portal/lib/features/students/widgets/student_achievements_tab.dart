import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_client.dart';
import '../../../core/theme/app_chart_palette.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/buttons/icon_action_button.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/cards/statistics_card.dart';
import '../../../core/widgets/data_display/custom_data_table.dart';
import '../../../core/widgets/data_display/status_chip.dart';
import '../../../core/widgets/data_display/table_container.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_skeleton.dart';
import '../../../core/widgets/inputs/filter_chip_group.dart';
import '../models/student.dart';
import '../models/student_achievement.dart';
import '../providers/student_providers.dart';
import 'student_profile_dialog.dart';

AppStatus _statusFor(AchievementLevel level) {
  switch (level) {
    case AchievementLevel.international:
      return AppStatus.approved;
    case AchievementLevel.national:
      return AppStatus.passed;
    case AchievementLevel.state:
      return AppStatus.pending;
    case AchievementLevel.institutional:
      return AppStatus.info;
  }
}

/// Recognitions won by students beyond the examination hall.
class StudentAchievementsTab extends ConsumerWidget {
  const StudentAchievementsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(studentAchievementsProvider);
    // Unfiltered, so the KPI cards report the year rather than the selection.
    final allAchievements =
        ref.watch(allStudentAchievementsProvider).valueOrNull ??
        const <StudentAchievement>[];
    int atLevel(AchievementLevel level) =>
        allAchievements.where((a) => a.level == level).length;
    final category = ref.watch(achievementCategoryFilterProvider);

    return achievementsAsync.when(
      loading: () => const CardSkeleton(height: 460),
      error: (err, st) => const ErrorState(),
      data: (achievements) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ResponsiveGrid(
            children: [
              StatisticsCard(
                label: 'Recognitions This Year',
                value: '${allAchievements.length}',
                icon: AppIcons.award,
                iconColor: AppChartPalette.at(0),
                iconBackground: AppChartPalette.at(0).withValues(alpha: 0.10),
              ),
              StatisticsCard(
                label: 'International',
                value: '${atLevel(AchievementLevel.international)}',
                icon: AppIcons.language,
                iconColor: AppColors.success,
                iconBackground: AppColors.successTint,
              ),
              StatisticsCard(
                label: 'National',
                value: '${atLevel(AchievementLevel.national)}',
                icon: AppIcons.institution,
                iconColor: AppChartPalette.at(2),
                iconBackground: AppChartPalette.at(2).withValues(alpha: 0.10),
              ),
              StatisticsCard(
                label: 'State',
                value: '${atLevel(AchievementLevel.state)}',
                icon: AppIcons.department,
                iconColor: AppColors.accentGold,
                iconBackground: AppColors.accentGoldTint,
              ),
            ],
          ),
          const SizedBox(height: 20),
          FilterChipGroup<AchievementCategory>(
            value: category,
            items: AchievementCategory.values,
            itemLabel: (value) => value.label,
            onChanged: (value) =>
                ref.read(achievementCategoryFilterProvider.notifier).state =
                    value,
          ),
          const SizedBox(height: 20),
          TableContainer(
            title: 'Student Achievements',
            subtitle: '${achievements.length} recognitions, most recent first',
            actions: [
              PrimaryButton(
                label: 'Import CSV',
                icon: AppIcons.upload,
                onPressed: () => _showImportDialog(context, ref),
              ),
            ],
            child: CustomDataTable(
              emptyMessage: 'No achievements recorded in this category.',
              columns: const [
                DataColumnConfig(label: 'Student', size: ColumnSize.M),
                DataColumnConfig(label: 'Dept', size: ColumnSize.S),
                DataColumnConfig(label: 'Achievement', size: ColumnSize.L),
                DataColumnConfig(label: 'Event', size: ColumnSize.L),
                DataColumnConfig(label: 'Category', size: ColumnSize.S),
                DataColumnConfig(label: 'Position', size: ColumnSize.M),
                DataColumnConfig(label: 'Date', size: ColumnSize.M),
                DataColumnConfig(label: 'Level', size: ColumnSize.S),
                DataColumnConfig(label: '', size: ColumnSize.S),
              ],
              rows: [
                for (final achievement in achievements)
                  _achievementRow(context, ref, achievement),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showImportDialog(BuildContext context, WidgetRef ref) {
    final yr = DateTime.now().year.toString();
    final controller = TextEditingController(
      text: 'student_name,department_code,title,event,category,level,position,achieved_on\n'
          'TEST_PRINCIPAL_IMPORT_UI_1,CSE,Code Sprint $yr,National Hackathon,technical,national,1st Place,$yr-08-01\n'
          'TEST_PRINCIPAL_IMPORT_UI_2,ECE,Robo Wars $yr,International Tech Fest,technical,international,Runner Up,$yr-08-15',
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isSubmitting = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Bulk CSV Import — Student Achievements'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 550,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Paste or edit CSV records below (headers required):\n'
                        'student_name, department_code, title, event, category, level, position, achieved_on',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: controller,
                        maxLines: 8,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'student_name,department_code,title,event,category,level,position,achieved_on',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setState(() => isSubmitting = true);
                          final messenger = ScaffoldMessenger.of(context);
                          final nav = Navigator.of(dialogContext);
                          try {
                            final res = await ApiClient.uploadCSV(
                              table: 'student_achievements',
                              csvContent: controller.text,
                              fileName: 'student_achievements_import.csv',
                            );
                            ref.invalidate(studentAchievementsProvider);
                            ref.invalidate(allStudentAchievementsProvider);
                            nav.pop();
                            messenger.showSnackBar(
                              SnackBar(
                                backgroundColor: Colors.green.shade800,
                                content: Text('CSV Import Success: ${res['message']}'),
                              ),
                            );
                          } catch (err) {
                            setState(() => isSubmitting = false);
                            if (!context.mounted) return;
                            await showDialog(
                              context: context,
                              builder: (errCtx) => AlertDialog(
                                title: const Text('Import Validation Failed'),
                                content: Text(err.toString().replaceAll('Exception: ', '')),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(errCtx).pop(),
                                    child: const Text('OK'),
                                  )
                                ],
                              ),
                            );
                          }
                        },
                  child: isSubmitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Import CSV'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  DataRow2 _achievementRow(
    BuildContext context,
    WidgetRef ref,
    StudentAchievement achievement,
  ) {
    final roster = ref.read(studentListProvider).valueOrNull ?? const [];
    final student =
        roster.where((s) => s.name == achievement.studentName).firstOrNull ??
        Student(
          id: '',
          name: achievement.studentName,
          rollNumber: 'Unknown',
          departmentId: achievement.departmentCode,
          semester: 0,
          cgpa: 0.0,
          attendancePercent: 0.0,
          isTopPerformer: false,
          isAtRisk: false,
        );

    return DataRow2(
      cells: [
        DataCell(
          Text(achievement.studentName, overflow: TextOverflow.ellipsis),
        ),
        DataCell(Text(achievement.departmentCode)),
        DataCell(Text(achievement.title, overflow: TextOverflow.ellipsis)),
        DataCell(Text(achievement.event, overflow: TextOverflow.ellipsis)),
        DataCell(Text(achievement.category.label)),
        DataCell(Text(achievement.position)),
        DataCell(Text(DateFormatter.shortDate(achievement.achievedOn))),
        DataCell(
          StatusChip(
            status: _statusFor(achievement.level),
            customLabel: achievement.level.label,
          ),
        ),
        DataCell(
          IconActionButton(
            icon: AppIcons.chevronRight,
            tooltip: 'View ${achievement.studentName}',
            onPressed: () =>
                StudentProfileDialog.show(context, student: student),
          ),
        ),
      ],
    );
  }
}
