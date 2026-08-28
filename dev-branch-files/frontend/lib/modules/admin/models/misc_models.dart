class AcademicCycleModel {

  const AcademicCycleModel({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.status,
  });
  final String id;
  final String name;
  final String startDate;
  final String endDate;
  final String status;

  AcademicCycleModel copyWith({
    String? id,
    String? name,
    String? startDate,
    String? endDate,
    String? status,
  }) => AcademicCycleModel(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
    );
}

class AuditLogModel { // Info, Warning, Critical

  const AuditLogModel({
    required this.id,
    required this.timestamp,
    required this.description,
    required this.operatorName,
    required this.level,
  });
  final String id;
  final String timestamp;
  final String description;
  final String operatorName;
  final String level;
}

class ReportModel { // PDF, Excel

  const ReportModel({
    required this.id,
    required this.code,
    required this.title,
    required this.status,
    required this.format,
  });
  final String id;
  final String code;
  final String title;
  final String status; // Completed, Processing, Failed
  final String format;
}

class MedicalAlertModel { // Active, Completed, Pending

  const MedicalAlertModel({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.status,
  });
  final String id;
  final String title;
  final String description;
  final String date;
  final String status;

  MedicalAlertModel copyWith({
    String? id,
    String? title,
    String? description,
    String? date,
    String? status,
  }) => MedicalAlertModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      status: status ?? this.status,
    );
}

class EventModel {

  const EventModel({
    required this.id,
    required this.title,
    required this.coordinator,
    required this.venue,
    required this.date,
    required this.status,
  });
  final String id;
  final String title;
  final String coordinator;
  final String venue;
  final String date;
  final String status;

  EventModel copyWith({
    String? id,
    String? title,
    String? coordinator,
    String? venue,
    String? date,
    String? status,
  }) => EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      coordinator: coordinator ?? this.coordinator,
      venue: venue ?? this.venue,
      date: date ?? this.date,
      status: status ?? this.status,
    );
}


