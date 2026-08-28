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
}
