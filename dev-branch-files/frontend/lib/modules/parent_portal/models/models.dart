class Parent {
  final String id;
  final String name;
  final String email;
  final String mobile;
  final String relationship;

  Parent({
    required this.id,
    required this.name,
    required this.email,
    required this.mobile,
    required this.relationship,
  });
}

class Student {
  final String id;
  final String name;
  final String registerNumber;
  final String department;
  final String year;
  final String section;
  final String photoUrl;
  final String mentor;
  final String mentorContact;
  
  // Personal Information
  final String? gender;
  final DateTime? dateOfBirth;
  final String? bloodGroup;
  final String? religion;
  final String? motherTongue;
  final String? casteCategory;
  final String? aadharNumber;
  
  // Contact Information
  final String? personalEmail;
  final String? mobileNumber;
  final String? parentMobileNumber;
  final String? permanentAddress;
  final String? currentAddress;
  
  // Admission Details
  final DateTime? admissionDate;
  final String? admissionType;
  final String? admissionMode;
  final String? admissionStatus;
  
  // Academic Details
  final double? cgpa;
  final double? sgpa;
  final int? totalCredits;
  
  // Additional info for hostel/transport
  final String? hostelName;
  final String? roomNumber;
  final String? wardenName;
  final String? busNumber;
  final String? route;
  final String? pickupPoint;
  final String? pickupTime;

  Student({
    required this.id,
    required this.name,
    required this.registerNumber,
    required this.department,
    required this.year,
    required this.section,
    required this.photoUrl,
    required this.mentor,
    required this.mentorContact,
    this.gender,
    this.dateOfBirth,
    this.bloodGroup,
    this.religion,
    this.motherTongue,
    this.casteCategory,
    this.aadharNumber,
    this.personalEmail,
    this.mobileNumber,
    this.parentMobileNumber,
    this.permanentAddress,
    this.currentAddress,
    this.admissionDate,
    this.admissionType,
    this.admissionMode,
    this.admissionStatus,
    this.cgpa,
    this.sgpa,
    this.totalCredits,
    this.hostelName,
    this.roomNumber,
    this.wardenName,
    this.busNumber,
    this.route,
    this.pickupPoint,
    this.pickupTime,
  });

  /// Returns true when the student lives in the hostel.
  /// Determined by the presence of a hostelName value.
  bool get isHosteller => hostelName != null && hostelName!.isNotEmpty;
}

class SubjectAttendance {
  final String subject;
  final int present;
  final int absent;
  final double percentage;
  final String status;

  SubjectAttendance({
    required this.subject,
    required this.present,
    required this.absent,
    required this.percentage,
    required this.status,
  });
}

class Attendance {
  final double overallPercentage;
  final int totalPresent;
  final int totalAbsent;
  final List<SubjectAttendance> subjectAttendance;

  Attendance({
    required this.overallPercentage,
    required this.totalPresent,
    required this.totalAbsent,
    required this.subjectAttendance,
  });
}

class Mark {
  final String subject;
  final String internal1;
  final String internal2;
  final String assignment;
  final String total;

  Mark({
    required this.subject,
    required this.internal1,
    required this.internal2,
    required this.assignment,
    required this.total,
  });
}

class AcademicPerformance {
  final double currentCgpa;
  final double currentGpa;
  final String currentSemester;
  final List<Mark> internalMarks;
  final List<double> semesterGpas; // For trend chart

  AcademicPerformance({
    required this.currentCgpa,
    required this.currentGpa,
    required this.currentSemester,
    required this.internalMarks,
    required this.semesterGpas,
  });
}

class Exam {
  final String subject;
  final DateTime date;
  final String time;
  final String venue;

  Exam({
    required this.subject,
    required this.date,
    required this.time,
    required this.venue,
  });
}

class ExamResult {
  final String semester;
  final double gpa;
  final String resultStatus;
  final String? pdfUrl; // URL to the semester result/grade sheet PDF

  ExamResult({
    required this.semester,
    required this.gpa,
    required this.resultStatus,
    this.pdfUrl,
  });
}

class Fee {
  final double totalFees;
  final double paid;
  final double pending;
  final DateTime dueDate;
  final List<PaymentHistory> history;

  Fee({
    required this.totalFees,
    required this.paid,
    required this.pending,
    required this.dueDate,
    required this.history,
  });
}

class PaymentHistory {
  final String receiptId;
  final DateTime date;
  final double amount;
  final String status;
  final String description;
  final String? receiptUrl; // URL to the receipt PDF

  PaymentHistory({
    required this.receiptId,
    required this.date,
    required this.amount,
    required this.status,
    required this.description,
    this.receiptUrl,
  });
}

class LeaveRequest {
  final String id;
  final String requestType; // Leave or Outpass
  final DateTime fromDate;
  final DateTime toDate;
  final String reason;
  final DateTime submittedDate;
  String status; // Pending, Approved, Rejected

  LeaveRequest({
    required this.id,
    required this.requestType,
    required this.fromDate,
    required this.toDate,
    required this.reason,
    required this.submittedDate,
    required this.status,
  });
}

class AppNotification {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final String category; // e.g. Attendance, Fees, Exams
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.category,
    this.isRead = false,
  });
}

class TimetableEntry {
  final String time;
  final String subject;
  final String faculty;
  final String room;
  final int dayOfWeek; // 1 = Mon, 5 = Fri

  TimetableEntry({
    required this.time,
    required this.subject,
    required this.faculty,
    required this.room,
    required this.dayOfWeek,
  });
}

class Assignment {
  final String id;
  final String subject;
  final String title;
  final DateTime dueDate;
  final String status; // Pending, Submitted, Overdue
  final String? attachmentUrl; // URL to the assignment PDF/document

  Assignment({
    required this.id,
    required this.subject,
    required this.title,
    required this.dueDate,
    required this.status,
    this.attachmentUrl,
  });
}

class Notice {
  final String id;
  final String title;
  final DateTime date;
  final String category; // College, Department
  final String description;
  final String? pdfUrl; // URL to the official circular PDF

  Notice({
    required this.id,
    required this.title,
    required this.date,
    required this.category,
    required this.description,
    this.pdfUrl,
  });
}

class AppDocument {
  final String id;
  final String name;
  final DateTime date;
  final String fileType;
  final String category; // Academic, Fee, Institutional
  final String? fileUrl; // URL to the document PDF/file

  AppDocument({
    required this.id,
    required this.name,
    required this.date,
    required this.fileType,
    required this.category,
    this.fileUrl,
  });
}

class PeriodAttendance {
  final DateTime date;
  final int period;
  final String subject;
  final String status; // 'Present' or 'Absent'

  PeriodAttendance({
    required this.date,
    required this.period,
    required this.subject,
    required this.status,
  });
}

/// Represents the class-level attendance (NOT the individual child's attendance).
class ClassAttendance {
  final int classStrength;
  final int presentStudents;
  final int absentStudents;

  ClassAttendance({
    required this.classStrength,
    required this.presentStudents,
    required this.absentStudents,
  });

  int get absentCount => classStrength - presentStudents;
  double get percentage => (presentStudents / classStrength) * 100;
}
