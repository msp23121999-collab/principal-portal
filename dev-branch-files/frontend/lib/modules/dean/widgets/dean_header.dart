import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';
import '../models/app_state.dart';

class DeanHeader extends StatelessWidget {
  final VoidCallback? onToggleSidebar;

  const DeanHeader({super.key, this.onToggleSidebar});

  static const List<Map<String, String>> _pageHeaderDetails = [
    {'title': 'Dashboard', 'subtitle': "Here's an overview of academic performance across the institution."},
    {'title': 'Academic Overview', 'subtitle': 'Comprehensive performance metrics and department analysis.'},
    {'title': 'Curriculum & Regulations', 'subtitle': 'Autonomous regulations, schemes, and credit structure.'},
    {'title': 'Programmes & Courses', 'subtitle': 'Master degree programmes and course catalogue.'},
    {'title': 'Faculty Performance & Workload', 'subtitle': 'Faculty workload analysis and teaching metrics.'},
    {'title': 'Student Standing & Performance', 'subtitle': 'Student performance standings and academic probation.'},
    {'title': 'Attendance Analytics & Condonation', 'subtitle': 'Institutional attendance trends and shortage requests.'},
    {'title': 'Examination Management & Results', 'subtitle': 'End-semester evaluation status and result sign-offs.'},
    {'title': 'Lesson Plan & Syllabus Monitoring', 'subtitle': 'Syllabus coverage progress across all departments.'},
    {'title': 'CO-PO & Course Attainment', 'subtitle': 'Course outcome direct and indirect attainment matrix.'},
    {'title': 'Research, Publications & Grants', 'subtitle': 'Institutional research output, grants, and patents.'},
    {'title': 'Accreditation & Quality Assurance', 'subtitle': 'NAAC & NBA criteria compliance audit dashboard.'},
    {'title': 'Academic Calendar & Schedule', 'subtitle': 'Institutional master academic schedule and events.'},
    {'title': 'Academic Approvals', 'subtitle': 'Executive queue for leaves and profile update requests.'},
    {'title': 'Reports & Analytics Builder', 'subtitle': 'Generate custom institutional reports and exports.'},
    {'title': 'Departmental Comparison', 'subtitle': 'Inter-departmental benchmarking and leaderboard.'},
    {'title': 'Notifications & Circulars', 'subtitle': 'Broadcast official academic announcements and notices.'},
    {'title': 'Digital Repository & Downloads', 'subtitle': 'Central archive of academic documents and policies.'},
    {'title': 'Board of Studies (BoS) & Meetings', 'subtitle': 'BoS council meeting schedule and minutes archive.'},
    {'title': 'My Profile & Settings', 'subtitle': 'Dean account profile settings and preferences.'},
  ];

  @override
  Widget build(BuildContext context) {
    final appState = DeanAppStateProvider.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return ListenableBuilder(
      listenable: appState,
      builder: (context, child) {
        final currentIndex = appState.selectedNavIndex.clamp(0, _pageHeaderDetails.length - 1);
        final currentHeader = _pageHeaderDetails[currentIndex];

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          color: Colors.white,
          child: Row(
            children: [
              if (!isDesktop) ...[
                IconButton(
                  icon: const Icon(Icons.menu, color: DeanTheme.textDark),
                  onPressed: onToggleSidebar,
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Welcome, Dean',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: DeanTheme.textDark,
                      ),
                    ),
                  ],
                ),
              ),
              if (isDesktop) ...[
                // Batch Filter (Left of Academic Year)
                _buildDropdownFilter(
                  label: 'Batch',
                  value: appState.selectedBatch,
                  items: ['All Batches', '2024 - 2028', '2023 - 2027', '2022 - 2026', '2021 - 2025'],
                  onChanged: (val) {
                    if (val != null) appState.setBatch(val);
                  },
                ),
                const SizedBox(width: 12),
                // Academic Year Filter (Dynamically linked to selected Batch)
                _buildDropdownFilter(
                  label: 'Academic Year',
                  value: (appState.batchToAcademicYears[appState.selectedBatch] ?? ['2024 - 2025'])
                          .contains(appState.selectedAcademicYear)
                      ? appState.selectedAcademicYear
                      : (appState.batchToAcademicYears[appState.selectedBatch] ?? ['2024 - 2025']).first,
                  items: appState.batchToAcademicYears[appState.selectedBatch] ?? ['2024 - 2025'],
                  onChanged: (val) {
                    if (val != null) appState.setAcademicYear(val);
                  },
                ),
                const SizedBox(width: 12),
                // Semester Filter (Strictly ODD / EVEN)
                _buildDropdownFilter(
                  label: 'Semester',
                  value: appState.selectedSemester.contains('ODD') ? 'ODD Semesters' : 'EVEN Semesters',
                  items: ['ODD Semesters', 'EVEN Semesters'],
                  onChanged: (val) {
                    if (val != null) appState.setSemester(val);
                  },
                ),
                const SizedBox(width: 12),
              ],

              // Calendar Button (Click moves to Academic Overview page index 1)
              Tooltip(
                message: 'Go to Academic Overview',
                child: InkWell(
                  onTap: () => appState.setNavIndex(1),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: DeanTheme.bgCanvas,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: DeanTheme.cardBorder),
                    ),
                    child: const Icon(Icons.calendar_month_outlined, size: 18, color: DeanTheme.primaryBlue),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Notifications Bell Icon
              Stack(
                children: [
                  InkWell(
                    onTap: () => appState.setNavIndex(16),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: DeanTheme.bgCanvas,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: DeanTheme.cardBorder),
                      ),
                      child: const Icon(Icons.notifications_outlined, size: 18, color: DeanTheme.textDark),
                    ),
                  ),
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: DeanTheme.dangerRose,
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        '12',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Dean Profile Avatar & Name Popup Menu (Dropdown with LOGOUT ONLY)
              PopupMenuButton<String>(
                tooltip: 'Dean Profile Options',
                offset: const Offset(0, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (value) {
                  if (value == 'logout') {
                    try {
                      context.go('/');
                    } catch (_) {
                      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                    }
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout_rounded, size: 18, color: DeanTheme.dangerRose),
                        SizedBox(width: 10),
                        Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: DeanTheme.dangerRose,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: DeanTheme.bgCanvas,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: DeanTheme.cardBorder),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 16,
                        backgroundColor: DeanTheme.primaryBlue,
                        child: Text(
                          'RK',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'Dr. R. K. Sharma',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: DeanTheme.textDark,
                            ),
                          ),
                          Text(
                            'Dean Academics',
                            style: TextStyle(
                              fontSize: 10,
                              color: DeanTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down, size: 16, color: DeanTheme.textMuted),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDropdownFilter({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: DeanTheme.bgCanvas,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DeanTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: DeanTheme.textMuted,
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isDense: true,
              icon: const Icon(Icons.keyboard_arrow_down, size: 14, color: DeanTheme.primaryBlue),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: DeanTheme.textDark,
              ),
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
