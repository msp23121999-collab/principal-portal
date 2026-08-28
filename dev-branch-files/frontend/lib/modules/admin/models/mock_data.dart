import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/department_model.dart';
import '../models/course_model.dart';
import '../models/regulation_model.dart';
import '../models/misc_models.dart';
import '../models/academic_schedule_model.dart';

import '../services/department_service.dart';
import '../services/programme_subject_service.dart';
import '../services/regulation_service.dart';
import '../services/admin_supabase_service.dart';
import '../shared/services/supabase_service.dart';

export '../models/user_model.dart';
export '../models/department_model.dart';
export '../models/course_model.dart';
export '../models/regulation_model.dart';
export '../models/misc_models.dart';
export '../models/academic_schedule_model.dart';

// ── 1. Users Notifier ────────────────────────────────────────────────────────
class UsersNotifier extends StateNotifier<List<UserModel>> {
  UsersNotifier([List<UserModel>? initial]) : super(initial ?? []) {
    loadUsersFromSupabase();
  }
  bool isLoading = false;
  String? errorMessage;
  bool isConnectedToSupabase = false;

  Future<void> loadUsersFromSupabase() async {
    isLoading = true;
    errorMessage = null;
    try {
      final rawList = await SupabaseService.instance.fetchTable('users');
      if (rawList.isNotEmpty) {
        state = rawList.map((m) => UserModel.fromSupabaseJson(m)).toList();
        isConnectedToSupabase = true;
      } else {
        final stList = await SupabaseService.instance.fetchTable('students');
        if (stList.isNotEmpty) {
          state = stList.map((st) => UserModel(
            id: st['id']?.toString() ?? '',
            name: st['name']?.toString() ?? '',
            email: '${st['roll_number'] ?? 'student'}@ksrce.ac.in',
            role: 'Student',
            department: st['department_code']?.toString() ?? 'CSE',
            node: 'Active Node',
            status: st['status']?.toString() ?? 'Active',
            rollNumber: st['roll_number']?.toString(),
            admissionNumber: st['admission_number']?.toString(),
            batch: st['batch']?.toString(),
            section: st['section']?.toString(),
          )).toList();
          isConnectedToSupabase = true;
        } else {
          state = [];
        }
      }
    } catch (e) {
      print('Error loading users from Supabase: $e');
      state = [];
    } finally {
      isLoading = false;
    }
  }

  Future<void> addUser(UserModel user) async {
    isLoading = true;
    errorMessage = null;
    try {
      final payload = user.toSupabaseJson();
      final inserted = await SupabaseService.instance.insertData('users', payload);
      if (inserted != null) {
        final insertedUser = UserModel.fromSupabaseJson(inserted);
        state = [insertedUser, ...state.where((u) => u.id != user.id)];
      } else {
        state = [user, ...state];
      }

      if (user.role == 'Student') {
        await SupabaseService.instance.insertData('students', {
          'name': user.name,
          'roll_number': user.rollNumber ?? user.admissionNumber ?? user.id,
          'admission_number': user.admissionNumber ?? user.rollNumber,
          'department_code': user.department,
          'batch': user.batch ?? '2022-2026',
          'section': user.section ?? 'A',
          'status': user.status,
        });
      }
    } catch (e) {
      print('Error adding user to Supabase: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> updateUser(UserModel user) async {
    try {
      final payload = user.toSupabaseJson();
      await SupabaseService.instance.updateData('users', payload, user.id);
      state = [
        for (final u in state)
          if (u.id == user.id) user else u,
      ];
    } catch (e) {
      print('Error updating user in Supabase: $e');
    }
  }

  Future<void> deleteUser(String id) async {
    try {
      await SupabaseService.instance.deleteData('users', id);
      state = state.where((u) => u.id != id).toList();
    } catch (e) {
      print('Error deleting user from Supabase: $e');
    }
  }
}

final usersProvider = StateNotifierProvider<UsersNotifier, List<UserModel>>((
  ref,
) => UsersNotifier());

// ── 2. Departments Notifier ──────────────────────────────────────────────────
class DepartmentsNotifier extends StateNotifier<List<DepartmentModel>> {
  DepartmentsNotifier([List<DepartmentModel>? initial]) : super(initial ?? []) {
    loadDepartments();
  }

  Future<void> loadDepartments() async {
    try {
      final data = await DepartmentService.fetchDepartments();
      if (data.isNotEmpty) {
        state = data
            .map(
              (json) => DepartmentModel(
                id: json['id']?.toString() ?? json['code']?.toString() ?? 'DEPT',
                name: json['name']?.toString() ?? json['department_name']?.toString() ?? 'Department',
                code: json['code']?.toString() ?? 'DEPT',
                hod: json['hod']?.toString() ?? json['hod_name']?.toString() ?? 'HOD',
                intakeCapacity: int.tryParse(json['capacity']?.toString() ?? json['intake_capacity']?.toString() ?? '60') ?? 60,
                status: json['status']?.toString() ?? 'Active',
              ),
            )
            .toList();
      } else {
        state = [];
      }
    } catch (_) {
      state = [];
    }
  }

  Future<void> addDepartment(DepartmentModel dept) async {
    state = [...state, dept];
    await DepartmentService.createDepartment({
      'code': dept.code,
      'name': dept.name,
      'hod': dept.hod,
      'hod_name': dept.hod,
      'intake_capacity': dept.intakeCapacity,
      'capacity': dept.intakeCapacity,
      'status': dept.status,
    });
    loadDepartments();
  }

  Future<void> updateDepartment(DepartmentModel dept) async {
    state = [
      for (final d in state)
        if (d.id == dept.id) dept else d,
    ];
    await DepartmentService.updateDepartment(dept.id, {
      'code': dept.code,
      'name': dept.name,
      'hod': dept.hod,
      'hod_name': dept.hod,
      'intake_capacity': dept.intakeCapacity,
      'capacity': dept.intakeCapacity,
      'status': dept.status,
    });
    loadDepartments();
  }

  Future<void> deleteDepartment(String id) async {
    state = state.where((d) => d.id != id).toList();
    await DepartmentService.deleteDepartment(id);
    loadDepartments();
  }
}

final departmentsProvider = StateNotifierProvider<DepartmentsNotifier, List<DepartmentModel>>((ref) => DepartmentsNotifier());

// ── 3. Courses (Programmes) Notifier ──────────────────────────────────────────
class CoursesNotifier extends StateNotifier<List<CourseModel>> {
  CoursesNotifier([List<CourseModel>? initial]) : super(initial ?? []) {
    loadCourses();
  }

  Future<void> loadCourses() async {
    try {
      final list = await ProgrammeSubjectService.fetchProgrammes();
      if (list.isNotEmpty) {
        state = list.map((json) => CourseModel(
          id: json['id']?.toString() ?? json['code']?.toString() ?? '',
          code: json['code']?.toString() ?? '',
          name: json['name']?.toString() ?? '',
          department: json['department']?.toString() ?? 'CSE',
          subjectsCount: 0,
          durationYears: int.tryParse(json['duration']?.toString() ?? '4') ?? 4,
          status: json['status']?.toString() ?? 'Active',
        )).toList();
      } else {
        state = [];
      }
    } catch (_) {
      state = [];
    }
  }

  Future<void> addCourse(CourseModel course) async {
    state = [...state, course];
    await ProgrammeSubjectService.createProgramme({
      'code': course.code,
      'name': course.name,
      'duration': course.durationYears,
      'status': course.status,
    });
    loadCourses();
  }

  Future<void> deleteCourse(String id) async {
    state = state.where((c) => c.id != id).toList();
    await ProgrammeSubjectService.deleteProgramme(id);
    loadCourses();
  }
}

final coursesProvider = StateNotifierProvider<CoursesNotifier, List<CourseModel>>((ref) => CoursesNotifier());

// ── 4. Subjects Notifier ──────────────────────────────────────────────────────
class SubjectsNotifier extends StateNotifier<List<SubjectModel>> {
  SubjectsNotifier([List<SubjectModel>? initial]) : super(initial ?? []) {
    loadSubjects();
  }

  Future<void> loadSubjects() async {
    try {
      final list = await ProgrammeSubjectService.fetchSubjects();
      if (list.isNotEmpty) {
        state = list.map((json) => SubjectModel(
          id: json['id']?.toString() ?? json['code']?.toString() ?? '',
          code: json['code']?.toString() ?? '',
          name: json['name']?.toString() ?? '',
          type: json['type']?.toString() ?? 'Core Theory',
          credits: int.tryParse(json['credits']?.toString() ?? '3') ?? 3,
          semester: int.tryParse(json['semester']?.toString() ?? '1') ?? 1,
          department: json['department']?.toString() ?? 'CSE',
          programmeId: json['programme_id']?.toString() ?? '',
          status: json['status']?.toString() ?? 'Active',
        )).toList();
      } else {
        state = [];
      }
    } catch (_) {
      state = [];
    }
  }

  Future<void> addSubject(SubjectModel subject) async {
    state = [...state, subject];
    await ProgrammeSubjectService.createSubject({
      'code': subject.code,
      'name': subject.name,
      'type': subject.type,
      'credits': subject.credits,
      'semester': subject.semester,
      'department': subject.department,
      'programme_id': subject.programmeId,
      'status': subject.status,
    });
    loadSubjects();
  }

  Future<void> deleteSubject(String id) async {
    state = state.where((s) => s.id != id).toList();
    await SupabaseService.instance.deleteData('subjects', id);
    loadSubjects();
  }
}

final subjectsProvider = StateNotifierProvider<SubjectsNotifier, List<SubjectModel>>((ref) => SubjectsNotifier());

// ── 5. Regulations Notifier ───────────────────────────────────────────────────
class RegulationsNotifier extends StateNotifier<List<RegulationModel>> {
  RegulationsNotifier([List<RegulationModel>? initial]) : super(initial ?? []) {
    loadRegulations();
  }

  Future<void> loadRegulations() async {
    try {
      final list = await RegulationService.fetchRegulations();
      if (list.isNotEmpty) {
        state = list.map((json) => RegulationModel.fromJson(json)).toList();
      } else {
        state = [];
      }
    } catch (_) {
      state = [];
    }
  }

  Future<void> addRegulation(RegulationModel reg) async {
    state = [...state, reg];
    await RegulationService.createRegulation(reg.toJson());
    loadRegulations();
  }

  Future<void> deleteRegulation(String id) async {
    state = state.where((r) => r.id != id).toList();
    await RegulationService.deleteRegulation(id);
    loadRegulations();
  }
}

final regulationsProvider = StateNotifierProvider<RegulationsNotifier, List<RegulationModel>>((ref) => RegulationsNotifier());

// ── 6. Academic Cycles (Years) Notifier ───────────────────────────────────────
class AcademicCyclesNotifier extends StateNotifier<List<AcademicCycleModel>> {
  AcademicCyclesNotifier([List<AcademicCycleModel>? initial]) : super(initial ?? []) {
    loadCycles();
  }

  Future<void> loadCycles() async {
    try {
      final list = await AdminSupabaseService.fetchAcademicYears();
      if (list.isNotEmpty) {
        state = list.map((json) => AcademicCycleModel(
          id: json['id']?.toString() ?? '',
          name: json['year_label']?.toString() ?? '2024-2025',
          startDate: json['start_date']?.toString() ?? '2024-06-01',
          endDate: json['end_date']?.toString() ?? '2025-05-31',
          status: (json['is_current'] == true || json['is_current']?.toString() == 'true') ? 'Active' : 'Inactive',
        )).toList();
      } else {
        state = [];
      }
    } catch (_) {
      state = [];
    }
  }

  Future<void> addCycle(AcademicCycleModel cycle) async {
    state = [...state, cycle];
    await SupabaseService.instance.insertData('academic_years', {
      'year_label': cycle.name,
      'start_date': cycle.startDate,
      'end_date': cycle.endDate,
      'is_current': cycle.status == 'Active',
    });
    loadCycles();
  }

  Future<void> deleteCycle(String id) async {
    state = state.where((c) => c.id != id).toList();
    await SupabaseService.instance.deleteData('academic_years', id);
    loadCycles();
  }
}

final academicCyclesProvider = StateNotifierProvider<AcademicCyclesNotifier, List<AcademicCycleModel>>((ref) => AcademicCyclesNotifier());

// ── 7. Audit Logs Notifier ───────────────────────────────────────────────────
class AuditLogsNotifier extends StateNotifier<List<AuditLogModel>> {
  AuditLogsNotifier([List<AuditLogModel>? initial]) : super(initial ?? []) {
    loadAuditLogs();
  }

  Future<void> loadAuditLogs() async {
    try {
      final list = await AdminSupabaseService.fetchAuditEntries();
      if (list.isNotEmpty) {
        state = list.map((json) => AuditLogModel(
          id: json['id']?.toString() ?? '',
          timestamp: json['timestamp']?.toString() ?? DateTime.now().toString(),
          description: json['description']?.toString() ?? 'System Action',
          operatorName: json['operator_name']?.toString() ?? 'Admin',
          level: json['level']?.toString() ?? 'INFO',
        )).toList();
      } else {
        state = [];
      }
    } catch (_) {
      state = [];
    }
  }
}

final auditLogsProvider = StateNotifierProvider<AuditLogsNotifier, List<AuditLogModel>>((ref) => AuditLogsNotifier());

// ── 8. Reports Notifier ───────────────────────────────────────────────────────
class ReportsNotifier extends StateNotifier<List<ReportModel>> {
  ReportsNotifier([List<ReportModel>? initial]) : super(initial ?? []) {
    loadReports();
  }

  Future<void> loadReports() async {
    try {
      final list = await AdminSupabaseService.fetchRepositoryDocuments();
      if (list.isNotEmpty) {
        state = list.map((json) => ReportModel(
          id: json['id']?.toString() ?? '',
          code: 'REP-${(json['id']?.toString() ?? '12345').substring(0, 5)}',
          title: json['file_name']?.toString() ?? 'Institutional Report',
          status: 'Completed',
          format: json['file_type']?.toString() ?? 'PDF',
        )).toList();
      } else {
        state = [];
      }
    } catch (_) {
      state = [];
    }
  }

  Future<void> addReport(ReportModel report) async {
    state = [report, ...state];
    await AdminSupabaseService.addRepositoryDocument({
      'file_name': report.title,
      'file_type': report.format,
      'uploaded_by': 'Admin System',
      'uploaded_at': DateTime.now().toIso8601String(),
    });
    loadReports();
  }
}

final reportsProvider = StateNotifierProvider<ReportsNotifier, List<ReportModel>>((ref) => ReportsNotifier());

// ── 9. Medical Alerts Notifier ────────────────────────────────────────────────
class MedicalAlertsNotifier extends StateNotifier<List<MedicalAlertModel>> {
  MedicalAlertsNotifier([List<MedicalAlertModel>? initial]) : super(initial ?? []);

  void addAlert(MedicalAlertModel alert) {
    state = [alert, ...state];
  }

  void deleteAlert(String id) {
    state = state.where((a) => a.id != id).toList();
  }
}

final medicalAlertsProvider = StateNotifierProvider<MedicalAlertsNotifier, List<MedicalAlertModel>>((ref) => MedicalAlertsNotifier());

// ── 10. Events Notifier ───────────────────────────────────────────────────────
class EventsNotifier extends StateNotifier<List<EventModel>> {
  EventsNotifier([List<EventModel>? initial]) : super(initial ?? []) {
    loadEvents();
  }

  Future<void> loadEvents() async {
    try {
      final list = await AdminSupabaseService.fetchMeetings();
      if (list.isNotEmpty) {
        state = list.map((json) => EventModel(
          id: json['id']?.toString() ?? '',
          title: json['title']?.toString() ?? '',
          date: json['date_time']?.toString() ?? json['date']?.toString() ?? '',
          venue: json['venue']?.toString() ?? '',
          coordinator: json['organizer']?.toString() ?? json['coordinator']?.toString() ?? '',
          status: json['status']?.toString() ?? 'Upcoming',
        )).toList();
      } else {
        state = [];
      }
    } catch (_) {
      state = [];
    }
  }

  Future<void> addEvent(EventModel event) async {
    state = [event, ...state];
    await SupabaseService.instance.insertData('meetings', {
      'title': event.title,
      'date_time': event.date,
      'venue': event.venue,
      'organizer': event.coordinator,
      'attendees': 'Faculty & Staff',
      'status': event.status,
    });
    loadEvents();
  }

  Future<void> deleteEvent(String id) async {
    state = state.where((e) => e.id != id).toList();
    await SupabaseService.instance.deleteData('meetings', id);
    loadEvents();
  }
}

final eventsProvider = StateNotifierProvider<EventsNotifier, List<EventModel>>((ref) => EventsNotifier());

// ── 11. Academic Events Notifier ──────────────────────────────────────────────
class AcademicEventsNotifier extends StateNotifier<List<AcademicEventModel>> {
  AcademicEventsNotifier([List<AcademicEventModel>? initial]) : super(initial ?? []) {
    loadAcademicEvents();
  }

  Future<void> loadAcademicEvents() async {
    try {
      final list = await AdminSupabaseService.fetchCirculars();
      if (list.isNotEmpty) {
        state = list.map((json) => AcademicEventModel(
          id: json['id']?.toString() ?? '',
          scheduleId: json['schedule_id']?.toString() ?? '',
          title: json['title']?.toString() ?? '',
          department: 'CSE',
          semester: 'Sem 1',
          category: 'Academic',
          startDate: json['published_date']?.toString() ?? '',
          endDate: json['published_date']?.toString() ?? '',
          venue: 'Main Auditorium',
          description: json['content']?.toString() ?? '',
          status: 'Upcoming',
        )).toList();
      } else {
        state = [];
      }
    } catch (_) {
      state = [];
    }
  }

  Future<void> addEvent(AcademicEventModel event) async {
    state = [...state, event];
    await SupabaseService.instance.insertData('circulars', {
      'title': event.title,
      'content': event.description,
      'published_by': 'Academic Registrar',
      'published_date': event.startDate,
      'target_audience': event.department,
    });
    loadAcademicEvents();
  }

  Future<void> updateEvent(AcademicEventModel event) async {
    state = [
      for (final e in state)
        if (e.id == event.id) event else e,
    ];
    await SupabaseService.instance.updateData('circulars', {
      'title': event.title,
      'content': event.description,
      'published_date': event.startDate,
    }, event.id);
    loadAcademicEvents();
  }

  Future<void> deleteEvent(String id) async {
    state = state.where((e) => e.id != id).toList();
    await SupabaseService.instance.deleteData('circulars', id);
    loadAcademicEvents();
  }

  void toggleStatus(String id) {
    state = [
      for (final e in state)
        if (e.id == id)
          e.copyWith(
            status: e.status == 'Completed'
                ? 'Upcoming'
                : e.status == 'Upcoming'
                ? 'Ongoing'
                : 'Completed',
          )
        else
          e,
    ];
  }
}

final academicEventsProvider = StateNotifierProvider<AcademicEventsNotifier, List<AcademicEventModel>>((ref) => AcademicEventsNotifier());

// ── 12. Academic Holidays & Milestones Notifiers ──────────────────────────────
class AcademicHolidaysNotifier extends StateNotifier<List<HolidayModel>> {
  AcademicHolidaysNotifier([List<HolidayModel>? initial]) : super(initial ?? []);
}

final academicHolidaysProvider = StateNotifierProvider<AcademicHolidaysNotifier, List<HolidayModel>>((ref) => AcademicHolidaysNotifier());

class AcademicMilestonesNotifier extends StateNotifier<List<AcademicMilestoneModel>> {
  AcademicMilestonesNotifier([List<AcademicMilestoneModel>? initial]) : super(initial ?? []);
}

final academicMilestonesProvider = StateNotifierProvider<AcademicMilestonesNotifier, List<AcademicMilestoneModel>>((ref) => AcademicMilestonesNotifier());

class AcademicScheduleDocNotifier extends StateNotifier<AcademicScheduleDocModel?> {
  AcademicScheduleDocNotifier([AcademicScheduleDocModel? initial]) : super(initial ?? null) {
    loadDoc();
  }

  Future<void> loadDoc() async {
    try {
      final list = await AdminSupabaseService.fetchRepositoryDocuments();
      if (list.isNotEmpty) {
        final doc = list.first;
        state = AcademicScheduleDocModel(
          id: doc['id']?.toString() ?? '',
          title: doc['file_name']?.toString() ?? 'Academic Calendar Document',
          pdfUrl: doc['file_path']?.toString() ?? '',
          pdfFileName: doc['file_name']?.toString() ?? 'Academic_Calendar.pdf',
          fileSize: doc['file_size']?.toString() ?? '2.4 MB',
          uploadedBy: doc['uploaded_by']?.toString() ?? 'Registrar',
          uploadedAt: doc['uploaded_at']?.toString() ?? DateTime.now().toString().split(' ')[0],
          academicYear: '2025-2026',
        );
      } else {
        state = null;
      }
    } catch (_) {
      state = null;
    }
  }

  Future<void> uploadPdf(String pdfFileName, String fileSize, String uploadedBy) async {
    state = AcademicScheduleDocModel(
      id: 'DOC-${DateTime.now().millisecondsSinceEpoch}',
      title: 'Academic Calendar 2025-26 (Approved)',
      pdfUrl: 'assets/docs/$pdfFileName',
      pdfFileName: pdfFileName,
      fileSize: fileSize,
      uploadedBy: uploadedBy,
      uploadedAt: DateTime.now().toString().split(' ')[0],
      academicYear: '2025-2026',
    );
    await AdminSupabaseService.addRepositoryDocument({
      'file_name': pdfFileName,
      'file_size': fileSize,
      'uploaded_by': uploadedBy,
      'file_type': 'PDF',
      'uploaded_at': DateTime.now().toIso8601String(),
    });
    loadDoc();
  }

  Future<void> deletePdf() async {
    if (state != null) {
      await AdminSupabaseService.deleteRepositoryDocument(state!.id);
    }
    state = null;
  }
}

final academicScheduleDocProvider = StateNotifierProvider<AcademicScheduleDocNotifier, AcademicScheduleDocModel?>((ref) => AcademicScheduleDocNotifier());

// ── Academic Schedule Filter Providers ─────────────────────────────────────────

final academicScheduleSearchQueryProvider = StateProvider<String>((ref) => '');
final academicScheduleDeptFilterProvider = StateProvider<String>((ref) => 'ALL');
final academicScheduleSemFilterProvider = StateProvider<String>((ref) => 'ALL');
final academicScheduleCategoryFilterProvider = StateProvider<String>((ref) => 'ALL');
final academicScheduleStatusFilterProvider = StateProvider<String>((ref) => 'ALL');

final filteredAcademicEventsProvider = Provider<List<AcademicEventModel>>((ref) {
  final events = ref.watch(academicEventsProvider);
  final search = ref.watch(academicScheduleSearchQueryProvider).toLowerCase();
  final dept = ref.watch(academicScheduleDeptFilterProvider);
  final sem = ref.watch(academicScheduleSemFilterProvider);
  final category = ref.watch(academicScheduleCategoryFilterProvider);
  final status = ref.watch(academicScheduleStatusFilterProvider);

  return events.where((e) {
    if (search.isNotEmpty &&
        !e.title.toLowerCase().contains(search) &&
        !e.description.toLowerCase().contains(search) &&
        !e.venue.toLowerCase().contains(search)) {
      return false;
    }
    if (dept != 'ALL' && e.department != dept) return false;
    if (sem != 'ALL' && e.semester != sem) return false;
    if (category != 'ALL' && e.category != category) return false;
    if (status != 'ALL' && e.status != status) return false;
    return true;
  }).toList();
});
