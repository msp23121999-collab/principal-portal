import '../models/company.dart';
import '../models/placement_record.dart';

/// Seed placement season data — companies visited, per-student offers, and
/// aggregate figures used by the Dashboard's placement-summary card.
class PlacementMockData {
  PlacementMockData._();

  static const List<Company> companies = [
    Company(
      name: 'TCS',
      sector: 'IT Services',
      studentsHired: 142,
      avgPackageLpa: 4.5,
    ),
    Company(
      name: 'Infosys',
      sector: 'IT Services',
      studentsHired: 98,
      avgPackageLpa: 5.2,
    ),
    Company(
      name: 'Zoho',
      sector: 'Product',
      studentsHired: 34,
      avgPackageLpa: 8.6,
    ),
    Company(
      name: 'Cognizant',
      sector: 'IT Services',
      studentsHired: 87,
      avgPackageLpa: 4.8,
    ),
    Company(
      name: 'Wipro',
      sector: 'IT Services',
      studentsHired: 65,
      avgPackageLpa: 4.3,
    ),
    Company(
      name: 'Zoho Recruits',
      sector: 'Product',
      studentsHired: 12,
      avgPackageLpa: 9.5,
    ),
    Company(
      name: 'Amazon',
      sector: 'E-Commerce / Cloud',
      studentsHired: 18,
      avgPackageLpa: 18.5,
    ),
    Company(
      name: 'Accenture',
      sector: 'Consulting',
      studentsHired: 76,
      avgPackageLpa: 5.6,
    ),
    Company(
      name: 'HCLTech',
      sector: 'IT Services',
      studentsHired: 54,
      avgPackageLpa: 4.4,
    ),
    Company(
      name: 'Microsoft',
      sector: 'Cloud / Software',
      studentsHired: 6,
      avgPackageLpa: 42.0,
    ),
  ];

  static List<PlacementRecord> placements() => [
    PlacementRecord(
      studentName: 'Aarav Sundaram',
      rollNumber: '21CSE045',
      departmentId: 'cse',
      companyName: 'Microsoft',
      packageLpa: 42.0,
      offerDate: DateTime(2026, 6, 12),
    ),
    PlacementRecord(
      studentName: 'Diya Krishnan',
      rollNumber: '21CSE012',
      departmentId: 'cse',
      companyName: 'Amazon',
      packageLpa: 18.5,
      offerDate: DateTime(2026, 6, 15),
    ),
    PlacementRecord(
      studentName: 'Yuvan Shankar',
      rollNumber: '21IT022',
      departmentId: 'it',
      companyName: 'Zoho',
      packageLpa: 9.0,
      offerDate: DateTime(2026, 5, 22),
    ),
    PlacementRecord(
      studentName: 'Meera Ramaswamy',
      rollNumber: '22ECE033',
      departmentId: 'ece',
      companyName: 'Zoho Recruits',
      packageLpa: 9.5,
      offerDate: DateTime(2026, 5, 28),
    ),
    PlacementRecord(
      studentName: 'Sanjana Pillai',
      rollNumber: '23IOT019',
      departmentId: 'iot',
      companyName: 'Accenture',
      packageLpa: 6.2,
      offerDate: DateTime(2026, 6, 4),
    ),
    PlacementRecord(
      studentName: 'Ishaan Mehta',
      rollNumber: '21EEE027',
      departmentId: 'eee',
      companyName: 'Cognizant',
      packageLpa: 4.8,
      offerDate: DateTime(2026, 4, 18),
    ),
    PlacementRecord(
      studentName: 'Aditya Narayan',
      rollNumber: '22MECH008',
      departmentId: 'mech',
      companyName: 'TCS',
      packageLpa: 4.5,
      offerDate: DateTime(2026, 4, 20),
    ),
    PlacementRecord(
      studentName: 'Nikhil Varadarajan',
      rollNumber: '23CIVIL015',
      departmentId: 'civil',
      companyName: 'Infosys',
      packageLpa: 5.2,
      offerDate: DateTime(2026, 5, 2),
    ),
    PlacementRecord(
      studentName: 'Dhruv Kapoor',
      rollNumber: '22CSE091',
      departmentId: 'cse',
      companyName: 'Wipro',
      packageLpa: 4.3,
      offerDate: DateTime(2026, 4, 25),
    ),
    PlacementRecord(
      studentName: 'Harini Vasudevan',
      rollNumber: '22ECE014',
      departmentId: 'ece',
      companyName: 'HCLTech',
      packageLpa: 4.4,
      offerDate: DateTime(2026, 5, 9),
    ),
    PlacementRecord(
      studentName: 'Manoj Kumaresan',
      rollNumber: '23IOT056',
      departmentId: 'iot',
      companyName: 'TCS',
      packageLpa: 4.5,
      offerDate: DateTime(2026, 4, 30),
    ),
    PlacementRecord(
      studentName: 'Yogesh Waran',
      rollNumber: '21EEE054',
      departmentId: 'eee',
      companyName: 'Accenture',
      packageLpa: 5.8,
      offerDate: DateTime(2026, 5, 14),
    ),
  ];

  static double get averagePackageLpa {
    final list = placements();
    return list.fold(0.0, (sum, p) => sum + p.packageLpa) / list.length;
  }

  static double get highestPackageLpa =>
      placements().map((p) => p.packageLpa).reduce((a, b) => a > b ? a : b);

  static int get totalPlaced =>
      companies.fold(0, (sum, c) => sum + c.studentsHired);
}
