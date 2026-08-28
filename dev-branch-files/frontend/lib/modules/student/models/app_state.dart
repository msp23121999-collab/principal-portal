import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class NotificationModel {
  final String id;
  final String title;
  final String category; // ACADEMIC, EXAMS, GENERAL, IMPORTANT
  final String desc;
  final String time;
  final String date;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final Color borderColor;
  final Color categoryColor;
  bool isNew;
  bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.category,
    required this.desc,
    required this.time,
    required this.date,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.borderColor,
    required this.categoryColor,
    this.isNew = true,
    this.isRead = false,
  });
}

class FeeItemModel {
  final String id;
  final String title;
  final String category;
  final double amount;
  final String dueDate;
  bool isPaid;
  String? paymentDate;
  String? receiptNo;
  String academicYear;
  String semester;

  FeeItemModel({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.dueDate,
    this.isPaid = false,
    this.paymentDate,
    this.receiptNo,
    this.academicYear = '2025-26',
    this.semester = 'V',
  });
}

class BookModel {
  final String id;
  final String title;
  final String author;
  final String isbn;
  final String category;
  bool isReserved;
  bool isIssued;
  String? dueDate;

  BookModel({
    required this.id,
    required this.title,
    required this.author,
    required this.isbn,
    required this.category,
    this.isReserved = false,
    this.isIssued = false,
    this.dueDate,
  });
}

class GrievanceItemModel {
  final String id;
  final String category;
  final String subject;
  final String description;
  final String recipient;
  final String priority;
  final String date;
  String status; // Pending, In Review, Resolved, Rejected
  final String response;

  String get title => subject;

  GrievanceItemModel({
    required this.id,
    required this.category,
    required this.subject,
    required this.description,
    this.recipient = 'HOD',
    this.priority = 'Medium',
    required this.date,
    this.status = 'Pending',
    this.response = '',
  });
}
typedef GrievanceModel = GrievanceItemModel;

class OutingRequestModel {
  final String id;
  final String purpose;
  final String destination;
  final String outTime;
  final String inTime;
  final String date;
  String status; // Approved, Pending, Rejected

  OutingRequestModel({
    required this.id,
    required this.purpose,
    required this.destination,
    required this.outTime,
    required this.inTime,
    required this.date,
    this.status = 'Pending',
  });
}

class CertificateRequestModel {
  final String id;
  final String type;
  final String reason;
  final String requestDate;
  String status; // Approved, Pending, Rejected
  String? downloadUrl;

  String get title => type;
  String get desc => reason;
  String get issuedOn => requestDate;
  String get validUpto => status == 'Approved' ? 'Permanent' : 'Under Review';

  CertificateRequestModel({
    required this.id,
    required this.type,
    required this.reason,
    required this.requestDate,
    this.status = 'Pending',
    this.downloadUrl,
  });
}
typedef CertificateModel = CertificateRequestModel;

class AchievementItemModel {
  final String id;
  final String title;
  final String category; // Academic, Sports, Cultural, Research
  final String event;
  final String date;
  final String description;
  String status;
  final int points;
  final String? attachmentName;
  final String? attachmentUrl;

  String get desc => description;
  String get org => event;

  AchievementItemModel({
    required this.id,
    required this.title,
    required this.category,
    required this.event,
    required this.date,
    required this.description,
    this.status = 'Verified',
    this.points = 100,
    this.attachmentName,
    this.attachmentUrl,
  });
}
typedef AchievementModel = AchievementItemModel;


class CourseItemModel {
  final String id;
  final String title;
  final String provider;
  final String duration;
  final String category;
  bool isEnrolled;

  String get instructor => provider;
  String get desc => '$title course offered by $provider ($duration)';
  String get startDate => 'Flexible';

  CourseItemModel({
    required this.id,
    required this.title,
    required this.provider,
    required this.duration,
    required this.category,
    this.isEnrolled = false,
  });
}
typedef CourseModel = CourseItemModel;


class PlacementItemModel {
  final String id;
  final String company;
  final String role;
  final String package;
  final String deadline;
  final String minCgpa;
  bool hasApplied;
  final String status;

  String get ctc => package;
  String get date => deadline;
  bool get isApplied => hasApplied;
  set isApplied(bool value) => hasApplied = value;

  PlacementItemModel({
    required this.id,
    required this.company,
    required this.role,
    required this.package,
    required this.deadline,
    this.minCgpa = '6.0',
    this.hasApplied = false,
    this.status = 'Open',
  });
}
typedef PlacementDriveModel = PlacementItemModel;


class NoticeItemModel {
  final String id;
  final String title;
  final String category;
  final String date;
  final String time;
  final String author;
  final String content;
  bool isBookmarked;
  final bool isPinned;
  final bool hasAttachment;
  final String attachmentName;

  NoticeItemModel({
    required this.id,
    required this.title,
    required this.category,
    required this.date,
    this.time = '10:00 AM',
    this.author = 'Admin',
    required this.content,
    this.isBookmarked = false,
    this.isPinned = false,
    this.hasAttachment = false,
    this.attachmentName = '',
  });
}
typedef NoticeModel = NoticeItemModel;


class AppState extends ChangeNotifier {
  static AppState? _instance;
  static AppState get instance => _instance ??= AppState._();

  AppState._();

  List<Map<String, dynamic>> marksList = [];
  List<Map<String, dynamic>> attendanceRecords = [];
  List<Map<String, dynamic>> timetables = [];
  List<Map<String, dynamic>> syllabusList = [];
  List<Map<String, dynamic>> assignmentsList = [];
  List<Map<String, dynamic>> assignmentMarks = [];
  List<Map<String, dynamic>> academicCalendarEvents = [];
  List<Map<String, dynamic>> examSchedules = [];
  List<Map<String, dynamic>> lessonPlans = [];
  List<Map<String, dynamic>> faculties = [];
  List<Map<String, dynamic>> libraryTransactions = [];
  List<Map<String, dynamic>> transportBuses = [];
  Map<String, dynamic>? studentTransportPass;
  List<Map<String, dynamic>> allocatedSubjects = [];
  List<Map<String, dynamic>> regulationsList = [];

  Future<void> initializeDb() async {
    await SupabaseService.instance.initialize();
    await fetchAllData();
  }

  bool _isDataFetched = false;
  bool get isDataFetched => _isDataFetched;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Available academic years (populated from Supabase public.academic_years)
  List<String> availableAcademicYears = [];

  Future<void> fetchAllData({bool force = false}) async {
    if (!SupabaseService.instance.isConfigured) return;
    if (_isDataFetched && !force) return;
    _isLoading = true;
    notifyListeners();
    try {
      // --- 1. Fetch Academic Years first to set the correct default ---
      final dbYears = await SupabaseService.instance.getAcademicYears();
      if (dbYears.isNotEmpty) {
        final fetched = dbYears
            .map((y) => y['label_short']?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toList();
        final Set<String> allYears = {'2023-24', '2024-25', '2025-26', '2026-27', ...fetched};
        availableAcademicYears = allYears.toList()..sort();
        // Auto-select the year marked as current
        final currentRow = dbYears.firstWhere(
          (y) => y['is_current'] == true,
          orElse: () => dbYears.last,
        );
        _selectedAcademicYear = currentRow['label_short']?.toString() ?? _selectedAcademicYear;
      } else {
        availableAcademicYears = ['2023-24', '2024-25', '2025-26', '2026-27'];
      }

      // Synchronize the academic year with SupabaseService
      SupabaseService.instance.selectedAcademicYear = _selectedAcademicYear;

      // Fetch profile first, regardless of selected academic year, so student name/photo are always available in the header
      final profile = await SupabaseService.instance.getStudentProfile(studentId);
      if (profile != null) {
        studentProfileData = profile;
        dbStudentUuid = profile['id']?.toString();
        studentName = profile['full_name'] ?? profile['name'] ?? studentName;
        personalEmail = profile['personal_email'] ?? personalEmail;
        mobileNumber = profile['mobile_number'] ?? mobileNumber;
        address = profile['address'] ?? address;
        if (profile['year_of_study'] != null) {
          final y = int.tryParse(profile['year_of_study'].toString());
          if (y != null) yearOfStudy = y;
        }
      }

      // If the academic year is not 2025-26, return empty data
      if (!isCurrentAcademicYear) {
        _clearAllDataForNon2025_26();
        _isLoading = false;
        _isDataFetched = true;
        notifyListeners();
        return;
      }
      
      final activeCode = studentId;
      final activeUuid = dbStudentUuid ?? studentId;
      final studentIdCode = getProfileField('student_id').isNotEmpty
          ? getProfileField('student_id')
          : (studentId.isNotEmpty ? studentId : getProfileField('register_no'));
      final regNo = getProfileField('register_no', defaultValue: activeCode);
      final rollNo = getProfileField('roll_no');
      final secVal = studentProfileData?['section']?.toString() ?? 'A';
      final deptVal = getProfileField('department_code', defaultValue: getProfileField('department', defaultValue: 'CSE'));
      final yrVal = getProfileField('year', defaultValue: 'III');

      final results = await Future.wait([
        SupabaseService.instance.getStudentFamily(activeCode), // 0
        SupabaseService.instance.getStudentDocuments(activeCode), // 1
        SupabaseService.instance.getStudentFinancials(activeCode), // 2
        SupabaseService.instance.getStudentEducation(activeCode), // 3
        SupabaseService.instance.getNotifications(studentIdCode.isNotEmpty ? studentIdCode : activeUuid), // 4
        SupabaseService.instance.getOutings(activeUuid), // 5
        SupabaseService.instance.getGrievances(activeCode), // 6
        SupabaseService.instance.getCertificates(activeUuid), // 7
        SupabaseService.instance.getAchievements(activeUuid), // 8
        SupabaseService.instance.getExtraCourses(), // 9
        SupabaseService.instance.getExtraCourseEnrollments(activeUuid), // 10
        SupabaseService.instance.getPlacements(), // 11
        SupabaseService.instance.getPlacementApplications(activeUuid), // 12
        SupabaseService.instance.getNotices(), // 13
        SupabaseService.instance.getNoticeBookmarks(activeUuid), // 14
        SupabaseService.instance.getFees(studentIdCode.isNotEmpty ? studentIdCode : activeUuid), // 15
        SupabaseService.instance.getLibraryBooks(), // 16
        SupabaseService.instance.getLibraryTransactions(activeUuid), // 17
        SupabaseService.instance.getStudentMarks(activeCode, rollNo, regNo), // 18
        SupabaseService.instance.getStudentAttendance(regNo, studentId: activeCode, rollNo: rollNo), // 19
        SupabaseService.instance.getTimetables(secVal), // 20
        SupabaseService.instance.getClassTimetables(department: deptVal, year: yrVal, section: secVal, academicYear: _selectedAcademicYear), // 21
        SupabaseService.instance.getSyllabus(), // 22
        SupabaseService.instance.getCourseMaterials(), // 23
        SupabaseService.instance.getAssignments(), // 24
        SupabaseService.instance.getAssignmentMarks(regNo, studentId: activeUuid), // 25
        SupabaseService.instance.getAcademicCalendarEvents(_selectedAcademicYear), // 26
        SupabaseService.instance.getLessonPlans(), // 27
        SupabaseService.instance.getFaculties(), // 28
        SupabaseService.instance.getTransportBuses(), // 29
        SupabaseService.instance.getStudentTransportPass(activeCode), // 30
        SupabaseService.instance.getFacultyCourseAllocations(), // 31
        SupabaseService.instance.getRegulations(), // 32
        SupabaseService.instance.getExamSchedules(), // 33
      ]);

      studentFamilyList = results[0] as List<Map<String, dynamic>>;
      studentDocList = results[1] as List<Map<String, dynamic>>;
      studentFinancialList = results[2] as List<Map<String, dynamic>>;
      studentEducationList = results[3] as List<Map<String, dynamic>>;

      // Notifications
      final dbNotifs = results[4] as List<Map<String, dynamic>>;
      if (dbNotifs.isNotEmpty) {
        _notifications.clear();
        for (var n in dbNotifs) {
          _notifications.add(NotificationModel(
            id: n['id'].toString(),
            title: n['title'] ?? '',
            category: n['category'] ?? 'GENERAL',
            desc: n['description'] ?? '',
            time: '10:00 AM',
            date: n['created_at'].toString().split('T')[0],
            icon: n['category'] == 'ACADEMIC'
                ? Icons.school_outlined
                : n['category'] == 'EXAMS'
                    ? Icons.description_outlined
                    : n['category'] == 'GENERAL'
                        ? Icons.campaign_outlined
                        : Icons.error_outline,
            iconColor: Colors.blue,
            bgColor: Colors.blue.shade50,
            borderColor: Colors.blue.shade100,
            categoryColor: Colors.blue,
            isNew: !(n['is_read'] ?? false),
            isRead: n['is_read'] ?? false,
          ));
        }
      }

      // Outings
      final dbOutings = results[5] as List<Map<String, dynamic>>;
      if (dbOutings.isNotEmpty) {
        _outings.clear();
        for (var o in dbOutings) {
          _outings.add(OutingRequestModel(
            id: o['id'].toString(),
            purpose: o['purpose'] ?? '',
            destination: o['destination'] ?? '',
            outTime: o['out_time'].toString().split('T').last.substring(0, 5),
            inTime: o['in_time'].toString().split('T').last.substring(0, 5),
            date: o['out_date'] ?? '',
            status: o['status'] ?? 'Pending',
          ));
        }
      }

      // Grievances
      final dbGrievances = results[6] as List<Map<String, dynamic>>;
      if (dbGrievances.isNotEmpty) {
        _grievances.clear();
        for (var g in dbGrievances) {
          _grievances.add(GrievanceItemModel(
            id: g['id'].toString(),
            category: g['category'] ?? '',
            subject: g['subject'] ?? '',
            description: g['description'] ?? '',
            recipient: g['recipient'] ?? 'HOD',
            priority: g['priority'] ?? 'Medium',
            date: g['date'] ?? (g['created_at'] != null ? g['created_at'].toString().split('T')[0] : ''),
            status: g['status'] ?? 'Pending',
            response: g['response'] ?? '',
          ));
        }
      }

      // Certificates
      final dbCertificates = results[7] as List<Map<String, dynamic>>;
      if (dbCertificates.isNotEmpty) {
        _certificates.clear();
        for (var c in dbCertificates) {
          _certificates.add(CertificateRequestModel(
            id: c['id'].toString(),
            type: c['certificate_type'] ?? '',
            reason: c['reason'] ?? '',
            requestDate: c['request_date'] ?? '',
            status: c['status'] ?? 'Pending',
            downloadUrl: c['download_url'],
          ));
        }
      }

      // Achievements
      final dbAchievements = results[8] as List<Map<String, dynamic>>;
      if (dbAchievements.isNotEmpty) {
        _achievements.clear();
        for (var a in dbAchievements) {
          _achievements.add(AchievementItemModel(
            id: a['id'].toString(),
            title: a['title'] ?? '',
            category: a['category'] ?? '',
            event: a['organized_by'] ?? '',
            date: a['date'] ?? '',
            description: a['description'] ?? '',
            status: a['status'] ?? 'Pending',
          ));
        }
      }

      // Extra courses & enrollments
      final dbExtraCourses = results[9] as List<Map<String, dynamic>>;
      final dbEnrollments = results[10] as List<Map<String, dynamic>>;
      final enrolledIds = dbEnrollments.map((e) => e['course_id'].toString()).toSet();
      if (dbExtraCourses.isNotEmpty) {
        _extraCourses.clear();
        for (var ec in dbExtraCourses) {
          _extraCourses.add(CourseItemModel(
            id: ec['id'].toString(),
            title: ec['title'] ?? '',
            provider: ec['provider'] ?? '',
            duration: ec['duration'] ?? '',
            category: ec['category'] ?? '',
            isEnrolled: enrolledIds.contains(ec['id'].toString()),
          ));
        }
      }

      // Placement drives & applications
      final dbPlacements = results[11] as List<Map<String, dynamic>>;
      final dbApps = results[12] as List<Map<String, dynamic>>;
      final appliedStatuses = {
        for (var a in dbApps) a['placement_id'].toString(): a['status']?.toString() ?? 'Applied'
      };
      if (dbPlacements.isNotEmpty) {
        _placements.clear();
        for (var p in dbPlacements) {
          final pid = p['id'].toString();
          final hasApplied = appliedStatuses.containsKey(pid);
          final companyObj = p['companies'];
          final companyName = (companyObj is Map ? companyObj['name'] : p['company']) ?? 'Unknown';
          final packageLpa = p['package_lpa']?.toString() ?? p['package']?.toString() ?? '';
          final packageStr = packageLpa.isNotEmpty ? '₹$packageLpa LPA' : '';
          final visitDate = p['visit_date']?.toString() ?? p['deadline']?.toString() ?? '';
          final stage = p['stage']?.toString() ?? 'Open';
          _placements.add(PlacementItemModel(
            id: pid,
            company: companyName,
            role: p['role'] ?? '',
            package: packageStr,
            deadline: visitDate,
            minCgpa: p['min_cgpa']?.toString() ?? '6.0',
            hasApplied: hasApplied,
            status: hasApplied ? appliedStatuses[pid]! : stage,
          ));
        }
      }

      // Notices & bookmarks
      final dbNotices = results[13] as List<Map<String, dynamic>>;
      final dbBookmarks = results[14] as List<Map<String, dynamic>>;
      final bookmarkedIds = dbBookmarks.map((b) => b['notice_id'].toString()).toSet();
      if (dbNotices.isNotEmpty) {
        _notices.clear();
        for (var n in dbNotices) {
          final attachUrl = n['attachment_url']?.toString() ?? '';
          _notices.add(NoticeItemModel(
            id: n['id'].toString(),
            title: n['title'] ?? '',
            category: n['category'] ?? '',
            date: n['post_date'] ?? '',
            time: '10:00 AM',
            author: n['author'] ?? 'Admin',
            content: n['content'] ?? '',
            isBookmarked: bookmarkedIds.contains(n['id'].toString()),
            isPinned: n['is_pinned'] == true,
            hasAttachment: attachUrl.isNotEmpty,
            attachmentName: attachUrl.split('/').last,
          ));
        }
      }

      // Fees
      final dbFees = results[15] as List<Map<String, dynamic>>;
      if (dbFees.isNotEmpty) {
        _fees.clear();
        for (var f in dbFees) {
          _fees.add(FeeItemModel(
            id: f['id'].toString(),
            title: f['title'] ?? '',
            category: f['category'] ?? '',
            amount: double.tryParse(f['amount']?.toString() ?? '0.0') ?? 0.0,
            dueDate: f['due_date'] ?? '',
            isPaid: f['is_paid'] ?? false,
            paymentDate: f['payment_date'],
            receiptNo: f['receipt_no'],
            academicYear: f['academic_year'] ?? '2025-26',
            semester: f['semester'] ?? 'V',
          ));
        }
      }

      // Library books
      final dbBooks = results[16] as List<Map<String, dynamic>>;
      _books.clear();
      if (dbBooks.isNotEmpty) {
        for (var b in dbBooks) {
          _books.add(BookModel(
            id: b['id'].toString(),
            title: b['title'] ?? '',
            author: b['author'] ?? '',
            isbn: b['isbn'] ?? '',
            category: b['category'] ?? '',
            isReserved: b['is_reserved'] == true,
            isIssued: b['is_issued'] == true,
            dueDate: b['due_date'],
          ));
        }
      } else {
        final mockBooksList = [
          BookModel(id: 'B1', title: 'Data Structures & Algorithms', author: 'Mark Allen Weiss', isbn: '978-0132847377', category: 'Computer Science'),
          BookModel(id: 'B2', title: 'Database System Concepts', author: 'Abraham Silberschatz', isbn: '978-0078022159', category: 'Database Systems'),
          BookModel(id: 'B3', title: 'Modern Operating Systems', author: 'Andrew S. Tanenbaum', isbn: '978-0133591620', category: 'Operating Systems'),
          BookModel(id: 'B4', title: 'Computer Networking: A Top-Down Approach', author: 'James Kurose, Keith Ross', isbn: '978-0136681557', category: 'Networking'),
          BookModel(id: 'B5', title: 'Software Engineering: A Practitioner\'s Approach', author: 'Roger S. Pressman', isbn: '978-1259872990', category: 'Software Engineering'),
          BookModel(id: 'B6', title: 'Artificial Intelligence: A Modern Approach', author: 'Stuart Russell, Peter Norvig', isbn: '978-0134610993', category: 'Artificial Intelligence'),
        ];
        _books.addAll(mockBooksList);
      }

      // Remaining states
      libraryTransactions = results[17] as List<Map<String, dynamic>>;
      marksList = results[18] as List<Map<String, dynamic>>;
      attendanceRecords = results[19] as List<Map<String, dynamic>>;
      timetables = results[20] as List<Map<String, dynamic>>;
      classTimetables = results[21] as List<Map<String, dynamic>>;
      if (classTimetables.isEmpty) {
        classTimetables = await SupabaseService.instance.getClassTimetables();
      }

      syllabusList = results[22] as List<Map<String, dynamic>>;
      courseMaterials = results[23] as List<Map<String, dynamic>>;
      assignmentsList = results[24] as List<Map<String, dynamic>>;
      assignmentMarks = results[25] as List<Map<String, dynamic>>;
      academicCalendarEvents = results[26] as List<Map<String, dynamic>>;
      lessonPlans = results[27] as List<Map<String, dynamic>>;
      faculties = results[28] as List<Map<String, dynamic>>;
      transportBuses = results[29] as List<Map<String, dynamic>>;
      studentTransportPass = results[30] as Map<String, dynamic>?;
      facultyCourseAllocations = results[31] as List<Map<String, dynamic>>;
      final regulations = results[32] as List<Map<String, dynamic>>;
      regulationsList = regulations;
      examSchedules = results[33] as List<Map<String, dynamic>>;

      final studentDept = getProfileField('department', defaultValue: 'CSE');
      final studentSec = getProfileField('section', defaultValue: 'A');
      final studentYear = getProfileField('year_of_study', defaultValue: 'III').toUpperCase();

      final regMap = {
        for (var r in regulations) r['course_code']?.toString() ?? '': r['course_name']?.toString() ?? ''
      };

      allocatedSubjects.clear();
      for (var alloc in facultyCourseAllocations) {
        final dept = alloc['department']?.toString().toUpperCase() ?? '';
        final sec = alloc['section']?.toString().toUpperCase() ?? '';
        final allocYear = (alloc['year_of_study'] ?? '').toString().toUpperCase();
        
        // Match department and section
        if (dept == studentDept.toUpperCase() && sec == studentSec.toUpperCase()) {
          // If year_of_study is specified, ensure it matches student's year (e.g. III)
          if (allocYear.isNotEmpty && allocYear != studentYear && allocYear != '3' && allocYear != '5') {
            continue;
          }
          final code = alloc['course_code']?.toString() ?? '';
          final name = regMap[code] ?? code;
          allocatedSubjects.add({
            'course_code': code,
            'subject_name': name,
            'department': dept,
            'section': sec,
            'year_of_study': allocYear.isNotEmpty ? allocYear : studentYear,
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching db data: $e');
    } finally {
      _isLoading = false;
      _isDataFetched = true;
      notifyListeners();
    }
  }

  // Academic Year State
  String _selectedAcademicYear = '2025-26';
  String get selectedAcademicYear => _selectedAcademicYear;

  bool get isCurrentAcademicYear =>
      _selectedAcademicYear.replaceAll('–', '-').replaceAll('—', '-').trim() == '2025-26';

  void setAcademicYear(String year) {
    if (_selectedAcademicYear == year) return;
    _selectedAcademicYear = year;
    SupabaseService.instance.selectedAcademicYear = year;
    notifyListeners();
    _fetchCalendarEventsOnly(year);
    if (isCurrentAcademicYear) {
      if (!_isDataFetched) {
        fetchAllData(force: false);
      }
    }
  }

  Future<void> _fetchCalendarEventsOnly(String year) async {
    try {
      academicCalendarEvents = await SupabaseService.instance.getAcademicCalendarEvents(year);
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching calendar events for non-current year: $e');
    }
  }

  void _clearAllDataForNon2025_26() {
    marksList = [];
    attendanceRecords = [];
    timetables = [];
    classTimetables = [];
    syllabusList = [];
    courseMaterials = [];
    assignmentsList = [];
    assignmentMarks = [];
    academicCalendarEvents = [];
    examSchedules = [];
    lessonPlans = [];
    faculties = [];
    libraryTransactions = [];
    transportBuses = [];
    studentTransportPass = null;
    allocatedSubjects = [];
    regulationsList = [];
    _notifications.clear();
    _fees.clear();
    _books.clear();
    _outings.clear();
    _grievances.clear();
    _certificates.clear();
    _achievements.clear();
    _extraCourses.clear();
    _placements.clear();
    _notices.clear();
    notifyListeners();
  }

  List<String> getAvailableSemestersForYear(String academicYear) {
    final year = academicYear.replaceAll('–', '-').replaceAll('—', '-').trim();
    if (year.contains('2023') || year == '2023-24') return ['I', 'II'];
    if (year.contains('2024') || year == '2024-25') return ['III', 'IV'];
    if (year.contains('2025') || year == '2025-26') return ['V', 'VI'];
    if (year.contains('2026') || year == '2026-27') return ['VII', 'VIII'];
    return ['III', 'IV', 'V', 'VI']; // Fallback
  }

  // User details
  String studentName = "";
  String studentId = "119519"; // DEVAROOPA (reg_no: 73152413035)
  String? dbStudentUuid;
  String activeRole = 'student';
  String personalEmail = "";
  String mobileNumber = "";
  String address = "";
  int yearOfStudy = 1;
  bool termCompleted = true;

  Map<String, dynamic>? studentProfileData;
  List<Map<String, dynamic>> studentFamilyList = [];
  List<Map<String, dynamic>> studentDocList = [];
  List<Map<String, dynamic>> studentFinancialList = [];
  List<Map<String, dynamic>> studentEducationList = [];
  List<Map<String, dynamic>> classTimetables = [];
  List<Map<String, dynamic>> facultyCourseAllocations = [];
  List<Map<String, dynamic>> courseMaterials = [];

  String getProfileField(String key, {String defaultValue = ''}) {
    if (studentProfileData != null && studentProfileData!.containsKey(key)) {
      final val = studentProfileData![key];
      if (val != null && val.toString().trim().isNotEmpty) {
        return val.toString();
      }
    }
    if (key == 'photo_url') {
      return 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&auto=format&fit=crop&q=80';
    }
    return defaultValue;
  }

  void updateProfile({String? name, required String email, required String phone, required String addr}) {
    if (name != null && name.isNotEmpty) studentName = name;
    personalEmail = email;
    mobileNumber = phone;
    address = addr;
    SupabaseService.instance.updateStudentProfile(dbStudentUuid ?? studentId, studentName, email, phone, addr);
    notifyListeners();
  }

  void setActiveRole(String role) {
    activeRole = role;
    notifyListeners();
  }

  // Notifications State
  String notificationFilter = 'All'; // All, Academic, Exams, General, Important

  final List<NotificationModel> _notifications = [];

  List<NotificationModel> get notifications => _notifications;

  List<NotificationModel> get filteredNotifications {
    if (notificationFilter == 'All') return _notifications;
    return _notifications.where((n) => n.category.toUpperCase() == notificationFilter.toUpperCase()).toList();
  }

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  int getCategoryCount(String filter) {
    if (filter == 'All') return _notifications.length;
    return _notifications.where((n) => n.category.toUpperCase() == filter.toUpperCase()).length;
  }

  void setNotificationFilter(String filter) {
    notificationFilter = filter;
    notifyListeners();
  }

  void markNotificationAsRead(String id) {
    _notifications.removeWhere((n) => n.id == id);
    SupabaseService.instance.markNotificationRead(id);
    notifyListeners();
  }

  void markAllNotificationsAsRead() {
    _notifications.clear();
    SupabaseService.instance.markAllNotificationsRead(dbStudentUuid ?? studentId);
    notifyListeners();
  }

  // Fees State
  final List<FeeItemModel> _fees = [];
  final Map<String, List<FeeItemModel>> _feesCache = {};

  List<FeeItemModel> get fees => _fees;

  double get pendingFeesTotal => _fees.where((f) => !f.isPaid).fold(0, (sum, item) => sum + item.amount);

  bool hasCachedFees(String? academicYear, String? semester) {
    final cacheKey = '${academicYear ?? "all"}_${semester ?? "all"}';
    return _feesCache.containsKey(cacheKey) && _feesCache[cacheKey]!.isNotEmpty;
  }

  Future<void> refreshFeesOnly({String? academicYear, String? semester}) async {
    final cacheKey = '${academicYear ?? "all"}_${semester ?? "all"}';

    // If cache exists, load immediately to update the UI instantly
    if (_feesCache.containsKey(cacheKey)) {
      _fees.clear();
      _fees.addAll(_feesCache[cacheKey]!);
      notifyListeners();
    }

    try {
      final studentIdCode = getProfileField('student_id').isNotEmpty
          ? getProfileField('student_id')
          : studentId;
      final activeUuid = dbStudentUuid ?? studentId;
      final targetStudentId = studentIdCode.isNotEmpty ? studentIdCode : activeUuid;

      List<Map<String, dynamic>> dbFees;
      if (academicYear != null && semester != null) {
        dbFees = await SupabaseService.instance.getFeesFiltered(
          studentIdCode: targetStudentId,
          academicYear: academicYear,
          semester: semester,
        );
      } else {
        dbFees = await SupabaseService.instance.getFees(targetStudentId);
      }

      final List<FeeItemModel> updatedFees = [];
      for (var f in dbFees) {
        updatedFees.add(FeeItemModel(
          id: f['id']?.toString() ?? '',
          title: f['title'] ?? '',
          category: f['category'] ?? '',
          amount: double.tryParse(f['amount']?.toString() ?? '0.0') ?? 0.0,
          dueDate: f['due_date']?.toString() ?? '',
          isPaid: f['is_paid'] == true,
          paymentDate: f['payment_date'],
          receiptNo: f['receipt_no'],
          academicYear: f['academic_year'] ?? '2025-26',
          semester: f['semester'] ?? 'V',
        ));
      }

      // Update cache
      _feesCache[cacheKey] = updatedFees;

      // Update active list and notify UI
      _fees.clear();
      _fees.addAll(updatedFees);
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing fees: $e');
    }
  }

  void payFee(String id) {
    final fee = _fees.firstWhere((f) => f.id == id);
    fee.isPaid = true;
    fee.paymentDate = DateTime.now().toString().split(' ')[0];
    fee.receiptNo = 'REC${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    SupabaseService.instance.payFee(id, fee.receiptNo!, fee.paymentDate!);
    notifyListeners();
  }

  // Library State
  final List<BookModel> _books = [];

  List<BookModel> get books => _books;

  void toggleBookReservation(String id) {
    final book = _books.firstWhere((b) => b.id == id);
    book.isReserved = !book.isReserved;
    if (book.isReserved) {
      final dueDateStr = DateTime.now().add(const Duration(days: 7)).toString().split(' ')[0];
      SupabaseService.instance.addLibraryTransaction(dbStudentUuid ?? studentId, id, 'Reserve', dueDateStr);
      // Locally add transaction
      libraryTransactions.insert(0, {
        'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
        'student_id': dbStudentUuid ?? studentId,
        'book_id': id,
        'type': 'Reserve',
        'due_date': dueDateStr,
        'is_active': true,
        'book_title': book.title,
        'book_author': book.author,
      });
    } else {
      // Remove reservation
      // In a real app we would set is_active = false or delete
    }
    notifyListeners();
  }

  void renewBook(String transactionId, String bookId) {
    final newDueDate = DateTime.now().add(const Duration(days: 14)).toString().split(' ')[0];
    SupabaseService.instance.renewLibraryBook(transactionId, newDueDate);
    // update local state
    final idx = libraryTransactions.indexWhere((t) => t['id'].toString() == transactionId);
    if (idx != -1) {
      libraryTransactions[idx]['due_date'] = newDueDate;
    }
    notifyListeners();
  }

  // Hostel State
  final List<OutingRequestModel> _outings = [];

  List<OutingRequestModel> get outings => _outings;

  void addOutingRequest(String purpose, String dest, String outT, String inT, String dt) {
    _outings.insert(0, OutingRequestModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      purpose: purpose,
      destination: dest,
      outTime: outT,
      inTime: inT,
      date: dt,
      status: 'Pending',
    ));
    SupabaseService.instance.addOutingRequest(dbStudentUuid ?? studentId, purpose, dest, outT, inT, dt);
    notifyListeners();
  }

  // Grievance State
  final List<GrievanceItemModel> _grievances = [];

  List<GrievanceItemModel> get grievances => _grievances;

  void addGrievance(String category, String subject, String description, [String? date, String? recipient, String? priority]) {
    final grievanceDate = date ?? DateTime.now().toString().split(' ')[0];
    final rec = recipient ?? 'HOD';
    final prio = priority ?? 'Medium';
    _grievances.insert(0, GrievanceItemModel(
      id: 'g${_grievances.length + 1}',
      category: category,
      subject: subject,
      description: description,
      recipient: rec,
      priority: prio,
      date: grievanceDate,
      status: 'Pending',
      response: '',
    ));

    final name = studentName;
    final roll = getProfileField('roll_no');
    final dept = getProfileField('department');
    final sec = getProfileField('section');
    final classSec = (dept.isNotEmpty && sec.isNotEmpty) ? '$dept - $sec' : dept;

    SupabaseService.instance.addGrievance(
      studentId: studentId,
      studentName: name,
      studentRoll: roll,
      classSec: classSec,
      category: category,
      subject: subject,
      description: description,
      recipient: rec,
      priority: prio,
      date: grievanceDate,
    );
    notifyListeners();
  }

  void replyToGrievance(String grievanceId, String replyMessage) {
    final idx = _grievances.indexWhere((g) => g.id == grievanceId);
    if (idx != -1) {
      final old = _grievances[idx];
      final dateStr = DateTime.now().toString().split(' ')[0];
      final newDesc = "${old.description}\n\n[Student Reply - $dateStr]: $replyMessage";
      final newStatus = (old.status.toLowerCase() == 'pending') ? 'In Review' : old.status;
      
      _grievances[idx] = GrievanceItemModel(
        id: old.id,
        category: old.category,
        subject: old.subject,
        description: newDesc,
        recipient: old.recipient,
        priority: old.priority,
        date: old.date,
        status: newStatus,
        response: old.response,
      );
      SupabaseService.instance.replyToGrievance(old.id, newDesc);
      notifyListeners();
    }
  }

  Future<void> refreshGrievances() async {
    final activeCode = studentProfileData?['student_id'] ?? studentId;
    final dbGrievances = await SupabaseService.instance.getGrievances(activeCode);
    if (dbGrievances.isNotEmpty) {
      _grievances.clear();
      for (var g in dbGrievances) {
        _grievances.add(GrievanceItemModel(
          id: g['id'].toString(),
          category: g['category'] ?? '',
          subject: g['subject'] ?? '',
          description: g['description'] ?? '',
          recipient: g['recipient'] ?? 'HOD',
          priority: g['priority'] ?? 'Medium',
          date: g['date'] ?? (g['created_at'] != null ? g['created_at'].toString().split('T')[0] : ''),
          status: g['status'] ?? 'Pending',
          response: g['response'] ?? '',
        ));
      }
      notifyListeners();
    }
  }

  Future<void> refreshAssignments() async {
    final activeUuid = dbStudentUuid ?? studentId;
    final regNoVal = getProfileField('register_no', defaultValue: activeUuid);
    assignmentsList = await SupabaseService.instance.getAssignments();
    assignmentMarks = await SupabaseService.instance.getAssignmentMarks(regNoVal, studentId: activeUuid);
    notifyListeners();
  }

  // Certificate State
  final List<CertificateRequestModel> _certificates = [];

  List<CertificateRequestModel> get certificates => _certificates;

  void addCertificateRequest(String type, String reason, [String? date]) {
    final reqDate = date ?? DateTime.now().toString().split(' ')[0];
    _certificates.insert(0, CertificateRequestModel(
      id: 'c${_certificates.length + 1}',
      type: type,
      reason: reason,
      requestDate: reqDate,
      status: 'Pending',
    ));
    SupabaseService.instance.addCertificateRequest(dbStudentUuid ?? studentId, type, reason, reqDate);
    notifyListeners();
  }

  void requestCertificate(String type, String reason, [String? date]) {
    addCertificateRequest(type, reason, date);
  }

  // Achievements State
  final List<AchievementItemModel> _achievements = [];

  List<AchievementItemModel> get achievements => _achievements;

  void addAchievement(String title, String category, String event, String date, String desc, {String? attachmentName, String? attachmentUrl}) {
    // Map categories to points
    int pts = 100;
    if (category.toLowerCase() == 'academic') pts = 150;
    if (category.toLowerCase() == 'sports') pts = 100;
    if (category.toLowerCase() == 'technical') pts = 120;
    if (category.toLowerCase() == 'cultural') pts = 80;
    if (category.toLowerCase() == 'certification') pts = 20;
    if (category.toLowerCase() == 'social') pts = 60;

    _achievements.insert(0, AchievementItemModel(
      id: 'a${_achievements.length + 1}',
      title: title,
      category: category,
      event: event,
      date: date,
      description: desc,
      status: 'Pending',
      points: pts,
      attachmentName: attachmentName,
      attachmentUrl: attachmentUrl,
    ));
    SupabaseService.instance.addAchievement(dbStudentUuid ?? studentId, title, category, event, date, desc);
    notifyListeners();
  }

  void approveAchievement(String id) {
    final idx = _achievements.indexWhere((a) => a.id == id);
    if (idx != -1) {
      _achievements[idx].status = 'Approved';
      notifyListeners();
    }
  }

  // Extra Courses State
  final List<CourseItemModel> _extraCourses = [];

  List<CourseItemModel> get extraCourses => _extraCourses;

  void toggleEnrollCourse(String id) {
    final course = _extraCourses.firstWhere((c) => c.id == id);
    course.isEnrolled = !course.isEnrolled;
    if (course.isEnrolled) {
      SupabaseService.instance.enrollExtraCourse(dbStudentUuid ?? studentId, id);
    }
    notifyListeners();
  }

  // Placement State
  final List<PlacementItemModel> _placements = [];

  List<PlacementItemModel> get placements => _placements;

  void applyPlacement(String id) {
    final p = _placements.firstWhere((item) => item.id == id);
    p.hasApplied = true;
    SupabaseService.instance.applyPlacement(dbStudentUuid ?? studentId, id);
    notifyListeners();
  }

  // Notice Board State
  final List<NoticeItemModel> _notices = [];

  List<NoticeItemModel> get notices => _notices;

  void toggleNoticeBookmark(String id) {
    final n = _notices.firstWhere((item) => item.id == id);
    n.isBookmarked = !n.isBookmarked;
    if (n.isBookmarked) {
      SupabaseService.instance.addNoticeBookmark(dbStudentUuid ?? studentId, id);
    } else {
      SupabaseService.instance.removeNoticeBookmark(dbStudentUuid ?? studentId, id);
    }
    notifyListeners();
  }

  // Medical State
  bool isBloodDonorRegistered = false;
  String? registeredBloodGroup;
  void registerBloodDonor([String? bloodGroup]) {
    isBloodDonorRegistered = true;
    if (bloodGroup != null) registeredBloodGroup = bloodGroup;
    notifyListeners();
  }
}

class AppStateProvider extends InheritedNotifier<AppState> {
  const AppStateProvider({
    super.key,
    required AppState appState,
    required super.child,
  }) : super(notifier: appState);

  static AppState of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<AppStateProvider>();
    return provider?.notifier ?? AppState.instance;
  }
}
