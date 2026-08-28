/// Institution-wide headline figures shown in the Dashboard's top KPI row.
class InstitutionOverview {
  const InstitutionOverview({
    required this.totalStudents,
    required this.totalFaculty,
    required this.totalDepartments,
  });

  final int totalStudents;
  final int totalFaculty;
  final int totalDepartments;
}

/// A single department row inside the Dashboard's department-summary card.
class DepartmentSummaryRow {
  const DepartmentSummaryRow({
    required this.name,
    required this.shortCode,
    required this.studentCount,
    required this.attendancePercent,
    required this.rank,
  });

  final String name;
  final String shortCode;
  final int studentCount;
  final double attendancePercent;
  final int rank;
}

/// Faculty aggregate stats for the Dashboard's faculty-summary card.
class FacultySummary {
  const FacultySummary({
    required this.totalFaculty,
    required this.averageExperienceYears,
    required this.averageAttendancePercent,
    required this.totalResearchPapers,
  });

  final int totalFaculty;
  final double averageExperienceYears;
  final double averageAttendancePercent;
  final int totalResearchPapers;
}

/// Student aggregate stats for the Dashboard's student-summary card.
class StudentSummary {
  const StudentSummary({
    required this.totalStudents,
    required this.averageCgpa,
    required this.averageAttendancePercent,
    required this.topPerformerCount,
    required this.atRiskCount,
  });

  final int totalStudents;
  final double averageCgpa;
  final double averageAttendancePercent;
  final int topPerformerCount;
  final int atRiskCount;
}

/// Most recent semester's pass-percentage summary, department-broken-down
/// for the Dashboard's result bar chart.
class ResultSummary {
  const ResultSummary({
    required this.semesterLabel,
    required this.overallPassPercent,
    required this.byDepartment,
  });

  final String semesterLabel;
  final double overallPassPercent;

  /// (departmentShortCode, passPercent).
  final List<({String departmentCode, double passPercent})> byDepartment;
}

/// Placement aggregate stats for the Dashboard's placement-summary card.
class PlacementSummary {
  const PlacementSummary({
    required this.totalEligible,
    required this.totalPlaced,
    required this.placementPercent,
    required this.averagePackageLpa,
    required this.highestPackageLpa,
    required this.topRecruiter,
  });

  final int totalEligible;
  final int totalPlaced;

  /// Null when placements and the roll do not describe the same population —
  /// 60 offers against 15 students has no meaningful percentage, and capping
  /// it to 100% claimed that every student was placed.
  final double? placementPercent;
  final double averagePackageLpa;
  final double highestPackageLpa;
  final String topRecruiter;
}

/// Aggregate bundle returned by dashboardSummaryProvider — one round-trip
/// "fetch" standing in for what would eventually be several API calls.
class DashboardSummary {
  const DashboardSummary({
    required this.institutionOverview,
    required this.departmentRows,
    required this.facultySummary,
    required this.studentSummary,
    required this.todayAttendancePercent,
    required this.resultSummary,
    required this.placementSummary,
  });

  final InstitutionOverview institutionOverview;
  final List<DepartmentSummaryRow> departmentRows;
  final FacultySummary facultySummary;
  final StudentSummary studentSummary;

  /// The most recent day on the register that actually carries a figure.
  ///
  /// Null when no day does. The Dashboard used to read the newest row
  /// unconditionally and print `0.0%` for it — but `v_attendance_daily`
  /// returns a null percentage for a date nobody marked, and "0% attended" is
  /// a claim where "not marked yet" is the truth.
  ///
  /// The week-long trend that fed the Attendance Snapshot chart is gone with
  /// it: the dashboard already reports attendance three times (this card,
  /// Student Summary, Faculty Status), and the trend belongs on Attendance
  /// Analytics.
  final double? todayAttendancePercent;

  final ResultSummary resultSummary;
  final PlacementSummary placementSummary;
}
