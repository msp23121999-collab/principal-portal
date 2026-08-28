import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/filters/portal_filter_bar.dart';
import '../../../core/services/table_export.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/layout/active_tab.dart';
import '../../../core/widgets/layout/tabbed_page.dart';
import '../models/examination.dart';
import '../providers/examination_providers.dart';
import '../widgets/tabs/cia_progress_tab.dart';
import '../widgets/tabs/exam_schedule_tab.dart';
import '../widgets/tabs/hall_tickets_tab.dart';
import '../widgets/tabs/result_publication_tab.dart';

/// Examination Monitoring — internal assessments, the end-semester
/// timetable, hall-ticket issue, and result publication.
class ExaminationMonitoringScreen extends ConsumerWidget {
  const ExaminationMonitoringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TabbedPage(
      title: 'Examination Monitoring',
      breadcrumbSegments: const ['Academics', 'Examination Monitoring'],
      subtitle:
          'Internal assessments, examination schedule, hall tickets, and '
          'result publication status.',
      filterBar: PortalFilterBar(
        show: const [PortalFilterKind.department, PortalFilterKind.semester],
        trailingActions: [
          PrimaryButton(
            // Was 'Export Schedule', which was only true on one of the four
            // tabs. It exports whichever table is in view.
            label: 'Export Report', // Updated to standardize text as well
            icon: AppIcons.download,
            onPressed: () => _export(context, ref),
          ),
        ],
      ),
      onTabChanged: (index) =>
          ref
                  .read(activeTabProvider(TabbedPageKeys.examinations).notifier)
                  .state =
              index,
      tabs: const [
        PageTab(label: 'Schedule', content: ExamScheduleTab()),
        PageTab(label: 'Internal Assessments', content: CiaProgressTab()),
        PageTab(label: 'Hall Tickets', content: HallTicketsTab()),
        PageTab(label: 'Results', content: ResultPublicationTab()),
      ],
    );
  }

  /// Exports the table on the visible tab, honouring the department and
  /// semester filters in the header.
  void _export(BuildContext context, WidgetRef ref) {
    switch (ref.read(activeTabProvider(TabbedPageKeys.examinations))) {
      case 0:
        // The filtered schedule — the tab also carries its own stage filter.
        final papers = ref.read(examScheduleProvider).valueOrNull ?? const [];
        TableExport.run(
          context,
          fileName: 'examination_schedule',
          noun: 'paper',
          headers: const [
            'Date',
            'Session',
            'Code',
            'Subject',
            'Department',
            'Semester',
            'Duration (min)',
            'Hall',
            'Candidates',
            'Stage',
          ],
          rows: [
            for (final p in papers)
              [
                DateFormatter.shortDate(p.date),
                p.session,
                p.subjectCode,
                p.subjectName,
                p.departmentCode,
                p.semester,
                p.durationMinutes,
                p.hall,
                p.candidates,
                p.stage.label,
              ],
          ],
        );

      case 1:
        final progress = ref.read(ciaProgressProvider).valueOrNull ?? const [];
        TableExport.run(
          context,
          fileName: 'cia_progress',
          noun: 'department',
          headers: const [
            'Department',
            'Department Name',
            'CIA 1 %',
            'CIA 2 %',
            'CIA 3 %',
            'Average %',
            'Marks Entered',
            'Marks Expected',
            'Entry %',
          ],
          rows: [
            for (final c in progress)
              [
                c.departmentCode,
                c.departmentName,
                c.cia1Percent,
                c.cia2Percent,
                c.cia3Percent,
                c.averagePercent.toStringAsFixed(1),
                c.marksEntered,
                c.marksExpected,
                c.entryPercent.toStringAsFixed(1),
              ],
          ],
        );

      case 2:
        final tickets =
            ref.read(hallTicketStatusProvider).valueOrNull ?? const [];
        TableExport.run(
          context,
          fileName: 'hall_ticket_status',
          noun: 'department',
          headers: const [
            'Department',
            'Department Name',
            'Eligible',
            'Issued',
            'Pending',
            'Withheld',
            'Issued %',
          ],
          rows: [
            for (final t in tickets)
              [
                t.departmentCode,
                t.departmentName,
                t.eligible,
                t.issued,
                t.pending,
                t.withheld,
                t.issuedPercent.toStringAsFixed(1),
              ],
          ],
        );

      default:
        final publications =
            ref.read(resultPublicationProvider).valueOrNull ?? const [];
        TableExport.run(
          context,
          fileName: 'result_publication_status',
          noun: 'semester',
          headers: const [
            'Semester',
            'Exam Ended',
            'Papers',
            'Evaluated',
            'Evaluation %',
            'Published On',
            'Stage',
          ],
          rows: [
            for (final p in publications)
              [
                p.semester,
                DateFormatter.shortDate(p.examEndedOn),
                p.papersTotal,
                p.papersEvaluated,
                p.evaluationPercent.toStringAsFixed(1),
                // Blank while unpublished, never a placeholder date.
                p.publishedOn == null
                    ? ''
                    : DateFormatter.shortDate(p.publishedOn!),
                p.stage.label,
              ],
          ],
        );
    }
  }
}
