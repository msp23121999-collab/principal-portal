/// Reads an admission batch out of a register number.
///
/// `principal.placement_records` records a roll number but no batch, and
/// `student.students` stores a batch as a single admission year ('2022')
/// rather than the range a Principal reads on a report ('2022–2026').
///
/// Both live formats already encode the year in the first two digits:
///
/// ```
/// 22CSE001   -> 2022
/// 2022IOT001 -> 2022
/// 731521101  -> no batch; a sequential number with no year in it
/// ```
///
/// Parsing this rather than storing a second copy keeps the batch from
/// disagreeing with the register number it came from. The last format is why
/// [startYearFrom] returns null instead of guessing: not every register number
/// carries a year, and inventing one would file students into a batch they
/// were never in.
class BatchParser {
  BatchParser._();

  /// Standard programme lengths, for turning a start year into a range.
  static const int _ugYears = 4;

  /// Admission year from a register number, or null when it carries none.
  static int? startYearFrom(String? registerNumber) {
    final raw = registerNumber?.trim() ?? '';
    if (raw.isEmpty) return null;

    // A four-digit year at the front, e.g. '2022IOT001'.
    final fourDigit = RegExp(r'^(19|20)(\d{2})').firstMatch(raw);
    if (fourDigit != null) return int.parse(raw.substring(0, 4));

    // Two digits followed by letters, e.g. '22CSE001'. The letters matter:
    // without them '731521101' would read as the year 2073.
    final twoDigit = RegExp(r'^(\d{2})[A-Za-z]').firstMatch(raw);
    if (twoDigit != null) {
      final yy = int.parse(twoDigit.group(1)!);
      // Two-digit years are this century; a batch from the 1900s has long
      // since graduated.
      return 2000 + yy;
    }

    return null;
  }

  /// Admission year from a batch value as `student.students` stores it.
  static int? startYearFromBatch(String? batch) {
    final raw = batch?.trim() ?? '';
    if (raw.isEmpty) return null;

    // Already a range — take the year it starts.
    final leading = RegExp(r'^(\d{4})').firstMatch(raw);
    return leading == null ? null : int.parse(leading.group(1)!);
  }

  /// The range a Principal reads, e.g. `2022–2026`.
  ///
  /// Uses an en dash, matching the rest of the portal's copy. Returns null
  /// when there is no year to build it from, so the caller shows an em dash
  /// rather than a fabricated range.
  static String? rangeFromStartYear(int? startYear, {int years = _ugYears}) {
    if (startYear == null) return null;
    return '$startYear–${startYear + years}';
  }

  /// The range for a register number in one step.
  static String? rangeFromRegisterNumber(String? registerNumber) =>
      rangeFromStartYear(startYearFrom(registerNumber));
}
