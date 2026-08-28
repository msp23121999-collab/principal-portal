import '../models/semester_result.dart';

/// Seed results across the last three semesters. Department pass
/// percentages are illustrative figures independent of the live
/// DepartmentMockData.avgCgpa so this module can show its own
/// exam-cycle-specific numbers.
class ResultMockData {
  ResultMockData._();

  static const List<String> semesters = [
    'Semester 6 — 2025-26',
    'Semester 5 — 2025-26',
    'Semester 4 — 2024-25',
  ];

  static const Map<String, SemesterResult> resultsBySemester = {
    'Semester 6 — 2025-26': SemesterResult(
      semesterLabel: 'Semester 6 — 2025-26',
      overallPassPercent: 87.6,
      byDepartment: [
        (departmentCode: 'CSE', passPercent: 93.2),
        (departmentCode: 'IT', passPercent: 90.5),
        (departmentCode: 'IOT', passPercent: 89.1),
        (departmentCode: 'ECE', passPercent: 86.4),
        (departmentCode: 'EEE', passPercent: 82.7),
        (departmentCode: 'CIVIL', passPercent: 84.0),
        (departmentCode: 'MECH', passPercent: 80.3),
      ],
    ),
    'Semester 5 — 2025-26': SemesterResult(
      semesterLabel: 'Semester 5 — 2025-26',
      overallPassPercent: 85.1,
      byDepartment: [
        (departmentCode: 'CSE', passPercent: 91.0),
        (departmentCode: 'IT', passPercent: 88.2),
        (departmentCode: 'IOT', passPercent: 87.6),
        (departmentCode: 'ECE', passPercent: 84.9),
        (departmentCode: 'EEE', passPercent: 80.1),
        (departmentCode: 'CIVIL', passPercent: 82.5),
        (departmentCode: 'MECH', passPercent: 78.8),
      ],
    ),
    'Semester 4 — 2024-25': SemesterResult(
      semesterLabel: 'Semester 4 — 2024-25',
      overallPassPercent: 83.4,
      byDepartment: [
        (departmentCode: 'CSE', passPercent: 89.7),
        (departmentCode: 'IT', passPercent: 86.9),
        (departmentCode: 'IOT', passPercent: 85.2),
        (departmentCode: 'ECE', passPercent: 82.6),
        (departmentCode: 'EEE', passPercent: 77.8),
        (departmentCode: 'CIVIL', passPercent: 80.1),
        (departmentCode: 'MECH', passPercent: 76.4),
      ],
    ),
  };

  static const Map<String, List<RankHolder>> rankHoldersBySemester = {
    'Semester 6 — 2025-26': [
      RankHolder(
        rank: 1,
        studentName: 'Aarav Sundaram',
        rollNumber: '21CSE045',
        departmentId: 'cse',
        cgpa: 9.4,
      ),
      RankHolder(
        rank: 2,
        studentName: 'Diya Krishnan',
        rollNumber: '21CSE012',
        departmentId: 'cse',
        cgpa: 9.2,
      ),
      RankHolder(
        rank: 3,
        studentName: 'Yuvan Shankar',
        rollNumber: '21IT022',
        departmentId: 'it',
        cgpa: 9.1,
      ),
      RankHolder(
        rank: 4,
        studentName: 'Meera Ramaswamy',
        rollNumber: '22ECE033',
        departmentId: 'ece',
        cgpa: 9.0,
      ),
      RankHolder(
        rank: 5,
        studentName: 'Sanjana Pillai',
        rollNumber: '23IOT019',
        departmentId: 'iot',
        cgpa: 8.9,
      ),
      RankHolder(
        rank: 6,
        studentName: 'Ishaan Mehta',
        rollNumber: '21EEE027',
        departmentId: 'eee',
        cgpa: 8.7,
      ),
      RankHolder(
        rank: 7,
        studentName: 'Aditya Narayan',
        rollNumber: '22MECH008',
        departmentId: 'mech',
        cgpa: 8.5,
      ),
      RankHolder(
        rank: 8,
        studentName: 'Nikhil Varadarajan',
        rollNumber: '23CIVIL015',
        departmentId: 'civil',
        cgpa: 8.3,
      ),
    ],
    'Semester 5 — 2025-26': [
      RankHolder(
        rank: 1,
        studentName: 'Diya Krishnan',
        rollNumber: '21CSE012',
        departmentId: 'cse',
        cgpa: 9.3,
      ),
      RankHolder(
        rank: 2,
        studentName: 'Aarav Sundaram',
        rollNumber: '21CSE045',
        departmentId: 'cse',
        cgpa: 9.2,
      ),
      RankHolder(
        rank: 3,
        studentName: 'Yuvan Shankar',
        rollNumber: '21IT022',
        departmentId: 'it',
        cgpa: 8.9,
      ),
      RankHolder(
        rank: 4,
        studentName: 'Sanjana Pillai',
        rollNumber: '23IOT019',
        departmentId: 'iot',
        cgpa: 8.8,
      ),
      RankHolder(
        rank: 5,
        studentName: 'Meera Ramaswamy',
        rollNumber: '22ECE033',
        departmentId: 'ece',
        cgpa: 8.7,
      ),
    ],
    'Semester 4 — 2024-25': [
      RankHolder(
        rank: 1,
        studentName: 'Aarav Sundaram',
        rollNumber: '21CSE045',
        departmentId: 'cse',
        cgpa: 9.1,
      ),
      RankHolder(
        rank: 2,
        studentName: 'Yuvan Shankar',
        rollNumber: '21IT022',
        departmentId: 'it',
        cgpa: 8.8,
      ),
      RankHolder(
        rank: 3,
        studentName: 'Diya Krishnan',
        rollNumber: '21CSE012',
        departmentId: 'cse',
        cgpa: 8.7,
      ),
      RankHolder(
        rank: 4,
        studentName: 'Ishaan Mehta',
        rollNumber: '21EEE027',
        departmentId: 'eee',
        cgpa: 8.5,
      ),
      RankHolder(
        rank: 5,
        studentName: 'Meera Ramaswamy',
        rollNumber: '22ECE033',
        departmentId: 'ece',
        cgpa: 8.4,
      ),
    ],
  };
}
