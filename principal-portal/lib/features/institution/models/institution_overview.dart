import 'package:flutter/widgets.dart';

/// Enrolment for one programme level, compared across two academic years.
class ProgramLevelEnrolment {
  const ProgramLevelEnrolment({
    required this.level,
    required this.currentYear,
    required this.previousYear,
  });

  /// UG, PG, Diploma, Ph.D.
  final String level;
  final int currentYear;
  final int previousYear;
}

/// Pass rate and average SGPA for a single semester — the two series
/// behind the Overall Performance chart.
class SemesterPerformance {
  const SemesterPerformance({
    required this.semester,
    required this.passPercent,
    required this.averageSgpa,
  });

  final String semester;
  final double passPercent;
  final double averageSgpa;
}

/// One slice of the faculty headcount breakdown.
class FacultyStatusSlice {
  const FacultyStatusSlice({required this.label, required this.count});

  final String label;
  final int count;
}

/// A campus facility count shown in the At a Glance strip.
class FacilityStat {
  const FacilityStat({
    required this.icon,
    required this.label,
    required this.count,
  });

  final IconData icon;
  final String label;
  final int count;
}

/// A standout institutional fact for the Key Highlights rail.
class InstitutionHighlight {
  const InstitutionHighlight({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;
}

/// An academic year the overview can be scoped to, newest first.
class AcademicYear {
  const AcademicYear({required this.label, required this.isCurrent});

  final String label;
  final bool isCurrent;
}
