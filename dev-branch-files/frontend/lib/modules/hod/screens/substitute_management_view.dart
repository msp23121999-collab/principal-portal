import 'package:flutter/material.dart';
import '../theme.dart';
import '../responsive.dart';
import '../../faculty/services/postgres_client.dart';

class SubstituteManagementView extends StatefulWidget {
  const SubstituteManagementView({super.key});

  @override
  State<SubstituteManagementView> createState() =>
      _SubstituteManagementViewState();
}

class _SubstituteManagementViewState extends State<SubstituteManagementView> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedFilter =
      'All Records'; // 'All Records', 'Pending', 'Confirmed'

  @override
  void initState() {
    super.initState();
    _substitutions.clear();
    _loadSubstitutions();
  }

  Future<void> _loadSubstitutions() async {
    final rows = await SupabaseClientHelper.select(
      'hod_substitutions',
      schema: 'hod',
    );
    if (!mounted) return;
    setState(() {
      _substitutions
        ..clear()
        ..addAll(
          rows.map(
            (row) => {
              'id': row['display_id'] ?? row['id'] ?? '',
              'absentFaculty': row['absent_faculty'] ?? '',
              'substituteFaculty': row['substitute_faculty'] ?? '',
              'subject': row['subject'] ?? '',
              'classSec': row['class_section'] ?? '',
              'date': row['substitute_date']?.toString() ?? '',
              'period': row['period'] ?? '',
              'reason': row['reason'] ?? '',
              'status': row['status'] ?? 'PENDING',
            },
          ),
        );
    });
  }

  final List<Map<String, dynamic>> _substitutions = [];
  /*
    {
      'id': 'SUB-2026-001',
      'absentFaculty': 'Prof. P. Ramya',
      'substituteFaculty': 'Prof. Muththukumaran',
      'subject': 'IOT2028 - Sensors & Actuators',
      'classSec': 'Year 2 - Sec A',
      'date': '21-Jul-2026',
      'period': 'Period 2 (09:30 - 10:30)',
      'reason': 'Casual Leave - Conference',
      'status': 'CONFIRMED',
    },
    {
      'id': 'SUB-2026-002',
      'absentFaculty': 'Dr. S. Karthi',
      'substituteFaculty': 'Dr. K. Ravichandran',
      'subject': 'IOT2029 - Embedded C & RTOS',
      'classSec': 'Year 3 - Sec B',
      'date': '22-Jul-2026',
      'period': 'Period 3 (10:45 - 11:45)',
      'reason': 'On Duty - BoS Meeting',
      'status': 'PENDING',
    },
    {
      'id': 'SUB-2026-003',
      'absentFaculty': 'Prof. K. Anand',
      'substituteFaculty': 'Prof. P. Ramya',
      'subject': 'IOT2031 - Cloud IoT Platforms',
      'classSec': 'Year 1 - Sec A',
      'date': '23-Jul-2026',
      'period': 'Period 5 (01:30 - 02:30)',
      'reason': 'Medical Leave',
      'status': 'CONFIRMED',
    },
  ];
  */

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate live KPI counts
    final totalCount = _substitutions.length;
    final pendingCount = _substitutions
        .where((s) => s['status'] == 'PENDING')
        .length;
    final confirmedCount = _substitutions
        .where((s) => s['status'] == 'CONFIRMED')
        .length;

    // Filter list safely
    String query = '';
    try {
      query = _searchCtrl.text.toLowerCase();
    } catch (_) {
      query = '';
    }

    final filteredList = _substitutions.where((item) {
      if (_selectedFilter == 'Pending' && item['status'] != 'PENDING')
        return false;
      if (_selectedFilter == 'Confirmed' && item['status'] != 'CONFIRMED')
        return false;

      if (query.isNotEmpty) {
        final absent = (item['absentFaculty'] ?? '').toString().toLowerCase();
        final sub = (item['substituteFaculty'] ?? '').toString().toLowerCase();
        final subject = (item['subject'] ?? '').toString().toLowerCase();
        final code = (item['id'] ?? '').toString().toLowerCase();
        return absent.contains(query) ||
            sub.contains(query) ||
            subject.contains(query) ||
            code.contains(query);
      }
      return true;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. HEADER SECTION ──
          HodSectionHeader(
            title: 'Substitute Management',
            breadcrumb:
                'Dashboard › Leave & Substitutes › Substitute Scheduling',
            academicYear: 'Academic Year 2025 - 2026',
            actions: [
              ElevatedButton.icon(
                onPressed: () => _openAssignSubstituteModal(context),
                icon: const Icon(
                  Icons.add_circle_outline,
                  size: 18,
                  color: Colors.white,
                ),
                label: const Text(
                  'Assign Substitute',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── 2. METRIC KPI CARDS ROW (3 CARDS) ──
          Row(
            children: [
              Expanded(
                child: _buildKpiCard(
                  title: 'Total Substitutions',
                  value: '$totalCount',
                  subtitle: 'This Semester',
                  icon: Icons.swap_horiz_rounded,
                  iconColor: const Color(0xFF2563EB),
                  valueColor: const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildKpiCard(
                  title: 'Pending Confirmation',
                  value: '$pendingCount',
                  subtitle: 'Awaiting Response',
                  icon: Icons.hourglass_empty_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  valueColor: const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildKpiCard(
                  title: 'Confirmed',
                  value: '$confirmedCount',
                  subtitle: 'Arranged & Notified',
                  icon: Icons.check_circle_outline_rounded,
                  iconColor: const Color(0xFF10B981),
                  valueColor: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── 3. FILTER CONTROLS CONTAINER ──
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Filter Pill Buttons
                Row(
                  children: [
                    _buildFilterPill('All Records'),
                    const SizedBox(width: 8),
                    _buildFilterPill('Pending'),
                    const SizedBox(width: 8),
                    _buildFilterPill('Confirmed'),
                  ],
                ),

                // Search Field
                SizedBox(
                  width: 320,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search,
                          size: 18,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              hintText: 'Search faculty or subject...',
                              hintStyle: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF94A3B8),
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── 4. SUBSTITUTE REGISTER DATATABLE CARD ──
          Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card Title Header
                  Row(
                    children: const [
                      Icon(
                        Icons.swap_horiz_rounded,
                        size: 20,
                        color: Color(0xFF2563EB),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Substitute Register',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Full Width Register Table
                  SizedBox(
                    width: double.infinity,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        const Color(0xFFF8FAFC),
                      ),
                      dataRowMaxHeight: 68,
                      columnSpacing: 16,
                      columns: const [
                        DataColumn(
                          label: Text(
                            'Absent Faculty',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Substitute',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Subject / Class',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Date & Period',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Reason',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Status',
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
                      rows: filteredList.map((item) {
                        final isConfirmed = item['status'] == 'CONFIRMED';

                        return DataRow(
                          cells: [
                            // Absent Faculty
                            DataCell(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    (item['absentFaculty'] as String?) ?? '-',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    (item['id'] as String?) ?? '-',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Substitute (Blue Accent Name)
                            DataCell(
                              Text(
                                (item['substituteFaculty'] as String?) ?? '-',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ),

                            // Subject / Class
                            DataCell(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    (item['subject'] as String?) ?? '-',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    (item['classSec'] as String?) ?? '-',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Date & Period
                            DataCell(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    (item['date'] as String?) ?? '-',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    (item['period'] as String?) ?? '-',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Reason
                            DataCell(
                              Text(
                                (item['reason'] as String?) ?? '-',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),

                            // Status Badge
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isConfirmed
                                      ? const Color(0xFFECFDF5)
                                      : const Color(0xFFFFF7ED),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isConfirmed ? 'CONFIRMED' : 'PENDING',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isConfirmed
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFF59E0B),
                                  ),
                                ),
                              ),
                            ),

                            // Actions
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!isConfirmed) ...[
                                    ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          item['status'] = 'CONFIRMED';
                                        });
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Substitute confirmed for ${item['absentFaculty']}!',
                                            ),
                                            backgroundColor: const Color(
                                              0xFF10B981,
                                            ),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF10B981,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        minimumSize: const Size(60, 28),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: const Text(
                                        'Confirm',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      size: 18,
                                      color: Color(0xFFEF4444),
                                    ),
                                    tooltip: 'Delete Record',
                                    onPressed: () =>
                                        _confirmDelete(context, item),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── FILTER PILL WIDGET BUILDER ──
  Widget _buildFilterPill(String title) {
    final isActive = _selectedFilter == title;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = title),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  // ── KPI CARD WIDGET BUILDER ──
  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Icon(icon, color: iconColor, size: 22),
          ),
        ],
      ),
    );
  }

  // ── ASSIGN SUBSTITUTE POPUP DIALOG ──
  void _openAssignSubstituteModal(BuildContext context) {
    final absentCtrl = TextEditingController(text: 'Dr. K. Ravichandran');
    final substituteCtrl = TextEditingController(text: 'Prof. Muththukumaran');
    final subjectCtrl = TextEditingController(
      text: 'IOT2030 - Cloud Protocols',
    );
    final classCtrl = TextEditingController(text: 'Year 4 - Sec A');
    final dateCtrl = TextEditingController(text: '24-Jul-2026');
    final periodCtrl = TextEditingController(text: 'Period 1 (08:30 - 09:30)');
    final reasonCtrl = TextEditingController(
      text: 'On Duty - Academic Inspection',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.swap_horiz_rounded, color: Color(0xFF2563EB)),
            SizedBox(width: 8),
            Text(
              'Assign Substitute Class',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: absentCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Absent Faculty Name *',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: substituteCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Substitute Faculty Name *',
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: subjectCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Subject Code & Title',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: classCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Class Section',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: dateCtrl,
                        decoration: const InputDecoration(labelText: 'Date'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: periodCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Period / Time Slot',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: reasonCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Reason for Absence',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (absentCtrl.text.trim().isEmpty ||
                  substituteCtrl.text.trim().isEmpty)
                return;

              setState(() {
                _substitutions.add({
                  'id': 'SUB-2026-00${_substitutions.length + 1}',
                  'absentFaculty': absentCtrl.text.trim(),
                  'substituteFaculty': substituteCtrl.text.trim(),
                  'subject': subjectCtrl.text.trim(),
                  'classSec': classCtrl.text.trim(),
                  'date': dateCtrl.text.trim(),
                  'period': periodCtrl.text.trim(),
                  'reason': reasonCtrl.text.trim(),
                  'status': 'PENDING',
                });
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Substitute assigned for ${absentCtrl.text.trim()} successfully!',
                  ),
                  backgroundColor: const Color(0xFF2563EB),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
            ),
            child: const Text(
              'Assign & Notify',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Delete Substitute Entry?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to remove substitute record for ${item['absentFaculty']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _substitutions.remove(item);
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Substitute entry removed.')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
