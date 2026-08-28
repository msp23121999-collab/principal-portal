import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_chart_palette.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/widgets/cards/statistics_card.dart';
import '../../../../core/widgets/data_display/custom_data_table.dart';
import '../../../../core/widgets/data_display/status_chip.dart';
import '../../../../core/widgets/data_display/table_container.dart';
import '../../../../core/widgets/feedback/error_state.dart';
import '../../../../core/widgets/feedback/loading_skeleton.dart';
import '../../models/research.dart';
import '../../providers/research_providers.dart';

AppStatus _statusFor(ProjectStage stage) {
  switch (stage) {
    case ProjectStage.sanctioned:
      return AppStatus.info;
    case ProjectStage.ongoing:
      return AppStatus.pending;
    case ProjectStage.completed:
      return AppStatus.approved;
  }
}

/// Externally funded research alongside paid consultancy work.
class ProjectsConsultancyTab extends ConsumerWidget {
  const ProjectsConsultancyTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(fundedProjectsProvider);
    final consultancyAsync = ref.watch(consultancyProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        projectsAsync.when(
          loading: () => const CardSkeleton(height: 420),
          error: (err, st) => const ErrorState(),
          data: (projects) {
            final funding = projects.fold(
              0.0,
              (sum, p) => sum + p.sanctionedAmount,
            );
            final ongoing = projects
                .where((p) => p.stage == ProjectStage.ongoing)
                .length;
            final agencies = projects.map((p) => p.agency).toSet().length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ResponsiveGrid(
                  children: [
                    StatisticsCard(
                      label: 'Funded Projects',
                      value: '${projects.length}',
                      icon: AppIcons.academic,
                      iconColor: AppChartPalette.at(0),
                      iconBackground: AppChartPalette.at(
                        0,
                      ).withValues(alpha: 0.10),
                    ),
                    StatisticsCard(
                      label: 'Currently Running',
                      value: '$ongoing',
                      icon: AppIcons.clock,
                      iconColor: AppColors.warning,
                      iconBackground: AppColors.warningTint,
                    ),
                    StatisticsCard(
                      label: 'Total Sanctioned',
                      value: NumberFormatter.rupees(funding),
                      icon: AppIcons.currency,
                      iconColor: AppColors.success,
                      iconBackground: AppColors.successTint,
                    ),
                    StatisticsCard(
                      label: 'Funding Agencies',
                      value: '$agencies',
                      icon: AppIcons.institution,
                      iconColor: AppChartPalette.at(3),
                      iconBackground: AppChartPalette.at(
                        3,
                      ).withValues(alpha: 0.10),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TableContainer(
                  title: 'Funded Research Projects',
                  subtitle: 'Sanctioned grants and their current stage',
                  child: CustomDataTable(
                    emptyMessage: 'No funded projects on record.',
                    columns: const [
                      DataColumnConfig(label: 'Project', size: ColumnSize.L),
                      DataColumnConfig(
                        label: 'Investigator',
                        size: ColumnSize.M,
                      ),
                      DataColumnConfig(label: 'Dept', size: ColumnSize.S),
                      DataColumnConfig(label: 'Agency', size: ColumnSize.L),
                      DataColumnConfig(label: 'Sanctioned', numeric: true),
                      DataColumnConfig(label: 'Duration', size: ColumnSize.S),
                      DataColumnConfig(label: 'From', size: ColumnSize.M),
                      DataColumnConfig(label: 'Stage', size: ColumnSize.S),
                    ],
                    rows: [
                      for (final project in projects) _projectRow(project),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        consultancyAsync.when(
          loading: () => const CardSkeleton(height: 340),
          error: (err, st) => const ErrorState(),
          data: (engagements) {
            final revenue = engagements.fold(0.0, (sum, c) => sum + c.revenue);

            return TableContainer(
              title: 'Consultancy Engagements',
              subtitle:
                  '${engagements.length} engagements, '
                  '${NumberFormatter.rupees(revenue)} in revenue',
              child: CustomDataTable(
                emptyMessage: 'No consultancy engagements recorded.',
                columns: const [
                  DataColumnConfig(label: 'Engagement', size: ColumnSize.L),
                  DataColumnConfig(label: 'Client', size: ColumnSize.L),
                  DataColumnConfig(label: 'Dept', size: ColumnSize.S),
                  DataColumnConfig(label: 'Lead Faculty', size: ColumnSize.M),
                  DataColumnConfig(label: 'Revenue', numeric: true),
                  DataColumnConfig(label: 'Stage', size: ColumnSize.S),
                ],
                rows: [
                  for (final engagement in engagements)
                    _consultancyRow(engagement),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  DataRow2 _projectRow(FundedProject project) {
    return DataRow2(
      cells: [
        DataCell(Text(project.title, overflow: TextOverflow.ellipsis)),
        DataCell(
          Text(project.principalInvestigator, overflow: TextOverflow.ellipsis),
        ),
        DataCell(Text(project.departmentCode)),
        DataCell(Text(project.agency, overflow: TextOverflow.ellipsis)),
        DataCell(Text(NumberFormatter.rupees(project.sanctionedAmount))),
        DataCell(Text('${project.durationMonths} mo')),
        DataCell(Text(DateFormatter.shortDate(project.sanctionedOn))),
        DataCell(
          StatusChip(
            status: _statusFor(project.stage),
            customLabel: project.stage.label,
          ),
        ),
      ],
    );
  }

  DataRow2 _consultancyRow(ConsultancyProject engagement) {
    return DataRow2(
      cells: [
        DataCell(Text(engagement.title, overflow: TextOverflow.ellipsis)),
        DataCell(Text(engagement.client, overflow: TextOverflow.ellipsis)),
        DataCell(Text(engagement.departmentCode)),
        DataCell(Text(engagement.leadFaculty, overflow: TextOverflow.ellipsis)),
        DataCell(Text(NumberFormatter.rupees(engagement.revenue))),
        DataCell(
          StatusChip(
            status: _statusFor(engagement.stage),
            customLabel: engagement.stage.label,
          ),
        ),
      ],
    );
  }
}
