import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../widgets/faculty_loading.dart';
import '../erp_repository.dart';
import '../services/leave_service.dart';
import '../services/profile_service.dart';
import '../services/timetable_service.dart';
import '../services/supabase_client.dart';
import 'premium_date_picker.dart';

class LeaveApplicationView extends StatefulWidget {
  const LeaveApplicationView({super.key});

  @override
  State<LeaveApplicationView> createState() => _LeaveApplicationViewState();
}

class _LeaveApplicationViewState extends State<LeaveApplicationView> {
  final repo = ErpRepository();
  final _searchCtrl = TextEditingController();
  String _selectedFilter = 'All Status';
  String _selectedSort = 'Latest First';
  bool _isFetching = false;

  @override
  void initState() {
    super.initState();
    _loadLeaveDataFast();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Map<String, String>> _deptFaculties = [];

  Future<void> _loadLeaveDataFast({bool showFeedback = false}) async {
    if (mounted) setState(() => _isFetching = true);

    try {
      final updated = await LeaveService.fetchFromSupabase();
      final empId = repo.profile['employeeId'] ?? 'EMP_CSE_002';
      final balancesMap = await LeaveService.fetchLeaveBalances(
        facultyEmpId: empId,
        academicYear: repo.selectedAcademicYear,
      );
      final hodNameFromDb = await ProfileService.fetchHodNameFromSupabase(
        hodEmployeeId: 'HOD-CSE-001',
      );
      final facultiesList = await LeaveService.fetchDepartmentFaculties(
        currentEmpId: empId,
      );
      if (mounted) {
        setState(() {
          repo.leaveApplications = updated;
          repo.leaveBalancesMap = balancesMap;
          balancesMap.forEach((type, b) {
            repo.leaveBalances[type] = b['remaining']?.toInt() ?? 8;
          });
          _deptFaculties = facultiesList;
          if (hodNameFromDb.isNotEmpty) {
            repo.profile['hodName'] = hodNameFromDb;
            repo.profile['hodEmployeeId'] = 'HOD-CSE-001';
          }
          _isFetching = false;
        });
        if (showFeedback) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Leave data refreshed successfully.'),
              backgroundColor: Color(0xFF2563EB),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  DateTime _parseSortableDate(dynamic raw) {
    if (raw == null) return DateTime(1970);
    final str = raw.toString().trim();
    if (str.isEmpty || str == '—') return DateTime(1970);

    try {
      final isoParsed = DateTime.tryParse(str);
      if (isoParsed != null) return isoParsed;

      final months = {
        'jan': 1,
        'feb': 2,
        'mar': 3,
        'apr': 4,
        'may': 5,
        'jun': 6,
        'jul': 7,
        'aug': 8,
        'sep': 9,
        'oct': 10,
        'nov': 11,
        'dec': 12,
      };
      final parts = str.split(RegExp(r'[\s\/\-\.]'));
      if (parts.length >= 3) {
        int? day = int.tryParse(parts[0]);
        int? month = months[parts[1].toLowerCase()] ?? int.tryParse(parts[1]);
        int? year = int.tryParse(parts[2]);

        if (day != null && month != null && year != null) {
          return DateTime(year, month, day);
        }
      }
    } catch (_) {}

    return DateTime(1970);
  }

  DateTime _getAppliedDate(Map<String, dynamic> app) {
    return _parseSortableDate(
      app['appliedOn'] ??
          app['createdAt'] ??
          app['applied_date'] ??
          app['fromDate'],
    );
  }

  DateTime _getFromDate(Map<String, dynamic> app) {
    return _parseSortableDate(
      app['fromDate'] ??
          app['startDate'] ??
          app['appliedOn'] ??
          app['createdAt'],
    );
  }

  List<Map<String, dynamic>> get _filteredApps {
    final list = repo.leaveApplications;
    final q = _searchCtrl.text.toLowerCase();

    final filtered = list.where((app) {
      final matchesSearch =
          q.isEmpty ||
          (app['type'] as String? ?? '').toLowerCase().contains(q) ||
          (app['reason'] as String? ?? '').toLowerCase().contains(q) ||
          (app['id'] as String? ?? '').toLowerCase().contains(q);

      final matchesFilter =
          _selectedFilter == 'All Status' ||
          (app['status'] as String? ?? '').toLowerCase() ==
              _selectedFilter.toLowerCase();

      return matchesSearch && matchesFilter;
    }).toList();

    filtered.sort((a, b) {
      if (_selectedSort == 'Oldest First' ||
          _selectedSort == 'Oldest Applied First') {
        final dateA = _getAppliedDate(a);
        final dateB = _getAppliedDate(b);
        return dateA.compareTo(dateB);
      } else if (_selectedSort == 'Leave Date (Newest First)') {
        final dateA = _getFromDate(a);
        final dateB = _getFromDate(b);
        return dateB.compareTo(dateA);
      } else if (_selectedSort == 'Leave Date (Oldest First)') {
        final dateA = _getFromDate(a);
        final dateB = _getFromDate(b);
        return dateA.compareTo(dateB);
      } else if (_selectedSort == 'Duration (High to Low)') {
        final daysA = (a['days'] as num? ?? 0).toDouble();
        final daysB = (b['days'] as num? ?? 0).toDouble();
        return daysB.compareTo(daysA);
      } else if (_selectedSort == 'Duration (Low to High)') {
        final daysA = (a['days'] as num? ?? 0).toDouble();
        final daysB = (b['days'] as num? ?? 0).toDouble();
        return daysA.compareTo(daysB);
      } else {
        // Latest First (default - sorts by Applied On date descending)
        final dateA = _getAppliedDate(a);
        final dateB = _getAppliedDate(b);
        return dateB.compareTo(dateA);
      }
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        if (repo.isLoadingData && repo.leaveApplications.isEmpty) {
          return const FacultyLoadingWidget();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _pageHeader(),
            const SizedBox(height: 20),
            _buildStatCards(),
            const SizedBox(height: 20),
            _applicationsTable(),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }

  Widget _pageHeader() {
    final applyButton = ElevatedButton.icon(
      onPressed: () => _showApplyLeaveDialog(),
      icon: const Icon(Icons.add_outlined, size: 16),
      label: Text(
        'Apply Leave / OD',
        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
    final yearBadge = _badge('Academic Year ${repo.selectedAcademicYear}');

    return Row(
      children: [
        Text(
          'Leave Application',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        const Spacer(),
        applyButton,
        const SizedBox(width: 12),
        yearBadge,
      ],
    );
  }

  Widget _heroBanner() {
    final applyButton = ElevatedButton.icon(
      onPressed: () => _showApplyLeaveDialog(),
      icon: const Icon(Icons.add_outlined, size: 16),
      label: Text(
        'Apply Leave / OD',
        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: const Border(
              left: BorderSide(color: Color(0xFF2563EB), width: 4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.calendar_today_outlined,
                            color: Color(0xFF2563EB),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Leave & OD Management',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Apply for leaves, track approval workflows, and monitor balances in one place.',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(width: double.infinity, child: applyButton),
                  ],
                )
              : Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.calendar_today_outlined,
                        color: Color(0xFF2563EB),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Leave & OD Management',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Apply for leaves, track approval workflows, and monitor balances in one place.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    applyButton,
                  ],
                ),
        );
      },
    );
  }

  String _calcFormattedDays(double val) {
    if (val % 1 == 0) return val.toInt().toString();
    return val.toStringAsFixed(1);
  }

  Map<String, double> _getApprovedDaysByType() {
    final map = <String, double>{
      'Casual Leave': 0.0,
      'Medical Leave': 0.0,
      'On Duty': 0.0,
      'Earned Leave': 0.0,
    };
    for (final app in repo.leaveApplications) {
      final status = (app['status']?.toString() ?? '').toLowerCase();
      if (status == 'approved' || status == 'hod approved') {
        final type = app['type']?.toString() ?? 'Casual Leave';
        final days = (app['days'] as num? ?? 1.0).toDouble();
        map[type] = (map[type] ?? 0.0) + days;
      }
    }
    return map;
  }

  Widget _buildStatCards() {
    final clBal =
        repo.leaveBalancesMap['Casual Leave'] ??
        {'total': 0.0, 'used': 0.0, 'remaining': 0.0};
    final mlBal =
        repo.leaveBalancesMap['Medical Leave'] ??
        repo.leaveBalancesMap['Sick Leave'] ??
        {'total': 0.0, 'used': 0.0, 'remaining': 0.0};
    final odBal =
        repo.leaveBalancesMap['On Duty'] ??
        {'total': 0.0, 'used': 0.0, 'remaining': 0.0};
    final elBal =
        repo.leaveBalancesMap['Earned Leave'] ??
        {'total': 0.0, 'used': 0.0, 'remaining': 0.0};

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;
        final cards = [
          _statCard(
            'Casual Leave',
            _calcFormattedDays(clBal['remaining']!),
            'Total: ${clBal['total']!.toInt()} Days (${_calcFormattedDays(clBal['used']!)} Used)',
            const Color(0xFFEFF6FF),
            const Color(0xFF2563EB),
            Icons.beach_access_outlined,
          ),
          _statCard(
            'Medical Leave',
            _calcFormattedDays(mlBal['remaining']!),
            'Total: ${mlBal['total']!.toInt()} Days (${_calcFormattedDays(mlBal['used']!)} Used)',
            const Color(0xFFECFDF5),
            const Color(0xFF059669),
            Icons.healing_outlined,
          ),
          _statCard(
            'On Duty',
            _calcFormattedDays(odBal['remaining']!),
            'Total: ${odBal['total']!.toInt()} Days (${_calcFormattedDays(odBal['used']!)} Used)',
            const Color(0xFFFFF7ED),
            const Color(0xFFEA580C),
            Icons.access_time_outlined,
          ),
          _statCard(
            'Earned Leave',
            _calcFormattedDays(elBal['remaining']!),
            'Total: ${elBal['total']!.toInt()} Days (${_calcFormattedDays(elBal['used']!)} Used)',
            const Color(0xFFF3E8FF),
            const Color(0xFF7C3AED),
            Icons.work_outline,
          ),
        ];

        if (isMobile) {
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: cards
                .map(
                  (c) => SizedBox(
                    width: (constraints.maxWidth - 12) / 2,
                    child: c,
                  ),
                )
                .toList(),
          );
        }

        return Row(
          children: cards
              .map(
                (c) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: c,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _statCard(
    String type,
    String rem,
    String detail,
    Color bg,
    Color fg,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                child: Icon(icon, size: 16, color: fg),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  type,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF334155),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (_isFetching) ...[
                const _SkeletonBox(width: 44, height: 26, borderRadius: 6),
                const Spacer(),
                const _SkeletonBox(width: 90, height: 12, borderRadius: 4),
              ] else ...[
                Text(
                  rem,
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: fg,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'LEFT',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: fg,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Text(
                  detail,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _applicationsTable() {
    final filtered = _filteredApps;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 750;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: _cardDecor(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isMobile) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.history,
                          color: Color(0xFF2563EB),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Application History',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    Tooltip(
                      message: 'Refresh Applications',
                      child: InkWell(
                        onTap: _isFetching
                            ? null
                            : () => _loadLeaveDataFast(showFeedback: true),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          height: 36,
                          width: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: _isFetching
                              ? LoadingAnimationWidget.hexagonDots(
                                  color: const Color(0xFF2563EB),
                                  size: 16,
                                )
                              : const Icon(
                                  Icons.refresh_outlined,
                                  size: 16,
                                  color: Color(0xFF2563EB),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _statusFilterDropdown(),
                    _sortDropdown(),
                    Container(
                      height: 36,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (_) => setState(() {}),
                        style: GoogleFonts.inter(fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'Search applications...',
                          hintStyle: GoogleFonts.inter(
                            color: const Color(0xFF94A3B8),
                            fontSize: 12,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            size: 16,
                            color: Color(0xFF94A3B8),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.history,
                          color: Color(0xFF2563EB),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Application History',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        _statusFilterDropdown(),
                        const SizedBox(width: 10),
                        _sortDropdown(),
                        const SizedBox(width: 10),
                        Container(
                          height: 38,
                          width: 240,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: (_) => setState(() {}),
                            style: GoogleFonts.inter(fontSize: 12),
                            decoration: InputDecoration(
                              hintText: 'Search applications...',
                              hintStyle: GoogleFonts.inter(
                                color: const Color(0xFF94A3B8),
                                fontSize: 12,
                              ),
                              prefixIcon: const Icon(
                                Icons.search,
                                size: 16,
                                color: Color(0xFF94A3B8),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Tooltip(
                          message: 'Refresh Applications',
                          child: InkWell(
                            onTap: _isFetching
                                ? null
                                : () => _loadLeaveDataFast(showFeedback: true),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              height: 38,
                              width: 38,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: _isFetching
                                  ? LoadingAnimationWidget.hexagonDots(
                                      color: const Color(0xFF2563EB),
                                      size: 16,
                                    )
                                  : const Icon(
                                      Icons.refresh_outlined,
                                      size: 18,
                                      color: Color(0xFF2563EB),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              if (_isFetching)
                const Padding(
                  padding: EdgeInsets.all(36),
                  child: FacultyLoadingWidget(),
                )
              else if (filtered.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.event_note_outlined,
                          size: 48,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No leave applications found',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Click "Apply Leave / OD" above to submit a new leave or OD application.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                LayoutBuilder(
                  builder: (context, tableConstraints) {
                    final double tableWidth = tableConstraints.maxWidth > 1080
                        ? tableConstraints.maxWidth
                        : 1080;

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: tableWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      'Leave Type',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      'Priority',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'From Date',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'To Date',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 65,
                                    child: Text(
                                      'Days',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      'Substitute',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      'Reason',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      'Status',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Applied On',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 65,
                                    child: Text(
                                      'Action',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ...filtered.map((app) => _appRow(app)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _appRow(Map<String, dynamic> app) {
    final statusStyle = _getStatusStyle(app['status']?.toString() ?? 'Pending');
    final isPending =
        (app['status']?.toString() ?? '').toLowerCase() == 'pending';
    final priority = app['priority']?.toString() ?? 'Normal';
    final isUrgent = priority.toLowerCase() == 'urgent';
    final subName =
        app['substituteFacultyId']?.toString() ??
        app['alternateFaculty']?.toString() ??
        'None';

    IconData icon = Icons.calendar_today_outlined;
    Color color = const Color(0xFF2563EB);
    if (app['type'] == 'Casual Leave') {
      icon = Icons.beach_access_outlined;
      color = const Color(0xFF2563EB);
    } else if (app['type'] == 'Medical Leave' || app['type'] == 'Sick Leave') {
      icon = Icons.healing_outlined;
      color = const Color(0xFF059669);
    } else if (app['type'] == 'On Duty') {
      icon = Icons.access_time_outlined;
      color = const Color(0xFFEA580C);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          // Leave Type
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 14, color: color),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    app['type'] as String? ?? 'Leave',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Priority
          SizedBox(
            width: 80,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isUrgent
                    ? const Color(0xFFFEF2F2)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                priority,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isUrgent
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF475569),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          // From Date
          Expanded(
            flex: 2,
            child: Text(
              _parseFriendlyDate(app['fromDate']?.toString()),
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF334155),
              ),
            ),
          ),
          // To Date
          Expanded(
            flex: 2,
            child: Text(
              _parseFriendlyDate(app['toDate']?.toString()),
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF334155),
              ),
            ),
          ),
          // Days
          SizedBox(
            width: 65,
            child: Text(
              '${(app['days'] as num? ?? 0).toInt()} Days',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF475569),
              ),
            ),
          ),
          // Substitute
          Expanded(
            flex: 3,
            child: Text(
              subName.isEmpty ? 'None' : subName,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF475569),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Reason
          Expanded(
            flex: 3,
            child: Text(
              app['reason'] as String? ?? '—',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF64748B),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Status
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusStyle['bg'],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusStyle['border']),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      statusStyle['icon'],
                      size: 12,
                      color: statusStyle['fg'],
                    ),
                    const SizedBox(width: 5),
                    Text(
                      statusStyle['label'],
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusStyle['fg'],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Applied On
          Expanded(
            flex: 2,
            child: Text(
              _parseFriendlyDate(
                app['appliedOn']?.toString() ?? app['createdAt']?.toString(),
              ),
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ),
          // Actions
          SizedBox(
            width: 65,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Color(0xFF2563EB),
                  ),
                  onPressed: () => _showDetailsDialog(app),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 30,
                    minHeight: 30,
                  ),
                ),
                if (isPending)
                  IconButton(
                    icon: const Icon(
                      Icons.cancel_outlined,
                      size: 16,
                      color: Colors.red,
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(
                            'Withdraw Application',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          content: Text(
                            'Are you sure you want to withdraw this leave application?',
                            style: GoogleFonts.inter(),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.inter(color: Colors.grey),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                final idToWithdraw =
                                    (app['id'] ?? app['leaveId'] ?? '')
                                        .toString();
                                Navigator.pop(ctx);
                                await repo.withdrawLeave(idToWithdraw);
                                await _loadLeaveDataFast();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Leave request withdrawn successfully.',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: Text(
                                'Withdraw',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 30,
                      minHeight: 30,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailsDialog(Map<String, dynamic> app) {
    final statusStyle = _getStatusStyle(app['status']?.toString() ?? 'Pending');
    final rawSubs = app['substitutions'] ?? app['substitutions_json'];
    final List substitutions = rawSubs is List ? rawSubs : [];

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          width: 640,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.85,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.description_outlined,
                      color: Color(0xFF2563EB),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Leave Application Details',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'ID: ${app['id'] ?? app['leaveId'] ?? 'LV001'}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusStyle['bg'],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusStyle['border']),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusStyle['icon'],
                          size: 14,
                          color: statusStyle['fg'],
                        ),
                        const SizedBox(width: 5),
                        Text(
                          statusStyle['label'],
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: statusStyle['fg'],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 16),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _detailCard(
                            'Leave Type',
                            app['type'] ?? 'Casual Leave',
                            Icons.beach_access_outlined,
                            const Color(0xFF2563EB),
                          ),
                          _detailCard(
                            'Priority',
                            app['priority'] ?? 'Normal',
                            Icons.flag_outlined,
                            const Color(0xFFD97706),
                          ),
                          _detailCard(
                            'From Date',
                            _parseFriendlyDate(app['fromDate']?.toString()),
                            Icons.calendar_today_outlined,
                            const Color(0xFF059669),
                          ),
                          _detailCard(
                            'To Date',
                            _parseFriendlyDate(app['toDate']?.toString()),
                            Icons.event_outlined,
                            const Color(0xFF059669),
                          ),
                          _detailCard(
                            'Working Days',
                            '${(app['days'] as num? ?? 1).toInt()} Working Day(s)',
                            Icons.timelapse_outlined,
                            const Color(0xFF2563EB),
                          ),
                          _detailCard(
                            'Applied Date',
                            _parseFriendlyDate(
                              app['appliedOn']?.toString() ??
                                  app['createdAt']?.toString(),
                            ),
                            Icons.access_time_outlined,
                            const Color(0xFF64748B),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Text(
                        'Reason for Leave',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          (app['reason'] != null &&
                                  app['reason'].toString().isNotEmpty)
                              ? app['reason'].toString()
                              : '—',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      Text(
                        'Approver Remarks',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          (app['remarks'] != null &&
                                  app['remarks'].toString().isNotEmpty)
                              ? app['remarks'].toString()
                              : 'No remarks provided yet.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),

                      // Supporting Document / Medical Certificate
                      if ((app['attachmentName']?.toString() ?? '')
                              .isNotEmpty ||
                          (app['attachmentUrl'] ?? app['document_url'] ?? '')
                              .toString()
                              .isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text(
                          'Supporting Document / Certificate',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.verified_outlined,
                                color: Color(0xFF16A34A),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  (app['attachmentName']?.toString() ?? '')
                                          .isNotEmpty
                                      ? app['attachmentName'].toString()
                                      : (app['attachmentUrl'] ??
                                                app['document_url'] ??
                                                '')
                                            .toString()
                                            .split('/')
                                            .last,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF15803D),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if ((app['attachmentUrl'] ??
                                      app['document_url'] ??
                                      '')
                                  .toString()
                                  .startsWith('http'))
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF16A34A),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Supabase Storage',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],

                      if (substitutions.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Assigned Class Substitutions',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Column(
                          children: substitutions.map((sub) {
                            final subMap = Map<String, dynamic>.from(
                              sub as Map,
                            );
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      subMap['period']?.toString() ?? 'P1',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF2563EB),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${subMap['subject'] ?? subMap['subjectCode'] ?? ''} (${subMap['classSec'] ?? ''})',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF0F172A),
                                          ),
                                        ),
                                        Text(
                                          'Substitute: ${subMap['substituteFaculty'] ?? subMap['substituteFacultyId'] ?? 'None'}',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: const Color(0xFF475569),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    subMap['date']?.toString() ?? '',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  child: Text(
                    'Close',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  void _showApplyLeaveDialog() {
    String selectedType = 'Casual Leave';
    String priority = 'Normal';
    String session = 'Full Day';
    bool isHalfDay = false;
    DateTime? fromDate;
    DateTime? toDate;

    int totalDaysCount = 0;
    int weekendDaysExcluded = 0;
    int holidaysExcluded = 0;
    int calculatedWorkingDays = 0;

    final reasonCtrl = TextEditingController();
    final remarksCtrl = TextEditingController();

    String alternateFaculty = 'None';
    final Map<String, String> substitutionAssignments = {};
    String hodName = (repo.profile['hodName']?.toString() ?? '').trim();
    bool declarationChecked = false;

    // Document attachment
    String? attachedFileName;
    String? attachedFileUrl;
    int attachedFileSize = 0;
    double uploadProgress = 0.0;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDlgState) {
            void updateDays() {
              if (fromDate != null && toDate != null) {
                if (toDate!.isBefore(fromDate!)) {
                  totalDaysCount = 0;
                  weekendDaysExcluded = 0;
                  calculatedWorkingDays = 0;
                  return;
                }
                int rawDays = toDate!.difference(fromDate!).inDays + 1;
                totalDaysCount = rawDays;

                int wDays = 0;
                for (int i = 0; i < rawDays; i++) {
                  DateTime check = fromDate!.add(Duration(days: i));
                  if (check.weekday == DateTime.saturday ||
                      check.weekday == DateTime.sunday) {
                    wDays++;
                  }
                }
                weekendDaysExcluded = wDays;
                holidaysExcluded = 0;
                int working = rawDays - weekendDaysExcluded - holidaysExcluded;
                if (isHalfDay || session != 'Full Day') {
                  working = (working > 0) ? working : 1;
                }
                calculatedWorkingDays = working < 0 ? 0 : working;
              } else {
                totalDaysCount = 0;
                weekendDaysExcluded = 0;
                calculatedWorkingDays = 0;
              }
            }

            final String facultyName =
                repo.profile['name']?.toString() ?? 'Mr. P. Kalaiyarasan';
            final String empId =
                repo.profile['employeeId']?.toString() ?? 'FAC002';
            final String dept =
                repo.profile['department']?.toString() ??
                'Information Technology';
            final String desig =
                repo.profile['designation']?.toString() ??
                'Assistant Professor';

            int currentBalance =
                repo.leaveBalances[selectedType] ??
                (selectedType == 'Sick Leave' || selectedType == 'Medical Leave'
                    ? 14
                    : (selectedType == 'Casual Leave'
                          ? 6
                          : (selectedType == 'Earned Leave'
                                ? 10
                                : (selectedType == 'On Duty'
                                      ? 4
                                      : (selectedType == 'Compensatory Leave'
                                            ? 3
                                            : 8)))));
            int remainingBalance = currentBalance - calculatedWorkingDays;
            final isSickLeave =
                selectedType == 'Sick Leave' || selectedType == 'Medical Leave';
            final isOnDuty = selectedType == 'On Duty';
            final showUploadSection = isSickLeave || isOnDuty;

            // ─── Timetable Substitution Calculation ───
            final List<DateTime> leaveDates = [];
            if (fromDate != null &&
                toDate != null &&
                !toDate!.isBefore(fromDate!)) {
              final count = toDate!.difference(fromDate!).inDays + 1;
              for (int i = 0; i < count; i++) {
                leaveDates.add(fromDate!.add(Duration(days: i)));
              }
            }

            final facultyTimetable = TimetableService.getByFaculty(empId);
            const weekdayNames = [
              'Monday',
              'Tuesday',
              'Wednesday',
              'Thursday',
              'Friday',
              'Saturday',
              'Sunday',
            ];

            String extractDept(String classSec, String subject) {
              final upper = '$classSec $subject'.toUpperCase();
              if (upper.contains('CSE') || upper.contains('COMPUTER SCIENCE'))
                return 'CSE';
              if (upper.contains('IT') ||
                  upper.contains('INFORMATION TECHNOLOGY'))
                return 'IT';
              if (upper.contains('ECE') || upper.contains('ELECTRONICS'))
                return 'ECE';
              if (upper.contains('EEE') || upper.contains('ELECTRICAL'))
                return 'EEE';
              if (upper.contains('MECH') || upper.contains('MECHANICAL'))
                return 'MECH';
              if (upper.contains('CIVIL')) return 'CIVIL';
              return dept;
            }

            final Map<DateTime, List<Map<String, dynamic>>> timetableByDate =
                {};
            int totalRequiredSubstitutions = 0;

            for (final d in leaveDates) {
              final dayName = weekdayNames[d.weekday - 1];
              final dayEntry = facultyTimetable.firstWhere(
                (item) =>
                    (item['day'] ?? '').toString().toLowerCase() ==
                    dayName.toLowerCase(),
                orElse: () => <String, dynamic>{},
              );
              final rawScheduleList = (dayEntry['schedule'] as List? ?? [])
                  .map((p) => Map<String, dynamic>.from(p as Map))
                  .where(
                    (p) => (p['subject'] ?? '').toString().trim().isNotEmpty,
                  )
                  .toList();

              final seenKeys = <String>{};
              final scheduleList = <Map<String, dynamic>>[];
              for (final p in rawScheduleList) {
                final key = "${p['period']}_${p['classSec']}_${p['subject']}"
                    .toUpperCase();
                if (!seenKeys.contains(key)) {
                  seenKeys.add(key);
                  scheduleList.add(p);
                }
              }

              timetableByDate[d] = scheduleList;
              totalRequiredSubstitutions += scheduleList.length;
            }

            bool allSubstitutionsComplete = true;
            if (fromDate != null &&
                toDate != null &&
                totalRequiredSubstitutions > 0) {
              for (final entry in timetableByDate.entries) {
                final d = entry.key;
                final dateIso =
                    "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
                for (final p in entry.value) {
                  final periodCode = p['period']?.toString() ?? 'P1';
                  final classSec = p['classSec']?.toString() ?? '';
                  final periodKey = "$dateIso|$periodCode|$classSec";
                  final assigned = substitutionAssignments[periodKey];
                  if (assigned == null ||
                      assigned.isEmpty ||
                      assigned == 'Select Faculty' ||
                      assigned == 'None') {
                    allSubstitutionsComplete = false;
                    break;
                  }
                }
                if (!allSubstitutionsComplete) break;
              }
            }

            final isFormValid =
                fromDate != null &&
                toDate != null &&
                !toDate!.isBefore(fromDate!) &&
                reasonCtrl.text.trim().isNotEmpty &&
                calculatedWorkingDays <= currentBalance &&
                (!showUploadSection || attachedFileName != null) &&
                (!declarationChecked ? false : true) &&
                (totalRequiredSubstitutions == 0 || allSubstitutionsComplete);

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              child: Container(
                width: 900,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.92,
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Modal Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.add_task_outlined,
                            color: Color(0xFF2563EB),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Apply Leave / On Duty Application',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(
                            Icons.close,
                            color: Color(0xFF64748B),
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 16),

                    // Scrollable Form Body
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ─── SECTION 1: APPLICANT PROFILE SUMMARY ───
                            _sectionHeader(
                              Icons.person_outline,
                              'SECTION 1: APPLICANT INFORMATION',
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Wrap(
                                spacing: 16,
                                runSpacing: 10,
                                children: [
                                  _infoChip(
                                    'Faculty Name',
                                    facultyName,
                                    Icons.person_pin_outlined,
                                  ),
                                  _infoChip(
                                    'Employee ID',
                                    empId,
                                    Icons.badge_outlined,
                                  ),
                                  _infoChip(
                                    'Department',
                                    dept,
                                    Icons.business_outlined,
                                  ),
                                  _infoChip(
                                    'Designation',
                                    desig,
                                    Icons.work_outline,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // ─── SECTION 2: LEAVE SPECIFICATIONS & DATES ───
                            _sectionHeader(
                              Icons.calendar_month_outlined,
                              'SECTION 2: LEAVE DETAILS & DURATION',
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
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
                                        [
                                          'Casual Leave',
                                          'Sick Leave',
                                          'Earned Leave',
                                          'On Duty',
                                          'Compensatory Leave',
                                          'Special Leave',
                                        ],
                                        selectedType,
                                        (v) {
                                          setDlgState(() {
                                            selectedType = v!;
                                            final today = DateTime.now();
                                            final todayMidnight = DateTime(
                                              today.year,
                                              today.month,
                                              today.day,
                                            );
                                            final isSick =
                                                selectedType == 'Sick Leave' ||
                                                selectedType == 'Medical Leave';
                                            final thirtyDaysAgo = todayMidnight
                                                .subtract(
                                                  const Duration(days: 30),
                                                );

                                            if (fromDate != null) {
                                              if (isSick) {
                                                if (fromDate!.isBefore(
                                                  thirtyDaysAgo,
                                                )) {
                                                  fromDate = null;
                                                }
                                              } else {
                                                if (fromDate!.isBefore(
                                                  todayMidnight,
                                                )) {
                                                  fromDate = null;
                                                }
                                              }
                                            }
                                            if (toDate != null) {
                                              if (isSick) {
                                                if (toDate!.isBefore(
                                                  thirtyDaysAgo,
                                                )) {
                                                  toDate = null;
                                                }
                                              } else {
                                                if (toDate!.isBefore(
                                                  todayMidnight,
                                                )) {
                                                  toDate = null;
                                                }
                                              }
                                            }
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
                                        hasError: fromDate == null,
                                        onTap: () async {
                                          final result =
                                              await PremiumDatePickerDialog.show(
                                                context: ctx,
                                                mode: PremiumDatePickerMode
                                                    .single,
                                                initialStartDate: fromDate,
                                                leaveType: selectedType,
                                                initialLeaveBalance:
                                                    repo.leaveBalances[selectedType] ??
                                                    8,
                                                existingLeaves:
                                                    repo.leaveApplications,
                                              );
                                          if (result != null &&
                                              result['start'] != null) {
                                            setDlgState(() {
                                              fromDate = result['start'];
                                              updateDays();
                                            });
                                          }
                                        },
                                      ),
                                      _datePickerField(
                                        'To Date *',
                                        toDate,
                                        (d) {},
                                        hasError: toDate == null,
                                        onTap: () async {
                                          final result =
                                              await PremiumDatePickerDialog.show(
                                                context: ctx,
                                                mode: PremiumDatePickerMode
                                                    .single,
                                                initialStartDate:
                                                    toDate ?? fromDate,
                                                leaveType: selectedType,
                                                initialLeaveBalance:
                                                    repo.leaveBalances[selectedType] ??
                                                    8,
                                                existingLeaves:
                                                    repo.leaveApplications,
                                              );
                                          if (result != null &&
                                              result['start'] != null) {
                                            setDlgState(() {
                                              toDate = result['start'];
                                              updateDays();
                                            });
                                          }
                                        },
                                      ),
                                      _modalDropdown(
                                        'Session',
                                        [
                                          'Full Day',
                                          'First Half',
                                          'Second Half',
                                        ],
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
                                  if (fromDate != null &&
                                      toDate != null &&
                                      toDate!.isBefore(fromDate!)) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.error_outline,
                                          color: Color(0xFFDC2626),
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'To Date cannot be before From Date.',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: const Color(0xFFDC2626),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: isHalfDay,
                                        onChanged: (v) {
                                          setDlgState(() {
                                            isHalfDay = v ?? false;
                                            if (isHalfDay &&
                                                session == 'Full Day') {
                                              session = 'First Half';
                                            } else if (!isHalfDay) {
                                              session = 'Full Day';
                                            }
                                            updateDays();
                                          });
                                        },
                                        activeColor: const Color(0xFF2563EB),
                                      ),
                                      Text(
                                        'Apply as Half Day (0.5 Day duration)',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: const Color(0xFF334155),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Auto-Calculated Summary Card
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: Wrap(
                                      spacing: 16,
                                      runSpacing: 10,
                                      alignment: WrapAlignment.spaceAround,
                                      children: [
                                        _calcStatItem(
                                          'Total Calendar Days',
                                          '$totalDaysCount Days',
                                          Colors.black87,
                                        ),
                                        _calcStatItem(
                                          'Weekends Excluded',
                                          '$weekendDaysExcluded Days',
                                          const Color(0xFFD97706),
                                        ),
                                        _calcStatItem(
                                          'Holidays Excluded',
                                          '$holidaysExcluded Days',
                                          const Color(0xFFD97706),
                                        ),
                                        _calcStatItem(
                                          'Net Working Days',
                                          '$calculatedWorkingDays Days',
                                          const Color(0xFF2563EB),
                                          isBold: true,
                                        ),
                                        _calcStatItem(
                                          'Remaining Balance',
                                          '$remainingBalance Days',
                                          remainingBalance < 0
                                              ? Colors.red
                                              : const Color(0xFF16A34A),
                                          isBold: true,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (fromDate != null &&
                                      toDate != null &&
                                      calculatedWorkingDays >
                                          currentBalance) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF2F2),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: const Color(0xFFFCA5A5),
                                        ),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Icon(
                                            Icons.warning_amber_rounded,
                                            color: Color(0xFFDC2626),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '⚠ Leave balance exceeded',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: const Color(
                                                      0xFF991B1B,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'You have only $currentBalance $selectedType days remaining, but you selected $calculatedWorkingDays days. Please reduce the selected leave duration.',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    color: const Color(
                                                      0xFFB91C1C,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // ─── SECTION 3: LEAVE BALANCE CARDS ───
                            _sectionHeader(
                              Icons.account_balance_wallet_outlined,
                              'SECTION 3: LEAVE BALANCE BREAKDOWN',
                            ),
                            const SizedBox(height: 10),
                            Builder(
                              builder: (context) {
                                final clBal =
                                    repo.leaveBalancesMap['Casual Leave'] ??
                                    {
                                      'total': 12.0,
                                      'used': 4.0,
                                      'remaining': 8.0,
                                    };
                                final mlBal =
                                    repo.leaveBalancesMap['Medical Leave'] ??
                                    repo.leaveBalancesMap['Sick Leave'] ??
                                    {
                                      'total': 10.0,
                                      'used': 1.0,
                                      'remaining': 9.0,
                                    };
                                final elBal =
                                    repo.leaveBalancesMap['Earned Leave'] ??
                                    {
                                      'total': 8.0,
                                      'used': 0.0,
                                      'remaining': 8.0,
                                    };
                                final odBal =
                                    repo.leaveBalancesMap['On Duty'] ??
                                    {
                                      'total': 15.0,
                                      'used': 4.0,
                                      'remaining': 11.0,
                                    };
                                final compBal =
                                    repo.leaveBalancesMap['Compensatory Leave'] ??
                                    {
                                      'total': 5.0,
                                      'used': 0.0,
                                      'remaining': 5.0,
                                    };

                                return Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    _balanceCard(
                                      'Casual Leave',
                                      clBal['total']!.toInt(),
                                      clBal['used']!.toInt(),
                                      clBal['remaining']!.toInt(),
                                      selectedType == 'Casual Leave',
                                    ),
                                    _balanceCard(
                                      'Sick Leave',
                                      mlBal['total']!.toInt(),
                                      mlBal['used']!.toInt(),
                                      mlBal['remaining']!.toInt(),
                                      selectedType == 'Sick Leave' ||
                                          selectedType == 'Medical Leave',
                                    ),
                                    _balanceCard(
                                      'Earned Leave',
                                      elBal['total']!.toInt(),
                                      elBal['used']!.toInt(),
                                      elBal['remaining']!.toInt(),
                                      selectedType == 'Earned Leave',
                                    ),
                                    _balanceCard(
                                      'On Duty (OD)',
                                      odBal['total']!.toInt(),
                                      odBal['used']!.toInt(),
                                      odBal['remaining']!.toInt(),
                                      selectedType == 'On Duty',
                                    ),
                                    _balanceCard(
                                      'Compensatory',
                                      compBal['total']!.toInt(),
                                      compBal['used']!.toInt(),
                                      compBal['remaining']!.toInt(),
                                      selectedType == 'Compensatory Leave',
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 20),

                            // ─── SECTION 4: REASON & REMARKS ───
                            _sectionHeader(
                              Icons.edit_note_outlined,
                              'SECTION 4: REASON & REMARKS',
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isOnDuty
                                        ? (reasonCtrl.text.trim().isEmpty
                                              ? 'Purpose of On Duty (OD) * (Required)'
                                              : 'Purpose of On Duty (OD) *')
                                        : (reasonCtrl.text.trim().isEmpty
                                              ? 'Reason for Leave * (Required)'
                                              : 'Reason for Leave *'),
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: reasonCtrl.text.trim().isEmpty
                                          ? const Color(0xFFDC2626)
                                          : const Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: reasonCtrl,
                                    maxLines: 2,
                                    onChanged: (_) => setDlgState(() {}),
                                    style: GoogleFonts.inter(fontSize: 12),
                                    decoration: InputDecoration(
                                      hintText: isOnDuty
                                          ? 'Enter official OD location, event name, and purpose...'
                                          : 'State specific reason for leave application...',
                                      hintStyle: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                      border: const OutlineInputBorder(),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    'Remarks / Additional Notes (Optional)',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: remarksCtrl,
                                    maxLines: 1,
                                    style: GoogleFonts.inter(fontSize: 12),
                                    decoration: InputDecoration(
                                      hintText:
                                          'Enter any additional remarks for HOD/Principal review...',
                                      hintStyle: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                      border: const OutlineInputBorder(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // ─── SECTION 5: SUPPORTING DOCUMENTS (DYNAMIC) ───
                            AnimatedSize(
                              duration: const Duration(milliseconds: 250),
                              child: showUploadSection
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _sectionHeader(
                                          Icons.attach_file_outlined,
                                          isSickLeave
                                              ? 'SECTION 5: MEDICAL CERTIFICATE (REQUIRED)'
                                              : 'SECTION 5: SUPPORTING DUTY ORDER (REQUIRED)',
                                        ),
                                        const SizedBox(height: 10),
                                        GestureDetector(
                                          onTap: () {
                                            if (isUploading) return;
                                            repo.triggerNativeUpload((
                                              name,
                                              size,
                                              dataUrl,
                                            ) {
                                              setDlgState(() {
                                                isUploading = true;
                                                attachedFileName = name;
                                                attachedFileSize = size;
                                                attachedFileUrl = null;
                                                uploadProgress = 0.2;
                                              });

                                              Future(() async {
                                                try {
                                                  if (dataUrl.contains(',')) {
                                                    final bytes = base64Decode(
                                                      dataUrl.substring(
                                                        dataUrl.indexOf(',') +
                                                            1,
                                                      ),
                                                    );
                                                    final safeName = name
                                                        .replaceAll(
                                                          RegExp(
                                                            r'[^A-Za-z0-9._-]',
                                                          ),
                                                          '_',
                                                        );
                                                    final bucket =
                                                        (selectedType ==
                                                                'Sick Leave' ||
                                                            selectedType ==
                                                                'Medical Leave')
                                                        ? 'medical_certificates'
                                                        : 'leave_documents';
                                                    final storagePath =
                                                        '$empId/${DateTime.now().millisecondsSinceEpoch}_$safeName';

                                                    setDlgState(() {
                                                      uploadProgress = 0.6;
                                                    });

                                                    final uploadedUrl =
                                                        await SupabaseClientHelper.uploadToStorage(
                                                          bucket,
                                                          storagePath,
                                                          bytes,
                                                          mimeType:
                                                              SupabaseClientHelper.mimeTypeFor(
                                                                name,
                                                              ),
                                                        );

                                                    if (uploadedUrl.startsWith(
                                                      'http',
                                                    )) {
                                                      setDlgState(() {
                                                        attachedFileUrl =
                                                            uploadedUrl;
                                                        uploadProgress = 1.0;
                                                        isUploading = false;
                                                      });
                                                      return;
                                                    }
                                                  }
                                                } catch (e) {
                                                  debugPrint(
                                                    'Document upload error: $e',
                                                  );
                                                }
                                                setDlgState(() {
                                                  uploadProgress = 1.0;
                                                  isUploading = false;
                                                });
                                              });
                                            });
                                          },
                                          child: Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF8FAFC),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: attachedFileUrl != null
                                                    ? const Color(0xFF16A34A)
                                                    : const Color(0xFFCBD5E1),
                                              ),
                                            ),
                                            child: attachedFileName == null
                                                ? Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      const Icon(
                                                        Icons
                                                            .cloud_upload_outlined,
                                                        color: Color(
                                                          0xFF2563EB,
                                                        ),
                                                        size: 24,
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            isSickLeave
                                                                ? 'Upload Medical Certificate (.PDF, .JPG, .PNG)'
                                                                : 'Upload Duty Order / Requisition Letter (.PDF, .JPG)',
                                                            style: GoogleFonts.inter(
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color:
                                                                  const Color(
                                                                    0xFF2563EB,
                                                                  ),
                                                            ),
                                                          ),
                                                          Text(
                                                            'Maximum file size: 10 MB (Stored in Supabase Bucket)',
                                                            style: GoogleFonts.inter(
                                                              fontSize: 10,
                                                              color:
                                                                  const Color(
                                                                    0xFF94A3B8,
                                                                  ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  )
                                                : Row(
                                                    children: [
                                                      Icon(
                                                        attachedFileUrl != null
                                                            ? Icons
                                                                  .check_circle_outline
                                                            : Icons
                                                                  .insert_drive_file_outlined,
                                                        color:
                                                            attachedFileUrl !=
                                                                null
                                                            ? const Color(
                                                                0xFF16A34A,
                                                              )
                                                            : const Color(
                                                                0xFF2563EB,
                                                              ),
                                                        size: 24,
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              attachedFileName!,
                                                              style: GoogleFonts.inter(
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color:
                                                                    const Color(
                                                                      0xFF334155,
                                                                    ),
                                                              ),
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                            Row(
                                                              children: [
                                                                Text(
                                                                  '${(attachedFileSize / 1024).toStringAsFixed(1)} KB',
                                                                  style: GoogleFonts.inter(
                                                                    fontSize:
                                                                        10,
                                                                    color: const Color(
                                                                      0xFF94A3B8,
                                                                    ),
                                                                  ),
                                                                ),
                                                                if (attachedFileUrl !=
                                                                    null) ...[
                                                                  const SizedBox(
                                                                    width: 8,
                                                                  ),
                                                                  Container(
                                                                    padding: const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          6,
                                                                      vertical:
                                                                          1,
                                                                    ),
                                                                    decoration: BoxDecoration(
                                                                      color: const Color(
                                                                        0xFFDCFCE7,
                                                                      ),
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            4,
                                                                          ),
                                                                    ),
                                                                    child: Text(
                                                                      '✓ Stored in Supabase Bucket',
                                                                      style: GoogleFonts.inter(
                                                                        fontSize:
                                                                            9,
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        color: const Color(
                                                                          0xFF15803D,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ],
                                                            ),
                                                            if (isUploading) ...[
                                                              const SizedBox(
                                                                height: 4,
                                                              ),
                                                              LinearProgressIndicator(
                                                                value:
                                                                    uploadProgress,
                                                                color:
                                                                    const Color(
                                                                      0xFF2563EB,
                                                                    ),
                                                                backgroundColor:
                                                                    Colors
                                                                        .grey[200],
                                                              ),
                                                            ],
                                                          ],
                                                        ),
                                                      ),
                                                      if (!isUploading)
                                                        IconButton(
                                                          onPressed: () =>
                                                              setDlgState(() {
                                                                attachedFileName =
                                                                    null;
                                                                attachedFileUrl =
                                                                    null;
                                                              }),
                                                          icon: const Icon(
                                                            Icons
                                                                .delete_outline,
                                                            color: Colors.red,
                                                            size: 18,
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                      ],
                                    )
                                  : const SizedBox.shrink(),
                            ),

                            // ─── SECTION 6: ALTERNATE FACULTY & APPROVAL WORKFLOW ───
                            _sectionHeader(
                              Icons.swap_calls_outlined,
                              'SECTION 6: ALTERNATE FACULTY & APPROVAL WORKFLOW',
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ── Timetable Substitution UI ──
                                  if (fromDate == null || toDate == null) ...[
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: const Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.info_outline,
                                            color: Color(0xFF2563EB),
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Select From Date and To Date above to automatically load scheduled classes requiring alternate faculty substitution.',
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: const Color(0xFF475569),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                  ] else if (totalRequiredSubstitutions ==
                                      0) ...[
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF0FDF4),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: const Color(0xFFBBF7D0),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.check_circle_outline,
                                            color: Color(0xFF16A34A),
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'No classes scheduled — no alternate faculty required for the selected leave dates.',
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xFF15803D),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                  ] else ...[
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEFF6FF),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color: const Color(0xFFBFDBFE),
                                            ),
                                          ),
                                          child: Text(
                                            '$totalRequiredSubstitutions ${totalRequiredSubstitutions == 1 ? "class requires" : "classes require"} alternate faculty',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF2563EB),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),

                                    // Grouped date sections for substitution
                                    ...leaveDates.map((dateItem) {
                                      final dateIso =
                                          "${dateItem.year}-${dateItem.month.toString().padLeft(2, '0')}-${dateItem.day.toString().padLeft(2, '0')}";
                                      final dayName =
                                          weekdayNames[dateItem.weekday - 1];
                                      final periodsForDay =
                                          timetableByDate[dateItem] ?? [];
                                      final formattedShortDate =
                                          _formatShortDate(dateItem);

                                      return Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 14,
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Date Header
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.calendar_today_outlined,
                                                  size: 14,
                                                  color: Color(0xFF2563EB),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  '$dayName, $formattedShortDate',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    color: const Color(
                                                      0xFF0F172A,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),

                                            if (periodsForDay.isEmpty) ...[
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 4,
                                                    ),
                                                child: Text(
                                                  'No scheduled classes for this date.',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 11,
                                                    fontStyle: FontStyle.italic,
                                                    color: const Color(
                                                      0xFF94A3B8,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ] else ...[
                                              ...periodsForDay.map((p) {
                                                final periodCode =
                                                    p['period']?.toString() ??
                                                    'P1';
                                                final classSec =
                                                    p['classSec']?.toString() ??
                                                    '';
                                                final subject =
                                                    p['subject']?.toString() ??
                                                    '';
                                                final code =
                                                    p['code']?.toString() ?? '';
                                                final room =
                                                    p['room']?.toString() ?? '';
                                                final time =
                                                    p['time']?.toString() ?? '';
                                                final periodKey =
                                                    "$dateIso|$periodCode|$classSec";
                                                final classDept = extractDept(
                                                  classSec,
                                                  subject,
                                                );

                                                final currentSelection =
                                                    substitutionAssignments[periodKey];
                                                final isMissingAssignment =
                                                    currentSelection == null ||
                                                    currentSelection.isEmpty;

                                                // Filter department faculties
                                                final eligibleFacs =
                                                    _deptFaculties.where((f) {
                                                      final fDept =
                                                          (f['department'] ??
                                                                  '')
                                                              .toString()
                                                              .trim()
                                                              .toUpperCase();
                                                      final targetDept =
                                                          classDept
                                                              .toUpperCase();
                                                      return fDept ==
                                                              targetDept ||
                                                          fDept.contains(
                                                            targetDept,
                                                          ) ||
                                                          targetDept.contains(
                                                            fDept,
                                                          );
                                                    }).toList();

                                                final availableOptions =
                                                    (eligibleFacs.isNotEmpty
                                                            ? eligibleFacs
                                                            : _deptFaculties)
                                                        .where(
                                                          (f) =>
                                                              f['id'] != empId,
                                                        )
                                                        .toList();

                                                return Container(
                                                  margin: const EdgeInsets.only(
                                                    bottom: 8,
                                                  ),
                                                  padding: const EdgeInsets.all(
                                                    10,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                    border: Border.all(
                                                      color: isMissingAssignment
                                                          ? const Color(
                                                              0xFFFCA5A5,
                                                            )
                                                          : const Color(
                                                              0xFFCBD5E1,
                                                            ),
                                                      width: isMissingAssignment
                                                          ? 1.5
                                                          : 1.0,
                                                    ),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      LayoutBuilder(
                                                        builder: (ctx, constraints) {
                                                          final isCompact =
                                                              constraints
                                                                  .maxWidth <
                                                              600;

                                                          final infoWidget = Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Row(
                                                                children: [
                                                                  Container(
                                                                    padding: const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          6,
                                                                      vertical:
                                                                          2,
                                                                    ),
                                                                    decoration: BoxDecoration(
                                                                      color: const Color(
                                                                        0xFFEFF6FF,
                                                                      ),
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            4,
                                                                          ),
                                                                    ),
                                                                    child: Text(
                                                                      '$periodCode ${time.isNotEmpty ? "($time)" : ""}',
                                                                      style: GoogleFonts.inter(
                                                                        fontSize:
                                                                            10,
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        color: const Color(
                                                                          0xFF2563EB,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 8,
                                                                  ),
                                                                  Expanded(
                                                                    child: Text(
                                                                      subject +
                                                                          (code.isNotEmpty
                                                                              ? ' ($code)'
                                                                              : ''),
                                                                      style: GoogleFonts.inter(
                                                                        fontSize:
                                                                            12,
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        color: const Color(
                                                                          0xFF0F172A,
                                                                        ),
                                                                      ),
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              const SizedBox(
                                                                height: 4,
                                                              ),
                                                              Row(
                                                                children: [
                                                                  Text(
                                                                    'Class: $classSec',
                                                                    style: GoogleFonts.inter(
                                                                      fontSize:
                                                                          11,
                                                                      color: const Color(
                                                                        0xFF475569,
                                                                      ),
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
                                                                    ),
                                                                  ),
                                                                  if (room
                                                                      .isNotEmpty) ...[
                                                                    Text(
                                                                      '  •  ',
                                                                      style: GoogleFonts.inter(
                                                                        fontSize:
                                                                            11,
                                                                        color: const Color(
                                                                          0xFF94A3B8,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    Text(
                                                                      'Room: $room',
                                                                      style: GoogleFonts.inter(
                                                                        fontSize:
                                                                            11,
                                                                        color: const Color(
                                                                          0xFF64748B,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                  Text(
                                                                    '  •  ',
                                                                    style: GoogleFonts.inter(
                                                                      fontSize:
                                                                          11,
                                                                      color: const Color(
                                                                        0xFF94A3B8,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  Container(
                                                                    padding: const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          5,
                                                                      vertical:
                                                                          1,
                                                                    ),
                                                                    decoration: BoxDecoration(
                                                                      color: const Color(
                                                                        0xFFF1F5F9,
                                                                      ),
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            3,
                                                                          ),
                                                                    ),
                                                                    child: Text(
                                                                      'Dept: $classDept',
                                                                      style: GoogleFonts.inter(
                                                                        fontSize:
                                                                            9,
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        color: const Color(
                                                                          0xFF475569,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ],
                                                          );

                                                          final dropdownWidget = SizedBox(
                                                            width: isCompact
                                                                ? double
                                                                      .infinity
                                                                : 280,
                                                            child: DropdownButtonFormField<String>(
                                                              value:
                                                                  availableOptions.any(
                                                                    (f) =>
                                                                        (f['label'] ??
                                                                            f['name']) ==
                                                                        currentSelection,
                                                                  )
                                                                  ? currentSelection
                                                                  : null,
                                                              hint: Text(
                                                                'Select Alternate Faculty',
                                                                style: GoogleFonts.inter(
                                                                  fontSize: 11,
                                                                  color: const Color(
                                                                    0xFF94A3B8,
                                                                  ),
                                                                ),
                                                              ),
                                                              items: availableOptions.map((
                                                                f,
                                                              ) {
                                                                final label =
                                                                    f['label'] ??
                                                                    f['name'] ??
                                                                    f['id']!;
                                                                return DropdownMenuItem<
                                                                  String
                                                                >(
                                                                  value: label,
                                                                  child: Text(
                                                                    label,
                                                                    style: GoogleFonts.inter(
                                                                      fontSize:
                                                                          11,
                                                                      color: const Color(
                                                                        0xFF0F172A,
                                                                      ),
                                                                    ),
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                );
                                                              }).toList(),
                                                              onChanged: (val) {
                                                                if (val !=
                                                                    null) {
                                                                  setDlgState(() {
                                                                    substitutionAssignments[periodKey] =
                                                                        val;
                                                                  });
                                                                }
                                                              },
                                                              decoration: InputDecoration(
                                                                contentPadding:
                                                                    const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          10,
                                                                      vertical:
                                                                          8,
                                                                    ),
                                                                isDense: true,
                                                                fillColor:
                                                                    isMissingAssignment
                                                                    ? const Color(
                                                                        0xFFFEF2F2,
                                                                      )
                                                                    : Colors
                                                                          .white,
                                                                filled: true,
                                                                border: OutlineInputBorder(
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        6,
                                                                      ),
                                                                  borderSide: BorderSide(
                                                                    color:
                                                                        isMissingAssignment
                                                                        ? const Color(
                                                                            0xFFEF4444,
                                                                          )
                                                                        : const Color(
                                                                            0xFFCBD5E1,
                                                                          ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          );

                                                          if (isCompact) {
                                                            return Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                infoWidget,
                                                                const SizedBox(
                                                                  height: 8,
                                                                ),
                                                                dropdownWidget,
                                                              ],
                                                            );
                                                          }

                                                          return Row(
                                                            children: [
                                                              Expanded(
                                                                child:
                                                                    infoWidget,
                                                              ),
                                                              const SizedBox(
                                                                width: 12,
                                                              ),
                                                              dropdownWidget,
                                                            ],
                                                          );
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }),
                                            ],
                                          ],
                                        ),
                                      );
                                    }),

                                    if (!allSubstitutionsComplete) ...[
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEF2F2),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFFFCA5A5),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.warning_amber_rounded,
                                              color: Color(0xFFDC2626),
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Please assign an alternate faculty for all scheduled classes before submitting the leave application.',
                                                style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(
                                                    0xFF991B1B,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                    ],
                                  ],
                                  const SizedBox(height: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Assigned HOD Approver',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF64748B),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFFE2E8F0),
                                          ),
                                        ),
                                        child: Text(
                                          hodName,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF0F172A),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Sequential Approval Workflow:',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 8,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      _workflowStep(
                                        'Faculty',
                                        'Submitted',
                                        const Color(0xFF2563EB),
                                        true,
                                      ),
                                      _workflowConnector(),
                                      _workflowStep(
                                        'HOD Approval',
                                        'Pending Review',
                                        const Color(0xFFD97706),
                                        false,
                                      ),
                                      _workflowConnector(),
                                      _workflowStep(
                                        'Principal Approval',
                                        calculatedWorkingDays > 3
                                            ? 'Required (>3 Days)'
                                            : 'Configured',
                                        const Color(0xFF64748B),
                                        false,
                                      ),
                                      _workflowConnector(),
                                      _workflowStep(
                                        'Approved',
                                        'Final Sanction',
                                        const Color(0xFF16A34A),
                                        false,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // ─── SECTION 7: DECLARATION ───
                            _sectionHeader(
                              Icons.verified_user_outlined,
                              'SECTION 7: DECLARATION & CONFIRMATION',
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: declarationChecked,
                                    onChanged: (v) => setDlgState(
                                      () => declarationChecked = v ?? false,
                                    ),
                                    activeColor: const Color(0xFF2563EB),
                                  ),
                                  Expanded(
                                    child: Text(
                                      'I confirm that the information provided is correct and class substitution arrangements have been coordinated.',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (fromDate != null &&
                        toDate != null &&
                        calculatedWorkingDays > currentBalance) ...[
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Color(0xFFDC2626),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '⚠ Leave balance exceeded: You have only $currentBalance $selectedType days remaining, but you selected $calculatedWorkingDays days. Please reduce the selected leave duration.',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF991B1B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

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
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF64748B),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () {
                            if (reasonCtrl.text.trim().isEmpty) {
                              _showErrorMsg(
                                'Reason is required to save draft.',
                              );
                              return;
                            }
                            final draft = {
                              'id': 'LV00${repo.leaveApplications.length + 1}',
                              'type': selectedType,
                              'fromDate': fromDate != null
                                  ? _formatDate(fromDate!)
                                  : '\u2014',
                              'toDate': toDate != null
                                  ? _formatDate(toDate!)
                                  : '\u2014',
                              'days': calculatedWorkingDays.toDouble(),
                              'reason': reasonCtrl.text,
                              'status': 'Draft',
                              'remarks': 'Saved as draft',
                            };
                            repo.applyLeave(draft);
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Draft saved successfully.'),
                                backgroundColor: Colors.grey,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2563EB),
                            side: const BorderSide(color: Color(0xFFBFDBFE)),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          child: Text(
                            'Save Draft',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: isFormValid
                              ? () async {
                                  final List<Map<String, dynamic>>
                                  substitutionsList = [];
                                  for (final entry in timetableByDate.entries) {
                                    final d = entry.key;
                                    final dateIso =
                                        "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
                                    for (final p in entry.value) {
                                      final periodCode =
                                          p['period']?.toString() ?? 'P1';
                                      final classSec =
                                          p['classSec']?.toString() ?? '';
                                      final subject =
                                          p['subject']?.toString() ?? '';
                                      final code = p['code']?.toString() ?? '';
                                      final room = p['room']?.toString() ?? '';
                                      final time = p['time']?.toString() ?? '';
                                      final periodKey =
                                          "$dateIso|$periodCode|$classSec";
                                      final assignedLabel =
                                          substitutionAssignments[periodKey] ??
                                          '';

                                      final matchedFac = _deptFaculties
                                          .firstWhere(
                                            (f) =>
                                                (f['label'] ?? f['name']) ==
                                                assignedLabel,
                                            orElse: () => <String, String>{
                                              'id': assignedLabel,
                                              'name': assignedLabel,
                                            },
                                          );

                                      substitutionsList.add({
                                        'date': dateIso,
                                        'period': periodCode,
                                        'classSec': classSec,
                                        'subject': subject,
                                        'subjectCode': code,
                                        'room': room,
                                        'time': time,
                                        'substituteFaculty': assignedLabel,
                                        'substituteFacultyId':
                                            matchedFac['id'] ?? assignedLabel,
                                      });
                                    }
                                  }

                                  final newLeave = {
                                    'facultyId':
                                        repo.profile['employeeId'] ??
                                        repo.profile['facultyId'] ??
                                        'FAC002',
                                    'hodEmployeeId': 'HOD-CSE-001',
                                    'type': selectedType,
                                    'priority': priority,
                                    'session': session,
                                    'isHalfDay': isHalfDay,
                                    'fromDate': _formatDate(fromDate!),
                                    'toDate': _formatDate(toDate!),
                                    'totalCalendarDays': totalDaysCount,
                                    'weekendDaysExcluded': weekendDaysExcluded,
                                    'holidaysExcluded': holidaysExcluded,
                                    'days': calculatedWorkingDays.toDouble(),
                                    'reason': reasonCtrl.text.trim(),
                                    'status': 'Pending',
                                    'submissionStatus': 'Submitted',
                                    'appliedOn': _formatDate(DateTime.now()),
                                    'createdAt': DateTime.now()
                                        .toIso8601String(),
                                    'remarks': remarksCtrl.text.trim().isEmpty
                                        ? 'Submitted for HOD review'
                                        : remarksCtrl.text.trim(),
                                    'substituteFacultyId': alternateFaculty,
                                    'alternateFaculty': alternateFaculty,
                                    'attachmentName': attachedFileName,
                                    'attachmentUrl':
                                        attachedFileUrl ?? attachedFileName,
                                    'document_url':
                                        attachedFileUrl ?? attachedFileName,
                                    'academicYear': repo.selectedAcademicYear,
                                    'substitutions': substitutionsList,
                                  };

                                  Navigator.pop(ctx);
                                  repo.applyLeave(newLeave);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Leave application submitted to HOD (HOD-CSE-001) successfully!',
                                      ),
                                      backgroundColor: Color(0xFF16A34A),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );

                                  LeaveService.apply(newLeave).then((_) {
                                    _loadLeaveDataFast();
                                  });
                                }
                              : null,
                          icon: const Icon(Icons.send_outlined, size: 14),
                          label: Text(
                            'Submit Application',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
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

  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF2563EB)),
        const SizedBox(width: 6),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _infoChip(String label, String value, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF64748B)),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _calcStatItem(
    String label,
    String value,
    Color color, {
    bool isBold = false,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _balanceCard(
    String type,
    int avail,
    int applied,
    int rem,
    bool isSelected,
  ) {
    return Container(
      width: 155,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            type,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? const Color(0xFF2563EB)
                  : const Color(0xFF0F172A),
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Avail: $avail',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  color: const Color(0xFF64748B),
                ),
              ),
              Text(
                'Applied: $applied',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Rem: $rem Days',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF16A34A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _workflowStep(String title, String status, Color color, bool isDone) {
    return Row(
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
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            Text(
              status,
              style: GoogleFonts.inter(
                fontSize: 9,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _workflowConnector() {
    return Container(
      width: 24,
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: const Color(0xFFCBD5E1),
    );
  }

  Widget _modalDropdown(
    String label,
    List<String> items,
    String currentVal,
    ValueChanged<String?> onChange,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: currentVal,
      items: items
          .map(
            (i) => DropdownMenuItem(
              value: i,
              child: Text(i, style: GoogleFonts.inter(fontSize: 12)),
            ),
          )
          .toList(),
      onChanged: onChange,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(
          fontSize: 11,
          color: const Color(0xFF64748B),
        ),
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }

  Widget _datePickerField(
    String label,
    DateTime? date,
    ValueChanged<DateTime?> onSelect, {
    VoidCallback? onTap,
    bool hasError = false,
  }) {
    final displayStr = date != null ? _formatDate(date) : '-- Select Date --';
    return SizedBox(
      width: 240,
      child: InkWell(
        onTap:
            onTap ??
            () async {
              final result = await PremiumDatePickerDialog.show(
                context: context,
                mode: PremiumDatePickerMode.single,
                initialStartDate: date ?? DateTime.now(),
                existingLeaves: repo.leaveApplications,
              );
              if (result != null && result['start'] != null) {
                onSelect(result['start']);
              }
            },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: hasError ? '$label (Required)' : label,
            labelStyle: GoogleFonts.inter(
              fontSize: 11,
              color: hasError
                  ? const Color(0xFFDC2626)
                  : const Color(0xFF64748B),
              fontWeight: hasError ? FontWeight.bold : FontWeight.normal,
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(
                color: hasError
                    ? const Color(0xFFDC2626)
                    : const Color(0xFFCBD5E1),
              ),
            ),
            isDense: true,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  displayStr,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: date != null
                        ? const Color(0xFF0F172A)
                        : const Color(0xFF94A3B8),
                  ),
                ),
              ),
              Icon(
                Icons.calendar_month_outlined,
                size: 16,
                color: hasError
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF64748B),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorMsg(String msg) {
    // Inlined into input label text per requirement
  }

  Widget _statusFilterDropdown() {
    final items = ['All Status', 'Pending', 'Approved', 'Rejected'];
    final validVal = items.contains(_selectedFilter)
        ? _selectedFilter
        : items.first;

    return PopupMenuButton<String>(
      tooltip: '',
      position: PopupMenuPosition.under,
      offset: const Offset(0, 4),
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      initialValue: validVal,
      onSelected: (v) {
        setState(() => _selectedFilter = v);
      },
      itemBuilder: (context) {
        return items.map((item) {
          final bool isSelected = item == validVal;
          return PopupMenuItem<String>(
            value: item,
            height: 38,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Text(
                item,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF334155),
                ),
              ),
            ),
          );
        }).toList();
      },
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              validVal,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF334155),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.filter_alt_outlined,
              size: 14,
              color: Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatusStyle(String rawStatus) {
    final status = rawStatus.trim().toLowerCase();
    if (status == 'approved' ||
        status == 'hod approved' ||
        status == 'final sanction') {
      return {
        'bg': const Color(0xFFECFDF5),
        'fg': const Color(0xFF16A34A),
        'border': const Color(0xFFA7F3D0),
        'icon': Icons.check_circle_outline,
        'label': 'APPROVED',
      };
    } else if (status.contains('reject')) {
      return {
        'bg': const Color(0xFFFEF2F2),
        'fg': const Color(0xFFDC2626),
        'border': const Color(0xFFFCA5A5),
        'icon': Icons.cancel_outlined,
        'label': 'REJECTED',
      };
    } else if (status.contains('draft')) {
      return {
        'bg': const Color(0xFFF1F5F9),
        'fg': const Color(0xFF475569),
        'border': const Color(0xFFCBD5E1),
        'icon': Icons.edit_note_outlined,
        'label': 'DRAFT',
      };
    } else {
      return {
        'bg': const Color(0xFFFFFBEB),
        'fg': const Color(0xFFD97706),
        'border': const Color(0xFFFDE68A),
        'icon': Icons.access_time,
        'label': rawStatus.toUpperCase().contains('PENDING')
            ? rawStatus.toUpperCase()
            : 'PENDING',
      };
    }
  }

  Widget _sortDropdown() {
    final items = [
      'Latest First',
      'Oldest First',
      'Leave Date (Newest First)',
      'Leave Date (Oldest First)',
      'Duration (High to Low)',
      'Duration (Low to High)',
    ];
    final validVal = items.contains(_selectedSort)
        ? _selectedSort
        : items.first;

    return PopupMenuButton<String>(
      tooltip: '',
      position: PopupMenuPosition.under,
      offset: const Offset(0, 4),
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      initialValue: validVal,
      onSelected: (v) {
        setState(() => _selectedSort = v);
      },
      itemBuilder: (context) {
        return items.map((item) {
          final bool isSelected = item == validVal;
          return PopupMenuItem<String>(
            value: item,
            height: 38,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Text(
                item,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF334155),
                ),
              ),
            ),
          );
        }).toList();
      },
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              validVal,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF334155),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.sort_outlined, size: 14, color: Color(0xFF2563EB)),
          ],
        ),
      ),
    );
  }

  Widget _detailCard(String label, String val, IconData icon, Color color) {
    return Container(
      width: 185,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: const Color(0xFF94A3B8),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  val,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
  }

  // Converts stored date strings (YYYY-MM-DD, ISO, DD MMM YYYY) to 'DD MMM YYYY'
  String _parseFriendlyDate(String? raw) {
    if (raw == null || raw.isEmpty || raw == '—') return '—';
    try {
      // Already formatted as DD MMM YYYY
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final parts = raw.split(' ');
      if (parts.length == 3 && months.contains(parts[1])) return raw;
      // ISO or YYYY-MM-DD
      final dt = DateTime.parse(raw.split('T')[0]);
      return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  Widget _bc(String t, {bool active = false}) => Text(
    t,
    style: GoogleFonts.inter(
      fontSize: 12,
      color: active ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
      fontWeight: active ? FontWeight.w600 : FontWeight.normal,
    ),
  );

  Widget _badge(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFFEFF6FF),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFBFDBFE)),
    ),
    child: Text(
      text,
      style: GoogleFonts.inter(
        color: const Color(0xFF2563EB),
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    ),
  );

  BoxDecoration _cardDecor() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: const Color(0xFFE5E7EB)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  String _formatShortDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
  }
}

/// Pulsing Skeleton Loader Widget for analytical cards
class _SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const _SkeletonBox({
    required this.width,
    required this.height,
    this.borderRadius = 4,
  });

  @override
  State<_SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<_SkeletonBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(
      begin: 0.35,
      end: 0.85,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: const Color(0xFFCBD5E1),
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}
