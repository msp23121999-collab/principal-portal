class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.department,
    required this.node,
    required this.status,
    this.admissionNumber,
    this.admissionDate,
    this.rollNumber,
    this.registrationNumber,
    this.domainEmail,
    this.gender,
    this.community,
    this.dateOfBirth,
    this.contactNumber,
    this.batch,
    this.section,
    this.bloodGroup,
    this.designation,
    this.joiningDate,
    this.qualification,
    this.employeeId,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final String department;
  final String node;
  final String status;

  // Student & Staff extended fields
  final String? admissionNumber;
  final String? admissionDate;
  final String? rollNumber;
  final String? registrationNumber;
  final String? domainEmail;
  final String? gender;
  final String? community;
  final String? dateOfBirth;
  final String? contactNumber;
  final String? batch;
  final String? section;
  final String? bloodGroup;
  final String? designation;
  final String? joiningDate;
  final String? qualification;
  final String? employeeId;

  bool get isStudent => role == 'Student';
  bool get isFacultyOrHod => role == 'Faculty' || role == 'Department HOD';

  factory UserModel.fromSupabaseJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'Student',
      department: json['department']?.toString() ?? 'CSE',
      node: json['node']?.toString() ?? 'Active Node',
      status: json['status']?.toString() ?? 'Active',
      admissionNumber: json['admission_number']?.toString(),
      admissionDate: json['admission_date']?.toString(),
      rollNumber: json['roll_number']?.toString(),
      registrationNumber: json['registration_number']?.toString(),
      domainEmail: json['domain_email']?.toString(),
      gender: json['gender']?.toString(),
      community: json['community']?.toString(),
      dateOfBirth: json['date_of_birth']?.toString(),
      contactNumber: json['contact_number']?.toString(),
      batch: json['batch']?.toString(),
      section: json['section']?.toString(),
      bloodGroup: json['blood_group']?.toString(),
      designation: json['designation']?.toString(),
      joiningDate: json['joining_date']?.toString(),
      qualification: json['qualification']?.toString(),
      employeeId: json['employee_id']?.toString(),
    );
  }

  Map<String, dynamic> toSupabaseJson() {
    final map = <String, dynamic>{
      'name': name,
      'email': email,
      'role': role,
      'department': department,
      'node': node,
      'status': status,
    };

    if (id.isNotEmpty) map['id'] = id;
    if (admissionNumber != null && admissionNumber!.isNotEmpty) map['admission_number'] = admissionNumber;
    if (admissionDate != null && admissionDate!.isNotEmpty) map['admission_date'] = admissionDate;
    if (rollNumber != null && rollNumber!.isNotEmpty) map['roll_number'] = rollNumber;
    if (registrationNumber != null && registrationNumber!.isNotEmpty) map['registration_number'] = registrationNumber;
    if (domainEmail != null && domainEmail!.isNotEmpty) map['domain_email'] = domainEmail;
    if (gender != null && gender!.isNotEmpty) map['gender'] = gender;
    if (community != null && community!.isNotEmpty) map['community'] = community;
    if (dateOfBirth != null && dateOfBirth!.isNotEmpty) map['date_of_birth'] = dateOfBirth;
    if (contactNumber != null && contactNumber!.isNotEmpty) map['contact_number'] = contactNumber;
    if (batch != null && batch!.isNotEmpty) map['batch'] = batch;
    if (section != null && section!.isNotEmpty) map['section'] = section;
    if (bloodGroup != null && bloodGroup!.isNotEmpty) map['blood_group'] = bloodGroup;
    if (designation != null && designation!.isNotEmpty) map['designation'] = designation;
    if (joiningDate != null && joiningDate!.isNotEmpty) map['joining_date'] = joiningDate;
    if (qualification != null && qualification!.isNotEmpty) map['qualification'] = qualification;
    if (employeeId != null && employeeId!.isNotEmpty) map['employee_id'] = employeeId;

    return map;
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? department,
    String? node,
    String? status,
    String? admissionNumber,
    String? admissionDate,
    String? rollNumber,
    String? registrationNumber,
    String? domainEmail,
    String? gender,
    String? community,
    String? dateOfBirth,
    String? contactNumber,
    String? batch,
    String? section,
    String? bloodGroup,
    String? designation,
    String? joiningDate,
    String? qualification,
    String? employeeId,
  }) => UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      department: department ?? this.department,
      node: node ?? this.node,
      status: status ?? this.status,
      admissionNumber: admissionNumber ?? this.admissionNumber,
      admissionDate: admissionDate ?? this.admissionDate,
      rollNumber: rollNumber ?? this.rollNumber,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      domainEmail: domainEmail ?? this.domainEmail,
      gender: gender ?? this.gender,
      community: community ?? this.community,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      contactNumber: contactNumber ?? this.contactNumber,
      batch: batch ?? this.batch,
      section: section ?? this.section,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      designation: designation ?? this.designation,
      joiningDate: joiningDate ?? this.joiningDate,
      qualification: qualification ?? this.qualification,
      employeeId: employeeId ?? this.employeeId,
    );
}
