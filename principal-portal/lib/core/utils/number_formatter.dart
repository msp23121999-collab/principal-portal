/// Centralised number formatting, so a rupee figure reads identically
/// whether it appears on Finance, Research, Approvals, or Departments.
class NumberFormatter {
  NumberFormatter._();

  /// What the portal shows where a value was never recorded.
  static const String unrecorded = '—';

  /// Formats a value that may not exist, without inventing one.
  ///
  /// The portal must never print `0` for something nobody entered — a
  /// department with an unrecorded student-faculty ratio is not a department
  /// with a 0:1 ratio, and an unrecorded appraisal is not a score of zero.
  /// Every such field renders through this, so "not recorded" looks the same
  /// everywhere.
  ///
  /// ```dart
  /// NumberFormatter.orDash(detail.mentees);                        // '—'
  /// NumberFormatter.orDash(hours, (h) => '$h hrs');                // '18 hrs'
  /// NumberFormatter.orDash(score, (s) => s.toStringAsFixed(1));    // '4.2'
  /// ```
  static String orDash<T extends Object>(
    T? value, [
    String Function(T)? format,
  ]) => value == null ? unrecorded : (format?.call(value) ?? value.toString());

  /// Rupees in the units an Indian institution reads in:
  /// "₹1.24 Cr", "₹48.50 L", "₹9,500".
  static String rupees(double amount) {
    final sign = amount < 0 ? '-' : '';
    final value = amount.abs();
    if (value >= 10000000) {
      return '$sign₹${(value / 10000000).toStringAsFixed(2)} Cr';
    }
    if (value >= 100000) {
      return '$sign₹${(value / 100000).toStringAsFixed(2)} L';
    }
    return '$sign₹${thousands(value.round())}';
  }

  /// Larger totals where lakh and crore read better than a raw byte-style
  /// figure — used for storage sizes measured in KB.
  static String kilobytes(int sizeKb) {
    if (sizeKb >= 1048576) {
      return '${(sizeKb / 1048576).toStringAsFixed(2)} GB';
    }
    if (sizeKb >= 1024) return '${(sizeKb / 1024).toStringAsFixed(1)} MB';
    return '$sizeKb KB';
  }

  /// 4285 -> "4,285". Kept local rather than pulling in intl's
  /// NumberFormat, which is more machinery than one grouping rule needs.
  static String thousands(int value) {
    final digits = value.abs().toString();
    final buffer = StringBuffer(value < 0 ? '-' : '');
    for (int i = 0; i < digits.length; i++) {
      if (i != 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}
