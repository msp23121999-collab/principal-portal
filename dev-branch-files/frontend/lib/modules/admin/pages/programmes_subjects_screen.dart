import 'package:flutter/material.dart';
import '../services/programme_subject_service.dart';
import '../utils/file_downloader.dart';

class ProgrammesSubjectsScreen extends StatefulWidget {
  const ProgrammesSubjectsScreen({super.key});

  @override
  State<ProgrammesSubjectsScreen> createState() =>
      _ProgrammesSubjectsScreenState();
}

class _ProgrammesSubjectsScreenState extends State<ProgrammesSubjectsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  List<Map<String, dynamic>> _programmes = [];
  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _mappings = [];

  // Filters for Tab 1 (Programmes)
  String _progSearch = '';
  String _progLevelFilter = 'All';
  String _progDeptFilter = 'All';
  String _progStatusFilter = 'All';

  // Filters for Tab 2 (Subjects)
  String _subjSearch = '';
  String _subjDeptFilter = 'All';
  String _subjTypeFilter = 'All';
  String _subjStatusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final progs = await ProgrammeSubjectService.fetchProgrammes();
    final subs = await ProgrammeSubjectService.fetchSubjects();
    final maps = await ProgrammeSubjectService.fetchProgrammeSubjectMappings();

    if (mounted) {
      setState(() {
        _programmes = progs;
        _subjects = subs;
        _mappings = maps;
        _isLoading = false;
      });
    }
  }

  void _showSnack(String message, [bool isError = false]) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color(0xFFDC2626)
            : const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── FILTERED LISTS ─────────────────────────────────────────────────────────
  List<Map<String, dynamic>> get _filteredProgrammes => _programmes.where((p) {
    final code = (p['code'] ?? '').toString().toLowerCase();
    final name = (p['name'] ?? '').toString().toLowerCase();
    final dept = (p['department'] ?? '').toString();
    final level = (p['level'] ?? '').toString();
    final status = (p['status'] ?? '').toString();

    final matchesSearch =
        _progSearch.isEmpty ||
        code.contains(_progSearch.toLowerCase()) ||
        name.contains(_progSearch.toLowerCase());
    final matchesLevel = _progLevelFilter == 'All' || level == _progLevelFilter;
    final matchesDept = _progDeptFilter == 'All' || dept == _progDeptFilter;
    final matchesStatus =
        _progStatusFilter == 'All' || status == _progStatusFilter;

    return matchesSearch && matchesLevel && matchesDept && matchesStatus;
  }).toList();

  List<Map<String, dynamic>> get _filteredSubjects => _subjects.where((s) {
    final code = (s['code'] ?? '').toString().toLowerCase();
    final title = (s['title'] ?? '').toString().toLowerCase();
    final dept = (s['department'] ?? '').toString();
    final type = (s['subject_type'] ?? '').toString();
    final status = (s['status'] ?? '').toString();

    final matchesSearch =
        _subjSearch.isEmpty ||
        code.contains(_subjSearch.toLowerCase()) ||
        title.contains(_subjSearch.toLowerCase());
    final matchesDept = _subjDeptFilter == 'All' || dept == _subjDeptFilter;
    final matchesType = _subjTypeFilter == 'All' || type == _subjTypeFilter;
    final matchesStatus =
        _subjStatusFilter == 'All' || status == _subjStatusFilter;

    return matchesSearch && matchesDept && matchesType && matchesStatus;
  }).toList();

  // ── EXPORT CSV ──────────────────────────────────────────────────────────────
  void _exportData() {
    if (_tabController.index == 0) {
      final csvRows = [
        [
          'Programme Code',
          'Programme Name',
          'Level',
          'Department',
          'Duration',
          'Semesters',
          'Regulation',
          'Active Students',
          'Status',
        ],
        ..._filteredProgrammes.map(
          (p) => [
            p['code'] ?? '',
            p['name'] ?? '',
            p['level'] ?? '',
            p['department'] ?? '',
            p['duration'] ?? '',
            p['semesters'] ?? '',
            p['current_regulation'] ?? '',
            p['active_students'] ?? '',
            p['status'] ?? '',
          ],
        ),
      ];
      FileDownloader.downloadCSV(
        csvRows.map((r) => r.join(',')).join('\n'),
        'Programmes_Master.csv',
      );
      _showSnack('Exported Programmes Master as CSV.');
    } else {
      final csvRows = [
        [
          'Subject Code',
          'Subject Title',
          'Department',
          'Subject Type',
          'L',
          'T',
          'P',
          'Credits',
          'Total Contact Hours',
          'Internal Max',
          'External Max',
          'Total Max',
          'Status',
        ],
        ..._filteredSubjects.map((s) {
          final l = int.tryParse(s['lecture_hours']?.toString() ?? '3') ?? 3;
          final t = int.tryParse(s['tutorial_hours']?.toString() ?? '0') ?? 0;
          final p = int.tryParse(s['practical_hours']?.toString() ?? '0') ?? 0;
          final totalHrs = l + t + p;
          final intMax =
              int.tryParse(s['internal_max_marks']?.toString() ?? '50') ?? 50;
          final extMax =
              int.tryParse(s['external_max_marks']?.toString() ?? '50') ?? 50;
          final prcMax =
              int.tryParse(s['practical_max_marks']?.toString() ?? '0') ?? 0;
          final totMax = intMax + extMax + prcMax;

          return [
            s['code'] ?? '',
            s['title'] ?? '',
            s['department'] ?? '',
            s['subject_type'] ?? '',
            l,
            t,
            p,
            s['credits'] ?? '3.0',
            '$totalHrs Hours/wk',
            intMax,
            extMax,
            totMax,
            s['status'] ?? '',
          ];
        }),
      ];
      FileDownloader.downloadCSV(
        csvRows.map((r) => r.join(',')).join('\n'),
        'Central_Subjects_Catalog.csv',
      );
      _showSnack('Exported Central Subject Catalog as CSV.');
    }
  }

  // ── ADD / EDIT PROGRAMME MODAL ─────────────────────────────────────────────
  void _showAddEditProgrammeModal([Map<String, dynamic>? existing]) {
    final isEdit = existing != null;
    final codeCtrl = TextEditingController(
      text: existing?['code']?.toString() ?? '',
    );
    final nameCtrl = TextEditingController(
      text: existing?['name']?.toString() ?? '',
    );
    final shortNameCtrl = TextEditingController(
      text: existing?['short_name']?.toString() ?? '',
    );
    final durationCtrl = TextEditingController(
      text: existing?['duration']?.toString() ?? '4 Years',
    );
    final semsCtrl = TextEditingController(
      text: existing?['semesters']?.toString() ?? '8',
    );
    final studentsCtrl = TextEditingController(
      text: existing?['active_students']?.toString() ?? '0',
    );
    final descCtrl = TextEditingController(
      text: existing?['description']?.toString() ?? '',
    );

    var level = existing?['level']?.toString() ?? 'UG';
    var dept =
        existing?['department']?.toString() ?? 'Computer Science & Engineering';
    var regulation = existing?['current_regulation']?.toString() ?? 'R2024';
    var status = existing?['status']?.toString() ?? 'Active';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            isEdit ? 'Edit Degree Programme' : 'Add New Degree Programme',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: codeCtrl,
                          enabled: !isEdit,
                          decoration: const InputDecoration(
                            labelText: 'Programme Code *',
                            hintText: 'e.g. BE-CSE',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: shortNameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Short Name',
                            hintText: 'e.g. B.E. CSE',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Programme Full Name *',
                      hintText: 'e.g. B.E. Computer Science and Engineering',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: dept,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Department',
                            border: OutlineInputBorder(),
                          ),
                          items:
                              [
                                    'Computer Science & Engineering',
                                    'Electronics & Communication Engg',
                                    'Mechanical Engineering',
                                    'Civil Engineering',
                                    'Information Technology',
                                    'Management Studies',
                                  ]
                                  .map(
                                    (d) => DropdownMenuItem(
                                      value: d,
                                      child: Text(
                                        d,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) => setModalState(() => dept = v!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: level,
                          decoration: const InputDecoration(
                            labelText: 'Degree Level',
                            border: OutlineInputBorder(),
                          ),
                          items: ['UG', 'PG', 'Diploma', 'Certificate', 'PhD']
                              .map(
                                (l) =>
                                    DropdownMenuItem(value: l, child: Text(l)),
                              )
                              .toList(),
                          onChanged: (v) => setModalState(() => level = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: durationCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Duration',
                            hintText: 'e.g. 4 Years',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: semsCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Semesters',
                            hintText: '8',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: regulation,
                          decoration: const InputDecoration(
                            labelText: 'Current Regulation',
                            border: OutlineInputBorder(),
                          ),
                          items: ['R2024', 'R2021', 'R2019', 'R2017']
                              .map(
                                (r) =>
                                    DropdownMenuItem(value: r, child: Text(r)),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setModalState(() => regulation = v!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: status,
                          decoration: const InputDecoration(
                            labelText: 'Status',
                            border: OutlineInputBorder(),
                          ),
                          items: ['Active', 'Inactive', 'Archived']
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
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Programme Overview',
                      hintText: 'Brief description...',
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
                final code = codeCtrl.text.trim();
                final name = nameCtrl.text.trim();
                if (code.isEmpty || name.isEmpty) {
                  _showSnack('Programme Code and Name are required.', true);
                  return;
                }

                final payload = {
                  'code': code,
                  'name': name,
                  'short_name': shortNameCtrl.text.trim(),
                  'department': dept,
                  'level': level,
                  'duration': durationCtrl.text.trim(),
                  'semesters': int.tryParse(semsCtrl.text) ?? 8,
                  'current_regulation': regulation,
                  'active_students': int.tryParse(studentsCtrl.text) ?? 0,
                  'status': status,
                  'description': descCtrl.text.trim(),
                };

                if (isEdit && existing['id'] != null) {
                  await ProgrammeSubjectService.updateProgramme(
                    existing['id'].toString(),
                    payload,
                  );
                  _showSnack('Programme "$code" updated.');
                } else {
                  await ProgrammeSubjectService.createProgramme(payload);
                  _showSnack('Programme "$code" created.');
                }

                if (mounted) {
                  Navigator.pop(ctx);
                  _loadData();
                }
              },
              child: Text(isEdit ? 'Save Changes' : 'Create Programme'),
            ),
          ],
        ),
      ),
    );
  }

  // ── ADD / EDIT SUBJECT MODAL (COMPLETE WITH SECTIONS A - F) ─────────────────
  void _showAddEditSubjectModal([Map<String, dynamic>? existing]) {
    final isEdit = existing != null;

    // Section A: Subject Info
    final codeCtrl = TextEditingController(
      text: existing?['code']?.toString() ?? '',
    );
    final titleCtrl = TextEditingController(
      text: existing?['title']?.toString() ?? '',
    );
    final shortNameCtrl = TextEditingController(
      text: existing?['short_name']?.toString() ?? '',
    );
    final descCtrl = TextEditingController(
      text: existing?['description']?.toString() ?? '',
    );
    var dept =
        existing?['department']?.toString() ?? 'Computer Science & Engineering';
    var type = existing?['subject_type']?.toString() ?? 'Core';
    var status = existing?['status']?.toString() ?? 'Active';

    // Section B: Teaching & Credit Structure (L-T-P-C)
    final lCtrl = TextEditingController(
      text: existing?['lecture_hours']?.toString() ?? '3',
    );
    final tCtrl = TextEditingController(
      text: existing?['tutorial_hours']?.toString() ?? '0',
    );
    final pCtrl = TextEditingController(
      text: existing?['practical_hours']?.toString() ?? '0',
    );
    final creditsCtrl = TextEditingController(
      text: existing?['credits']?.toString() ?? '3.0',
    );

    // Section C: Assessment Configuration
    final intMaxCtrl = TextEditingController(
      text: existing?['internal_max_marks']?.toString() ?? '50',
    );
    final extMaxCtrl = TextEditingController(
      text: existing?['external_max_marks']?.toString() ?? '50',
    );
    final prcMaxCtrl = TextEditingController(
      text: existing?['practical_max_marks']?.toString() ?? '0',
    );
    final minPassCtrl = TextEditingController(
      text: existing?['min_passing_marks']?.toString() ?? '40',
    );
    final intMinCtrl = TextEditingController(
      text: existing?['internal_min_marks']?.toString() ?? '20',
    );
    final extMinCtrl = TextEditingController(
      text: existing?['external_min_marks']?.toString() ?? '20',
    );

    // Section D: Curriculum Mapping
    var mapProg = _programmes.isNotEmpty
        ? _programmes.first['code']?.toString() ?? 'BE-CSE'
        : 'BE-CSE';
    var mapReg = 'R2024';
    var mapSem = 1;
    var mapAcadYear = '2025-26';

    // Course Outcomes & Units state
    var tempCOs = <Map<String, String>>[];
    var tempUnits = <Map<String, dynamic>>[];
    var isSaving = false;

    // Preload COs and Units if editing
    if (isEdit && existing['code'] != null) {
      final code = existing['code'].toString();
      ProgrammeSubjectService.fetchCourseOutcomes(code).then((cos) {
        if (cos.isNotEmpty) {
          tempCOs = cos
              .map(
                (c) => {
                  'co_code': c['co_code']?.toString() ?? '',
                  'co_description': c['co_description']?.toString() ?? '',
                  'status': c['status']?.toString() ?? 'Active',
                },
              )
              .toList();
        }
      });
      ProgrammeSubjectService.fetchSubjectUnits(code).then((units) {
        if (units.isNotEmpty) {
          tempUnits = units;
        }
      });
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          // Live calculation of Total Contact Hours (L + T + P)
          final lVal = int.tryParse(lCtrl.text) ?? 0;
          final tVal = int.tryParse(tCtrl.text) ?? 0;
          final pVal = int.tryParse(pCtrl.text) ?? 0;
          final totalContactHours =
              (lVal < 0 ? 0 : lVal) +
              (tVal < 0 ? 0 : tVal) +
              (pVal < 0 ? 0 : pVal);

          // Live calculation of Total Maximum Marks (Internal + External + Practical)
          final intMax = int.tryParse(intMaxCtrl.text) ?? 0;
          final extMax = int.tryParse(extMaxCtrl.text) ?? 0;
          final prcMax = int.tryParse(prcMaxCtrl.text) ?? 0;
          final totalMaxMarks =
              (intMax < 0 ? 0 : intMax) +
              (extMax < 0 ? 0 : extMax) +
              (prcMax < 0 ? 0 : prcMax);

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                const Icon(Icons.menu_book_rounded, color: Color(0xFF0052CC)),
                const SizedBox(width: 8),
                Text(
                  isEdit
                      ? 'Edit Subject Catalog Entry'
                      : 'Add Official Subject to Master Catalog',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 720,
              height: 580,
              child: DefaultTabController(
                length: 6,
                child: Column(
                  children: [
                    const TabBar(
                      isScrollable: true,
                      labelColor: Color(0xFF0052CC),
                      unselectedLabelColor: Color(0xFF64748B),
                      indicatorColor: Color(0xFF0052CC),
                      tabs: [
                        Tab(text: 'A. Subject Info'),
                        Tab(text: 'B. Teaching & Credits (L-T-P-C)'),
                        Tab(text: 'C. Assessment Config'),
                        Tab(text: 'D. Curriculum Mapping'),
                        Tab(text: 'E. Course Outcomes'),
                        Tab(text: 'F. Syllabus Structure'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // ── SECTION A: SUBJECT INFORMATION ───────────────────
                          SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Official Subject Master Data',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: codeCtrl,
                                        enabled: !isEdit,
                                        textCapitalization:
                                            TextCapitalization.characters,
                                        decoration: const InputDecoration(
                                          labelText: 'Subject Code *',
                                          hintText: 'e.g. CS8591',
                                          border: OutlineInputBorder(),
                                          helperText:
                                              'Unique subject code (e.g. CS8591)',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextField(
                                        controller: shortNameCtrl,
                                        decoration: const InputDecoration(
                                          labelText: 'Short Name',
                                          hintText: 'e.g. CN',
                                          border: OutlineInputBorder(),
                                          helperText: 'Abbreviation / acronym',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: titleCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Subject Full Name / Title *',
                                    hintText: 'e.g. Computer Networks',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        value: dept,
                                        isExpanded: true,
                                        decoration: const InputDecoration(
                                          labelText: 'Department *',
                                          border: OutlineInputBorder(),
                                        ),
                                        items:
                                            [
                                                  'Computer Science & Engineering',
                                                  'Electronics & Communication Engg',
                                                  'Mechanical Engineering',
                                                  'Civil Engineering',
                                                  'Information Technology',
                                                  'Management Studies',
                                                ]
                                                .map(
                                                  (d) => DropdownMenuItem(
                                                    value: d,
                                                    child: Text(
                                                      d,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                        onChanged: (v) =>
                                            setModalState(() => dept = v!),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        value: type,
                                        decoration: const InputDecoration(
                                          labelText: 'Subject Type *',
                                          border: OutlineInputBorder(),
                                        ),
                                        items:
                                            [
                                                  'Core',
                                                  'Professional Core',
                                                  'Professional Elective',
                                                  'Open Elective',
                                                  'Laboratory',
                                                  'Project',
                                                  'Seminar',
                                                  'Value Added Course',
                                                ]
                                                .map(
                                                  (t) => DropdownMenuItem(
                                                    value: t,
                                                    child: Text(t),
                                                  ),
                                                )
                                                .toList(),
                                        onChanged: (v) =>
                                            setModalState(() => type = v!),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        value: status,
                                        decoration: const InputDecoration(
                                          labelText: 'Status',
                                          border: OutlineInputBorder(),
                                        ),
                                        items: ['Active', 'Inactive']
                                            .map(
                                              (s) => DropdownMenuItem(
                                                value: s,
                                                child: Text(s),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (v) =>
                                            setModalState(() => status = v!),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: descCtrl,
                                  maxLines: 2,
                                  decoration: const InputDecoration(
                                    labelText: 'Description (Optional)',
                                    hintText:
                                        'Subject overview and objectives...',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ── SECTION B: TEACHING & CREDIT STRUCTURE (L-T-P-C) ──
                          SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Teaching & Credit Structure (L - T - P - C)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Configure weekly contact hours and academic credit valuation.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: lCtrl,
                                        keyboardType: TextInputType.number,
                                        onChanged: (_) => setModalState(() {}),
                                        decoration: const InputDecoration(
                                          labelText: 'Lecture (L) *',
                                          border: OutlineInputBorder(),
                                          helperText: 'L: Lecture hours/week',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: TextField(
                                        controller: tCtrl,
                                        keyboardType: TextInputType.number,
                                        onChanged: (_) => setModalState(() {}),
                                        decoration: const InputDecoration(
                                          labelText: 'Tutorial (T) *',
                                          border: OutlineInputBorder(),
                                          helperText: 'T: Tutorial hours/week',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: TextField(
                                        controller: pCtrl,
                                        keyboardType: TextInputType.number,
                                        onChanged: (_) => setModalState(() {}),
                                        decoration: const InputDecoration(
                                          labelText: 'Practical (P) *',
                                          border: OutlineInputBorder(),
                                          helperText:
                                              'P: Practical/Lab hrs/week',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: TextField(
                                        controller: creditsCtrl,
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        decoration: const InputDecoration(
                                          labelText: 'Credits (C) *',
                                          border: OutlineInputBorder(),
                                          helperText: 'C: Credit value',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFBFDBFE),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(
                                            Icons.schedule_rounded,
                                            color: Color(0xFF0052CC),
                                            size: 22,
                                          ),
                                          SizedBox(width: 10),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Total Contact Hours',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  color: Color(0xFF1E3A8A),
                                                ),
                                              ),
                                              Text(
                                                'Automatically calculated as L + T + P',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xFF3B82F6),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0052CC),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          '$totalContactHours hours/week',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ── SECTION C: ASSESSMENT CONFIGURATION ───────────────
                          SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Assessment & Examination Configuration',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Define maximum marks and minimum pass thresholds for examinations.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: intMaxCtrl,
                                        keyboardType: TextInputType.number,
                                        onChanged: (_) => setModalState(() {}),
                                        decoration: const InputDecoration(
                                          labelText:
                                              'Internal Assessment Max Marks *',
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: TextField(
                                        controller: extMaxCtrl,
                                        keyboardType: TextInputType.number,
                                        onChanged: (_) => setModalState(() {}),
                                        decoration: const InputDecoration(
                                          labelText:
                                              'External Exam Max Marks *',
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: TextField(
                                        controller: prcMaxCtrl,
                                        keyboardType: TextInputType.number,
                                        onChanged: (_) => setModalState(() {}),
                                        decoration: const InputDecoration(
                                          labelText:
                                              'Practical Max Marks (Optional)',
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Total Maximum Marks (Internal + External + Practical):',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Color(0xFF334155),
                                        ),
                                      ),
                                      Text(
                                        '$totalMaxMarks Marks',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Color(0xFF16A34A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: minPassCtrl,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: 'Minimum Passing Marks *',
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: TextField(
                                        controller: intMinCtrl,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: 'Internal Minimum Marks',
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: TextField(
                                        controller: extMinCtrl,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: 'External Minimum Marks',
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // ── SECTION D: CURRICULUM MAPPING ────────────────────
                          SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Degree Curriculum Mapping Assignment',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Map this subject master to degree programmes without duplicating central data.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        value: mapProg,
                                        isExpanded: true,
                                        decoration: const InputDecoration(
                                          labelText: 'Target Programme',
                                          border: OutlineInputBorder(),
                                        ),
                                        items: _programmes
                                            .map(
                                              (p) => DropdownMenuItem(
                                                value: p['code']?.toString(),
                                                child: Text(
                                                  '${p['code']} - ${p['name']}',
                                                ),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (v) =>
                                            setModalState(() => mapProg = v!),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        value: mapReg,
                                        decoration: const InputDecoration(
                                          labelText: 'Regulation',
                                          border: OutlineInputBorder(),
                                        ),
                                        items:
                                            ['R2024', 'R2021', 'R2019', 'R2017']
                                                .map(
                                                  (r) => DropdownMenuItem(
                                                    value: r,
                                                    child: Text(r),
                                                  ),
                                                )
                                                .toList(),
                                        onChanged: (v) =>
                                            setModalState(() => mapReg = v!),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<int>(
                                        value: mapSem,
                                        decoration: const InputDecoration(
                                          labelText: 'Semester Placement',
                                          border: OutlineInputBorder(),
                                        ),
                                        items: List.generate(8, (i) => i + 1)
                                            .map(
                                              (s) => DropdownMenuItem(
                                                value: s,
                                                child: Text('Semester $s'),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (v) =>
                                            setModalState(() => mapSem = v!),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        value: mapAcadYear,
                                        decoration: const InputDecoration(
                                          labelText: 'Effective Academic Year',
                                          border: OutlineInputBorder(),
                                        ),
                                        items: ['2025-26', '2024-25', '2023-24']
                                            .map(
                                              (y) => DropdownMenuItem(
                                                value: y,
                                                child: Text(y),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (v) => setModalState(
                                          () => mapAcadYear = v!,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // ── SECTION E: COURSE OUTCOMES (CO) ──────────────────
                          SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Course Outcomes (CO)',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        Text(
                                          'Configure official course outcome statements',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF0052CC,
                                        ),
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () {
                                        setModalState(() {
                                          tempCOs.add({
                                            'co_code':
                                                'CO${tempCOs.length + 1}',
                                            'co_description': '',
                                            'status': 'Active',
                                          });
                                        });
                                      },
                                      icon: const Icon(
                                        Icons.add_rounded,
                                        size: 16,
                                      ),
                                      label: const Text('Add Outcome'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (tempCOs.isEmpty)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(30),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: const Column(
                                      children: [
                                        Icon(
                                          Icons.assignment_outlined,
                                          size: 36,
                                          color: Color(0xFFCBD5E1),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'No Course Outcomes Configured',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF64748B),
                                            fontSize: 13,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Add course outcome statements for NBA/NAAC accreditation compliance.',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF94A3B8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  Column(
                                    children: List.generate(tempCOs.length, (
                                      idx,
                                    ) {
                                      final co = tempCOs[idx];
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: 80,
                                              child: TextField(
                                                controller:
                                                    TextEditingController(
                                                      text: co['co_code'],
                                                    ),
                                                onChanged: (v) =>
                                                    co['co_code'] = v,
                                                decoration:
                                                    const InputDecoration(
                                                      labelText: 'CO Code',
                                                      border:
                                                          OutlineInputBorder(),
                                                    ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: TextField(
                                                controller:
                                                    TextEditingController(
                                                      text:
                                                          co['co_description'],
                                                    ),
                                                onChanged: (v) =>
                                                    co['co_description'] = v,
                                                decoration:
                                                    const InputDecoration(
                                                      labelText:
                                                          'Outcome Description',
                                                      hintText:
                                                          'Ability to apply...',
                                                      border:
                                                          OutlineInputBorder(),
                                                    ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline_rounded,
                                                color: Color(0xFFDC2626),
                                              ),
                                              onPressed: () {
                                                setModalState(
                                                  () => tempCOs.removeAt(idx),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ),
                              ],
                            ),
                          ),

                          // ── SECTION F: SYLLABUS STRUCTURE / UNITS ──────────────
                          SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Syllabus Modules & Units',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        Text(
                                          'Configure unit titles, contact hours, and core topics',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF0052CC,
                                        ),
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () {
                                        setModalState(() {
                                          tempUnits.add({
                                            'unit_number':
                                                'Unit ${tempUnits.length + 1}',
                                            'unit_title': '',
                                            'teaching_hours': 9,
                                            'topics': '',
                                          });
                                        });
                                      },
                                      icon: const Icon(
                                        Icons.add_rounded,
                                        size: 16,
                                      ),
                                      label: const Text('Add Unit'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (tempUnits.isEmpty)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(30),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: const Column(
                                      children: [
                                        Icon(
                                          Icons.list_alt_rounded,
                                          size: 36,
                                          color: Color(0xFFCBD5E1),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'No Syllabus Units Configured',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF64748B),
                                            fontSize: 13,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Define syllabus units and teaching hour allocations.',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF94A3B8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  Column(
                                    children: List.generate(tempUnits.length, (
                                      idx,
                                    ) {
                                      final u = tempUnits[idx];
                                      return Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 10,
                                        ),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFFE2E8F0),
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Row(
                                              children: [
                                                SizedBox(
                                                  width: 100,
                                                  child: TextField(
                                                    controller:
                                                        TextEditingController(
                                                          text: u['unit_number']
                                                              ?.toString(),
                                                        ),
                                                    onChanged: (v) =>
                                                        u['unit_number'] = v,
                                                    decoration:
                                                        const InputDecoration(
                                                          labelText: 'Unit No.',
                                                          border:
                                                              OutlineInputBorder(),
                                                        ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: TextField(
                                                    controller:
                                                        TextEditingController(
                                                          text: u['unit_title']
                                                              ?.toString(),
                                                        ),
                                                    onChanged: (v) =>
                                                        u['unit_title'] = v,
                                                    decoration:
                                                        const InputDecoration(
                                                          labelText:
                                                              'Unit Title',
                                                          border:
                                                              OutlineInputBorder(),
                                                        ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons
                                                        .delete_outline_rounded,
                                                    color: Color(0xFFDC2626),
                                                  ),
                                                  onPressed: () =>
                                                      setModalState(
                                                        () => tempUnits
                                                            .removeAt(idx),
                                                      ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            TextField(
                                              controller: TextEditingController(
                                                text: u['topics']?.toString(),
                                              ),
                                              onChanged: (v) => u['topics'] = v,
                                              decoration: const InputDecoration(
                                                labelText: 'Topics Covered',
                                                hintText: 'Topic 1, Topic 2...',
                                                border: OutlineInputBorder(),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0052CC),
                  foregroundColor: Colors.white,
                ),
                onPressed: isSaving
                    ? null
                    : () async {
                        final code = codeCtrl.text.trim().toUpperCase();
                        final title = titleCtrl.text.trim();
                        final l = int.tryParse(lCtrl.text) ?? 0;
                        final t = int.tryParse(tCtrl.text) ?? 0;
                        final p = int.tryParse(pCtrl.text) ?? 0;
                        final credits =
                            double.tryParse(creditsCtrl.text) ?? 3.0;

                        if (code.isEmpty || title.isEmpty) {
                          _showSnack(
                            'Subject Code and Subject Title are required.',
                            true,
                          );
                          return;
                        }
                        if (l < 0 || t < 0 || p < 0 || credits < 0) {
                          _showSnack(
                            'L/T/P and Credits cannot be negative numbers.',
                            true,
                          );
                          return;
                        }

                        // Unique Subject Code validation for new creation
                        if (!isEdit) {
                          final exists = _subjects.any(
                            (s) =>
                                (s['code'] ?? '').toString().toUpperCase() ==
                                code,
                          );
                          if (exists) {
                            _showSnack(
                              'Subject Code "$code" already exists in the central catalog.',
                              true,
                            );
                            return;
                          }
                        }

                        setModalState(() => isSaving = true);

                        final payload = {
                          'code': code,
                          'title': title,
                          'short_name': shortNameCtrl.text.trim(),
                          'department': dept,
                          'subject_type': type,
                          'lecture_hours': l,
                          'tutorial_hours': t,
                          'practical_hours': p,
                          'credits': credits,
                          'contact_hours': totalContactHours,
                          'internal_max_marks': intMax,
                          'external_max_marks': extMax,
                          'practical_max_marks': prcMax,
                          'total_max_marks': totalMaxMarks,
                          'min_passing_marks':
                              int.tryParse(minPassCtrl.text) ?? 40,
                          'internal_min_marks':
                              int.tryParse(intMinCtrl.text) ?? 20,
                          'external_min_marks':
                              int.tryParse(extMinCtrl.text) ?? 20,
                          'status': status,
                          'description': descCtrl.text.trim(),
                          'updated_by': 'Administrator',
                        };

                        if (isEdit && existing['id'] != null) {
                          await ProgrammeSubjectService.updateSubject(
                            existing['id'].toString(),
                            payload,
                            previous: existing,
                          );
                          _showSnack('Subject "$code" updated successfully.');
                        } else {
                          payload['created_by'] = 'Administrator';
                          await ProgrammeSubjectService.createSubject(payload);
                          _showSnack(
                            'Subject "$code" created in central catalog.',
                          );
                        }

                        // Also save Curriculum Mapping if provided
                        await ProgrammeSubjectService.mapSubjectToProgramme({
                          'programme_code': mapProg,
                          'subject_code': code,
                          'regulation': mapReg,
                          'semester': mapSem,
                          'subject_type': type,
                          'credits': credits,
                          'effective_academic_year': mapAcadYear,
                          'status': status,
                        });

                        // Save Course Outcomes
                        for (final co in tempCOs) {
                          if (co['co_description']!.isNotEmpty) {
                            await ProgrammeSubjectService.addCourseOutcome({
                              'subject_code': code,
                              'co_code': co['co_code'],
                              'co_description': co['co_description'],
                              'status': co['status'],
                            });
                          }
                        }

                        // Save Subject Units
                        for (final u in tempUnits) {
                          if (u['unit_title'] != null &&
                              u['unit_title'].toString().isNotEmpty) {
                            await ProgrammeSubjectService.addSubjectUnit({
                              'subject_code': code,
                              'unit_number': u['unit_number'],
                              'unit_title': u['unit_title'],
                              'topics': u['topics'],
                            });
                          }
                        }

                        if (mounted) {
                          Navigator.pop(ctx);
                          _loadData();
                        }
                      },
                child: Text(
                  isSaving
                      ? 'Saving...'
                      : (isEdit ? 'Save Changes' : 'Save Subject'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── DETAILED SUBJECT VIEW MODAL (SECTION 3) ─────────────────────────────────
  void _showSubjectDetailsModal(Map<String, dynamic> subj) {
    final code = subj['code']?.toString() ?? '-';
    final title = subj['title']?.toString() ?? '-';
    final dept = subj['department']?.toString() ?? '-';
    final type = subj['subject_type']?.toString() ?? 'Core';
    final status = subj['status']?.toString() ?? 'Active';
    final l = int.tryParse(subj['lecture_hours']?.toString() ?? '3') ?? 3;
    final t = int.tryParse(subj['tutorial_hours']?.toString() ?? '0') ?? 0;
    final p = int.tryParse(subj['practical_hours']?.toString() ?? '0') ?? 0;
    final credits = subj['credits']?.toString() ?? '3.0';
    final totalHrs = l + t + p;

    final intMax =
        int.tryParse(subj['internal_max_marks']?.toString() ?? '50') ?? 50;
    final extMax =
        int.tryParse(subj['external_max_marks']?.toString() ?? '50') ?? 50;
    final prcMax =
        int.tryParse(subj['practical_max_marks']?.toString() ?? '0') ?? 0;
    final totMax = intMax + extMax + prcMax;
    final minPass =
        int.tryParse(subj['min_passing_marks']?.toString() ?? '40') ?? 40;

    var subjectMappings = <Map<String, dynamic>>[];
    var subjectCOs = <Map<String, dynamic>>[];
    var subjectUnits = <Map<String, dynamic>>[];
    var auditLogs = <Map<String, dynamic>>[];
    var isFetchingDetails = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          if (isFetchingDetails) {
            Future.wait([
              ProgrammeSubjectService.fetchProgrammeSubjectMappings(
                subjectCode: code,
              ),
              ProgrammeSubjectService.fetchCourseOutcomes(code),
              ProgrammeSubjectService.fetchSubjectUnits(code),
              ProgrammeSubjectService.fetchAuditHistory(
                subj['id']?.toString() ?? code,
              ),
            ]).then((results) {
              setModalState(() {
                subjectMappings = results[0];
                subjectCOs = results[1];
                subjectUnits = results[2];
                auditLogs = results[3];
                isFetchingDetails = false;
              });
            });
          }

          return DefaultTabController(
            length: 7,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0052CC).withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      code,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0052CC),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: status == 'Active'
                          ? const Color(0xFF16A34A).withAlpha(25)
                          : const Color(0xFF64748B).withAlpha(25),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: status == 'Active'
                            ? const Color(0xFF16A34A)
                            : const Color(0xFF64748B),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 760,
                height: 520,
                child: Column(
                  children: [
                    const TabBar(
                      isScrollable: true,
                      labelColor: Color(0xFF0052CC),
                      unselectedLabelColor: Color(0xFF64748B),
                      indicatorColor: Color(0xFF0052CC),
                      tabs: [
                        Tab(text: 'Overview'),
                        Tab(text: 'Teaching & Credits'),
                        Tab(text: 'Assessment Pattern'),
                        Tab(text: 'Course Outcomes'),
                        Tab(text: 'Syllabus Modules'),
                        Tab(text: 'Programme Mapping'),
                        Tab(text: 'Audit History'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: isFetchingDetails
                          ? const Center(child: CircularProgressIndicator())
                          : TabBarView(
                              children: [
                                // Tab 1: Overview
                                SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      _detailTile('Subject Code', code),
                                      _detailTile('Subject Full Title', title),
                                      _detailTile(
                                        'Short Name',
                                        subj['short_name'] ?? '-',
                                      ),
                                      _detailTile('Department', dept),
                                      _detailTile('Subject Type', type),
                                      _detailTile('Status', status),
                                      _detailTile(
                                        'Description',
                                        subj['description'] ??
                                            'No overview text provided.',
                                      ),
                                    ],
                                  ),
                                ),

                                // Tab 2: Teaching & Credits
                                SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      _detailTile(
                                        'Lecture Hours (L)',
                                        '$l Hours/week',
                                      ),
                                      _detailTile(
                                        'Tutorial Hours (T)',
                                        '$t Hours/week',
                                      ),
                                      _detailTile(
                                        'Practical Hours (P)',
                                        '$p Hours/week',
                                      ),
                                      _detailTile(
                                        'Credit Value (C)',
                                        '$credits Credits',
                                      ),
                                      _detailTile(
                                        'Total Contact Hours',
                                        '$totalHrs Hours/week',
                                      ),
                                    ],
                                  ),
                                ),

                                // Tab 3: Assessment Pattern
                                SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      _detailTile(
                                        'Internal Assessment Maximum',
                                        '$intMax Marks',
                                      ),
                                      _detailTile(
                                        'External Exam Maximum',
                                        '$extMax Marks',
                                      ),
                                      _detailTile(
                                        'Practical Maximum',
                                        '$prcMax Marks',
                                      ),
                                      _detailTile(
                                        'Total Maximum Marks',
                                        '$totMax Marks',
                                      ),
                                      _detailTile(
                                        'Minimum Passing Threshold',
                                        '$minPass Marks',
                                      ),
                                      _detailTile(
                                        'Internal Minimum Threshold',
                                        '${subj['internal_min_marks'] ?? 20} Marks',
                                      ),
                                      _detailTile(
                                        'External Minimum Threshold',
                                        '${subj['external_min_marks'] ?? 20} Marks',
                                      ),
                                    ],
                                  ),
                                ),

                                // Tab 4: Course Outcomes
                                SingleChildScrollView(
                                  child: subjectCOs.isEmpty
                                      ? const Padding(
                                          padding: EdgeInsets.all(30),
                                          child: Center(
                                            child: Text(
                                              'No Course Outcomes Configured',
                                              style: TextStyle(
                                                color: Color(0xFF94A3B8),
                                              ),
                                            ),
                                          ),
                                        )
                                      : Column(
                                          children: subjectCOs
                                              .map(
                                                (co) => ListTile(
                                                  leading: CircleAvatar(
                                                    backgroundColor:
                                                        const Color(0xFFEFF6FF),
                                                    child: Text(
                                                      co['co_code'] ?? 'CO',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Color(
                                                          0xFF0052CC,
                                                        ),
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ),
                                                  title: Text(
                                                    co['co_description'] ?? '',
                                                  ),
                                                  subtitle: Text(
                                                    'Status: ${co['status']}',
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                        ),
                                ),

                                // Tab 5: Syllabus Modules
                                SingleChildScrollView(
                                  child: subjectUnits.isEmpty
                                      ? const Padding(
                                          padding: EdgeInsets.all(30),
                                          child: Center(
                                            child: Text(
                                              'No Syllabus Units Configured',
                                              style: TextStyle(
                                                color: Color(0xFF94A3B8),
                                              ),
                                            ),
                                          ),
                                        )
                                      : Column(
                                          children: subjectUnits
                                              .map(
                                                (u) => Card(
                                                  margin: const EdgeInsets.only(
                                                    bottom: 8,
                                                  ),
                                                  child: ListTile(
                                                    title: Text(
                                                      '${u['unit_number']}: ${u['unit_title']}',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    subtitle: Text(
                                                      'Topics: ${u['topics'] ?? 'General Topics'}',
                                                    ),
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                        ),
                                ),

                                // Tab 6: Programme Mapping
                                SingleChildScrollView(
                                  child: subjectMappings.isEmpty
                                      ? const Padding(
                                          padding: EdgeInsets.all(30),
                                          child: Center(
                                            child: Text(
                                              'Subject is not yet mapped to any programme curriculum.',
                                              style: TextStyle(
                                                color: Color(0xFF94A3B8),
                                              ),
                                            ),
                                          ),
                                        )
                                      : DataTable(
                                          columns: const [
                                            DataColumn(
                                              label: Text('Programme Code'),
                                            ),
                                            DataColumn(
                                              label: Text('Regulation'),
                                            ),
                                            DataColumn(label: Text('Semester')),
                                            DataColumn(label: Text('Type')),
                                            DataColumn(label: Text('Credits')),
                                          ],
                                          rows: subjectMappings
                                              .map(
                                                (m) => DataRow(
                                                  cells: [
                                                    DataCell(
                                                      Text(
                                                        m['programme_code']
                                                                ?.toString() ??
                                                            '',
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Color(
                                                            0xFF0052CC,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        m['regulation']
                                                                ?.toString() ??
                                                            'R2024',
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        'Semester ${m['semester']}',
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        m['subject_type']
                                                                ?.toString() ??
                                                            '',
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        '${m['credits']} Credits',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                              .toList(),
                                        ),
                                ),

                                // Tab 7: Audit History (Section 9)
                                SingleChildScrollView(
                                  child: auditLogs.isEmpty
                                      ? const Padding(
                                          padding: EdgeInsets.all(30),
                                          child: Center(
                                            child: Text(
                                              'No Audit History Records Found',
                                              style: TextStyle(
                                                color: Color(0xFF94A3B8),
                                              ),
                                            ),
                                          ),
                                        )
                                      : Column(
                                          children: auditLogs
                                              .map(
                                                (log) => Container(
                                                  margin: const EdgeInsets.only(
                                                    bottom: 8,
                                                  ),
                                                  padding: const EdgeInsets.all(
                                                    10,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xFFF8FAFC,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    border: Border.all(
                                                      color: const Color(
                                                        0xFFE2E8F0,
                                                      ),
                                                    ),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Text(
                                                            log['action']
                                                                    ?.toString() ??
                                                                'ACTION',
                                                            style:
                                                                const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Color(
                                                                    0xFF0052CC,
                                                                  ),
                                                                  fontSize: 12,
                                                                ),
                                                          ),
                                                          Text(
                                                            log['created_at']
                                                                    ?.toString() ??
                                                                '',
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 10,
                                                                  color: Color(
                                                                    0xFF94A3B8,
                                                                  ),
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        'Performed By: ${log['performed_by'] ?? 'Administrator'}',
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          color: Color(
                                                            0xFF64748B,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              )
                                              .toList(),
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
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── CONFIRM DELETE / DEACTIVATE ENFORCEMENT (SECTION 8) ─────────────────────
  void _confirmDeleteSubject(Map<String, dynamic> subj) async {
    final code = subj['code']?.toString() ?? '';
    final isReferenced = await ProgrammeSubjectService.isSubjectReferenced(
      code,
    );

    if (!mounted) return;

    if (isReferenced) {
      // Block hard delete & offer deactivation
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706)),
              SizedBox(width: 8),
              Text(
                'Deletion Blocked',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            'This subject ($code) cannot be deleted because it is referenced by existing academic records and programme curriculum mappings.',
            style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final id = subj['id']?.toString();
                if (id != null) {
                  await ProgrammeSubjectService.updateSubject(id, {
                    'status': 'Inactive',
                  });
                  _showSnack('Subject "$code" has been deactivated.');
                  if (mounted) {
                    Navigator.pop(ctx);
                    _loadData();
                  }
                }
              },
              icon: const Icon(Icons.block_rounded, size: 16),
              label: const Text('Deactivate Subject'),
            ),
          ],
        ),
      );
    } else {
      // Confirm normal deletion
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Delete Subject "$code"?',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Are you sure you want to permanently delete this subject from the central catalog?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final id = subj['id']?.toString();
                if (id != null) {
                  await ProgrammeSubjectService.deleteSubject(id);
                  _showSnack('Subject "$code" deleted.');
                  if (mounted) {
                    Navigator.pop(ctx);
                    _loadData();
                  }
                }
              },
              child: const Text('Delete'),
            ),
          ],
        ),
      );
    }
  }

  Widget _detailTile(String label, dynamic val) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        Text(
          (val ?? '-').toString(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    ),
  );

  // ── PROGRAMME CURRICULUM MODAL ─────────────────────────────────────────────
  void _showProgrammeDetailsModal(Map<String, dynamic> prog) {
    final code = prog['code'] ?? '';
    final name = prog['name'] ?? '';
    final progMappings = _mappings
        .where((m) => m['programme_code'] == code)
        .toList();

    showDialog(
      context: context,
      builder: (ctx) => DefaultTabController(
        length: 3,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.school_rounded, color: Color(0xFF0052CC)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$code: $name',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 720,
            height: 520,
            child: Column(
              children: [
                const TabBar(
                  labelColor: Color(0xFF0052CC),
                  unselectedLabelColor: Color(0xFF64748B),
                  indicatorColor: Color(0xFF0052CC),
                  tabs: [
                    Tab(text: 'Overview & Metadata'),
                    Tab(text: 'Curriculum & Semesters'),
                    Tab(text: 'Mapped Subjects'),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: TabBarView(
                    children: [
                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _detailTile('Programme Code', prog['code']),
                            _detailTile('Degree Level', prog['level']),
                            _detailTile('Department', prog['department']),
                            _detailTile(
                              'Duration & Semesters',
                              '${prog['duration']} (${prog['semesters']} Semesters)',
                            ),
                            _detailTile(
                              'Current Regulation',
                              prog['current_regulation'],
                            ),
                            _detailTile(
                              'Active Students Enrolled',
                              '${prog['active_students']} Students',
                            ),
                            _detailTile('Status', prog['status']),
                            _detailTile(
                              'Description',
                              prog['description'] ?? 'No description provided.',
                            ),
                          ],
                        ),
                      ),
                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(prog['semesters'] ?? 8, (
                            idx,
                          ) {
                            final semNum = idx + 1;
                            final semSubjects = progMappings
                                .where((m) => m['semester'] == semNum)
                                .toList();
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Semester $semNum',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF0052CC),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  if (semSubjects.isEmpty)
                                    const Text(
                                      'No subjects mapped to this semester.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    )
                                  else
                                    Column(
                                      children: semSubjects
                                          .map(
                                            (m) => Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 2,
                                                  ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    '${m['subject_code']} - ${m['subject_type']}',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  Text(
                                                    '${m['credits']} Credits',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Color(0xFF64748B),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                ],
                              ),
                            );
                          }),
                        ),
                      ),
                      SingleChildScrollView(
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Subject Code')),
                            DataColumn(label: Text('Semester')),
                            DataColumn(label: Text('Type')),
                            DataColumn(label: Text('Credits')),
                          ],
                          rows: progMappings
                              .map(
                                (m) => DataRow(
                                  cells: [
                                    DataCell(
                                      Text(m['subject_code']?.toString() ?? ''),
                                    ),
                                    DataCell(Text('Semester ${m['semester']}')),
                                    DataCell(
                                      Text(m['subject_type']?.toString() ?? ''),
                                    ),
                                    DataCell(Text('${m['credits']} Credits')),
                                  ],
                                ),
                              )
                              .toList(),
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
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  // ── MAP SUBJECT TO PROGRAMME MODAL ─────────────────────────────────────────
  void _showMapSubjectModal([String? preselectedSubject]) {
    var selectedProg = _programmes.isNotEmpty
        ? _programmes.first['code']?.toString()
        : null;
    var selectedSubj =
        preselectedSubject ??
        (_subjects.isNotEmpty ? _subjects.first['code']?.toString() : null);
    var selectedSem = 1;
    var type = 'Core';
    var credits = 3;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.alt_route_rounded, color: Color(0xFF0052CC)),
              SizedBox(width: 8),
              Text('Map Subject to Degree Programme'),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedProg,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Target Programme *',
                    border: OutlineInputBorder(),
                  ),
                  items: _programmes
                      .map(
                        (p) => DropdownMenuItem(
                          value: p['code']?.toString(),
                          child: Text('${p['code']} - ${p['name']}'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setModalState(() => selectedProg = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedSubj,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Catalog Subject *',
                    border: OutlineInputBorder(),
                  ),
                  items: _subjects
                      .map(
                        (s) => DropdownMenuItem(
                          value: s['code']?.toString(),
                          child: Text('${s['code']} - ${s['title']}'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setModalState(() => selectedSubj = v),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: selectedSem,
                        decoration: const InputDecoration(
                          labelText: 'Semester',
                          border: OutlineInputBorder(),
                        ),
                        items: List.generate(8, (i) => i + 1)
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text('Semester $s'),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setModalState(() => selectedSem = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: type,
                        decoration: const InputDecoration(
                          labelText: 'Type',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            [
                                  'Core',
                                  'Professional Elective',
                                  'Open Elective',
                                  'Laboratory',
                                ]
                                .map(
                                  (t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(t),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) => setModalState(() => type = v!),
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
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0052CC),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (selectedProg == null || selectedSubj == null) {
                  _showSnack(
                    'Please select both a programme and a subject.',
                    true,
                  );
                  return;
                }

                final payload = {
                  'programme_code': selectedProg,
                  'subject_code': selectedSubj,
                  'regulation': 'R2024',
                  'semester': selectedSem,
                  'subject_type': type,
                  'credits': credits,
                };

                await ProgrammeSubjectService.mapSubjectToProgramme(payload);
                _showSnack(
                  'Mapped subject $selectedSubj to $selectedProg (Sem $selectedSem).',
                );

                if (mounted) {
                  Navigator.pop(ctx);
                  _loadData();
                }
              },
              child: const Text('Confirm Mapping'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalProgs = _programmes.length;
    final ugProgs = _programmes.where((p) => p['level'] == 'UG').length;
    final pgProgs = _programmes.where((p) => p['level'] == 'PG').length;
    final totalSubjects = _subjects.length;
    final activeProgs = _programmes
        .where((p) => p['status'] == 'Active')
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;
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
                        'Programme & Subject Management',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Manage academic programmes, regulations, curriculum structure, and subject catalog.',
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
                            onPressed: _exportData,
                            icon: const Icon(Icons.download_rounded, size: 16),
                            label: const Text('Export'),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0052CC),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              if (_tabController.index == 0) {
                                _showAddEditProgrammeModal();
                              } else {
                                _showAddEditSubjectModal();
                              }
                            },
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: Text(
                              _tabController.index == 0
                                  ? '+ Add Programme'
                                  : '+ Add Subject',
                            ),
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
                              'Programme & Subject Management',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Manage academic programmes, regulations, curriculum structure, and subject catalog.',
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
                            onPressed: _exportData,
                            icon: const Icon(Icons.download_rounded, size: 16),
                            label: const Text('Export'),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0052CC),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              if (_tabController.index == 0) {
                                _showAddEditProgrammeModal();
                              } else {
                                _showAddEditSubjectModal();
                              }
                            },
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: Text(
                              _tabController.index == 0
                                  ? '+ Add Programme'
                                  : '+ Add Subject',
                            ),
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
                  crossAxisCount: constraints.maxWidth > 850
                      ? 5
                      : (constraints.maxWidth > 550 ? 3 : 2),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: constraints.maxWidth > 1200
                      ? 3.0
                      : (constraints.maxWidth > 850
                            ? 2.5
                            : (isMobile ? 2.1 : 2.4)),
                  children: [
                    _buildSummaryCard(
                      'Total Programmes',
                      '$totalProgs',
                      Icons.school_rounded,
                      const Color(0xFF0052CC),
                      'Degree Offerings',
                    ),
                    _buildSummaryCard(
                      'UG Programmes',
                      '$ugProgs',
                      Icons.workspace_premium_rounded,
                      const Color(0xFF16A34A),
                      'Undergraduate',
                    ),
                    _buildSummaryCard(
                      'PG Programmes',
                      '$pgProgs',
                      Icons.military_tech_rounded,
                      const Color(0xFF9333EA),
                      'Postgraduate',
                    ),
                    _buildSummaryCard(
                      'Total Subjects',
                      '$totalSubjects',
                      Icons.menu_book_rounded,
                      const Color(0xFFD97706),
                      'Central Catalog',
                    ),
                    _buildSummaryCard(
                      'Active Programmes',
                      '$activeProgs',
                      Icons.verified_rounded,
                      const Color(0xFF0284C7),
                      'Current Sessions',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── CLICK-ONLY NAVIGATION TABS ───────────────────────────────────
                Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    onTap: (idx) => setState(() {}),
                    labelColor: const Color(0xFF0052CC),
                    unselectedLabelColor: const Color(0xFF64748B),
                    indicatorColor: const Color(0xFF0052CC),
                    indicatorWeight: 3,
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.school_rounded, size: 18),
                        text: 'Programmes Master',
                      ),
                      Tab(
                        icon: Icon(Icons.menu_book_rounded, size: 18),
                        text: 'Subjects Catalog',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── TAB CONTENT WITH CLICK-ONLY PHYSICS ──────────────────────────
                SizedBox(
                  height: 680,
                  child: TabBarView(
                    controller: _tabController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [_buildProgrammesTab(), _buildSubjectsTab()],
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
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFE2E8F0)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withAlpha(2),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                val,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    ),
  );

  // ── TAB 1: PROGRAMMES MASTER ───────────────────────────────────────────────
  Widget _buildProgrammesTab() {
    final progs = _filteredProgrammes;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    onChanged: (v) => setState(() => _progSearch = v),
                    decoration: InputDecoration(
                      hintText: 'Search by programme code or name...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 16),
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
              ),
              const SizedBox(width: 10),
              DropdownButton<String>(
                value: _progLevelFilter,
                items: ['All', 'UG', 'PG', 'Diploma', 'Certificate', 'PhD']
                    .map(
                      (l) =>
                          DropdownMenuItem(value: l, child: Text('Level: $l')),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _progLevelFilter = v!),
              ),
              const SizedBox(width: 10),
              DropdownButton<String>(
                value: _progStatusFilter,
                items: ['All', 'Active', 'Inactive', 'Archived']
                    .map(
                      (s) =>
                          DropdownMenuItem(value: s, child: Text('Status: $s')),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _progStatusFilter = v!),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            )
          else if (progs.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    const Icon(
                      Icons.school_outlined,
                      size: 48,
                      color: Color(0xFFCBD5E1),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'No Programmes Configured',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Create a programme to begin configuring the institution academic structure.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0052CC),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _showAddEditProgrammeModal,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add Programme'),
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
                      'Programme Code',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Programme Name',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Level',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Department',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Duration',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Current Regulation',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Active Students',
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
                rows: progs.map((p) {
                  final code = p['code']?.toString() ?? '-';
                  final name = p['name']?.toString() ?? '-';
                  final level = p['level']?.toString() ?? 'UG';
                  final dept = p['department']?.toString() ?? '-';
                  final duration = p['duration']?.toString() ?? '4 Years';
                  final reg = p['current_regulation']?.toString() ?? 'R2024';
                  final students = p['active_students'] ?? 0;
                  final status = p['status']?.toString() ?? 'Active';

                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          code,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0052CC),
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0052CC).withAlpha(25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            level,
                            style: const TextStyle(
                              color: Color(0xFF0052CC),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                      DataCell(Text(dept)),
                      DataCell(Text(duration)),
                      DataCell(
                        Text(
                          reg,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(
                        Text(
                          '$students Students',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A).withAlpha(25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            status,
                            style: const TextStyle(
                              color: Color(0xFF16A34A),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        PopupMenuButton<String>(
                          onSelected: (v) async {
                            if (v == 'View Details') {
                              _showProgrammeDetailsModal(p);
                            } else if (v == 'Edit')
                              _showAddEditProgrammeModal(p);
                            else if (v == 'Map Subject')
                              _showMapSubjectModal();
                            else if (v == 'Delete') {
                              final id = p['id']?.toString();
                              if (id != null) {
                                await ProgrammeSubjectService.deleteProgramme(
                                  id,
                                );
                                _showSnack('Programme deleted.');
                                _loadData();
                              }
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'View Details',
                              child: Text('View Details & Curriculum'),
                            ),
                            const PopupMenuItem(
                              value: 'Edit',
                              child: Text('Edit Programme'),
                            ),
                            const PopupMenuItem(
                              value: 'Map Subject',
                              child: Text('Map Subject to Semester'),
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
    );
  }

  // ── TAB 2: SUBJECTS CATALOG (SECTION 4 REVISED TABLE) ──────────────────────
  Widget _buildSubjectsTab() {
    final subs = _filteredSubjects;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Bar
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    onChanged: (v) => setState(() => _subjSearch = v),
                    decoration: InputDecoration(
                      hintText: 'Search by subject code or title...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 16),
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
              ),
              const SizedBox(width: 10),
              DropdownButton<String>(
                value: _subjTypeFilter,
                items:
                    [
                          'All',
                          'Core',
                          'Professional Core',
                          'Professional Elective',
                          'Open Elective',
                          'Laboratory',
                          'Project',
                          'Seminar',
                          'Value Added Course',
                        ]
                        .map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text('Type: $t'),
                          ),
                        )
                        .toList(),
                onChanged: (v) => setState(() => _subjTypeFilter = v!),
              ),
              const SizedBox(width: 10),
              DropdownButton<String>(
                value: _subjStatusFilter,
                items: ['All', 'Active', 'Inactive']
                    .map(
                      (s) =>
                          DropdownMenuItem(value: s, child: Text('Status: $s')),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _subjStatusFilter = v!),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            )
          else if (subs.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    const Icon(
                      Icons.menu_book_outlined,
                      size: 48,
                      color: Color(0xFFCBD5E1),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'No Subjects in Central Catalog',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Create subjects in the central subject catalog before mapping them to programmes.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0052CC),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _showAddEditSubjectModal,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add Subject'),
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
                      'Subject Code',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Subject Name',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Department',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Subject Type',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'L',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'T',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'P',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Credits',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Total Hours',
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
                rows: subs.map((s) {
                  final code = s['code']?.toString() ?? '-';
                  final title = s['title']?.toString() ?? '-';
                  final dept = s['department']?.toString() ?? '-';
                  final type = s['subject_type']?.toString() ?? 'Core';
                  final l =
                      int.tryParse(s['lecture_hours']?.toString() ?? '3') ?? 3;
                  final t =
                      int.tryParse(s['tutorial_hours']?.toString() ?? '0') ?? 0;
                  final p =
                      int.tryParse(s['practical_hours']?.toString() ?? '0') ??
                      0;
                  final credits = s['credits']?.toString() ?? '3.0';
                  final totalHrs = '${l + t + p} hrs/wk';
                  final status = s['status']?.toString() ?? 'Active';

                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          code,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0052CC),
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      DataCell(Text(dept)),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0052CC).withAlpha(25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            type,
                            style: const TextStyle(
                              color: Color(0xFF0052CC),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          '$l',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(
                        Text(
                          '$t',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(
                        Text(
                          '$p',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(
                        Text(
                          '$credits C',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          totalHrs,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: status == 'Active'
                                ? const Color(0xFF16A34A).withAlpha(25)
                                : const Color(0xFF64748B).withAlpha(25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: status == 'Active'
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFF64748B),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        PopupMenuButton<String>(
                          onSelected: (v) async {
                            if (v == 'View Details') {
                              _showSubjectDetailsModal(s);
                            } else if (v == 'Edit')
                              _showAddEditSubjectModal(s);
                            else if (v == 'Map to Programme')
                              _showMapSubjectModal(code);
                            else if (v == 'Delete')
                              _confirmDeleteSubject(s);
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'View Details',
                              child: Text('View Details & Assessment'),
                            ),
                            const PopupMenuItem(
                              value: 'Edit',
                              child: Text('Edit Subject Catalog Entry'),
                            ),
                            const PopupMenuItem(
                              value: 'Map to Programme',
                              child: Text('Map to Programme Curriculum'),
                            ),
                            const PopupMenuItem(
                              value: 'Delete',
                              child: Text('Deactivate / Delete Subject'),
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
    );
  }
}

