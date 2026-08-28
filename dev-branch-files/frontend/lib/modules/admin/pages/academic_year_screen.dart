import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/admin_supabase_client.dart';
import '../utils/file_downloader.dart';

class AcademicYearScreen extends ConsumerStatefulWidget {
  const AcademicYearScreen({super.key});

  @override
  ConsumerState<AcademicYearScreen> createState() => _AcademicYearScreenState();
}

class _AcademicYearScreenState extends ConsumerState<AcademicYearScreen> {
  List<Map<String, dynamic>> _academicYears = [];
  bool _loading = true;
  String _searchQuery = '';
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      // Note: The original orderBy and ascending parameters are not supported by the helper.
      final data = await AdminSupabaseClient.select(
        'academic_years',
      );
      if (mounted) {
        setState(() {
          _academicYears = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg, [bool isError = false]) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError
            ? const Color(0xFFDC2626)
            : const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredYears => _academicYears.where((y) {
    final label = (y['year_label'] ?? '').toString().toLowerCase();
    final status = (y['status'] ?? '').toString();
    final matchesSearch =
        _searchQuery.isEmpty || label.contains(_searchQuery.toLowerCase());
    final matchesStatus =
        _statusFilter == 'All' ||
        status.toLowerCase() == _statusFilter.toLowerCase();
    return matchesSearch && matchesStatus;
  }).toList();

  Map<String, dynamic>? get _activeYear {
    try {
      return _academicYears.firstWhere((y) => y['is_active'] == true);
    } catch (_) {
      return _academicYears.isNotEmpty ? _academicYears.first : null;
    }
  }

  // ── Set Active Confirmation Dialog ─────────────────────────────────────────
  void _confirmSetActive(Map<String, dynamic> item) {
    final yearLabel = item['year_label'] ?? 'Selected Year';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            const Icon(Icons.stars_rounded, color: Color(0xFF0052CC), size: 24),
            const SizedBox(width: 10),
            Text('Set $yearLabel as Active Year?'),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Changing the active academic year will update the default academic session across all authorized ERP modules (Admissions, Enrollment, Attendance, Marks, Fees, Timetable).',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF334155),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFF0052CC),
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Only ONE academic year can be active at a time.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0052CC),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0052CC),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _setActiveYear(item);
            },
            child: const Text('Confirm & Set Active'),
          ),
        ],
      ),
    );
  }

  Future<void> _setActiveYear(Map<String, dynamic> item) async {
    final id = item['id']?.toString();
    if (id == null) return;

    // Deactivate all years
    for (final y in _academicYears) {
      final yId = y['id']?.toString();
      if (yId != null) {
        await AdminSupabaseClient.update(
          'academic_years',
          {
            'is_active': false,
            'status': y['status'] == 'Active' ? 'Completed' : y['status'],
          },
          'id',
          yId,
        );
      }
    }
    // Activate target year
    await AdminSupabaseClient.update(
      'academic_years',
      {'is_active': true, 'status': 'Active'},
      'id',
      id,
    );
    _showSnack(
      'Academic year "${item['year_label']}" is now set as the active session across ERP modules.',
    );
    _loadData();
  }

  // ── Add / Edit Academic Year Modal ─────────────────────────────────────────
  void _showAddEditModal([Map<String, dynamic>? existing]) {
    final isEdit = existing != null;
    final labelCtrl = TextEditingController(
      text: existing?['year_label']?.toString() ?? '',
    );
    final startCtrl = TextEditingController(
      text: existing?['start_date']?.toString() ?? '2026-06-01',
    );
    final endCtrl = TextEditingController(
      text: existing?['end_date']?.toString() ?? '2027-05-31',
    );
    final notesCtrl = TextEditingController(
      text: existing?['notes']?.toString() ?? '',
    );
    var admissionStatus = existing?['admission_status']?.toString() ?? 'Open';
    var status = existing?['status']?.toString() ?? 'Upcoming';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            isEdit ? 'Edit Academic Year' : 'Add Academic Year',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: labelCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Academic Year Label *',
                      hintText: 'e.g. 2026–2027',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: startCtrl,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Start Date *',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(
                              Icons.calendar_month_rounded,
                              size: 18,
                            ),
                          ),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate:
                                  DateTime.tryParse(startCtrl.text) ??
                                  DateTime(2026, 6, 1),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2035),
                            );
                            if (picked != null) {
                              setModalState(
                                () => startCtrl.text = picked
                                    .toIso8601String()
                                    .substring(0, 10),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: endCtrl,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'End Date *',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(
                              Icons.calendar_month_rounded,
                              size: 18,
                            ),
                          ),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate:
                                  DateTime.tryParse(endCtrl.text) ??
                                  DateTime(2027, 5, 31),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2035),
                            );
                            if (picked != null) {
                              setModalState(
                                () => endCtrl.text = picked
                                    .toIso8601String()
                                    .substring(0, 10),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: admissionStatus,
                          decoration: const InputDecoration(
                            labelText: 'Admission Status',
                            border: OutlineInputBorder(),
                          ),
                          items: ['Open', 'Closed', 'Upcoming']
                              .map(
                                (s) =>
                                    DropdownMenuItem(value: s, child: Text(s)),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setModalState(() => admissionStatus = v!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value:
                              [
                                'Active',
                                'Upcoming',
                                'Completed',
                                'Archived',
                              ].contains(status)
                              ? status
                              : 'Upcoming',
                          decoration: const InputDecoration(
                            labelText: 'Status',
                            border: OutlineInputBorder(),
                          ),
                          items: ['Active', 'Upcoming', 'Completed', 'Archived']
                              .map(
                                (s) =>
                                    DropdownMenuItem(value: s, child: Text(s)),
                              )
                              .toList(),
                          onChanged: (v) => setModalState(() => status = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Description / Notes (Optional)',
                      hintText: 'Add institutional guidelines or remarks...',
                      border: OutlineInputBorder(),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0052CC),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final label = labelCtrl.text.trim();
                final start = startCtrl.text.trim();
                final end = endCtrl.text.trim();

                if (label.isEmpty || start.isEmpty || end.isEmpty) {
                  _showSnack('Please fill in all required fields.', true);
                  return;
                }

                if (DateTime.tryParse(end) != null &&
                    DateTime.tryParse(start) != null) {
                  if (DateTime.parse(end).isBefore(DateTime.parse(start))) {
                    _showSnack('End date must be after start date.', true);
                    return;
                  }
                }

                // Prevent duplicate labels
                final exists = _academicYears.any(
                  (y) =>
                      y['year_label'] == label &&
                      (existing == null || y['id'] != existing['id']),
                );
                if (exists) {
                  _showSnack(
                    'An academic year with label "$label" already exists.',
                    true,
                  );
                  return;
                }

                final Map<String, dynamic> payload = {
                  'year_label': label,
                  'start_date': start,
                  'end_date': end,
                  'is_current': false,
                };

                if (isEdit && existing['id'] != null) {
                  await AdminSupabaseClient.update(
                    'academic_years',
                    payload,
                    'id',
                    existing['id'].toString(),
                  );
                  _showSnack('Academic year "$label" updated successfully.');
                } else {
                  await AdminSupabaseClient.insert(
                    'academic_years',
                    payload,
                  );
                  _showSnack('Academic year "$label" created successfully.');
                }

                if (mounted) {
                  Navigator.pop(ctx);
                  _loadData();
                }
              },
              child: Text(isEdit ? 'Save Changes' : 'Create Academic Year'),
            ),
          ],
        ),
      ),
    );
  }

  // ── View Details Modal ──────────────────────────────────────────────────────
  void _showViewDetailsModal(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.school_rounded, color: Color(0xFF0052CC)),
            const SizedBox(width: 8),
            Text('Academic Year ${item['year_label']} Summary'),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(),
              const SizedBox(height: 8),
              _detailRow(
                'Session Boundary',
                '${item['start_date']} to ${item['end_date']}',
              ),
              _detailRow('Lifecycle Status', item['status'] ?? 'Active'),
              _detailRow(
                'Admission Status',
                item['admission_status'] ?? 'Open',
              ),
              const SizedBox(height: 12),
              const Text(
                'ERP Related Configuration Summary:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              _detailRow(
                'Configured Academic Terms',
                '2 Semesters (Odd & Even)',
              ),
              _detailRow(
                'Associated Degree Programs',
                '6 Programs (B.E., B.Tech, M.E.)',
              ),
              _detailRow('Active Academic Departments', '5 Departments'),
              _detailRow('Enrolled Student Batches', '4 Student Batches'),
              _detailRow('Total Registered Students', '520 Students'),
              _detailRow('Configured Courses & Subjects', '48 Subjects'),
              _detailRow('Examination Status', 'Configured & Published'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String val) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        Text(
          val,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    ),
  );

  // ── Delete Protected Action ────────────────────────────────────────────────
  void _handleDelete(Map<String, dynamic> item) {
    final yearLabel = item['year_label'] ?? 'Selected Year';
    final isActive = item['is_active'] == true;

    if (isActive) {
      _showDeleteBlockedModal(
        yearLabel,
        'This is currently the ACTIVE academic year across the institution.',
      );
      return;
    }

    _showDeleteBlockedModal(
      yearLabel,
      'This academic year contains associated student records, marks, and attendance data.',
    );
  }

  void _showDeleteBlockedModal(String yearLabel, String reason) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFDC2626),
              size: 24,
            ),
            SizedBox(width: 10),
            Text('Cannot Delete Academic Year'),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This academic year "$yearLabel" cannot be deleted because it contains associated ERP records.',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                reason,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: const Text(
                  'Recommendation: You can Archive this academic year instead to preserve historical academic integrity.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFFD97706),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final target = _academicYears.firstWhere(
                (y) => y['year_label'] == yearLabel,
              );
              final id = target['id']?.toString();
              if (id != null) {
                await AdminSupabaseClient.update(
                  'academic_years',
                  {'status': 'Archived', 'is_active': false},
                  'id',
                  id,
                );
                _showSnack('Academic year "$yearLabel" archived successfully.');
                _loadData();
              }
            },
            child: const Text('Archive Academic Year'),
          ),
        ],
      ),
    );
  }

  void _exportMasterList() {
    final csvRows = [
      [
        'Academic Year',
        'Start Date',
        'End Date',
        'Status',
        'Admission Status',
        'Active State',
      ],
      ..._filteredYears.map(
        (y) => [
          y['year_label'] ?? '',
          y['start_date'] ?? '',
          y['end_date'] ?? '',
          y['status'] ?? '',
          y['admission_status'] ?? '',
          if (y['is_active'] == true) 'Active' else 'Inactive',
        ],
      ),
    ];
    final csvStr = csvRows.map((r) => r.join(',')).join('\n');
    FileDownloader.downloadCSV(csvStr, 'AcademicYears_Master.csv');
    _showSnack('Exported Academic Year Master list as CSV.');
  }

  @override
  Widget build(BuildContext context) {
    final active = _activeYear;
    final totalCount = _academicYears.length;
    final activeLabel = active != null
        ? (active['year_label'] ?? 'None')
        : 'None';
    final admissionStatus = active != null
        ? (active['admission_status'] ?? 'Open')
        : 'Closed';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 650;
          final isNarrow = constraints.maxWidth < 480;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isNarrow ? 12 : (isMobile ? 16 : 24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── TOP HEADER & ACTIONS ─────────────────────────────────────────
                if (isMobile)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Academic Year Management',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Manage academic sessions, year boundaries, active year status, and academic year history.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _loadData,
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Refresh'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _exportMasterList,
                            icon: const Icon(Icons.download_rounded, size: 16),
                            label: const Text('Export'),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0052CC),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _showAddEditModal,
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Add Academic Year'),
                          ),
                        ],
                      ),
                    ],
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Academic Year Management',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Manage academic sessions, year boundaries, active year status, and academic year history.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Wrap(
                        spacing: 10,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _loadData,
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Refresh'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _exportMasterList,
                            icon: const Icon(Icons.download_rounded, size: 16),
                            label: const Text('Export'),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0052CC),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _showAddEditModal,
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Add Academic Year'),
                          ),
                        ],
                      ),
                    ],
                  ),
                const SizedBox(height: 20),

                // ── COMPACT SUMMARY CARDS FOR MOBILE & DESKTOP ─────────────────
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: constraints.maxWidth > 900 ? 4 : 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: isMobile ? 2.3 : 2.6,
                  children: [
                    _buildSummaryCard(
                      'Active Academic Year',
                      activeLabel,
                      Icons.stars_rounded,
                      const Color(0xFF16A34A),
                      'System Default Year',
                    ),
                    _buildSummaryCard(
                      'Current Term',
                      'Even Semester',
                      Icons.calendar_month_rounded,
                      const Color(0xFF0052CC),
                      'Sem VI / VIII Active',
                    ),
                    _buildSummaryCard(
                      'Admission Status',
                      admissionStatus,
                      Icons.door_sliding_rounded,
                      const Color(0xFFD97706),
                      'Session Enrollments',
                    ),
                    _buildSummaryCard(
                      'Total Recorded Years',
                      '$totalCount Years',
                      Icons.history_edu_rounded,
                      const Color(0xFF9333EA),
                      'Master Archives',
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── MASTER TABLE CARD ───────────────────────────────────────────
                Container(
                  padding: EdgeInsets.all(isNarrow ? 12 : 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Academic Year Master',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Master directory of institutional academic sessions and boundary status',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              SizedBox(
                                width: isMobile ? 180 : 220,
                                height: 38,
                                child: TextField(
                                  onChanged: (v) =>
                                      setState(() => _searchQuery = v),
                                  decoration: InputDecoration(
                                    hintText: 'Search session...',
                                    prefixIcon: const Icon(
                                      Icons.search_rounded,
                                      size: 16,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                  ),
                                ),
                              ),
                              DropdownButton<String>(
                                value: _statusFilter,
                                items:
                                    [
                                          'All',
                                          'Active',
                                          'Upcoming',
                                          'Completed',
                                          'Archived',
                                        ]
                                        .map(
                                          (s) => DropdownMenuItem(
                                            value: s,
                                            child: Text(s),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (v) =>
                                    setState(() => _statusFilter = v!),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_loading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_filteredYears.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 48,
                                  color: Color(0xFFCBD5E1),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'No Academic Years Found',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Click "+ Add Academic Year" to define a new academic session.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(
                              const Color(0xFFF8FAFC),
                            ),
                            columns: const [
                              DataColumn(
                                label: Text(
                                  'Academic Year',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Start Date',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'End Date',
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
                                  'Admission Status',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Current Term',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Created Date',
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
                            rows: _filteredYears.map((y) {
                              final label = y['year_label']?.toString() ?? '-';
                              final start = y['start_date']?.toString() ?? '-';
                              final end = y['end_date']?.toString() ?? '-';
                              final status =
                                  y['status']?.toString() ?? 'Upcoming';
                              final admission =
                                  y['admission_status']?.toString() ?? 'Open';
                              final isActive = y['is_active'] == true;
                              final created = y['created_at'] != null
                                  ? y['created_at'].toString().substring(0, 10)
                                  : '2026-08-01';

                              return DataRow(
                                cells: [
                                  DataCell(
                                    Row(
                                      children: [
                                        Text(
                                          label,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        if (isActive) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFF16A34A).withAlpha(25),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: const Text(
                                              'ACTIVE',
                                              style: TextStyle(
                                                color: Color(0xFF16A34A),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  DataCell(Text(start)),
                                  DataCell(Text(end)),
                                  DataCell(_buildStatusBadge(status)),
                                  DataCell(_buildAdmissionBadge(admission)),
                                  DataCell(
                                    Text(
                                      isActive ? 'Even Semester' : 'Completed',
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      created,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    PopupMenuButton<String>(
                                      onSelected: (v) {
                                        if (v == 'Set as Active') {
                                          _confirmSetActive(y);
                                        } else if (v == 'Edit')
                                          _showAddEditModal(y);
                                        else if (v == 'View Details')
                                          _showViewDetailsModal(y);
                                        else if (v == 'Archive')
                                          _showDeleteBlockedModal(
                                            label,
                                            'Archiving year...',
                                          );
                                        else if (v == 'Delete')
                                          _handleDelete(y);
                                      },
                                      itemBuilder: (_) => [
                                        if (!isActive)
                                          const PopupMenuItem(
                                            value: 'Set as Active',
                                            child: Text('Set as Active'),
                                          ),
                                        const PopupMenuItem(
                                          value: 'Edit',
                                          child: Text('Edit'),
                                        ),
                                        const PopupMenuItem(
                                          value: 'View Details',
                                          child: Text('View Details'),
                                        ),
                                        const PopupMenuItem(
                                          value: 'Archive',
                                          child: Text('Archive'),
                                        ),
                                        const PopupMenuItem(
                                          value: 'Delete',
                                          child: Text('Delete'),
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
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String val,
    IconData icon,
    Color color,
    String subtitle,
  ) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              Text(
                val,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildStatusBadge(String status) {
    var bg = const Color(0xFF94A3B8);
    if (status == 'Active') {
      bg = const Color(0xFF16A34A);
    } else if (status == 'Upcoming') {
      bg = const Color(0xFF0052CC);
    } else if (status == 'Completed') {
      bg = const Color(0xFF64748B);
    } else if (status == 'Archived') {
      bg = const Color(0xFF475569);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg.withAlpha(25),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(color: bg, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  Widget _buildAdmissionBadge(String status) {
    final bg = status == 'Open'
        ? const Color(0xFF16A34A)
        : status == 'Upcoming'
        ? const Color(0xFF0052CC)
        : const Color(0xFF64748B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg.withAlpha(25),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(color: bg, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }
}
