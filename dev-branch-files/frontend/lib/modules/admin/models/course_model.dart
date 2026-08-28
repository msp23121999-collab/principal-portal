class CourseModel {

  const CourseModel({
    required this.id,
    required this.code,
    required this.name,
    required this.department,
    required this.subjectsCount,
    required this.status,
    this.durationYears = 4,
  });
  final String id;
  final String code;
  final String name;
  final String department;
  final int subjectsCount;
  final String status;
  final int durationYears;

  CourseModel copyWith({
    String? id,
    String? code,
    String? name,
    String? department,
    int? subjectsCount,
    String? status,
    int? durationYears,
  }) => CourseModel(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      department: department ?? this.department,
      subjectsCount: subjectsCount ?? this.subjectsCount,
      status: status ?? this.status,
      durationYears: durationYears ?? this.durationYears,
    );
}

class SubjectModel {

  const SubjectModel({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    required this.credits,
    required this.status,
    this.department = 'CSE',
    this.semester = 1,
    this.programmeId = '',
  });
  final String id;
  final String code;
  final String name;
  final String type; // Theory, Lab, Elective
  final int credits;
  final String status;
  final String department;
  final int semester;
  final String programmeId;

  SubjectModel copyWith({
    String? id,
    String? code,
    String? name,
    String? type,
    int? credits,
    String? status,
    String? department,
    int? semester,
    String? programmeId,
  }) => SubjectModel(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      type: type ?? this.type,
      credits: credits ?? this.credits,
      status: status ?? this.status,
      department: department ?? this.department,
      semester: semester ?? this.semester,
      programmeId: programmeId ?? this.programmeId,
    );
}
