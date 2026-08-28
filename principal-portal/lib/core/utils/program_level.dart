/// The four levels a programme can sit at.
///
/// `student.students.degree` is free text written by whoever enrolled the
/// student, and the live rows already carry four spellings of one programme:
///
/// ```
/// B.E  |  B.E.  |  BE COMPUTER SCIENCE AND ENGINEERING  |  B.Tech
/// ```
///
/// Grouping on that raw text would report four undergraduate programmes
/// instead of one and split every programme-wise total. [ProgramLevel.from]
/// collapses it, the same job [DepartmentNormalizer] does for departments.
enum ProgramLevel { ug, pg, diploma, phd }

extension ProgramLevelX on ProgramLevel {
  /// Short label for filter chips and dropdowns.
  String get label => switch (this) {
    ProgramLevel.ug => 'UG',
    ProgramLevel.pg => 'PG',
    ProgramLevel.diploma => 'Diploma',
    ProgramLevel.phd => 'PhD',
  };

  /// Expanded label for table headings and card subtitles.
  String get description => switch (this) {
    ProgramLevel.ug => 'Undergraduate',
    ProgramLevel.pg => 'Postgraduate',
    ProgramLevel.diploma => 'Diploma',
    ProgramLevel.phd => 'Doctoral',
  };

  /// The value stored in the database, for round-tripping a filter.
  String get code => name;
}

/// Resolves the many spellings of a degree down to one level.
class ProgramLevels {
  ProgramLevels._();

  /// Distinctive fragment -> level. Order matters: the first match wins, so
  /// the longer and more specific phrases are checked before short ones, and
  /// doctoral before master's before bachelor's — "M.Phil" must not be read as
  /// a master's when it is checked after "Ph.D".
  static const List<MapEntry<String, ProgramLevel>> _rules = [
    // Doctoral
    MapEntry('ph.d', ProgramLevel.phd),
    MapEntry('phd', ProgramLevel.phd),
    MapEntry('doctor', ProgramLevel.phd),
    MapEntry('research scholar', ProgramLevel.phd),
    // Diploma — before the master's rules, so "Post Graduate Diploma" is
    // recorded as a diploma rather than a master's degree.
    MapEntry('diploma', ProgramLevel.diploma),
    // Postgraduate
    MapEntry('m.e', ProgramLevel.pg),
    MapEntry('m.tech', ProgramLevel.pg),
    MapEntry('mtech', ProgramLevel.pg),
    MapEntry('m.sc', ProgramLevel.pg),
    MapEntry('msc', ProgramLevel.pg),
    MapEntry('mca', ProgramLevel.pg),
    MapEntry('mba', ProgramLevel.pg),
    MapEntry('m.phil', ProgramLevel.pg),
    MapEntry('master', ProgramLevel.pg),
    // Undergraduate
    MapEntry('b.e', ProgramLevel.ug),
    MapEntry('b.tech', ProgramLevel.ug),
    MapEntry('btech', ProgramLevel.ug),
    MapEntry('b.sc', ProgramLevel.ug),
    MapEntry('bsc', ProgramLevel.ug),
    MapEntry('bca', ProgramLevel.ug),
    MapEntry('bba', ProgramLevel.ug),
    MapEntry('bachelor', ProgramLevel.ug),
  ];

  /// The level for any spelling, or null when the value is blank or
  /// unrecognised.
  ///
  /// Null rather than a guess: filing an unreadable degree under UG would
  /// quietly inflate the undergraduate count, and a wrong number is worse
  /// than a missing one.
  static ProgramLevel? from(String? rawDegree) {
    final raw = rawDegree?.trim().toLowerCase() ?? '';
    if (raw.isEmpty) return null;

    for (final rule in _rules) {
      if (raw.contains(rule.key)) return rule.value;
    }

    // 'BE COMPUTER SCIENCE AND ENGINEERING' — a bare 'be'/'me' prefix with no
    // full stops. Checked last because 'be' appears inside ordinary words.
    final firstWord = raw.split(RegExp(r'[\s.]+')).firstOrNull ?? '';
    return switch (firstWord) {
      'be' || 'btech' || 'bsc' => ProgramLevel.ug,
      'me' || 'mtech' || 'msc' => ProgramLevel.pg,
      _ => null,
    };
  }

  /// The levels actually present in a set of degrees, in enum order.
  ///
  /// Filter dropdowns are built from this rather than from
  /// [ProgramLevel.values], so the portal never offers a level that would
  /// return nothing. As PG or PhD students are admitted they appear on their
  /// own, with no code change.
  static List<ProgramLevel> presentIn(Iterable<String?> degrees) {
    final found = <ProgramLevel>{};
    for (final degree in degrees) {
      final level = from(degree);
      if (level != null) found.add(level);
    }
    return [
      for (final level in ProgramLevel.values)
        if (found.contains(level)) level,
    ];
  }
}
