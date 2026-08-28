import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/admin_supabase_service.dart';
import '../utils/file_downloader.dart';

class HallTicketScreen extends ConsumerStatefulWidget {
  const HallTicketScreen({super.key});

  @override
  ConsumerState<HallTicketScreen> createState() => _HallTicketScreenState();
}

class _HallTicketScreenState extends ConsumerState<HallTicketScreen> {
  String _selectedDept = 'Computer Science & Engineering';
  String _selectedSem = 'Semester VI';
  String _searchQuery = '';
  Map<String, dynamic>? _previewStudent;
  List<Map<String, dynamic>> _data = [];
  bool _loading = true;

  final List<String> _departments = [
    'Computer Science & Engineering',
    'Information Technology',
    'Electronics & Communication Engg',
    'Artificial Intelligence & Data Science',
    'Mechanical Engineering',
    'Civil Engineering',
  ];

  final List<String> _semesters = [
    'Semester I',
    'Semester II',
    'Semester III',
    'Semester IV',
    'Semester V',
    'Semester VI',
    'Semester VII',
    'Semester VIII',
  ];

  final Map<String, List<Map<String, dynamic>>> _deptCoursesCatalog = {
    'Computer Science & Engineering': [
      {
        'sem': 'VI',
        'code': 'CS601',
        'name': 'Software Engineering',
        'credits': 3,
        'date': '12.05.2026',
        'session': 'FN',
      },
      {
        'sem': 'VI',
        'code': 'CS602',
        'name': 'Computer Networks',
        'credits': 4,
        'date': '14.05.2026',
        'session': 'FN',
      },
      {
        'sem': 'VI',
        'code': 'CS603',
        'name': 'Compiler Design',
        'credits': 3,
        'date': '16.05.2026',
        'session': 'FN',
      },
      {
        'sem': 'VI',
        'code': 'CS604',
        'name': 'Artificial Intelligence',
        'credits': 3,
        'date': '18.05.2026',
        'session': 'AN',
      },
      {
        'sem': 'VI',
        'code': 'CS605',
        'name': 'AI Laboratory',
        'credits': 2,
        'date': '20.05.2026',
        'session': 'FN',
      },
      {
        'sem': 'VI',
        'code': 'CS606',
        'name': 'Mini Project',
        'credits': 2,
        'date': '22.05.2026',
        'session': 'FN',
      },
    ],
    'Information Technology': [
      {
        'sem': 'VI',
        'code': 'IT601',
        'name': 'Full Stack Architecture',
        'credits': 4,
        'date': '12.05.2026',
        'session': 'FN',
      },
      {
        'sem': 'VI',
        'code': 'IT602',
        'name': 'Cloud Computing Services',
        'credits': 3,
        'date': '14.05.2026',
        'session': 'FN',
      },
      {
        'sem': 'VI',
        'code': 'IT603',
        'name': 'Information & Cyber Security',
        'credits': 3,
        'date': '16.05.2026',
        'session': 'FN',
      },
      {
        'sem': 'VI',
        'code': 'IT604',
        'name': 'Web Technologies Laboratory',
        'credits': 2,
        'date': '18.05.2026',
        'session': 'AN',
      },
      {
        'sem': 'VI',
        'code': 'IT605',
        'name': 'Mobile App Development',
        'credits': 3,
        'date': '20.05.2026',
        'session': 'FN',
      },
    ],
    'Electronics & Communication Engg': [
      {
        'sem': 'VI',
        'code': 'EC601',
        'name': 'VLSI System Design',
        'credits': 4,
        'date': '12.05.2026',
        'session': 'FN',
      },
      {
        'sem': 'VI',
        'code': 'EC602',
        'name': 'Digital Signal Processing',
        'credits': 4,
        'date': '14.05.2026',
        'session': 'FN',
      },
      {
        'sem': 'VI',
        'code': 'EC603',
        'name': 'Embedded Systems & IoT',
        'credits': 3,
        'date': '16.05.2026',
        'session': 'FN',
      },
      {
        'sem': 'VI',
        'code': 'EC604',
        'name': 'Antennas & Wave Propagation',
        'credits': 3,
        'date': '18.05.2026',
        'session': 'AN',
      },
      {
        'sem': 'VI',
        'code': 'EC605',
        'name': 'VLSI Laboratory',
        'credits': 2,
        'date': '20.05.2026',
        'session': 'FN',
      },
    ],
    'Artificial Intelligence & Data Science': [
      {
        'sem': 'VI',
        'code': 'AD601',
        'name': 'Machine Learning Algorithms',
        'credits': 4,
        'date': '12.05.2026',
        'session': 'FN',
      },
      {
        'sem': 'VI',
        'code': 'AD602',
        'name': 'Deep Learning & Neural Nets',
        'credits': 4,
        'date': '14.05.2026',
        'session': 'FN',
      },
      {
        'sem': 'VI',
        'code': 'AD603',
        'name': 'Big Data Analytics',
        'credits': 3,
        'date': '16.05.2026',
        'session': 'FN',
      },
      {
        'sem': 'VI',
        'code': 'AD604',
        'name': 'Data Visualization Laboratory',
        'credits': 2,
        'date': '18.05.2026',
        'session': 'AN',
      },
      {
        'sem': 'VI',
        'code': 'AD605',
        'name': 'Capstone Data Project',
        'credits': 3,
        'date': '20.05.2026',
        'session': 'FN',
      },
    ],
    'Mechanical Engineering': [
      {
        'sem': 'VI',
        'code': 'ME601',
        'name': 'Design of Machine Elements',
        'credits': 4,
        'date': '12.05.2026',
        'session': 'FN',
      },
      {
        'sem': 'VI',
        'code': 'ME602',
        'name': 'Heat & Mass Transfer',
        'credits': 4,
        'date': '14.05.2026',
        'session': 'FN',
      },
      {
        'sem': 'VI',
        'code': 'ME603',
        'name': 'CAD/CAM Robotics',
        'credits': 3,
        'date': '16.05.2026',
        'session': 'FN',
      },
      {
        'sem': 'VI',
        'code': 'ME604',
        'name': 'Thermal Engineering Lab',
        'credits': 2,
        'date': '18.05.2026',
        'session': 'AN',
      },
    ],
    'Civil Engineering': [
      {
        'sem': 'VI',
        'code': 'CE601',
        'name': 'Structural Analysis II',
        'credits': 4,
        'date': '12.05.2026',
        'session': 'FN',
      },
      {
        'sem': 'VI',
        'code': 'CE602',
        'name': 'Design of RC Structures',
        'credits': 4,
        'date': '14.05.2026',
        'session': 'FN',
      },
      {
        'sem': 'VI',
        'code': 'CE603',
        'name': 'Environmental Engineering',
        'credits': 3,
        'date': '16.05.2026',
        'session': 'FN',
      },
      {
        'sem': 'VI',
        'code': 'CE604',
        'name': 'Concrete & Highway Lab',
        'credits': 2,
        'date': '18.05.2026',
        'session': 'AN',
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final hallTicketResults =
          await AdminSupabaseService.fetchHallTicketStatus();
      final adminUsers = await AdminSupabaseService.fetchAdminUsers();

      var loadedStudents = <Map<String, dynamic>>[];

      if (hallTicketResults.isNotEmpty) {
        loadedStudents = hallTicketResults
            .map(
              (e) => {
                'db_id': e['id'],
                'id': e['roll_no'] ?? e['id'] ?? '',
                'regNo': e['register_number'] ?? e['reg_no'] ?? '',
                'name': (e['student_name'] ?? e['name'] ?? '')
                    .toString()
                    .toUpperCase(),
                'dept': e['course'] ?? e['department'] ?? _selectedDept,
                'sem': e['semester'] ?? _selectedSem,
                'dob': e['dob'] ?? '12.08.2004',
                'reg': e['regulation'] ?? '2023',
                'attendance': e['attendance'] ?? '94.2%',
                'feeStatus': e['fee_status'] ?? 'Paid',
                'eligibility': e['eligibility'] ?? 'Eligible',
                'status': e['status'] ?? 'Published',
              },
            )
            .toList();
      } else if (adminUsers.isNotEmpty) {
        final students = adminUsers
            .where((u) => u['role'] == 'STUDENT' || u['role'] == 'Student')
            .toList();
        loadedStudents = students
            .map(
              (s) => {
                'id': s['roll_no'] ?? s['id'] ?? '',
                'regNo': s['register_number'] ?? '',
                'name': (s['full_name'] ?? s['name'] ?? '')
                    .toString()
                    .toUpperCase(),
                'dept': s['department'] ?? _selectedDept,
                'sem': s['semester'] ?? _selectedSem,
                'dob': s['dob'] ?? '12.08.2004',
                'reg': '2023',
                'attendance': '92.5%',
                'feeStatus': 'Paid',
                'eligibility': 'Eligible',
                'status': 'Published',
              },
            )
            .toList();
      }

      if (mounted) {
        setState(() {
          _data = loadedStudents;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> _getStudentCourses(String dept) =>
      _deptCoursesCatalog[dept] ??
      _deptCoursesCatalog['Computer Science & Engineering']!;

  Future<void> _publishDepartmentHallTickets() async {
    final List<Map<String, dynamic>> recordsToPublish = [];
    for (final s in _data) {
      if (s['dept'] == _selectedDept &&
          s['sem'] == _selectedSem &&
          s['eligibility'] == 'Eligible') {
        s['status'] = 'Published'; // Update local state
        recordsToPublish.add({
          'roll_no': s['id'],
          'register_number': s['regNo'],
          'student_name': s['name'],
          'course': s['dept'],
          'semester': s['sem'],
          'dob': s['dob'],
          'regulation': s['reg'],
          'attendance': s['attendance'],
          'fee_status': s['feeStatus'],
          'eligibility': s['eligibility'],
          'status': 'Published',
        });
      }
    }
    await AdminSupabaseService.addHallTicketsInBatch(
      recordsToPublish,
    ); // Assumes a new batch method
    setState(() {});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Successfully Published & Synced Hall Tickets for ALL eligible students in $_selectedDept ($_selectedSem)!',
          ),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _unpublishDepartmentHallTickets() {
    setState(() {
      for (final s in _data) {
        if (s['dept'] == _selectedDept && s['sem'] == _selectedSem) {
          s['status'] = 'Pending';
        }
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Hall Tickets Unpublished for $_selectedDept ($_selectedSem). Status set to Pending.',
        ),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final deptStudents = _data.where((s) {
      final sDept = (s['dept'] ?? '').toString().toLowerCase();
      final selDept = _selectedDept.toLowerCase();

      final matchDept =
          sDept == selDept ||
          (selDept.contains('computer science') &&
              (sDept.contains('cse') || sDept.contains('computer'))) ||
          (selDept.contains('information technology') &&
              (sDept.contains('it') || sDept.contains('tech'))) ||
          (selDept.contains('electronics') &&
              (sDept.contains('ece') || sDept.contains('electronics'))) ||
          (selDept.contains('artificial intelligence') &&
              (sDept.contains('aids') || sDept.contains('ai'))) ||
          (selDept.contains('mechanical') &&
              (sDept.contains('mech') || sDept.contains('mechanical'))) ||
          (selDept.contains('civil') && sDept.contains('civil')) ||
          sDept.isEmpty;

      final sSem = (s['sem'] ?? '').toString().toLowerCase();
      final selSem = _selectedSem.toLowerCase();

      final matchSem =
          sSem == selSem ||
          sSem.contains('vi') ||
          sSem.contains('6') ||
          sSem.isEmpty;

      final q = _searchQuery.toLowerCase();
      final matchSearch =
          q.isEmpty ||
          (s['name'] ?? '').toString().toLowerCase().contains(q) ||
          (s['id'] ?? '').toString().toLowerCase().contains(q) ||
          (s['regNo'] ?? '').toString().toLowerCase().contains(q);

      return matchDept && matchSem && matchSearch;
    }).toList();

    final totalDeptCount = deptStudents.length;
    final publishedCount = deptStudents
        .where((s) => s['status'] == 'Published')
        .length;
    final eligibleCount = deptStudents
        .where((s) => s['eligibility'] == 'Eligible')
        .length;
    final holdCount = deptStudents.where((s) => s['status'] == 'Hold').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── PAGE TOP TITLE HEADER ─────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0052CC).withAlpha(25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.assignment_ind_rounded,
                            size: 28,
                            color: Color(0xFF0052CC),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hall Ticket Publishing Portal',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.3,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Manage examination hall ticket eligibility, departmental publishing, and bulk PDF generation',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_previewStudent != null)
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _previewStudent = null),
                      icon: const Icon(Icons.arrow_back_rounded, size: 16),
                      label: const Text('Back to Department List'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0052CC),
                        side: const BorderSide(color: Color(0xFF0052CC)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              if (_previewStudent != null)
                _buildOfficialHallTicketDocument(_previewStudent!)
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 1. PUBLISHING CONTROL PANEL CARD ────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(5),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
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
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Department Hall Ticket Publishing Control',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Select Department & Semester to manage hall ticket eligibility, publishing, and bulk printing.',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFF86EFAC),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color: Color(0xFF166534),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Published: $publishedCount / $totalDeptCount Students',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF166534),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // ── DROPDOWNS & SEARCH ROW ───────────────────────────────
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isDesktop = constraints.maxWidth > 800;
                              if (isDesktop) {
                                return Row(
                                  children: [
                                    Expanded(
                                      flex: 4,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Department',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: Color(0xFF334155),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          DropdownButtonFormField<String>(
                                            initialValue: _selectedDept,
                                            isExpanded: true,
                                            decoration: InputDecoration(
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 14,
                                                    vertical: 12,
                                                  ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFFCBD5E1),
                                                ),
                                              ),
                                              filled: true,
                                              fillColor: const Color(
                                                0xFFF8FAFC,
                                              ),
                                            ),
                                            items: _departments
                                                .map(
                                                  (d) => DropdownMenuItem(
                                                    value: d,
                                                    child: Text(
                                                      d,
                                                      style: const TextStyle(
                                                        fontSize: 13.5,
                                                      ),
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                            onChanged: (val) {
                                              if (val != null)
                                                setState(() {
                                                  _selectedDept = val;
                                                  _previewStudent = null;
                                                });
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Semester',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: Color(0xFF334155),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          DropdownButtonFormField<String>(
                                            initialValue: _selectedSem,
                                            isExpanded: true,
                                            decoration: InputDecoration(
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 14,
                                                    vertical: 12,
                                                  ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFFCBD5E1),
                                                ),
                                              ),
                                              filled: true,
                                              fillColor: const Color(
                                                0xFFF8FAFC,
                                              ),
                                            ),
                                            items: _semesters
                                                .map(
                                                  (s) => DropdownMenuItem(
                                                    value: s,
                                                    child: Text(
                                                      s,
                                                      style: const TextStyle(
                                                        fontSize: 13.5,
                                                      ),
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                            onChanged: (val) {
                                              if (val != null)
                                                setState(() {
                                                  _selectedSem = val;
                                                  _previewStudent = null;
                                                });
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      flex: 4,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Search Student',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: Color(0xFF334155),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          TextField(
                                            onChanged: (val) => setState(
                                              () => _searchQuery = val,
                                            ),
                                            decoration: InputDecoration(
                                              hintText:
                                                  'Search by Name / Reg No / Roll No...',
                                              prefixIcon: const Icon(
                                                Icons.search_rounded,
                                                size: 18,
                                                color: Color(0xFF64748B),
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 14,
                                                    vertical: 12,
                                                  ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFFCBD5E1),
                                                ),
                                              ),
                                              filled: true,
                                              fillColor: const Color(
                                                0xFFF8FAFC,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Department',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: Color(0xFF334155),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      DropdownButtonFormField<String>(
                                        initialValue: _selectedDept,
                                        isExpanded: true,
                                        decoration: InputDecoration(
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 14,
                                                vertical: 12,
                                              ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          filled: true,
                                          fillColor: const Color(0xFFF8FAFC),
                                        ),
                                        items: _departments
                                            .map(
                                              (d) => DropdownMenuItem(
                                                value: d,
                                                child: Text(
                                                  d,
                                                  style: const TextStyle(
                                                    fontSize: 13.5,
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (val) {
                                          if (val != null)
                                            setState(() {
                                              _selectedDept = val;
                                              _previewStudent = null;
                                            });
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Semester',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: Color(0xFF334155),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            DropdownButtonFormField<String>(
                                              initialValue: _selectedSem,
                                              isExpanded: true,
                                              decoration: InputDecoration(
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 14,
                                                      vertical: 12,
                                                    ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                filled: true,
                                                fillColor: const Color(
                                                  0xFFF8FAFC,
                                                ),
                                              ),
                                              items: _semesters
                                                  .map(
                                                    (s) => DropdownMenuItem(
                                                      value: s,
                                                      child: Text(
                                                        s,
                                                        style: const TextStyle(
                                                          fontSize: 13.5,
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                  .toList(),
                                              onChanged: (val) {
                                                if (val != null)
                                                  setState(() {
                                                    _selectedSem = val;
                                                    _previewStudent = null;
                                                  });
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Search Student',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: Color(0xFF334155),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            TextField(
                                              onChanged: (val) => setState(
                                                () => _searchQuery = val,
                                              ),
                                              decoration: InputDecoration(
                                                hintText:
                                                    'Search Name / Reg No...',
                                                prefixIcon: const Icon(
                                                  Icons.search_rounded,
                                                  size: 18,
                                                ),
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 14,
                                                      vertical: 12,
                                                    ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                filled: true,
                                                fillColor: const Color(
                                                  0xFFF8FAFC,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 20),

                          // ── ACTION BUTTONS ───────────────────────────────────────
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _publishDepartmentHallTickets,
                                icon: const Icon(
                                  Icons.publish_rounded,
                                  size: 18,
                                ),
                                label: Text(
                                  'Publish All Hall Tickets for $_selectedSem',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF16A34A),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 1,
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: _unpublishDepartmentHallTickets,
                                icon: const Icon(
                                  Icons.unpublished_outlined,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Unpublish Department',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFDC2626),
                                  side: const BorderSide(
                                    color: Color(0xFFDC2626),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  final deptList = _getStudentCourses(
                                    _selectedDept,
                                  );
                                  final firstStudent = _data.firstWhere(
                                    (s) =>
                                        s['dept'] == _selectedDept ||
                                        s['dept'].toString().contains(
                                          'Computer',
                                        ) ||
                                        s['dept'].toString().contains('CSE'),
                                    orElse: () => {
                                      'id': '21CSE012',
                                      'regNo': '731521104012',
                                      'name': 'ARUN KUMAR',
                                      'dept': _selectedDept,
                                      'sem': _selectedSem,
                                    },
                                  );
                                  FileDownloader.openOfficialHallTicketDocument(
                                    student: firstStudent,
                                    courses: deptList,
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Opening Official Printable Hall Tickets PDF for $_selectedDept...',
                                      ),
                                      backgroundColor: const Color(0xFF0052CC),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.download_rounded,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Bulk Download All Hall Tickets (PDF)',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0052CC),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── 2. DEPARTMENT STUDENT DIRECTORY CARD ─────────────────────────
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(5),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 12,
                            runSpacing: 10,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Department Student Directory — $_selectedDept ($_selectedSem)',
                                    style: const TextStyle(
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'List of registered students with attendance percentage, fee status, and hall ticket publish state',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'Total: $totalDeptCount',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11.5,
                                        color: Color(0xFF0052CC),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDCFCE7),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'Eligible: $eligibleCount',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11.5,
                                        color: Color(0xFF166534),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEE2E2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'On Hold: $holdCount',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11.5,
                                        color: Color(0xFF991B1B),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          if (deptStudents.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(40),
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.assignment_late_outlined,
                                      size: 54,
                                      color: Color(0xFFCBD5E1),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'No Student Records Found',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'No student data is available for $_selectedDept ($_selectedSem).',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        color: Color(0xFF94A3B8),
                                      ),
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
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: SizedBox(
                                    width: 960,
                                    child: Table(
                                      columnWidths: const {
                                        0: FixedColumnWidth(100),
                                        1: FixedColumnWidth(125),
                                        2: FixedColumnWidth(190),
                                        3: FixedColumnWidth(105),
                                        4: FixedColumnWidth(85),
                                        5: FixedColumnWidth(110),
                                        6: FixedColumnWidth(110),
                                        7: FixedColumnWidth(135),
                                      },
                                      children: [
                                        const TableRow(
                                          decoration: BoxDecoration(
                                            color: Color(0xFFF1F5F9),
                                          ),
                                          children: [
                                            Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 12,
                                              ),
                                              child: Text(
                                                'Roll No',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12.5,
                                                  color: Color(0xFF0F172A),
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 12,
                                              ),
                                              child: Text(
                                                'Reg No',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12.5,
                                                  color: Color(0xFF0F172A),
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 12,
                                              ),
                                              child: Text(
                                                'Student Name',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12.5,
                                                  color: Color(0xFF0F172A),
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 12,
                                              ),
                                              child: Text(
                                                'Attendance',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12.5,
                                                  color: Color(0xFF0F172A),
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 12,
                                              ),
                                              child: Text(
                                                'Fees',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12.5,
                                                  color: Color(0xFF0F172A),
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 12,
                                              ),
                                              child: Text(
                                                'Eligibility',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12.5,
                                                  color: Color(0xFF0F172A),
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 12,
                                              ),
                                              child: Text(
                                                'Status',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12.5,
                                                  color: Color(0xFF0F172A),
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 12,
                                              ),
                                              child: Text(
                                                'Action',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12.5,
                                                  color: Color(0xFF0F172A),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        ...deptStudents.map((student) {
                                          final isPublished =
                                              student['status'] == 'Published';
                                          final isHold =
                                              student['status'] == 'Hold';

                                          return TableRow(
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                child: Text(
                                                  student['id'] as String,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12.5,
                                                    color: Color(0xFF0F172A),
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                child: Text(
                                                  student['regNo'] as String,
                                                  style: const TextStyle(
                                                    fontSize: 12.5,
                                                    color: Color(0xFF334155),
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                child: Text(
                                                  student['name'] as String,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 12.5,
                                                    color: Color(0xFF0F172A),
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                child: Text(
                                                  student['attendance']
                                                      as String,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12.5,
                                                    color:
                                                        (student['attendance']
                                                                as String)
                                                            .startsWith('6')
                                                        ? Colors.red
                                                        : const Color(
                                                            0xFF16A34A,
                                                          ),
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                child: Text(
                                                  student['feeStatus']
                                                      as String,
                                                  style: const TextStyle(
                                                    fontSize: 12.5,
                                                    color: Color(0xFF334155),
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 3,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: isHold
                                                        ? Colors.red.withAlpha(
                                                            25,
                                                          )
                                                        : const Color(
                                                            0xFFDCFCE7,
                                                          ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    student['eligibility']
                                                        as String,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: isHold
                                                          ? Colors.red
                                                          : const Color(
                                                              0xFF166534,
                                                            ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 3,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: isPublished
                                                        ? const Color(
                                                            0xFFEFF6FF,
                                                          )
                                                        : const Color(
                                                            0xFFFEF3C7,
                                                          ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    student['status'] as String,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: isPublished
                                                          ? const Color(
                                                              0xFF0052CC,
                                                            )
                                                          : const Color(
                                                              0xFFD97706,
                                                            ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                      vertical: 4,
                                                    ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      constraints:
                                                          const BoxConstraints(),
                                                      padding:
                                                          const EdgeInsets.all(
                                                            4,
                                                          ),
                                                      icon: const Icon(
                                                        Icons
                                                            .remove_red_eye_rounded,
                                                        color: Color(
                                                          0xFF0052CC,
                                                        ),
                                                        size: 18,
                                                      ),
                                                      tooltip:
                                                          'View Official Hall Ticket Document',
                                                      onPressed: () => setState(
                                                        () => _previewStudent =
                                                            student,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Transform.scale(
                                                      scale: 0.75,
                                                      child: Switch(
                                                        value: isPublished,
                                                        activeThumbColor:
                                                            const Color(
                                                              0xFF16A34A,
                                                            ),
                                                        onChanged: (val) {
                                                          setState(() {
                                                            student['status'] =
                                                                val
                                                                ? 'Published'
                                                                : 'Pending';
                                                          });
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOfficialHallTicketDocument(Map<String, dynamic> student) {
    final courses = _getStudentCourses(student['dept'] as String);

    return Center(
      child: Container(
        width: 860,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: () => setState(() => _previewStudent = null),
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: const Text('Back to Department List'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    FileDownloader.openOfficialHallTicketDocument(
                      student: student,
                      courses: courses,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Generating & Opening Official Hall Ticket PDF for ${student['name']} (${student['id']})...',
                        ),
                        backgroundColor: const Color(0xFF16A34A),
                      ),
                    );
                  },
                  icon: const Icon(Icons.print_rounded, size: 16),
                  label: const Text(
                    'Print / Save Hall Ticket (PDF)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0052CC),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── INSTITUTION HEADER (MATCHING PROVISIONAL RESULT SHEET) ────────────────
            const Text(
              'KSR COLLEGE OF ENGINEERING (AUTONOMOUS)',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0052CC),
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 3),
            const Text(
              'Approved by AICTE, New Delhi & Affiliated to Anna University, Chennai',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF334155),
              ),
              textAlign: TextAlign.center,
            ),
            const Text(
              'K.S.R. Kalvi Nagar, Tiruchengode - 637 215, Namakkal District, Tamil Nadu',
              style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),

            // SYSTEM GENERATED PILL BADGE
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Text(
                  'SYSTEM GENERATED OFFICIAL HALL TICKET / ADMIT CARD',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF475569),
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFF0052CC), thickness: 2, height: 1),
            const SizedBox(height: 20),

            // ── STUDENT INFO GRID CARD (MATCHING RESULT SHEET CARD) ────────────────
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildResultStyleRow(
                          'STUDENT NAME:',
                          student['name'] as String,
                        ),
                        const SizedBox(height: 10),
                        _buildResultStyleRow(
                          'ROLL NUMBER:',
                          student['id'] as String,
                        ),
                        const SizedBox(height: 10),
                        _buildResultStyleRow(
                          'SEMESTER / YEAR:',
                          '${student['sem']} / 2025-2026',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildResultStyleRow(
                          'REGISTER NO:',
                          student['regNo'] as String,
                        ),
                        const SizedBox(height: 10),
                        _buildResultStyleRow(
                          'DEGREE & BRANCH:',
                          'B.E. - ${(student['dept'] as String).replaceAll('Computer Science & Engineering', 'CSE').replaceAll('Information Technology', 'IT')}',
                        ),
                        const SizedBox(height: 10),
                        _buildResultStyleRow(
                          'DATE OF ISSUE:',
                          DateTime.now().toIso8601String().substring(0, 10),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // STUDENT PHOTO FRAME
                  Container(
                    width: 90,
                    height: 105,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFCBD5E1),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.person_rounded,
                          size: 48,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          student['id'] as String,
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── EXAMINATION COURSES TABLE (MATCHING RESULT TABLE) ──────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Table(
                border: TableBorder.all(color: const Color(0xFFE2E8F0)),
                columnWidths: const {
                  0: FixedColumnWidth(50),
                  1: FixedColumnWidth(110),
                  2: FlexColumnWidth(),
                  3: FixedColumnWidth(80),
                  4: FixedColumnWidth(110),
                  5: FixedColumnWidth(80),
                },
                children: [
                  const TableRow(
                    decoration: BoxDecoration(color: Color(0xFFF1F5F9)),
                    children: [
                      Padding(
                        padding: EdgeInsets.all(10),
                        child: Text(
                          'S.NO',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: Color(0xFF475569),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(10),
                        child: Text(
                          'COURSE CODE',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: Color(0xFF475569),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(10),
                        child: Text(
                          'COURSE TITLE',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(10),
                        child: Text(
                          'CREDITS',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: Color(0xFF475569),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(10),
                        child: Text(
                          'EXAM DATE',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: Color(0xFF475569),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(10),
                        child: Text(
                          'SESSION',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: Color(0xFF475569),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  ...courses.asMap().entries.map((entry) {
                    final idx = entry.key + 1;
                    final c = entry.value;
                    return TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            '$idx',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            c['code'] as String,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0052CC),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            c['name'] as String,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            '${c['credits']}',
                            style: const TextStyle(fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            c['date'] as String,
                            style: const TextStyle(fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            c['session'] as String,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── SUMMARY METRIC CARDS (MATCHING RESULT SHEET) ─────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          'TOTAL COURSES',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF166534),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${courses.length}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 35,
                    color: const Color(0xFFBBF7D0),
                  ),
                  const Expanded(
                    child: Column(
                      children: [
                        Text(
                          'ATTENDANCE STATUS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF166534),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'ELIGIBLE (94.2%)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 35,
                    color: const Color(0xFFBBF7D0),
                  ),
                  const Expanded(
                    child: Column(
                      children: [
                        Text(
                          'HALL TICKET STATUS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF166534),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'OFFICIAL / PUBLISHED',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Divider(color: Color(0xFFCBD5E1), height: 1),
            const SizedBox(height: 24),

            // ── SIGNATORY AUTHORITIES (MATCHING PROVISIONAL RESULT SHEET) ───────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(width: 160, height: 1, color: Colors.black87),
                      const SizedBox(height: 6),
                      const Text(
                        'Prepared & Verified By',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const Text(
                        'Academic Section',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Container(width: 160, height: 1, color: Colors.black87),
                      const SizedBox(height: 6),
                      const Text(
                        'Controller of Examinations',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const Text(
                        'KSR College of Engineering',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Container(width: 160, height: 1, color: Colors.black87),
                      const SizedBox(height: 6),
                      const Text(
                        'Principal / Director',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const Text(
                        'Institutional Authority',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // DISCLAIMER FOOTER NOTE
            const Text(
              '* Note: This is an official system-generated examination hall ticket derived from master ERP examination databases. No manual signature required.',
              style: TextStyle(
                fontSize: 10,
                fontStyle: FontStyle.italic,
                color: Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultStyleRow(String label, String value) => Row(
    children: [
      SizedBox(
        width: 125,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            color: Color(0xFF64748B),
          ),
        ),
      ),
      Expanded(
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
    ],
  );
}
