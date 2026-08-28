import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/data_display/custom_data_table.dart';
import '../../../../core/widgets/data_display/table_container.dart';
import '../../../../core/widgets/feedback/error_state.dart';
import '../../../../core/widgets/feedback/loading_skeleton.dart';
import '../../models/meeting.dart';
import '../../providers/meetings_providers.dart';
import '../month_calendar.dart';

/// The published academic calendar for the year, in date order.
class AcademicCalendarTab extends ConsumerWidget {
  const AcademicCalendarTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(calendarEntriesProvider)
        .when(
          loading: () => const CardSkeleton(height: 320),
          error: (err, st) => const ErrorState(),
          data: (entries) => _buildTable(context, entries),
        );
  }

  Widget _buildTable(
    BuildContext context,
    List<AcademicCalendarEntry> entries,
  ) {
    return TableContainer(
      // The year was written into the title as '2025-26' regardless of what
      // `public.academic_calendar_events` actually held. The period is read
      // from the entries instead — and deliberately as a month range rather
      // than an academic-year label, because nothing in the data says where a
      // KSRCE academic year starts and ends.
      title: 'Academic Calendar',
      subtitle: _periodOf(entries),
      child: CustomDataTable(
        emptyMessage: 'The academic calendar has not been published yet.',
        columns: const [
          DataColumnConfig(label: 'Entry', size: ColumnSize.L),
          DataColumnConfig(label: 'Type', size: ColumnSize.M),
          DataColumnConfig(label: 'From', size: ColumnSize.M),
          DataColumnConfig(label: 'To', size: ColumnSize.M),
          DataColumnConfig(label: 'Days', numeric: true),
          DataColumnConfig(label: 'Detail', size: ColumnSize.L),
        ],
        rows: [for (final entry in entries) _entryRow(context, entry)],
      ),
    );
  }

  DataRow2 _entryRow(BuildContext context, AcademicCalendarEntry entry) {
    final category = getCategoryForEntry(
      title: entry.title,
      type: entry.type,
      description: entry.description,
    );
    final accent = colorForCategory(category);
    final softBg = softColorForCategory(category);
    final categoryLabel = labelForCategory(category);
    final isTestSystem = category == CalendarCategory.testSystem;

    // Highlights whatever is running today.
    final isCurrent = entry.coversDay(DateTime.now());

    return DataRow2(
      cells: [
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  entry.title,
                  overflow: TextOverflow.ellipsis,
                  style: isTestSystem
                      ? Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w400,
                          )
                      : isCurrent
                          ? Theme.of(context).textTheme.titleSmall
                          : Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: softBg,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: accent.withValues(alpha: 0.2)),
            ),
            child: Text(
              categoryLabel,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ),
        DataCell(Text(DateFormatter.shortDate(entry.from))),
        DataCell(Text(DateFormatter.shortDate(entry.to))),
        DataCell(Text('${entry.dayCount}')),
        DataCell(Text(
          entry.description,
          overflow: TextOverflow.ellipsis,
          style: isTestSystem
              ? Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF94A3B8),
                  )
              : null,
        )),
      ],
    );
  }

  /// How many entries are published, and the period they cover.
  String _periodOf(List<AcademicCalendarEntry> entries) {
    final count = '${entries.length} published entries';
    // Both ends: an entry running into the next month should widen the range.
    final period = DateFormatter.monthRange([
      for (final e in entries) ...[e.from, e.to],
    ]);
    return period == null ? count : '$count · $period';
  }
}
