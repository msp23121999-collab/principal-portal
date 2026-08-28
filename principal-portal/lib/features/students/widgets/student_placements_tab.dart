import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/department_normalizer.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/buttons/icon_action_button.dart';
import '../../../core/widgets/cards/statistics_card.dart';
import '../../../core/widgets/data_display/custom_data_table.dart';
import '../../../core/widgets/data_display/status_chip.dart';
import '../../../core/widgets/data_display/table_container.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_skeleton.dart';
import '../../placements/models/placement_record.dart';
import '../../placements/providers/placement_providers.dart';
import '../models/student.dart';
import '../providers/student_providers.dart';
import 'student_profile_dialog.dart';

/// Individual student placement records.
class StudentPlacementsTab extends ConsumerWidget {
  const StudentPlacementsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placementsAsync = ref.watch(filteredPlacementsProvider);

    return placementsAsync.when(
      loading: () => const CardSkeleton(height: 460),
      error: (err, st) => const ErrorState(),
      data: (records) {
        final highest = records.isEmpty
            ? 0.0
            : records.map((r) => r.packageLpa).reduce((a, b) => a > b ? a : b);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ResponsiveGrid(
              children: [
                StatisticsCard(
                  label: 'Students Placed',
                  value: '${records.length}',
                  icon: AppIcons.check,
                  iconColor: AppColors.success,
                  iconBackground: AppColors.successTint,
                  subtitle: 'In current selection',
                ),
                StatisticsCard(
                  label: 'Highest Package',
                  value: '₹${highest.toStringAsFixed(1)} LPA',
                  icon: AppIcons.award,
                  iconColor: AppColors.accentGold,
                  iconBackground: AppColors.accentGoldTint,
                ),
              ],
            ),
            const SizedBox(height: 20),
            TableContainer(
              title: 'Student Placements',
              subtitle: 'Individual placement records',
              child: CustomDataTable(
                emptyMessage: 'No placement records found.',
                columns: const [
                  DataColumnConfig(label: 'Student', size: ColumnSize.L),
                  DataColumnConfig(label: 'Register No', size: ColumnSize.M),
                  DataColumnConfig(label: 'Dept', size: ColumnSize.S),
                  DataColumnConfig(label: 'Batch', size: ColumnSize.S),
                  DataColumnConfig(label: 'Company', size: ColumnSize.L),
                  DataColumnConfig(
                    label: 'Package',
                    numeric: true,
                    size: ColumnSize.M,
                  ),
                  DataColumnConfig(label: 'Date', size: ColumnSize.M),
                  DataColumnConfig(label: 'Status', size: ColumnSize.S),
                  DataColumnConfig(label: '', size: ColumnSize.S),
                ],
                rows: [
                  for (final record in records)
                    _placementRow(context, ref, record),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  DataRow2 _placementRow(
    BuildContext context,
    WidgetRef ref,
    PlacementRecord record,
  ) {
    final roster = ref.read(studentListProvider).valueOrNull ?? const [];
    final student =
        roster.where((s) => s.rollNumber == record.rollNumber).firstOrNull ??
        Student(
          id: '',
          name: record.studentName,
          rollNumber: record.rollNumber,
          departmentId: record.departmentId,
          semester: 0,
          cgpa: 0.0,
          attendancePercent: 0.0,
          isTopPerformer: false,
          isAtRisk: false,
        );

    return DataRow2(
      cells: [
        DataCell(Text(record.studentName, overflow: TextOverflow.ellipsis)),
        DataCell(Text(record.rollNumber)),
        DataCell(Text(DepartmentNormalizer.codeFor(record.departmentId))),
        DataCell(Text(record.batchRange ?? '—')),
        DataCell(Text(record.companyName, overflow: TextOverflow.ellipsis)),
        DataCell(Text('₹${record.packageLpa.toStringAsFixed(1)} L')),
        DataCell(Text(DateFormatter.shortDate(record.offerDate))),
        const DataCell(
          StatusChip(status: AppStatus.approved, customLabel: 'Placed'),
        ),
        DataCell(
          IconActionButton(
            icon: AppIcons.chevronRight,
            tooltip: 'View ${record.studentName}',
            onPressed: () =>
                StudentProfileDialog.show(context, student: student),
          ),
        ),
      ],
    );
  }
}
