/// Resolves the many spellings of a department name down to one stable code.
///
/// Departments are stored as free text across the existing portals, so the
/// same department arrives spelt several ways:
///
/// ```
/// CSE  |  Computer Science and Engineering  |  Computer Science & Engineering
/// Internet of Things (IOT)  |  Internet of Things (IoT)
/// Science & Humanities     |  S&H  |  SCI
/// ```
///
/// Counting those raw strings would report four Computer Science departments
/// instead of one and throw off every institution-wide total, average, and
/// ranking on the Principal's screens. Every aggregate must group on
/// [codeFor] rather than on the raw value.
class DepartmentNormalizer {
  DepartmentNormalizer._();

  /// Canonical code -> the display name used across the portal.
  static const Map<String, String> canonicalNames = {
    'CSE': 'Computer Science & Engineering',
    'IT': 'Information Technology',
    'IOT': 'Internet of Things',
    'ECE': 'Electronics & Communication Engineering',
    'EEE': 'Electrical & Electronics Engineering',
    'MECH': 'Mechanical Engineering',
    'CIVIL': 'Civil Engineering',
    'AIDS': 'Artificial Intelligence & Data Science',
    'MBA': 'Master of Business Administration',
    'MCA': 'Master of Computer Applications',
    'SCI': 'Science & Humanities',
  };

  /// Distinctive keyword -> code. Order matters: the first match wins, so
  /// longer and more specific phrases are checked before short ones.
  static const List<MapEntry<String, String>> _keywordRules = [
    MapEntry('artificial intelligence', 'AIDS'),
    MapEntry('data science', 'AIDS'),
    MapEntry('internet of things', 'IOT'),
    MapEntry('information technology', 'IT'),
    MapEntry('computer application', 'MCA'),
    MapEntry('business administration', 'MBA'),
    MapEntry('computer science', 'CSE'),
    MapEntry('electronics and communication', 'ECE'),
    MapEntry('electronics & communication', 'ECE'),
    MapEntry('electrical and electronics', 'EEE'),
    MapEntry('electrical & electronics', 'EEE'),
    MapEntry('mechanical', 'MECH'),
    MapEntry('civil', 'CIVIL'),
    MapEntry('science and humanities', 'SCI'),
    MapEntry('science & humanities', 'SCI'),
  ];

  /// Bare abbreviations that may arrive on their own.
  static const Map<String, String> _abbreviations = {
    'cse': 'CSE',
    'cs': 'CSE',
    'it': 'IT',
    'iot': 'IOT',
    'ece': 'ECE',
    'eee': 'EEE',
    'mech': 'MECH',
    'me': 'MECH',
    'civil': 'CIVIL',
    'ce': 'CIVIL',
    'aids': 'AIDS',
    'ai&ds': 'AIDS',
    'mba': 'MBA',
    'mca': 'MCA',
    's&h': 'SCI',
    'sci': 'SCI',
  };

  /// The canonical code for any spelling. Returns `'UNKNOWN'` for null, blank,
  /// or unrecognised values so those rows stay visible in totals rather than
  /// being silently dropped.
  static String codeFor(String? rawDepartment) {
    final raw = rawDepartment?.trim() ?? '';
    if (raw.isEmpty) return 'UNKNOWN';

    final lower = raw.toLowerCase();

    final abbreviation = _abbreviations[lower];
    if (abbreviation != null) return abbreviation;

    for (final rule in _keywordRules) {
      if (lower.contains(rule.key)) return rule.value;
    }

    // A parenthesised abbreviation, e.g. "Internet of Things (IOT)".
    final match = RegExp(r'\(([^)]+)\)').firstMatch(raw);
    if (match != null) {
      final inner = match.group(1)!.trim().toLowerCase();
      final fromBrackets = _abbreviations[inner];
      if (fromBrackets != null) return fromBrackets;
    }

    // Unrecognised: keep it, upper-cased, so it still appears in reports.
    return raw.toUpperCase();
  }

  /// Display name for a code, falling back to the code itself.
  static String displayName(String code) => canonicalNames[code] ?? code;

  /// Groups rows by normalised department code.
  static Map<String, List<T>> groupByDepartment<T>(
    Iterable<T> rows,
    String? Function(T) departmentOf,
  ) {
    final grouped = <String, List<T>>{};
    for (final row in rows) {
      grouped.putIfAbsent(codeFor(departmentOf(row)), () => <T>[]).add(row);
    }
    return grouped;
  }
}
