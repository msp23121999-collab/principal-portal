import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/data_display/custom_data_table.dart';
import '../../../core/widgets/data_display/status_chip.dart';
import '../../../core/widgets/data_display/table_container.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_skeleton.dart';
import '../../../core/widgets/inputs/filter_dropdown.dart';
import '../models/placement_drive.dart';
import '../providers/placement_providers.dart';

AppStatus _statusFor(DriveStage stage) {
  switch (stage) {
    case DriveStage.scheduled:
      return AppStatus.info;
    case DriveStage.ongoing:
      return AppStatus.pending;
    case DriveStage.completed:
      return AppStatus.approved;
    case DriveStage.cancelled:
      return AppStatus.rejected;
  }
}

/// Company visits this season — who came, who they saw, and what came of
/// it — filterable by stage.
class PlacementDrivesTable extends ConsumerWidget {
  const PlacementDrivesTable({super.key});

  static const String _allStages = '__all__';

  /// The period the listed campus visits fall across.
  String _seasonOf(List<PlacementDrive> drives) {
    final period = DateFormatter.monthRange([
      for (final d in drives) d.visitDate,
    ]);
    return period == null ? 'No drives scheduled' : 'Campus visits, $period';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drivesAsync = ref.watch(placementDrivesProvider);
    final stage = ref.watch(driveStageFilterProvider);

    return drivesAsync.when(
      loading: () => const CardSkeleton(height: 420),
      error: (err, st) => const ErrorState(),
      data: (drives) => TableContainer(
        title: 'Recruitment Drives',
        // Read from the drives listed. The season used to be written into the
        // caption as "2025-26" whatever dates the table actually held.
        subtitle: _seasonOf(drives),
        actions: [
          FilterDropdown<String>(
            value: stage?.name ?? _allStages,
            items: [_allStages, ...DriveStage.values.map((s) => s.name)],
            itemLabel: (value) => value == _allStages
                ? 'All Stages'
                : DriveStage.values.byName(value).label,
            width: 170,
            onChanged: (value) =>
                ref
                    .read(driveStageFilterProvider.notifier)
                    .state = value == _allStages
                ? null
                : DriveStage.values.byName(value!),
          ),
        ],
        child: CustomDataTable(
          emptyMessage: 'No drives at this stage.',
          columns: const [
            DataColumnConfig(label: 'Company', size: ColumnSize.M),
            DataColumnConfig(label: 'Role', size: ColumnSize.L),
            DataColumnConfig(label: 'Visit Date', size: ColumnSize.M),
            DataColumnConfig(label: 'Eligible', size: ColumnSize.L),
            DataColumnConfig(label: 'Registered', numeric: true),
            DataColumnConfig(label: 'Shortlisted', numeric: true),
            DataColumnConfig(label: 'Offers', numeric: true),
            DataColumnConfig(label: 'Package', numeric: true),
            DataColumnConfig(label: 'Stage', size: ColumnSize.S),
          ],
          rows: [for (final drive in drives) _driveRow(drive)],
        ),
      ),
    );
  }

  DataRow2 _driveRow(PlacementDrive drive) {
    return DataRow2(
      cells: [
        DataCell(Text(drive.companyName, overflow: TextOverflow.ellipsis)),
        DataCell(Text(drive.role, overflow: TextOverflow.ellipsis)),
        DataCell(Text(DateFormatter.shortDate(drive.visitDate))),
        DataCell(
          Text(
            drive.eligibleDepartments.join(', '),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        DataCell(Text('${drive.registered}')),
        DataCell(Text(drive.shortlisted == 0 ? '—' : '${drive.shortlisted}')),
        DataCell(Text(drive.offersMade == 0 ? '—' : '${drive.offersMade}')),
        DataCell(Text('₹${drive.packageLpa.toStringAsFixed(1)} LPA')),
        DataCell(
          StatusChip(
            status: _statusFor(drive.stage),
            customLabel: drive.stage.label,
          ),
        ),
      ],
    );
  }
}
