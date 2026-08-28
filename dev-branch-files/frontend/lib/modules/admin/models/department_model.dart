class DepartmentModel {

  const DepartmentModel({
    required this.id,
    required this.name,
    required this.code,
    required this.hod,
    required this.intakeCapacity,
    required this.status,
  });

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    final isAct = json['is_active'];
    String statusStr = 'Active';
    if (isAct is bool) {
      statusStr = isAct ? 'Active' : 'Inactive';
    } else if (json['status'] != null) {
      statusStr = json['status'].toString();
    }

    final capVal = json['capacity'] ?? json['intake_capacity'] ?? json['program_count'] ?? 60;
    final int capacity = capVal is int ? capVal : (int.tryParse(capVal.toString()) ?? 60);

    return DepartmentModel(
      id: json['id']?.toString() ?? json['code']?.toString() ?? 'DEPT',
      name: json['name']?.toString() ?? json['department_name']?.toString() ?? 'Department',
      code: json['code']?.toString() ?? json['department_code']?.toString() ?? 'DEPT',
      hod: json['hod_name']?.toString() ?? json['hod']?.toString() ?? 'HOD',
      intakeCapacity: capacity,
      status: statusStr,
    );
  }
  final String id;
  final String name;
  final String code;
  final String hod;
  final int intakeCapacity;
  final String status;

  Map<String, dynamic> toJson() => {
      'id': id,
      'code': code,
      'name': name,
      'hod_name': hod,
      'is_active': status == 'Active',
    };

  DepartmentModel copyWith({
    String? id,
    String? name,
    String? code,
    String? hod,
    int? intakeCapacity,
    String? status,
  }) => DepartmentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      hod: hod ?? this.hod,
      intakeCapacity: intakeCapacity ?? this.intakeCapacity,
      status: status ?? this.status,
    );
}
