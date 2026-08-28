/// Canonical department entity — owned by the institution module, imported
/// by Dashboard, Department/Faculty/Student/Attendance/Result/Placement
/// analytics instead of each module hand-rolling its own department list.
class Department {
  const Department({
    required this.id,
    required this.name,
    required this.shortCode,
    required this.hodName,
    required this.facultyCount,
    required this.studentCount,
    required this.attendancePercent,
    required this.avgCgpa,
    required this.placementPercent,
    required this.rank,
  });

  final String id;
  final String name;
  final String shortCode;
  final String hodName;
  final int facultyCount;
  final int studentCount;
  final double attendancePercent;
  final double avgCgpa;
  final double placementPercent;
  final int rank;
}
