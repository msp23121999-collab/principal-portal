/// A recruiting company that visited campus this placement season.
class Company {
  const Company({
    required this.name,
    required this.sector,
    required this.studentsHired,
    required this.avgPackageLpa,
  });

  final String name;
  final String sector;
  final int studentsHired;
  final double avgPackageLpa;
}
