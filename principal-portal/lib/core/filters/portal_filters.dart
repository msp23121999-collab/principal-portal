import '../utils/program_level.dart';

/// One field of [PortalFilters], used to say which one changed.
///
/// Distinct from `PortalFilterKind`, which says which controls a *screen*
/// offers. This names the fields of the scope itself, so the hierarchy can be
/// stated once as a list rather than as a flag per caller.
enum PortalFilterField {
  academicYear,
  department,
  programLevel,
  batch,
  yearOfStudy,
  semester,
  subject,
}

/// The scope the Principal is currently looking at.
///
/// One object rather than a filter per screen. A Principal who narrows to
/// "CSE, III Year, Semester 5" expects Attendance, Student Performance, Top
/// Performers, Result and Placement to agree about what they are showing; the
/// alternative is seven screens each holding their own idea of the scope and
/// quietly disagreeing.
///
/// Every field is nullable and null means "all". A screen reads only the
/// fields that apply to it — [subject] means nothing to Attendance, and
/// [semester] means nothing to Placement — so each surface shows only the
/// filters it honours rather than a full row of controls where most do
/// nothing.
class PortalFilters {
  const PortalFilters({
    this.academicYear,
    this.departmentCode,
    this.programLevel,
    this.batch,
    this.yearOfStudy,
    this.semester,
    this.subject,
  });

  /// e.g. '2025-26', matching `principal.academic_years.label`.
  final String? academicYear;

  /// Normalised department code ('CSE'), never the raw department text.
  final String? departmentCode;

  final ProgramLevel? programLevel;

  /// Admission batch as stored, e.g. '2022'.
  final String? batch;

  /// Roman year of study as stored, e.g. 'III'.
  final String? yearOfStudy;

  final int? semester;

  /// Subject name, used only by Result Analysis.
  final String? subject;

  /// Nothing narrowed — the whole institution.
  bool get isEmpty =>
      academicYear == null &&
      departmentCode == null &&
      programLevel == null &&
      batch == null &&
      yearOfStudy == null &&
      semester == null &&
      subject == null;

  /// How many filters are active, for the "N filters applied" chip.
  int get activeCount => [
    academicYear,
    departmentCode,
    programLevel,
    batch,
    yearOfStudy,
    semester,
    subject,
  ].where((value) => value != null).length;

  /// Copies with the given fields changed.
  ///
  /// Each field takes a `clear` flag rather than treating null as "leave
  /// alone", because a filter being set back to "All" is a real change and
  /// `copyWith(departmentCode: null)` cannot express it otherwise.
  PortalFilters copyWith({
    String? academicYear,
    bool clearAcademicYear = false,
    String? departmentCode,
    bool clearDepartment = false,
    ProgramLevel? programLevel,
    bool clearProgramLevel = false,
    String? batch,
    bool clearBatch = false,
    String? yearOfStudy,
    bool clearYearOfStudy = false,
    int? semester,
    bool clearSemester = false,
    String? subject,
    bool clearSubject = false,
  }) {
    return PortalFilters(
      academicYear: clearAcademicYear
          ? null
          : (academicYear ?? this.academicYear),
      departmentCode: clearDepartment
          ? null
          : (departmentCode ?? this.departmentCode),
      programLevel: clearProgramLevel
          ? null
          : (programLevel ?? this.programLevel),
      batch: clearBatch ? null : (batch ?? this.batch),
      yearOfStudy: clearYearOfStudy ? null : (yearOfStudy ?? this.yearOfStudy),
      semester: clearSemester ? null : (semester ?? this.semester),
      subject: clearSubject ? null : (subject ?? this.subject),
    );
  }

  /// The filters, broadest first.
  ///
  /// This is the order they appear in on screen and the order they narrow each
  /// other: each one's options are drawn from the rows left by the filters
  /// above it, and changing one clears every one below it.
  static const List<PortalFilterField> hierarchy = [
    PortalFilterField.academicYear,
    PortalFilterField.department,
    PortalFilterField.programLevel,
    PortalFilterField.batch,
    PortalFilterField.yearOfStudy,
    PortalFilterField.semester,
    PortalFilterField.subject,
  ];

  /// Drops the selections that no longer make sense after a broader filter
  /// changed.
  ///
  /// Everything below [changed] in [hierarchy] is cleared. Previously only the
  /// programme and subject were, so choosing "Batch 2022" in CSE and then
  /// switching department left a batch that department never admitted still
  /// selected. That is not only wrong on screen — the batch dropdown no longer
  /// offered the value it was holding, and `DropdownButton` asserts on that,
  /// taking the page down.
  ///
  /// Clearing downwards is also what a Principal expects: narrowing to a new
  /// department starts a new question, it does not carry the last one's answers
  /// across.
  PortalFilters narrowedFor(PortalFilterField changed) {
    final from = hierarchy.indexOf(changed);
    bool keeps(PortalFilterField field) => hierarchy.indexOf(field) <= from;

    return PortalFilters(
      academicYear: keeps(PortalFilterField.academicYear) ? academicYear : null,
      departmentCode: keeps(PortalFilterField.department)
          ? departmentCode
          : null,
      programLevel: keeps(PortalFilterField.programLevel) ? programLevel : null,
      batch: keeps(PortalFilterField.batch) ? batch : null,
      yearOfStudy: keeps(PortalFilterField.yearOfStudy) ? yearOfStudy : null,
      semester: keeps(PortalFilterField.semester) ? semester : null,
      subject: keeps(PortalFilterField.subject) ? subject : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PortalFilters &&
      other.academicYear == academicYear &&
      other.departmentCode == departmentCode &&
      other.programLevel == programLevel &&
      other.batch == batch &&
      other.yearOfStudy == yearOfStudy &&
      other.semester == semester &&
      other.subject == subject;

  @override
  int get hashCode => Object.hash(
    academicYear,
    departmentCode,
    programLevel,
    batch,
    yearOfStudy,
    semester,
    subject,
  );

  @override
  String toString() =>
      'PortalFilters(year: $academicYear, dept: $departmentCode, '
      'program: ${programLevel?.label}, batch: $batch, '
      'yearOfStudy: $yearOfStudy, semester: $semester, subject: $subject)';
}
