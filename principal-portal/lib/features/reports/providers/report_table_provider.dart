import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_formatter.dart';
import '../../academic/providers/academic_providers.dart';
import '../../approvals/models/approval_request.dart';
import '../../approvals/providers/approvals_providers.dart';
import '../../attendance/providers/attendance_providers.dart';
import '../../audit/models/audit.dart';
import '../../audit/providers/audit_providers.dart';
import '../../faculty/models/faculty.dart';
import '../../faculty/providers/faculty_providers.dart';
import '../../finance/providers/finance_providers.dart';
import '../../placements/providers/placement_providers.dart';
import 'reports_providers.dart';

/// A report's contents: the header row and the rows beneath it.
typedef ReportTable = ({List<String> headers, List<List<Object?>> rows});

/// Builds the table behind a report request.
///
/// Reports used to record that a report had been asked for and produce
/// nothing, while the screen showed a file size, a "Ready" status and a
/// download button for a file that did not exist. This turns the request into
/// an actual CSV, drawn from the same providers the corresponding screen reads
/// — so a report and the screen it names can never disagree.
///
/// Every module maps to the table a Principal would expect from that screen.
/// Filters currently in force are honoured, for the same reason the per-screen
/// exports honour them: a report of the whole institution when the Principal is
/// looking at one department is not the report they asked for.
ReportTable buildReportTable(WidgetRef ref, String module) {
  switch (module) {
    case 'academic':
      final summaries =
          ref.read(semesterSummariesProvider).valueOrNull ?? const [];
      return (
        headers: const [
          'Semester',
          'Appeared',
          'Passed',
          'Pass %',
          'Average SGPA',
          'Average CGPA',
          'Backlogs',
          'Top Performer',
          'Top Performer CGPA',
        ],
        rows: [
          for (final s in summaries)
            [
              s.semester,
              s.appeared,
              s.passed,
              s.passPercent.toStringAsFixed(2),
              s.averageSgpa,
              s.averageCgpa,
              s.backlogs,
              s.topPerformer,
              s.topPerformerCgpa,
            ],
        ],
      );

    case 'attendance':
      final byYear = ref.read(attendanceByYearProvider).valueOrNull ?? const [];
      return (
        headers: const ['Year of Study', 'Students', 'Average Attendance %'],
        rows: [
          for (final row in byYear)
            [row.year, row.students, row.average.toStringAsFixed(2)],
        ],
      );

    case 'faculty':
      final roster = ref.read(facultyListProvider).valueOrNull ?? const [];
      final details = ref.read(facultyDetailsProvider);
      return (
        headers: const [
          'Employee ID',
          'Name',
          'Designation',
          'Department',
          'Experience (years)',
          'Attendance %',
          'Research Output',
          'Weekly Hours',
          'Qualification',
        ],
        rows: [
          for (final f in roster)
            [
              f.id,
              f.name,
              f.designation.label,
              f.departmentId,
              f.experienceYears,
              f.attendancePercent,
              f.researchPapersCount,
              // Blank where unrecorded — never a stand-in number.
              details[f.id]?.weeklyTeachingHours ?? '',
              details[f.id]?.qualification ?? '',
            ],
        ],
      );

    case 'placement':
      final offers =
          ref.read(filteredPlacementsProvider).valueOrNull ?? const [];
      return (
        headers: const [
          'Student',
          'Roll Number',
          'Department',
          'Company',
          'Package (LPA)',
          'Offer Date',
        ],
        rows: [
          for (final o in offers)
            [
              o.studentName,
              o.rollNumber,
              o.departmentId,
              o.companyName,
              o.packageLpa,
              DateFormatter.shortDate(o.offerDate),
            ],
        ],
      );

    case 'finance':
      final fees = ref.read(departmentFeesProvider).valueOrNull ?? const [];
      return (
        headers: const [
          'Department',
          'Department Name',
          'Students',
          'Students Paid',
          'Demand',
          'Collected',
          'Outstanding',
          'Collection %',
        ],
        rows: [
          for (final f in fees)
            [
              f.departmentCode,
              f.departmentName,
              f.studentsTotal,
              f.studentsPaid,
              f.demand,
              f.collected,
              f.outstanding,
              f.collectionPercent.toStringAsFixed(2),
            ],
        ],
      );

    case 'approvals':
      final requests =
          ref.read(approvalRequestsProvider).valueOrNull ?? const [];
      return (
        headers: const [
          'Request ID',
          'Title',
          'Category',
          'Requester',
          'Department',
          'Submitted',
          'Priority',
          'Amount',
          'Decision',
        ],
        rows: [
          for (final r in requests)
            [
              r.id,
              r.title,
              r.category.label,
              r.requesterName,
              r.departmentCode,
              DateFormatter.shortDate(r.submittedAt),
              r.priority.label,
              // Only budget and purchase requests carry an amount.
              r.amount ?? '',
              r.decision.label,
            ],
        ],
      );

    default:
      final entries = ref.read(auditEntriesProvider).valueOrNull ?? const [];
      return (
        headers: const [
          'Timestamp',
          'Actor',
          'Role',
          'Action',
          'Module',
          'Detail',
          'IP Address',
          'Severity',
        ],
        rows: [
          for (final e in entries)
            [
              '${DateFormatter.shortDate(e.timestamp)} ${DateFormatter.time(e.timestamp)}',
              e.actor,
              e.actorRole,
              e.action.label,
              e.module,
              e.description,
              e.ipAddress,
              e.severity.label,
            ],
        ],
      );
  }
}

/// A file name for a module's report, e.g. `report_placement`.
String reportFileName(String module) => 'report_$module';

/// Kept so a caller cannot pass a module the switch above does not handle.
bool isKnownReportModule(String module) => reportModules.contains(module);
