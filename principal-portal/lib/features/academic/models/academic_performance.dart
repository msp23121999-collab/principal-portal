/// A headline academic figure with its year-over-year movement.
class AcademicKpi {
  const AcademicKpi({
    required this.label,
    required this.value,
    required this.trend,
    required this.isPositive,
  });

  final String label;
  final String value;
  final String trend;
  final bool isPositive;
}

/// Pass rate for one department across the selected year and the year it
/// is being compared against.
class DepartmentPassRate {
  const DepartmentPassRate({
    required this.department,
    required this.currentPercent,
    required this.previousPercent,
  });

  final String department;
  final double currentPercent;
  final double previousPercent;
}

/// Department pass rates plus the two semesters they came from.
///
/// The chart's legend used to be hardcoded to '2024 - 2025' and '2023 - 2024'.
/// The bars are drawn from the two most recently published semesters, whatever
/// those are, so the legend named years the data need not have been from — and
/// would go quietly wrong the moment a new semester was published.
///
/// Carrying the labels beside the rates means the legend cannot disagree with
/// the bars it describes.
typedef DepartmentPassComparison = ({
  /// Label of the most recently published semester.
  String currentLabel,

  /// The one before it, or null when only one semester has been published.
  String? previousLabel,

  List<DepartmentPassRate> rates,
});

/// A band of the SGPA histogram, e.g. "8.0 - 8.99".
class SgpaBand {
  const SgpaBand({required this.label, required this.studentCount});

  final String label;
  final int studentCount;
}

/// Course- and programme-outcome attainment at one of the three levels
/// (high, medium, low), counted and expressed as a share of outcomes.
class AttainmentLevel {
  const AttainmentLevel({
    required this.label,
    required this.courseOutcomes,
    required this.programOutcomes,
  });

  final String label;
  final int courseOutcomes;
  final int programOutcomes;

  int get total => courseOutcomes + programOutcomes;
}

/// One semester's aggregate result line.
class SemesterSummary {
  const SemesterSummary({
    required this.semester,
    required this.appeared,
    required this.passed,
    required this.averageSgpa,
    required this.averageCgpa,
    required this.backlogs,
    required this.topPerformer,
    required this.topPerformerCgpa,
  });

  final String semester;
  final int appeared;
  final int passed;
  final double averageSgpa;
  final double averageCgpa;
  final int backlogs;
  final String topPerformer;
  final double topPerformerCgpa;

  double get passPercent => appeared == 0 ? 0 : passed / appeared * 100;
}

/// Why a cohort of students is flagged as at risk, and how many.
class AtRiskReason {
  const AtRiskReason({required this.reason, required this.studentCount});

  final String reason;
  final int studentCount;
}

/// Institution pass percentage for a single academic year.
class YearlyPassRate {
  const YearlyPassRate({required this.year, required this.passPercent});

  final String year;
  final double passPercent;
}

/// Share of students awarded a given letter grade.
class GradeSlice {
  const GradeSlice({required this.grade, required this.studentCount});

  final String grade;
  final int studentCount;
}

/// Result of a single subject offering.
class SubjectResult {
  const SubjectResult({
    required this.code,
    required this.name,
    required this.departmentCode,
    required this.semester,
    required this.faculty,
    required this.appeared,
    required this.passed,
    required this.averageMarks,
  });

  final String code;
  final String name;
  final String departmentCode;
  final String semester;
  final String faculty;
  final int appeared;
  final int passed;
  final double averageMarks;

  double get passPercent => appeared == 0 ? 0 : passed / appeared * 100;
}

/// A student in the top- or bottom-performers list.
class PerformerRecord {
  const PerformerRecord({
    required this.name,
    required this.rollNumber,
    required this.departmentCode,
    required this.semester,
    required this.cgpa,
    required this.backlogs,
    required this.attendancePercent,
  });

  final String name;
  final String rollNumber;
  final String departmentCode;
  final String semester;
  final double cgpa;
  final int backlogs;
  final double attendancePercent;
}
