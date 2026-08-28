import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_chart_palette.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/widgets/cards/statistics_card.dart';
import '../../../../core/widgets/data_display/custom_data_table.dart';
import '../../../../core/widgets/data_display/status_chip.dart';
import '../../../../core/widgets/data_display/table_container.dart';
import '../../../../core/widgets/feedback/error_state.dart';
import '../../../../core/widgets/feedback/loading_skeleton.dart';
import '../../../../core/widgets/inputs/filter_dropdown.dart';
import '../../../../core/widgets/inputs/search_field.dart';
import '../../models/audit.dart';
import '../../providers/audit_providers.dart';

AppStatus _statusFor(AuditSeverity severity) {
  switch (severity) {
    case AuditSeverity.routine:
      return AppStatus.info;
    case AuditSeverity.notable:
      return AppStatus.pending;
    case AuditSeverity.critical:
      return AppStatus.rejected;
  }
}

/// The recorded action trail, filterable by module, severity, and text.
class AuditLogTab extends ConsumerWidget {
  const AuditLogTab({super.key});

  static const String _all = '__all__';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(auditEntriesProvider);
    // Unfiltered totals, so the cards describe the trail rather than the
    // rows currently showing.
    final summary = ref.watch(auditSummaryProvider).valueOrNull;
    final modules = ref.watch(auditModulesProvider);
    final module = ref.watch(auditModuleFilterProvider);
    final severity = ref.watch(auditSeverityFilterProvider);

    return entriesAsync.when(
      loading: () => const CardSkeleton(height: 460),
      error: (err, st) => const ErrorState(),
      data: (entries) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ResponsiveGrid(
            children: [
              StatisticsCard(
                label: 'Actions Recorded',
                value: '${summary?.totalActions ?? 0}',
                icon: AppIcons.audit,
                iconColor: AppChartPalette.at(0),
                iconBackground: AppChartPalette.at(0).withValues(alpha: 0.10),
                subtitle: 'Last seven days',
              ),
              StatisticsCard(
                label: 'Critical Actions',
                value: '${summary?.criticalActions ?? 0}',
                icon: AppIcons.warning,
                iconColor: AppColors.danger,
                iconBackground: AppColors.dangerTint,
                subtitle: 'Require review',
              ),
              StatisticsCard(
                label: 'Modules Touched',
                value: '${modules.length}',
                icon: AppIcons.dashboard,
                iconColor: AppChartPalette.at(2),
                iconBackground: AppChartPalette.at(2).withValues(alpha: 0.10),
              ),
              StatisticsCard(
                label: 'Showing',
                value: '${entries.length}',
                icon: AppIcons.filter,
                iconColor: AppChartPalette.at(3),
                iconBackground: AppChartPalette.at(3).withValues(alpha: 0.10),
                subtitle: 'After active filters',
              ),
            ],
          ),
          const SizedBox(height: 20),
          TableContainer(
            title: 'Audit Trail',
            subtitle: 'Every recorded action, most recent first',
            actions: [
              SearchField(
                width: 230,
                hintText: 'Search actor or action',
                onChanged: (value) =>
                    ref.read(auditSearchProvider.notifier).state = value,
              ),
              FilterDropdown<String>(
                value: module ?? _all,
                items: [_all, ...modules],
                itemLabel: (value) => value == _all ? 'All Modules' : value,
                width: 165,
                onChanged: (value) =>
                    ref.read(auditModuleFilterProvider.notifier).state =
                        value == _all ? null : value,
              ),
              FilterDropdown<String>(
                value: severity?.name ?? _all,
                items: [
                  _all,
                  ...AuditSeverity.values.map((value) => value.name),
                ],
                itemLabel: (value) => value == _all
                    ? 'All Severities'
                    : AuditSeverity.values.byName(value).label,
                width: 165,
                onChanged: (value) =>
                    ref
                        .read(auditSeverityFilterProvider.notifier)
                        .state = value == _all
                    ? null
                    : AuditSeverity.values.byName(value!),
              ),
            ],
            child: CustomDataTable(
              emptyMessage: 'No recorded actions match the current filters.',
              columns: const [
                DataColumnConfig(label: 'Timestamp', size: ColumnSize.M),
                DataColumnConfig(label: 'Actor', size: ColumnSize.M),
                DataColumnConfig(label: 'Role', size: ColumnSize.M),
                DataColumnConfig(label: 'Action', size: ColumnSize.S),
                DataColumnConfig(label: 'Module', size: ColumnSize.S),
                DataColumnConfig(label: 'Detail', size: ColumnSize.L),
                DataColumnConfig(label: 'IP Address', size: ColumnSize.S),
                DataColumnConfig(label: 'Severity', size: ColumnSize.S),
              ],
              rows: [for (final entry in entries) _entryRow(entry)],
            ),
          ),
        ],
      ),
    );
  }

  DataRow2 _entryRow(AuditEntry entry) {
    return DataRow2(
      cells: [
        DataCell(
          Text(
            '${DateFormatter.shortDate(entry.timestamp)} '
            '${DateFormatter.time(entry.timestamp)}',
          ),
        ),
        DataCell(Text(entry.actor, overflow: TextOverflow.ellipsis)),
        DataCell(Text(entry.actorRole, overflow: TextOverflow.ellipsis)),
        DataCell(Text(entry.action.label)),
        DataCell(Text(entry.module)),
        DataCell(Text(entry.description, overflow: TextOverflow.ellipsis)),
        DataCell(Text(entry.ipAddress)),
        DataCell(
          StatusChip(
            status: _statusFor(entry.severity),
            customLabel: entry.severity.label,
          ),
        ),
      ],
    );
  }
}
