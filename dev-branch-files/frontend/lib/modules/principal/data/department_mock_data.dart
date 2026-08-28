import '../models/department.dart';

/// Canonical seed list of departments — the single source every other
/// module (Dashboard, Department/Faculty/Student/Attendance/Result/
/// Placement analytics) reads from instead of duplicating department names.
class DepartmentMockData {
  DepartmentMockData._();

  static const List<Department> all = [
    Department(
      id: 'cse',
      name: 'Computer Science & Engineering',
      shortCode: 'CSE',
      hodName: 'Dr. R. Kumaresan',
      facultyCount: 42,
      studentCount: 720,
      attendancePercent: 91.4,
      avgCgpa: 8.2,
      placementPercent: 94.0,
      rank: 1,
    ),
    Department(
      id: 'ece',
      name: 'Electronics & Communication Engineering',
      shortCode: 'ECE',
      hodName: 'Dr. S. Meenakshi',
      facultyCount: 36,
      studentCount: 610,
      attendancePercent: 89.7,
      avgCgpa: 7.9,
      placementPercent: 88.0,
      rank: 2,
    ),
    Department(
      id: 'iot',
      name: 'Internet of Things',
      shortCode: 'IOT',
      hodName: 'Dr. M. Govindharaj',
      facultyCount: 24,
      studentCount: 340,
      attendancePercent: 91.6,
      avgCgpa: 8.0,
      placementPercent: 90.0,
      rank: 3,
    ),
    Department(
      id: 'eee',
      name: 'Electrical & Electronics Engineering',
      shortCode: 'EEE',
      hodName: 'Dr. P. Vijayakumar',
      facultyCount: 30,
      studentCount: 480,
      attendancePercent: 88.2,
      avgCgpa: 7.6,
      placementPercent: 82.0,
      rank: 5,
    ),
    Department(
      id: 'mech',
      name: 'Mechanical Engineering',
      shortCode: 'MECH',
      hodName: 'Dr. K. Balasubramaniam',
      facultyCount: 34,
      studentCount: 560,
      attendancePercent: 87.5,
      avgCgpa: 7.4,
      placementPercent: 79.0,
      rank: 6,
    ),
    Department(
      id: 'civil',
      name: 'Civil Engineering',
      shortCode: 'CIVIL',
      hodName: 'Dr. A. Rajendran',
      facultyCount: 26,
      studentCount: 390,
      attendancePercent: 90.1,
      avgCgpa: 7.7,
      placementPercent: 75.0,
      rank: 7,
    ),
    Department(
      id: 'it',
      name: 'Information Technology',
      shortCode: 'IT',
      hodName: 'Dr. N. Saravanan',
      facultyCount: 28,
      studentCount: 450,
      attendancePercent: 90.8,
      avgCgpa: 8.1,
      placementPercent: 91.0,
      rank: 4,
    ),
  ];

  static Department byId(String id) => all.firstWhere((d) => d.id == id);

  static int get totalFaculty => all.fold(0, (sum, d) => sum + d.facultyCount);
  static int get totalStudents => all.fold(0, (sum, d) => sum + d.studentCount);
  static double get averageAttendance =>
      all.fold(0.0, (sum, d) => sum + d.attendancePercent) / all.length;
  static double get averageCgpa =>
      all.fold(0.0, (sum, d) => sum + d.avgCgpa) / all.length;
  static double get averagePlacement =>
      all.fold(0.0, (sum, d) => sum + d.placementPercent) / all.length;
}
