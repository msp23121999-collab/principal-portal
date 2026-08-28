import 'package:flutter/material.dart';
import '../theme.dart';
import '../hod_toast.dart';
import '../pdf_download_helper.dart';
import '../responsive.dart';
import '../../faculty/services/postgres_client.dart';

class TimetableManagementView extends StatefulWidget {
  const TimetableManagementView({super.key});

  @override
  State<TimetableManagementView> createState() => _TimetableManagementViewState();
}

class _TimetableManagementViewState extends State<TimetableManagementView> {
  // Navigation / Tabs: 0 for Timetable Management (Master Schedule), 1 for My Timetable
  int _activeTab = 0;

  // Search controller
  final TextEditingController _searchCtrl = TextEditingController();

  // Selected filters
  String _selectedBatch = 'Batch 2022 - 2026 (Year IV)';

  // Edit Mode state
  bool _isEditing = false;
  bool _hasUnsavedChanges = false;

  // Selected cell coordinates (dayIndex, periodIndex) for showing interactive options during Edit Mode
  int? _selectedEditDayIndex;
  int? _selectedEditPeriodIndex;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _clearTimetableData();
    _loadTimetableFromDatabase();
  }

  void _clearTimetableData() {
    final emptyMaster = List.generate(6, (_) => List.generate(6, (_) => <String, String>{'subject': 'FREE', 'code': '', 'instructor': '', 'room': ''}));
    final emptyMine = List.generate(6, (_) => List.generate(6, (_) => <String, String>{'subject': 'FREE', 'code': '', 'detail': '', 'room': ''}));
    _masterGridData = emptyMaster;
    _myGridData = emptyMine;
  }

  Future<void> _loadTimetableFromDatabase() async {
    final rows = await SupabaseClientHelper.select('class_timetables', schema: 'public');
    if (!mounted) return;
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    final master = List.generate(6, (_) => List.generate(6, (_) => <String, String>{'subject': 'FREE', 'code': '', 'instructor': '', 'room': ''}));
    for (final row in rows) {
      final day = days.indexWhere((value) => value.toLowerCase() == (row['day_of_week'] ?? '').toString().toLowerCase());
      final period = int.tryParse((row['period'] ?? row['period_number'] ?? '1').toString()) ?? 1;
      if (day < 0 || period < 1 || period > 6) continue;
      final code = (row['course_code'] ?? row['course_id'] ?? '').toString();
      master[day][period - 1] = {'subject': code.isEmpty ? 'null' : code, 'code': code, 'instructor': 'null', 'room': (row['room_no'] ?? 'null').toString()};
    }
    setState(() {
      _masterGridData = master;
      _myGridData = master.map((day) => day.map((cell) => {'subject': cell['subject'] ?? 'null', 'code': cell['code'] ?? '', 'detail': 'null', 'room': cell['room'] ?? 'null'}).toList()).toList();
    });
  }

  // Master Timetable Grid Data: 6 days (Mon-Sat), 6 periods (Period 1-6)
  final List<String> _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  
  final List<Map<String, String>> _periods = [
    {'name': 'PERIOD 1', 'time': '08:00 AM - 09:00 AM'},
    {'name': 'PERIOD 2', 'time': '09:15 AM - 10:15 AM'},
    {'name': 'PERIOD 3', 'time': '11:30 AM - 12:30 PM'},
    {'name': 'PERIOD 4', 'time': '01:30 PM - 02:30 PM'},
    {'name': 'PERIOD 5', 'time': '02:45 PM - 03:45 PM'},
    {'name': 'PERIOD 6', 'time': '04:00 PM - 05:00 PM'},
  ];

  // Master Schedule Grid Cells data (Monday to Saturday)
  late List<List<Map<String, String>>> _masterGridData = [
    // Monday
    [
      {'subject': 'FREE', 'code': '', 'instructor': '', 'room': ''},
      {'subject': 'History', 'code': 'LAW174', 'instructor': 'Surya', 'room': 'Rm. 302 (Main Block)'},
      {'subject': 'Cloud Protocols', 'code': 'CS401', 'instructor': 'Dr. K. Govindaraj', 'room': 'Rm. 303 (Main Block)'},
      {'subject': 'IoT Security', 'code': 'CS402', 'instructor': 'Prof. P. Ramya', 'room': 'Lab-3'},
      {'subject': 'Edge Computing', 'code': 'CS403', 'instructor': 'Dr. S. Karthi', 'room': 'Rm. 304 (Main Block)'},
      {'subject': 'FREE', 'code': '', 'instructor': '', 'room': ''},
    ],
    // Tuesday
    [
      {'subject': 'IoT Security', 'code': 'CS402', 'instructor': 'Prof. P. Ramya', 'room': 'Lab-3'},
      {'subject': 'FREE', 'code': '', 'instructor': '', 'room': ''},
      {'subject': 'Cloud Protocols', 'code': 'CS401', 'instructor': 'Dr. K. Govindaraj', 'room': 'Rm. 303 (Main Block)'},
      {'subject': 'History', 'code': 'LAW174', 'instructor': 'Surya', 'room': 'Rm. 302 (Main Block)'},
      {'subject': 'FREE', 'code': '', 'instructor': '', 'room': ''},
      {'subject': 'Edge Computing', 'code': 'CS403', 'instructor': 'Dr. S. Karthi', 'room': 'Rm. 304 (Main Block)'},
    ],
    // Wednesday
    [
      {'subject': 'History', 'code': 'LAW174', 'instructor': 'Surya', 'room': 'Rm. 302 (Main Block)'},
      {'subject': 'IoT Security', 'code': 'CS402', 'instructor': 'Prof. P. Ramya', 'room': 'Lab-3'},
      {'subject': 'FREE', 'code': '', 'instructor': '', 'room': ''},
      {'subject': 'Cloud Protocols', 'code': 'CS401', 'instructor': 'Dr. K. Govindaraj', 'room': 'Rm. 303 (Main Block)'},
      {'subject': 'Edge Computing', 'code': 'CS403', 'instructor': 'Dr. S. Karthi', 'room': 'Rm. 304 (Main Block)'},
      {'subject': 'FREE', 'code': '', 'instructor': '', 'room': ''},
    ],
    // Thursday
    [
      {'subject': 'FREE', 'code': '', 'instructor': '', 'room': ''},
      {'subject': 'History', 'code': 'LAW174', 'instructor': 'Surya', 'room': 'Rm. 302 (Main Block)'},
      {'subject': 'IoT Security', 'code': 'CS402', 'instructor': 'Prof. P. Ramya', 'room': 'Lab-3'},
      {'subject': 'FREE', 'code': '', 'instructor': '', 'room': ''},
      {'subject': 'Edge Computing', 'code': 'CS403', 'instructor': 'Dr. S. Karthi', 'room': 'Rm. 304 (Main Block)'},
      {'subject': 'History', 'code': 'LAW174', 'instructor': 'Surya', 'room': 'Rm. 302 (Main Block)'},
    ],
    // Friday
    [
      {'subject': 'Cloud Protocols', 'code': 'CS401', 'instructor': 'Dr. K. Govindaraj', 'room': 'Rm. 303 (Main Block)'},
      {'subject': 'FREE', 'code': '', 'instructor': '', 'room': ''},
      {'subject': 'History', 'code': 'LAW174', 'instructor': 'Surya', 'room': 'Rm. 302 (Main Block)'},
      {'subject': 'IoT Security', 'code': 'CS402', 'instructor': 'Prof. P. Ramya', 'room': 'Lab-3'},
      {'subject': 'FREE', 'code': '', 'instructor': '', 'room': ''},
      {'subject': 'FREE', 'code': '', 'instructor': '', 'room': ''},
    ],
    // Saturday
    [
      {'subject': 'FREE', 'code': '', 'instructor': '', 'room': ''},
      {'subject': 'FREE', 'code': '', 'instructor': '', 'room': ''},
      {'subject': 'Edge Computing', 'code': 'CS403', 'instructor': 'Dr. S. Karthi', 'room': 'Rm. 304 (Main Block)'},
      {'subject': 'FREE', 'code': '', 'instructor': '', 'room': ''},
      {'subject': 'FREE', 'code': '', 'instructor': '', 'room': ''},
      {'subject': 'FREE', 'code': '', 'instructor': '', 'room': ''},
    ],
  ];

  // My Timetable Grid Data: 6 days, 6 periods
  final List<List<Map<String, String>>> _myGridData = [
    // Monday
    [
      {'subject': 'IoT Sensors & Actuators', 'code': 'IOT2028', 'detail': 'Year 2 Sec A', 'room': 'Room L-204'},
      {'subject': 'FREE', 'code': '', 'detail': '', 'room': ''},
      {'subject': 'Embedded C Architecture', 'code': 'IOT2029', 'detail': 'Year 3 Sec B', 'room': 'Room L-205'},
      {'subject': 'FREE', 'code': '', 'detail': '', 'room': ''},
      {'subject': 'FREE', 'code': '', 'detail': '', 'room': ''},
      {'subject': 'FREE', 'code': '', 'detail': '', 'room': ''},
    ],
    // Tuesday
    [
      {'subject': 'FREE', 'code': '', 'detail': '', 'room': ''},
      {'subject': 'Digital Signal Proc...', 'code': 'EC2045', 'detail': 'Year 3 Sec B', 'room': 'Room LH-301'},
      {'subject': 'FREE', 'code': '', 'detail': '', 'room': ''},
      {'subject': 'FREE', 'code': '', 'detail': '', 'room': ''},
      {'subject': 'Communication Sy...', 'code': 'EC2047', 'detail': 'Year 2 Sec C', 'room': 'Room LH-302'},
      {'subject': 'FREE', 'code': '', 'detail': '', 'room': ''},
    ],
    // Wednesday
    [
      {'subject': 'Embedded C Architecture', 'code': 'IOT2029', 'detail': 'Year 3 Sec B', 'room': 'Room L-205'},
      {'subject': 'FREE', 'code': '', 'detail': '', 'room': ''},
      {'subject': 'IoT Sensors & Actuators', 'code': 'IOT2028', 'detail': 'Year 2 Sec A', 'room': 'Room L-204'},
      {'subject': 'FREE', 'code': '', 'detail': '', 'room': ''},
      {'subject': 'FREE', 'code': '', 'detail': '', 'room': ''},
      {'subject': 'FREE', 'code': '', 'detail': '', 'room': ''},
    ],
    // Thursday
    [
      {'subject': 'FREE', 'code': '', 'detail': '', 'room': ''},
      {'subject': 'Digital Signal Proc...', 'code': 'EC2045', 'detail': 'Year 3 Sec B', 'room': 'Room LH-301'},
      {'subject': 'FREE', 'code': '', 'detail': '', 'room': ''},
      {'subject': 'Communication Sy...', 'code': 'EC2047', 'detail': 'Year 2 Sec C', 'room': 'Room LH-302'},
      {'subject': 'FREE', 'code': '', 'detail': '', 'room': ''},
      {'subject': 'FREE', 'code': '', 'detail': '', 'room': ''},
    ],
    // Friday
    [
      {'subject': 'IoT Sensors & Actuators', 'code': 'IOT2028', 'detail': 'Year 2 Sec A', 'room': 'Room L-204'},
      {'subject': 'FREE', 'code': '', 'detail': '', 'room': ''},
      {'subject': 'FREE', 'code': '', 'detail': '', 'room': ''},
      {'subject': 'Embedded C Architecture', 'code': 'IOT2029', 'detail': 'Year 3 Sec B', 'room': 'Room L-205'},
      {'subject': 'FREE', 'code': '', 'detail': '', 'room': ''},
      {'subject': 'FREE', 'code': '', 'detail': '', 'room': ''},
    ],
    // Saturday
    [
      {'subject': 'FREE', 'code': '', 'detail': '', 'room': ''},
      {'subject': 'FREE', 'code': '', 'detail': '', 'room': ''},
      {'subject': 'FREE', 'code': '', 'detail': '', 'room': ''},
      {'subject': 'FREE', 'code': '', 'detail': '', 'room': ''},
      {'subject': 'FREE', 'code': '', 'detail': '', 'room': ''},
      {'subject': 'FREE', 'code': '', 'detail': '', 'room': ''},
    ],
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgCanvas,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── TOP HEADER & BREADCRUMBS ──
            _buildHeaderRow(),
            const SizedBox(height: 12),

            // ── TIMETABLE TABS / SELECTOR ──
            _buildTimetableTabsRow(),
            const SizedBox(height: 12),

            // ── ACTIVE SUB-VIEW CONTENT ──
            _activeTab == 0 ? _buildMasterTimetableSubmodule() : _buildMyTimetableSubmodule(),
          ],
        ),
      ),
    );
  }

  // ── HEADER ROW ──
  Widget _buildHeaderRow() {
    final String breadcrumb = _activeTab == 0
        ? 'Academic Management > Timetable Management > Master Schedule'
        : 'Academic Management > Timetable Management > My Timetable';

    return HodSectionHeader(
      title: 'Timetable Management',
      breadcrumb: breadcrumb,
      academicYear: 'Academic Year 2025 - 2026',
    );
  }

  // ── TWO COMPACT SELECTION TABS ──
  Widget _buildTimetableTabsRow() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Row(
        children: [
          _buildCompactTab(
            label: 'Timetable Management',
            icon: Icons.calendar_month_rounded,
            isActive: _activeTab == 0,
            onTap: () {
              setState(() {
                _activeTab = 0;
                _isEditing = false;
                _selectedEditDayIndex = null;
                _selectedEditPeriodIndex = null;
              });
            },
          ),
          _buildCompactTab(
            label: 'My Timetable',
            icon: Icons.badge_outlined,
            isActive: _activeTab == 1,
            onTap: () {
              setState(() {
                _activeTab = 1;
                _isEditing = false;
                _selectedEditDayIndex = null;
                _selectedEditPeriodIndex = null;
              });
            },
          ),
        ],
      ),
    );
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

  // ── SUBMODULE 1: MASTER TIMETABLE ──
  Widget _buildMasterTimetableSubmodule() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title block
        const Text(
          'Timetable Management',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Weekly class schedule and room allocations strictly active',
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 20),

        // Search Bar
        _buildSearchBar(),
        const SizedBox(height: 20),

        // KPI Cards Row (4 Cards)
        _buildMasterKpiRow(),
        const SizedBox(height: 24),

        // Filters and Action Buttons Row
        _buildMasterActionRow(),
        const SizedBox(height: 20),

        // Master Timetable Grid Card
        _buildTimetableGridCard(isMaster: true),
      ],
    );
  }

  // ── SUBMODULE 2: MY TIMETABLE ──
  Widget _buildMyTimetableSubmodule() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Block (Dynamic for My Timetable as per image)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Teaching & Academic Curriculum Module',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Teaching > Courses, Timetable, Syllabus, Details & Course Diary',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () {
                PdfDownloadHelper.showExportConfirmation(
                  context,
                  title: 'Faculty Teaching File',
                );
              },
              icon: const Icon(Icons.download_rounded, size: 16, color: Colors.white),
              label: const Text(
                'Export Teaching File',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // KPI Cards Row (5 Cards)
        _buildMyKpiRow(),
        const SizedBox(height: 28),

        // Section Title: My Timetable Schedule Grid
        const Text(
          'My Timetable Schedule Grid',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),

        // My Timetable Grid Card
        _buildTimetableGridCard(isMaster: false),
      ],
    );
  }

  // ── SEARCH BAR WIDGET ──
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (val) {
          setState(() {}); // Redraw filters
        },
        decoration: const InputDecoration(
          hintText: 'Search by Subject, Code, Room or Instructor...',
          hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          prefixIcon: Icon(Icons.search, size: 20, color: Color(0xFF94A3B8)),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  // ── MASTER TIMETABLE KPI ROW ──
  Widget _buildMasterKpiRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double spacing = 16.0;
        final int columns = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 600 ? 2 : 1);
        final double cardWidth = (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        final cards = [
          _buildKpiCard(
            title: 'TOTAL SCHEDULED PERIODS',
            value: '38 Hrs',
            subtitle: '6 Days (Mon - Sat)',
            icon: Icons.calendar_today_outlined,
            iconColor: const Color(0xFF2563EB),
            iconBg: const Color(0xFFEFF6FF),
          ),
          _buildKpiCard(
            title: 'THEORY LECTURES',
            value: '32 Classes',
            subtitle: 'Lecture halls assigned',
            icon: Icons.menu_book_outlined,
            iconColor: const Color(0xFF9333EA),
            iconBg: const Color(0xFFF3E8FF),
          ),
          _buildKpiCard(
            title: 'LAB & WORKSHOP SESSIONS',
            value: '6 Periods',
            subtitle: 'Computer & HW labs',
            icon: Icons.science_outlined,
            iconColor: const Color(0xFF10B981),
            iconBg: const Color(0xFFECFDF5),
          ),
          _buildKpiCard(
            title: 'ACTIVE CLASSROOMS',
            value: '6 Halls',
            subtitle: 'LH-301 to LH-310',
            icon: Icons.meeting_room_outlined,
            iconColor: const Color(0xFFF59E0B),
            iconBg: const Color(0xFFFFFBEB),
          ),
        ];

        if (columns == 4) {
          return Row(
            children: cards.map((c) => Expanded(child: Padding(padding: EdgeInsets.only(right: c != cards.last ? spacing : 0), child: c))).toList(),
          );
        } else if (columns == 2) {
          return Column(
            children: [
              Row(children: [Expanded(child: cards[0]), SizedBox(width: spacing), Expanded(child: cards[1])]),
              SizedBox(height: spacing),
              Row(children: [Expanded(child: cards[2]), SizedBox(width: spacing), Expanded(child: cards[3])]),
            ],
          );
        } else {
          return Column(
            children: cards.map((c) => Padding(padding: EdgeInsets.only(bottom: spacing), child: c)).toList(),
          );
        }
      },
    );
  }

  // ── MY TIMETABLE KPI ROW ──
  Widget _buildMyKpiRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double spacing = 12.0;
        final int columns = constraints.maxWidth > 1000 ? 5 : (constraints.maxWidth > 600 ? 3 : 1);

        final cards = [
          _buildKpiCard(
            title: 'Classes Today',
            value: '3',
            subtitle: 'Scheduled Lectures',
            icon: Icons.schedule_rounded,
            iconColor: const Color(0xFF2563EB),
            iconBg: const Color(0xFFEFF6FF),
          ),
          _buildKpiCard(
            title: 'Ongoing Class',
            value: '1',
            subtitle: 'L-204 (Sec A)',
            icon: Icons.play_arrow_rounded,
            iconColor: const Color(0xFF10B981),
            iconBg: const Color(0xFFECFDF5),
          ),
          _buildKpiCard(
            title: 'Upcoming Classes',
            value: '2',
            subtitle: 'Lab-IoT & L-205',
            icon: Icons.upcoming_rounded,
            iconColor: const Color(0xFF9333EA),
            iconBg: const Color(0xFFF3E8FF),
          ),
          _buildKpiCard(
            title: 'Free Hours',
            value: '2 Hours',
            subtitle: 'Research & Prep',
            icon: Icons.hourglass_empty_rounded,
            iconColor: const Color(0xFFF97316),
            iconBg: const Color(0xFFFFF7ED),
          ),
          _buildKpiCard(
            title: 'Substitutions',
            value: '0 Today',
            subtitle: 'Regular Timetable',
            icon: Icons.swap_horiz_rounded,
            iconColor: const Color(0xFF14B8A6),
            iconBg: const Color(0xFFF0FDFA),
          ),
        ];

        if (columns == 5) {
          return Row(
            children: cards.map((c) => Expanded(child: Padding(padding: EdgeInsets.only(right: c != cards.last ? spacing : 0), child: c))).toList(),
          );
        } else if (columns == 3) {
          return Column(
            children: [
              Row(children: [Expanded(child: cards[0]), SizedBox(width: spacing), Expanded(child: cards[1]), SizedBox(width: spacing), Expanded(child: cards[2])]),
              SizedBox(height: spacing),
              Row(children: [Expanded(child: cards[3]), SizedBox(width: spacing), Expanded(child: cards[4]), const Spacer()]),
            ],
          );
        } else {
          return Column(
            children: cards.map((c) => Padding(padding: EdgeInsets.only(bottom: spacing), child: c)).toList(),
          );
        }
      },
    );
  }

  // Single KPI Card Widget
  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── FILTER AND ACTION CONTROLS ROW ──
  Widget _buildMasterActionRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Dropdown filters
        Row(
          children: [
            // Dropdown 2: Batch Selection
            _buildDropdown(
              value: _selectedBatch,
              items: [
                'Batch 2022 - 2026 (Year IV)',
                'Batch 2023 - 2027 (Year III)',
                'Batch 2024 - 2028 (Year II)',
                'Batch 2025 - 2029 (Year I)',
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedBatch = val;
                    HodToast.show(context, message: 'Switched to schedule for $val');
                  });
                }
              },
            ),
          ],
        ),

        // Action Buttons: Edit, Save, Confirm
        Row(
          children: [
            // Edit button (Dark background)
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isEditing = !_isEditing;
                  if (!_isEditing) {
                    _selectedEditDayIndex = null;
                    _selectedEditPeriodIndex = null;
                  }
                  HodToast.show(
                    context,
                    message: _isEditing ? 'Editing Mode Active. Click a timetable slot to change details.' : 'Editing Mode Dismissed.',
                    isSuccess: _isEditing,
                  );
                });
              },
              icon: Icon(
                _isEditing ? Icons.close_rounded : Icons.edit_rounded,
                size: 16,
                color: Colors.white,
              ),
              label: Text(
                _isEditing ? 'Cancel Edit' : 'Edit',
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
            ),
            const SizedBox(width: 10),

            // Save button (Greyed out unless there are changes)
            ElevatedButton.icon(
              onPressed: (_isEditing && _hasUnsavedChanges)
                  ? () {
                      setState(() {
                        _hasUnsavedChanges = false;
                        _isEditing = false;
                        _selectedEditDayIndex = null;
                        _selectedEditPeriodIndex = null;
                        HodToast.show(context, message: 'Timetable modifications saved successfully!', isSuccess: true);
                      });
                    }
                  : null,
              icon: Icon(
                Icons.save_rounded,
                size: 16,
                color: (_isEditing && _hasUnsavedChanges) ? Colors.black87 : const Color(0xFF94A3B8),
              ),
              label: Text(
                'Save',
                style: TextStyle(
                  color: (_isEditing && _hasUnsavedChanges) ? Colors.black87 : const Color(0xFF94A3B8),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE2E8F0),
                disabledBackgroundColor: const Color(0xFFF1F5F9),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
            ),
            const SizedBox(width: 10),

            // Confirm button (Blue background)
            ElevatedButton.icon(
              onPressed: () {
                _showConfirmTimetableDialog();
              },
              icon: const Icon(Icons.check_circle_outline_rounded, size: 16, color: Colors.white),
              label: const Text(
                'Confirm',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Dropdown helper widget
  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textSecondary, size: 18),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
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
    );
  }

  // ── TIMETABLE GRID TABLE CARD ──
  Widget _buildTimetableGridCard({required bool isMaster}) {
    // Column widths: Day (120px), Period columns (170px each), Break Separator column (20px)
    final double dayWidth = 110.0;
    final double periodWidth = 175.0;
    final double breakWidth = 16.0;

    final double totalGridWidth = dayWidth + (periodWidth * 6) + breakWidth;

    return Card(
      color: Colors.white,
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: totalGridWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Grid Header Row
                _buildGridHeaderRow(dayWidth, periodWidth, breakWidth),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),

                // Grid Body Rows (Monday to Saturday)
                ...List.generate(_days.length, (dayIndex) {
                  return Column(
                    children: [
                      _buildGridDayRow(dayIndex, isMaster, dayWidth, periodWidth, breakWidth),
                      if (dayIndex < _days.length - 1)
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Grid Header Row Widget
  Widget _buildGridHeaderRow(double dayWidth, double periodWidth, double breakWidth) {
    return Container(
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          // Day Column
          SizedBox(
            width: dayWidth,
            child: const Padding(
              padding: EdgeInsets.only(left: 20),
              child: Text(
                'DAY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),

          // Period Columns (1 to 3)
          ...List.generate(3, (i) => _buildPeriodHeaderCell(_periods[i], periodWidth)),

          // Break Column (Lunch Break Spacer Header)
          SizedBox(
            width: breakWidth,
            child: const SizedBox.shrink(),
          ),

          // Period Columns (4 to 6)
          ...List.generate(3, (i) => _buildPeriodHeaderCell(_periods[i + 3], periodWidth)),
        ],
      ),
    );
  }

  // Individual Period Header Cell
  Widget _buildPeriodHeaderCell(Map<String, String> period, double width) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            period['name']!,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            period['time']!,
            style: const TextStyle(
              fontSize: 9,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Grid Day Row (e.g. Monday Row)
  Widget _buildGridDayRow(int dayIndex, bool isMaster, double dayWidth, double periodWidth, double breakWidth) {
    final String dayName = _days[dayIndex];
    final List<Map<String, String>> rowCells = isMaster ? _masterGridData[dayIndex] : _myGridData[dayIndex];

    // Filter by search query if any
    final query = _searchCtrl.text.trim().toLowerCase();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          // Day Cell
          SizedBox(
            width: dayWidth,
            child: Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Text(
                dayName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ),

          // Periods 1 to 3 cells
          ...List.generate(3, (pIndex) {
            final cell = rowCells[pIndex];
            final bool matchesSearch = query.isEmpty ||
                cell['subject']!.toLowerCase().contains(query) ||
                cell['code']!.toLowerCase().contains(query) ||
                (cell['instructor'] != null && cell['instructor']!.toLowerCase().contains(query)) ||
                cell['room']!.toLowerCase().contains(query);

            return SizedBox(
              width: periodWidth,
              height: 90,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Opacity(
                  opacity: matchesSearch ? 1.0 : 0.25,
                  child: _buildGridCell(dayIndex, pIndex, cell, isMaster),
                ),
              ),
            );
          }),

          // Lunch Break Separator Column
          SizedBox(
            width: breakWidth,
            height: 90,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFFFFEDD5), width: 1),
              ),
            ),
          ),

          // Periods 4 to 6 cells
          ...List.generate(3, (pIndex) {
            final realPeriodIndex = pIndex + 3;
            final cell = rowCells[realPeriodIndex];
            final bool matchesSearch = query.isEmpty ||
                cell['subject']!.toLowerCase().contains(query) ||
                cell['code']!.toLowerCase().contains(query) ||
                (cell['instructor'] != null && cell['instructor']!.toLowerCase().contains(query)) ||
                cell['room']!.toLowerCase().contains(query);

            return SizedBox(
              width: periodWidth,
              height: 90,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Opacity(
                  opacity: matchesSearch ? 1.0 : 0.25,
                  child: _buildGridCell(dayIndex, realPeriodIndex, cell, isMaster),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // Individual Timetable Grid Cell (FREE or Assigned Subject)
  Widget _buildGridCell(int dayIndex, int periodIndex, Map<String, String> data, bool isMaster) {
    final bool isFree = data['subject'] == 'FREE';

    if (isFree) {
      return InkWell(
        onTap: (_isEditing && isMaster) ? () => _handleCellTap(dayIndex, periodIndex, data) : null,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: (_isEditing && _selectedEditDayIndex == dayIndex && _selectedEditPeriodIndex == periodIndex)
                  ? const Color(0xFF2563EB)
                  : const Color(0xFFE2E8F0),
              width: 1.5,
            ),
          ),
          child: const Center(
            child: Text(
              'FREE',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      );
    }

    // Assigned Course/Subject Card (Green background, solid green left strip)
    return InkWell(
      onTap: () => _handleCellTap(dayIndex, periodIndex, data),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: (_isEditing && _selectedEditDayIndex == dayIndex && _selectedEditPeriodIndex == periodIndex)
                ? const Color(0xFF2563EB)
                : const Color(0xFFA7F3D0),
            width: (_isEditing && _selectedEditDayIndex == dayIndex && _selectedEditPeriodIndex == periodIndex) ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          children: [
            // Thick Left Green Bar Indicator
            Container(
              width: 4,
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Text Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 2.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      data['subject']!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF065F46),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data['code']!,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF047857),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isMaster ? data['instructor']! : data['detail']!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      data['room']!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Cell Interaction Handle
  void _handleCellTap(int dayIndex, int periodIndex, Map<String, String> data) {
    if (_isEditing && _activeTab == 0) {
      // Toggle edit selection
      setState(() {
        _selectedEditDayIndex = dayIndex;
        _selectedEditPeriodIndex = periodIndex;
      });
      _showEditSlotModal(dayIndex, periodIndex, data);
    } else {
      // Normal mode: Show details modal
      _showViewSlotDetailsModal(dayIndex, periodIndex, data);
    }
  }

  // Modal: View slot details
  void _showViewSlotDetailsModal(int dayIndex, int periodIndex, Map<String, String> data) {
    final String dayName = _days[dayIndex];
    final String timeSlot = _periods[periodIndex]['time']!;
    final String periodName = _periods[periodIndex]['name']!;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB), size: 24),
              const SizedBox(width: 10),
              Text(
                'Schedule Details - $periodName',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildModalDetailRow('Day / Schedule', dayName),
              _buildModalDetailRow('Timing Slot', timeSlot),
              const Divider(height: 20),
              _buildModalDetailRow('Subject Title', data['subject']!),
              if (data['code']!.isNotEmpty) _buildModalDetailRow('Subject Code', data['code']!),
              if (_activeTab == 0 && data['instructor']!.isNotEmpty)
                _buildModalDetailRow('Instructor', data['instructor']!),
              if (_activeTab == 1 && data['detail']!.isNotEmpty)
                _buildModalDetailRow('Target Class', data['detail']!),
              if (data['room']!.isNotEmpty) _buildModalDetailRow('Classroom/Hall', data['room']!),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
            ),
          ],
        );
      },
    );
  }

  // Modal helper row
  Widget _buildModalDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B), fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // Modal: Edit Slot Details in Edit Mode
  void _showEditSlotModal(int dayIndex, int periodIndex, Map<String, String> data) {
    final String dayName = _days[dayIndex];
    final String periodName = _periods[periodIndex]['name']!;

    // Initial values
    String selectedSubject = data['subject'] ?? 'FREE';
    if (selectedSubject.isEmpty) selectedSubject = 'FREE';

    // Subject mapping for auto-allocation
    final Map<String, Map<String, String>> subjectMapping = {
      'FREE': {'code': '', 'instructor': '', 'room': ''},
      'History': {'code': 'LAW174', 'instructor': 'Surya', 'room': 'Rm. 302 (Main Block)'},
      'Cloud Protocols': {'code': 'CS401', 'instructor': 'Dr. K. Govindaraj', 'room': 'Rm. 303 (Main Block)'},
      'IoT Security': {'code': 'CS402', 'instructor': 'Prof. P. Ramya', 'room': 'Lab-3'},
      'Edge Computing': {'code': 'CS403', 'instructor': 'Dr. S. Karthi', 'room': 'Rm. 304 (Main Block)'},
    };

    // Dynamically add existing subject if not present to avoid data loss
    if (!subjectMapping.containsKey(selectedSubject)) {
      subjectMapping[selectedSubject] = {
        'code': data['code'] ?? '',
        'instructor': data['instructor'] ?? '',
        'room': data['room'] ?? '',
      };
    }

    // Controllers
    final codeCtrl = TextEditingController(text: subjectMapping[selectedSubject]!['code']);
    final instructorCtrl = TextEditingController(text: subjectMapping[selectedSubject]!['instructor']);
    final roomCtrl = TextEditingController(text: subjectMapping[selectedSubject]!['room']);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              titlePadding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 8),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              actionsPadding: const EdgeInsets.only(left: 24, right: 24, top: 12, bottom: 20),
              title: Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: Color(0xFF8B5CF6), size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Schedule Timetable Slot',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          '$_selectedBatch • $dayName - $periodName',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        _selectedEditDayIndex = null;
                        _selectedEditPeriodIndex = null;
                      });
                    },
                    icon: const Icon(Icons.close, color: Color(0xFF64748B), size: 20),
                  ),
                ],
              ),
              content: SizedBox(
                width: 440,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SLOT TYPE Label
                    const Text(
                      'SLOT TYPE',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 8),
                    // Single slot type button: Academic Class
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF6366F1), width: 1.5),
                          ),
                          child: const Text(
                            'Academic Class',
                            style: TextStyle(
                              color: Color(0xFF4F46E5),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // SUBJECT Label
                    const Text(
                      'SUBJECT',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedSubject,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                          items: subjectMapping.keys.map((sub) {
                            String displayName = sub;
                            if (sub != 'FREE') {
                              displayName = '$sub (${subjectMapping[sub]!['code']})';
                            }
                            return DropdownMenuItem<String>(
                              value: sub,
                              child: Text(
                                displayName,
                                style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() {
                                selectedSubject = val;
                                codeCtrl.text = subjectMapping[val]!['code']!;
                                instructorCtrl.text = subjectMapping[val]!['instructor']!;
                                roomCtrl.text = subjectMapping[val]!['room']!;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // FACULTY Label
                    const Text(
                      'FACULTY',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: instructorCtrl,
                      readOnly: true,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF334155), fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (selectedSubject != 'FREE')
                      Row(
                        children: const [
                          Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Auto-allocated from Subject Allocation.',
                            style: TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedEditDayIndex = null;
                      _selectedEditPeriodIndex = null;
                    });
                  },
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _masterGridData[dayIndex][periodIndex] = {
                        'subject': selectedSubject,
                        'code': codeCtrl.text,
                        'instructor': instructorCtrl.text,
                        'room': roomCtrl.text,
                      };
                      _hasUnsavedChanges = true;
                      _selectedEditDayIndex = null;
                      _selectedEditPeriodIndex = null;
                    });
                    Navigator.pop(context);
                    HodToast.show(context, message: 'Slot modified. Save changes to commit updates.', isSuccess: true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: const Text('Apply Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Dialog: Confirm Timetable Layout
  void _showConfirmTimetableDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 24),
              SizedBox(width: 10),
              Text(
                'Confirm Timetable Layout',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to verify and confirm this weekly timetable layout? '
            'This action will lock the current master schedule for this batch and notify all assigned faculties.',
            style: TextStyle(fontSize: 13, height: 1.4, color: AppTheme.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                HodToast.show(
                  context,
                  message: 'Timetable Layout confirmed & lock applied!',
                  isSuccess: true,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'Confirm & Lock',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}
