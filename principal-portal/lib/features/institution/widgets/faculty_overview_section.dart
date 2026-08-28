import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/cards/analytics_card.dart';
import '../../../core/widgets/cards/info_tile.dart';
import '../../../core/widgets/charts/horizontal_bar_chart_widget.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_skeleton.dart';
import '../providers/institution_providers.dart';

/// Institution-level Faculty Overview — headline metrics (total, composition
/// by employment status) and a department-wise faculty-availability bar chart.
///
/// All data is derived from existing providers:
/// * [institutionLiveKpisProvider] for the total faculty count.
/// * [facultyCompositionProvider] for employment-type breakdown.
/// * [departmentsProvider] for per-department faculty counts.
class FacultyOverviewSection extends ConsumerWidget {
  const FacultyOverviewSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final figuresAsync = ref.watch(institutionLiveKpisProvider);
    final compositionAsync = ref.watch(facultyCompositionProvider);
    final departmentsAsync = ref.watch(departmentsProvider);

    // Wait for all three — any one failing blanks the section.
    if (figuresAsync is AsyncError ||
        compositionAsync is AsyncError ||
        departmentsAsync is AsyncError) {
      return const ErrorState();
    }
    if (figuresAsync is AsyncLoading ||
        compositionAsync is AsyncLoading ||
        departmentsAsync is AsyncLoading) {
      return const CardSkeleton(height: 360);
    }

    final figures = figuresAsync.value!;
    final composition = compositionAsync.value!;
    final departments = departmentsAsync.value!;

    // Sorted descending by faculty count for the bar chart.
    final withFaculty = departments.where((d) => d.facultyCount > 0).toList()
      ..sort((a, b) => b.facultyCount.compareTo(a.facultyCount));

    // Bar chart height scales with number of departments.
    final barHeight = (withFaculty.length * 34.0 + 24).clamp(140.0, 400.0);

    return AnalyticsCard(
      title: 'Faculty Overview',
      subtitle: 'Institution-wide teaching staff summary',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Metric row ---
          Row(
            children: [
              Expanded(
                child: InfoTile(
                  label: 'Total Faculty',
                  value: figures.totalFaculty.toString(),
                  icon: AppIcons.faculty,
                ),
              ),
              for (final slice in composition.take(3))
                Expanded(
                  child: InfoTile(
                    label: slice.label,
                    value: slice.count.toString(),
                    icon: _iconForSlice(slice.label),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // --- Faculty by department bar chart ---
          if (withFaculty.isNotEmpty) ...[
            Text(
              'Faculty Availability by Department',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Departments with faculty on the roll '
              '(${withFaculty.length} of ${departments.length})',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: barHeight,
              child: HorizontalBarChartWidget(
                data: [
                  for (final d in withFaculty)
                    HorizontalBarDatum(
                      label: d.shortCode,
                      value: d.facultyCount.toDouble(),
                      color: AppColors.primaryBlue,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Pick a contextual icon for the employment-type slice.
  static IconData _iconForSlice(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('permanent') || lower.contains('regular')) {
      return AppIcons.check;
    }
    if (lower.contains('contract')) return AppIcons.calendar;
    if (lower.contains('visiting') || lower.contains('guest')) {
      return AppIcons.faculty;
    }
    return AppIcons.info;
  }
}
