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
import '../../models/research.dart';
import '../../providers/research_providers.dart';

AppStatus _statusFor(PatentStage stage) {
  switch (stage) {
    case PatentStage.filed:
      return AppStatus.pending;
    case PatentStage.published:
      return AppStatus.info;
    case PatentStage.granted:
      return AppStatus.approved;
  }
}

/// Patent applications and where each stands in the IPR process.
class PatentsTab extends ConsumerWidget {
  const PatentsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patentsAsync = ref.watch(patentsProvider);

    return patentsAsync.when(
      loading: () => const CardSkeleton(height: 420),
      error: (err, st) => const ErrorState(),
      data: (patents) {
        final filed = patents.where((p) => p.stage == PatentStage.filed).length;
        final published = patents
            .where((p) => p.stage == PatentStage.published)
            .length;
        final granted = patents
            .where((p) => p.stage == PatentStage.granted)
            .length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ResponsiveGrid(
              children: [
                StatisticsCard(
                  label: 'Applications on Record',
                  value: '${patents.length}',
                  icon: AppIcons.innovation,
                  iconColor: AppChartPalette.at(0),
                  iconBackground: AppChartPalette.at(0).withValues(alpha: 0.10),
                ),
                StatisticsCard(
                  label: 'Awaiting Publication',
                  value: '$filed',
                  icon: AppIcons.clock,
                  iconColor: AppColors.warning,
                  iconBackground: AppColors.warningTint,
                ),
                StatisticsCard(
                  label: 'Published',
                  value: '$published',
                  icon: AppIcons.document,
                  iconColor: AppChartPalette.at(2),
                  iconBackground: AppChartPalette.at(2).withValues(alpha: 0.10),
                ),
                StatisticsCard(
                  label: 'Granted',
                  value: '$granted',
                  icon: AppIcons.award,
                  iconColor: AppColors.success,
                  iconBackground: AppColors.successTint,
                ),
              ],
            ),
            const SizedBox(height: 20),
            TableContainer(
              title: 'Patents & IPR',
              subtitle: 'Applications filed by the institution',
              child: CustomDataTable(
                emptyMessage: 'No patent applications on record.',
                columns: const [
                  DataColumnConfig(label: 'Title', size: ColumnSize.L),
                  DataColumnConfig(label: 'Lead Inventor', size: ColumnSize.M),
                  DataColumnConfig(label: 'Dept', size: ColumnSize.S),
                  DataColumnConfig(
                    label: 'Application No.',
                    size: ColumnSize.M,
                  ),
                  DataColumnConfig(label: 'Filed', size: ColumnSize.M),
                  DataColumnConfig(label: 'Granted', size: ColumnSize.M),
                  DataColumnConfig(label: 'Stage', size: ColumnSize.S),
                ],
                rows: [for (final patent in patents) _patentRow(patent)],
              ),
            ),
          ],
        );
      },
    );
  }

  DataRow2 _patentRow(Patent patent) {
    return DataRow2(
      cells: [
        DataCell(Text(patent.title, overflow: TextOverflow.ellipsis)),
        DataCell(Text(patent.leadInventor, overflow: TextOverflow.ellipsis)),
        DataCell(Text(patent.departmentCode)),
        DataCell(Text(patent.applicationNumber)),
        DataCell(Text(DateFormatter.shortDate(patent.filedOn))),
        DataCell(
          Text(
            patent.grantedOn == null
                ? '—'
                : DateFormatter.shortDate(patent.grantedOn!),
          ),
        ),
        DataCell(
          StatusChip(
            status: _statusFor(patent.stage),
            customLabel: patent.stage.label,
          ),
        ),
      ],
    );
  }
}
