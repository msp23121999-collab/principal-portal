class AcademicScheduleDocModel {

  const AcademicScheduleDocModel({
    required this.id,
    required this.title,
    required this.pdfUrl,
    required this.pdfFileName,
    required this.fileSize,
    required this.uploadedBy,
    required this.uploadedAt,
    required this.academicYear,
  });
  final String id;
  final String title;
  final String pdfUrl;
  final String pdfFileName;
  final String fileSize;
  final String uploadedBy;
  final String uploadedAt;
  final String academicYear;

  AcademicScheduleDocModel copyWith({
    String? id,
    String? title,
    String? pdfUrl,
    String? pdfFileName,
    String? fileSize,
    String? uploadedBy,
    String? uploadedAt,
    String? academicYear,
  }) => AcademicScheduleDocModel(
      id: id ?? this.id,
      title: title ?? this.title,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      pdfFileName: pdfFileName ?? this.pdfFileName,
      fileSize: fileSize ?? this.fileSize,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      academicYear: academicYear ?? this.academicYear,
    );
}

class AcademicEventModel {

  const AcademicEventModel({
    required this.id,
    required this.scheduleId,
    required this.title,
    required this.description,
    required this.category,
    required this.startDate,
    required this.endDate,
    required this.semester,
    required this.department,
    required this.status,
    required this.venue,
    this.timeSlot = 'Full Day',
  });
  final String id;
  final String scheduleId;
  final String title;
  final String description;
  final String category; // Semester Start, Mid Exam, Practical Exam, Internal Exam, Holiday, University Event, Semester End
  final String startDate;
  final String endDate;
  final String semester;
  final String department;
  final String status; // Upcoming, Ongoing, Completed
  final String venue;
  final String timeSlot;

  AcademicEventModel copyWith({
    String? id,
    String? scheduleId,
    String? title,
    String? description,
    String? category,
    String? startDate,
    String? endDate,
    String? semester,
    String? department,
    String? status,
    String? venue,
    String? timeSlot,
  }) => AcademicEventModel(
      id: id ?? this.id,
      scheduleId: scheduleId ?? this.scheduleId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      semester: semester ?? this.semester,
      department: department ?? this.department,
      status: status ?? this.status,
      venue: venue ?? this.venue,
      timeSlot: timeSlot ?? this.timeSlot,
    );
}


class HolidayModel {

  const HolidayModel({
    required this.id,
    required this.name,
    required this.date,
    required this.dayOfWeek,
    required this.remarks,
  });
  final String id;
  final String name;
  final String date;
  final String dayOfWeek;
  final String remarks;
}

class AcademicMilestoneModel { // Completed, Upcoming, In Progress

  const AcademicMilestoneModel({
    required this.id,
    required this.title,
    required this.targetDate,
    required this.description,
    required this.status,
  });
  final String id;
  final String title;
  final String targetDate;
  final String description;
  final String status;
}
