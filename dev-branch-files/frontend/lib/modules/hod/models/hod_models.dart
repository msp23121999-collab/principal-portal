import 'package:flutter/material.dart';

class HodFullProfileData {
  final String fullName;
  final String employeeId;
  final String designation;
  final String department;
  final String deptCode;
  final String officialEmail;
  final String personalEmail;
  final String phone;
  final String emergencyContact;
  final String dob;
  final String gender;
  final String bloodGroup;
  final String nationality;
  final String maritalStatus;
  final String address;
  final String dateOfJoining;
  final String employmentType;
  final String officeLocation;
  final String reportingAuthority;
  final int teachingExperienceYears;
  final int adminExperienceYears;
  final String ugDegree;
  final String pgDegree;
  final String phdDegree;
  final String specialization;
  final String university;
  final int publicationCount;
  final int conferenceCount;
  final int booksCount;
  final int patentsCount;
  final String fundedProjectsAmount;
  final String ORCID;
  final String scopusId;
  final String googleScholar;
  final String researchGate;
  final List<String> subjectsHandled;
  final int weeklyWorkloadHours;
  final List<String> departmentRoles;
  final List<String> awards;
  final List<String> certifications;
  final List<ProfileDocument> documents;
  final double profileCompletionPct;

  const HodFullProfileData({
    required this.fullName,
    required this.employeeId,
    required this.designation,
    required this.department,
    required this.deptCode,
    required this.officialEmail,
    required this.personalEmail,
    required this.phone,
    required this.emergencyContact,
    required this.dob,
    required this.gender,
    required this.bloodGroup,
    required this.nationality,
    required this.maritalStatus,
    required this.address,
    required this.dateOfJoining,
    required this.employmentType,
    required this.officeLocation,
    required this.reportingAuthority,
    required this.teachingExperienceYears,
    required this.adminExperienceYears,
    required this.ugDegree,
    required this.pgDegree,
    required this.phdDegree,
    required this.specialization,
    required this.university,
    required this.publicationCount,
    required this.conferenceCount,
    required this.booksCount,
    required this.patentsCount,
    required this.fundedProjectsAmount,
    required this.ORCID,
    required this.scopusId,
    required this.googleScholar,
    required this.researchGate,
    required this.subjectsHandled,
    required this.weeklyWorkloadHours,
    required this.departmentRoles,
    required this.awards,
    required this.certifications,
    required this.documents,
    required this.profileCompletionPct,
  });
}

class ProfileDocument {
  final String name;
  final String category;
  final String uploadDate;
  final bool isVerified;

  const ProfileDocument({
    required this.name,
    required this.category,
    required this.uploadDate,
    required this.isVerified,
  });
}

class HodHeaderProfile {
  final String name;
  final String greeting;
  final String designation;
  final String department;
  final String deptCode;
  final String academicYear;
  final String semester;
  final String currentDate;
  final String currentTime;
  final String avatarInitial;
  final int pendingNotificationsCount;

  const HodHeaderProfile({
    required this.name,
    required this.greeting,
    required this.designation,
    required this.department,
    required this.deptCode,
    required this.academicYear,
    required this.semester,
    required this.currentDate,
    required this.currentTime,
    required this.avatarInitial,
    required this.pendingNotificationsCount,
  });
}

class KpiStatItem {
  final String id;
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String trendPct;
  final bool trendIsUp;

  const KpiStatItem({
    required this.id,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.trendPct,
    required this.trendIsUp,
  });
}

class ScheduleItem {
  final String id;
  final String subjectCode;
  final String subjectName;
  final String facultyName;
  final String roomNo;
  final String section;
  final String semester;
  final String timing;
  final String status;

  const ScheduleItem({
    required this.id,
    required this.subjectCode,
    required this.subjectName,
    required this.facultyName,
    required this.roomNo,
    required this.section,
    required this.semester,
    required this.timing,
    required this.status,
  });
}

class FacultyOverviewItem {
  final String id;
  final String name;
  final String designation;
  final double attendancePct;
  final int assignedSubjects;
  final int classesToday;
  final int researchCount;
  final int pendingTasks;
  final String status;

  const FacultyOverviewItem({
    required this.id,
    required this.name,
    required this.designation,
    required this.attendancePct,
    required this.assignedSubjects,
    required this.classesToday,
    required this.researchCount,
    required this.pendingTasks,
    required this.status,
  });
}

class StudentOverviewSummary {
  final int totalStudents;
  final int presentToday;
  final int lowAttendanceCount;
  final int feeDefaultersCount;
  final int onLeaveToday;
  final double examEligiblePct;
  final int year1Count;
  final int year2Count;
  final int year3Count;
  final int year4Count;

  const StudentOverviewSummary({
    required this.totalStudents,
    required this.presentToday,
    required this.lowAttendanceCount,
    required this.feeDefaultersCount,
    required this.onLeaveToday,
    required this.examEligiblePct,
    required this.year1Count,
    required this.year2Count,
    required this.year3Count,
    required this.year4Count,
  });
}

class LeaveRequestItem {
  final String id;
  final String facultyName;
  final String designation;
  final String leaveType;
  final String dates;
  final int daysCount;
  final String reason;
  String status;

  LeaveRequestItem({
    required this.id,
    required this.facultyName,
    required this.designation,
    required this.leaveType,
    required this.dates,
    required this.daysCount,
    required this.reason,
    required this.status,
  });
}

class ResearchMetric {
  final int publicationsCount;
  final int conferencesCount;
  final int patentsCount;
  final int fdpsCount;
  final int fundedProjectsCount;
  final double targetCompletionPct;

  const ResearchMetric({
    required this.publicationsCount,
    required this.conferencesCount,
    required this.patentsCount,
    required this.fdpsCount,
    required this.fundedProjectsCount,
    required this.targetCompletionPct,
  });
}

class ExamStatusItem {
  final String subjectCode;
  final String subjectName;
  final int pendingEvaluations;
  final double markEntryPct;
  final String status;

  const ExamStatusItem({
    required this.subjectCode,
    required this.subjectName,
    required this.pendingEvaluations,
    required this.markEntryPct,
    required this.status,
  });
}

class NoticeItem {
  final String id;
  final String title;
  final String category;
  final String source;
  final String date;
  final bool isHighPriority;

  const NoticeItem({
    required this.id,
    required this.title,
    required this.category,
    required this.source,
    required this.date,
    required this.isHighPriority,
  });
}

class TimelineActivity {
  final String id;
  final String title;
  final String description;
  final String timestamp;
  final String user;
  final IconData icon;
  final Color iconColor;

  const TimelineActivity({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.user,
    required this.icon,
    required this.iconColor,
  });
}

class HodProfile {
  final String name;
  final String greeting;
  final String title;
  final String department;
  final String deptCode;
  final String academicYear;
  final String status;
  final String avatarInitial;

  const HodProfile({
    required this.name,
    required this.greeting,
    required this.title,
    required this.department,
    required this.deptCode,
    required this.academicYear,
    required this.status,
    required this.avatarInitial,
  });
}

class StatItem {
  final String title;
  final int count;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;

  const StatItem({
    required this.title,
    required this.count,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
  });
}

class ClassAdviserItem {
  final String className;
  final String adviserName;
  final int studentCount;
  final String status;

  const ClassAdviserItem({
    required this.className,
    required this.adviserName,
    required this.studentCount,
    required this.status,
  });
}

class MentorAssignmentItem {
  final String mentorName;
  final String studentName;
  final String rollNo;
  final String yearSection;
  final String status;

  const MentorAssignmentItem({
    required this.mentorName,
    required this.studentName,
    required this.rollNo,
    required this.yearSection,
    required this.status,
  });
}

class FacultyMember {
  final String id;
  final String name;
  final String designation;
  final String email;
  final String phone;
  final String specialization;
  final String status;

  const FacultyMember({
    required this.id,
    required this.name,
    required this.designation,
    required this.email,
    required this.phone,
    required this.specialization,
    required this.status,
  });
}

class StudentItem {
  final String rollNo;
  final String name;
  final String yearSection;
  final String email;
  final String phone;
  final String status;

  const StudentItem({
    required this.rollNo,
    required this.name,
    required this.yearSection,
    required this.email,
    required this.phone,
    required this.status,
  });
}

class CourseItem {
  final String code;
  final String name;
  final int credits;
  final String facultyAssigned;
  final String semester;

  const CourseItem({
    required this.code,
    required this.name,
    required this.credits,
    required this.facultyAssigned,
    required this.semester,
  });
}
