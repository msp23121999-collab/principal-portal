/// Administrative and infrastructure position for one department —
/// the operational side that sits alongside its academic results.
class DepartmentAdminMetrics {
  const DepartmentAdminMetrics({
    required this.departmentCode,
    required this.departmentName,
    required this.budgetAllocated,
    required this.budgetUtilised,
    required this.classrooms,
    required this.laboratories,
    required this.sanctionedPosts,
    required this.filledPosts,
    required this.studentCount,
    required this.infrastructureScore,
  });

  final String departmentCode;
  final String departmentName;

  /// Annual budget sanctioned to the department, in rupees.
  final double budgetAllocated;

  /// Of that, how much has been spent.
  final double budgetUtilised;

  final int classrooms;
  final int laboratories;

  /// Teaching posts approved for the department.
  final int sanctionedPosts;

  /// Of those, how many are occupied.
  final int filledPosts;

  final int studentCount;

  /// Facilities audit score out of 100.
  final double infrastructureScore;

  double get budgetUtilisationPercent =>
      budgetAllocated == 0 ? 0 : budgetUtilised / budgetAllocated * 100;

  int get vacantPosts => sanctionedPosts - filledPosts;

  double get staffingPercent =>
      sanctionedPosts == 0 ? 0 : filledPosts / sanctionedPosts * 100;

  /// Students per teaching staff member — AICTE norms expect 20:1 or better.
  double get facultyStudentRatio =>
      filledPosts == 0 ? 0 : studentCount / filledPosts;

  bool get meetsRatioNorm => facultyStudentRatio <= 20;
}
