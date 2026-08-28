import 'faculty.dart';

/// The teaching, appraisal, and research detail behind a faculty member —
/// what the profile drill-down and the workload tables show.
///
/// Kept separate from [Faculty] so the roster stays a light list model.
///
/// **Every field that is not recorded is null, never a number.** This class
/// used to carry a `FacultyDetail.forFaculty` factory that invented the whole
/// record from a hash of the employee id — workload, subjects handled, mentees,
/// and a manufactured `firstnamelastname@ksrce.ac.in` email address — for any
/// member without a row in `principal.faculty_details`. Four real, named staff
/// were being shown those figures. It survived the mock-data purge only because
/// it lived in a model file rather than a `*_mock_data.dart` one.
///
/// A null renders as an em dash. That tells the Principal "not recorded", which
/// is true, instead of a plausible number that is not.
class FacultyDetail {
  const FacultyDetail({
    required this.facultyId,
    this.weeklyTeachingHours,
    this.subjectsHandled,
    this.mentees,
    this.appraisalScore,
    this.feedbackScore,
    this.fundedProjects,
    this.achievements = const [],
    this.qualification,
    this.email,
  });

  /// The weekly contact-hour norm. Stated once here rather than in each widget,
  /// so the table's "Over / Normal" chip and [isOverloaded] cannot disagree.
  static const int weeklyHoursNorm = 18;

  final String facultyId;

  /// Contact hours per week against the [weeklyHoursNorm] AICTE norm.
  final int? weeklyTeachingHours;

  final int? subjectsHandled;

  /// Students under this member's mentorship. Nothing in any schema records
  /// this today, so it is null for everyone without a stored detail row.
  final int? mentees;

  /// Annual appraisal score out of 100.
  final double? appraisalScore;

  /// Student feedback rating out of 5.
  final double? feedbackScore;

  final int? fundedProjects;

  /// Notable recognitions. Empty for most of the roster, and empty is honest —
  /// these used to be awarded by a threshold in code ('Best Faculty Award,
  /// 2024-25' for anyone scoring 90+), which invented a citation nobody issued.
  final List<String> achievements;

  final String? qualification;
  final String? email;

  /// True only when the workload is **known** to exceed the norm.
  ///
  /// An unrecorded workload is not evidence of an overload, so it is not
  /// flagged as one.
  bool get isOverloaded =>
      weeklyTeachingHours != null && weeklyTeachingHours! > weeklyHoursNorm;

  /// The detail carried on the roster row itself, for members with no stored
  /// row in `principal.faculty_details`.
  ///
  /// `faculty.faculties` already holds a real qualification, a real
  /// `weekly_workload_hours` and an email column. Reading them is both more
  /// truthful and less code than the formula this replaced. Anything that
  /// genuinely has no source — mentees, appraisal, feedback — stays null.
  factory FacultyDetail.fromRosterRow(Faculty faculty) {
    return FacultyDetail(
      facultyId: faculty.id,
      weeklyTeachingHours: faculty.weeklyWorkloadHours,
      subjectsHandled: faculty.subjectsHandled,
      qualification: faculty.qualification,
      email: faculty.email,
    );
  }
}
