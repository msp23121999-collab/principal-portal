import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../utils/responsive_utils.dart';
import './feedback/error_state.dart';
import './feedback/loading_skeleton.dart';
import '../models/department.dart';
import '../providers/institution_providers.dart';

/// One card per department: name, HOD, rank badge, and the four headline
/// metrics (faculty, students, attendance, placement).
class DepartmentCardGrid extends ConsumerWidget {
  const DepartmentCardGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final departmentsAsync = ref.watch(departmentsProvider);

    return departmentsAsync.when(
      loading: () => ResponsiveGrid(
        minTileWidth: 300,
        children: List.generate(7, (_) => const CardSkeleton(height: 190)),
      ),
      error: (err, st) => const ErrorState(),
      data: (departments) => ResponsiveGrid(
        minTileWidth: 300,
        children: [for (final d in departments) _DepartmentCard(department: d)],
      ),
    );
  }
}

class _DepartmentCard extends StatelessWidget {
  const _DepartmentCard({required this.department});

  final Department department;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      department.shortCode,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      department.name,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentGoldTint,
                  borderRadius: AppRadius.smRadius,
                ),
                child: Text(
                  'Rank #${department.rank}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF8A6D00),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'HOD: ${department.hodName}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _MetricColumn(
                  icon: AppIcons.faculty,
                  label: 'Faculty',
                  value: department.facultyCount.toString(),
                ),
              ),
              Expanded(
                child: _MetricColumn(
                  icon: AppIcons.students,
                  label: 'Students',
                  value: department.studentCount.toString(),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _MetricColumn(
                  icon: AppIcons.attendance,
                  label: 'Attendance',
                  value: '${department.attendancePercent.toStringAsFixed(1)}%',
                ),
              ),
              Expanded(
                child: _MetricColumn(
                  icon: AppIcons.placements,
                  label: 'Placement',
                  value: '${department.placementPercent.toStringAsFixed(1)}%',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricColumn extends StatelessWidget {
  const _MetricColumn({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.secondaryText),
        const SizedBox(width: AppSpacing.xs),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: Theme.of(context).textTheme.titleSmall),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ],
    );
  }
}
