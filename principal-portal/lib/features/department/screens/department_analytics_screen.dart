import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/filters/portal_filter_bar.dart';
import '../../../core/services/table_export.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/layout/content_scaffold.dart';
import '../../../core/widgets/layout/page_header.dart';
import '../providers/department_providers.dart';
import '../widgets/department_attention_required.dart';
import '../widgets/department_comparison_matrix.dart';
import '../widgets/department_health_section.dart';
import '../widgets/department_ranking_trend.dart';

/// Department Performance — comparative academic results, performance trends,
/// and highlights of areas requiring attention.
class DepartmentAnalyticsScreen extends ConsumerWidget {
  const DepartmentAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ContentScaffold(
      children: [
        PageHeader(
          title: 'Department Performance',
          breadcrumbSegments: const ['Analytics', 'Department'],
          subtitle:
              'Compare department performance, identify trends, and highlight areas requiring attention.',
          actions: const [],
        ),
        PortalFilterBar(
          show: const [
            PortalFilterKind.academicYear,
            PortalFilterKind.department,
            PortalFilterKind.program,
            PortalFilterKind.batch,
            PortalFilterKind.semester,
          ],
          trailingActions: [
            Consumer(
              builder: (context, ref, child) {
                return PrimaryButton(
                  label: 'Generate Report',
                  icon: AppIcons.download,
                  onPressed: () => _export(context, ref),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        const DepartmentHealthSection(),
        const DepartmentRankingTrend(),
        const SizedBox(height: AppSpacing.lg),
        const DepartmentComparisonMatrix(),
        const DepartmentAttentionRequired(),
      ],
    );
  }

  void _export(BuildContext context, WidgetRef ref) {
    final insights =
        ref.read(departmentInsightsProvider).valueOrNull ?? const [];

    TableExport.run(
      context,
      fileName: 'department_performance_matrix',
      noun: 'department',
      headers: const [
        'Department Code',
        'Department Name',
        'Rank',
        'Status',
        'Filtered CGPA',
        'Filtered Attendance',
        'Overall Placement',
      ],
      rows: [
        for (final d in insights)
          [
            d.departmentCode,
            d.departmentName,
            d.rank,
            d.status,
            d.cgpa.toStringAsFixed(2),
            '${d.attendance.toStringAsFixed(1)}%',
            '${d.placement.toStringAsFixed(1)}%',
          ],
      ],
    );
  }
}
