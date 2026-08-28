/// A student — aggregated by Dashboard's student-summary section and
/// listed/ranked in full on the Student Performance screen.
class Student {
  const Student({
    required this.id,
    required this.name,
    required this.rollNumber,
    required this.departmentId,
    required this.semester,
    required this.cgpa,
    required this.attendancePercent,
    required this.isTopPerformer,
    required this.isAtRisk,
  });

  final String id;
  final String name;
  final String rollNumber;
  final String departmentId;
  final int semester;
  final double cgpa;
  final double attendancePercent;
  final bool isTopPerformer;
  final bool isAtRisk;
}
