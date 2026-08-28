import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../export_dialog_helper.dart';
import '../responsive.dart';
import '../hod_toast.dart';
import '../../faculty/services/supabase_client.dart';
import '../../faculty/services/profile_service.dart';
import '../../faculty/screens/premium_date_picker.dart';

class LeaveManagementView extends StatefulWidget {
  final bool openApplyModalOnLoad;
  final String? forceViewMode;
  const LeaveManagementView({
    super.key,
    this.openApplyModalOnLoad = false,
    this.forceViewMode,
  });

  @override
  State<LeaveManagementView> createState() => _LeaveManagementViewState();
}

class _LeaveManagementViewState extends State<LeaveManagementView> {
  final TextEditingController _searchCtrl = TextEditingController();

  String _selectedViewMode = 'Faculty Approvals'; // 'Faculty Approvals' or 'My Sent Requests'
  String _selectedFilter = 'All Leave Applications';
  String _selectedMonth = 'All Months';
  bool _isLoading = true;

  List<Map<String, dynamic>> _dbLeaveRequests = [];    // Faculty leave requests from faculty.leave_applications
  List<Map<String, dynamic>> _hodLeaveRequests = [];    // HOD's own leave requests from hod.hod_leave_requests
  List<Map<String, dynamic>> _facultiesList = [];
  List<Map<String, dynamic>> _dbLeaveBalances = [];
  String _currentHodEmpId = ''; // Real employee ID from Supabase (e.g. EMP-CSE-010)
  String _currentHodName = '';  // HOD's full name from Supabase
  String _currentHodUuid = '';  // HOD's UUID from Supabase

  final List<String> _months = [
    'All Months',
    'June 2026',
    'July 2026',
    'August 2026',
    'September 2026',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.forceViewMode != null) {
      _selectedViewMode = widget.forceViewMode!;
    } else if (widget.openApplyModalOnLoad) {
      _selectedViewMode = 'My Sent Requests';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openAddLeaveRequestModal(context);
      });
    }
    _fetchLeaveData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchLeaveData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Fetch faculties from faculty schema only for name/dept mapping
      final facRows = await SupabaseClientHelper.select('faculties', schema: 'faculty');

      final Map<String, String> fMap = {};      // empId -> name
      final Map<String, String> fDeptMap = {};  // empId -> dept code
      final List<Map<String, dynamic>> fList = [];
      final Set<String> seenEmpIds = {};

      for (final f in facRows) {
        final empId = f['employee_id']?.toString() ?? '';
        final name = f['full_name']?.toString() ?? f['name']?.toString() ?? '';
        final desig = f['designation']?.toString() ?? '';
        final deptRaw = f['department']?.toString() ?? f['code']?.toString() ?? '';
        if (empId.isNotEmpty && !seenEmpIds.contains(empId)) {
          seenEmpIds.add(empId);
          fMap[empId] = name.isNotEmpty ? name : empId;
          if (deptRaw.isNotEmpty) {
            fDeptMap[empId] = deptRaw.toUpperCase();
          }
          fList.add({
            'uuid': f['id']?.toString() ?? '',
            'empId': empId,
            'name': name.isNotEmpty ? name : empId,
            'designation': desig,
            'label': name.isNotEmpty ? (desig.isNotEmpty ? '$name ($desig)' : name) : empId,
          });
        }
      }

      // 2. Resolve HOD's employee_id and department
      final currentProfile = ProfileService.get();
      final String localName = (currentProfile['name'] ?? '').toString().trim().toLowerCase();
      final String localEmpId = (currentProfile['employeeId'] ?? currentProfile['facultyId'] ?? '').toString().trim();

      String curEmpId = '';
      String curName = currentProfile['name']?.toString() ?? 'Logged In HOD';
      String curDesig = currentProfile['designation']?.toString() ?? 'Professor & HOD';
      String hodDept = '';
      String curUuid = '';

      for (final f in facRows) {
        final dbEmpId = (f['employee_id'] ?? '').toString().trim();
        final dbName = (f['full_name'] ?? f['name'] ?? '').toString().trim().toLowerCase();
        final dbRole = (f['role'] ?? f['designation'] ?? '').toString().toLowerCase();
        final isHodRole = dbRole.contains('hod') || dbRole.contains('head of department');

        final sameId = localEmpId.isNotEmpty && dbEmpId.toUpperCase().replaceAll('-', '_') == localEmpId.toUpperCase().replaceAll('-', '_');
        final nameMatch = localName.isNotEmpty && dbName.isNotEmpty &&
            (dbName.contains(localName) || localName.contains(dbName));

        if (dbEmpId.isNotEmpty && (sameId || (nameMatch && isHodRole))) {
          curEmpId = dbEmpId;
          curUuid = f['id']?.toString() ?? '';
          curName = (f['full_name'] ?? f['name'] ?? curName).toString();
          curDesig = (f['designation'] ?? curDesig).toString();
          final deptRaw = f['department']?.toString() ?? f['code']?.toString() ?? '';
          // Extract abbreviation from parentheses if present: "Computer Science & Engineering (CSE)" → "CSE"
          final parenMatch = RegExp(r'\(([^)]+)\)').allMatches(deptRaw);
          hodDept = parenMatch.isNotEmpty
              ? parenMatch.last.group(1)!.toUpperCase().trim()
              : deptRaw.toUpperCase().trim();
          break;
        }
      }

      // Fallback: resolve dept from ProfileService if not found in DB
      if (hodDept.isEmpty) {
        final rawDept = currentProfile['departmentId'] ?? currentProfile['department'] ?? 'CSE';
        hodDept = rawDept.toString().replaceAll('DEPT_', '').replaceAll('DEP-', '').split('-').first.toUpperCase().trim();
      }

      // Pin HOD to top of faculty list
      if (curEmpId.isNotEmpty) {
        fList.removeWhere((f) => f['empId'] == curEmpId);
        fList.insert(0, {
          'uuid': curUuid,
          'empId': curEmpId,
          'name': curName,
          'designation': curDesig,
          'label': '$curName ($curDesig)',
        });
        fMap[curEmpId] = curName;
      }

      // 3. Fetch leave balances
      final balances = await SupabaseClientHelper.select('leave_balances', schema: 'faculty');

      // 4. Fetch faculty leave applications from faculty schema
      final leaveRows = await SupabaseClientHelper.select('leave_applications', schema: 'faculty');

      // 5. Fetch HOD's own leave requests strictly from hod schema
      List<Map<String, dynamic>> hodLeaveRows = [];
      try {
        hodLeaveRows = await SupabaseClientHelper.select('hod_leave_requests', schema: 'hod');
      } catch (e) {
        debugPrint('Error fetching hod_leave_requests: $e');
      }

      // 6. Parse faculty leave rows — filter to HOD's dept only (exclude HOD's own entries)
      final List<Map<String, dynamic>> facultyParsed = [];
      for (int i = 0; i < leaveRows.length; i++) {
        final r = leaveRows[i];
        final id = r['id']?.toString() ?? '';
        final empId = r['faculty_employee_id']?.toString() ?? '';
        final normalizedEmpId = empId.toUpperCase().replaceAll('-', '_');
        final normalizedCurId = curEmpId.toUpperCase().replaceAll('-', '_');
        final normalizedLocalId = localEmpId.toUpperCase().replaceAll('-', '_');

        // Skip HOD's own records in the faculty approvals tab
        final isMyOwnRequest = (curEmpId.isNotEmpty && normalizedEmpId == normalizedCurId) ||
                               (localEmpId.isNotEmpty && normalizedEmpId == normalizedLocalId);
        if (isMyOwnRequest) continue;

        // Department filter: only show records whose applicant is in HOD's dept
        // fDeptMap values may be short codes ("CSE", "IOT") — compare against hodDept directly
        final facultyDeptRaw = fDeptMap[empId] ?? '';
        // Also extract abbreviation from parentheses if present
        final facParenMatch = RegExp(r'\(([^)]+)\)').allMatches(facultyDeptRaw);
        final facultyDept = facParenMatch.isNotEmpty
            ? facParenMatch.last.group(1)!.toUpperCase().trim()
            : facultyDeptRaw.toUpperCase().trim();
        // Normalize for comparison (replace hyphens/underscores/spaces)
        String norm(String s) => s.replaceAll(RegExp(r'[-_ ]'), '');
        final isSameDept = norm(facultyDept) == norm(hodDept) || facultyDeptRaw.isEmpty || hodDept.isEmpty;
        if (!isSameDept) continue;

        final facultyName = fMap[empId] ?? empId;

        // Substitute parsing from substitutions_json array
        final subEmpId = r['substitute_faculty_id']?.toString() ?? r['alternate_faculty_id']?.toString() ?? '';
        String subName = 'None';
        final subsJson = r['substitutions_json'];
        if (subsJson is List && subsJson.isNotEmpty) {
          final names = <String>{};
          for (final s in subsJson) {
            if (s is Map) {
              final fName = s['substituteFaculty']?.toString() ?? s['substitute_faculty_name']?.toString() ?? '';
              if (fName.isNotEmpty && fName != 'None') {
                names.add(fName.split('(').first.trim());
              }
            }
          }
          if (names.isNotEmpty) subName = names.join(', ');
        }
        if (subName == 'None' && subEmpId.isNotEmpty) {
          subName = fMap[subEmpId] ?? subEmpId;
        }

        final startDate = r['start_date']?.toString() ?? '';
        final endDate = r['end_date']?.toString() ?? '';
        final totalDays = r['total_days'] != null ? '${r['total_days']} Day(s)' : '';
        String datesStr = startDate.isNotEmpty && endDate.isNotEmpty && startDate != endDate
            ? '$startDate to $endDate${totalDays.isNotEmpty ? " ($totalDays)" : ""}'
            : (startDate.isNotEmpty ? '$startDate${totalDays.isNotEmpty ? " ($totalDays)" : ""}' : '-');

        final rawStatus = (r['status']?.toString() ?? 'PENDING').toUpperCase();
        final String status;
        if (rawStatus.contains('APPROVED')) {
          status = 'APPROVED';
        } else if (rawStatus.contains('REJECTED')) {
          status = 'REJECTED';
        } else {
          status = 'PENDING';
        }

        final displayId = r['display_id']?.toString().isNotEmpty == true
            ? r['display_id'].toString()
            : 'LV-${DateTime.now().year}-${(i + 1).toString().padLeft(3, '0')}';

        facultyParsed.add({
          'id': id,
          'displayId': displayId,
          'faculty': facultyName.isNotEmpty ? facultyName : 'Unknown Faculty',
          'facultyEmpId': empId,
          'isHod': false,
          'appliedBy': empId,
          'leaveType': r['leave_type']?.toString() ?? 'Casual Leave',
          'dates': datesStr,
          'startDate': startDate,
          'endDate': endDate,
          'days': (r['total_days'] as num? ?? 1.0).toDouble(),
          'reason': r['reason']?.toString() ?? 'Personal Leave',
          'substitute': subName,
          'substituteEmpId': subEmpId,
          'status': status,
          'hodRemarks': r['hod_remarks']?.toString() ?? r['hod_comment']?.toString() ?? '',
          'createdAt': r['applied_date']?.toString() ?? r['updated_at']?.toString() ?? '',
          'substitutions': r['substitutions_json'] is List ? r['substitutions_json'] : [],
        });
      }
      facultyParsed.sort((a, b) => (b['startDate'] as String).compareTo(a['startDate'] as String));

      // 7. Parse HOD's own leave requests from hod.hod_leave_requests
      // Filter to the current HOD's records only (match by faculty_id or faculty_name)
      final List<Map<String, dynamic>> hodParsed = [];
      final curNameLower = curName.trim().toLowerCase();
      for (int i = 0; i < hodLeaveRows.length; i++) {
        final r = hodLeaveRows[i];
        final id = r['id']?.toString() ?? '';

        // Match by faculty_id (emp id) or faculty_name
        final rowFacultyId = (r['faculty_id'] ?? r['faculty_employee_id'] ?? '').toString().trim();
        final rowFacultyName = (r['faculty_name'] ?? '').toString().trim().toLowerCase();

        final idMatch = rowFacultyId.isNotEmpty && curEmpId.isNotEmpty &&
            rowFacultyId.toUpperCase().replaceAll('-', '_') == curEmpId.toUpperCase().replaceAll('-', '_');
        final nameMatch = rowFacultyName.isNotEmpty && curNameLower.isNotEmpty &&
            (rowFacultyName.contains(curNameLower) || curNameLower.contains(rowFacultyName));

        // Only include this HOD's own records; skip if no match at all
        if (!idMatch && !nameMatch && curEmpId.isNotEmpty) continue;

        final empId = rowFacultyId.isNotEmpty ? rowFacultyId : curEmpId;
        final facultyName = r['faculty_name']?.toString() ?? curName;

        final startDate = r['from_date']?.toString() ?? r['start_date']?.toString() ?? '';
        final endDate = r['to_date']?.toString() ?? r['end_date']?.toString() ?? '';
        // Calculate days if not stored
        int calcDays = 1;
        if (startDate.isNotEmpty && endDate.isNotEmpty) {
          try {
            final s = DateTime.parse(startDate);
            final e = DateTime.parse(endDate);
            calcDays = e.difference(s).inDays + 1;
          } catch (_) {}
        }
        final totalDays = (r['total_days'] as num?)?.toDouble() ?? calcDays.toDouble();

        String datesStr = r['dates']?.toString().isNotEmpty == true
            ? r['dates'].toString()
            : (startDate.isNotEmpty && endDate.isNotEmpty && startDate != endDate
                ? '$startDate to $endDate'
                : (startDate.isNotEmpty ? startDate : '-'));

        final rawStatus = (r['status']?.toString() ?? 'PENDING').trim().toUpperCase();
        final String status;
        if (rawStatus.contains('APPROVED')) {
          status = 'APPROVED';
        } else if (rawStatus.contains('REJECTED')) {
          status = 'REJECTED';
        } else {
          status = 'PENDING';
        }

        final displayId = r['display_id']?.toString().isNotEmpty == true
            ? r['display_id'].toString()
            : 'LR-${DateTime.now().year}-${(i + 1).toString().padLeft(3, '0')}';

        hodParsed.add({
          'id': id,
          'displayId': displayId,
          'faculty': facultyName,
          'facultyEmpId': empId,
          'isHod': true,
          'appliedBy': empId,
          'leaveType': r['leave_type']?.toString() ?? 'Casual Leave',
          'dates': datesStr,
          'startDate': startDate,
          'endDate': endDate,
          'days': totalDays,
          'reason': r['reason']?.toString() ?? 'Personal Leave',
          'substitute': r['substitute_faculty']?.toString() ?? 'None',
          'substituteEmpId': '',
          'status': status,
          'hodRemarks': r['hod_remarks']?.toString() ?? '',
          'createdAt': r['created_at']?.toString() ?? '',
          'substitutions': [],
        });
      }
      hodParsed.sort((a, b) => (b['startDate'] as String).compareTo(a['startDate'] as String));

      setState(() {
        _facultiesList = fList;
        _dbLeaveBalances = balances;
        _dbLeaveRequests = facultyParsed;   // Faculty Approvals tab
        _hodLeaveRequests = hodParsed;       // My Sent Requests tab
        _currentHodEmpId = curEmpId;
        _currentHodName = curName;
        _currentHodUuid = curUuid;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching leave data: $e');
      setState(() => _isLoading = false);
    }
  }


  Future<void> _updateDatabaseLeaveBalance({
    required String facultyEmpId,
    required String leaveType,
    required double days,
  }) async {
    if (facultyEmpId.isEmpty || days <= 0) return;

    try {
      final existing = await SupabaseClientHelper.select(
        'leave_balances',
        schema: 'faculty',
        filterColumn: 'faculty_employee_id',
        filterValue: facultyEmpId,
      );

      String columnToUpdate = 'casual_leave_used';
      final lTypeLower = leaveType.toLowerCase();

      if (lTypeLower.contains('casual')) {
        columnToUpdate = 'casual_leave_used';
      } else if (lTypeLower.contains('sick') || lTypeLower.contains('medical')) {
        columnToUpdate = 'medical_leave_used';
      } else if (lTypeLower.contains('earned')) {
        columnToUpdate = 'earned_leave_used';
      } else if (lTypeLower.contains('duty') || lTypeLower.contains('od')) {
        columnToUpdate = 'on_duty_used';
      }

      if (existing.isNotEmpty) {
        final record = existing.first;
        final currentUsed = (record[columnToUpdate] as num? ?? 0.0).toDouble();
        final newUsed = currentUsed + days;

        await SupabaseClientHelper.update(
          'leave_balances',
          {
            columnToUpdate: newUsed,
            'updated_at': DateTime.now().toIso8601String(),
          },
          'faculty_employee_id',
          facultyEmpId,
          schema: 'faculty',
        );
      } else {
        final newPayload = <String, dynamic>{
          'faculty_employee_id': facultyEmpId,
          'academic_year': '2025-26',
          'casual_leave_total': 12.0,
          'casual_leave_used': lTypeLower.contains('casual') ? days : 0.0,
          'medical_leave_total': 10.0,
          'medical_leave_used': (lTypeLower.contains('sick') || lTypeLower.contains('medical')) ? days : 0.0,
          'earned_leave_total': 8.0,
          'earned_leave_used': lTypeLower.contains('earned') ? days : 0.0,
          'on_duty_total': 15.0,
          'on_duty_used': (lTypeLower.contains('duty') || lTypeLower.contains('od')) ? days : 0.0,
          'updated_at': DateTime.now().toIso8601String(),
        };

        await SupabaseClientHelper.insert(
          'leave_balances',
          newPayload,
          schema: 'faculty',
        );
      }
    } catch (e) {
      debugPrint('Error updating database leave balance: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // HOD's own sent leave requests come from hod.hod_leave_requests
    final myHodRequests = _hodLeaveRequests;

    // Faculty leave requests come from faculty.leave_applications
    final facultyApprovalsRequests = _dbLeaveRequests;

    final activeDataset = _selectedViewMode == 'My Sent Requests'
        ? myHodRequests
        : facultyApprovalsRequests;

    final query = _searchCtrl.text.toLowerCase().trim();
    final filteredBySearch = activeDataset.where((d) {
      final faculty = (d['faculty'] ?? '').toString().toLowerCase();
      final leaveType = (d['leaveType'] ?? '').toString().toLowerCase();
      final displayId = (d['displayId'] ?? '').toString().toLowerCase();
      final substitute = (d['substitute'] ?? '').toString().toLowerCase();
      final reason = (d['reason'] ?? '').toString().toLowerCase();
      return faculty.contains(query) ||
          leaveType.contains(query) ||
          displayId.contains(query) ||
          substitute.contains(query) ||
          reason.contains(query);
    }).toList();

    final filtered = filteredBySearch.where((d) {
      final status = (d['status'] ?? '').toString().toUpperCase();
      if (_selectedFilter == 'Pending') {
        return status.contains('PENDING');
      } else if (_selectedFilter == 'Approved') {
        return status.contains('APPROVED') || status.contains('SANCTIONED');
      } else if (_selectedFilter == 'Rejected') {
        return status.contains('REJECTED');
      }
      return true;
    }).toList();

    final totalRequests = activeDataset.length;
    final pendingCount = activeDataset.where((d) {
      final s = (d['status'] ?? '').toString().toUpperCase();
      return s.contains('PENDING');
    }).length;
    final approvedCount = activeDataset.where((d) {
      final s = (d['status'] ?? '').toString().toUpperCase();
      return s.contains('APPROVED') || s.contains('SANCTIONED');
    }).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Page Header Title & Academic Year Badge
          HodSectionHeader(
            title: 'Leave Management',
            breadcrumb: _selectedViewMode == 'My Sent Requests' ? 'Dashboard > My Sent Leave Requests' : 'Dashboard > Leave Approvals',
            academicYear: 'Academic Year 2025 - 2026',
          ),
          const SizedBox(height: 16),

          // Top Mode Switcher Tab Selector Row (Hidden when direct view mode is forced via sidebar navigation)
          if (widget.forceViewMode == null) ...[
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTopModeTab(
                    title: 'Faculty Approvals',
                    modeKey: 'Faculty Approvals',
                    icon: Icons.approval_rounded,
                    badgeCount: facultyApprovalsRequests.where((d) => d['status'].toString().toUpperCase().contains('PENDING')).length,
                  ),
                  const SizedBox(width: 4),
                  _buildTopModeTab(
                    title: 'My Sent Requests',
                    modeKey: 'My Sent Requests',
                    icon: Icons.send_rounded,
                    badgeCount: myHodRequests.where((d) => d['status'].toString().toUpperCase().contains('PENDING')).length,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // 2. Faculty Leave Approvals vs Apply Leave Hero Banner Box
          if (_selectedViewMode == 'Faculty Approvals') ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFFEDD5)),
                        ),
                        child: const Icon(
                          Icons.calendar_month_rounded,
                          color: Color(0xFFF97316),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Faculty Leave Approvals & Substitutes',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (_isLoading)
                                const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Real-time leave management synchronized directly from faculty.leave_applications database.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          HodToast.show(context, message: 'Printing Leave Register...');
                        },
                        icon: const Icon(Icons.print_rounded, size: 16, color: Color(0xFFD97706)),
                        label: const Text(
                          'Print',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFD97706),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFFDE68A)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      HodExportDialog.buildExportButton(
                        context,
                        onPressed: () => HodExportDialog.show(
                          context,
                          title: 'Export Leave Data',
                          subtitle: 'Select export format for Leave Management records:',
                          moduleName: 'Leave Management',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            // Header card removed as requested
          ],
          const SizedBox(height: 20),

            // 3. Filter Options & Action Button Strip
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Radio Options
                  Row(
                    children: [
                      _buildFilterOption('All Leave Applications'),
                      const SizedBox(width: 12),
                      _buildFilterOption('Pending'),
                      const SizedBox(width: 12),
                      _buildFilterOption('Approved'),
                      const SizedBox(width: 12),
                      _buildFilterOption('Rejected'),
                    ],
                  ),

                  // Right Side: Month Dropdown + Apply Leave (if My Sent Requests)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedMonth,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                            items: _months.map((String month) {
                              return DropdownMenuItem<String>(
                                value: month,
                                child: Text(month),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedMonth = val);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

          // 4. Main Leave Register Card with Table & 3 KPI Stat Cards
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with Search Box & New Leave Request Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            color: Color(0xFFF97316),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _selectedViewMode == 'My Sent Requests' ? 'My Sent Leave Register' : 'Faculty Leave Register',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          SizedBox(
                            width: 240,
                            height: 38,
                            child: TextField(
                              controller: _searchCtrl,
                              onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Search faculty...',
                            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                            suffixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF64748B)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                            ),
                          ),
                        ),
                      ),
                      if (_selectedViewMode == 'My Sent Requests') ...[
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () => _openAddLeaveRequestModal(context),
                          icon: const Icon(Icons.add_circle_outline_rounded, size: 16, color: Colors.white),
                          label: const Text(
                            'Apply Leave',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

                  // 3 High Density Metric Summary Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          title: 'TOTAL REQUESTS',
                          value: '$totalRequests',
                          subtitle: 'In Database',
                          icon: Icons.assignment_outlined,
                          bgColor: const Color(0xFFEFF6FF),
                          borderColor: const Color(0xFFDBEAFE),
                          accentColor: const Color(0xFF2563EB),
                          textColor: const Color(0xFF1E40AF),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'PENDING REVIEW',
                          value: '$pendingCount',
                          subtitle: 'Requires action',
                          icon: Icons.error_outline_rounded,
                          bgColor: const Color(0xFFFFF7ED),
                          borderColor: const Color(0xFFFFEDD5),
                          accentColor: const Color(0xFFEA580C),
                          textColor: const Color(0xFFC2410C),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'APPROVED LEAVES',
                          value: '$approvedCount',
                          subtitle: 'Sanctioned',
                          icon: Icons.check_circle_outline_rounded,
                          bgColor: const Color(0xFFF0FDF4),
                          borderColor: const Color(0xFFDCFCE7),
                          accentColor: const Color(0xFF16A34A),
                          textColor: const Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // High Density Data Table
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Center(
                        child: Text(
                          _selectedViewMode == 'My Sent Requests'
                              ? 'No leave applications sent to Principal yet. Use \'Apply New Leave\' to submit one.'
                              : 'No faculty leave applications found.',
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                        ),
                      ),
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minWidth: constraints.maxWidth),
                            child: DataTable(
                              headingRowHeight: 46,
                              dataRowMinHeight: 60,
                              dataRowMaxHeight: 64,
                              horizontalMargin: 16,
                              columnSpacing: 28,
                              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                              columns: [
                                DataColumn(
                                  label: Text(
                                    _selectedViewMode == 'My Sent Requests' ? 'HOD / Applicant' : 'Faculty',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                                  ),
                                ),
                                const DataColumn(
                                  label: Text(
                                    'Leave Type',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                                  ),
                                ),
                                const DataColumn(
                                  label: Text(
                                    'Dates',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                                  ),
                                ),
                                const DataColumn(
                                  label: Text(
                                    'Reason',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                                  ),
                                ),
                                const DataColumn(
                                  label: Text(
                                    'Substitute',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    _selectedViewMode == 'My Sent Requests' ? 'Principal Approval' : 'Status',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    _selectedViewMode == 'My Sent Requests' ? 'Action' : 'HOD Actions',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                                  ),
                                ),
                              ],
                              rows: filtered.map((d) {
                                final status = (d['status'] ?? 'APPROVED').toString().toUpperCase();
                                final isPendingHOD = status == 'PENDING HOD' || status == 'PENDING';
                                final isWithdrawalAllowed = status.contains('PENDING');
                                return DataRow(cells: [
                                  // Faculty Column
                                  DataCell(
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          d['faculty'] ?? 'Unknown Faculty',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          d['displayId'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF94A3B8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Leave Type
                                  DataCell(
                                    Text(
                                      d['leaveType'] ?? 'Casual Leave',
                                      style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
                                    ),
                                  ),

                                  // Dates & Duration
                                  DataCell(
                                    Text(
                                      d['dates'] ?? '-',
                                      style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
                                    ),
                                  ),

                                  // Reason
                                  DataCell(
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: 180),
                                      child: Text(
                                        (d['reason'] != null && d['reason'].toString().trim().isNotEmpty) ? d['reason'].toString() : 'Personal Leave',
                                        style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),

                                  // Substitute Staff
                                  DataCell(
                                    Text(
                                      d['substitute'] ?? 'None',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF2563EB),
                                      ),
                                    ),
                                  ),

                                  // Status Badge — in Apply Leave show Principal approval status
                                  DataCell(_selectedViewMode == 'My Sent Requests'
                                      ? _buildPrincipalStatusBadge(status)
                                      : _buildStatusBadge(status)),

                                  // Actions
                                  DataCell(
                                    _selectedViewMode == 'Faculty Approvals' && isPendingHOD
                                        ? Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              ElevatedButton(
                                                onPressed: () => _openApproveModal(context, d['id'] ?? '', d),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF10B981),
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                  minimumSize: Size.zero,
                                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                ),
                                                child: const Text('Approve', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                              ),
                                              const SizedBox(width: 8),
                                              OutlinedButton(
                                                onPressed: () => _openRejectModal(context, d['id'] ?? '', d),
                                                style: OutlinedButton.styleFrom(
                                                  side: const BorderSide(color: Color(0xFFEF4444)),
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                  minimumSize: Size.zero,
                                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                ),
                                                child: const Text('Reject', style: TextStyle(color: Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.bold)),
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                icon: const Icon(Icons.info_outline_rounded, size: 20, color: Color(0xFF2563EB)),
                                                onPressed: () => _showDetailsModal(context, d),
                                                tooltip: 'View Application Details',
                                                constraints: const BoxConstraints(),
                                                padding: EdgeInsets.zero,
                                              ),
                                            ],
                                          )
                                        : _selectedViewMode == 'My Sent Requests' && isWithdrawalAllowed
                                            ? OutlinedButton.icon(
                                                onPressed: () async {
                                                  final docId = (d['id'] ?? '').toString();
                                                  if (docId.isEmpty) return;

                                                  final bool? confirm = await showDialog<bool>(
                                                    context: context,
                                                    builder: (BuildContext ctx) {
                                                      return AlertDialog(
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                        title: Text('Withdraw Leave Request', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                                                        content: Text('Are you sure you want to withdraw this leave request? This action cannot be undone.', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569))),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () => Navigator.pop(ctx, false),
                                                            child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 13)),
                                                          ),
                                                          ElevatedButton(
                                                            onPressed: () => Navigator.pop(ctx, true),
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor: const Color(0xFFEF4444),
                                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                              elevation: 0,
                                                            ),
                                                            child: Text('Withdraw', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  );

                                                  if (confirm == true) {
                                                    await SupabaseClientHelper.delete('hod_leave_requests', 'id', docId, schema: 'hod');
                                                    await SupabaseClientHelper.delete('hod_leave_requests', 'id', docId, schema: 'public');
                                                    await SupabaseClientHelper.delete('leave_applications', 'id', docId, schema: 'faculty');
                                                    await SupabaseClientHelper.delete('leave_applications', 'id', docId, schema: 'public');
                                                    if (context.mounted) {
                                                      HodToast.show(context, message: 'Leave request withdrawn successfully', isSuccess: true);
                                                      _fetchLeaveData();
                                                    }
                                                  }
                                                },
                                                icon: const Icon(Icons.cancel_outlined, size: 14, color: Color(0xFFEF4444)),
                                                label: const Text('Withdraw', style: TextStyle(color: Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.bold)),
                                                style: OutlinedButton.styleFrom(
                                                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                  minimumSize: Size.zero,
                                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                ),
                                              )
                                            : IconButton(
                                                icon: const Icon(Icons.info_outline_rounded, size: 20, color: Color(0xFF2563EB)),
                                                onPressed: () => _showDetailsModal(context, d),
                                                tooltip: 'View Application Details',
                                              ),
                                  ),
                                ]);
                              }).toList(),
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
      ),
    );
  }

  // Mode Switcher Tab
  Widget _buildTopModeTab({
    required String title,
    required String modeKey,
    required IconData icon,
    int badgeCount = 0,
  }) {
    final isSelected = _selectedViewMode == modeKey;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedViewMode = modeKey;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
              ),
            ),
            if (badgeCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Filter option pill widget
  Widget _buildFilterOption(String title) {
    final isSelected = _selectedFilter == title;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = title;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              size: 16,
              color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Metric summary card builder
  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color bgColor,
    required Color borderColor,
    required Color accentColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Status Badge Pill
  Widget _buildStatusBadge(String status) {
    if (status == 'APPROVED' || status == 'SANCTIONED') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.check_circle, size: 13, color: Color(0xFF15803D)),
            SizedBox(width: 4),
            Text(
              'APPROVED',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF15803D),
              ),
            ),
          ],
        ),
      );
    } else if (status == 'REJECTED') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.cancel, size: 13, color: Color(0xFFB91C1C)),
            SizedBox(width: 4),
            Text(
              'REJECTED',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFFB91C1C),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.access_time_filled, size: 13, color: Color(0xFFC2410C)),
            SizedBox(width: 4),
            Text(
              'PENDING',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFFC2410C),
              ),
            ),
          ],
        ),
      );
    }
  }

  /// Status badge shown in the HOD's "Apply Leave" tab — labels reflect Principal's decision
  Widget _buildPrincipalStatusBadge(String status) {
    if (status.contains('APPROVED') || status.contains('SANCTIONED')) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.verified_rounded, size: 13, color: Color(0xFF15803D)),
            SizedBox(width: 4),
            Text(
              'APPROVED BY PRINCIPAL',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
            ),
          ],
        ),
      );
    } else if (status.contains('REJECTED')) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.cancel_rounded, size: 13, color: Color(0xFFB91C1C)),
            SizedBox(width: 4),
            Text(
              'REJECTED BY PRINCIPAL',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFB91C1C)),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.schedule_rounded, size: 13, color: Color(0xFF1D4ED8)),
            SizedBox(width: 4),
            Text(
              'PENDING PRINCIPAL',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
            ),
          ],
        ),
      );
    }
  }

  // Modal: Add New Leave Request (7-Section Comprehensive Modal)
  void _openAddLeaveRequestModal(BuildContext context) {
    String selectedType = 'Casual Leave';
    String priority = 'Normal';
    String session = 'Full Day';
    bool isHalfDay = false;
    final now = DateTime.now();
    DateTime? fromDate = now;
    DateTime? toDate = now;

    bool applyForMultipleDays = false;
    int totalDaysCount = 1;
    int weekendDaysExcluded = 0;
    int holidaysExcluded = 0;
    int calculatedWorkingDays = 1;

    final reasonCtrl = TextEditingController();
    final remarksCtrl = TextEditingController();

    // Use real Supabase-resolved HOD employee ID (e.g. EMP-CSE-010), not local ProfileService default
    final String currentEmpId = _currentHodEmpId.isNotEmpty
        ? _currentHodEmpId
        : (ProfileService.get()['employeeId'] ?? ProfileService.get()['facultyId'] ?? '').toString();

    // Ensure current user is at the top of _facultiesList
    final bool hasCurrentUserInList = _facultiesList.any((f) => f['empId'] == currentEmpId);
    if (!hasCurrentUserInList && currentEmpId.isNotEmpty) {
      final profile = ProfileService.get();
      final String insertName = (profile['name'] ?? 'Logged In HOD').toString();
      final String insertDesig = (profile['designation'] ?? 'HOD & Professor').toString();
      _facultiesList.insert(0, {
        'uuid': _currentHodUuid,
        'empId': currentEmpId,
        'name': insertName,
        'designation': insertDesig,
        'label': '$insertName ($insertDesig)',
      });
    }

    String selectedFacultyEmpId = currentEmpId;
    String alternateFaculty = 'None (Optional)';
    bool declarationChecked = true;
    bool isSaving = false;

    // Document attachment state
    String? attachedFileName;
    int attachedFileSize = 0;
    double uploadProgress = 0.0;
    bool isUploading = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDlgState) {
            void updateDays() {
              if (!applyForMultipleDays) {
                toDate = fromDate;
              }
              if (fromDate != null && toDate != null) {
                final startNorm = DateTime(fromDate!.year, fromDate!.month, fromDate!.day);
                final endNorm = DateTime(toDate!.year, toDate!.month, toDate!.day);
                if (endNorm.isBefore(startNorm)) {
                  totalDaysCount = 0;
                  weekendDaysExcluded = 0;
                  calculatedWorkingDays = 0;
                  return;
                }
                int rawDays = endNorm.difference(startNorm).inDays + 1;
                totalDaysCount = rawDays;

                int wDays = 0;
                for (int i = 0; i < rawDays; i++) {
                  DateTime check = startNorm.add(Duration(days: i));
                  if (check.weekday == DateTime.saturday || check.weekday == DateTime.sunday) {
                    wDays++;
                  }
                }
                weekendDaysExcluded = wDays;
                holidaysExcluded = 0;
                int working = rawDays - weekendDaysExcluded - holidaysExcluded;
                if (isHalfDay || session != 'Full Day') {
                  working = (working > 0) ? working : 1;
                }
                calculatedWorkingDays = working <= 0 ? (totalDaysCount > 0 ? 1 : 0) : working;
              } else {
                totalDaysCount = 0;
                weekendDaysExcluded = 0;
                calculatedWorkingDays = 0;
              }
            }

            // ─── STRICT EMPLOYEE ISOLATION ───────────────────────────────
            // NEVER fall back to _facultiesList.first — that leaks another
            // employee's leave balance into this user's view.
            final String selectedEmpIdRaw =
                selectedFacultyEmpId.trim().toLowerCase();

            final selectedFacultyObj = _facultiesList.firstWhere(
              (f) => (f['empId'] ?? '').toString().trim().toLowerCase() ==
                  selectedEmpIdRaw,
              orElse: () => <String, dynamic>{
                'empId': selectedFacultyEmpId,
                'name': 'Unknown Faculty',
                'designation': '',
                'label': 'Unknown Faculty',
              },
            );

            // empId is ALWAYS sourced from the selected ID, never from a fallback row
            final String empId =
                (selectedFacultyObj['empId'] ?? selectedFacultyEmpId)
                    .toString()
                    .trim();
            final String targetEmpId = empId.toLowerCase();

            Map<String, dynamic>? userBalanceRecord;
            if (empId.isNotEmpty && _dbLeaveBalances.isNotEmpty) {
              try {
                userBalanceRecord = _dbLeaveBalances.firstWhere(
                  (b) {
                    final balanceEmpId = (b['faculty_employee_id'] ??
                            b['employee_id'] ??
                            b['faculty_id'])
                        ?.toString()
                        .trim()
                        .toLowerCase() ?? '';
                    return balanceEmpId.isNotEmpty && (balanceEmpId == targetEmpId || balanceEmpId.replaceAll('-', '_') == targetEmpId.replaceAll('-', '_'));
                  },
                );
              } catch (_) {
                userBalanceRecord = null;
              }
            }

            // Fallback default leave policy allocation for CSE HOD & Faculty
            userBalanceRecord ??= {
              'casual_leave_total': 12,
              'casual_leave_used': 2,
              'medical_leave_total': 10,
              'medical_leave_used': 0,
              'earned_leave_total': 15,
              'earned_leave_used': 1,
              'on_duty_total': 15,
              'on_duty_used': 0,
              'comp_leave_total': 5,
              'comp_leave_used': 0,
            };

            final rec = userBalanceRecord;
            final bool hasLeavePolicy = rec != null;

            num getVal(Map<String, dynamic>? m, List<String> keys) {
              if (m == null) return 0;
              for (final k in keys) {
                if (m.containsKey(k) && m[k] != null) {
                  final v = m[k];
                  if (v is num) return v;
                  final parsed = num.tryParse(v.toString());
                  if (parsed != null) return parsed;
                }
              }
              return 0;
            }

            final casualTotal = hasLeavePolicy ? getVal(rec, ['casual_leave_total', 'casual_total', 'casual_leave_allocated', 'casual_allocated', 'casual_leave', 'casual', 'total_casual']).toInt() : 0;
            final casualUsed = hasLeavePolicy ? getVal(rec, ['casual_leave_used', 'casual_used', 'used_casual']).toInt() : 0;
            final casualRem = (casualTotal - casualUsed).clamp(0, 999);

            final sickTotal = hasLeavePolicy ? getVal(rec, ['medical_leave_total', 'medical_leave_allocated', 'medical_allocated', 'sick_leave_total', 'sick_leave_allocated', 'medical_total', 'medical_leave', 'sick_total', 'sick_leave']).toInt() : 0;
            final sickUsed = hasLeavePolicy ? getVal(rec, ['medical_leave_used', 'sick_leave_used', 'medical_used', 'sick_used']).toInt() : 0;
            final sickRem = (sickTotal - sickUsed).clamp(0, 999);

            final earnedTotal = hasLeavePolicy ? getVal(rec, ['earned_leave_total', 'earned_leave_allocated', 'earned_allocated', 'earned_total', 'earned_leave']).toInt() : 0;
            final earnedUsed = hasLeavePolicy ? getVal(rec, ['earned_leave_used', 'earned_used']).toInt() : 0;
            final earnedRem = (earnedTotal - earnedUsed).clamp(0, 999);

            final odTotal = hasLeavePolicy ? getVal(rec, ['on_duty_total', 'on_duty_allocated', 'on_duty', 'od_total', 'od_allocated', 'on_duty_leave_total']).toInt() : 0;
            final odUsed = hasLeavePolicy ? getVal(rec, ['on_duty_used', 'od_used']).toInt() : 0;
            final odRem = (odTotal - odUsed).clamp(0, 999);

            final compTotal = hasLeavePolicy ? getVal(rec, ['comp_leave_total', 'comp_leave_allocated', 'comp_allocated', 'comp_total', 'compensatory_leave_total', 'compensatory_leave_allocated', 'comp_leave']).toInt() : 0;
            final compUsed = hasLeavePolicy ? getVal(rec, ['comp_leave_used', 'comp_used', 'compensatory_leave_used']).toInt() : 0;
            final compRem = (compTotal - compUsed).clamp(0, 999);

            int currentBalance = 0;
            final lTypeLower = selectedType.toLowerCase();
            if (hasLeavePolicy) {
              if (lTypeLower.contains('casual')) {
                currentBalance = casualRem;
              } else if (lTypeLower.contains('sick') || lTypeLower.contains('medical')) {
                currentBalance = sickRem;
              } else if (lTypeLower.contains('earned')) {
                currentBalance = earnedRem;
              } else if (lTypeLower.contains('duty') || lTypeLower.contains('od')) {
                currentBalance = odRem;
              } else if (lTypeLower.contains('compensatory')) {
                currentBalance = compRem;
              } else {
                currentBalance = 0;
              }
            }

            int remainingBalance = currentBalance - calculatedWorkingDays;
            final isSickLeave = selectedType == 'Sick Leave' || selectedType == 'Medical Leave';
            final isOnDuty = selectedType == 'On Duty';
            final showUploadSection = isSickLeave || isOnDuty;

            final isFormValid = hasLeavePolicy &&
                fromDate != null &&
                toDate != null &&
                !toDate!.isBefore(fromDate!) &&
                totalDaysCount > 0 &&
                declarationChecked;

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Container(
                width: 880,
                constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.92),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Modal Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.note_add_outlined, color: Color(0xFF2563EB), size: 24),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Apply Leave / On Duty (OD)', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                            Text('Official HOD Leave Application & Principal Approval Workflow', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                          ],
                        ),
                        const Spacer(),
                        IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, color: Color(0xFF64748B))),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 14),

                    // Modal Content Body
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ─── SECTION 1: LEAVE DETAILS & AUTO-CALCULATION ───
                            _sectionHeader(Icons.event_note_outlined, 'SECTION 1: LEAVE DETAILS & AUTO-CALCULATION'),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 16,
                                    runSpacing: 14,
                                    children: [
                                      _modalDropdown(
                                        'Leave Type *',
                                        ['Casual Leave', 'Medical Leave', 'Earned Leave', 'On Duty'],
                                        selectedType,
                                        (v) {
                                          setDlgState(() {
                                            selectedType = v!;
                                            updateDays();
                                          });
                                        },
                                      ),
                                      _modalDropdown(
                                        'Priority',
                                        ['Normal', 'Urgent'],
                                        priority,
                                        (v) => setDlgState(() => priority = v!),
                                      ),
                                      _datePickerField(
                                        'From Date *',
                                        fromDate,
                                        (d) {},
                                        context: ctx,
                                        onTap: () async {
                                          final result = await PremiumDatePickerDialog.show(
                                            context: ctx,
                                            mode: PremiumDatePickerMode.single,
                                            initialStartDate: fromDate,
                                            leaveType: selectedType,
                                            initialLeaveBalance: currentBalance,
                                            existingLeaves: const [],
                                          );
                                          if (result != null && result['start'] != null) {
                                            setDlgState(() {
                                              fromDate = result['start'];
                                              updateDays();
                                            });
                                          }
                                        },
                                      ),
                                      if (applyForMultipleDays)
                                        _datePickerField(
                                          'To Date *',
                                          toDate,
                                          (d) {},
                                          context: ctx,
                                          onTap: () async {
                                            final result = await PremiumDatePickerDialog.show(
                                              context: ctx,
                                              mode: PremiumDatePickerMode.single,
                                              initialStartDate: toDate ?? fromDate,
                                              leaveType: selectedType,
                                              initialLeaveBalance: currentBalance,
                                              existingLeaves: const [],
                                            );
                                            if (result != null && result['start'] != null) {
                                              setDlgState(() {
                                                toDate = result['start'];
                                                updateDays();
                                              });
                                            }
                                          },
                                        ),
                                      _modalDropdown(
                                        'Session',
                                        ['Full Day', 'First Half', 'Second Half'],
                                        session,
                                        (v) {
                                          setDlgState(() {
                                            session = v!;
                                            isHalfDay = session != 'Full Day';
                                            updateDays();
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  if (applyForMultipleDays && fromDate != null && toDate != null && toDate!.isBefore(fromDate!)) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          'To Date cannot be before From Date.',
                                          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFDC2626), fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 20,
                                    runSpacing: 10,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Checkbox(
                                            value: applyForMultipleDays,
                                            onChanged: (v) {
                                              setDlgState(() {
                                                applyForMultipleDays = v ?? false;
                                                if (applyForMultipleDays) {
                                                  toDate = fromDate;
                                                }
                                                updateDays();
                                              });
                                            },
                                            activeColor: const Color(0xFF2563EB),
                                          ),
                                          Text('Apply for multiple days', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF334155), fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Checkbox(
                                            value: isHalfDay,
                                            onChanged: (v) {
                                              setDlgState(() {
                                                isHalfDay = v ?? false;
                                                if (isHalfDay && session == 'Full Day') {
                                                  session = 'First Half';
                                                } else if (!isHalfDay) {
                                                  session = 'Full Day';
                                                }
                                                updateDays();
                                              });
                                            },
                                            activeColor: const Color(0xFF2563EB),
                                          ),
                                          Text('Apply as Half Day (0.5 Day duration)', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF334155))),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // ─── SECTION 2: LEAVE BALANCE CARDS ───
                            _sectionHeader(Icons.account_balance_wallet_outlined, 'SECTION 2: LEAVE BALANCE BREAKDOWN'),
                            const SizedBox(height: 10),
                            hasLeavePolicy
                                ? Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: [
                                      _balanceCard('Casual Leave', casualTotal, casualUsed, casualRem, selectedType == 'Casual Leave'),
                                      _balanceCard('Medical Leave', sickTotal, sickUsed, sickRem, selectedType == 'Medical Leave' || selectedType == 'Sick Leave'),
                                      _balanceCard('Earned Leave', earnedTotal, earnedUsed, earnedRem, selectedType == 'Earned Leave'),
                                      _balanceCard('On Duty (OD)', odTotal, odUsed, odRem, selectedType == 'On Duty'),
                                    ],
                                  )
                                : Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF2F2),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFFFECACA)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 28),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Your leave policy is not defined',
                                                style: GoogleFonts.inter(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFF991B1B),
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'No active leave policy allocations found in database for Employee ID ($empId). Please contact HR to configure your leave allocation.',
                                                style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  color: const Color(0xFFB91C1C),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                            const SizedBox(height: 20),

                            // ─── SECTION 3: REASON & REMARKS ───
                            _sectionHeader(Icons.edit_note_outlined, 'SECTION 3: REASON & REMARKS'),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(isOnDuty ? 'Purpose of On Duty (OD) *' : 'Reason for Leave * (Required)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: reasonCtrl,
                                    maxLines: 2,
                                    onChanged: (_) => setDlgState(() {}),
                                    style: GoogleFonts.inter(fontSize: 12),
                                    decoration: InputDecoration(
                                      hintText: isOnDuty ? 'Enter official OD location, event name, and purpose...' : 'State specific reason for leave application...',
                                      hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                                      border: const OutlineInputBorder(),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text('Remarks / Additional Notes (Optional)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: remarksCtrl,
                                    maxLines: 1,
                                    style: GoogleFonts.inter(fontSize: 12),
                                    decoration: InputDecoration(
                                      hintText: 'Enter any additional remarks for Principal review...',
                                      hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                                      border: const OutlineInputBorder(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // ─── SECTION 4: SUPPORTING DOCUMENTS (DYNAMIC) ───
                            AnimatedSize(
                              duration: const Duration(milliseconds: 250),
                              child: showUploadSection
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _sectionHeader(Icons.attach_file_outlined, isSickLeave ? 'SECTION 4: MEDICAL CERTIFICATE (REQUIRED)' : 'SECTION 4: SUPPORTING DUTY ORDER (REQUIRED)'),
                                        const SizedBox(height: 10),
                                        GestureDetector(
                                          onTap: () {
                                            if (isUploading) return;
                                            setDlgState(() {
                                              isUploading = true;
                                              attachedFileName = isSickLeave ? 'Medical_Certificate_Doc.pdf' : 'Duty_Order_Approval.pdf';
                                              attachedFileSize = 1420500;
                                              uploadProgress = 0.0;
                                            });
                                            Future.doWhile(() async {
                                              await Future.delayed(const Duration(milliseconds: 100));
                                              setDlgState(() {
                                                uploadProgress += 0.25;
                                              });
                                              if (uploadProgress >= 1.0) {
                                                setDlgState(() {
                                                  uploadProgress = 1.0;
                                                  isUploading = false;
                                                });
                                                return false;
                                              }
                                              return true;
                                            });
                                          },
                                          child: Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF8FAFC),
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(color: const Color(0xFFCBD5E1)),
                                            ),
                                            child: attachedFileName == null
                                                ? Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      const Icon(Icons.cloud_upload_outlined, color: Color(0xFF2563EB), size: 24),
                                                      const SizedBox(width: 12),
                                                      Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(isSickLeave ? 'Upload Medical Certificate (.PDF, .JPG, .PNG)' : 'Upload Duty Order / Requisition Letter (.PDF, .JPG)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB))),
                                                          Text('Maximum file size: 10 MB', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8))),
                                                        ],
                                                      ),
                                                    ],
                                                  )
                                                : Row(
                                                    children: [
                                                      const Icon(Icons.insert_drive_file_outlined, color: Color(0xFF2563EB), size: 24),
                                                      const SizedBox(width: 10),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(attachedFileName!, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF334155)), overflow: TextOverflow.ellipsis),
                                                            Text('${(attachedFileSize / 1024).toStringAsFixed(1)} KB', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8))),
                                                            if (isUploading) ...[
                                                              const SizedBox(height: 4),
                                                              LinearProgressIndicator(value: uploadProgress, color: const Color(0xFF2563EB), backgroundColor: Colors.grey[200]),
                                                            ]
                                                          ],
                                                        ),
                                                      ),
                                                      if (!isUploading)
                                                        IconButton(onPressed: () => setDlgState(() => attachedFileName = null), icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18)),
                                                    ],
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                      ],
                                    )
                                  : const SizedBox.shrink(),
                            ),

                             // ─── SECTION 5: APPROVAL WORKFLOW ROUTING ───
                             _sectionHeader(Icons.swap_calls_outlined, 'SECTION 5: APPROVAL WORKFLOW ROUTING'),
                             const SizedBox(height: 10),
                             Container(
                               padding: const EdgeInsets.all(16),
                               decoration: BoxDecoration(
                                 color: Colors.white,
                                 borderRadius: BorderRadius.circular(10),
                                 border: Border.all(color: const Color(0xFFE2E8F0)),
                               ),
                               child: Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   Text(
                                     'As HOD, your leave request is routed directly to the Principal for review and approval.',
                                     style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569)),
                                   ),
                                   const SizedBox(height: 12),
                                   Row(
                                     children: [
                                       _dialogWorkflowStep('HOD (Applicant)', 'Submitted', const Color(0xFF2563EB), true),
                                       _dialogWorkflowConnector(),
                                       _dialogWorkflowStep('Principal Approval', 'Pending Review', const Color(0xFFD97706), false),
                                       _dialogWorkflowConnector(),
                                       _dialogWorkflowStep('Approved', 'Final Sanction', const Color(0xFF16A34A), false),
                                     ],
                                   ),
                                   const SizedBox(height: 12),
                                   Row(
                                     children: [
                                       Checkbox(value: isHalfDay, onChanged: (v) => setDlgState(() => isHalfDay = v!)),
                                       Text('Apply as Half Day (0.5 Day duration)', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF334155))),
                                     ],
                                   ),
                                 ],
                               ),
                             ),
                             const SizedBox(height: 20),

                             // ─── SECTION 6: DECLARATION ───
                             _sectionHeader(Icons.verified_user_outlined, 'SECTION 6: DECLARATION & CONFIRMATION'),
                             const SizedBox(height: 10),
                             Container(
                               padding: const EdgeInsets.all(12),
                               decoration: BoxDecoration(
                                 color: const Color(0xFFF8FAFC),
                                 borderRadius: BorderRadius.circular(8),
                                 border: Border.all(color: const Color(0xFFE2E8F0)),
                               ),
                               child: Row(
                                 children: [
                                   Checkbox(
                                     value: declarationChecked,
                                     onChanged: (v) => setDlgState(() => declarationChecked = v ?? false),
                                     activeColor: const Color(0xFF2563EB),
                                   ),
                                   Expanded(
                                     child: Text(
                                       'I confirm that the information provided is correct and class substitution arrangements have been coordinated.',
                                       style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF0F172A)),
                                     ),
                                   ),
                                 ],
                               ),
                             ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 16),

                    // Actions Row
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      alignment: WrapAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: isSaving ? null : () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF64748B), side: const BorderSide(color: Color(0xFFE2E8F0)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                          child: Text('Cancel', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                        OutlinedButton(
                          onPressed: isSaving
                              ? null
                              : () {
                                  if (reasonCtrl.text.trim().isEmpty) {
                                    HodToast.show(ctx, message: 'Reason is required to save draft.', isError: true);
                                    return;
                                  }
                                  Navigator.pop(ctx);
                                  HodToast.show(this.context, message: 'Draft saved successfully.', isSuccess: true);
                                },
                          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF2563EB), side: const BorderSide(color: Color(0xFFBFDBFE)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                          child: Text('Save Draft', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
),
                        ElevatedButton.icon(
                          onPressed: (isFormValid && !isSaving)
                              ? () async {
                                  if (reasonCtrl.text.trim().isEmpty) {
                                    HodToast.show(ctx, message: 'Please enter a reason for leave application.', isError: true);
                                    return;
                                  }
                                  setDlgState(() => isSaving = true);
                                  final startDateStr = fromDate != null ? '${fromDate!.year}-${fromDate!.month.toString().padLeft(2, '0')}-${fromDate!.day.toString().padLeft(2, '0')}' : '';
                                  final endDateStr = toDate != null ? '${toDate!.year}-${toDate!.month.toString().padLeft(2, '0')}-${toDate!.day.toString().padLeft(2, '0')}' : '';
                                  final bool isHodRequest = empId == currentEmpId || empId == _currentHodEmpId;

                                  if (isHodRequest && fromDate != null && toDate != null) {
                                    bool hasOverlap = false;
                                    final reqStart = DateTime(fromDate!.year, fromDate!.month, fromDate!.day);
                                    final reqEnd = DateTime(toDate!.year, toDate!.month, toDate!.day);

                                    for (final r in _hodLeaveRequests) {
                                      final rStatus = (r['status'] ?? '').toString().toUpperCase();
                                      if (rStatus == 'REJECTED' || rStatus == 'WITHDRAWN') continue;

                                      final rFromStr = r['startDate']?.toString() ?? '';
                                      final rToStr = r['endDate']?.toString() ?? '';
                                      if (rFromStr.isNotEmpty && rToStr.isNotEmpty) {
                                        try {
                                          final rFrom = DateTime.parse(rFromStr);
                                          final rTo = DateTime.parse(rToStr);
                                          final rFromNorm = DateTime(rFrom.year, rFrom.month, rFrom.day);
                                          final rToNorm = DateTime(rTo.year, rTo.month, rTo.day);

                                          if (!reqStart.isAfter(rToNorm) && !rFromNorm.isAfter(reqEnd)) {
                                            hasOverlap = true;
                                            break;
                                          }
                                        } catch (_) {}
                                      }
                                    }

                                    if (hasOverlap) {
                                      final bool? proceed = await showDialog<bool>(
                                        context: ctx,
                                        builder: (c) => AlertDialog(
                                          title: Row(
                                            children: const [
                                              Icon(Icons.warning_amber_rounded, color: Colors.amber),
                                              SizedBox(width: 8),
                                              Text('Leave Overlap Warning'),
                                            ],
                                          ),
                                          content: const Text('You already have an active leave request registered for the selected date range. Do you want to submit anyway?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(c, false),
                                              child: const Text('Cancel'),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                                              onPressed: () => Navigator.pop(c, true),
                                              child: const Text('Submit Anyway'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (proceed != true) {
                                        setDlgState(() => isSaving = false);
                                        return;
                                      }
                                    }
                                  }

                                  final statusVal = isHodRequest ? 'PENDING' : 'PENDING';

                                  // Payload for faculty.leave_applications table
                                  final facultyPayload = <String, dynamic>{
                                    'faculty_employee_id': empId,
                                    'leave_type': selectedType,
                                    'start_date': startDateStr,
                                    'end_date': endDateStr,
                                    'reason': reasonCtrl.text.trim(),
                                    'substitute_faculty_id': alternateFaculty == 'None (Optional)' ? null : alternateFaculty,
                                    'status': statusVal,
                                    'hod_remarks': remarksCtrl.text.trim().isNotEmpty ? remarksCtrl.text.trim() : 'Submitted by HOD',
                                  };

                                  // Payload for hod.hod_leave_requests table — columns: faculty_id, faculty_name, from_date, to_date, substitute_faculty
                                  final String? facultyUuid = selectedFacultyObj['uuid']?.toString();
                                  final bool isUuidValid = facultyUuid != null && RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(facultyUuid);
                                  final hodPayload = <String, dynamic>{
                                    'faculty_id': isUuidValid ? facultyUuid : null,
                                    'faculty_name': _currentHodName.isNotEmpty ? _currentHodName : (ProfileService.get()['name'] ?? '').toString(),
                                    'leave_type': selectedType,
                                    'dates': '$startDateStr to $endDateStr',
                                    'from_date': startDateStr,
                                    'to_date': endDateStr,
                                    'reason': reasonCtrl.text.trim(),
                                    'substitute_faculty': alternateFaculty == 'None (Optional)' ? null : alternateFaculty,
                                    'status': statusVal,
                                    'created_at': DateTime.now().toIso8601String(),
                                  };

                                  // 1. If it is an HOD request, strictly insert into hod_leave_requests in hod schema
                                  if (isHodRequest) {
                                    await SupabaseClientHelper.insert('hod_leave_requests', hodPayload, schema: 'hod');
                                  } else {
                                    // 2. Otherwise (Faculty request), insert into faculty.leave_applications
                                    final resFaculty = await SupabaseClientHelper.insert('leave_applications', facultyPayload, schema: 'faculty');
                                    if (resFaculty == null) {
                                      await SupabaseClientHelper.insert('leave_applications', facultyPayload, schema: 'public');
                                    }
                                  }

                                  await _updateDatabaseLeaveBalance(
                                    facultyEmpId: empId,
                                    leaveType: selectedType,
                                    days: calculatedWorkingDays.toDouble(),
                                  );

                                  if (ctx.mounted) Navigator.pop(ctx);

                                  if (mounted) {
                                    HodToast.show(this.context, message: 'Leave request submitted & database synced!', isSuccess: true);
                                    _fetchLeaveData();
                                  }
                                }
                              : null,
                          icon: isSaving
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.send_outlined, size: 14),
                          label: Text('Submit Application', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Modal Section Helper Widgets
  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF2563EB)),
        const SizedBox(width: 6),
        Text(title, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A), letterSpacing: 0.5)),
      ],
    );
  }

  Widget _dialogWorkflowStep(String title, String status, Color color, bool isDone) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: isDone ? color : color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(
            isDone ? Icons.check : Icons.circle,
            size: 12,
            color: isDone ? Colors.white : color,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
            ),
            Text(
              status,
              style: GoogleFonts.inter(fontSize: 9, color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }

  Widget _dialogWorkflowConnector() {
    return Expanded(
      child: Container(
        height: 1,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: const Color(0xFFCBD5E1),
      ),
    );
  }



  Widget _calcStatItem(String label, String value, Color color, {bool isBold = false}) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: color)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B))),
      ],
    );
  }

  Widget _balanceCard(String type, int avail, int applied, int rem, bool isSelected) {
    return Container(
      width: 155,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0), width: isSelected ? 1.5 : 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(type, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF0F172A)), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Avail: $avail', style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF64748B))),
              Text('Applied: $applied', style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF64748B))),
            ],
          ),
          const SizedBox(height: 2),
          Text('Rem: $rem Days', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF16A34A))),
        ],
      ),
    );
  }


  Widget _modalDropdown(String label, List<String> items, String currentVal, ValueChanged<String?> onChange) {
    final validVal = items.contains(currentVal) ? currentVal : items.first;
    return SizedBox(
      width: 240,
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        initialValue: validVal,
        items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: GoogleFonts.inter(fontSize: 12), overflow: TextOverflow.ellipsis))).toList(),
        onChanged: onChange,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }

  Widget _datePickerField(String label, DateTime? date, ValueChanged<DateTime?> onSelect, {required BuildContext context, VoidCallback? onTap}) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final displayStr = date != null ? '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}' : '-- Select Date --';
    return SizedBox(
      width: 240,
      child: InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            labelStyle: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          child: Row(
            children: [
              Expanded(child: Text(displayStr, style: GoogleFonts.inter(fontSize: 12, color: date != null ? const Color(0xFF0F172A) : const Color(0xFF94A3B8)))),
              const Icon(Icons.calendar_month_outlined, size: 16, color: Color(0xFF64748B)),
            ],
          ),
        ),
      ),
    );
  }

  // Modal: Approve Leave
  void _openApproveModal(BuildContext context, String docId, Map<String, dynamic> d) {
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Approve Leave', style: TextStyle(fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Are you sure you want to approve this leave request?',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Faculty: ${d['faculty']}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Dates: ${d['dates']}',
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Type: ${d['leaveType']}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          setModalState(() => isSaving = true);
                          if (docId.isNotEmpty) {
                            final appPayload = {
                              'status': 'APPROVED',
                              'substitute_faculty_id': d['substituteEmpId'] ?? '',
                              'hod_remarks': 'Sanctioned by HOD',
                            };
                            await SupabaseClientHelper.update('leave_applications', appPayload, 'id', docId, schema: 'faculty');
                            await SupabaseClientHelper.update('leave_applications', appPayload, 'id', docId, schema: 'public');
                            await SupabaseClientHelper.update('hod_leave_requests', appPayload, 'id', docId, schema: 'hod');
                            await SupabaseClientHelper.update('hod_leave_requests', appPayload, 'id', docId, schema: 'public');

                            final facultyEmpId = d['facultyEmpId']?.toString() ?? '';
                            final leaveType = d['leaveType']?.toString() ?? 'Casual Leave';
                            final double days = (d['days'] as num? ?? 1.0).toDouble();

                            await _updateDatabaseLeaveBalance(
                              facultyEmpId: facultyEmpId,
                              leaveType: leaveType,
                              days: days,
                            );
                          }
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) {
                            HodToast.show(this.context, message: 'Leave ${d['displayId']} APPROVED & balance updated!', isSuccess: true);
                            _fetchLeaveData();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: isSaving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Confirm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Modal: Reject Leave
  void _openRejectModal(BuildContext context, String docId, Map<String, dynamic> d) {
    final reasonCtrl = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Reject Leave: ${d['displayId']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
              content: SizedBox(
                width: 440,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Faculty: ${d['faculty']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 14),
                    const Text('Reason for Rejection *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF334155))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: reasonCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'State reason for rejecting leave request...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: isSaving ? null : () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (reasonCtrl.text.trim().isEmpty) {
                            HodToast.show(ctx, message: 'Please provide a rejection reason!', isError: true);
                            return;
                          }
                          setModalState(() => isSaving = true);
                          if (docId.isNotEmpty) {
                            final appPayload = {
                              'status': 'REJECTED',
                              'hod_remarks': reasonCtrl.text.trim(),
                            };
                            await SupabaseClientHelper.update('leave_applications', appPayload, 'id', docId, schema: 'faculty');
                            await SupabaseClientHelper.update('leave_applications', appPayload, 'id', docId, schema: 'public');
                            await SupabaseClientHelper.update('hod_leave_requests', appPayload, 'id', docId, schema: 'hod');
                            await SupabaseClientHelper.update('hod_leave_requests', appPayload, 'id', docId, schema: 'public');
                          }
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) {
                            HodToast.show(this.context, message: 'Leave ${d['displayId']} REJECTED!', isError: true);
                            _fetchLeaveData();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: isSaving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Confirm Rejection', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Modal: Details
  void _showDetailsModal(BuildContext context, Map<String, dynamic> d) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.description_rounded, color: Color(0xFF2563EB)),
            const SizedBox(width: 10),
            Text('Leave Details: ${d['displayId']}', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Faculty Name:', d['faculty'] ?? '-'),
              _detailRow('Leave Type:', d['leaveType'] ?? '-'),
              _detailRow('Dates & Duration:', d['dates'] ?? '-'),
              _detailRow('Reason:', d['reason'] ?? '-'),
              if ((d['hodRemarks'] ?? '').isNotEmpty) _detailRow('HOD Remarks:', d['hodRemarks'] ?? '-'),
              if (d['substitutions'] != null && (d['substitutions'] as List).isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                const Text('Substitute Staff Details:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
                const SizedBox(height: 8),
                (() {
                  final seenSub = <String>{};
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: (d['substitutions'] as List).map((s) {
                      if (s is! Map) return const SizedBox.shrink();
                      final date = s['date']?.toString() ?? '';
                      final period = s['period']?.toString() ?? '';
                      final rawFac = s['substituteFaculty']?.toString() ?? s['substitute_faculty_name']?.toString() ?? 'None';
                      final cleanFaculty = rawFac.split('(').first.trim();
                      final subject = s['subject']?.toString() ?? '';
                      final classSec = s['classSec']?.toString() ?? s['class_sec']?.toString() ?? '';

                      final key = '$date-$period-$cleanFaculty-$subject-$classSec';
                      if (seenSub.contains(key)) return const SizedBox.shrink();
                      seenSub.add(key);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.swap_horiz_rounded, size: 16, color: Color(0xFF2563EB)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '$date | $period: $cleanFaculty${subject.isNotEmpty ? " ($subject)" : ""}${classSec.isNotEmpty ? " [$classSec]" : ""}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                })(),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Application Status: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  _buildStatusBadge(d['status'] ?? 'APPROVED'),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF64748B))),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
          ),
        ],
      ),
    );
  }
}
