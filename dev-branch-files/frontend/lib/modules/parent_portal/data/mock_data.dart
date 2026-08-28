import '../models/models.dart';

class MockData {
  static final Parent currentParent = Parent(
    id: 'p1',
    name: 'Mr. R. Senthil Kumar',
    email: 'senthil.kumar@ksrce.ac.in',
    mobile: '+91 98765 43210',
    relationship: 'Father',
  );

  // ── Multiple Wards List ───────────────────────────────────────────────────
  static final List<Student> wards = [
    Student(
      id: 's1',
      name: 'RAVI S',
      registerNumber: '731521104045',
      department: 'Computer Science & Engineering',
      year: 'III Year',
      section: 'A',
      photoUrl: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=200&auto=format&fit=crop&q=80',
      mentor: 'Dr. S. Karthik, M.E., Ph.D.',
      mentorContact: '+91 94432 18901',
      gender: 'Male',
      dateOfBirth: DateTime(2004, 5, 14),
      bloodGroup: 'O+',
      religion: 'Hindu',
      motherTongue: 'Tamil',
      casteCategory: 'BC',
      aadharNumber: '7890 1234 5678',
      personalEmail: 'sridharan.cse21@ksrce.ac.in',
      mobileNumber: '+91 98421 67890',
      parentMobileNumber: '+91 98765 43210',
      permanentAddress: '14/B, Railway Colony, Erode, Tamil Nadu 638002',
      currentAddress: 'KSR Boys Hostel - Block C, Room 304',
      admissionDate: DateTime(2021, 8, 20),
      admissionType: 'Counselling',
      admissionMode: 'Government Quota',
      admissionStatus: 'Regular / Active',
      cgpa: 8.72,
      sgpa: 8.60,
      totalCredits: 156,
      hostelName: 'KSR Boys Hostel (Block C)',
      roomNumber: 'C-304',
      wardenName: 'Dr. P. Murugan',
    ),
    Student(
      id: 's2',
      name: 'ALICE JOHNSON',
      registerNumber: '731522205012',
      department: 'Information Technology',
      year: 'II Year',
      section: 'B',
      photoUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200&auto=format&fit=crop&q=80',
      mentor: 'Prof. M. Anita, M.Tech.',
      mentorContact: '+91 98433 11223',
      gender: 'Female',
      dateOfBirth: DateTime(2005, 3, 15),
      bloodGroup: 'A+',
      religion: 'Christian',
      motherTongue: 'English',
      casteCategory: 'General',
      aadharNumber: '1234 5678 9101',
      personalEmail: 'alice.it22@ksrce.ac.in',
      mobileNumber: '+91 87654 32100',
      parentMobileNumber: '+91 98765 43210',
      permanentAddress: '123 Main Street, Tiruchengode, Namakkal 637211',
      currentAddress: '123 Main Street, Tiruchengode, Namakkal 637211',
      admissionDate: DateTime(2022, 7, 15),
      admissionType: 'Management',
      admissionMode: 'Merit Based',
      admissionStatus: 'Regular / Active',
      cgpa: 9.15,
      sgpa: 9.20,
      totalCredits: 98,
      busNumber: 'Bus No. 12',
      route: 'Erode Bus Stand - KSR Campus',
      pickupPoint: 'Erode Collectorate Stop',
      pickupTime: '07:45 AM',
    ),
    Student(
      id: 's3',
      name: 'K. RAJESH KUMAR',
      registerNumber: '731523106089',
      department: 'Electrical & Electronics Engg',
      year: 'I Year',
      section: 'A',
      photoUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&auto=format&fit=crop&q=80',
      mentor: 'Dr. V. Arun Kumar',
      mentorContact: '+91 97888 55443',
      gender: 'Male',
      dateOfBirth: DateTime(2006, 11, 28),
      bloodGroup: 'B+',
      religion: 'Hindu',
      motherTongue: 'Tamil',
      casteCategory: 'MBC',
      aadharNumber: '4567 8901 2345',
      personalEmail: 'rajesh.eee23@ksrce.ac.in',
      mobileNumber: '+91 99444 33221',
      parentMobileNumber: '+91 98765 43210',
      permanentAddress: '56 Gandhi Nagar, Salem, Tamil Nadu 636007',
      currentAddress: 'KSR Boys Hostel - Block A, Room 102',
      admissionDate: DateTime(2023, 8, 10),
      admissionType: 'Counselling',
      admissionMode: 'Government Quota',
      admissionStatus: 'Regular / Active',
      cgpa: 8.10,
      sgpa: 8.05,
      totalCredits: 44,
      hostelName: 'KSR Boys Hostel (Block A)',
      roomNumber: 'A-102',
      wardenName: 'Prof. K. Ramesh',
    ),
  ];

  static Student _selectedStudent = wards.first;

  static Student get selectedStudent => _selectedStudent;

  static set selectedStudent(Student student) {
    _selectedStudent = student;
  }

  // Backward compatibility alias
  static Student get singleStudent => selectedStudent;

  // ── Dynamic Data Resolvers based on Selected Student ─────────────────────

  static Attendance get mockAttendance {
    if (_selectedStudent.id == 's2') {
      return Attendance(
        overallPercentage: 96.5,
        totalPresent: 193,
        totalAbsent: 7,
        subjectAttendance: [
          SubjectAttendance(subject: 'Data Structures & Algos', present: 50, absent: 1, percentage: 98.0, status: 'Good'),
          SubjectAttendance(subject: 'Database Management Systems', present: 48, absent: 2, percentage: 96.0, status: 'Good'),
          SubjectAttendance(subject: 'Computer Networks', present: 47, absent: 3, percentage: 94.0, status: 'Good'),
          SubjectAttendance(subject: 'Web Technologies Lab', present: 48, absent: 1, percentage: 98.0, status: 'Good'),
        ],
      );
    } else if (_selectedStudent.id == 's3') {
      return Attendance(
        overallPercentage: 82.4,
        totalPresent: 140,
        totalAbsent: 30,
        subjectAttendance: [
          SubjectAttendance(subject: 'Circuit Theory', present: 36, absent: 9, percentage: 80.0, status: 'Warning'),
          SubjectAttendance(subject: 'Engineering Physics', present: 38, absent: 7, percentage: 84.4, status: 'Warning'),
          SubjectAttendance(subject: 'Basic Mechanical Engg', present: 33, absent: 11, percentage: 75.0, status: 'Shortage'),
          SubjectAttendance(subject: 'Maths I - Calculus', present: 33, absent: 3, percentage: 91.6, status: 'Good'),
        ],
      );
    }
    // Default: Ravi (s1)
    return Attendance(
      overallPercentage: 94.2,
      totalPresent: 188,
      totalAbsent: 12,
      subjectAttendance: [
        SubjectAttendance(subject: 'Design & Analysis of Algorithms', present: 49, absent: 1, percentage: 98.0, status: 'Good'),
        SubjectAttendance(subject: 'Database Management Systems', present: 46, absent: 4, percentage: 92.0, status: 'Good'),
        SubjectAttendance(subject: 'Web Application Development', present: 48, absent: 2, percentage: 96.0, status: 'Good'),
        SubjectAttendance(subject: 'Software Engineering Principles', present: 45, absent: 5, percentage: 90.0, status: 'Good'),
      ],
    );
  }

  static List<double> get monthlyAttendancePercentages {
    if (_selectedStudent.id == 's2') return [94.0, 95.5, 97.0, 96.0, 98.0, 96.5];
    if (_selectedStudent.id == 's3') return [75.0, 78.0, 80.5, 82.0, 81.5, 82.4];
    return [88.0, 91.5, 93.0, 92.5, 95.0, 94.2];
  }

  static List<String> get attendanceMonths => ['Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug'];

  static AcademicPerformance get mockAcademicPerformance {
    if (_selectedStudent.id == 's2') {
      return AcademicPerformance(
        currentCgpa: 9.15,
        currentGpa: 9.20,
        currentSemester: 'Semester 3',
        internalMarks: [
          Mark(subject: 'Data Structures', internal1: '48/50', internal2: '49/50', assignment: '10/10', total: '107/110'),
          Mark(subject: 'DBMS', internal1: '47/50', internal2: '48/50', assignment: '10/10', total: '105/110'),
          Mark(subject: 'Computer Networks', internal1: '45/50', internal2: '46/50', assignment: '9/10', total: '100/110'),
        ],
        semesterGpas: [9.0, 9.25, 9.20],
      );
    } else if (_selectedStudent.id == 's3') {
      return AcademicPerformance(
        currentCgpa: 8.10,
        currentGpa: 8.05,
        currentSemester: 'Semester 1',
        internalMarks: [
          Mark(subject: 'Circuit Theory', internal1: '39/50', internal2: '41/50', assignment: '8/10', total: '88/110'),
          Mark(subject: 'Engineering Physics', internal1: '40/50', internal2: '42/50', assignment: '9/10', total: '91/110'),
          Mark(subject: 'Calculus & Algebra', internal1: '43/50', internal2: '45/50', assignment: '10/10', total: '98/110'),
        ],
        semesterGpas: [8.05],
      );
    }
    // Default: Ravi
    return AcademicPerformance(
      currentCgpa: 8.72,
      currentGpa: 8.60,
      currentSemester: 'Semester 5',
      internalMarks: [
        Mark(subject: 'Design & Analysis of Algorithms', internal1: '46/50', internal2: '47/50', assignment: '10/10', total: '103/110'),
        Mark(subject: 'Database Systems', internal1: '43/50', internal2: '44/50', assignment: '9/10', total: '96/110'),
        Mark(subject: 'Web Application Dev', internal1: '48/50', internal2: '49/50', assignment: '10/10', total: '107/110'),
        Mark(subject: 'Software Engineering', internal1: '42/50', internal2: '45/50', assignment: '9/10', total: '96/110'),
      ],
      semesterGpas: [8.5, 8.65, 8.8, 8.55, 8.60],
    );
  }

  static List<Exam> get upcomingExams {
    final now = DateTime.now();
    return [
      Exam(subject: 'Database Systems Lab', date: now.add(const Duration(days: 4)), time: '09:30 AM - 12:30 PM', venue: 'CS Lab 3 (2nd Floor)'),
      Exam(subject: 'Algorithms & Complexity', date: now.add(const Duration(days: 9)), time: '10:00 AM - 01:00 PM', venue: 'Main Exam Hall B-12'),
      Exam(subject: 'Web Architecture & Services', date: now.add(const Duration(days: 14)), time: '10:00 AM - 01:00 PM', venue: 'Main Exam Hall B-14'),
    ];
  }

  static List<ExamResult> get mockResults {
    return [
      ExamResult(
        semester: 'Semester 4',
        gpa: 8.55,
        resultStatus: 'Pass / First Class Distinction',
        pdfUrl: null, // Document not yet available in Firebase Storage
      ),
      ExamResult(
        semester: 'Semester 3',
        gpa: 8.80,
        resultStatus: 'Pass / First Class',
        pdfUrl: null, // Document not yet available in Firebase Storage
      ),
      ExamResult(
        semester: 'Semester 2',
        gpa: 8.65,
        resultStatus: 'Pass / First Class',
        pdfUrl: null, // Document not yet available in Firebase Storage
      ),
      ExamResult(
        semester: 'Semester 1',
        gpa: 8.50,
        resultStatus: 'Pass / First Class',
        pdfUrl: null, // Document not yet available in Firebase Storage
      ),
    ];
  }

  static Fee get mockFees {
    if (_selectedStudent.id == 's2') {
      return Fee(
        totalFees: 110000,
        paid: 110000,
        pending: 0,
        dueDate: DateTime.now().add(const Duration(days: 45)),
        history: [
          PaymentHistory(
            receiptId: 'REC-2026-8901',
            date: DateTime.now().subtract(const Duration(days: 20)),
            amount: 55000,
            status: 'Success',
            description: 'Even Sem Tuition & Special Fees',
            receiptUrl: null, // Receipt PDF not yet available in Firebase Storage
          ),
          PaymentHistory(
            receiptId: 'REC-2025-4421',
            date: DateTime.now().subtract(const Duration(days: 180)),
            amount: 55000,
            status: 'Success',
            description: 'Odd Sem Tuition Fees',
            receiptUrl: null, // Receipt PDF not yet available in Firebase Storage
          ),
        ],
      );
    }
    // Ravi
    return Fee(
      totalFees: 135000,
      paid: 122500,
      pending: 12500,
      dueDate: DateTime.now().add(const Duration(days: 12)),
      history: [
        PaymentHistory(
          receiptId: 'REC-2026-9042',
          date: DateTime.now().subtract(const Duration(days: 25)),
          amount: 65000,
          status: 'Success',
          description: 'Term 1 Tuition & Lab Fees',
          receiptUrl: null, // Receipt PDF not yet available in Firebase Storage
        ),
        PaymentHistory(
          receiptId: 'REC-2026-9043',
          date: DateTime.now().subtract(const Duration(days: 25)),
          amount: 57500,
          status: 'Success',
          description: 'Hostel & Mess Maintenance Fees',
          receiptUrl: null, // Receipt PDF not yet available in Firebase Storage
        ),
      ],
    );
  }

  static List<LeaveRequest> get mockLeaveRequests => [
    LeaveRequest(
      id: 'lr-101',
      requestType: 'Outpass',
      fromDate: DateTime.now().add(const Duration(days: 1, hours: 8)),
      toDate: DateTime.now().add(const Duration(days: 1, hours: 18)),
      reason: 'Weekend local outing & purchasing technical project components.',
      submittedDate: DateTime.now().subtract(const Duration(hours: 12)),
      status: 'Approved',
    ),
    LeaveRequest(
      id: 'lr-102',
      requestType: 'Leave',
      fromDate: DateTime.now().add(const Duration(days: 6)),
      toDate: DateTime.now().add(const Duration(days: 8)),
      reason: 'Attending State-Level Technical Symposium & Paper Presentation.',
      submittedDate: DateTime.now().subtract(const Duration(days: 2)),
      status: 'Pending',
    ),
    LeaveRequest(
      id: 'lr-100',
      requestType: 'Leave',
      fromDate: DateTime.now().subtract(const Duration(days: 15)),
      toDate: DateTime.now().subtract(const Duration(days: 13)),
      reason: 'Medical Leave - Viral Fever (Doctor Note Uploaded).',
      submittedDate: DateTime.now().subtract(const Duration(days: 16)),
      status: 'Approved',
    ),
  ];

  static List<AppNotification> get mockNotifications => [
    AppNotification(
      id: 'n1',
      title: 'Attendance Shortage Alert',
      description: 'Your ward Ravi requires 85% min attendance in DBMS. Current is 92%. Maintain good standing.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
      category: 'Attendance',
    ),
    AppNotification(
      id: 'n2',
      title: 'End-Semester Timetable Published',
      description: 'The schedule for Semester 5 Laboratory and Theory exams is live in the Exams portal.',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      category: 'Exams',
      isRead: false,
    ),
    AppNotification(
      id: 'n3',
      title: 'Fee Installment Reminder',
      description: 'Pending balance of ₹12,500 for Hostel & Tuition is due on 25th August 2026.',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      category: 'Fees',
      isRead: true,
    ),
    AppNotification(
      id: 'n4',
      title: 'Leave Request Approved',
      description: 'Outpass request #lr-101 for local outing on tomorrow has been approved by Warden.',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      category: 'Outpass',
      isRead: true,
    ),
  ];

  static List<TimetableEntry> get mockTimetable => [
    TimetableEntry(time: '09:00 AM - 09:50 AM', subject: 'Design & Analysis of Algorithms', faculty: 'Dr. S. Karthik', room: 'CS-204', dayOfWeek: 1),
    TimetableEntry(time: '09:50 AM - 10:40 AM', subject: 'Database Management Systems', faculty: 'Prof. K. Ravi', room: 'CS-204', dayOfWeek: 1),
    TimetableEntry(time: '11:00 AM - 11:50 AM', subject: 'Web Architecture & Services', faculty: 'Dr. V. Arun', room: 'CS Lab 3', dayOfWeek: 1),
    TimetableEntry(time: '11:50 AM - 12:40 PM', subject: 'Software Engineering Principles', faculty: 'Prof. M. Anita', room: 'CS-204', dayOfWeek: 1),
    TimetableEntry(time: '01:40 PM - 03:20 PM', subject: 'DBMS Laboratory Session', faculty: 'Prof. K. Ravi / Dr. S. Karthik', room: 'Database Lab', dayOfWeek: 1),
    TimetableEntry(time: '03:30 PM - 04:20 PM', subject: 'Aptitude & Technical Seminar', faculty: 'Placement Cell', room: 'Seminar Hall B', dayOfWeek: 1),
  ];

  static List<Assignment> get mockAssignments => [
    Assignment(
      id: 'a1',
      subject: 'Database Systems',
      title: 'ER Diagram & Relational Schema Design for College ERP',
      dueDate: DateTime.now().add(const Duration(days: 3)),
      status: 'Pending',
      attachmentUrl: null, // Attachment not yet available in Firebase Storage
    ),
    Assignment(
      id: 'a2',
      subject: 'Algorithms',
      title: 'Dynamic Programming & Knapsack Problem Implementations',
      dueDate: DateTime.now().add(const Duration(days: 6)),
      status: 'Pending',
      attachmentUrl: null, // Attachment not yet available in Firebase Storage
    ),
    Assignment(
      id: 'a3',
      subject: 'Web Development',
      title: 'Responsive Dashboard Component Prototype',
      dueDate: DateTime.now().subtract(const Duration(days: 2)),
      status: 'Submitted',
      attachmentUrl: null, // Attachment not yet available in Firebase Storage
    ),
    Assignment(
      id: 'a4',
      subject: 'Software Engg',
      title: 'Agile User Stories & Requirement Traceability Matrix',
      dueDate: DateTime.now().subtract(const Duration(days: 7)),
      status: 'Submitted',
      attachmentUrl: null, // Attachment not yet available in Firebase Storage
    ),
  ];

  static List<Notice> get mockNotices => [
    Notice(
      id: 'no1',
      title: 'National Level Technical Symposium - INNOVISION 2026',
      date: DateTime.now().add(const Duration(days: 15)),
      category: 'College Fest',
      description: 'KSRCE invites paper presentations, hackathons, and project expos across all departments.',
      pdfUrl: null, // Circular PDF not yet available in Firebase Storage
    ),
    Notice(
      id: 'no2',
      title: 'Campus Placement Drive by Top Tech Enterprise',
      date: DateTime.now().add(const Duration(days: 8)),
      category: 'Placement',
      description: 'Pre-placement talk and coding round for 3rd and 4th year CSE/IT students.',
      pdfUrl: null, // Circular PDF not yet available in Firebase Storage
    ),
    Notice(
      id: 'no3',
      title: 'Autonomous Academic Council Exam Rules Update',
      date: DateTime.now().subtract(const Duration(days: 3)),
      category: 'Academic',
      description: 'Mandatory minimum 85% attendance rule strict enforcement for Semester 5 end-term exams.',
      pdfUrl: null, // Circular PDF not yet available in Firebase Storage
    ),
  ];

  static List<AppDocument> get mockDocuments => [
    AppDocument(
      id: 'doc-1',
      name: 'Semester 4 Official Grade Sheet / Marksheet',
      date: DateTime.now().subtract(const Duration(days: 45)),
      fileType: 'PDF',
      category: 'Academic Marksheets',
      fileUrl: null, // Document not yet available in Firebase Storage
    ),
    AppDocument(
      id: 'doc-2',
      name: 'Term 1 Tuition & Lab Fee Receipt (#REC-9042)',
      date: DateTime.now().subtract(const Duration(days: 25)),
      fileType: 'PDF',
      category: 'Fee Receipts',
      fileUrl: null, // Document not yet available in Firebase Storage
    ),
    AppDocument(
      id: 'doc-3',
      name: 'Hostel Resident ID & Bonafide Certificate',
      date: DateTime.now().subtract(const Duration(days: 120)),
      fileType: 'PDF',
      category: 'Identity & Certificates',
      fileUrl: null, // Document not yet available in Firebase Storage
    ),
    AppDocument(
      id: 'doc-4',
      name: 'Semester 5 Mid-Term Examination Hall Ticket',
      date: DateTime.now().subtract(const Duration(days: 10)),
      fileType: 'PDF',
      category: 'Hall Tickets',
      fileUrl: null, // Document not yet available in Firebase Storage
    ),
  ];

  static List<PeriodAttendance> get mockPeriodAttendance => [
    PeriodAttendance(date: DateTime(2026, 8, 13), period: 1, subject: 'Design & Analysis of Algorithms', status: 'Present'),
    PeriodAttendance(date: DateTime(2026, 8, 13), period: 2, subject: 'Database Management Systems', status: 'Present'),
    PeriodAttendance(date: DateTime(2026, 8, 13), period: 3, subject: 'Web Architecture & Services', status: 'Present'),
    PeriodAttendance(date: DateTime(2026, 8, 13), period: 4, subject: 'Software Engineering Principles', status: 'Present'),
    PeriodAttendance(date: DateTime(2026, 8, 12), period: 1, subject: 'Design & Analysis of Algorithms', status: 'Present'),
    PeriodAttendance(date: DateTime(2026, 8, 12), period: 2, subject: 'Database Management Systems', status: 'Present'),
    PeriodAttendance(date: DateTime(2026, 8, 12), period: 3, subject: 'Web Architecture & Services', status: 'Absent'),
    PeriodAttendance(date: DateTime(2026, 8, 12), period: 4, subject: 'Software Engineering Principles', status: 'Present'),
  ];

  static ClassAttendance get mockClassAttendance => ClassAttendance(
    classStrength: 64,
    presentStudents: 59,
    absentStudents: 5,
  );
}

