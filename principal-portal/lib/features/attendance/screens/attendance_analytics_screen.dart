import 'package:flutter/material.dart';
import '../../../core/filters/portal_filter_bar.dart';
import '../../../core/widgets/layout/tabbed_page.dart';
import '../widgets/department_attendance_tab.dart';
import '../widgets/faculty_attendance_tab.dart';
import '../widgets/overall_attendance_tab.dart';
import '../widgets/student_attendance_tab.dart';

class AttendanceAnalyticsScreen extends StatelessWidget {
  const AttendanceAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TabbedPage(
      title: 'Attendance Analytics',
      breadcrumbSegments: ['Analytics', 'Attendance'],
      subtitle: 'Overall, department, faculty, and student attendance',
      // Section 2: every tab below reports against this scope. Semester and
      // subject are left out — attendance is taken by day, not by paper.
      filterBar: PortalFilterBar(
        show: [
          PortalFilterKind.academicYear,
          PortalFilterKind.department,
          PortalFilterKind.program,
          PortalFilterKind.yearOfStudy,
        ],
      ),
      tabs: [
        PageTab(label: 'Overall', content: OverallAttendanceTab()),
        PageTab(label: 'Department', content: DepartmentAttendanceTab()),
        PageTab(label: 'Faculty', content: FacultyAttendanceTab()),
        PageTab(label: 'Student', content: StudentAttendanceTab()),
      ],
    );
  }
}
