/// Where a notice sits in its publishing lifecycle.
enum CircularStatus { draft, published, archived }

extension CircularStatusX on CircularStatus {
  String get label {
    switch (this) {
      case CircularStatus.draft:
        return 'Draft';
      case CircularStatus.published:
        return 'Published';
      case CircularStatus.archived:
        return 'Archived';
    }
  }
}

/// Subject area of a notice, used for filtering and colour coding.
enum CircularCategory { academic, administrative, examination, event, urgent }

extension CircularCategoryX on CircularCategory {
  String get label {
    switch (this) {
      case CircularCategory.academic:
        return 'Academic';
      case CircularCategory.administrative:
        return 'Administrative';
      case CircularCategory.examination:
        return 'Examination';
      case CircularCategory.event:
        return 'Event';
      case CircularCategory.urgent:
        return 'Urgent';
    }
  }
}

/// Who a notice is addressed to.
enum CircularAudience { everyone, faculty, students, staff, headsOfDepartment }

extension CircularAudienceX on CircularAudience {
  String get label {
    switch (this) {
      case CircularAudience.everyone:
        return 'All Members';
      case CircularAudience.faculty:
        return 'Faculty';
      case CircularAudience.students:
        return 'Students';
      case CircularAudience.staff:
        return 'Support Staff';
      case CircularAudience.headsOfDepartment:
        return 'Heads of Department';
    }
  }
}

/// How much attention a notice demands.
///
/// Separate from [CircularCategory], which says what the notice is *about*. An
/// examination notice can be routine or urgent; the two are not the same axis.
enum NoticePriority { normal, important, urgent }

extension NoticePriorityX on NoticePriority {
  String get label => switch (this) {
    NoticePriority.normal => 'Normal',
    NoticePriority.important => 'Important',
    NoticePriority.urgent => 'Urgent',
  };

  String get code => name;
}

/// Who a notice is narrowed to, beyond the broad [CircularAudience].
///
/// Every field is nullable and null means "not narrowed on this axis", so an
/// institution-wide notice carries none of them. The values are the same ones
/// the portal's filters use — a normalised department code, a programme level
/// label, the Roman year of study and the admission batch as stored.
class NoticeTargeting {
  const NoticeTargeting({
    this.departmentCode,
    this.programLevel,
    this.yearOfStudy,
    this.batch,
  });

  final String? departmentCode;
  final String? programLevel;
  final String? yearOfStudy;
  final String? batch;

  bool get isInstitutionWide =>
      departmentCode == null &&
      programLevel == null &&
      yearOfStudy == null &&
      batch == null;

  /// Reads as a scope line: "CSE · UG · III Year · Batch 2022".
  String describe() {
    if (isInstitutionWide) return 'Entire institution';
    return [
      if (departmentCode != null) departmentCode!,
      if (programLevel != null) programLevel!,
      if (yearOfStudy != null) '$yearOfStudy Year',
      if (batch != null) 'Batch $batch',
    ].join(' · ');
  }
}

/// A single circular, notice, or announcement.
class Circular {
  const Circular({
    required this.id,
    required this.reference,
    required this.title,
    required this.body,
    required this.category,
    required this.audience,
    required this.status,
    required this.author,
    required this.createdAt,
    required this.recipients,
    required this.acknowledgements,
    this.publishedAt,
    this.isPinned = false,
  });

  final String id;

  /// Institutional reference number, e.g. "KSRCE/CIR/2025/084".
  final String reference;

  final String title;
  final String body;
  final CircularCategory category;
  final CircularAudience audience;
  final CircularStatus status;
  final String author;
  final DateTime createdAt;

  /// How many people the notice was addressed to.
  final int recipients;

  /// How many of them have opened it.
  final int acknowledgements;

  /// Null while the notice is still a draft.
  final DateTime? publishedAt;

  final bool isPinned;

  double get readPercent =>
      recipients == 0 ? 0 : acknowledgements / recipients * 100;

  Circular copyWith({
    CircularStatus? status,
    DateTime? publishedAt,
    bool? isPinned,
  }) {
    return Circular(
      id: id,
      reference: reference,
      title: title,
      body: body,
      category: category,
      audience: audience,
      status: status ?? this.status,
      author: author,
      createdAt: createdAt,
      recipients: recipients,
      acknowledgements: acknowledgements,
      publishedAt: publishedAt ?? this.publishedAt,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}
