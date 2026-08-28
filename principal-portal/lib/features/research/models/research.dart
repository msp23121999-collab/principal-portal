/// Where a paper appeared.
enum PublicationType { journal, conference, bookChapter }

extension PublicationTypeX on PublicationType {
  String get label {
    switch (this) {
      case PublicationType.journal:
        return 'Journal';
      case PublicationType.conference:
        return 'Conference';
      case PublicationType.bookChapter:
        return 'Book Chapter';
    }
  }
}

/// Which index the venue is listed in — what accreditation bodies count.
enum PublicationIndex { scopus, webOfScience, ugcCare, other }

extension PublicationIndexX on PublicationIndex {
  String get label {
    switch (this) {
      case PublicationIndex.scopus:
        return 'Scopus';
      case PublicationIndex.webOfScience:
        return 'Web of Science';
      case PublicationIndex.ugcCare:
        return 'UGC CARE';
      case PublicationIndex.other:
        return 'Other';
    }
  }
}

/// A published research output.
class Publication {
  const Publication({
    required this.title,
    required this.leadAuthor,
    required this.venue,
    required this.departmentCode,
    required this.type,
    required this.index,
    required this.year,
    required this.citations,
    required this.impactFactor,
  });

  final String title;
  final String leadAuthor;

  /// Journal or conference name.
  final String venue;

  final String departmentCode;
  final PublicationType type;
  final PublicationIndex index;
  final int year;
  final int citations;

  /// Zero where the venue carries no impact factor.
  final double impactFactor;
}

/// Stage a patent application has reached.
enum PatentStage { filed, published, granted }

extension PatentStageX on PatentStage {
  String get label {
    switch (this) {
      case PatentStage.filed:
        return 'Filed';
      case PatentStage.published:
        return 'Published';
      case PatentStage.granted:
        return 'Granted';
    }
  }
}

/// A patent application from the institution.
class Patent {
  const Patent({
    required this.title,
    required this.leadInventor,
    required this.departmentCode,
    required this.applicationNumber,
    required this.filedOn,
    required this.stage,
    this.grantedOn,
  });

  final String title;
  final String leadInventor;
  final String departmentCode;
  final String applicationNumber;
  final DateTime filedOn;
  final PatentStage stage;

  /// Null until the patent is actually granted.
  final DateTime? grantedOn;
}

/// Where a funded project stands.
enum ProjectStage { sanctioned, ongoing, completed }

extension ProjectStageX on ProjectStage {
  String get label {
    switch (this) {
      case ProjectStage.sanctioned:
        return 'Sanctioned';
      case ProjectStage.ongoing:
        return 'Ongoing';
      case ProjectStage.completed:
        return 'Completed';
    }
  }
}

/// An externally funded research project.
class FundedProject {
  const FundedProject({
    required this.title,
    required this.principalInvestigator,
    required this.departmentCode,
    required this.agency,
    required this.sanctionedAmount,
    required this.durationMonths,
    required this.sanctionedOn,
    required this.stage,
  });

  final String title;
  final String principalInvestigator;
  final String departmentCode;

  /// Funding body — DST, AICTE, DRDO, industry, and so on.
  final String agency;

  final double sanctionedAmount;
  final int durationMonths;
  final DateTime sanctionedOn;
  final ProjectStage stage;
}

/// A paid consultancy engagement with an external client.
class ConsultancyProject {
  const ConsultancyProject({
    required this.title,
    required this.client,
    required this.departmentCode,
    required this.leadFaculty,
    required this.revenue,
    required this.stage,
  });

  final String title;
  final String client;
  final String departmentCode;
  final String leadFaculty;
  final double revenue;
  final ProjectStage stage;
}

/// Research output for a single year, used for the trend chart.
class ResearchYearOutput {
  const ResearchYearOutput({
    required this.year,
    required this.publications,
    required this.patents,
    required this.projects,
  });

  final String year;
  final int publications;
  final int patents;
  final int projects;
}
