import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/mock_delay.dart';
import '../data/faculty_mock_data.dart';
import '../models/faculty.dart';
import '../data/department_mock_data.dart';
import '../models/department.dart';
import '../data/student_mock_data.dart';
import '../models/student.dart';
import '../data/attendance_mock_data.dart';
import '../models/daily_attendance.dart';

final overallAttendanceTrendProvider = FutureProvider<List<DailyAttendance>>((
  ref,
) {
  return mockDelay(() => AttendanceMockData.lastTwoWeeks);
});

final departmentAttendanceProvider = FutureProvider<List<Department>>((ref) {
  return mockDelay(() => DepartmentMockData.all);
});

final facultyAttendanceProvider = FutureProvider<List<Faculty>>((ref) {
  return mockDelay(() => FacultyMockData.all);
});

final studentAttendanceProvider = FutureProvider<List<Student>>((ref) {
  return mockDelay(() => StudentMockData.all);
});
