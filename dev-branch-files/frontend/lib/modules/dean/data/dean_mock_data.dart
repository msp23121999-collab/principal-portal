import 'dean_mock_data_expanded.dart';

class DeanMockData {
  static const bool useMockData = false;

  static const Map<String, dynamic> academicOverview = {
    'totalStudents': 3750,
    'totalFaculty': 186,
    'totalCourses': 186,
    'averageSgpa': 8.12,
    'passPercentage': 91.6,
    'backlogPercentage': 4.8,
    'placementPercentage': 87.4,
  };

  // Use expanded department summaries
  static const List<Map<String, dynamic>> departmentSummaries = [
    {'code': 'CSE', 'name': 'Computer Science & Engineering', 'students': 420, 'faculty': 32, 'courses': 18, 'avgSgpa': 8.34, 'passPct': 94.2, 'backlogPct': 3.1, 'placementPct': 91.5},
    {'code': 'IT', 'name': 'Information Technology', 'students': 360, 'faculty': 24, 'courses': 13, 'avgSgpa': 8.18, 'passPct': 92.1, 'backlogPct': 4.0, 'placementPct': 89.2},
    {'code': 'AI & DS', 'name': 'Artificial Intelligence & Data Science', 'students': 280, 'faculty': 18, 'courses': 9, 'avgSgpa': 8.27, 'passPct': 93.5, 'backlogPct': 3.7, 'placementPct': 90.8},
    {'code': 'ECE', 'name': 'Electronics & Communication Engineering', 'students': 390, 'faculty': 28, 'courses': 10, 'avgSgpa': 8.11, 'passPct': 91.3, 'backlogPct': 4.6, 'placementPct': 88.9},
    {'code': 'EEE', 'name': 'Electrical & Electronics Engineering', 'students': 310, 'faculty': 22, 'courses': 8, 'avgSgpa': 8.06, 'passPct': 90.8, 'backlogPct': 4.9, 'placementPct': 87.2},
    {'code': 'MECH', 'name': 'Mechanical Engineering', 'students': 350, 'faculty': 26, 'courses': 8, 'avgSgpa': 7.86, 'passPct': 88.7, 'backlogPct': 6.3, 'placementPct': 82.5},
    {'code': 'CIVIL', 'name': 'Civil Engineering', 'students': 280, 'faculty': 20, 'courses': 5, 'avgSgpa': 7.92, 'passPct': 89.6, 'backlogPct': 5.8, 'placementPct': 80.4},
    {'code': 'CYSC', 'name': 'Cyber Security', 'students': 200, 'faculty': 14, 'courses': 8, 'avgSgpa': 8.42, 'passPct': 94.1, 'backlogPct': 2.8, 'placementPct': 93.5},
    {'code': 'CSBS', 'name': 'Computer Science & Business Systems', 'students': 160, 'faculty': 12, 'courses': 6, 'avgSgpa': 8.15, 'passPct': 92.3, 'backlogPct': 4.2, 'placementPct': 88.9},
  ];

  // Lazy-loaded expanded datasets
  static late final List<Map<String, dynamic>> students = DeanMockDataExpanded.generateStudents();
  static late final List<Map<String, dynamic>> faculties = DeanMockDataExpanded.generateFaculty();
  
  static const List<Map<String, dynamic>> departments = [
    {'id': 'D001', 'name': 'Computer Science & Engineering', 'department': 'Computer Science & Engineering', 'dept': 'CSE', 'code': 'CSE'},
    {'id': 'D002', 'name': 'Information Technology', 'department': 'Information Technology', 'dept': 'IT', 'code': 'IT'},
    {'id': 'D003', 'name': 'Artificial Intelligence & Data Science', 'department': 'Artificial Intelligence & Data Science', 'dept': 'AI & DS', 'code': 'AI & DS'},
    {'id': 'D004', 'name': 'Electronics & Communication Engineering', 'department': 'Electronics & Communication Engineering', 'dept': 'ECE', 'code': 'ECE'},
    {'id': 'D005', 'name': 'Electrical & Electronics Engineering', 'department': 'Electrical & Electronics Engineering', 'dept': 'EEE', 'code': 'EEE'},
    {'id': 'D006', 'name': 'Mechanical Engineering', 'department': 'Mechanical Engineering', 'dept': 'MECH', 'code': 'MECH'},
    {'id': 'D007', 'name': 'Civil Engineering', 'department': 'Civil Engineering', 'dept': 'CIVIL', 'code': 'CIVIL'},
    {'id': 'D008', 'name': 'Cyber Security', 'department': 'Cyber Security', 'dept': 'CYSC', 'code': 'CYSC'},
    {'id': 'D009', 'name': 'Computer Science & Business Systems', 'department': 'Computer Science & Business Systems', 'dept': 'CSBS', 'code': 'CSBS'},
  ];

  static late final List<Map<String, dynamic>> approvals = DeanMockDataExpanded.generateApprovals();
  static late final List<Map<String, dynamic>> regulations = DeanMockDataExpanded.generateCourses();
  static late final List<Map<String, dynamic>> calendarEvents = DeanMockDataExpanded.generateExams();
  static late final List<Map<String, dynamic>> lessonPlanProgress = DeanMockDataExpanded.generateLessonPlans();
  static late final List<Map<String, dynamic>> examMarks = _generateExamMarks();
  static late final List<Map<String, dynamic>> attendanceRecords = DeanMockDataExpanded.generateAttendance();
  static late final List<Map<String, dynamic>> notificationsCirculars = DeanMockDataExpanded.generateNotifications();
  static late final List<Map<String, dynamic>> digitalRepository = DeanMockDataExpanded.generateRepository();
  static late final List<Map<String, dynamic>> meetingRecords = DeanMockDataExpanded.generateMeetings();
  static late final List<Map<String, dynamic>> accreditationDocuments = DeanMockDataExpanded.generateAccreditation();
  
  static late final List<Map<String, dynamic>> poAttainment = _generatePOAttainment();
  static late final List<Map<String, dynamic>> researchProjects = DeanMockDataExpanded.generateResearchProjects();
  static late final List<Map<String, dynamic>> coursesList = DeanMockDataExpanded.generateCourses();
  static late final List<Map<String, dynamic>> programmesData = _generateProgrammes();



  static const List<Map<String, dynamic>> markSheets = [
    {'id': 'MS001', 'department': 'Computer Science & Engineering', 'dept': 'CSE', 'status': 'Verified', 'moderation_status': 'Verified', 'total_subjects': 12},
    {'id': 'MS002', 'department': 'Information Technology', 'dept': 'IT', 'status': 'In Progress', 'moderation_status': 'In Progress', 'total_subjects': 10},
    {'id': 'MS003', 'department': 'Electronics & Communication', 'dept': 'ECE', 'status': 'Verified', 'moderation_status': 'Verified', 'total_subjects': 11},
    {'id': 'MS004', 'department': 'Mechanical Engineering', 'dept': 'MECH', 'status': 'Pending', 'moderation_status': 'Pending', 'total_subjects': 9},
    {'id': 'MS005', 'department': 'Artificial Intelligence & DS', 'dept': 'AI & DS', 'status': 'Verified', 'moderation_status': 'Verified', 'total_subjects': 10},
  ];

  static const List<Map<String, dynamic>> placements = [
    {'id': 'PL001', 'company': 'TCS', 'placed_count': 120, 'date': '2026-08-06', 'placement_rate': 88.67},
    {'id': 'PL002', 'company': 'Infosys', 'placed_count': 96, 'date': '2026-08-08', 'placement_rate': 86.25},
    {'id': 'PL003', 'company': 'Wipro', 'placed_count': 72, 'date': '2026-08-09', 'placement_rate': 83.45},
  ];

  static const List<Map<String, dynamic>> placementApps = [
    {'id': 'PA001', 'student_name': 'Aarav Nair', 'company': 'TCS', 'status': 'Shortlisted', 'department': 'CSE'},
    {'id': 'PA002', 'student_name': 'Rohan Patel', 'company': 'Infosys', 'status': 'Applied', 'department': 'IT'},
    {'id': 'PA003', 'student_name': 'Aditya Kumar', 'company': 'Wipro', 'status': 'Interviewed', 'department': 'AI & DS'},
    {'id': 'PA004', 'student_name': 'Neha Gupta', 'company': 'TCS', 'status': 'Selected', 'department': 'MCA'},
  ];

  // Helper function to generate exam marks with realistic variation
  static List<Map<String, dynamic>> _generateExamMarks() {
    final marks = <Map<String, dynamic>>[];
    final courses = coursesList;
    for (int i = 0; i < courses.length && i < 150; i++) {
      final course = courses[i];
      final percentage = 65 + (i * 7) % 35;
      marks.add({
        'id': 'M${(i + 1).toString().padLeft(4, '0')}',
        'subject': course['course_title'],
        'subject_name': course['course_title'],
        'department': course['dept'],
        'percentage': percentage.toDouble(),
        'marks': percentage.toDouble(),
        'status': percentage >= 40 ? 'Passed' : 'Failed',
      });
    }
    return marks;
  }

  // Helper function to generate PO attainment for all departments
  static List<Map<String, dynamic>> _generatePOAttainment() {
    final depts = ['CSE', 'IT', 'AI & DS', 'ECE', 'EEE', 'MECH', 'CIVIL', 'CYSC'];
    final poData = <Map<String, dynamic>>[];
    for (int d = 0; d < depts.length; d++) {
      final baseScore = 2.5 + (d * 0.05);
      poData.add({
        'department': depts[d],
        'po1': _variatePO(baseScore, 0),
        'po2': _variatePO(baseScore, 1),
        'po3': _variatePO(baseScore, 2),
        'po4': _variatePO(baseScore, 3),
        'po5': _variatePO(baseScore, 4),
        'po6': _variatePO(baseScore, 5),
        'po7': _variatePO(baseScore, 6),
        'po8': _variatePO(baseScore, 7),
        'po9': _variatePO(baseScore, 8),
        'po10': _variatePO(baseScore, 9),
        'po11': _variatePO(baseScore, 10),
        'po12': _variatePO(baseScore, 11),
        'direct': _variatePO(baseScore, 12),
        'indirect': _variatePO(baseScore - 0.3, 13),
        'overall': _variatePO(baseScore - 0.1, 14),
        'target': 2.50,
      });
    }
    return poData;
  }

  static double _variatePO(double base, int seed) {
    final varied = base + ((seed * 7) % 15) / 100.0 - 0.07;
    return double.parse(varied.toStringAsFixed(2));
  }

  // Generate programmes
  static List<Map<String, dynamic>> _generateProgrammes() {
    return [
      {'id': 'P001', 'name': 'B.E. Computer Science & Engineering', 'dept': 'CSE', 'duration': '4 years', 'semester': 8},
      {'id': 'P002', 'name': 'B.Tech Information Technology', 'dept': 'IT', 'duration': '4 years', 'semester': 8},
      {'id': 'P003', 'name': 'B.Tech Artificial Intelligence & Data Science', 'dept': 'AI & DS', 'duration': '4 years', 'semester': 8},
      {'id': 'P004', 'name': 'B.E. Electronics & Communication Engineering', 'dept': 'ECE', 'duration': '4 years', 'semester': 8},
      {'id': 'P005', 'name': 'B.E. Electrical & Electronics Engineering', 'dept': 'EEE', 'duration': '4 years', 'semester': 8},
      {'id': 'P006', 'name': 'B.E. Mechanical Engineering', 'dept': 'MECH', 'duration': '4 years', 'semester': 8},
      {'id': 'P007', 'name': 'B.E. Civil Engineering', 'dept': 'CIVIL', 'duration': '4 years', 'semester': 8},
      {'id': 'P008', 'name': 'B.Tech Cyber Security', 'dept': 'CYSC', 'duration': '4 years', 'semester': 8},
      {'id': 'P009', 'name': 'B.Tech Computer Science & Business Systems', 'dept': 'CSBS', 'duration': '4 years', 'semester': 8},
    ];
  }
}
