import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/admin_supabase_client.dart';
import '../app/router/route_names.dart';

class AcademicConfigScreen extends ConsumerStatefulWidget {
  const AcademicConfigScreen({super.key});

  @override
  ConsumerState<AcademicConfigScreen> createState() =>
      _AcademicConfigScreenState();
}

class _AcademicConfigScreenState extends ConsumerState<AcademicConfigScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> _masterYears = [];
  String? _selectedYearLabel;
  Map<String, dynamic>? _selectedYearRecord;

  List<Map<String, dynamic>> _cycles = [];
  List<Map<String, dynamic>> _batches = [];
  List<Map<String, dynamic>> _milestones = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMasterYears();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMasterYears() async {
    setState(() => _loading = true);
    try {
      final years = await AdminSupabaseClient.select('academic_years',
          orderBy: 'start_date', ascending: false);
      if (mounted) {
        setState(() {
          _masterYears = years;
          if (_masterYears.isNotEmpty) {
            final active = _masterYears.firstWhere(
                (y) => y['is_active'] == true,
                orElse: () => _masterYears.first);
            _selectedYearLabel = active['year_label']?.toString();
            _selectedYearRecord = active;
          }
          _loading = false;
        });
        if (_selectedYearLabel != null) {
          _loadConfigData();
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadConfigData() async {
    if (_selectedYearLabel == null) return;
    setState(() => _loading = true);
    try {
      final cycles =
          await AdminSupabaseClient.select('academic_cycles');
      final batches = await AdminSupabaseClient.select('enrollment_batches');
      final milestones =
          await AdminSupabaseClient.select('term_milestones');

      if (mounted) {
        setState(() {
          _cycles = cycles
              .where((c) => c['academic_year'] == _selectedYearLabel)
              .toList();
          _batches = batches
              .where((b) => b['academic_year'] == _selectedYearLabel)
              .toList();
          _milestones = milestones
              .where((m) => m['academic_year'] == _selectedYearLabel)
              .toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg, [bool isError = false]) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            isError ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Tab 1: Add/Edit Academic Cycle Modal ───────────────────────────────────
  void _showAddEditCycleModal([Map<String, dynamic>? existing]) {
    final isEdit = existing != null;
    final nameCtrl =
        TextEditingController(text: existing?['term_name']?.toString() ?? '');
    final startCtrl = TextEditingController(
        text: existing?['start_date']?.toString() ?? '2025-12-15');
    final endCtrl = TextEditingController(
        text: existing?['end_date']?.toString() ?? '2026-05-20');
    var type = existing?['term_type']?.toString() ?? 'Even Semester';
    var status = existing?['status']?.toString() ?? 'Active';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isEdit ? 'Edit Academic Cycle' : 'Add Academic Cycle',
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Term Name *',
                      hintText: 'e.g. Even Semester (Sem II, IV, VI, VIII)',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: type,
                        decoration: const InputDecoration(
                            labelText: 'Term Type',
                            border: OutlineInputBorder()),
                        items: [
                          'Odd Semester',
                          'Even Semester',
                          'Trimester',
                          'Summer Term'
                        ]
                            .map((t) =>
                                DropdownMenuItem(value: t, child: Text(t)))
                            .toList(),
                        onChanged: (v) => setModalState(() => type = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: status,
                        decoration: const InputDecoration(
                            labelText: 'Status', border: OutlineInputBorder()),
                        items: ['Active', 'Completed', 'Upcoming']
                            .map((s) =>
                                DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (v) => setModalState(() => status = v!),
                      ),
                    ),
                  ],
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
                            suffixIcon:
                                Icon(Icons.calendar_month_rounded, size: 18)),
                        onTap: () async {
                          final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime(2025, 12, 15),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2035));
                          if (picked != null)
                            setModalState(() => startCtrl.text =
                                picked.toIso8601String().substring(0, 10));
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
                            suffixIcon:
                                Icon(Icons.calendar_month_rounded, size: 18)),
                        onTap: () async {
                          final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime(2026, 5, 20),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2035));
                          if (picked != null)
                            setModalState(() => endCtrl.text =
                                picked.toIso8601String().substring(0, 10));
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0052CC),
                  foregroundColor: Colors.white),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) {
                  _showSnack('Term Name is required.', true);
                  return;
                }

                final payload = {
                  'academic_year': _selectedYearLabel,
                  'term_name': name,
                  'term_type': type,
                  'start_date': startCtrl.text,
                  'end_date': endCtrl.text,
                  'status': status,
                };

                if (isEdit && existing['id'] != null) {
                  await AdminSupabaseClient.update('academic_cycles', payload,
                      'id', existing['id'].toString());
                  _showSnack('Academic Cycle "$name" updated.');
                } else {
                  await AdminSupabaseClient.insert('academic_cycles', payload);
                  _showSnack('Academic Cycle "$name" created.');
                }

                if (mounted) {
                  Navigator.pop(ctx);
                  _loadConfigData();
                }
              },
              child: Text(isEdit ? 'Save Changes' : 'Add Cycle'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab 2: Add/Edit Enrollment Batch Modal ─────────────────────────────────
  void _showAddEditBatchModal([Map<String, dynamic>? existing]) {
    final isEdit = existing != null;
    final batchCtrl = TextEditingController(
        text: existing?['batch_name']?.toString() ?? 'Batch 2025–2029');
    final countCtrl = TextEditingController(
        text: existing?['student_count']?.toString() ?? '120');
    final admYearCtrl = TextEditingController(
        text: existing?['admission_year']?.toString() ?? '2025');
    final gradYearCtrl = TextEditingController(
        text: existing?['expected_graduation_year']?.toString() ?? '2029');
    var program = existing?['program']?.toString() ?? 'B.E.';
    var dept =
        existing?['department']?.toString() ?? 'Computer Science & Engineering';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isEdit ? 'Edit Enrollment Batch' : 'Add Enrollment Batch',
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: batchCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Batch Name *',
                        hintText: 'e.g. Batch 2025–2029',
                        border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: program,
                          decoration: const InputDecoration(
                              labelText: 'Program',
                              border: OutlineInputBorder()),
                          items: ['B.E.', 'B.Tech', 'M.E.', 'MBA', 'MCA']
                              .map((p) =>
                                  DropdownMenuItem(value: p, child: Text(p)))
                              .toList(),
                          onChanged: (v) => setModalState(() => program = v!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: dept,
                          isExpanded: true,
                          decoration: const InputDecoration(
                              labelText: 'Department',
                              border: OutlineInputBorder()),
                          items: [
                            'Computer Science & Engineering',
                            'Information Technology',
                            'Electronics & Communication Engg',
                            'Mechanical Engineering',
                            'Civil Engineering',
                          ]
                              .map((d) => DropdownMenuItem(
                                  value: d,
                                  child:
                                      Text(d, overflow: TextOverflow.ellipsis)))
                              .toList(),
                          onChanged: (v) => setModalState(() => dept = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: admYearCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: 'Admission Year',
                              border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: gradYearCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: 'Expected Graduation Year',
                              border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: countCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Student Count',
                        border: OutlineInputBorder()),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0052CC),
                  foregroundColor: Colors.white),
              onPressed: () async {
                final name = batchCtrl.text.trim();
                if (name.isEmpty) {
                  _showSnack('Batch Name is required.', true);
                  return;
                }

                final payload = {
                  'academic_year': _selectedYearLabel,
                  'batch_name': name,
                  'program': program,
                  'department': dept,
                  'admission_year': admYearCtrl.text,
                  'expected_graduation_year': gradYearCtrl.text,
                  'student_count': int.tryParse(countCtrl.text) ?? 0,
                  'status': 'Active',
                };

                if (isEdit && existing['id'] != null) {
                  await AdminSupabaseClient.update('enrollment_batches',
                      payload, 'id', existing['id'].toString());
                  _showSnack('Batch "$name" updated.');
                } else {
                  await AdminSupabaseClient.insert(
                      'enrollment_batches', payload);
                  _showSnack('Batch "$name" created.');
                }

                if (mounted) {
                  Navigator.pop(ctx);
                  _loadConfigData();
                }
              },
              child: Text(isEdit ? 'Save Changes' : 'Add Batch'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab 3: Add/Edit Term Milestone Modal ───────────────────────────────────
  void _showAddEditMilestoneModal([Map<String, dynamic>? existing]) {
    final isEdit = existing != null;
    var milestoneName = existing?['milestone_name']?.toString() ??
        'Internal Assessment Test 1 (CAT-1)';
    var termName = existing?['term_name']?.toString() ?? 'Even Semester';
    final startCtrl = TextEditingController(
        text: existing?['start_date']?.toString() ?? '2026-02-10');
    final endCtrl = TextEditingController(
        text: existing?['end_date']?.toString() ?? '2026-02-18');
    var status = existing?['status']?.toString() ?? 'Upcoming';

    final milestoneOptions = [
      'Semester Commencement',
      'Continuous Assessment Test 1 (CAT-1)',
      'Continuous Assessment Test 2 (CAT-2)',
      'Practical & Laboratory Examinations',
      'End Semester Theory Examination (ESE)',
      'Provisional Result Publication',
      'Semester End',
      'Registration Deadline',
      'Add/Drop Deadline',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isEdit ? 'Edit Term Milestone' : 'Add Term Milestone',
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: milestoneOptions.contains(milestoneName)
                      ? milestoneName
                      : milestoneOptions.first,
                  isExpanded: true,
                  decoration: const InputDecoration(
                      labelText: 'Milestone Event *',
                      border: OutlineInputBorder()),
                  items: milestoneOptions
                      .map((m) => DropdownMenuItem(
                          value: m,
                          child: Text(m, overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (v) => setModalState(() => milestoneName = v!),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: termName,
                        decoration: const InputDecoration(
                            labelText: 'Target Term',
                            border: OutlineInputBorder()),
                        items: ['Odd Semester', 'Even Semester', 'Annual']
                            .map((t) =>
                                DropdownMenuItem(value: t, child: Text(t)))
                            .toList(),
                        onChanged: (v) => setModalState(() => termName = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: status,
                        decoration: const InputDecoration(
                            labelText: 'Status', border: OutlineInputBorder()),
                        items: ['Upcoming', 'Active', 'Completed', 'Cancelled']
                            .map((s) =>
                                DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (v) => setModalState(() => status = v!),
                      ),
                    ),
                  ],
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
                            suffixIcon:
                                Icon(Icons.calendar_month_rounded, size: 18)),
                        onTap: () async {
                          final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime(2026, 2, 10),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2035));
                          if (picked != null)
                            setModalState(() => startCtrl.text =
                                picked.toIso8601String().substring(0, 10));
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
                            suffixIcon:
                                Icon(Icons.calendar_month_rounded, size: 18)),
                        onTap: () async {
                          final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime(2026, 2, 18),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2035));
                          if (picked != null)
                            setModalState(() => endCtrl.text =
                                picked.toIso8601String().substring(0, 10));
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0052CC),
                  foregroundColor: Colors.white),
              onPressed: () async {
                final payload = {
                  'academic_year': _selectedYearLabel,
                  'milestone_name': milestoneName,
                  'term_name': termName,
                  'start_date': startCtrl.text,
                  'end_date': endCtrl.text,
                  'status': status,
                };

                if (isEdit && existing['id'] != null) {
                  await AdminSupabaseClient.update('term_milestones', payload,
                      'id', existing['id'].toString());
                  _showSnack('Milestone "$milestoneName" updated.');
                } else {
                  await AdminSupabaseClient.insert('term_milestones', payload);
                  _showSnack('Milestone "$milestoneName" added.');
                }

                if (mounted) {
                  Navigator.pop(ctx);
                  _loadConfigData();
                }
              },
              child: Text(isEdit ? 'Save Changes' : 'Add Milestone'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _masterYears.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_masterYears.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.school_outlined,
                    size: 64, color: Color(0xFFCBD5E1)),
                const SizedBox(height: 16),
                const Text('No Academic Years Configured Yet',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A))),
                const SizedBox(height: 8),
                const Text(
                    'Please create a master academic year in Academic Year Management first.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0052CC),
                      foregroundColor: Colors.white),
                  onPressed: () => context.go(RouteNames.academicYear),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('Go to Academic Year Management'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, outerConstraints) {
            final isMobile = outerConstraints.maxWidth < 700;
            return SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 12 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 1. PAGE HEADER & ACADEMIC YEAR SELECTOR ───────────────────────
                  Container(
                    padding: EdgeInsets.all(isMobile ? 14 : 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: LayoutBuilder(
                      builder: (context, headerConstraints) {
                        final isHeaderMobile = headerConstraints.maxWidth < 700;
                        return Flex(
                          direction:
                              isHeaderMobile ? Axis.vertical : Axis.horizontal,
                          crossAxisAlignment: isHeaderMobile
                              ? CrossAxisAlignment.start
                              : CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              flex: isHeaderMobile ? 0 : 1,
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Academic Year & Semester Configuration',
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                        letterSpacing: -0.3),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Configure semesters, enrollment batches, and academic milestones for the selected academic year.',
                                    style: TextStyle(
                                        fontSize: 12.5,
                                        color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                            if (isHeaderMobile) const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: const Color(0xFF0052CC)
                                        .withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.calendar_month_rounded,
                                      size: 16, color: Color(0xFF0052CC)),
                                  const SizedBox(width: 6),
                                  const Text('Academic Year: ',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12.5,
                                          color: Color(0xFF0052CC))),
                                  DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedYearLabel,
                                      icon: const Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          color: Color(0xFF0052CC)),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: Color(0xFF0F172A)),
                                      items: _masterYears.map((y) {
                                        final label =
                                            y['year_label']?.toString() ?? '';
                                        final isActive = y['is_active'] == true;
                                        return DropdownMenuItem(
                                          value: label,
                                          child: Text(
                                              '$label${isActive ? " (Active)" : ""}'),
                                        );
                                      }).toList(),
                                      onChanged: (v) {
                                        if (v != null) {
                                          setState(() {
                                            _selectedYearLabel = v;
                                            _selectedYearRecord =
                                                _masterYears.firstWhere((y) =>
                                                    y['year_label'] == v);
                                          });
                                          _loadConfigData();
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── 2. SCROLLABLE SEGMENTED TAB NAVIGATION BAR ───────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: TabBar(
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        labelColor: const Color(0xFF0052CC),
                        unselectedLabelColor: const Color(0xFF64748B),
                        labelStyle: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13.5),
                        unselectedLabelStyle: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13.5),
                        tabs: const [
                          Tab(
                            height: 44,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.loop_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Text('Academic Cycles'),
                                ],
                              ),
                            ),
                          ),
                          Tab(
                            height: 44,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.groups_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Text('Enrollment Batches'),
                                ],
                              ),
                            ),
                          ),
                          Tab(
                            height: 44,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.flag_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Text('Term Milestones'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── 3. TAB CONTENT VIEWS ─────────────────────────────────────────
                  AnimatedBuilder(
                    animation: _tabController,
                    builder: (context, _) {
                      final index = _tabController.index;
                      if (index == 0) return _buildCyclesTab();
                      if (index == 1) return _buildBatchesTab();
                      return _buildMilestonesTab();
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ── TAB 1: ACADEMIC CYCLES ─────────────────────────────────────────────────
  Widget _buildCyclesTab() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Semesters & Terms in $_selectedYearLabel',
                      style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                        'Configure institutional semester cycles and duration boundaries',
                        style:
                            TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0052CC),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _showAddEditCycleModal(),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Academic Cycle',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Center(
                  child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator()))
            else if (_cycles.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      const Icon(Icons.event_repeat_rounded,
                          size: 48, color: Color(0xFFCBD5E1)),
                      const SizedBox(height: 10),
                      const Text('No Academic Cycles Configured',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF64748B))),
                      const SizedBox(height: 4),
                      Text(
                          'Configure semesters or academic terms for $_selectedYearLabel.',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF94A3B8))),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0052CC),
                            foregroundColor: Colors.white),
                        onPressed: () => _showAddEditCycleModal(),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add Academic Cycle'),
                      ),
                    ],
                  ),
                ),
              )
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      horizontalMargin: 16,
                      columnSpacing: 24,
                      headingRowHeight: 44,
                      dataRowMaxHeight: 50,
                      headingRowColor:
                          MaterialStateProperty.all(const Color(0xFFF1F5F9)),
                      columns: const [
                        DataColumn(
                            label: Text('Term Name',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A)))),
                        DataColumn(
                            label: Text('Term Type',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A)))),
                        DataColumn(
                            label: Text('Start Date',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A)))),
                        DataColumn(
                            label: Text('End Date',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A)))),
                        DataColumn(
                            label: Text('Status',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A)))),
                        DataColumn(
                            label: Text('Current Term',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A)))),
                        DataColumn(
                            label: Text('Actions',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A)))),
                      ],
                      rows: _cycles.map((c) {
                        final isCurrent = c['is_current'] == true;
                        final status = c['status']?.toString() ?? 'Active';
                        Color sColor = const Color(0xFF16A34A);
                        if (status == 'Completed')
                          sColor = const Color(0xFF2563EB);
                        if (status == 'Upcoming')
                          sColor = const Color(0xFFD97706);

                        return DataRow(cells: [
                          DataCell(Text(c['term_name']?.toString() ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A)))),
                          DataCell(Text(
                              c['term_type']?.toString() ?? 'Semester',
                              style:
                                  const TextStyle(color: Color(0xFF334155)))),
                          DataCell(Text(c['start_date']?.toString() ?? '-',
                              style:
                                  const TextStyle(color: Color(0xFF334155)))),
                          DataCell(Text(c['end_date']?.toString() ?? '-',
                              style:
                                  const TextStyle(color: Color(0xFF334155)))),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                  color: sColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20)),
                              child: Text(status,
                                  style: TextStyle(
                                      color: sColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11)),
                            ),
                          ),
                          DataCell(
                            isCurrent
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                        color: const Color(0xFFDCFCE7),
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check_circle_rounded,
                                            size: 14, color: Color(0xFF166534)),
                                        SizedBox(width: 4),
                                        Text('YES (Active)',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF166534),
                                                fontSize: 11)),
                                      ],
                                    ),
                                  )
                                : const Text('No',
                                    style: TextStyle(color: Color(0xFF64748B))),
                          ),
                          DataCell(
                            PopupMenuButton<String>(
                              tooltip: 'Actions',
                              onSelected: (v) async {
                                if (v == 'Edit')
                                  _showAddEditCycleModal(c);
                                else if (v == 'Set as Current') {
                                  final id = c['id']?.toString();
                                  if (id != null) {
                                    for (final item in _cycles) {
                                      final itemId = item['id']?.toString();
                                      if (itemId != null)
                                        await AdminSupabaseClient.update(
                                            'academic_cycles',
                                            {'is_current': false},
                                            'id',
                                            itemId);
                                    }
                                    await AdminSupabaseClient.update(
                                        'academic_cycles',
                                        {'is_current': true},
                                        'id',
                                        id);
                                    _showSnack(
                                        'Term "${c['term_name']}" is now set as current term.');
                                    _loadConfigData();
                                  }
                                } else if (v == 'Delete') {
                                  final id = c['id']?.toString();
                                  if (id != null) {
                                    await AdminSupabaseClient.delete(
                                        'academic_cycles', 'id', id);
                                    _showSnack('Academic cycle deleted.');
                                    _loadConfigData();
                                  }
                                }
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                    value: 'Edit',
                                    child: Row(children: [
                                      Icon(Icons.edit_outlined, size: 16),
                                      SizedBox(width: 8),
                                      Text('Edit')
                                    ])),
                                if (!isCurrent)
                                  const PopupMenuItem(
                                      value: 'Set as Current',
                                      child: Row(children: [
                                        Icon(Icons.star_outline_rounded,
                                            size: 16),
                                        SizedBox(width: 8),
                                        Text('Set as Current')
                                      ])),
                                const PopupMenuItem(
                                    value: 'Delete',
                                    child: Row(children: [
                                      Icon(Icons.delete_outline_rounded,
                                          size: 16, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Delete',
                                          style: TextStyle(color: Colors.red))
                                    ])),
                              ],
                            ),
                          ),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );

  // ── TAB 2: ENROLLMENT BATCHES ──────────────────────────────────────────────
  Widget _buildBatchesTab() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enrollment Batches in $_selectedYearLabel',
                      style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                        'Manage student enrollment cohorts and graduation timelines',
                        style:
                            TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0052CC),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _showAddEditBatchModal(),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Enrollment Batch',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Center(
                  child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator()))
            else if (_batches.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      const Icon(Icons.groups_outlined,
                          size: 48, color: Color(0xFFCBD5E1)),
                      const SizedBox(height: 10),
                      const Text('No Enrollment Batches Configured',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF64748B))),
                      const SizedBox(height: 4),
                      Text(
                          'No enrollment batches have been configured for $_selectedYearLabel.',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF94A3B8))),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0052CC),
                            foregroundColor: Colors.white),
                        onPressed: () => _showAddEditBatchModal(),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add Enrollment Batch'),
                      ),
                    ],
                  ),
                ),
              )
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      horizontalMargin: 16,
                      columnSpacing: 24,
                      headingRowHeight: 44,
                      dataRowMaxHeight: 50,
                      headingRowColor:
                          MaterialStateProperty.all(const Color(0xFFF1F5F9)),
                      columns: const [
                        DataColumn(
                            label: Text('Batch Name',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A)))),
                        DataColumn(
                            label: Text('Program',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A)))),
                        DataColumn(
                            label: Text('Department',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A)))),
                        DataColumn(
                            label: Text('Admission Year',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A)))),
                        DataColumn(
                            label: Text('Graduation Year',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A)))),
                        DataColumn(
                            label: Text('Student Count',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A)))),
                        DataColumn(
                            label: Text('Status',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A)))),
                        DataColumn(
                            label: Text('Actions',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A)))),
                      ],
                      rows: _batches.map((b) {
                        return DataRow(cells: [
                          DataCell(Text(b['batch_name']?.toString() ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A)))),
                          DataCell(Text(b['program']?.toString() ?? 'B.E.',
                              style:
                                  const TextStyle(color: Color(0xFF334155)))),
                          DataCell(Text(b['department']?.toString() ?? 'CSE',
                              style:
                                  const TextStyle(color: Color(0xFF334155)))),
                          DataCell(Text(
                              b['admission_year']?.toString() ?? '2025',
                              style:
                                  const TextStyle(color: Color(0xFF334155)))),
                          DataCell(Text(
                              b['expected_graduation_year']?.toString() ??
                                  '2029',
                              style:
                                  const TextStyle(color: Color(0xFF334155)))),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(20)),
                              child: Text('${b['student_count'] ?? 0} Students',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0052CC),
                                      fontSize: 11)),
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(20)),
                              child: Text(b['status']?.toString() ?? 'Active',
                                  style: const TextStyle(
                                      color: Color(0xFF166534),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11)),
                            ),
                          ),
                          DataCell(
                            PopupMenuButton<String>(
                              tooltip: 'Actions',
                              onSelected: (v) async {
                                if (v == 'Edit')
                                  _showAddEditBatchModal(b);
                                else if (v == 'Delete') {
                                  final id = b['id']?.toString();
                                  if (id != null) {
                                    await AdminSupabaseClient.delete(
                                        'enrollment_batches', 'id', id);
                                    _showSnack('Enrollment batch deleted.');
                                    _loadConfigData();
                                  }
                                }
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                    value: 'Edit',
                                    child: Row(children: [
                                      Icon(Icons.edit_outlined, size: 16),
                                      SizedBox(width: 8),
                                      Text('Edit')
                                    ])),
                                const PopupMenuItem(
                                    value: 'Delete',
                                    child: Row(children: [
                                      Icon(Icons.delete_outline_rounded,
                                          size: 16, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Delete',
                                          style: TextStyle(color: Colors.red))
                                    ])),
                              ],
                            ),
                          ),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );

  // ── TAB 3: TERM MILESTONES ─────────────────────────────────────────────────
  Widget _buildMilestonesTab() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Term Milestones in $_selectedYearLabel',
                      style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                        'Configure key academic deadlines, examination schedules, and result publication dates',
                        style:
                            TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0052CC),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _showAddEditMilestoneModal(),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Milestone',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Center(
                  child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator()))
            else if (_milestones.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      const Icon(Icons.flag_outlined,
                          size: 48, color: Color(0xFFCBD5E1)),
                      const SizedBox(height: 10),
                      const Text('No Term Milestones Configured',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF64748B))),
                      const SizedBox(height: 4),
                      Text(
                          'Configure academic milestones and examination dates for $_selectedYearLabel.',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF94A3B8))),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0052CC),
                            foregroundColor: Colors.white),
                        onPressed: () => _showAddEditMilestoneModal(),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add Milestone'),
                      ),
                    ],
                  ),
                ),
              )
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      horizontalMargin: 16,
                      columnSpacing: 24,
                      headingRowHeight: 44,
                      dataRowMaxHeight: 50,
                      headingRowColor:
                          MaterialStateProperty.all(const Color(0xFFF1F5F9)),
                      columns: const [
                        DataColumn(
                            label: Text('Milestone Event',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A)))),
                        DataColumn(
                            label: Text('Term',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A)))),
                        DataColumn(
                            label: Text('Start Date',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A)))),
                        DataColumn(
                            label: Text('End Date',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A)))),
                        DataColumn(
                            label: Text('Status',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A)))),
                        DataColumn(
                            label: Text('Actions',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A)))),
                      ],
                      rows: _milestones.map((m) {
                        final status = m['status']?.toString() ?? 'Upcoming';
                        Color sColor = const Color(0xFF0052CC);
                        if (status == 'Completed')
                          sColor = const Color(0xFF64748B);
                        if (status == 'Active')
                          sColor = const Color(0xFF16A34A);
                        if (status == 'Cancelled')
                          sColor = const Color(0xFFDC2626);

                        return DataRow(cells: [
                          DataCell(Text(m['milestone_name']?.toString() ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A)))),
                          DataCell(Text(
                              m['term_name']?.toString() ?? 'Even Semester',
                              style:
                                  const TextStyle(color: Color(0xFF334155)))),
                          DataCell(Text(m['start_date']?.toString() ?? '-',
                              style:
                                  const TextStyle(color: Color(0xFF334155)))),
                          DataCell(Text(m['end_date']?.toString() ?? '-',
                              style:
                                  const TextStyle(color: Color(0xFF334155)))),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                  color: sColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20)),
                              child: Text(status,
                                  style: TextStyle(
                                      color: sColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11)),
                            ),
                          ),
                          DataCell(
                            PopupMenuButton<String>(
                              tooltip: 'Actions',
                              onSelected: (v) async {
                                if (v == 'Edit')
                                  _showAddEditMilestoneModal(m);
                                else if (v == 'Delete') {
                                  final id = m['id']?.toString();
                                  if (id != null) {
                                    await AdminSupabaseClient.delete(
                                        'term_milestones', 'id', id);
                                    _showSnack('Milestone deleted.');
                                    _loadConfigData();
                                  }
                                }
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                    value: 'Edit',
                                    child: Row(children: [
                                      Icon(Icons.edit_outlined, size: 16),
                                      SizedBox(width: 8),
                                      Text('Edit')
                                    ])),
                                const PopupMenuItem(
                                    value: 'Delete',
                                    child: Row(children: [
                                      Icon(Icons.delete_outline_rounded,
                                          size: 16, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Delete',
                                          style: TextStyle(color: Colors.red))
                                    ])),
                              ],
                            ),
                          ),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
}
