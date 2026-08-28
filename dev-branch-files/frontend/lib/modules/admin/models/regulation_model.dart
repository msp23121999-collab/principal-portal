class RegulationModel {

  const RegulationModel({
    required this.id,
    required this.code,
    required this.scheme,
    required this.department,
    required this.semester,
    required this.passingCriteria,
    required this.totalCredits,
    required this.status,
  });

  factory RegulationModel.fromJson(Map<String, dynamic> json) {
    final regYr = json['regulation_year']?.toString() ?? '';
    final crsCode = json['course_code']?.toString() ?? '';
    String codeDisplay = 'REG-2026';
    if (regYr.isNotEmpty && crsCode.isNotEmpty) {
      codeDisplay = '$regYr • $crsCode';
    } else if (regYr.isNotEmpty) {
      codeDisplay = regYr;
    } else if (crsCode.isNotEmpty) {
      codeDisplay = crsCode;
    } else if (json['code'] != null) {
      codeDisplay = json['code'].toString();
    }

    final nameDisplay = json['course_name']?.toString() ?? json['scheme_title'] ?? json['scheme']?.toString() ?? 'Academic Scheme';

    final credVal = json['credits'] ?? json['total_credits'] ?? 3.0;
    final double cred = double.tryParse(credVal.toString()) ?? 3.0;

    final typeDisplay = json['course_type']?.toString() ?? json['passing_criteria']?.toString() ?? 'Autonomous';

    return RegulationModel(
      id: json['id']?.toString() ?? '',
      code: codeDisplay,
      scheme: nameDisplay,
      department: json['department']?.toString() ?? 'ALL',
      semester: int.tryParse(json['semester']?.toString() ?? '1') ?? 1,
      passingCriteria: typeDisplay,
      totalCredits: cred,
      status: json['status']?.toString() ?? 'Active',
    );
  }
  final String id;
  final String code;
  final String scheme;
  final String department;
  final int semester;
  final String passingCriteria;
  final double totalCredits;
  final String status;

  Map<String, dynamic> toJson() => {
      'id': id,
      'regulation_year': code.contains('•') ? code.split('•')[0].trim() : code,
      'course_code': code.contains('•') ? code.split('•')[1].trim() : code,
      'course_name': scheme,
      'department': department,
      'semester': semester,
      'credits': totalCredits,
      'course_type': passingCriteria,
      'status': status,
    };

  RegulationModel copyWith({
    String? id,
    String? code,
    String? scheme,
    String? department,
    int? semester,
    String? passingCriteria,
    double? totalCredits,
    String? status,
  }) => RegulationModel(
      id: id ?? this.id,
      code: code ?? this.code,
      scheme: scheme ?? this.scheme,
      department: department ?? this.department,
      semester: semester ?? this.semester,
      passingCriteria: passingCriteria ?? this.passingCriteria,
      totalCredits: totalCredits ?? this.totalCredits,
      status: status ?? this.status,
    );
}
