import '../../../core/utils/program_level.dart';

/// A student — aggregated by Dashboard's student-summary section and
/// listed/ranked in full on the Student Performance screen.
///
/// [degree], [batch] and [yearOfStudy] carry the raw values from
/// `student.students`. They exist so the portal's filters have something real
/// to narrow on; the Student Portal writes them as free text, so nothing here
/// should group on them directly — use [programLevel], which normalises the
/// degree, and compare [yearOfStudy] and [batch] against the option lists
/// derived from the roll rather than against literals.
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
    this.degree,
    this.batch,
    this.yearOfStudy,
    this.section,
    this.admittedOn,
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

  /// Degree as written by whoever enrolled the student — 'B.E', 'B.E.',
  /// 'BE COMPUTER SCIENCE AND ENGINEERING'. Read through [programLevel].
  final String? degree;

  /// Admission batch, stored as a single year ('2022') rather than a range.
  final String? batch;

  /// Roman year of study, e.g. 'III'.
  final String? yearOfStudy;

  final String? section;

  /// Date of admission, where recorded — the source for admission trends.
  final DateTime? admittedOn;

  /// UG / PG / Diploma / PhD, or null when the degree is blank or unreadable.
  ProgramLevel? get programLevel => ProgramLevels.from(degree);
}
