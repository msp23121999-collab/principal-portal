import 'package:flutter/material.dart';

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

  FeeItemModel({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.dueDate,
    this.isPaid = false,
    this.paymentDate,
    this.receiptNo,
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
  final String date;
  String status; // Pending, In Progress, Resolved
  final String response;

  String get title => subject;

  GrievanceItemModel({
    required this.id,
    required this.category,
    required this.subject,
    required this.description,
    required this.date,
    this.status = 'Pending',
    this.response = 'Under review by student welfare committee.',
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
  final String status;

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

  NoticeItemModel({
    required this.id,
    required this.title,
    required this.category,
    required this.date,
    this.time = '10:00 AM',
    this.author = 'Admin',
    required this.content,
    this.isBookmarked = false,
  });
}
typedef NoticeModel = NoticeItemModel;


class AppState extends ChangeNotifier {
  static AppState? _instance;
  static AppState get instance => _instance ??= AppState._();

  AppState._();

  // User details
  String studentName = "Demo Student";
  String studentId = "STU2024001";
  String activeRole = 'student';
  String personalEmail = "john.doe@personal.com";
  String mobileNumber = "9876543210";
  String address = "123 Campus Drive, Tech City, State - 600001";

  void updateProfile({required String email, required String phone, required String addr}) {
    personalEmail = email;
    mobileNumber = phone;
    address = addr;
    notifyListeners();
  }

  void setActiveRole(String role) {
    activeRole = role;
    notifyListeners();
  }

  // Notifications State
  String notificationFilter = 'All'; // All, Academic, Exams, General, Important

  final List<NotificationModel> _notifications = [
    NotificationModel(
      id: '1',
      title: 'Attendance Warning',
      category: 'ACADEMIC',
      desc: 'Attendance warning issued for Mathematics II. Your current attendance is 72%. Attend upcoming classes.',
      time: '10:30 AM',
      date: 'May 16, 2024',
      icon: Icons.error_outline,
      iconColor: const Color(0xFFF59E0B),
      bgColor: const Color(0xFFFFFBEB),
      borderColor: const Color(0xFFFEF3C7),
      categoryColor: const Color(0xFFF59E0B),
      isNew: true,
      isRead: false,
    ),
    NotificationModel(
      id: '2',
      title: 'Hall Ticket Published',
      category: 'EXAMS',
      desc: 'Hall ticket published for semester exams. Please download and verify your details before May 20.',
      time: '09:15 AM',
      date: 'May 16, 2024',
      icon: Icons.description_outlined,
      iconColor: const Color(0xFF1D4ED8),
      bgColor: const Color(0xFFEFF6FF),
      borderColor: const Color(0xFFDBEAFE),
      categoryColor: const Color(0xFF3B82F6),
      isNew: true,
      isRead: false,
    ),
    NotificationModel(
      id: '3',
      title: 'Results Published',
      category: 'GENERAL',
      desc: 'New result has been published. Check your semester results now in the Marks section.',
      time: '08:45 AM',
      date: 'May 16, 2024',
      icon: Icons.check_circle_outline,
      iconColor: const Color(0xFF10B981),
      bgColor: const Color(0xFFF0FDF4),
      borderColor: const Color(0xFFDCFCE7),
      categoryColor: const Color(0xFF10B981),
      isNew: true,
      isRead: false,
    ),
  ];

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
    final notifIndex = _notifications.indexWhere((n) => n.id == id);
    if (notifIndex != -1) {
      _notifications[notifIndex].isRead = true;
      _notifications[notifIndex].isNew = false;
      notifyListeners();
    }
  }

  void markAllNotificationsAsRead() {
    for (var n in _notifications) {
      n.isRead = true;
      n.isNew = false;
    }
    notifyListeners();
  }

  // Fees State
  final List<FeeItemModel> _fees = [
    FeeItemModel(id: 'f1', title: 'Tuition Fee - Semester 4', category: 'Tuition', amount: 20000.0, dueDate: '30 May 2024'),
    FeeItemModel(id: 'f2', title: 'Exam Fee - April 2024', category: 'Exam', amount: 3500.0, dueDate: '15 Jun 2024'),
    FeeItemModel(id: 'f3', title: 'Library Fine / Renewal Fee', category: 'Library', amount: 1500.0, dueDate: '20 May 2024'),
    FeeItemModel(id: 'f4', title: 'Hostel Maintenance Fee', category: 'Hostel', amount: 5000.0, dueDate: '10 Jun 2024', isPaid: true, paymentDate: '01 May 2024', receiptNo: 'REC89201'),
  ];

  List<FeeItemModel> get fees => _fees;

  double get pendingFeesTotal => _fees.where((f) => !f.isPaid).fold(0, (sum, item) => sum + item.amount);

  void payFee(String id) {
    final fee = _fees.firstWhere((f) => f.id == id);
    fee.isPaid = true;
    fee.paymentDate = DateTime.now().toString().split(' ')[0];
    fee.receiptNo = 'REC${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    notifyListeners();
  }

  // Library State
  final List<BookModel> _books = [
    BookModel(id: 'b1', title: 'Data Structures and Algorithms', author: 'Mark Allen Weiss', isbn: '978-0132847377', category: 'Computer Science', isIssued: true, dueDate: '28 May 2024'),
    BookModel(id: 'b2', title: 'Clean Code: Handbook of Agile Software Craftsmanship', author: 'Robert C. Martin', isbn: '978-0132350884', category: 'Software Engineering'),
    BookModel(id: 'b3', title: 'Artificial Intelligence: A Modern Approach', author: 'Stuart Russell', isbn: '978-0134610993', category: 'AI & ML'),
    BookModel(id: 'b4', title: 'Operating System Concepts', author: 'Abraham Silberschatz', isbn: '978-1118063330', category: 'Operating Systems'),
  ];

  List<BookModel> get books => _books;

  void toggleBookReservation(String id) {
    final book = _books.firstWhere((b) => b.id == id);
    book.isReserved = !book.isReserved;
    notifyListeners();
  }

  void renewBook(String id) {
    final book = _books.firstWhere((b) => b.id == id);
    book.dueDate = '15 Jun 2024';
    notifyListeners();
  }

  // Hostel State
  final List<OutingRequestModel> _outings = [
    OutingRequestModel(id: 'o1', purpose: 'Weekend Home Visit', destination: 'Coimbatore', outTime: '09:00 AM', inTime: '06:00 PM', date: '18 May 2024', status: 'Approved'),
    OutingRequestModel(id: 'o2', purpose: 'Medical Checkup', destination: 'City Center Hospital', outTime: '10:00 AM', inTime: '02:00 PM', date: '22 May 2024', status: 'Pending'),
  ];

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
    notifyListeners();
  }

  // Grievance State
  final List<GrievanceItemModel> _grievances = [
    GrievanceItemModel(id: 'g1', category: 'Academic', subject: 'Marks Discrepancy in Mid-Term', description: 'Internal assessment marks recorded incorrectly.', date: '10 May 2024', status: 'In Progress'),
    GrievanceItemModel(id: 'g2', category: 'Hostel', subject: 'WiFi Connectivity Issue', description: 'Hostel Block B 3rd floor WiFi signal frequent drops.', date: '02 May 2024', status: 'Resolved', response: 'Router replaced on May 4.'),
  ];

  List<GrievanceItemModel> get grievances => _grievances;

  void addGrievance(String category, String subject, String description, [String? date]) {
    _grievances.insert(0, GrievanceItemModel(
      id: 'g${_grievances.length + 1}',
      category: category,
      subject: subject,
      description: description,
      date: date ?? DateTime.now().toString().split(' ')[0],
      status: 'Pending',
    ));
    notifyListeners();
  }

  // Certificate State
  final List<CertificateRequestModel> _certificates = [
    CertificateRequestModel(id: 'c1', type: 'Bonafide Certificate', reason: 'Passport Application', requestDate: '12 May 2024', status: 'Approved', downloadUrl: 'bonafide.pdf'),
    CertificateRequestModel(id: 'c2', type: 'Transcript of Records', reason: 'Higher Studies Application', requestDate: '15 May 2024', status: 'Pending'),
  ];

  List<CertificateRequestModel> get certificates => _certificates;

  void addCertificateRequest(String type, String reason, [String? date]) {
    _certificates.insert(0, CertificateRequestModel(
      id: 'c${_certificates.length + 1}',
      type: type,
      reason: reason,
      requestDate: date ?? DateTime.now().toString().split(' ')[0],
      status: 'Pending',
    ));
    notifyListeners();
  }

  void requestCertificate(String type, String reason, [String? date]) {
    addCertificateRequest(type, reason, date);
  }

  // Achievements State
  final List<AchievementItemModel> _achievements = [
    AchievementItemModel(id: 'a1', title: 'National Hackathon 1st Runner Up', category: 'Academic', event: 'Smart India Hackathon 2024', date: 'March 2024', description: 'Developed AI-driven agriculture prediction system.'),
    AchievementItemModel(id: 'a2', title: 'Inter-College Badminton Winner', category: 'Sports', event: 'Annual Sports Meet 2024', date: 'February 2024', description: 'Secured Gold Medal in Men\'s Singles Badminton.'),
  ];

  List<AchievementItemModel> get achievements => _achievements;

  void addAchievement(String title, String category, String event, String date, String desc) {
    _achievements.insert(0, AchievementItemModel(
      id: 'a${_achievements.length + 1}',
      title: title,
      category: category,
      event: event,
      date: date,
      description: desc,
    ));
    notifyListeners();
  }

  // Extra Courses State
  final List<CourseItemModel> _extraCourses = [
    CourseItemModel(id: 'ec1', title: 'Flutter & Dart Deep Dive', provider: 'Google Developers', duration: '6 Weeks', category: 'Technical', isEnrolled: true),
    CourseItemModel(id: 'ec2', title: 'Cloud Architecture & AWS Certification', provider: 'AWS Academy', duration: '8 Weeks', category: 'Technical'),
    CourseItemModel(id: 'ec3', title: 'Professional Communication & Public Speaking', provider: 'Humanities Dept', duration: '4 Weeks', category: 'Soft Skills'),
  ];

  List<CourseItemModel> get extraCourses => _extraCourses;

  void toggleEnrollCourse(String id) {
    final course = _extraCourses.firstWhere((c) => c.id == id);
    course.isEnrolled = !course.isEnrolled;
    notifyListeners();
  }

  // Placement State
  final List<PlacementItemModel> _placements = [
    PlacementItemModel(id: 'p1', company: 'Google Inc.', role: 'Associate Software Engineer', package: '₹18 LPA', deadline: '25 May 2024'),
    PlacementItemModel(id: 'p2', company: 'Microsoft', role: 'Support Engineer', package: '₹14 LPA', deadline: '30 May 2024', hasApplied: true),
    PlacementItemModel(id: 'p3', company: 'Amazon', role: 'SDE-1', package: '₹22 LPA', deadline: '05 Jun 2024'),
  ];

  List<PlacementItemModel> get placements => _placements;

  void applyPlacement(String id) {
    final p = _placements.firstWhere((item) => item.id == id);
    p.hasApplied = true;
    notifyListeners();
  }

  // Notice Board State
  final List<NoticeItemModel> _notices = [
    NoticeItemModel(id: 'n1', title: 'Holiday on 15 Aug 2024', category: 'General', date: 'May 16, 2024', content: 'College will remain closed on the occasion of Independence Day.'),
    NoticeItemModel(id: 'n2', title: 'End Semester Exam Schedule Released', category: 'Examinations', date: 'May 14, 2024', content: 'The final timetable for April/May 2024 semester examinations is now available.'),
    NoticeItemModel(id: 'n3', title: 'Annual Cultural Fest - Rhythm 2024', category: 'Events', date: 'May 10, 2024', content: 'Registrations are open for events in Rhythm 2024. Contact student coordinator.'),
  ];

  List<NoticeItemModel> get notices => _notices;

  void toggleNoticeBookmark(String id) {
    final n = _notices.firstWhere((item) => item.id == id);
    n.isBookmarked = !n.isBookmarked;
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
