import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/widgets/cards/analytics_card.dart';
import '../../../../core/widgets/cards/statistics_card.dart';
import '../../../../core/widgets/charts/pie_chart_widget.dart';
import '../../../../core/widgets/data_display/custom_data_table.dart';
import '../../../../core/widgets/data_display/status_chip.dart';
import '../../../../core/widgets/data_display/table_container.dart';
import '../../../../core/widgets/feedback/error_state.dart';
import '../../../../core/widgets/feedback/loading_skeleton.dart';
import '../../../../core/widgets/layout/responsive_row.dart';
import '../../models/finance.dart';
import '../../providers/finance_providers.dart';

const List<Color> _sponsorColors = [
  AppColors.primaryBlue,
  AppColors.success,
  AppColors.accentGold,
  AppColors.darkBlue,
];

/// Scholarship and fee-waiver schemes, and how much each has paid out.
class ScholarshipsTab extends ConsumerWidget {
  const ScholarshipsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schemesAsync = ref.watch(scholarshipsProvider);

    return schemesAsync.when(
      loading: () => const CardSkeleton(height: 460),
      error: (err, st) => const ErrorState(),
      data: (schemes) {
        final sanctioned = schemes.fold(0.0, (sum, s) => sum + s.sanctioned);
        final disbursed = schemes.fold(0.0, (sum, s) => sum + s.disbursed);
        final beneficiaries = schemes.fold(
          0,
          (sum, s) => sum + s.beneficiaries,
        );

        // Group by sponsor so the donut shows who is actually funding this.
        final bySponsor = <String, double>{};
        for (final scheme in schemes) {
          bySponsor.update(
            scheme.sponsor,
            (value) => value + scheme.disbursed,
            ifAbsent: () => scheme.disbursed,
          );
        }
        final sponsors = bySponsor.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ResponsiveGrid(
              children: [
                StatisticsCard(
                  label: 'Schemes Running',
                  value: '${schemes.length}',
                  icon: AppIcons.award,
                  iconColor: const Color(0xFF2563EB),
                  iconBackground: const Color(0xFFEFF6FF),
                ),
                StatisticsCard(
                  label: 'Beneficiaries',
                  value: '$beneficiaries',
                  icon: AppIcons.students,
                  iconColor: const Color(0xFF059669),
                  iconBackground: const Color(0xFFECFDF5),
                ),
                StatisticsCard(
                  label: 'Amount Sanctioned',
                  value: NumberFormatter.rupees(sanctioned),
                  icon: AppIcons.currency,
                  iconColor: const Color(0xFF7C3AED),
                  iconBackground: const Color(0xFFF5F3FF),
                ),
                StatisticsCard(
                  label: 'Amount Disbursed',
                  value: NumberFormatter.rupees(disbursed),
                  icon: AppIcons.check,
                  iconColor: const Color(0xFF0891B2),
                  iconBackground: const Color(0xFFECFEFF),
                  subtitle: sanctioned == 0
                      ? null
                      : '${(disbursed / sanctioned * 100).toStringAsFixed(1)}% released',
                ),
              ],
            ),
            const SizedBox(height: 24),
            ResponsiveRow(
              columns: [
                ResponsiveColumn(
                  flex: 67,
                  child: TableContainer(
                    title: 'Scholarship Schemes',
                    subtitle: 'Sanctioned against disbursed, by scheme',
                    child: CustomDataTable(
                      emptyMessage: 'No scholarship schemes are running.',
                      columns: const [
                        DataColumnConfig(label: 'Scheme', size: ColumnSize.L),
                        DataColumnConfig(label: 'Sponsor', size: ColumnSize.M),
                        DataColumnConfig(label: 'Beneficiaries', numeric: true),
                        DataColumnConfig(label: 'Sanctioned', numeric: true),
                        DataColumnConfig(label: 'Disbursed', numeric: true),
                        DataColumnConfig(label: 'Pending', numeric: true),
                        DataColumnConfig(label: 'Status', size: ColumnSize.S),
                      ],
                      rows: [for (final scheme in schemes) _schemeRow(scheme)],
                    ),
                  ),
                ),
                ResponsiveColumn(
                  flex: 33,
                  child: AnalyticsCard(
                    title: 'Disbursement by Sponsor',
                    subtitle: NumberFormatter.rupees(disbursed),
                    child: SizedBox(
                      height: 260,
                      child: PieChartWidget(
                        centerLabel: '${sponsors.length}',
                        data: [
                          for (int i = 0; i < sponsors.length; i++)
                            PieChartDatum(
                              label: sponsors[i].key,
                              value: sponsors[i].value,
                              color: _sponsorColors[i % _sponsorColors.length],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  DataRow2 _schemeRow(ScholarshipScheme scheme) {
    final fullyReleased = scheme.pending <= 0;

    return DataRow2(
      cells: [
        DataCell(Text(scheme.name, overflow: TextOverflow.ellipsis)),
        DataCell(Text(scheme.sponsor, overflow: TextOverflow.ellipsis)),
        DataCell(Text('${scheme.beneficiaries}')),
        DataCell(Text(NumberFormatter.rupees(scheme.sanctioned))),
        DataCell(Text(NumberFormatter.rupees(scheme.disbursed))),
        DataCell(
          Text(
            fullyReleased ? '—' : NumberFormatter.rupees(scheme.pending),
            style: TextStyle(
              color: fullyReleased ? AppColors.primaryText : AppColors.warning,
              fontWeight: fullyReleased ? FontWeight.normal : FontWeight.w600,
            ),
          ),
        ),
        DataCell(
          StatusChip(
            status: fullyReleased ? AppStatus.approved : AppStatus.pending,
            customLabel: fullyReleased ? 'Released' : 'Pending',
          ),
        ),
      ],
    );
  }
}
