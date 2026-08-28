/// Institution-wide headline figures shown in the Dashboard's top KPI row.
class InstitutionOverview {
  const InstitutionOverview({
    required this.totalStudents,
    required this.totalFaculty,
    required this.totalDepartments,
    required this.studentGrowthPercent,
    required this.facultyGrowthPercent,
  });

  final int totalStudents;
  final int totalFaculty;
  final int totalDepartments;
  final String studentGrowthPercent;
  final String facultyGrowthPercent;
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

/// Today's institution-wide attendance snapshot plus a short trailing trend
/// used to draw the Dashboard's attendance bar chart.
class AttendanceSnapshot {
  const AttendanceSnapshot({
    required this.todayPercent,
    required this.weekTrend,
  });

  final double todayPercent;

  /// Last 7 days, oldest first: (label, percent).
  final List<({String label, double percent})> weekTrend;
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
  final double placementPercent;
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
    required this.attendanceSnapshot,
    required this.resultSummary,
    required this.placementSummary,
  });

  final InstitutionOverview institutionOverview;
  final List<DepartmentSummaryRow> departmentRows;
  final FacultySummary facultySummary;
  final StudentSummary studentSummary;
  final AttendanceSnapshot attendanceSnapshot;
  final ResultSummary resultSummary;
  final PlacementSummary placementSummary;
}
