/// The arena an achievement was won in.
enum AchievementCategory { technical, sports, cultural, academic, social }

extension AchievementCategoryX on AchievementCategory {
  String get label {
    switch (this) {
      case AchievementCategory.technical:
        return 'Technical';
      case AchievementCategory.sports:
        return 'Sports';
      case AchievementCategory.cultural:
        return 'Cultural';
      case AchievementCategory.academic:
        return 'Academic';
      case AchievementCategory.social:
        return 'Social Service';
    }
  }
}

/// How far the competition reached.
enum AchievementLevel { institutional, state, national, international }

extension AchievementLevelX on AchievementLevel {
  String get label {
    switch (this) {
      case AchievementLevel.institutional:
        return 'Institutional';
      case AchievementLevel.state:
        return 'State';
      case AchievementLevel.national:
        return 'National';
      case AchievementLevel.international:
        return 'International';
    }
  }
}

/// A recognition won by a student outside the examination hall.
class StudentAchievement {
  const StudentAchievement({
    required this.studentName,
    required this.departmentCode,
    required this.title,
    required this.event,
    required this.category,
    required this.level,
    required this.position,
    required this.achievedOn,
  });

  final String studentName;
  final String departmentCode;
  final String title;

  /// Competition or forum where it was won.
  final String event;

  final AchievementCategory category;
  final AchievementLevel level;

  /// Placement won, e.g. "First Prize" or "Gold Medal".
  final String position;

  final DateTime achievedOn;
}

/// Placement position for one department's outgoing batch.
class DepartmentPlacementSummary {
  const DepartmentPlacementSummary({
    required this.departmentCode,
    required this.departmentName,
    required this.eligible,
    required this.placed,
    required this.highestPackageLpa,
    required this.averagePackageLpa,
  });

  final String departmentCode;
  final String departmentName;
  final int eligible;
  final int placed;
  final double highestPackageLpa;
  final double averagePackageLpa;

  /// Whether there is a roll to measure the placements against.
  ///
  /// Ten of the twelve departments currently have no students recorded in
  /// `student.students`, which is the Student Portal's table and not ours to
  /// populate. For those departments a placement rate is undefined rather than
  /// zero, and the screen must say so instead of printing a figure.
  bool get hasEligibleRoll => eligible > 0;

  /// Students yet to be placed.
  ///
  /// Floored at zero: where the roll is incomplete, `placed` can exceed
  /// `eligible`, and a negative count of unplaced students is never a fact
  /// worth showing.
  int get unplaced => eligible - placed < 0 ? 0 : eligible - placed;

  /// Null when there is no roll to divide by — see [hasEligibleRoll].
  double? get placementPercent =>
      hasEligibleRoll ? placed / eligible * 100 : null;
}
