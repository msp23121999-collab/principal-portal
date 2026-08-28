enum FacultyDesignation { professor, associateProfessor, assistantProfessor }

extension FacultyDesignationX on FacultyDesignation {
  String get label {
    switch (this) {
      case FacultyDesignation.professor:
        return 'Professor';
      case FacultyDesignation.associateProfessor:
        return 'Associate Professor';
      case FacultyDesignation.assistantProfessor:
        return 'Assistant Professor';
    }
  }
}

/// A faculty member — aggregated by Dashboard's faculty-summary section and
/// listed/filtered in full on the Faculty Performance screen.
class Faculty {
  const Faculty({
    required this.id,
    required this.name,
    required this.designation,
    required this.departmentId,
    required this.experienceYears,
    required this.attendancePercent,
    required this.researchPapersCount,
    required this.performanceScore,
    this.qualification,
    this.email,
    this.weeklyWorkloadHours,
    this.subjectsHandled,
  });

  final String id;
  final String name;
  final FacultyDesignation designation;
  final String departmentId;
  final int experienceYears;
  final double attendancePercent;
  final int researchPapersCount;
  final double performanceScore;

  // The four fields below are read from the same `faculty.faculties` row as
  // everything above, and carried here so the detail layer can fall back on
  // them without fetching the roster a second time. Null means the column is
  // blank on the record — never a substituted value.

  /// e.g. 'M.E., Ph.D.', as the Faculty Portal recorded it.
  final String? qualification;

  final String? email;

  /// Contact hours per week, from `weekly_workload_hours`.
  final int? weeklyWorkloadHours;

  /// Count of `assigned_subjects`, where that column is populated.
  final int? subjectsHandled;
}
