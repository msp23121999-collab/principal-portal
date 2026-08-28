import '../../../core/utils/batch_parser.dart';

/// A single student's placement offer.
class PlacementRecord {
  const PlacementRecord({
    required this.studentName,
    required this.rollNumber,
    required this.departmentId,
    required this.companyName,
    required this.packageLpa,
    required this.offerDate,
  });

  final String studentName;
  final String rollNumber;
  final String departmentId;
  final String companyName;
  final double packageLpa;
  final DateTime offerDate;

  /// Admission year, read out of the register number.
  ///
  /// `placement_records` stores no batch. Parsing the roll number keeps the
  /// batch from disagreeing with the register number it came from, and works
  /// on rows that already exist. Null where the number carries no year.
  int? get batchStartYear => BatchParser.startYearFrom(rollNumber);

  /// The batch as a Principal reads it, e.g. `2022–2026`, or null.
  String? get batchRange => BatchParser.rangeFromStartYear(batchStartYear);
}
