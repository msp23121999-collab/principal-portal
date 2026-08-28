/// Turns headers and rows into CSV text.
///
/// This is deliberately separate from the browser download code. The escaping
/// below is a security control — it is what stops a value stored in the
/// database from executing as a formula when the Principal opens the export —
/// and a security control that cannot be tested is a security control nobody
/// can trust. The download path needs `dart:js_interop`, which does not exist
/// on the Dart VM the tests run on; this file needs nothing, so it can be
/// tested directly.
class CsvSerializer {
  CsvSerializer._();

  /// The byte-order mark Excel needs to read the file as UTF-8 rather than
  /// mangling the rupee sign and the en dashes the portal uses throughout.
  static const String utf8Bom = '\u{FEFF}';

  /// Characters that make a spreadsheet treat a cell as a formula.
  ///
  /// Tab and carriage return are included because Excel strips them and then
  /// evaluates whatever follows.
  static const List<String> formulaLeads = ['=', '+', '-', '@', '\t', '\r'];

  /// Serialises [headers] and [rows] into a complete CSV document, BOM first.
  static String toCsv({
    required List<String> headers,
    required List<List<Object?>> rows,
  }) {
    final buffer = StringBuffer()..writeln(headers.map(escapeField).join(','));

    for (final row in rows) {
      buffer.writeln(row.map((cell) => escapeField('${cell ?? ''}')).join(','));
    }

    return '$utf8Bom$buffer';
  }

  /// Quotes a field only when it needs it, and never lets one become a formula.
  ///
  /// A comma, a quote or a newline inside a value would otherwise shift every
  /// column after it, which is the classic way a CSV export silently corrupts
  /// the report it was meant to produce.
  ///
  /// A cell that opens with `=`, `+`, `-` or `@` is treated as a formula by
  /// Excel and by Sheets, so a circular titled `=HYPERLINK(...)` stored in the
  /// database would execute when the Principal opened the export. Prefixing a
  /// single quote is the documented neutraliser: the spreadsheet shows the
  /// original text and evaluates nothing.
  static String escapeField(String value) {
    final safe = neutraliseFormula(value);
    final needsQuotes =
        safe.contains(',') ||
        safe.contains('"') ||
        safe.contains('\n') ||
        safe != value;
    if (!needsQuotes) return safe;
    return '"${safe.replaceAll('"', '""')}"';
  }

  /// Prefixes a leading formula character so a spreadsheet renders it as text.
  ///
  /// Negative numbers are exempt. The portal exports deficits, variances and
  /// negative surpluses, and quoting those into text would break every sum the
  /// Principal builds on top of the export.
  static String neutraliseFormula(String value) {
    if (value.isEmpty) return value;
    if (!formulaLeads.contains(value[0])) return value;
    if (num.tryParse(value) != null) return value;
    return "'$value";
  }
}
