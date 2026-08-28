import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class DeanAppState extends ChangeNotifier {
  bool _initializationStarted = false;

  int selectedNavIndex = 0;
  String selectedBatch = 'All Batches';
  bool isLoading = false;
  bool hasLoaded = false;
  String? lastError;
  String selectedAcademicYear = '2024 - 2025';
  String selectedSemester = 'EVEN Semesters';
  String selectedViewBy = 'Overall';

  final Map<String, List<String>> batchToAcademicYears = {
    '2024 - 2028': ['2024 - 2025', '2025 - 2026', '2026 - 2027', '2027 - 2028'],
    '2023 - 2027': ['2023 - 2024', '2024 - 2025', '2025 - 2026', '2026 - 2027'],
    '2022 - 2026': ['2022 - 2023', '2023 - 2024', '2024 - 2025', '2025 - 2026'],
    '2021 - 2025': ['2021 - 2022', '2022 - 2023', '2023 - 2024', '2024 - 2025'],
    'All Batches': ['2024 - 2025', '2023 - 2024', '2022 - 2023', '2021 - 2022'],
  };

  void setNavIndex(int index) {
    selectedNavIndex = index;
    notifyListeners();
  }

  void setBatch(String batch) {
    selectedBatch = batch;
    final availableYears = batchToAcademicYears[batch] ?? ['2024 - 2025'];
    if (!availableYears.contains(selectedAcademicYear)) {
      selectedAcademicYear = availableYears.first;
    }
    notifyListeners();
  }

  // Real Database Lists (populated from Supabase endpoints)
  List<Map<String, dynamic>> studentsData = [];
  List<Map<String, dynamic>> facultiesData = [];
  List<Map<String, dynamic>> departmentsData = [];
  List<Map<String, dynamic>> regulationsData = [];
  List<Map<String, dynamic>> calendarEventsData = [];
  List<Map<String, dynamic>> researchProjectsData = [];
  List<Map<String, dynamic>> approvalsData = [];
  List<Map<String, dynamic>> examMarksData = [];
  List<Map<String, dynamic>> markSheetsData = [];
  List<Map<String, dynamic>> placementsData = [];
  List<Map<String, dynamic>> placementAppsData = [];
  List<Map<String, dynamic>> repositoryDocumentsData = [];
  List<Map<String, dynamic>> meetingsData = [];
  List<Map<String, dynamic>> examinationSignoffsData = [];
  List<Map<String, dynamic>> deanNotificationsData = [];

  // --- Additional Analytics Data Lists ---
  List<Map<String, dynamic>> attendanceRecordsData = [];
  List<Map<String, dynamic>> facultyCourseAllocationsData = [];
  List<Map<String, dynamic>> lessonPlansData = [];
  List<Map<String, dynamic>> assignmentMarksData = [];
  List<Map<String, dynamic>> facultyAttendanceSessionsData = [];
  List<Map<String, dynamic>> classAdvisersData = [];
  List<Map<String, dynamic>> mentorAssignmentsData = [];
  List<Map<String, dynamic>> departmentEventsData = [];
  List<Map<String, dynamic>> departmentNoticesData = [];
  List<Map<String, dynamic>> courseDiaryData = [];
  List<Map<String, dynamic>> departmentFilesData = [];
  List<Map<String, dynamic>> facultyTimetablesData = [];
  List<Map<String, dynamic>> syllabusUploadsData = [];
  List<Map<String, dynamic>> facultyLeaveApplicationsData = [];
  List<Map<String, dynamic>> facultyAssignmentsData = [];
  List<Map<String, dynamic>> subjectsData = [];
  List<Map<String, dynamic>> classionsData = [];
  List<Map<String, dynamic>> academicYearsData = [];

  // --- Calculated Analytics ---
  Map<String, int> departmentWiseStudentCount = {};
  Map<String, int> departmentWiseFacultyCount = {};


  Future<void> initialize() async {
    if (_initializationStarted) return;
    _initializationStarted = true;

    print('[DEAN TRACE] DeanAppState.initialize START');
    try {
      isLoading = true;
      lastError = null;
      hasLoaded = false;
      notifyListeners();

      print('[DEAN TRACE] Supabase initialize START');
      await DeanSupabaseService.instance.initialize();
      print('[DEAN TRACE] Supabase initialize COMPLETE');

      print('[DEAN TRACE] fetchAllData START');
      await fetchAllData();
      print('[DEAN TRACE] DeanAppState.initialize COMPLETE');
    } catch (e, stackTrace) {
      print('[DEAN TRACE] DeanAppState.initialize EXCEPTION: $e');
      debugPrintStack(stackTrace: stackTrace);
      lastError = e.toString();
      hasLoaded = true;
      isLoading = false;
      notifyListeners();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllData() async {
    print('[DEAN TRACE] fetchAllData START');
    isLoading = true;
    lastError = null;
    notifyListeners();

    try {
      // -----------------------------------------------------------------------
      // STEP 1 — Fetch critical dean-schema tables by name (zero index risk).
      // -----------------------------------------------------------------------
      print('[DEAN UI DEBUG] Fetching dean.dean_meetings...');
      final rawMeetings = await DeanSupabaseService.instance.getDeanMeetings();
      print('[DEAN UI DEBUG] meetings Supabase row count = ${rawMeetings.length}');
      if (rawMeetings.isNotEmpty) {
        print('[DEAN UI DEBUG] meetings first row = ${rawMeetings.first}');
      }

      print('[DEAN UI DEBUG] Fetching dean.dean_academic_approvals...');
      final rawApprovals = await DeanSupabaseService.instance.getFacultyApprovals();
      print('[DEAN UI DEBUG] approvals Supabase row count = ${rawApprovals.length}');
      if (rawApprovals.isNotEmpty) {
        print('[DEAN UI DEBUG] approvals first row = ${rawApprovals.first}');
      }

      print('[DEAN UI DEBUG] Fetching dean.dean_notifications...');
      final rawNotifications = await DeanSupabaseService.instance.getDeanNotifications();
      print('[DEAN UI DEBUG] notifications Supabase row count = ${rawNotifications.length}');

      // Assign by name — no index involved.
      meetingsData = _normalizeList(rawMeetings);
      approvalsData = _normalizeList(rawApprovals);
      deanNotificationsData = _normalizeList(rawNotifications);

      print('[DEAN UI DEBUG] appState.meetingsData count = ${meetingsData.length}');
      print('[DEAN UI DEBUG] appState.approvalsData count = ${approvalsData.length}');

      // Notify early so the UI can render meetings/approvals before the slower
      // public-schema batch completes.
      notifyListeners();

      // -----------------------------------------------------------------------
      // STEP 2 — Parallel fetch for remaining public/student-schema sources.
      //          IMPORTANT: new entries must be APPENDED at the END of this list.
      //          Never insert in the middle — that would shift all indexes below.
      // -----------------------------------------------------------------------
      final results = await Future.wait([
        DeanSupabaseService.instance.getStudentsList(),               // [0]
        DeanSupabaseService.instance.getFacultiesList(),              // [1]
        DeanSupabaseService.instance.getDepartmentsList(),            // [2]
        DeanSupabaseService.instance.getRegulationsList(),            // [3]
        DeanSupabaseService.instance.getCalendarEvents(),             // [4]
        DeanSupabaseService.instance.getResearchProjects(),           // [5]
        DeanSupabaseService.instance.getExaminationMarks(),           // [6]
        DeanSupabaseService.instance.getMarkSheetStatuses(),          // [7]
        DeanSupabaseService.instance.getPlacementsList(),             // [8]
        DeanSupabaseService.instance.getPlacementApplications(),      // [9]
        DeanSupabaseService.instance.getDeanRepositoryDocuments(),    // [10]
        DeanSupabaseService.instance.getDeanExaminationSignoffs(),    // [11]
        DeanSupabaseService.instance.getStudentAttendanceRecords(),   // [12]
        DeanSupabaseService.instance.getFacultyAttendanceSessions(),  // [13]
        DeanSupabaseService.instance.getClassAttendanceSummary(),     // [14]
        DeanSupabaseService.instance.getFacultyCourseAllocations(),   // [15]
        DeanSupabaseService.instance.getLessonPlans(),                // [16]
        DeanSupabaseService.instance.getFacultyTimetables(),          // [17]
        DeanSupabaseService.instance.getSyllabusUploads(),            // [18]
        DeanSupabaseService.instance.getFacultyLeaveApplications(),   // [19]
        DeanSupabaseService.instance.getFacultyAssignments(),         // [20]
        DeanSupabaseService.instance.getAssignmentMarks(),            // [21]
        DeanSupabaseService.instance.getClassAdvisers(),              // [22]
        // ADD NEW ENTRIES HERE — append only, never insert in the middle.
      ]);

      studentsData                  = _normalizeList(results[0]);
      facultiesData                 = _normalizeList(results[1]);
      departmentsData               = _normalizeList(results[2]);
      regulationsData               = _normalizeList(results[3]);
      calendarEventsData            = _normalizeList(results[4]);
      researchProjectsData          = _normalizeList(results[5]);
      examMarksData                 = _normalizeList(results[6]);
      markSheetsData                = _normalizeList(results[7]);
      placementsData                = _normalizeList(results[8]);
      placementAppsData             = _normalizeList(results[9]);
      repositoryDocumentsData       = _normalizeList(results[10]);
      examinationSignoffsData       = _normalizeList(results[11]);
      attendanceRecordsData         = _normalizeList(results[12]);
      facultyAttendanceSessionsData = _normalizeList(results[13]);
      classionsData                 = _normalizeList(results[14]);
      facultyCourseAllocationsData  = _normalizeList(results[15]);
      lessonPlansData               = _normalizeList(results[16]);
      facultyTimetablesData         = _normalizeList(results[17]);
      syllabusUploadsData           = _normalizeList(results[18]);
      facultyLeaveApplicationsData  = _normalizeList(results[19]);
      facultyAssignmentsData        = _normalizeList(results[20]);
      assignmentMarksData           = _normalizeList(results[21]);
      classAdvisersData             = _normalizeList(results[22]);

      departmentWiseStudentCount = await DeanSupabaseService.instance.getDepartmentWiseStudentCount();
      departmentWiseFacultyCount = await DeanSupabaseService.instance.getDepartmentWiseFacultyCount();

      hasLoaded = true;
      print('[DEAN UI DEBUG] fetchAllData COMPLETE — meetingsData=${meetingsData.length} approvalsData=${approvalsData.length}');
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('[DEAN UI DEBUG] fetchAllData EXCEPTION: $e');
      debugPrintStack(stackTrace: stackTrace);
      // Do NOT wipe meetingsData/approvalsData if they were already successfully
      // assigned in Step 1. Only record the error from Step 2.
      lastError = e.toString();
      hasLoaded = true;
      notifyListeners();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }


  List<Map<String, dynamic>> _normalizeList(List<Map<String, dynamic>> data) {
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // --- Dynamic Database Metric Calculations ---

  int get totalStudentsCount => studentsData.length;

  int get totalFacultyCount => facultiesData.length;

  int get totalDeptsCount => departmentsData.length;

  int get totalProgrammesCount {
    if (regulationsData.isNotEmpty) {
      final progSet = <String>{};
      for (final r in regulationsData) {
        if (r['department'] != null) progSet.add(r['department'].toString());
      }
      if (progSet.isNotEmpty) return progSet.length;
    }
    return 0;
  }

  double get calculatedOverallPassPercentage {
    if (studentsData.isNotEmpty) {
      int passed = 0;
      for (final s in studentsData) {
        final cgpaVal = double.tryParse(s['cgpa']?.toString() ?? '0') ?? 0.0;
        if (cgpaVal >= 5.0) passed++;
      }
      return (passed / studentsData.length) * 100.0;
    }
    if (examMarksData.isNotEmpty) {
      int passed = 0;
      for (final m in examMarksData) {
        final pct = double.tryParse(m['percentage']?.toString() ?? '0') ?? 0.0;
        if (pct >= 50.0) passed++;
      }
      return (passed / examMarksData.length) * 100.0;
    }
    return 0.0;
  }

  double get calculatedAverageSGPA {
    if (studentsData.isEmpty) return 0.0;
    double total = 0.0;
    int count = 0;
    for (final s in studentsData) {
      final val = double.tryParse(s['cgpa']?.toString() ?? '0');
      if (val != null && val > 0) {
        total += val;
        count++;
      }
    }
    return count > 0 ? (total / count) : 0.0;
  }

  double get calculatedAverageCGPA {
    return calculatedAverageSGPA;
  }

  int get backlogStudentsCount {
    if (studentsData.isEmpty) return 0;
    int count = 0;
    for (final s in studentsData) {
      final val = double.tryParse(s['cgpa']?.toString() ?? '0') ?? 0.0;
      if (val > 0 && val < 6.0) count++;
    }
    return count;
  }

  int get atRiskStudentsCount {
    if (studentsData.isEmpty) return 0;
    int count = 0;
    for (final s in studentsData) {
      final att = double.tryParse(s['attendance_percentage']?.toString() ?? '100') ?? 100.0;
      if (att < 75.0) count++;
    }
    return count;
  }

  void setAcademicYear(String year) {
    selectedAcademicYear = year;
    notifyListeners();
  }

  void setSemester(String sem) {
    selectedSemester = sem;
    notifyListeners();
  }

  void setViewBy(String viewBy) {
    selectedViewBy = viewBy;
    notifyListeners();
  }

  // ===== ACCREDITATION & QA ACTIONS =====
  void verifyDocument(String documentId) {
    for (final approval in approvalsData) {
      if (approval['id'] == documentId || approval['request_id'] == documentId) {
        approval['status'] = 'Verified';
        notifyListeners();
        return;
      }
    }
  }

  // ===== ACADEMIC APPROVALS ACTIONS =====
  Future<void> approveRequest(String requestId) async {
    final match = approvalsData.firstWhere(
      (approval) => approval['id'] == requestId || approval['request_id'] == requestId,
      orElse: () => <String, dynamic>{},
    );

    if (match.isEmpty) {
      return;
    }

    final payload = <String, dynamic>{
      'status': 'APPROVED',
      'updated_at': DateTime.now().toIso8601String(),
    };

    final updated = await DeanSupabaseService.instance.updateAcademicApproval(requestId, payload);
    if (updated != null) {
      final idx = approvalsData.indexOf(match);
      if (idx >= 0) {
        approvalsData[idx] = {...match, ...updated};
      }
    } else {
      match['status'] = 'APPROVED';
    }
    notifyListeners();
  }

  Future<void> rejectRequest(String requestId) async {
    final match = approvalsData.firstWhere(
      (approval) => approval['id'] == requestId || approval['request_id'] == requestId,
      orElse: () => <String, dynamic>{},
    );

    if (match.isEmpty) {
      return;
    }

    final payload = <String, dynamic>{
      'status': 'REJECTED',
      'updated_at': DateTime.now().toIso8601String(),
    };

    final updated = await DeanSupabaseService.instance.updateAcademicApproval(requestId, payload);
    if (updated != null) {
      final idx = approvalsData.indexOf(match);
      if (idx >= 0) {
        approvalsData[idx] = {...match, ...updated};
      }
    } else {
      match['status'] = 'REJECTED';
    }
    notifyListeners();
  }

  // ===== REPORTS ACTIONS =====
  String generateReport(String reportType, String academicYear) {
    // Generate a simple report summary
    switch (reportType) {
      case 'Institutional Academic Summary':
        return 'Academic Year: $academicYear\n\n'
            'Total Students: ${studentsData.length}\n'
            'Total Faculty: ${facultiesData.length}\n'
            'Total Departments: ${departmentsData.length}\n'
            'Average SGPA: ${calculatedAverageSGPA.toStringAsFixed(2)}\n'
            'Pass Percentage: ${calculatedOverallPassPercentage.toStringAsFixed(2)}%\n'
            'Backlog Students: ${backlogStudentsCount}\n'
            'At Risk Students: ${atRiskStudentsCount}';
      case 'Faculty Workload & Research Report':
        return 'Academic Year: $academicYear\n\n'
            'Total Faculty Members: ${facultiesData.length}\n\n'
            'Faculty Details:\n'
            '${facultiesData.map((f) => '${f['name']} (${f['designation']}) - ${f['publications_count']} Publications').join('\n')}';
      case 'Student Arrears & Probation Report':
        return 'Academic Year: $academicYear\n\n'
            'Total Students: ${studentsData.length}\n'
            'Students with Backlogs: ${backlogStudentsCount}\n'
            'At Risk Students (Attendance < 75%): ${atRiskStudentsCount}';
      default:
        return 'Report for $reportType - Academic Year: $academicYear';
    }
  }

  // ===== DIGITAL SIGNATURE ACTIONS =====
  String? uploadedSignaturePath;

  void updateDigitalSignature(String filePath) {
    uploadedSignaturePath = filePath;
    notifyListeners();
  }
}

class DeanAppStateProvider extends InheritedWidget {
  final DeanAppState state;

  const DeanAppStateProvider({
    super.key,
    required this.state,
    required super.child,
  });

  static DeanAppState of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<DeanAppStateProvider>();
    assert(provider != null, 'No DeanAppStateProvider found in context');
    return provider!.state;
  }

  @override
  bool updateShouldNotify(DeanAppStateProvider oldWidget) => true;
}
