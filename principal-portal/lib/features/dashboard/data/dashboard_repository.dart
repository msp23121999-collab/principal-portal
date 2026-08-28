import '../../../core/services/api_client.dart';
import '../../../core/services/repository.dart';
import '../../../core/theme/app_icons.dart';
import '../../institution/models/department.dart';
import '../models/dashboard_summary.dart';
import '../models/recent_activity.dart';

/// Assembles the Dashboard from `principal.v_dashboard_summary`.
///
/// The view counts the live student and faculty rolls and the current
/// approvals and placements every time it is read. Nothing on this screen is
/// stored — which is the point, because the Dashboard's whole job is to agree
/// with the pages it summarises. A stored total would start disagreeing the
/// first time a student was enrolled.
class DashboardRepository extends Repository {
  const DashboardRepository();

  Future<Sourced<DashboardSummary>> fetch({
    required List<Department> departments,
  }) {
    return load<DashboardSummary>(
      debugLabel: 'principal.v_dashboard_summary',
      fromSupabase: () async {
        // maybeSingle, not single: `single()` throws a raw PostgREST error
        // when the view returns no row, and the screen then shows the database
        // driver's own wording. The view always returns exactly one row, so
        // getting none means something is genuinely wrong — worth saying so in
        // words a Principal can act on.
        final results = await Future.wait([
          ApiClient.schema(
            DbSchema.principal,
          ).from('v_dashboard_summary').select().maybeSingle(),
          ApiClient.schema(DbSchema.principal)
              .from('v_attendance_daily')
              .select()
              .order('entry_date', ascending: false)
              .limit(6),
        ]);

        final summaryRow = results[0];
        if (summaryRow == null) {
          throw StateError(
            'principal.v_dashboard_summary returned no row. The view exists to '
            'return exactly one, so the institution totals cannot be read.',
          );
        }

        final summary = Map<String, dynamic>.from(summaryRow as Map);
        final trendRows = results[1] as List;

        return _toSummary(summary, trendRows, departments);
      },
    );
  }

  /// Recent activity, taken from the audit trail.
  ///
  /// The trail already records what happened in the portal, so this panel
  /// reads it rather than keeping a parallel list that could tell a different
  /// story about the same events.
  Future<Sourced<List<RecentActivity>>> fetchRecentActivity() {
    return load<List<RecentActivity>>(
      debugLabel: 'principal.audit_entries (recent)',
      isEmpty: (rows) => rows.isEmpty,
      fromSupabase: () async {
        final rows = await ApiClient.schema(DbSchema.principal)
            .from('audit_entries')
            .select()
            .order('occurred_at', ascending: false)
            .limit(6);

        return [
          for (final raw in rows) _toActivity(Map<String, dynamic>.from(raw)),
        ];
      },
    );
  }

  RecentActivity _toActivity(Map<String, dynamic> row) {
    final action = row.strOr('action', '');
    return RecentActivity(
      icon: switch (action) {
        'approved' => AppIcons.check,
        'rejected' => AppIcons.close,
        'published' => AppIcons.notifications,
        'exported' => AppIcons.download,
        'signed_in' => AppIcons.security,
        _ => AppIcons.info,
      },
      title: row.strOr('description', ''),
      subtitle: '${row.strOr('actor', 'Unknown')} · ${row.strOr('module', '')}',
      timestamp: row.dateOr('occurred_at', DateTime.now()),
    );
  }

  /// Placement percentage, or null when it cannot honestly be stated.
  ///
  /// Placement records and the student roll are populated by different teams
  /// and do not yet describe the same cohort. Where placements outnumber the
  /// roll the ratio is meaningless, so no figure is given rather than a capped
  /// one.
  static double? _placementPercent({
    required int placed,
    required int eligible,
  }) {
    if (eligible <= 0 || placed > eligible) return null;
    return placed / eligible * 100;
  }

  DashboardSummary _toSummary(
    Map<String, dynamic> row,
    List<dynamic> trendRows,
    List<Department> departments,
  ) {
    // The newest day that carries a figure, not simply the newest day.
    //
    // `v_attendance_daily` returns `overall_percent = null` for a date on which
    // no register was marked, and the two most recent dates are routinely
    // like that. Reading the newest row regardless turned a null into `0.0%`,
    // so the card announced that nobody attended while the Student Summary
    // beside it reported 86%. Null here means "no marked day on record", and
    // the card shows a dash.
    double? todayPercent;
    for (final raw in trendRows) {
      final entry = Map<String, dynamic>.from(raw as Map);
      if (entry['overall_percent'] == null) continue;
      todayPercent = entry.doubleOr('overall_percent', 0);
      break;
    }

    final ranked = [...departments]..sort((a, b) => a.rank.compareTo(b.rank));

    return DashboardSummary(
      institutionOverview: InstitutionOverview(
        totalStudents: row.intOr('total_students', 0),
        totalFaculty: row.intOr('total_faculty', 0),
        totalDepartments: row.intOr('total_departments', 0),
        // There is no historical snapshot to compare against, so no movement
        // can honestly be reported. Said plainly rather than shown as +0%,
        // which would read as "no change" instead of "not measured".
      ),
      departmentRows: [
        for (final d in ranked)
          DepartmentSummaryRow(
            name: d.name,
            shortCode: d.shortCode,
            studentCount: d.studentCount,
            attendancePercent: d.attendancePercent,
            rank: d.rank,
          ),
      ],
      facultySummary: FacultySummary(
        totalFaculty: row.intOr('total_faculty', 0),
        // Experience and research output live on faculty_details and the
        // Faculty Portal's tables; the Faculty screen reports them. The
        // dashboard shows the count it can vouch for rather than a figure
        // assembled from somewhere else.
        averageExperienceYears: 0,
        averageAttendancePercent: row.doubleOr('average_attendance_percent', 0),
        totalResearchPapers: 0,
      ),
      studentSummary: StudentSummary(
        totalStudents: row.intOr('total_students', 0),
        averageCgpa: row.doubleOr('average_cgpa', 0),
        averageAttendancePercent: row.doubleOr('average_attendance_percent', 0),
        topPerformerCount: row.intOr('top_performer_count', 0),
        atRiskCount: row.intOr('at_risk_count', 0),
      ),
      todayAttendancePercent: todayPercent,
      resultSummary: ResultSummary(
        semesterLabel: row.strOr('latest_semester_label', 'No results yet'),
        overallPassPercent: row.doubleOr('latest_pass_percent', 0),
        byDepartment: [
          for (final d in ranked)
            (departmentCode: d.shortCode, passPercent: d.passPercent),
        ],
      ),
      placementSummary: PlacementSummary(
        totalEligible: row.intOr('total_students', 0),
        totalPlaced: row.intOr('total_placed', 0),
        // Null unless the two figures describe the same population.
        //
        // There are 60 placement records against a roll of 15, which is 400%.
        // Clamping that to 100% made the card announce that every student was
        // placed — a stronger claim than the data supports, and the one a
        // Principal is most likely to repeat. The offer count is true either
        // way and is shown instead.
        placementPercent: _placementPercent(
          placed: row.intOr('total_placed', 0),
          eligible: row.intOr('total_students', 0),
        ),
        averagePackageLpa: row.doubleOr('average_package_lpa', 0),
        highestPackageLpa: row.doubleOr('highest_package_lpa', 0),
        // Requires ordering companies by hires — the Placement screen does
        // that properly. Not restated here from a different calculation.
        topRecruiter: '—',
      ),
    );
  }
}
