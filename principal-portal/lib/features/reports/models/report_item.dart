enum ReportCategory { academic, attendance, faculty, placement }

extension ReportCategoryX on ReportCategory {
  String get label {
    switch (this) {
      case ReportCategory.academic:
        return 'Academic';
      case ReportCategory.attendance:
        return 'Attendance';
      case ReportCategory.faculty:
        return 'Faculty';
      case ReportCategory.placement:
        return 'Placement';
    }
  }
}

/// One downloadable institutional report.
class ReportItem {
  const ReportItem({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.lastGeneratedAt,
  });

  final String id;
  final String title;
  final ReportCategory category;
  final String description;
  final DateTime lastGeneratedAt;
}
