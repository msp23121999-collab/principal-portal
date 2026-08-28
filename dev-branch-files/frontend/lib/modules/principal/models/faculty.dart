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
  });

  final String id;
  final String name;
  final FacultyDesignation designation;
  final String departmentId;
  final int experienceYears;
  final double attendancePercent;
  final int researchPapersCount;
  final double performanceScore;
}
