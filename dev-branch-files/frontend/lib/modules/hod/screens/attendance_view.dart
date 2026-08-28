import 'package:flutter/material.dart';
import '../hod_toast.dart';
import '../export_dialog_helper.dart';
import '../responsive.dart';
import '../../faculty/services/supabase_client.dart';
import '../../faculty/services/profile_service.dart';

class AttendanceMonitoringView extends StatefulWidget {
  const AttendanceMonitoringView({super.key});

  @override
  State<AttendanceMonitoringView> createState() => _AttendanceMonitoringViewState();
}

class _AttendanceMonitoringViewState extends State<AttendanceMonitoringView> {
  int _activeTab = 0; // 0: Department Attendance, 1: My Class Attendance
  String _selectedSubject = '';
  DateTime _selectedDate = DateTime.now();
  List<String> _subjectsList = [];

  // Directory search query
  final TextEditingController _searchCtrl = TextEditingController();

  // Active student roster data for Take Attendance
  late List<Map<String, dynamic>> _rosterData;
  List<Map<String, dynamic>> _dbDirectoryData = [];
  List<Map<String, dynamic>> _dbDefaultersList = [];
  int _totalCSECount = 0;
  int _presentTodayCount = 0;
  int _absentTodayCount = 0;
  int _lowAttendanceCount = 0;
  bool _isLoading = true;
  bool _isAttendanceSubmitted = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _rosterData = [];
    _searchCtrl.addListener(() {
      if (mounted) setState(() {});
    });
    _fetchSupabaseAttendance();
  }

  Future<void> _fetchSupabaseAttendance() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    try {
      // Fetch dynamic subjects/timetable for the logged-in HOD
      final currentProfile = ProfileService.get();
      final String localEmpId = (currentProfile['employeeId'] ?? currentProfile['facultyId'] ?? 'EMP-CSE-010').toString().trim();
      
      // 1. Fetch faculties to resolve active department code
      final facultyRows = await SupabaseClientHelper.select('faculties', schema: 'faculty');
      final publicFacRows = await SupabaseClientHelper.select('faculties', schema: 'public');
      final allRows = [...facultyRows, ...publicFacRows];
      
      // Helper to always get short dept code like 'CSE' from any format
      String extractShortDeptCode(String raw) {
        final knownCodes = ['CSE', 'IT', 'ECE', 'EEE', 'MECH', 'CIVIL', 'IOT', 'AIDS', 'MBA', 'MCA'];
        final upper = raw.trim().toUpperCase();
        if (knownCodes.contains(upper)) return upper;
        // Extract from parentheses e.g. "Computer Science & Engineering (CSE)"
        final parenMatch = RegExp(r'\(([A-Z]{2,6})\)').firstMatch(raw);
        if (parenMatch != null) return parenMatch.group(1)!.toUpperCase();
        final clean = upper.replaceAll('DEPT_', '').replaceAll('DEP-', '').split('-').first.split('_').first;
        if (knownCodes.contains(clean)) return clean;
        return 'CSE';
      }

      String employeeIdVal = localEmpId;
      // Start with profile departmentId (already short like 'CSE')
      String hodDept = extractShortDeptCode(
        currentProfile['departmentId']?.toString() ?? currentProfile['department']?.toString() ?? 'CSE'
      );

      final match = allRows.firstWhere(
        (r) {
          final dbEmpId = r['employee_id']?.toString() ?? '';
          final sameId = dbEmpId.toUpperCase() == localEmpId.toUpperCase();
          final name = (currentProfile['name'] ?? '').toString().toLowerCase();
          final dbName = (r['full_name'] ?? r['name'] ?? '').toString().toLowerCase();
          final sameName = name.isNotEmpty && dbName.isNotEmpty && (dbName.contains(name) || name.contains(dbName));
          final role = r['role']?.toString().toUpperCase() ?? '';
          final isHod = role.contains('HOD') || r['designation']?.toString().toUpperCase().contains('HOD') == true;
          return sameId || (sameName && isHod);
        },
        orElse: () => <String, dynamic>{},
      );
      if (match.isNotEmpty) {
        employeeIdVal = match['employee_id']?.toString() ?? employeeIdVal;
        // Extract short code from DB dept name too
        final rawDbDept = match['department']?.toString() ?? match['dept']?.toString() ?? '';
        if (rawDbDept.isNotEmpty) {
          hodDept = extractShortDeptCode(rawDbDept);
        }
      }
      debugPrint('HOD dept resolved in attendance: $hodDept, employeeId: $employeeIdVal');
      
      final allocs = await SupabaseClientHelper.select(
        'faculty_course_allocations',
        schema: 'faculty',
        filterColumn: 'faculty_employee_id',
        filterValue: employeeIdVal,
      );
      final List<String> hodAllocatedCodes = allocs.map((a) => (a['course_code']?.toString() ?? '').trim().toUpperCase()).where((c) => c.isNotEmpty).toList();
      
      final subjectsData = await SupabaseClientHelper.select('subjects', schema: 'admin');
      final Map<String, String> subjectMap = {};
      for (final s in subjectsData) {
        final code = s['code']?.toString() ?? '';
        final title = s['title']?.toString() ?? '';
        if (code.isNotEmpty && title.isNotEmpty) {
          subjectMap[code] = title;
        }
      }
      
      // Let's resolve the current day of the week name (e.g. Saturday)
      final List<String> weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      final String activeDay = weekdays[_selectedDate.weekday - 1];
      
      // Query class timetables from the timetable schema
      final timetableRows = await SupabaseClientHelper.select(
        'class_timetables',
        schema: 'timetable',
        filterColumn: 'day',
        filterValue: activeDay,
      );

      final List<String> resolvedSubjects = [];
      for (final row in timetableRows) {
        final status = (row['status'] ?? '').toString().trim().toLowerCase();
        if (status != 'confirmed') continue;

        final rowDept = (row['department_code'] ?? '').toString().trim().toUpperCase();
        if (rowDept != hodDept.toUpperCase()) continue;
        
        final year = (row['year'] ?? '').toString();
        final section = (row['section'] ?? '').toString();
        
        // Scan periods p1 through p8 to check if any matches HOD's allocated subjects
        for (int p = 1; p <= 8; p++) {
          final code = (row['p${p}_code'] ?? '').toString().trim().toUpperCase();
          if (code.isNotEmpty && hodAllocatedCodes.contains(code)) {
            final title = subjectMap[code] ?? row['p${p}_name']?.toString() ?? 'Course $code';
            
            // Format: "2nd Period - Data Warehousing and Data Mining - III - A"
            String suffix = 'th';
            if (p == 1) suffix = 'st';
            else if (p == 2) suffix = 'nd';
            else if (p == 3) suffix = 'rd';
            
            final entry = '$p$suffix Period - $title - $year - $section';
            if (!resolvedSubjects.contains(entry)) {
              resolvedSubjects.add(entry);
            }
          }
        }
      }
      


      // Fetch attendance logs strictly from 'attendance_table' (student / public schema)
      var attendanceRows = await SupabaseClientHelper.select(
        'attendance_table',
        schema: 'student',
      );
      if (attendanceRows.isEmpty) {
        attendanceRows = await SupabaseClientHelper.select(
          'attendance_table',
          schema: 'public',
        );
      }

      final cseRows = attendanceRows.where((r) {
        final d = r['dept']?.toString().toUpperCase() ?? '';
        return d == 'CSE' || d.contains('CSE');
      }).toList();

      final Map<String, Map<String, dynamic>> studentMap = {};

      // Seed student map strictly from attendance_table entries
      for (var r in cseRows) {
        final regNo = (r['reg_no']?.toString() ?? '').trim();
        if (regNo.isEmpty) continue;
        final name = (r['name']?.toString() ?? 'Student').trim();
        final sec = (r['section']?.toString() ?? 'A').trim();
        final rawYear = (r['year']?.toString() ?? '').trim();
        final year = rawYear.isNotEmpty
            ? (rawYear.contains('Year') ? rawYear : '$rawYear Year')
            : 'II Year';

        if (!studentMap.containsKey(regNo)) {
          studentMap[regNo] = {
            'regNo': regNo,
            'rollNo': regNo,
            'name': name,
            'year': year,
            'section': sec,
            'dept': 'CSE',
            'dailyLogs': <Map<String, dynamic>>[],
          };
        }

        int pPresent = 0;
        int pTotal = 0;
        for (int i = 1; i <= 8; i++) {
          final val = r['p$i'];
          if (val != null) {
            pTotal++;
            if (val == true || val == 1 || val.toString() == 'true' ||
                val.toString().toUpperCase() == 'P' ||
                val.toString().toUpperCase() == 'OD' ||
                val.toString().toUpperCase() == 'ML') {
              pPresent++;
            }
          }
        }

        double? logPct = (r['attendance_percentage'] as num?)?.toDouble();
        if (logPct == null && pTotal > 0) {
          logPct = (pPresent / pTotal) * 100;
        }

        // Determine dominant status for this row (OD > ML > P > A)
        String rowStatus = 'A';
        bool anyOd = false;
        bool anyMl = false;
        bool anyP = false;
        for (int i = 1; i <= 8; i++) {
          final pv = r['p$i']?.toString().toUpperCase() ?? '';
          if (pv == 'OD') anyOd = true;
          if (pv == 'ML') anyMl = true;
          if (pv == 'P' || pv == 'TRUE') anyP = true;
        }
        if (anyOd) rowStatus = 'OD';
        else if (anyMl) rowStatus = 'ML';
        else if (anyP) rowStatus = 'P';

        (studentMap[regNo]!['dailyLogs'] as List<Map<String, dynamic>>).add({
          'date': r['date']?.toString() ?? '',
          'p1': r['p1'],
          'p2': r['p2'],
          'p3': r['p3'],
          'p4': r['p4'],
          'p5': r['p5'],
          'p6': r['p6'],
          'p7': r['p7'],
          'p8': r['p8'],
          'pPresent': pPresent,
          'pTotal': pTotal,
          'pct': logPct,
          'rowStatus': rowStatus,
        });
      }

      int index = 1;
      final directory = studentMap.values.map((s) {
        final dailyLogs = (s['dailyLogs'] as List<Map<String, dynamic>>);
        dailyLogs.sort((a, b) {
          final dA = a['date']?.toString() ?? '';
          final dB = b['date']?.toString() ?? '';
          return dB.compareTo(dA);
        });

        int totalPresentPeriods = 0;
        int totalPeriodsCount = 0;
        double validPctSum = 0;
        int validPctCount = 0;

        for (final log in dailyLogs) {
          final pTot = (log['pTotal'] as int?) ?? 0;
          final pPres = (log['pPresent'] as int?) ?? 0;
          if (pTot > 0) {
            totalPresentPeriods += pPres;
            totalPeriodsCount += pTot;
          }
          final logPct = log['pct'] as double?;
          if (logPct != null) {
            validPctSum += logPct;
            validPctCount++;
          }
        }

        double finalPct = 100.0;
        if (totalPeriodsCount > 0) {
          finalPct = (totalPresentPeriods / totalPeriodsCount) * 100;
        } else if (validPctCount > 0) {
          finalPct = validPctSum / validPctCount;
        }

        final pctDouble = double.parse(finalPct.toStringAsFixed(1));

        Color badgeColor = const Color(0xFF10B981);
        if (pctDouble < 75.0) {
          badgeColor = const Color(0xFFEF4444);
        } else if (pctDouble < 85.0) {
          badgeColor = const Color(0xFFF97316);
        }

        return {
          'sNo': index++,
          'regNo': s['regNo'],
          'rollNo': s['rollNo'],
          'name': s['name'],
          'year': s['year'],
          'section': s['section'],
          'dept': s['dept'],
          'pct': pctDouble,
          'color': badgeColor,
          'dailyLogs': dailyLogs,
        };
      }).toList();

      int sNo = 1;
      final targetDateStr = _selectedDate.toIso8601String().split('T')[0];
      
      // Determine active period key from selectedSubject
      String activePeriodKey = 'p1';
      if (_selectedSubject.isNotEmpty && _selectedSubject.contains('Period')) {
        final parts = _selectedSubject.split(' - ');
        if (parts.isNotEmpty) {
          final periodStr = parts[0].trim().toLowerCase();
          if (periodStr.contains('1')) activePeriodKey = 'p1';
          else if (periodStr.contains('2')) activePeriodKey = 'p2';
          else if (periodStr.contains('3')) activePeriodKey = 'p3';
          else if (periodStr.contains('4')) activePeriodKey = 'p4';
          else if (periodStr.contains('5')) activePeriodKey = 'p5';
          else if (periodStr.contains('6')) activePeriodKey = 'p6';
          else if (periodStr.contains('7')) activePeriodKey = 'p7';
          else if (periodStr.contains('8')) activePeriodKey = 'p8';
        }
      }

      // Check if attendance already exists for this date and department
      bool hasSubmittedAttendance = false;

      final roster = directory.map((s) {
        final logs = (s['dailyLogs'] as List<Map<String, dynamic>>);
        final matchLog = logs.firstWhere(
          (l) => l['date']?.toString() == targetDateStr,
          orElse: () => <String, dynamic>{},
        );
        String status;
        if (matchLog.isNotEmpty) {
          // If we found a record for this date, load the specific period status (e.g. p1, p2, etc.)
          final specificPeriodVal = matchLog[activePeriodKey]?.toString().trim().toUpperCase() ?? '';
          if (specificPeriodVal.isNotEmpty && specificPeriodVal != 'NULL') {
            status = specificPeriodVal;
            hasSubmittedAttendance = true; // Mark as submitted since at least one student has a value for this period
          } else {
            status = (s['pct'] as double) < 75.0 ? 'A' : 'P';
          }
        } else {
          status = (s['pct'] as double) < 75.0 ? 'A' : 'P';
        }
        return {
          'sNo': sNo++,
          'rollNo': s['regNo'],
          'name': s['name'],
          'status': status,
        };
      }).toList();

      final defaulters = directory.where((s) => (s['pct'] as double) < 75.0).map((s) {
        return {
          'name': s['name'],
          'regNo': s['regNo'],
          'pct': '${s['pct']}%',
          'class': '${s['year']} - Sec ${s['section']}',
          'status': 'Warning Issued',
          'color': Colors.red,
        };
      }).toList();

      int presentCount = directory.where((s) => (s['pct'] as double) >= 75.0).length;
      int absentCount = directory.length - presentCount;

      if (mounted) {
        setState(() {
          _dbDirectoryData = directory;
          _rosterData = roster;
          _dbDefaultersList = defaulters;
          _totalCSECount = directory.length;
          _presentTodayCount = presentCount;
          _absentTodayCount = absentCount;
          _lowAttendanceCount = defaulters.length;
          _subjectsList = resolvedSubjects.toSet().toList();
          if (!_subjectsList.contains(_selectedSubject) && _subjectsList.isNotEmpty) {
            _selectedSubject = _subjectsList.first;
          }
          _isAttendanceSubmitted = hasSubmittedAttendance;
          if (!hasSubmittedAttendance) {
            _isEditMode = false; // Reset edit mode if attendance not recorded yet
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching attendance_table from Supabase: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submitAttendanceToSupabase() async {
    // Show confirmation dialog before submitting or resubmitting
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Icon(
                _isAttendanceSubmitted ? Icons.edit_note_rounded : Icons.help_outline_rounded,
                color: const Color(0xFF2563EB),
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                _isAttendanceSubmitted ? 'Confirm Update' : 'Confirm Submission',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: Text(
            _isAttendanceSubmitted
                ? 'Are you sure you want to update the attendance records for the selected period?'
                : 'Are you sure you want to submit the student attendance roster for database logging?',
            style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Confirm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    if (mounted) setState(() => _isLoading = true);
    try {
      final dateStr = _selectedDate.toIso8601String().split('T')[0];
      
      // Resolve period key (p1-p8), year, section from the active dropdown subject selection:
      // Format: "Xth Period - Subject Title - Year - Section" (e.g. "2nd Period - Principles of Compiler Design - III - A")
      String targetPeriod = 'p1';
      String targetYear = 'III Year';
      String targetSection = 'A';
      
      if (_selectedSubject.isNotEmpty && _selectedSubject.contains('Period')) {
        final parts = _selectedSubject.split(' - ');
        if (parts.isNotEmpty) {
          final periodStr = parts[0].trim().toLowerCase(); // e.g. "2nd period"
          if (periodStr.contains('1')) targetPeriod = 'p1';
          else if (periodStr.contains('2')) targetPeriod = 'p2';
          else if (periodStr.contains('3')) targetPeriod = 'p3';
          else if (periodStr.contains('4')) targetPeriod = 'p4';
          else if (periodStr.contains('5')) targetPeriod = 'p5';
          else if (periodStr.contains('6')) targetPeriod = 'p6';
          else if (periodStr.contains('7')) targetPeriod = 'p7';
          else if (periodStr.contains('8')) targetPeriod = 'p8';
        }
        if (parts.length >= 3) {
          final yr = parts[2].trim();
          targetYear = yr.contains('Year') ? yr : '$yr Year';
        }
        if (parts.length >= 4) {
          targetSection = parts[3].trim();
        }
      }

      for (var item in _rosterData) {
        final regNo = item['rollNo']?.toString() ?? '';
        final name = item['name']?.toString() ?? '';
        final status = item['status']?.toString() ?? 'P';
        
        final payload = <String, dynamic>{
          'date': dateStr,
          'reg_no': regNo,
          'name': name,
          'dept': 'CSE',
          'section': targetSection,
          'year': targetYear,
          'updated_at': DateTime.now().toIso8601String(),
        };
        payload[targetPeriod] = status;

        // Upsert into student schema attendance_table
        await SupabaseClientHelper.upsert(
          'attendance_table',
          payload,
          'reg_no,date',
          schema: 'student',
        );
      }
      
      if (mounted) {
        HodToast.show(
          context,
          message: _isAttendanceSubmitted
              ? 'Class attendance successfully updated!'
              : 'Class attendance successfully saved to database!',
          isSuccess: true,
        );
      }
      
      setState(() {
        _isEditMode = false;
      });
      await _fetchSupabaseAttendance();
    } catch (e) {
      debugPrint('Error submitting HOD attendance: $e');
      if (mounted) {
        HodToast.show(context, message: 'Failed to save attendance: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // Format date helper
  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // Date picker selection
  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isAfter(now) ? now : _selectedDate,
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      if (context.mounted) {
        HodToast.show(context, message: 'Date updated to: ${_formatDate(picked)}');
      }
      _fetchSupabaseAttendance();
    }
  }

  // Actions for All Present / All Absent
  void _setAllAttendance(String status) {
    setState(() {
      for (var student in _rosterData) {
        student['status'] = status;
      }
    });
    HodToast.show(
      context,
      message: status == 'P' ? 'All students marked Present.' : 'All students marked Absent.',
      isSuccess: status == 'P',
      isError: status == 'A',
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── TOP HEADER BLOCK ──
          HodSectionHeader(
            title: 'Attendance Monitoring',
            breadcrumb: 'Academic Management > Attendance Monitoring > ${_activeTab == 0 ? "Department Attendance" : "My Class Attendance"}',
            academicYear: 'Academic Year 2025 - 2026',
            actions: [
              IconButton(
                tooltip: 'Sync with Database',
                icon: const Icon(Icons.refresh_rounded, color: Color(0xFF2563EB)),
                onPressed: () {
                  _fetchSupabaseAttendance();
                  HodToast.show(context, message: 'Syncing live attendance data from database...');
                },
              ),
              const SizedBox(width: 8),
              HodExportDialog.buildExportButton(
                context,
                onPressed: () => HodExportDialog.show(
                  context,
                  title: 'Export Attendance Data',
                  subtitle: 'Select export format for Attendance records:',
                  moduleName: 'Attendance',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── SECONDARY TAB NAVIGATION ROW ──
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
            ),
            child: Row(
              children: [
                _buildCompactTab(
                  label: 'Department Attendance',
                  icon: Icons.corporate_fare_rounded,
                  isActive: _activeTab == 0,
                  onTap: () {
                    if (_activeTab != 0) {
                      setState(() => _activeTab = 0);
                      _fetchSupabaseAttendance();
                    }
                  },
                ),
                _buildCompactTab(
                  label: 'My Class Attendance',
                  icon: Icons.person_add_alt_1_rounded,
                  isActive: _activeTab == 1,
                  onTap: () {
                    if (_activeTab != 1) {
                      setState(() => _activeTab = 1);
                      _fetchSupabaseAttendance();
                    }
                  },
                ),
              ],
            ),
          ),
          if (_isLoading) ...[
            const SizedBox(height: 4),
            const LinearProgressIndicator(
              backgroundColor: Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
            ),
          ],
          const SizedBox(height: 12),

          // ── SUBMODULE VIEWS ──
          _activeTab == 0 ? _buildDepartmentAttendanceView() : _buildMyClassAttendanceView(),
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

  // ── VIEW 1: DEPARTMENT ATTENDANCE ──
  Widget _buildDepartmentAttendanceView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // KPI Cards Row
        LayoutBuilder(
          builder: (context, constraints) {
            final double width = constraints.maxWidth;
            int crossAxisCount = 6;
            if (width < 650) {
              crossAxisCount = 2;
            } else if (width < 1100) {
              crossAxisCount = 3;
            }

            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 110,
              children: [
                _buildKpiCard('Total Students', '$_totalCSECount', 'CSE Department', Icons.school_rounded, const Color(0xFF2563EB)),
                _buildKpiCard('Present Today', '$_presentTodayCount', '${_totalCSECount > 0 ? ((_presentTodayCount / _totalCSECount) * 100).toStringAsFixed(1) : 0}% Attendance', Icons.check_circle_rounded, const Color(0xFF10B981)),
                _buildKpiCard('Absent Today', '$_absentTodayCount', '${_totalCSECount > 0 ? ((_absentTodayCount / _totalCSECount) * 100).toStringAsFixed(1) : 0}% Absentees', Icons.cancel_rounded, const Color(0xFFEF4444)),
                _buildKpiCard('Faculty Attendance', '96.0%', '23/24 Present', Icons.badge_rounded, const Color(0xFF0D9488)),
                _buildKpiCard('Low Attendance Alert', '$_lowAttendanceCount', '< 75% Threshold', Icons.warning_rounded, const Color(0xFFF97316)),
                _buildKpiCard('Attendance Defaulters', '${_dbDefaultersList.isNotEmpty ? _dbDefaultersList.length : _lowAttendanceCount}', 'Requires Warning', Icons.report_problem_rounded, const Color(0xFF8B5CF6)),
              ],
            );
          },
        ),
        const SizedBox(height: 24),

        // Table Card
        Card(
          color: Colors.white,
          margin: EdgeInsets.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.school_rounded, color: Color(0xFF2563EB), size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Student Attendance Directory & Eligibility Status (CSE)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: _showDefaultersModal,
                      icon: const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.white),
                      label: Text(
                        'View Defaulter List (${_dbDefaultersList.isNotEmpty ? _dbDefaultersList.length : _lowAttendanceCount})',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Table Filter
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          style: const TextStyle(fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: 'Search by Student Name, Reg No, or Subject...',
                            prefixIcon: Icon(Icons.search, size: 16, color: Color(0xFF94A3B8)),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Horizontal scrollable DataTable
                LayoutBuilder(
                  builder: (context, constraints) {
                    final double minW = (constraints.maxWidth.isFinite && constraints.maxWidth > 900)
                        ? constraints.maxWidth
                        : 900.0;
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: minW,
                        child: Column(
                          children: [
                            // Header
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  topRight: Radius.circular(8),
                                ),
                              ),
                              child: Row(
                                children: const [
                                  Expanded(
                                    flex: 1,
                                    child: Text('S.No', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text('Reg No', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text('Student Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text('Year', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text('Section', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text('Attendance %', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text('View', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                                  ),
                                ],
                              ),
                            ),
                            // Rows
                            if (_dbDirectoryData.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(24.0),
                                child: Center(
                                  child: Text(
                                    'No attendance records found in database.',
                                    style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                                  ),
                                ),
                              )
                            else
                              ..._dbDirectoryData.where((d) {
                                final query = _searchCtrl.text.trim().toLowerCase();
                                if (query.isEmpty) return true;
                                return d['name'].toString().toLowerCase().contains(query) ||
                                    d['regNo'].toString().toLowerCase().contains(query) ||
                                    (d['year'] ?? '').toString().toLowerCase().contains(query);
                              }).map((d) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: const BoxDecoration(
                                    border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 1,
                                        child: Text('${d['sNo'] ?? 1}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text('${d['regNo'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E293B))),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Row(
                                          children: [
                                            const Icon(Icons.school_outlined, size: 14, color: Color(0xFF2563EB)),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                '${d['name'] ?? ''}',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text('${d['year'] ?? 'II Year'}', style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Text('${d['section'] ?? 'A'}', style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SizedBox(
                                              width: 42,
                                              child: Text(
                                                '${d['pct']}%',
                                                style: TextStyle(
                                                  color: d['color'] ?? const Color(0xFF10B981),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            SizedBox(
                                              width: 75,
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(4),
                                                child: LinearProgressIndicator(
                                                  value: ((d['pct'] as num?)?.toDouble() ?? 100.0) / 100,
                                                  backgroundColor: const Color(0xFFE2E8F0),
                                                  valueColor: AlwaysStoppedAnimation<Color>(d['color'] ?? const Color(0xFF10B981)),
                                                  minHeight: 6,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: ElevatedButton.icon(
                                            onPressed: () => _showDailyAttendanceModal(context, d),
                                            icon: const Icon(Icons.calendar_month_outlined, size: 13, color: Colors.white),
                                            label: const Text(
                                              'View Daily Attendance',
                                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF2563EB),
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              minimumSize: Size.zero,
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                              elevation: 0,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── VIEW 2: MY CLASS ATTENDANCE ──
  Widget _buildMyClassAttendanceView() {
    // Math statistics calculated dynamically
    final int total = _rosterData.length;
    final int present = _rosterData.where((s) => s['status'] == 'P').length;
    final int absent = _rosterData.where((s) => s['status'] == 'A').length;
    final int od = _rosterData.where((s) => s['status'] == 'OD').length;
    final int ml = _rosterData.where((s) => s['status'] == 'ML').length;
    final double presentRate = total > 0 ? (present / total) * 100 : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selection Parameters Card
        Card(
          color: Colors.white,
          margin: EdgeInsets.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Attendance Selection Parameters',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 600;
                    return Row(
                      children: [
                        // Subject Selector
                        Expanded(
                          flex: isNarrow ? 1 : 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Select Subject',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _subjectsList.contains(_selectedSubject)
                                        ? _selectedSubject
                                        : (_subjectsList.isNotEmpty ? _subjectsList.first : null),
                                    isExpanded: true,
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
                                    items: _subjectsList.map((sub) => DropdownMenuItem(value: sub, child: Text(sub))).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() {
                                          _selectedSubject = val;
                                        });
                                        HodToast.show(context, message: 'Active Subject: $val');
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Date Selector
                        Expanded(
                          flex: isNarrow ? 1 : 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Select Date',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () => _selectDate(context),
                                child: Container(
                                  height: 48,
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatDate(_selectedDate),
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                      ),
                                      const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF64748B)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),

                        // View Daily Attendance Button placed next to filters
                        Padding(
                          padding: const EdgeInsets.only(top: 18.0),
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: () => _showSubjectSelectionDialog(),
                              icon: const Icon(Icons.grid_on_rounded, size: 16, color: Colors.white),
                              label: const Text(
                                'View Daily Attendance',
                                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F172A), // Dark navy style
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Two-Column Layout (Roster and Summary)
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 992;

            final Widget rosterColumn = Card(
              color: Colors.white,
              margin: EdgeInsets.zero,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Student Roster',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        // Only show bulk action tools if we are editing or taking attendance for the first time
                        if (!_isAttendanceSubmitted || _isEditMode)
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: () => _setAllAttendance('P'),
                              icon: const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF10B981)),
                              label: const Text(
                                'All Present',
                                style: TextStyle(color: Color(0xFF10B981), fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () => _setAllAttendance('A'),
                              icon: const Icon(Icons.cancel_rounded, size: 14, color: Color(0xFFEF4444)),
                              label: const Text(
                                'All Absent',
                                style: TextStyle(color: Color(0xFFEF4444), fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Roster Table
                    // Full Width Roster Table
                    Column(
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8),
                            ),
                          ),
                          child: Row(
                            children: const [
                              SizedBox(
                                width: 50,
                                child: Text('S.No', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A))),
                              ),
                              SizedBox(
                                width: 90,
                                child: Text('Roll No', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A))),
                              ),
                              Expanded(
                                child: Text('Student Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A))),
                              ),
                              SizedBox(
                                width: 170,
                                child: Text('Attendance Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A))),
                              ),
                            ],
                          ),
                        ),
                        // Rows
                        if (_rosterData.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Center(
                              child: Text(
                                'No student roster records found in database.',
                                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                              ),
                            ),
                          )
                        else
                          ..._rosterData.map((s) {
                          final currentStatus = s['status'];
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: const BoxDecoration(
                              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 50,
                                  child: Text(s['sNo'].toString(), style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                ),
                                SizedBox(
                                  width: 90,
                                  child: Text(s['rollNo'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                                ),
                                Expanded(
                                  child: Text(s['name'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                                ),
                                SizedBox(
                                  width: 170,
                                  child: Row(
                                    children: [
                                      _buildStatusToggleButton(
                                        'P',
                                        currentStatus == 'P',
                                        const Color(0xFF10B981),
                                        (_isAttendanceSubmitted && !_isEditMode)
                                            ? null
                                            : () {
                                                setState(() {
                                                  s['status'] = 'P';
                                                });
                                              },
                                      ),
                                      const SizedBox(width: 6),
                                      _buildStatusToggleButton(
                                        'A',
                                        currentStatus == 'A',
                                        const Color(0xFFEF4444),
                                        (_isAttendanceSubmitted && !_isEditMode)
                                            ? null
                                            : () {
                                                setState(() {
                                                  s['status'] = 'A';
                                                });
                                              },
                                      ),
                                      const SizedBox(width: 6),
                                      _buildStatusToggleButton(
                                        'OD',
                                        currentStatus == 'OD',
                                        const Color(0xFF3B82F6),
                                        (_isAttendanceSubmitted && !_isEditMode)
                                            ? null
                                            : () {
                                                setState(() {
                                                  s['status'] = 'OD';
                                                });
                                              },
                                      ),
                                      const SizedBox(width: 6),
                                      _buildStatusToggleButton(
                                        'ML',
                                        currentStatus == 'ML',
                                        const Color(0xFF8B5CF6),
                                        (_isAttendanceSubmitted && !_isEditMode)
                                            ? null
                                            : () {
                                                setState(() {
                                                  s['status'] = 'ML';
                                                });
                                              },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),
            );

            final Widget summaryColumn = Column(
              children: [
                Card(
                  color: Colors.white,
                  margin: EdgeInsets.zero,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Attendance Summary',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Circular Gauge Progress
                        _buildCircularProgressGauge(presentRate),
                        const SizedBox(height: 24),

                        // Detailed stats
                        _buildSummaryStatRow('Total Strength', total.toString(), const Color(0xFF64748B)),
                        const Divider(height: 12, color: Color(0xFFF1F5F9)),
                        _buildSummaryStatRow('Present Count', present.toString(), const Color(0xFF10B981)),
                        const Divider(height: 12, color: Color(0xFFF1F5F9)),
                        _buildSummaryStatRow('Absent Count', absent.toString(), const Color(0xFFEF4444)),
                        const Divider(height: 12, color: Color(0xFFF1F5F9)),
                        _buildSummaryStatRow('On Duty (OD)', od.toString(), const Color(0xFF3B82F6)),
                        const Divider(height: 12, color: Color(0xFFF1F5F9)),
                        _buildSummaryStatRow('Medical Leave (ML)', ml.toString(), const Color(0xFF8B5CF6)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Submit / Edit Action Button under summary card
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: _isAttendanceSubmitted && !_isEditMode
                      ? ElevatedButton.icon(
                          onPressed: () async {
                            final bool? confirmEdit = await showDialog<bool>(
                              context: context,
                              builder: (BuildContext ctx) {
                                return AlertDialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  title: const Row(
                                    children: [
                                      Icon(Icons.edit_rounded, color: Color(0xFFEAB308), size: 24),
                                      SizedBox(width: 10),
                                      Text('Edit Attendance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    ],
                                  ),
                                  content: const Text(
                                    'Would you like to unlock the roster to edit and resubmit attendance entries?',
                                    style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFEAB308),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: const Text('Edit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (confirmEdit == true) {
                              setState(() {
                                _isEditMode = true;
                              });
                            }
                          },
                          icon: const Icon(Icons.edit_rounded, size: 18, color: Colors.white),
                          label: const Text(
                            'Edit Attendance',
                            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEAB308), // Yellow/Orange button for edit Mode
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: () => _submitAttendanceToSupabase(),
                          icon: const Icon(Icons.cloud_upload_rounded, size: 18, color: Colors.white),
                          label: Text(
                            _isEditMode ? 'Resubmit Attendance' : 'Submit Attendance',
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                        ),
                ),
              ],
            );

            if (isNarrow) {
              return Column(
                children: [
                  rosterColumn,
                  const SizedBox(height: 20),
                  summaryColumn,
                ],
              );
            } else {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: rosterColumn),
                  const SizedBox(width: 20),
                  Expanded(flex: 2, child: summaryColumn),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  // Segment status toggle buttons
  Widget _buildStatusToggleButton(String label, bool isSelected, Color color, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 34,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Circular Gauge Widget
  Widget _buildCircularProgressGauge(double percentage) {
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: CircularProgressIndicator(
              value: percentage / 100,
              strokeWidth: 9,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Present Rate',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper row in summary
  Widget _buildSummaryStatRow(String label, String value, Color dotColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF475569),
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  // Dialog: Daily Attendance Details (Sorted Date-wise)
  void _showDailyAttendanceModal(BuildContext context, Map<String, dynamic> student) {
    bool isAscending = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final List<Map<String, dynamic>> rawLogs = List<Map<String, dynamic>>.from(
              (student['dailyLogs'] as List<dynamic>?) ?? [
                {
                  'date': '2026-08-06',
                  'p1': true,
                  'p2': true,
                  'p3': true,
                  'p4': true,
                  'p5': true,
                  'p6': true,
                  'p7': true,
                  'p8': true,
                  'pct': student['pct'] ?? 100.0,
                }
              ]
            );

            // Sort logs date-wise
            rawLogs.sort((a, b) {
              final dA = a['date']?.toString() ?? '';
              final dB = b['date']?.toString() ?? '';
              return isAscending ? dA.compareTo(dB) : dB.compareTo(dA);
            });

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.event_note_rounded, color: Color(0xFF2563EB), size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Daily Attendance History',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          'Student: ${student['name']} (${student['regNo']}) • ${student['year']} Sec ${student['section']}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.normal),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      setModalState(() {
                        isAscending = !isAscending;
                      });
                    },
                    icon: Icon(
                      isAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                      size: 14,
                      color: const Color(0xFF2563EB),
                    ),
                    label: Text(
                      isAscending ? 'Date: Oldest First' : 'Date: Latest First',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF93C5FD)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 720,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFDBEAFE)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Cumulative Attendance: ${student['pct']}%',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: ((student['pct'] as num?)?.toDouble() ?? 100.0) < 75 ? Colors.red : Colors.green[800],
                              ),
                            ),
                            Text(
                              'Sorted: ${isAscending ? "Oldest → Newest" : "Newest → Oldest"} (${rawLogs.length} Logged Days)',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF1E40AF), fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          sortColumnIndex: 0,
                          sortAscending: isAscending,
                          headingRowHeight: 40,
                          dataRowHeight: 42,
                          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                          columns: [
                            DataColumn(
                              label: Row(
                                children: [
                                  const Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  const SizedBox(width: 4),
                                  Icon(
                                    isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                                    size: 14,
                                    color: const Color(0xFF2563EB),
                                  ),
                                ],
                              ),
                              onSort: (columnIndex, ascending) {
                                setModalState(() {
                                  isAscending = ascending;
                                });
                              },
                            ),
                            const DataColumn(label: Text('P1', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            const DataColumn(label: Text('P2', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            const DataColumn(label: Text('P3', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            const DataColumn(label: Text('P4', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            const DataColumn(label: Text('P5', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            const DataColumn(label: Text('P6', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            const DataColumn(label: Text('P7', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            const DataColumn(label: Text('P8', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            const DataColumn(label: Text('Status %', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          ],
                          rows: rawLogs.map((log) {
                            Widget buildPBadge(dynamic val) {
                              if (val == null) {
                                return const Text('-', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)));
                              }
                              final raw = val.toString().trim().toUpperCase();
                              final String label;
                              final Color bg;
                              final Color fg;
                              if (raw == 'P' || val == true || raw == 'TRUE') {
                                label = 'P'; bg = const Color(0xFFDCFCE7); fg = const Color(0xFF15803D);
                              } else if (raw == 'A' || val == false || raw == 'FALSE') {
                                label = 'A'; bg = const Color(0xFFFEE2E2); fg = const Color(0xFFB91C1C);
                              } else if (raw == 'OD') {
                                label = 'OD'; bg = const Color(0xFFDBEAFE); fg = const Color(0xFF1D4ED8);
                              } else if (raw == 'ML') {
                                label = 'ML'; bg = const Color(0xFFEDE9FE); fg = const Color(0xFF7C3AED);
                              } else {
                                label = raw.isEmpty ? '-' : raw;
                                bg = const Color(0xFFF1F5F9); fg = const Color(0xFF64748B);
                              }
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: bg,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  label,
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
                                ),
                              );
                            }

                            final pct = (log['pct'] as num?)?.toDouble() ?? 100.0;

                            return DataRow(
                              cells: [
                                DataCell(Text(log['date']?.toString() ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                                DataCell(buildPBadge(log['p1'])),
                                DataCell(buildPBadge(log['p2'])),
                                DataCell(buildPBadge(log['p3'])),
                                DataCell(buildPBadge(log['p4'])),
                                DataCell(buildPBadge(log['p5'])),
                                DataCell(buildPBadge(log['p6'])),
                                DataCell(buildPBadge(log['p7'])),
                                DataCell(buildPBadge(log['p8'])),
                                DataCell(Text('${pct.toStringAsFixed(1)}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: pct >= 75 ? Colors.green : Colors.red))),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatPeriodName(String pKey) {
    final numStr = pKey.replaceAll('p', '');
    final pNum = int.tryParse(numStr) ?? 1;
    String suffix = 'th';
    if (pNum == 1) suffix = 'st';
    else if (pNum == 2) suffix = 'nd';
    else if (pNum == 3) suffix = 'rd';
    return '$pNum$suffix per';
  }

  String _formatDateWithPeriod(String dateStr, String pKey) {
    final parts = dateStr.split('-');
    if (parts.length == 3) {
      final formattedDate = '${parts[2]}/${parts[1]}/${parts[0]}';
      return '$formattedDate(${_formatPeriodName(pKey)})';
    }
    return '$dateStr(${_formatPeriodName(pKey)})';
  }

  void _showSubjectSelectionDialog() {
    String tempSelected = _selectedSubject.isNotEmpty 
        ? _selectedSubject 
        : (_subjectsList.isNotEmpty ? _subjectsList.first : '');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select Subject', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Please select a subject to view daily attendance:',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: tempSelected.isNotEmpty && _subjectsList.contains(tempSelected) ? tempSelected : null,
                        isExpanded: true,
                        items: _subjectsList.map((sub) => DropdownMenuItem(value: sub, child: Text(sub))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              tempSelected = val;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedSubject = tempSelected;
                    });
                    Navigator.pop(context);
                    _showDailyClassAttendanceGridModal();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: const Text('View Attendance', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Dialog: Daily Class Attendance Grid View (Multi-day horizontal grid logs)
  void _showDailyClassAttendanceGridModal() {
    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: SupabaseClientHelper.select('class_timetables', schema: 'timetable'),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final timetables = snapshot.data ?? [];

            // Resolve target period and class section from the active dropdown subject selection
            String targetPeriod = 'p1';
            String targetYear = 'III Year';
            String targetSection = 'A';
            String subjectTitle = '';
            
            if (_selectedSubject.isNotEmpty) {
              final parts = _selectedSubject.split(' - ');
              if (parts.isNotEmpty) {
                final periodStr = parts[0].trim().toLowerCase();
                if (periodStr.contains('1')) targetPeriod = 'p1';
                else if (periodStr.contains('2')) targetPeriod = 'p2';
                else if (periodStr.contains('3')) targetPeriod = 'p3';
                else if (periodStr.contains('4')) targetPeriod = 'p4';
                else if (periodStr.contains('5')) targetPeriod = 'p5';
                else if (periodStr.contains('6')) targetPeriod = 'p6';
                else if (periodStr.contains('7')) targetPeriod = 'p7';
                else if (periodStr.contains('8')) targetPeriod = 'p8';
              }
              if (parts.length >= 2) {
                subjectTitle = parts[1].trim();
              }
              if (parts.length >= 3) {
                final yr = parts[2].trim();
                targetYear = yr.contains('Year') ? yr : '$yr Year';
              }
              if (parts.length >= 4) {
                targetSection = parts[3].trim();
              }
            }

            final List<String> weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
            final List<Map<String, dynamic>> columnsList = [];

            final today = DateTime.now();
            final List<String> pastDates = [];
            for (int i = 0; i < 5; i++) {
              final d = today.subtract(Duration(days: i));
              pastDates.add(d.toIso8601String().split('T')[0]);
            }

            // For each of the past 5 dates, find which periods belong to the selected subject
            for (final dateStr in pastDates) {
              final dateObj = DateTime.parse(dateStr);
              final String dayName = weekdays[dateObj.weekday - 1];

              final matches = timetables.where((row) {
                final rowDept = (row['department_code'] ?? '').toString().trim().toUpperCase();
                final sameDept = rowDept == 'CSE' || rowDept.isEmpty; // CSE dept filter fallback
                
                final rowYear = (row['year'] ?? '').toString().trim();
                final yrClean = targetYear.replaceAll(' Year', '').trim();
                final sameYear = rowYear.contains(yrClean) || rowYear == yrClean;
                
                final sameSec = (row['section'] ?? '').toString().trim().toUpperCase() == targetSection.toUpperCase();
                final sameDay = (row['day'] ?? '').toString().trim().toUpperCase() == dayName.toUpperCase();
                
                return sameYear && sameSec && sameDay;
              }).toList();

              final List<String> activePeriods = [];
              for (final row in matches) {
                for (int p = 1; p <= 8; p++) {
                  final code = (row['p${p}_code'] ?? '').toString().trim().toUpperCase();
                  final name = (row['p${p}_name'] ?? '').toString().trim().toLowerCase();
                  final title = subjectTitle.toLowerCase();
                  if (code.isNotEmpty && (name.contains(title) || title.contains(name) || code.contains(title))) {
                    activePeriods.add('p$p');
                  }
                }
              }

              if (activePeriods.isEmpty) {
                activePeriods.add(targetPeriod);
              }

              // Sort periods (e.g. p4 then p6)
              activePeriods.sort();

              for (final p in activePeriods) {
                columnsList.add({
                  'date': dateStr,
                  'period': p,
                });
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.grid_on_rounded, color: Color(0xFF2563EB), size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Daily Attendance Grid View',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          'Class: $targetYear - Section $targetSection | Subject: $subjectTitle',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.normal),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 850,
                height: 480,
                child: _dbDirectoryData.isEmpty
                    ? const Center(
                        child: Text(
                          'No dynamic student directory profiles found.',
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowHeight: 44,
                            dataRowHeight: 46,
                            headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                            columns: [
                              const DataColumn(label: Text('S.No', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                              const DataColumn(label: Text('Student Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                              const DataColumn(label: Text('Class', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                              const DataColumn(label: Text('Con.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                              const DataColumn(label: Text('Att.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                              ...columnsList.map((col) {
                                return DataColumn(
                                  label: Text(
                                    _formatDateWithPeriod(col['date'], col['period']),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF1E3A8A)),
                                  ),
                                );
                              }),
                            ],
                            rows: _dbDirectoryData.map((s) {
                              final logs = List<Map<String, dynamic>>.from(s['dailyLogs'] ?? []);
                              
                              int conducted = 0;
                              int attended = 0;
                              
                              for (final log in logs) {
                                for (final col in columnsList) {
                                  if (col['date'] == log['date']) {
                                    final specificVal = log[col['period']]?.toString().trim().toUpperCase() ?? '';
                                    if (specificVal.isNotEmpty && specificVal != 'NULL') {
                                      conducted++;
                                      if (specificVal == 'P' || specificVal == 'OD' || specificVal == 'ML') {
                                        attended++;
                                      }
                                    }
                                  }
                                }
                              }

                              Widget buildGridBadge(String dateStr, String pKey) {
                                final matchLog = logs.firstWhere(
                                  (l) => l['date']?.toString() == dateStr,
                                  orElse: () => <String, dynamic>{},
                                );

                                if (matchLog.isEmpty) {
                                  return const Text('-', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)));
                                }

                                final val = matchLog[pKey]?.toString().trim().toUpperCase() ?? '';
                                if (val.isEmpty || val == 'NULL') {
                                  return const Text('-', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)));
                                }

                                final Color bg;
                                final Color fg;
                                if (val == 'P') {
                                  bg = const Color(0xFFDCFCE7); fg = const Color(0xFF15803D);
                                } else if (val == 'A') {
                                  bg = const Color(0xFFFEE2E2); fg = const Color(0xFFB91C1C);
                                } else if (val == 'OD') {
                                  bg = const Color(0xFFDBEAFE); fg = const Color(0xFF1D4ED8);
                                } else if (val == 'ML') {
                                  bg = const Color(0xFFEDE9FE); fg = const Color(0xFF7C3AED);
                                } else {
                                  bg = const Color(0xFFF1F5F9); fg = const Color(0xFF64748B);
                                }

                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: bg,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    val,
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg),
                                  ),
                                );
                              }

                              return DataRow(
                                cells: [
                                  DataCell(Text('${s['sNo']}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)))),
                                  DataCell(Text('${s['name']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)))),
                                  DataCell(Text('${s['year']} Sec ${s['section']}', style: const TextStyle(fontSize: 11, color: Color(0xFF475569)))),
                                  DataCell(Text('$conducted', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                  DataCell(Text('$attended', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: attended < (conducted * 0.75) ? Colors.red : Colors.green))),
                                  ...columnsList.map((col) => DataCell(Center(child: buildGridBadge(col['date'], col['period'])))),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Dialog: Defaulters List
  void _showDefaultersModal() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 24),
              SizedBox(width: 10),
              Text(
                'Attendance Defaulters (< 75%)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'The following students are currently below the required 75% attendance threshold for the academic term:',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  if (_dbDefaultersList.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No attendance defaulters found (< 75%).',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      ),
                    )
                  else
                    ..._dbDefaultersList.map((st) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFEE2E2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(st['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF991B1B))),
                              Text('${st['regNo']} • ${st['class']}', style: const TextStyle(fontSize: 11, color: Color(0xFFB91C1C))),
                            ],
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFFCA5A5)),
                                ),
                                child: Text(
                                  st['pct'],
                                  style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFEF4444), fontSize: 12),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                st['status'],
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB91C1C)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                HodToast.show(context, message: 'Warning notices dispatched to all 6 defaulters.', isSuccess: true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'Send Warning Notices',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
