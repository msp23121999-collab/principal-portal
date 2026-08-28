import 'package:flutter/material.dart';
import '../theme.dart';
import '../responsive.dart';
import '../export_dialog_helper.dart';

class ManagementModuleView extends StatefulWidget {
  final int initialTabIndex;
  final String title;

  const ManagementModuleView({
    super.key,
    this.initialTabIndex = 0,
    this.title = 'Academic Management Module',
  });

  @override
  State<ManagementModuleView> createState() => _ManagementModuleViewState();
}

class _ManagementModuleViewState extends State<ManagementModuleView> {
  int _activeTab = 0;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTabIndex;
  }

  @override
  void didUpdateWidget(ManagementModuleView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTabIndex != widget.initialTabIndex) {
      _activeTab = widget.initialTabIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Breadcrumb
          HodSectionHeader(
            title: 'Academic Management Central Hub',
            breadcrumb: 'Management > Attendance, Assignments, Grade Entry & Exams',
            academicYear: 'Academic Year 2025 - 2026',
            actions: [
              HodExportDialog.buildExportButton(
                context,
                onPressed: () => HodExportDialog.show(
                  context,
                  title: 'Export Management Data',
                  subtitle: 'Select export format for Academic Management records:',
                  moduleName: 'Academic Management',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Segmented Submodule Tab Navigation
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCompactTab(
                  label: 'Attendance (94.1%)',
                  icon: Icons.fact_check,
                  isActive: _activeTab == 0,
                  onTap: () => setState(() => _activeTab = 0),
                ),
                _buildCompactTab(
                  label: 'Assignments (24)',
                  icon: Icons.assignment,
                  isActive: _activeTab == 1,
                  onTap: () => setState(() => _activeTab = 1),
                ),
                _buildCompactTab(
                  label: 'Grade Entry (84.5%)',
                  icon: Icons.grade,
                  isActive: _activeTab == 2,
                  onTap: () => setState(() => _activeTab = 2),
                ),
                _buildCompactTab(
                  label: 'Exams & Schedule',
                  icon: Icons.edit_note,
                  isActive: _activeTab == 3,
                  onTap: () => setState(() => _activeTab = 3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tab Body Content
          _buildActiveSubmodule(),
        ],
      ),
    );
  }

  // 1. ATTENDANCE SUBMODULE
  Widget _buildAttendanceSubmodule(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _buildKpiCard('Total Students', '480', 'Enrolled Strength', Icons.groups, AppTheme.accentBlue)),
            const SizedBox(width: 8),
            Expanded(child: _buildKpiCard('Present Today', '452', '94.1% Attendance', Icons.check_circle, AppTheme.accentGreen)),
            const SizedBox(width: 8),
            Expanded(child: _buildKpiCard('Absent Today', '28', '5.9% Absentees', Icons.cancel, AppTheme.accentRose)),
            const SizedBox(width: 8),
            Expanded(child: _buildKpiCard('Faculty Attendance', '96.0%', '23/24 Present', Icons.badge, AppTheme.accentTeal)),
            const SizedBox(width: 8),
            Expanded(child: _buildKpiCard('Low Attendance Alert', '14', '< 75% Threshold', Icons.warning, AppTheme.accentOrange)),
            const SizedBox(width: 8),
            Expanded(child: _buildKpiCard('Attendance Defaulters', '6', 'Requires Warning', Icons.report_problem, AppTheme.accentPurple)),
          ],
        ),
        const SizedBox(height: 16),

        Card(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Student Attendance Directory & Eligibility Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    ElevatedButton.icon(
                      onPressed: () => _showDefaultersModal(context),
                      icon: const Icon(Icons.warning_amber, size: 16, color: Colors.white),
                      label: const Text('View Defaulter List (6)', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRose),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                    columns: const [
                      DataColumn(label: Text('Student Name & Reg No', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Class & Sec', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Subject', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Faculty', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Classes Conducted/Attended', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Attendance %', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Eligibility Status', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: [
                      DataRow(cells: [
                        const DataCell(Text('Kavyaa P S\n731622IOT001', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        const DataCell(Text('Year 4 • Sec A', style: TextStyle(fontSize: 12))),
                        const DataCell(Text('IOT2028: Sensors & Actuators', style: TextStyle(fontSize: 11))),
                        const DataCell(Text('Prof. Muththukumaran', style: TextStyle(fontSize: 11))),
                        const DataCell(Text('42 / 40 Attended', style: TextStyle(fontSize: 12))),
                        const DataCell(Text('95.2%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.accentGreen))),
                        const DataCell(Text('ELIGIBLE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.badgeGreenText))),
                        DataCell(IconButton(
                          icon: const Icon(Icons.visibility, size: 18, color: AppTheme.accentBlue),
                          onPressed: () => _showStudentAttendanceDetails(context, 'Kavyaa P S'),
                        )),
                      ]),
                      DataRow(cells: [
                        const DataCell(Text('Arun Kumar R\n731622IOT004', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        const DataCell(Text('Year 3 • Sec B', style: TextStyle(fontSize: 12))),
                        const DataCell(Text('IOT2029: Embedded C', style: TextStyle(fontSize: 11))),
                        const DataCell(Text('Dr. S. Karthi', style: TextStyle(fontSize: 11))),
                        const DataCell(Text('42 / 28 Attended', style: TextStyle(fontSize: 12))),
                        const DataCell(Text('66.6%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.accentRose))),
                        const DataCell(Text('DEFAULTER (<75%)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.accentRose))),
                        DataCell(IconButton(
                          icon: const Icon(Icons.visibility, size: 18, color: AppTheme.accentBlue),
                          onPressed: () => _showStudentAttendanceDetails(context, 'Arun Kumar R'),
                        )),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 2. ASSIGNMENTS SUBMODULE
  Widget _buildAssignmentsSubmodule(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _buildKpiCard('Total Assignments', '24', 'Created This Sem', Icons.assignment, AppTheme.accentBlue)),
            const SizedBox(width: 8),
            Expanded(child: _buildKpiCard('Active Assignments', '18', 'Open Submissions', Icons.pending_actions, AppTheme.accentGreen)),
            const SizedBox(width: 8),
            Expanded(child: _buildKpiCard('Pending Submissions', '42', 'Awaiting Upload', Icons.hourglass_top, AppTheme.accentOrange)),
            const SizedBox(width: 8),
            Expanded(child: _buildKpiCard('Submitted', '398', 'Received Uploads', Icons.task_alt, AppTheme.accentTeal)),
            const SizedBox(width: 8),
            Expanded(child: _buildKpiCard('Evaluated', '360', 'Marks Entered', Icons.grade, AppTheme.accentPurple)),
            const SizedBox(width: 8),
            Expanded(child: _buildKpiCard('Overdue', '2', 'Past Due Date', Icons.error_outline, AppTheme.accentRose)),
          ],
        ),
        const SizedBox(height: 16),

        Card(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Course Assignments & Submission Progress', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                    columns: const [
                      DataColumn(label: Text('Assignment Title & Code', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Subject', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Faculty', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Due Date', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Submissions', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Avg Marks', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Evaluation Status', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: [
                      DataRow(cells: [
                        const DataCell(Text('Assignment 1: SPI Sensor Interface\nIOT2028-A1', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        const DataCell(Text('IOT2028: Sensors & Actuators', style: TextStyle(fontSize: 11))),
                        const DataCell(Text('Prof. Muththukumaran', style: TextStyle(fontSize: 11))),
                        const DataCell(Text('25-Jul-2026', style: TextStyle(fontSize: 12))),
                        const DataCell(Text('58 / 60 Submitted', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.accentGreen))),
                        const DataCell(Text('18.5 / 20', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.accentBlue))),
                        const DataCell(Text('EVALUATED (96%)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.badgeGreenText))),
                        DataCell(IconButton(
                          icon: const Icon(Icons.arrow_forward, size: 18, color: AppTheme.accentBlue),
                          onPressed: () => _showAssignmentDetailsModal(context, 'Assignment 1: SPI Sensor Interface'),
                        )),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 3. GRADE ENTRY SUBMODULE
  Widget _buildGradeEntrySubmodule(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _buildKpiCard('Total Subjects', '28', 'Curriculum Subjects', Icons.menu_book, AppTheme.accentBlue)),
            const SizedBox(width: 8),
            Expanded(child: _buildKpiCard('Grade Entry Done', '24', 'Marks Submitted', Icons.check_circle, AppTheme.accentGreen)),
            const SizedBox(width: 8),
            Expanded(child: _buildKpiCard('Pending Entry', '4', 'Marks Awaited', Icons.pending, AppTheme.accentOrange)),
            const SizedBox(width: 8),
            Expanded(child: _buildKpiCard('Verified Grades', '22', 'Approved by HOD', Icons.verified, AppTheme.accentTeal)),
            const SizedBox(width: 8),
            Expanded(child: _buildKpiCard('Unverified Grades', '2', 'Requires Sign-off', Icons.rule, AppTheme.accentRose)),
            const SizedBox(width: 8),
            Expanded(child: _buildKpiCard('Avg Dept Score', '84.5%', 'Academic Rating', Icons.workspace_premium, AppTheme.accentPurple)),
          ],
        ),
        const SizedBox(height: 16),

        Card(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Internal Marks & Final Grade Entry Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                    columns: const [
                      DataColumn(label: Text('Subject Code & Name', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Faculty Assigned', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Semester & Sec', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Internal Marks', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('External Marks', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Verification Status', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: [
                      DataRow(cells: [
                        const DataCell(Text('IOT2028: IoT Sensors & Actuators', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        const DataCell(Text('Prof. Muththukumaran', style: TextStyle(fontSize: 11))),
                        const DataCell(Text('Sem IV • Sec A', style: TextStyle(fontSize: 12))),
                        const DataCell(Text('COMPLETED (100%)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.badgeGreenText))),
                        const DataCell(Text('PENDING EXAM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.accentOrange))),
                        const DataCell(Text('VERIFIED BY HOD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.badgeGreenText))),
                        DataCell(ElevatedButton(
                          onPressed: () => _openVerifyGradesModal(context, 'IOT2028: IoT Sensors & Actuators'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentBlue, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                          child: const Text('Verify Grades', style: TextStyle(color: Colors.white, fontSize: 11)),
                        )),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 4. EXAMS SUBMODULE
  Widget _buildExamsSubmodule(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _buildKpiCard('Upcoming Exams', '4', 'Scheduled Assessments', Icons.event_available, AppTheme.accentBlue)),
            const SizedBox(width: 8),
            Expanded(child: _buildKpiCard('Ongoing Exam', '1', 'Internal Assessment II', Icons.play_circle_fill, AppTheme.accentGreen)),
            const SizedBox(width: 8),
            Expanded(child: _buildKpiCard('Completed Exams', '12', 'Evaluated', Icons.task_alt, AppTheme.accentPurple)),
            const SizedBox(width: 8),
            Expanded(child: _buildKpiCard('Internal Assessments', '3', 'Continuous Eval', Icons.assignment, AppTheme.accentOrange)),
            const SizedBox(width: 8),
            Expanded(child: _buildKpiCard('University Exams', '2', 'Anna Univ Sem', Icons.account_balance, AppTheme.accentTeal)),
            const SizedBox(width: 8),
            Expanded(child: _buildKpiCard('Pending Hall Tickets', '0', '100% Generated', Icons.confirmation_number, AppTheme.accentIndigo)),
          ],
        ),
        const SizedBox(height: 16),

        Card(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Examination Schedule & Hall Seating Allocation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                    columns: const [
                      DataColumn(label: Text('Exam Name & Type', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Subject & Code', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Date & Session', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Hall Allocation', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Invigilator', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Result Status', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: [
                      DataRow(cells: [
                        const DataCell(Text('Internal Assessment II\nContinuous Assessment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        const DataCell(Text('IOT2028: Sensors & Actuators', style: TextStyle(fontSize: 11))),
                        const DataCell(Text('28-Jul-2026 • FN (09:30 AM)', style: TextStyle(fontSize: 12))),
                        const DataCell(Text('Halls L-204 & L-205', style: TextStyle(fontSize: 11))),
                        const DataCell(Text('Dr. S. Karthi', style: TextStyle(fontSize: 11))),
                        const DataCell(Text('SCHEDULED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.badgeBlueText))),
                        DataCell(IconButton(
                          icon: const Icon(Icons.arrow_forward, size: 18, color: AppTheme.accentBlue),
                          onPressed: () => _showExamScheduleModal(context, 'Internal Assessment II'),
                        )),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textSecondary), maxLines: 1),
              Icon(icon, color: color, size: 16),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 9, color: AppTheme.textMuted), maxLines: 1),
        ],
      ),
    );
  }

  void _showDefaultersModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Attendance Defaulters List (< 75%)', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentRose)),
          content: const SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(dense: true, title: Text('Arun Kumar R (731622IOT004)'), subtitle: Text('Attendance: 66.6% • Sem VI'), trailing: Text('Warning Sent', style: TextStyle(color: Colors.orange))),
                ListTile(dense: true, title: Text('Priya Dharshini M (731622IOT018)'), subtitle: Text('Attendance: 71.2% • Sem IV'), trailing: Text('Parent Alerted', style: TextStyle(color: Colors.red))),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Warning notices sent to all 6 defaulter parents!')));
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRose),
              child: const Text('Send Warning Notices', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showStudentAttendanceDetails(BuildContext context, String studentName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Attendance History: $studentName', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• Total Classes Conducted: 42'),
              Text('• Classes Attended: 40'),
              Text('• Attendance Percentage: 95.2%'),
              Text('• Status: ELIGIBLE FOR SEMESTER EXAMINATIONS'),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ],
        );
      },
    );
  }

  void _showAssignmentDetailsModal(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• Total Submissions Received: 58 / 60'),
              Text('• Average Marks: 18.5 / 20'),
              Text('• Evaluation Status: COMPLETED'),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ],
        );
      },
    );
  }

  void _openVerifyGradesModal(BuildContext context, String subject) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('HOD Grade Verification: $subject', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('Confirm verification and sign-off for internal assessment marks and grade sheets for this subject?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Grades verified and signed off for $subject!')));
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentGreen),
              child: const Text('Verify & Sign Off', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showExamScheduleModal(BuildContext context, String examName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Exam Schedule: $examName', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• Date: 28-Jul-2026 (Forenoon 09:30 AM - 12:30 PM)'),
              Text('• Examination Halls: L-204 & L-205'),
              Text('• Invigilator Assigned: Dr. S. Karthi'),
              Text('• Enrolled Students: 60'),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ],
        );
      },
    );
  }



  Widget _buildActiveSubmodule() {
    switch (_activeTab) {
      case 0:
        return _buildAttendanceSubmodule(context);
      case 1:
        return _buildAssignmentsSubmodule(context);
      case 2:
        return _buildGradeEntrySubmodule(context);
      case 3:
        return _buildExamsSubmodule(context);
      default:
        return _buildAttendanceSubmodule(context);
    }
  }

  Widget _buildCompactTab({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEFF6FF) : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isActive ? const Color(0xFF2563EB) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? const Color(0xFF2563EB) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? const Color(0xFF2563EB) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Retain legacy class for router compatibility
class ManagementView extends StatelessWidget {
  final String title;
  final IconData icon;

  const ManagementView({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    int initialTab = 0;
    if (title.contains('Assignments')) initialTab = 1;
    if (title.contains('Grade')) initialTab = 2;
    if (title.contains('Exams')) initialTab = 3;

    return ManagementModuleView(initialTabIndex: initialTab, title: title);
  }
}
