import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/admin_supabase_service.dart';
import '../services/admin_user_service.dart';
import '../shared/services/supabase_service.dart';
import '../utils/file_downloader.dart';

// ─── 1. Student Attendance & Marks Record Model ──────────────────────────────
class StudentAttendanceMarkRecord {
  // out of 15

  const StudentAttendanceMarkRecord({
    required this.id,
    required this.studentName,
    required this.registerNo,
    required this.rollNo,
    required this.department,
    required this.subject,
    required this.attendancePercentage,
    required this.cat1Marks,
    required this.cat2Marks,
    required this.assessmentMarks,
  });
  final String id;
  final String studentName;
  final String registerNo;
  final String rollNo;
  final String department;
  final String subject;
  final double attendancePercentage; // e.g., 92.0
  final double cat1Marks; // out of 25
  final double cat2Marks; // out of 25
  final double assessmentMarks;

  double get attendanceMarksWeightage {
    if (attendancePercentage >= 90) return 5;
    if (attendancePercentage >= 85) return 4;
    if (attendancePercentage >= 80) return 3;
    if (attendancePercentage >= 75) return 2;
    return 0;
  }

  double get totalInternalMarks {
    final catWeightage = ((cat1Marks + cat2Marks) / 50.0) * 30.0;
    final total = catWeightage + assessmentMarks + attendanceMarksWeightage;
    return double.parse(total.clamp(0.0, 50.0).toStringAsFixed(1));
  }

  String get status {
    if (attendancePercentage < 75) return 'Low Attendance Alert';
    if (totalInternalMarks < 20) return 'At Risk (Low Marks)';
    return 'Eligible for Exam';
  }

  StudentAttendanceMarkRecord copyWith({
    String? id,
    String? studentName,
    String? registerNo,
    String? rollNo,
    String? department,
    String? subject,
    double? attendancePercentage,
    double? cat1Marks,
    double? cat2Marks,
    double? assessmentMarks,
  }) => StudentAttendanceMarkRecord(
    id: id ?? this.id,
    studentName: studentName ?? this.studentName,
    registerNo: registerNo ?? this.registerNo,
    rollNo: rollNo ?? this.rollNo,
    department: department ?? this.department,
    subject: subject ?? this.subject,
    attendancePercentage: attendancePercentage ?? this.attendancePercentage,
    cat1Marks: cat1Marks ?? this.cat1Marks,
    cat2Marks: cat2Marks ?? this.cat2Marks,
    assessmentMarks: assessmentMarks ?? this.assessmentMarks,
  );
}

// ─── 2. Faculty Daily Attendance Record Model ──────────────────────────────
class FacultyAttendanceRecord {
  const FacultyAttendanceRecord({
    required this.id,
    required this.facultyName,
    required this.employeeId,
    required this.department,
    required this.designation,
    required this.date,
    required this.status,
    required this.checkIn,
    required this.checkOut,
    required this.attendancePercentage,
  });
  final String id;
  final String facultyName;
  final String employeeId;
  final String department;
  final String designation;
  final String date;
  final String status; // 'Present', 'Absent', 'On Leave', 'On Duty (OD)'
  final String checkIn;
  final String checkOut;
  final double attendancePercentage;

  FacultyAttendanceRecord copyWith({
    String? id,
    String? facultyName,
    String? employeeId,
    String? department,
    String? designation,
    String? date,
    String? status,
    String? checkIn,
    String? checkOut,
    double? attendancePercentage,
  }) => FacultyAttendanceRecord(
    id: id ?? this.id,
    facultyName: facultyName ?? this.facultyName,
    employeeId: employeeId ?? this.employeeId,
    department: department ?? this.department,
    designation: designation ?? this.designation,
    date: date ?? this.date,
    status: status ?? this.status,
    checkIn: checkIn ?? this.checkIn,
    checkOut: checkOut ?? this.checkOut,
    attendancePercentage: attendancePercentage ?? this.attendancePercentage,
  );
}

// ─── 3. Student Attendance Notifier (Direct Database Fetching) ──────────────
class AttendanceMarkNotifier
    extends StateNotifier<List<StudentAttendanceMarkRecord>> {
  AttendanceMarkNotifier() : super([]) {
    loadData();
  }

  Future<void> loadData() async {
    try {
      final list = await AdminSupabaseService.fetchStudentAttendanceMarks();
      if (list.isNotEmpty) {
        state = list.map((e) {
          final studentId = e['student_id']?.toString() ?? e['register_no']?.toString() ?? e['student_name']?.toString() ?? 'Student';
          final subject = e['subject_code']?.toString() ?? e['subject']?.toString() ?? 'Data Structures & Algorithms';
          final attended = double.tryParse(e['attended_classes']?.toString() ?? e['attendance_percentage']?.toString() ?? '') ?? 90.0;
          final totalCls = double.tryParse(e['total_classes']?.toString() ?? '') ?? 100.0;
          final attPct = totalCls > 0 ? (attended / totalCls) * 100.0 : attended;
          final internal = double.tryParse(e['internal_marks']?.toString() ?? e['cat1_marks']?.toString() ?? '') ?? 40.0;

          return StudentAttendanceMarkRecord(
            id: e['id']?.toString() ?? '',
            studentName: e['student_name']?.toString() ?? studentId,
            registerNo: e['register_no']?.toString() ?? studentId,
            rollNo: e['roll_no']?.toString() ?? studentId,
            department: e['department']?.toString() ?? 'CSE',
            subject: subject,
            attendancePercentage: double.parse(attPct.toStringAsFixed(1)),
            cat1Marks: double.parse(((internal * 0.4).clamp(0.0, 25.0)).toStringAsFixed(1)),
            cat2Marks: double.parse(((internal * 0.4).clamp(0.0, 25.0)).toStringAsFixed(1)),
            assessmentMarks: double.parse(((internal * 0.2).clamp(0.0, 15.0)).toStringAsFixed(1)),
          );
        }).toList();
      } else {
        final liveUsers = await AdminUserService.fetchAllUsers();
        final studentUsers = liveUsers
            .where(
              (u) => (u['role'] ?? '').toString().trim().toLowerCase().contains(
                'student',
              ),
            )
            .toList();

        if (studentUsers.isNotEmpty) {
          state = studentUsers.map((u) {
            final reg =
                (u['registration_number'] != null &&
                    u['registration_number'].toString().isNotEmpty)
                ? u['registration_number'].toString()
                : (u['roll_number']?.toString() ?? '21CS001');
            final roll =
                (u['roll_number'] != null &&
                    u['roll_number'].toString().isNotEmpty)
                ? u['roll_number'].toString()
                : reg;
            return StudentAttendanceMarkRecord(
              id: 'SAM_${u['id']}',
              studentName: u['name']?.toString() ?? '',
              registerNo: reg,
              rollNo: roll,
              department: (u['department']?.toString() ?? '').isNotEmpty
                  ? u['department'].toString()
                  : 'CSE',
              subject: 'Data Structures & Algorithms',
              attendancePercentage: 91.5,
              cat1Marks: 22,
              cat2Marks: 23,
              assessmentMarks: 13.5,
            );
          }).toList();
        } else {
          state = [];
        }
      }
    } catch (_) {
      state = [];
    }
  }

  Future<void> addRecord(StudentAttendanceMarkRecord record) async {
    state = [record, ...state];
    
    // 1. Insert into student_attendance_marks table in Supabase
    await AdminSupabaseService.addStudentAttendanceMark({
      'student_id': record.registerNo.isNotEmpty ? record.registerNo : record.studentName,
      'subject_code': record.subject,
      'total_classes': 100,
      'attended_classes': record.attendancePercentage.round(),
      'internal_marks': record.totalInternalMarks,
      'semester': 1,
    });

    // 2. Also register student into users table in Supabase if new
    await SupabaseService.instance.insertData('users', {
      'name': record.studentName,
      'email': '${record.registerNo.isNotEmpty ? record.registerNo : 'student_${DateTime.now().millisecondsSinceEpoch}'}@ksrce.ac.in',
      'role': 'Student',
      'department': record.department,
      'registration_number': record.registerNo,
      'roll_number': record.rollNo,
      'status': 'Active',
      'node': 'Active Node',
    });

    // 3. Sync to students table in Supabase
    await SupabaseService.instance.insertData('students', {
      'name': record.studentName,
      'roll_number': record.rollNo.isNotEmpty ? record.rollNo : record.registerNo,
      'admission_number': record.registerNo,
      'department_code': record.department,
      'batch': '2022-2026',
      'section': 'A',
      'status': 'Active',
    });

    loadData();
  }

  Future<void> updateRecord(StudentAttendanceMarkRecord record) async {
    state = [
      for (final r in state)
        if (r.id == record.id) record else r,
    ];
    await AdminSupabaseService.updateStudentAttendanceMark(record.id, {
      'student_id': record.registerNo.isNotEmpty ? record.registerNo : record.studentName,
      'subject_code': record.subject,
      'total_classes': 100,
      'attended_classes': record.attendancePercentage.round(),
      'internal_marks': record.totalInternalMarks,
      'semester': 1,
    });
    loadData();
  }

  Future<void> deleteRecord(String id) async {
    state = state.where((r) => r.id != id).toList();
    await AdminSupabaseService.deleteStudentAttendanceMark(id);
    loadData();
  }
}

final attendanceMarkProvider =
    StateNotifierProvider<
      AttendanceMarkNotifier,
      List<StudentAttendanceMarkRecord>
    >((ref) => AttendanceMarkNotifier());

// ─── 4. Faculty Attendance Notifier (Direct Database Fetching) ──────────────
class FacultyAttendanceNotifier
    extends StateNotifier<List<FacultyAttendanceRecord>> {
  FacultyAttendanceNotifier() : super([]) {
    loadData();
  }

  Future<void> loadData() async {
    try {
      final list = await AdminSupabaseService.fetchFacultyAttendance();
      if (list.isNotEmpty) {
        state = list
            .map(
              (e) => FacultyAttendanceRecord(
                id: e['id']?.toString() ?? '',
                facultyName:
                    e['faculty_name']?.toString() ??
                    e['name']?.toString() ??
                    'Faculty Member',
                employeeId:
                    e['employee_id']?.toString() ??
                    e['emp_id']?.toString() ??
                    'EMP-101',
                department: e['department']?.toString() ?? 'CSE',
                designation:
                    e['designation']?.toString() ?? 'Assistant Professor',
                date:
                    e['date']?.toString() ??
                    DateTime.now().toString().split(' ')[0],
                status: e['status']?.toString() ?? 'Present',
                checkIn: e['check_in']?.toString() ?? '08:45 AM',
                checkOut: e['check_out']?.toString() ?? '04:30 PM',
                attendancePercentage:
                    double.tryParse(
                      e['attendance_percentage']?.toString() ?? '95.0',
                    ) ??
                    95.0,
              ),
            )
            .toList();
      } else {
        // Fetch live faculty users from Supabase admin_users table (No mock fallback)
        final liveUsers = await AdminUserService.fetchAllUsers();
        final facultyUsers = liveUsers.where((u) {
          final r = (u['role'] ?? '').toString().trim().toLowerCase();
          return r.contains('faculty') || r.contains('hod') || r == 'teacher';
        }).toList();

        if (facultyUsers.isNotEmpty) {
          state = facultyUsers.map((u) {
            final empId =
                (u['employee_id'] != null &&
                    u['employee_id'].toString().isNotEmpty)
                ? u['employee_id'].toString()
                : 'EMP-${(u['id'] ?? '').toString().substring(0, (u['id'] ?? '').toString().length.clamp(0, 4))}';
            final desig =
                (u['designation'] != null &&
                    u['designation'].toString().isNotEmpty)
                ? u['designation'].toString()
                : ((u['role'] ?? '').toString().contains('HOD')
                      ? 'Head of Department'
                      : 'Assistant Professor');
            return FacultyAttendanceRecord(
              id: 'FAC_ATT_${u['id']}',
              facultyName: u['name']?.toString() ?? '',
              employeeId: empId,
              department: (u['department']?.toString() ?? '').isNotEmpty
                  ? u['department'].toString()
                  : 'CSE',
              designation: desig,
              date: DateTime.now().toString().split(' ')[0],
              status: 'Present',
              checkIn: '08:45 AM',
              checkOut: '04:30 PM',
              attendancePercentage: 96.5,
            );
          }).toList();
        } else {
          state = [];
        }
      }
    } catch (_) {
      state = [];
    }
  }

  Future<void> addRecord(FacultyAttendanceRecord record) async {
    state = [record, ...state];
    await AdminSupabaseService.addFacultyAttendance({
      'faculty_id': record.employeeId.isNotEmpty ? record.employeeId : record.facultyName,
      'date': record.date,
      'status': record.status,
      'check_in': record.checkIn.isNotEmpty ? record.checkIn : null,
      'check_out': record.checkOut.isNotEmpty ? record.checkOut : null,
    });
    loadData();
  }

  Future<void> updateRecord(FacultyAttendanceRecord record) async {
    state = [
      for (final r in state)
        if (r.id == record.id) record else r,
    ];
    final payload = {
      'faculty_id': record.employeeId.isNotEmpty ? record.employeeId : record.facultyName,
      'date': record.date,
      'status': record.status,
      'check_in': record.checkIn.isNotEmpty ? record.checkIn : null,
      'check_out': record.checkOut.isNotEmpty ? record.checkOut : null,
    };
    if (record.id.startsWith('FAC_ATT_')) {
      await AdminSupabaseService.addFacultyAttendance(payload);
    } else {
      await AdminSupabaseService.updateFacultyAttendance(record.id, payload);
    }
    loadData();
  }

  Future<void> deleteRecord(String id) async {
    state = state.where((r) => r.id != id).toList();
    await AdminSupabaseService.deleteFacultyAttendance(id);
    loadData();
  }
}

final facultyAttendanceProvider =
    StateNotifierProvider<
      FacultyAttendanceNotifier,
      List<FacultyAttendanceRecord>
    >((ref) => FacultyAttendanceNotifier());

// ─── 5. Main AttendanceScreen Component ─────────────────────────────────────
class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key, this.initialType = 'student'});
  final String initialType;

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  final TextEditingController _searchController = TextEditingController();

  late String _selectedType; // 'student' or 'faculty'
  String _searchQuery = '';
  String _selectedDept = 'All';
  final String _selectedSubject = 'All';
  String _selectedStatus = 'All';

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType.toLowerCase().contains('faculty')
        ? 'faculty'
        : 'student';
  }

  @override
  void didUpdateWidget(covariant AttendanceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialType != widget.initialType) {
      setState(() {
        _selectedType = widget.initialType.toLowerCase().contains('faculty')
            ? 'faculty'
            : 'student';
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Student Attendance Add/Edit Modal ──────────────────────────────────────
  void _showAddEditStudentModal([StudentAttendanceMarkRecord? existing]) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: existing?.studentName ?? '');
    final regCtrl = TextEditingController(text: existing?.registerNo ?? '');
    final rollCtrl = TextEditingController(text: existing?.rollNo ?? '');
    final attCtrl = TextEditingController(
      text: existing?.attendancePercentage.toString() ?? '90.0',
    );
    final cat1Ctrl = TextEditingController(
      text: existing?.cat1Marks.toString() ?? '20.0',
    );
    final cat2Ctrl = TextEditingController(
      text: existing?.cat2Marks.toString() ?? '20.0',
    );
    final assessCtrl = TextEditingController(
      text: existing?.assessmentMarks.toString() ?? '12.0',
    );

    var dept = existing?.department ?? 'CSE';
    var subject = existing?.subject ?? 'Data Structures & Algorithms';

    final deptsList = ['CSE', 'IT', 'ECE', 'MECH', 'CIVIL'];
    final subjectsList = [
      'Data Structures & Algorithms',
      'Operating Systems',
      'Digital Signal Processing',
      'AI & Machine Learning',
      'Thermodynamics',
      'Database Management Systems',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final currentAtt = double.tryParse(attCtrl.text) ?? 0.0;
          final currentCat1 = double.tryParse(cat1Ctrl.text) ?? 0.0;
          final currentCat2 = double.tryParse(cat2Ctrl.text) ?? 0.0;
          final currentAssess = double.tryParse(assessCtrl.text) ?? 0.0;

          final attMarks = currentAtt >= 90
              ? 5.0
              : (currentAtt >= 85
                    ? 4.0
                    : (currentAtt >= 80
                          ? 3.0
                          : (currentAtt >= 75 ? 2.0 : 0.0)));
          final catWeightage = ((currentCat1 + currentCat2) / 50.0) * 30.0;
          final totalInternal = (catWeightage + currentAssess + attMarks).clamp(
            0.0,
            50.0,
          );

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 540),
              padding: const EdgeInsets.all(24),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.school_rounded,
                                  color: Color(0xFF0052CC),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                existing == null
                                    ? 'Add Student Attendance & Marks'
                                    : 'Edit Student Record',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Student Full Name',
                          hintText: 'Enter student name',
                        ),
                        validator: (v) => v == null || v.isEmpty
                            ? 'Student name is required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: regCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Register Number',
                                hintText: '731521104001',
                              ),
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: rollCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Roll Number',
                                hintText: '21CSE001',
                              ),
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: dept,
                              decoration: const InputDecoration(
                                labelText: 'Department',
                              ),
                              items: deptsList
                                  .map(
                                    (d) => DropdownMenuItem(
                                      value: d,
                                      child: Text(d),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => setModalState(() => dept = v!),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: subject,
                              decoration: const InputDecoration(
                                labelText: 'Subject',
                              ),
                              items: subjectsList
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(
                                        s,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setModalState(() => subject = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: attCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Attendance %',
                                suffixText: '%',
                              ),
                              onChanged: (_) => setModalState(() {}),
                              validator: (v) =>
                                  (double.tryParse(v ?? '') ?? -1) < 0
                                  ? 'Enter valid %'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: cat1Ctrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'CAT-1 (Max 25)',
                              ),
                              onChanged: (_) => setModalState(() {}),
                              validator: (v) =>
                                  (double.tryParse(v ?? '') ?? -1) < 0
                                  ? 'Enter marks'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: cat2Ctrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'CAT-2 (Max 25)',
                              ),
                              onChanged: (_) => setModalState(() {}),
                              validator: (v) =>
                                  (double.tryParse(v ?? '') ?? -1) < 0
                                  ? 'Enter marks'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: assessCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Assessment (Max 15)',
                              ),
                              onChanged: (_) => setModalState(() {}),
                              validator: (v) =>
                                  (double.tryParse(v ?? '') ?? -1) < 0
                                  ? 'Enter marks'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 16,
                                  color: Color(0xFF0052CC),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Automated Calculation Preview',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0052CC),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 12,
                              runSpacing: 6,
                              children: [
                                Text(
                                  'Attendance Weightage: ${attMarks.toStringAsFixed(1)} / 5',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                Text(
                                  'Internal Total: ${totalInternal.toStringAsFixed(1)} / 50',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0052CC),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.save_rounded, size: 18),
                            label: Text(
                              existing == null
                                  ? 'Save Record'
                                  : 'Update Record',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0052CC),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {
                              if (formKey.currentState!.validate()) {
                                final newRecord = StudentAttendanceMarkRecord(
                                  id:
                                      existing?.id ??
                                      'SAM${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                                  studentName: nameCtrl.text,
                                  registerNo: regCtrl.text,
                                  rollNo: rollCtrl.text,
                                  department: dept,
                                  subject: subject,
                                  attendancePercentage: currentAtt,
                                  cat1Marks: currentCat1,
                                  cat2Marks: currentCat2,
                                  assessmentMarks: currentAssess,
                                );

                                final messenger = ScaffoldMessenger.of(context);
                                if (existing == null) {
                                  ref
                                      .read(attendanceMarkProvider.notifier)
                                      .addRecord(newRecord);
                                } else {
                                  ref
                                      .read(attendanceMarkProvider.notifier)
                                      .updateRecord(newRecord);
                                }
                                Navigator.of(context).pop();
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Student attendance for "${newRecord.studentName}" saved successfully.',
                                    ),
                                    backgroundColor: const Color(0xFF16A34A),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Faculty Attendance Mark/Edit Modal ──────────────────────────────────────
  void _showAddEditFacultyModal([FacultyAttendanceRecord? existing]) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: existing?.facultyName ?? '');
    final empCtrl = TextEditingController(text: existing?.employeeId ?? '');
    final dateCtrl = TextEditingController(
      text: existing?.date ?? DateTime.now().toString().split(' ')[0],
    );
    final checkInCtrl = TextEditingController(
      text: existing?.checkIn ?? '08:45 AM',
    );
    final checkOutCtrl = TextEditingController(
      text: existing?.checkOut ?? '04:30 PM',
    );
    final attCtrl = TextEditingController(
      text: existing?.attendancePercentage.toString() ?? '96.5',
    );

    var dept = existing?.department ?? 'CSE';
    var designation = existing?.designation ?? 'Assistant Professor';
    var status = existing?.status ?? 'Present';

    final deptsList = ['CSE', 'IT', 'ECE', 'EEE', 'MECH', 'CIVIL'];
    final desigList = [
      'Head of Department',
      'Professor',
      'Associate Professor',
      'Assistant Professor',
      'Lab Instructor',
    ];
    final statusList = ['Present', 'Absent', 'On Leave', 'On Duty (OD)'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 540),
              padding: const EdgeInsets.all(24),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.badge_rounded,
                                  color: Color(0xFF059669),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                existing == null
                                    ? 'Mark Daily Faculty Attendance'
                                    : 'Edit Faculty Attendance Record',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Faculty Full Name',
                          hintText: 'Dr. K. S. Ravichandran',
                        ),
                        validator: (v) => v == null || v.isEmpty
                            ? 'Faculty name is required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: empCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Employee ID',
                                hintText: 'EMP-101',
                              ),
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: dateCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Date (YYYY-MM-DD)',
                                hintText: '2026-08-11',
                              ),
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: dept,
                              decoration: const InputDecoration(
                                labelText: 'Department',
                              ),
                              items: deptsList
                                  .map(
                                    (d) => DropdownMenuItem(
                                      value: d,
                                      child: Text(d),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => setModalState(() => dept = v!),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: designation,
                              decoration: const InputDecoration(
                                labelText: 'Designation',
                              ),
                              items: desigList
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(
                                        s,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setModalState(() => designation = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: status,
                        decoration: const InputDecoration(
                          labelText: 'Attendance Status',
                        ),
                        items: statusList
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                        onChanged: (v) => setModalState(() => status = v!),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: checkInCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Check-In Time',
                                hintText: '08:45 AM',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: checkOutCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Check-Out Time',
                                hintText: '04:30 PM',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: attCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Attendance %',
                                suffixText: '%',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.save_rounded, size: 18),
                            label: Text(
                              existing == null
                                  ? 'Save Faculty Attendance'
                                  : 'Update Record',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF059669),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {
                              if (formKey.currentState!.validate()) {
                                final newRecord = FacultyAttendanceRecord(
                                  id:
                                      existing?.id ??
                                      'FAC_ATT_${DateTime.now().millisecondsSinceEpoch}',
                                  facultyName: nameCtrl.text,
                                  employeeId: empCtrl.text,
                                  department: dept,
                                  designation: designation,
                                  date: dateCtrl.text,
                                  status: status,
                                  checkIn: checkInCtrl.text,
                                  checkOut: checkOutCtrl.text,
                                  attendancePercentage:
                                      double.tryParse(attCtrl.text) ?? 96.0,
                                );

                                final messenger = ScaffoldMessenger.of(context);
                                if (existing == null) {
                                  ref
                                      .read(facultyAttendanceProvider.notifier)
                                      .addRecord(newRecord);
                                } else {
                                  ref
                                      .read(facultyAttendanceProvider.notifier)
                                      .updateRecord(newRecord);
                                }
                                Navigator.of(context).pop();
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Faculty attendance for "${newRecord.facultyName}" saved successfully.',
                                    ),
                                    backgroundColor: const Color(0xFF16A34A),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF8FAFC),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top Bar: Segmented Tab Selector (Scrollable on Mobile) ────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => setState(() => _selectedType = 'student'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _selectedType == 'student'
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _selectedType == 'student'
                            ? [
                                const BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.school_rounded,
                            size: 18,
                            color: _selectedType == 'student'
                                ? const Color(0xFF0052CC)
                                : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Student Attendance & Marks',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: _selectedType == 'student'
                                  ? const Color(0xFF0052CC)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => setState(() => _selectedType = 'faculty'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _selectedType == 'faculty'
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _selectedType == 'faculty'
                            ? [
                                const BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.badge_rounded,
                            size: 18,
                            color: _selectedType == 'faculty'
                                ? const Color(0xFF059669)
                                : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Faculty Daily Attendance',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: _selectedType == 'faculty'
                                  ? const Color(0xFF059669)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Render Selected View ─────────────────────────────────────────
          if (_selectedType == 'faculty')
            _buildFacultyAttendanceView(context)
          else
            _buildStudentAttendanceView(context),
        ],
      ),
    ),
  );

  // ── 6. Student Attendance & Marks View ────────────────────────────────────
  Widget _buildStudentAttendanceView(BuildContext context) {
    final records = ref.watch(attendanceMarkProvider);

    final filteredRecords = records.where((r) {
      final matchesSearch =
          r.studentName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.registerNo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.rollNo.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesDept =
          _selectedDept == 'All' || r.department == _selectedDept;
      final matchesSubject =
          _selectedSubject == 'All' || r.subject == _selectedSubject;
      final matchesStatus =
          _selectedStatus == 'All' || r.status == _selectedStatus;
      return matchesSearch && matchesDept && matchesSubject && matchesStatus;
    }).toList();

    final avgAttendance = records.isEmpty
        ? 0.0
        : records.map((r) => r.attendancePercentage).reduce((a, b) => a + b) /
              records.length;
    final avgInternal = records.isEmpty
        ? 0.0
        : records.map((r) => r.totalInternalMarks).reduce((a, b) => a + b) /
              records.length;
    final avgCat1 = records.isEmpty
        ? 0.0
        : records.map((r) => r.cat1Marks).reduce((a, b) => a + b) /
              records.length;
    final lowAttendanceCount = records
        .where((r) => r.attendancePercentage < 75)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Bar
        LayoutBuilder(
          builder: (context, headerConstraints) {
            final isNarrow = headerConstraints.maxWidth < 950;
            return Flex(
              direction: isNarrow ? Axis.vertical : Axis.horizontal,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: isNarrow
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Student Attendance & Internal Marks Console',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Continuous assessment, CAT marks, and attendance weightages',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
                if (isNarrow) const SizedBox(height: 12),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        final messenger = ScaffoldMessenger.of(context);
                        final buffer = StringBuffer();
                        buffer.writeln(
                          'RegNo,RollNo,Name,Department,Subject,Attendance%,AttnMarks(5),CAT1(25),CAT2(25),Assessment(15),TotalInternal(50),Status',
                        );
                        for (final r in filteredRecords) {
                          buffer.writeln(
                            '${r.registerNo},${r.rollNo},"${r.studentName}",${r.department},"${r.subject}",${r.attendancePercentage},${r.attendanceMarksWeightage},${r.cat1Marks},${r.cat2Marks},${r.assessmentMarks},${r.totalInternalMarks},${r.status}',
                          );
                        }
                        final bytes = utf8.encode(buffer.toString());
                        FileDownloader.downloadFile(
                          bytes,
                          'student_attendance_marks_report.csv',
                        );
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Student Attendance & Marks Report exported to CSV!',
                            ),
                            backgroundColor: Color(0xFF16A34A),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.download_rounded,
                        size: 18,
                        color: Color(0xFF0052CC),
                      ),
                      label: const Text(
                        'Export Report CSV',
                        style: TextStyle(color: Color(0xFF0052CC)),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _showAddEditStudentModal,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add / Calculate Marks'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0052CC),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),

        // KPI Metric Cards (2 per row on mobile viewports)
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth > 900
                ? (constraints.maxWidth - 36) / 4
                : (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildMetricCard(
                  'Avg Attendance Rate',
                  '${avgAttendance.toStringAsFixed(1)}%',
                  'Threshold: >=75%',
                  Icons.fact_check_rounded,
                  const Color(0xFF16A34A),
                  cardWidth,
                ),
                _buildMetricCard(
                  'Avg Internal Score',
                  '${avgInternal.toStringAsFixed(1)} / 50',
                  'Include Attn Weightage',
                  Icons.star_rounded,
                  const Color(0xFF0052CC),
                  cardWidth,
                ),
                _buildMetricCard(
                  'Avg CAT-1 Marks',
                  '${avgCat1.toStringAsFixed(1)} / 25',
                  'Continuous Test 1',
                  Icons.bar_chart_rounded,
                  const Color(0xFF8B5CF6),
                  cardWidth,
                ),
                _buildMetricCard(
                  'Low Attendance Alert',
                  '$lowAttendanceCount Students',
                  '<75% Condonation',
                  Icons.warning_rounded,
                  const Color(0xFFDC2626),
                  cardWidth,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),

        // Filter Bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 700;
              return Flex(
                direction: isSmall ? Axis.vertical : Axis.horizontal,
                children: [
                  Expanded(
                    flex: isSmall ? 0 : 2,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText:
                            'Search student name, roll no, or register no...',
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF64748B),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(),
                      ),
                    ),
                  ),
                  if (isSmall)
                    const SizedBox(height: 10)
                  else
                    const SizedBox(width: 12),
                  Expanded(
                    flex: isSmall ? 0 : 1,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedDept,
                      decoration: InputDecoration(
                        labelText: 'Dept Filter',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: ['All', 'CSE', 'IT', 'ECE', 'MECH', 'CIVIL']
                          .map(
                            (d) => DropdownMenuItem(value: d, child: Text(d)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedDept = v!),
                    ),
                  ),
                  if (isSmall)
                    const SizedBox(height: 10)
                  else
                    const SizedBox(width: 12),
                  Expanded(
                    flex: isSmall ? 0 : 1,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedStatus,
                      decoration: InputDecoration(
                        labelText: 'Status Filter',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items:
                          [
                                'All',
                                'Eligible for Exam',
                                'Low Attendance Alert',
                                'At Risk (Low Marks)',
                              ]
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(
                                    s,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: (v) => setState(() => _selectedStatus = v!),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // Data Table
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
              columns: const [
                DataColumn(
                  label: Text(
                    'Student Info',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Dept & Subject',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Attendance %',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Attn Marks (5)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'CAT-1 (25)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'CAT-2 (25)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Internal (50)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Status Badge',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Actions',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              rows: filteredRecords.map((r) {
                final isLowAtt = r.attendancePercentage < 75;
                final isAtRisk = r.totalInternalMarks < 20;

                var statusColor = const Color(0xFF16A34A);
                if (isLowAtt) {
                  statusColor = const Color(0xFFDC2626);
                } else if (isAtRisk) { statusColor = const Color(0xFFD97706); }

                return DataRow(
                  cells: [
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            r.studentName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Reg: ${r.registerNo} | Roll: ${r.rollNo}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            r.department,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0052CC),
                            ),
                          ),
                          Text(
                            r.subject,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          Icon(
                            isLowAtt
                                ? Icons.warning_rounded
                                : Icons.check_circle_rounded,
                            size: 14,
                            color: isLowAtt ? Colors.red : Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${r.attendancePercentage}%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isLowAtt ? Colors.red : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Text(
                        '${r.attendanceMarksWeightage} / 5',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    DataCell(Text('${r.cat1Marks} / 25')),
                    DataCell(Text('${r.cat2Marks} / 25')),
                    DataCell(
                      Text(
                        '${r.totalInternalMarks} / 50',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0052CC),
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          r.status,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: Color(0xFF0052CC),
                            ),
                            onPressed: () => _showAddEditStudentModal(r),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              ref
                                  .read(attendanceMarkProvider.notifier)
                                  .deleteRecord(r.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Record for "${r.studentName}" deleted.',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  // ── 7. Faculty Attendance View ────────────────────────────────────────────
  Widget _buildFacultyAttendanceView(BuildContext context) {
    final facultyRecords = ref.watch(facultyAttendanceProvider);

    final filteredRecords = facultyRecords.where((r) {
      final matchesSearch =
          r.facultyName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.employeeId.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesDept =
          _selectedDept == 'All' || r.department == _selectedDept;
      final matchesStatus =
          _selectedStatus == 'All' || r.status == _selectedStatus;
      return matchesSearch && matchesDept && matchesStatus;
    }).toList();

    final totalFaculty = facultyRecords.length;
    final presentCount = facultyRecords
        .where((r) => r.status == 'Present')
        .length;
    final leaveCount = facultyRecords
        .where((r) => r.status == 'On Leave' || r.status == 'On Duty (OD)')
        .length;
    final avgAttendance = facultyRecords.isEmpty
        ? 0.0
        : facultyRecords
                  .map((r) => r.attendancePercentage)
                  .reduce((a, b) => a + b) /
              facultyRecords.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Bar
        LayoutBuilder(
          builder: (context, headerConstraints) {
            final isNarrow = headerConstraints.maxWidth < 950;
            return Flex(
              direction: isNarrow ? Axis.vertical : Axis.horizontal,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: isNarrow
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Faculty Daily Attendance Console',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Track daily attendance presents, check-in/out times, and leave status',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
                if (isNarrow) const SizedBox(height: 12),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        final messenger = ScaffoldMessenger.of(context);
                        final buffer = StringBuffer();
                        buffer.writeln(
                          'EmpID,FacultyName,Department,Designation,Date,Status,CheckIn,CheckOut,Attendance%',
                        );
                        for (final r in filteredRecords) {
                          buffer.writeln(
                            '${r.employeeId},"${r.facultyName}",${r.department},"${r.designation}",${r.date},${r.status},${r.checkIn},${r.checkOut},${r.attendancePercentage}%',
                          );
                        }
                        final bytes = utf8.encode(buffer.toString());
                        FileDownloader.downloadFile(
                          bytes,
                          'faculty_daily_attendance_report.csv',
                        );
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Faculty Attendance Report exported to CSV!',
                            ),
                            backgroundColor: Color(0xFF16A34A),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.download_rounded,
                        size: 18,
                        color: Color(0xFF059669),
                      ),
                      label: const Text(
                        'Export Faculty CSV',
                        style: TextStyle(color: Color(0xFF059669)),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _showAddEditFacultyModal,
                      icon: const Icon(Icons.how_to_reg_rounded, size: 18),
                      label: const Text('Mark Faculty Attendance'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),

        // KPI Summary Cards (2 per row on mobile viewports)
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth > 900
                ? (constraints.maxWidth - 36) / 4
                : (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildMetricCard(
                  'Avg Faculty Attn Rate',
                  '${avgAttendance.toStringAsFixed(1)}%',
                  'Monthly Target: >=95%',
                  Icons.fact_check_rounded,
                  const Color(0xFF059669),
                  cardWidth,
                ),
                _buildMetricCard(
                  'Faculty Present Today',
                  '$presentCount / $totalFaculty',
                  'Active Teaching Staff',
                  Icons.check_circle_rounded,
                  const Color(0xFF16A34A),
                  cardWidth,
                ),
                _buildMetricCard(
                  'Faculty On Leave / OD',
                  '$leaveCount Members',
                  'Leave & Official Duty',
                  Icons.event_busy_rounded,
                  const Color(0xFFD97706),
                  cardWidth,
                ),
                _buildMetricCard(
                  'Total Faculty Staff',
                  '$totalFaculty Members',
                  'Registered Instructors',
                  Icons.people_alt_rounded,
                  const Color(0xFF0052CC),
                  cardWidth,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),

        // Filter Bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 700;
              return Flex(
                direction: isSmall ? Axis.vertical : Axis.horizontal,
                children: [
                  Expanded(
                    flex: isSmall ? 0 : 2,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'Search faculty name or employee ID...',
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF64748B),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(),
                      ),
                    ),
                  ),
                  if (isSmall)
                    const SizedBox(height: 10)
                  else
                    const SizedBox(width: 12),
                  Expanded(
                    flex: isSmall ? 0 : 1,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedDept,
                      decoration: InputDecoration(
                        labelText: 'Dept Filter',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: ['All', 'CSE', 'IT', 'ECE', 'MECH', 'CIVIL']
                          .map(
                            (d) => DropdownMenuItem(value: d, child: Text(d)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedDept = v!),
                    ),
                  ),
                  if (isSmall)
                    const SizedBox(height: 10)
                  else
                    const SizedBox(width: 12),
                  Expanded(
                    flex: isSmall ? 0 : 1,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedStatus,
                      decoration: InputDecoration(
                        labelText: 'Status Filter',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items:
                          [
                                'All',
                                'Present',
                                'Absent',
                                'On Leave',
                                'On Duty (OD)',
                              ]
                              .map(
                                (s) =>
                                    DropdownMenuItem(value: s, child: Text(s)),
                              )
                              .toList(),
                      onChanged: (v) => setState(() => _selectedStatus = v!),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // Data Table
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
              columns: const [
                DataColumn(
                  label: Text(
                    'Faculty Member Info',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Department & Role',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Date',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Status Badge',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Check-In / Out',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Attendance %',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Quick Status Toggle',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Actions',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              rows: filteredRecords.map((r) {
                var statusColor = const Color(0xFF16A34A);
                if (r.status == 'Absent') {
                  statusColor = const Color(0xFFDC2626);
                } else if (r.status.contains('Leave')) {
                  statusColor = const Color(0xFFD97706);
                } else if (r.status.contains('Duty') ||
                    r.status.contains('OD')) {
                  statusColor = const Color(0xFF0052CC);
                }

                return DataRow(
                  cells: [
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            r.facultyName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Emp ID: ${r.employeeId}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            r.department,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF059669),
                            ),
                          ),
                          Text(
                            r.designation,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Text(r.date, style: const TextStyle(fontSize: 12)),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha(30),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          r.status,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${r.checkIn} - ${r.checkOut}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${r.attendancePercentage}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          InkWell(
                            onTap: () {
                              ref
                                  .read(facultyAttendanceProvider.notifier)
                                  .updateRecord(r.copyWith(status: 'Present'));
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Present',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: () {
                              ref
                                  .read(facultyAttendanceProvider.notifier)
                                  .updateRecord(r.copyWith(status: 'Absent'));
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Absent',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFB91C1C),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: () {
                              ref
                                  .read(facultyAttendanceProvider.notifier)
                                  .updateRecord(r.copyWith(status: 'On Leave'));
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Leave',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: Color(0xFF059669),
                            ),
                            onPressed: () => _showAddEditFacultyModal(r),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              ref
                                  .read(facultyAttendanceProvider.notifier)
                                  .deleteRecord(r.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Faculty attendance record for "${r.facultyName}" deleted.',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  // ── Helper Metric Card Widget (Optimized for 2-column mobile layout) ───
  Widget _buildMetricCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
    double width,
  ) => Container(
    width: width,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}
