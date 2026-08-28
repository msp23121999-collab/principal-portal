// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../erp_repository.dart';
import '../widgets/faculty_loading.dart';
import '../services/grievances_service.dart';

/// Grievances View (Faculty Portal — Index 21)
/// Evaluates and responds to student complaints addressed to Faculty / Mentor Faculty.
class GrievancesView extends StatefulWidget {
  const GrievancesView({super.key});

  @override
  State<GrievancesView> createState() => _GrievancesViewState();
}

class _GrievancesViewState extends State<GrievancesView> {
  final repo = ErpRepository();

  bool _isLoading = true;
  List<Map<String, dynamic>> _allGrievances = [];

  // Filter controllers & states
  String _selectedCategory = 'All Categories';
  String _selectedStatus = 'All Statuses';
  String _selectedPriority = 'All Priorities';
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadGrievances();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadGrievances({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() => _isLoading = true);
    }
    final facId =
        repo.profile['employeeId']?.toString() ??
        repo.profile['facultyId']?.toString() ??
        'EMP_CSE_002';
    final list = await GrievancesService.fetchFacultyGrievances(
      facultyId: facId,
    );
    if (mounted) {
      setState(() {
        _allGrievances = list;
        _isLoading = false;
      });
    }
  }

  // ── Filtered List ─────────────────────────────────────────────────────────
  List<Map<String, dynamic>> get _filteredGrievances {
    final q = _searchQuery.toLowerCase().trim();
    return _allGrievances.where((g) {
      final category = (g['category'] ?? '').toString();
      final status = (g['status'] ?? '').toString();
      final priority = (g['priority'] ?? '').toString();
      final subject = (g['subject'] ?? '').toString().toLowerCase();
      final desc = (g['description'] ?? '').toString().toLowerCase();
      final name = (g['studentName'] ?? '').toString().toLowerCase();
      final roll = (g['studentRoll'] ?? '').toString().toLowerCase();

      final matchesCategory =
          _selectedCategory == 'All Categories' ||
          category == _selectedCategory;
      final matchesStatus =
          _selectedStatus == 'All Statuses' || status == _selectedStatus;
      final matchesPriority =
          _selectedPriority == 'All Priorities' ||
          priority == _selectedPriority;
      final matchesSearch =
          q.isEmpty ||
          subject.contains(q) ||
          desc.contains(q) ||
          name.contains(q) ||
          roll.contains(q);

      return matchesCategory &&
          matchesStatus &&
          matchesPriority &&
          matchesSearch;
    }).toList();
  }

  // ── Stats ──────────────────────────────────────────────────────────────────
  int get _totalCount => _filteredGrievances.length;
  int get _pendingCount =>
      _filteredGrievances.where((g) => g['status'] == 'Pending').length;
  int get _inReviewCount =>
      _filteredGrievances.where((g) => g['status'] == 'In Review').length;
  int get _resolvedCount =>
      _filteredGrievances.where((g) => g['status'] == 'Resolved').length;

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        if (_isLoading) {
          return const FacultyLoadingWidget();
        }

        final grievances = _filteredGrievances;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _pageHeader(),
            const SizedBox(height: 20),
            _statsRow(),
            const SizedBox(height: 20),
            _mainCard(grievances),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }

  Widget _pageHeader() {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Student Grievances',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Review and respond to grievances addressed directly to Faculty & Mentors',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Text(
            'Academic Year ${repo.selectedAcademicYear}',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2563EB),
            ),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          tooltip: 'Refresh Grievances',
          icon: const Icon(Icons.refresh, size: 20, color: Color(0xFF2563EB)),
          onPressed: () => _loadGrievances(showLoading: true),
        ),
      ],
    );
  }

  // ── Stat Pills Row ────────────────────────────────────────────────────────
  Widget _statsRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 650) {
          return Row(
            children: [
              Expanded(
                child: _statPill(
                  Icons.gavel_outlined,
                  const Color(0xFF6366F1),
                  const Color(0xFFEEF2FF),
                  'Total Complaints',
                  '$_totalCount',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _statPill(
                  Icons.hourglass_top_outlined,
                  const Color(0xFFF59E0B),
                  const Color(0xFFFFFBEB),
                  'Pending Action',
                  '$_pendingCount',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _statPill(
                  Icons.rate_review_outlined,
                  const Color(0xFF2563EB),
                  const Color(0xFFEFF6FF),
                  'In Review',
                  '$_inReviewCount',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _statPill(
                  Icons.check_circle_outline,
                  const Color(0xFF10B981),
                  const Color(0xFFECFDF5),
                  'Resolved',
                  '$_resolvedCount',
                ),
              ),
            ],
          );
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              SizedBox(
                width: 180,
                child: _statPill(
                  Icons.gavel_outlined,
                  const Color(0xFF6366F1),
                  const Color(0xFFEEF2FF),
                  'Total Complaints',
                  '$_totalCount',
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 180,
                child: _statPill(
                  Icons.hourglass_top_outlined,
                  const Color(0xFFF59E0B),
                  const Color(0xFFFFFBEB),
                  'Pending Action',
                  '$_pendingCount',
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 180,
                child: _statPill(
                  Icons.rate_review_outlined,
                  const Color(0xFF2563EB),
                  const Color(0xFFEFF6FF),
                  'In Review',
                  '$_inReviewCount',
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 180,
                child: _statPill(
                  Icons.check_circle_outline,
                  const Color(0xFF10B981),
                  const Color(0xFFECFDF5),
                  'Resolved',
                  '$_resolvedCount',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statPill(
    IconData icon,
    Color fg,
    Color bg,
    String label,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 22, color: fg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Main Card ──────────────────────────────────────────────────────────────
  Widget _mainCard(List<Map<String, dynamic>> grievances) {
    final categories = [
      'All Categories',
      'Academic',
      'Infrastructure',
      'Hostel',
      'Admin',
      'Fee',
      'General',
    ];
    final statuses = [
      'All Statuses',
      'Pending',
      'In Review',
      'Resolved',
      'Rejected',
    ];
    final priorities = ['All Priorities', 'High', 'Medium', 'Low'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Toolbar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Search Input
                SizedBox(
                  width: 240,
                  height: 40,
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: GoogleFonts.inter(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search grievances...',
                      hintStyle: GoogleFonts.inter(
                        color: const Color(0xFF94A3B8),
                        fontSize: 12,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        size: 16,
                        color: Color(0xFF94A3B8),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                  ),
                ),
                _dropdownFilter(
                  'Category',
                  categories,
                  _selectedCategory,
                  (v) => setState(() => _selectedCategory = v!),
                ),
                _dropdownFilter(
                  'Status',
                  statuses,
                  _selectedStatus,
                  (v) => setState(() => _selectedStatus = v!),
                ),
                _dropdownFilter(
                  'Priority',
                  priorities,
                  _selectedPriority,
                  (v) => setState(() => _selectedPriority = v!),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedCategory = 'All Categories';
                      _selectedStatus = 'All Statuses';
                      _selectedPriority = 'All Priorities';
                      _searchCtrl.clear();
                      _searchQuery = '';
                    });
                  },
                  icon: const Icon(Icons.restart_alt, size: 15),
                  label: Text(
                    'Reset',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // List Content
          grievances.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 48,
                          color: Color(0xFFCBD5E1),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No student grievances found',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'No grievance entries match your filter criteria.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: grievances.length,
                  separatorBuilder: (ctx, idx) =>
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  itemBuilder: (ctx, idx) => _grievanceTile(grievances[idx]),
                ),
        ],
      ),
    );
  }

  Widget _dropdownFilter(
    String label,
    List<String> items,
    String value,
    ValueChanged<String?> onChanged,
  ) {
    final uniqueItems = items.toSet().toList();
    final validVal = uniqueItems.contains(value)
        ? value
        : (uniqueItems.isNotEmpty ? uniqueItems.first : value);

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
      onSelected: onChanged,
      itemBuilder: (context) {
        return uniqueItems.map((item) {
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
        padding: const EdgeInsets.symmetric(horizontal: 12),
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
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
              Icons.keyboard_arrow_down,
              size: 16,
              color: Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }

  // ── Single Grievance Card Tile ─────────────────────────────────────────────
  Widget _grievanceTile(Map<String, dynamic> g) {
    final name = (g['studentName'] ?? 'Student').toString();
    final roll = (g['studentRoll'] ?? '').toString();
    final classSec = (g['classSec'] ?? '').toString();
    final category = (g['category'] ?? 'General').toString();
    final subject = (g['subject'] ?? 'No Subject').toString();
    final desc = (g['description'] ?? '').toString();
    final status = (g['status'] ?? 'Pending').toString();
    final priority = (g['priority'] ?? 'Medium').toString();
    final date = (g['date'] ?? '').toString();
    final recipient = (g['recipient'] ?? 'Faculty').toString();

    final initials = name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFEFF6FF),
            child: Text(
              initials.isEmpty ? 'S' : initials,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2563EB),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    if (roll.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        '($roll)',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                    if (classSec.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          classSec,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    _statusBadge(status),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E8FF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        category,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF7C3AED),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _priorityBadge(priority),
                    const SizedBox(width: 8),
                    Text(
                      'To: $recipient',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 12,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      date,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  subject,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF475569),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if ((g['response'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.reply_outlined,
                          size: 14,
                          color: Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF334155),
                              ),
                              children: [
                                TextSpan(
                                  text: 'Faculty Response: ',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(text: g['response'].toString()),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () => _showResponseModal(g),
                    icon: const Icon(Icons.edit_note, size: 16),
                    label: Text(
                      status == 'Resolved'
                          ? 'View Details'
                          : 'Respond & Resolve',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: status == 'Resolved'
                          ? const Color(0xFF64748B)
                          : const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color bg = const Color(0xFFFFF7ED);
    Color fg = const Color(0xFFC2410C);
    if (status == 'Resolved') {
      bg = const Color(0xFFECFDF5);
      fg = const Color(0xFF047857);
    } else if (status == 'In Review') {
      bg = const Color(0xFFEFF6FF);
      fg = const Color(0xFF1D4ED8);
    } else if (status == 'Rejected') {
      bg = const Color(0xFFFEF2F2);
      fg = const Color(0xFFB91C1C);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }

  Widget _priorityBadge(String priority) {
    Color fg = const Color(0xFF047857);
    if (priority == 'High') fg = const Color(0xFFDC2626);
    if (priority == 'Medium') fg = const Color(0xFFD97706);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(shape: BoxShape.circle, color: fg),
        ),
        const SizedBox(width: 4),
        Text(
          '$priority Priority',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: fg,
          ),
        ),
      ],
    );
  }

  // ── Response & Resolution Modal ───────────────────────────────────────────
  void _showResponseModal(Map<String, dynamic> g) {
    final responseCtrl = TextEditingController(
      text: (g['response'] ?? '').toString(),
    );
    final remarksCtrl = TextEditingController(
      text: (g['remarks'] ?? '').toString(),
    );
    String currentStatus = (g['status'] ?? 'Pending').toString();
    if (currentStatus == 'Pending') currentStatus = 'In Review';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              title: Row(
                children: [
                  const Icon(
                    Icons.gavel_outlined,
                    color: Color(0xFF2563EB),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Grievance Resolution',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Student Info Card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  (g['studentName'] ?? 'Student').toString(),
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  'Date: ${(g['date'] ?? '').toString()}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Roll No: ${(g['studentRoll'] ?? '').toString()} | Class: ${(g['classSec'] ?? '').toString()}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Grievance Details
                      Text(
                        'Subject',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (g['subject'] ?? '').toString(),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Text(
                        'Description',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAFAFA),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          (g['description'] ?? '').toString(),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF334155),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Status Dropdown
                      Text(
                        'Update Status',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: currentStatus,
                        items: ['In Review', 'Resolved', 'Rejected']
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(
                                  s,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setModalState(() => currentStatus = v!),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Official Faculty Response
                      Text(
                        'Official Response to Student',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: responseCtrl,
                        maxLines: 3,
                        style: GoogleFonts.inter(fontSize: 12),
                        decoration: InputDecoration(
                          hintText:
                              'Enter official response or resolution notes for student...',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF94A3B8),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Color(0xFF2563EB),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Internal Remarks
                      Text(
                        'Internal Remarks (Optional)',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: remarksCtrl,
                        style: GoogleFonts.inter(fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'Internal faculty remarks...',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF94A3B8),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(color: const Color(0xFF64748B)),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final resp = responseCtrl.text.trim();
                    final rem = remarksCtrl.text.trim();
                    final id = (g['id'] ?? '').toString();

                    final success =
                        await GrievancesService.updateGrievanceStatus(
                          grievanceId: id,
                          status: currentStatus,
                          response: resp.isEmpty ? null : resp,
                          remarks: rem.isEmpty ? null : rem,
                        );

                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      await _loadGrievances(showLoading: false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? 'Grievance updated successfully ✓'
                                : 'Grievance updated locally ✓',
                          ),
                          backgroundColor: const Color(0xFF10B981),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.check, size: 16),
                  label: Text(
                    'Save Resolution',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
