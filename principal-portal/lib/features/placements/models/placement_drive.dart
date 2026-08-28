/// Where a recruitment drive has reached.
enum DriveStage { scheduled, ongoing, completed, cancelled }

extension DriveStageX on DriveStage {
  String get label {
    switch (this) {
      case DriveStage.scheduled:
        return 'Scheduled';
      case DriveStage.ongoing:
        return 'Ongoing';
      case DriveStage.completed:
        return 'Completed';
      case DriveStage.cancelled:
        return 'Cancelled';
    }
  }
}

/// A campus recruitment drive by a visiting company.
class PlacementDrive {
  const PlacementDrive({
    required this.companyName,
    required this.role,
    required this.visitDate,
    required this.eligibleDepartments,
    required this.registered,
    required this.shortlisted,
    required this.offersMade,
    required this.packageLpa,
    required this.stage,
  });

  final String companyName;
  final String role;
  final DateTime visitDate;

  /// Department short codes invited to the drive.
  final List<String> eligibleDepartments;

  final int registered;
  final int shortlisted;
  final int offersMade;
  final double packageLpa;
  final DriveStage stage;

  double get conversionPercent =>
      registered == 0 ? 0 : offersMade / registered * 100;
}

/// An internship offered to students, paid or otherwise.
class InternshipRecord {
  const InternshipRecord({
    required this.companyName,
    required this.domain,
    required this.departmentCode,
    required this.students,
    required this.durationWeeks,
    required this.monthlyStipend,
    required this.convertsToOffer,
  });

  final String companyName;
  final String domain;
  final String departmentCode;
  final int students;
  final int durationWeeks;

  /// Zero for unpaid internships.
  final double monthlyStipend;

  /// Whether the internship carries a pre-placement offer route.
  final bool convertsToOffer;
}

/// Count of offers falling inside one package range.
class PackageBand {
  const PackageBand({
    required this.label,
    required this.minLpa,
    required this.maxLpa,
    required this.offerCount,
  });

  final String label;
  final double minLpa;

  /// Null for the open-ended top band.
  final double? maxLpa;

  final int offerCount;
}
