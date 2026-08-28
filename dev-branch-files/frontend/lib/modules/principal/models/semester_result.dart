/// Pass-percentage results for one semester, department-broken-down.
class SemesterResult {
  const SemesterResult({
    required this.semesterLabel,
    required this.overallPassPercent,
    required this.byDepartment,
  });

  final String semesterLabel;
  final double overallPassPercent;

  /// (departmentCode, passPercent).
  final List<({String departmentCode, double passPercent})> byDepartment;
}

/// A single rank-holder entry for a given semester.
class RankHolder {
  const RankHolder({
    required this.rank,
    required this.studentName,
    required this.rollNumber,
    required this.departmentId,
    required this.cgpa,
  });

  final int rank;
  final String studentName;
  final String rollNumber;
  final String departmentId;
  final double cgpa;
}
