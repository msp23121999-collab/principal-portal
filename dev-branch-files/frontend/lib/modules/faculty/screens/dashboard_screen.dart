import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../widgets/faculty_loading.dart';
import '../erp_repository.dart';
import 'academic_calendar_view.dart';
import 'timetable_view.dart';
import 'attendance_view.dart';
import 'lesson_plan_view.dart';
import 'syllabus_upload_view.dart';
import 'question_bank_view.dart';
import 'assignment_upload_view.dart';
import 'my_uploads_view.dart';
import 'leave_application_view.dart';
import 'reports_view.dart';
import 'notifications_view.dart';
import 'profile_view.dart';
import 'marks_entry_view.dart';
import 'student_progress_view.dart';
import 'co_po_attainment_view.dart';
import 'student_feedback_view.dart';
import 'research_publications_view.dart';
import 'faculty_workload_view.dart';
import 'faculty_settings_view.dart';
import 'grievances_view.dart';
import '../services/timetable_service.dart';
import '../services/academic_calendar_service.dart';

// ─── Brand Colors ────────────────────────────────────────────────────────────
const _kNavyDark = Color(0xFF0D1B3E);
const _kNavyMid = Color(0xFF112255);
const _kAccent = Color(0xFF2563EB);
const _kSurface = Color(0xFFF4F6FA);

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.showSidebar = true, this.onLogout});

  final bool showSidebar;
  final VoidCallback? onLogout;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final repo = ErpRepository();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  DateTime get _now => DateTime.now();
  bool _isLoggedOut = false;

  final FocusNode _searchFocusNode = FocusNode();
  final LayerLink _searchLayerLink = LayerLink();
  OverlayEntry? _searchOverlayEntry;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  final TextEditingController _searchBarCtrl = TextEditingController();

  void _closeMobileDrawer([BuildContext? itemContext]) {
    try {
      if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
        _scaffoldKey.currentState?.closeDrawer();
      } else if (itemContext != null) {
        final scaffoldCtx = Scaffold.maybeOf(itemContext);
        if (scaffoldCtx != null && scaffoldCtx.isDrawerOpen) {
          scaffoldCtx.closeDrawer();
        } else if (Navigator.canPop(itemContext)) {
          Navigator.pop(itemContext);
        }
      }
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus) {
        // Wait minor delay to allow onTap suggestions to trigger first
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) _hideSearchOverlay();
        });
      }
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchBarCtrl.dispose();
    _hideSearchOverlay();
    super.dispose();
  }

  void _hideSearchOverlay() {
    _searchOverlayEntry?.remove();
    _searchOverlayEntry = null;
  }

  void _showSearchOverlay() {
    _hideSearchOverlay();
    _searchOverlayEntry = _createSearchOverlayEntry();
    Overlay.of(context).insert(_searchOverlayEntry!);
  }

  Timer? _searchDebounceTimer;

  Widget _highlightText(String text, String query) {
    if (query.isEmpty || text.isEmpty)
      return Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF0F172A),
        ),
      );
    final String lowerText = text.toLowerCase();
    final String lowerQuery = query.toLowerCase();
    final int index = lowerText.indexOf(lowerQuery);
    if (index == -1 || (index + query.length) > text.length)
      return Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF0F172A),
        ),
      );

    return RichText(
      text: TextSpan(
        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF0F172A)),
        children: [
          TextSpan(text: text.substring(0, index)),
          TextSpan(
            text: text.substring(index, index + query.length),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2563EB),
            ),
          ),
          TextSpan(text: text.substring(index + query.length)),
        ],
      ),
    );
  }

  OverlayEntry _createSearchOverlayEntry() {
    return OverlayEntry(
      builder: (overlayCtx) => Positioned(
        width: 420,
        child: CompositedTransformFollower(
          link: _searchLayerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 40),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 380),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: _isSearching
                  ? Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: LoadingAnimationWidget.hexagonDots(
                          color: const Color(0xFF2563EB),
                          size: 36,
                        ),
                      ),
                    )
                  : _searchResults.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'No matching records found.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(8),
                      itemCount: _searchResults.length,
                      itemBuilder: (listCtx, idx) {
                        final res = _searchResults[idx];
                        final type = res['type'] as String;
                        final isStudent = type == 'student';
                        final studentData = isStudent
                            ? (res['details'] as Map<String, dynamic>?)
                            : null;
                        final photoUrl = studentData?['photoUrl'] as String?;

                        Widget leadingWidget;
                        if (isStudent &&
                            photoUrl != null &&
                            photoUrl.isNotEmpty) {
                          leadingWidget = CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0xFFF1F5F9),
                            child: ClipOval(
                              child: Image.network(
                                photoUrl,
                                width: 36,
                                height: 36,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Center(
                                      child: Text(
                                        res['title']
                                            .toString()
                                            .substring(0, 1)
                                            .toUpperCase(),
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF2563EB),
                                        ),
                                      ),
                                    ),
                              ),
                            ),
                          );
                        } else {
                          IconData icon = Icons.info_outline;
                          if (type == 'student') icon = Icons.person_outline;
                          if (type == 'faculty') icon = Icons.school_outlined;
                          if (type == 'assignment')
                            icon = Icons.assignment_outlined;
                          if (type == 'leave')
                            icon = Icons.description_outlined;
                          if (type == 'notification')
                            icon = Icons.notifications_none_outlined;
                          if (type == 'subject')
                            icon = Icons.menu_book_outlined;
                          if (type == 'questionbank')
                            icon = Icons.folder_open_outlined;

                          leadingWidget = Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              icon,
                              color: const Color(0xFF2563EB),
                              size: 18,
                            ),
                          );
                        }

                        String typeLabel = type.toUpperCase();
                        if (type == 'student') typeLabel = 'Student';
                        if (type == 'faculty') typeLabel = 'Faculty';
                        if (type == 'assignment') typeLabel = 'Assignment';
                        if (type == 'leave') typeLabel = 'Leave';
                        if (type == 'notification') typeLabel = 'Notification';
                        if (type == 'subject') typeLabel = 'Subject';
                        if (type == 'questionbank') typeLabel = 'Question Bank';

                        final subtitleText = res['subtitle'] as String;
                        final fullSubtitle = "$subtitleText | Type: $typeLabel";

                        return ListTile(
                          leading: leadingWidget,
                          title: _highlightText(
                            res['title'] as String,
                            _searchBarCtrl.text,
                          ),
                          subtitle: Text(
                            fullSubtitle,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          onTap: () {
                            _hideSearchOverlay();
                            _searchFocusNode.unfocus();
                            _searchBarCtrl.clear();
                            if (type == 'student' && res['details'] != null) {
                              _showStudentDetailsDialog(
                                Map<String, dynamic>.from(res['details']),
                              );
                            } else {
                              setState(() {
                                if (type == 'student') {
                                  repo.selectedMenuIndex = 3;
                                } else if (type == 'faculty') {
                                  repo.selectedMenuIndex = 13;
                                } else if (type == 'assignment') {
                                  repo.selectedMenuIndex = 8;
                                } else if (type == 'leave') {
                                  repo.selectedMenuIndex = 10;
                                } else if (type == 'notification') {
                                  repo.selectedMenuIndex = 12;
                                } else if (type == 'subject') {
                                  repo.selectedMenuIndex = 6;
                                } else if (type == 'questionbank') {
                                  repo.selectedMenuIndex = 7;
                                }
                              });
                            }
                          },
                        );
                      },
                    ),
            ),
          ),
        ),
      ),
    );
  }

  void _onSearchChanged(String v) {
    if (_searchDebounceTimer?.isActive ?? false) _searchDebounceTimer!.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () async {
      if (v.trim().isEmpty) {
        _hideSearchOverlay();
        return;
      }
      setState(() {
        _isSearching = true;
      });
      _showSearchOverlay();
      final results = await repo.searchAll(v);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
        _showSearchOverlay();
      }
    });
  }

  void _showStudentDetailsDialog(Map<String, dynamic> student) {
    final roll = student['roll'];
    final name = student['name'];
    final dept = student['dept'];
    final sec = student['sec'];
    final email = student['email'] ?? 'N/A';
    final phone = student['phone'] ?? 'N/A';
    final status = student['status'] ?? 'Active';

    // 1. Calculate Attendance
    final classSecStr = '$dept - $sec (II Year)';
    final studentSessions = repo.attendanceSessions
        .where((s) => s['classSec'] == classSecStr)
        .toList();
    int totalClasses = studentSessions.length;
    int presentClasses = 0;
    for (var s in studentSessions) {
      final records = s['records'] as List?;
      if (records != null) {
        final r = records.where((rec) => rec['roll'] == roll).firstOrNull;
        if (r != null &&
            (r['status'] == 'P' ||
                r['status'] == 'OD' ||
                r['status'] == 'ML')) {
          presentClasses++;
        }
      }
    }
    final attPercentage = totalClasses > 0
        ? (presentClasses / totalClasses * 100).toStringAsFixed(1)
        : '100.0';

    // 2. Fetch Marks
    final studentMarks = repo.marks
        .where((m) => m['studentRoll'] == roll)
        .toList();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 550,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFFEFF6FF),
                          child: Text(
                            name.isNotEmpty
                                ? name.substring(0, 1).toUpperCase()
                                : 'S',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'Roll No: $roll | Reg No: ${student['reg']}',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(height: 32, color: Color(0xFFE2E8F0)),

                // Basic Info Grid
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Department',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$dept - Section $sec',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              status,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF166534),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Email Address',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            email,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mobile Number',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            phone,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32, color: Color(0xFFE2E8F0)),

                // Attendance Section
                Text(
                  'Attendance Summary',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Attendance Percentage',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$attPercentage%',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Classes Attended',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$presentClasses / $totalClasses',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 32, color: Color(0xFFE2E8F0)),

                // Marks Section
                Text(
                  'Academic Marks',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                studentMarks.isEmpty
                    ? Text(
                        'No marks recorded for this student yet.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    : Container(
                        constraints: const BoxConstraints(maxHeight: 120),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: studentMarks.length,
                          itemBuilder: (context, idx) {
                            final m = studentMarks[idx];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4.0,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${m['assessment'] ?? 'Exam'}: ${m['subject'] ?? 'Subject'}',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF334155),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    'Score: ${m['total'] ?? 'N/A'} (Grade: ${m['grade'] ?? 'N/A'})',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF16A34A),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Grouped Sidebar structure (matching Image 1) ─────────────────────────
  // ─── Flat Sidebar structure (matching KSR screenshots) ────────────────────
  static const _sidebarGroups = [
    {
      'label': null,
      'items': [
        {'title': 'My Dashboard', 'icon': Icons.dashboard_outlined, 'idx': 0},
      ],
    },
    {
      'label': 'TEACHING',
      'items': [
        {'title': 'My Timetable', 'icon': Icons.access_time_outlined, 'idx': 2},
        {'title': 'Attendance', 'icon': Icons.how_to_reg_outlined, 'idx': 3},
        {'title': 'Marks Entry', 'icon': Icons.edit_note_outlined, 'idx': 4},
        {
          'title': 'Student Progress',
          'icon': Icons.trending_up_outlined,
          'idx': 15,
        },
        {
          'title': 'Student Feedback',
          'icon': Icons.rate_review_outlined,
          'idx': 17,
        },
        {
          'title': 'Faculty Workload',
          'icon': Icons.schedule_outlined,
          'idx': 19,
        },
      ],
    },
    {
      'label': 'ACADEMIC',
      'items': [
        {'title': 'Lesson Plan', 'icon': Icons.menu_book_outlined, 'idx': 5},
        {
          'title': 'Course Materials',
          'icon': Icons.library_books_outlined,
          'idx': 6,
        },
        {'title': 'Assignments', 'icon': Icons.note_add_outlined, 'idx': 8},
        {
          'title': 'CO–PO Attainment',
          'icon': Icons.auto_graph_outlined,
          'idx': 16,
        },
      ],
    },
    {
      'label': 'ADMINISTRATION',
      'items': [
        {
          'title': 'Leave Application',
          'icon': Icons.description_outlined,
          'idx': 10,
        },
        {
          'title': 'Student Grievances',
          'icon': Icons.gavel_outlined,
          'idx': 21,
        },
        {
          'title': 'Notifications',
          'icon': Icons.notifications_none_outlined,
          'idx': 12,
        },
        {'title': 'Reports', 'icon': Icons.bar_chart_outlined, 'idx': 11},
        {'title': 'My Uploads', 'icon': Icons.upload_file_outlined, 'idx': 9},
        {
          'title': 'Research & Publications',
          'icon': Icons.science_outlined,
          'idx': 18,
        },
      ],
    },
    {
      'label': 'OTHER',
      'items': [
        {
          'title': 'Academic Calendar',
          'icon': Icons.calendar_month_outlined,
          'idx': 1,
        },
        {
          'title': 'My Profile',
          'icon': Icons.person_outline_rounded,
          'idx': 13,
        },
        {'title': 'Settings', 'icon': Icons.settings_outlined, 'idx': 20},
        {'title': 'Logout', 'icon': Icons.logout_rounded, 'idx': 99},
      ],
    },
  ];

  String _pageTitle(int idx) {
    for (final grp in _sidebarGroups) {
      for (final item in (grp['items'] as List? ?? [])) {
        if (item['idx'] == idx)
          return (item['title'] ?? 'Dashboard').toString();
      }
    }
    return 'Dashboard';
  }

  Widget _buildMainContent(double sw) {
    if (repo.isLoadingData && repo.timetable.isEmpty && repo.profile.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: FacultyLoadingWidget(),
      );
    }
    switch (repo.selectedMenuIndex) {
      case 0:
        return _buildDashboard(sw);
      case 1:
        return const AcademicCalendarView();
      case 2:
        return const TimetableView();
      case 3:
        return const AttendanceView();
      case 4:
        return const MarksEntryView();
      case 5:
        return const LessonPlanView();
      case 6:
        return const SyllabusUploadView();
      case 7:
        return const QuestionBankView();
      case 8:
        return const AssignmentUploadView();
      case 9:
        return const MyUploadsView();
      case 10:
        return const LeaveApplicationView();
      case 11:
        return const ReportsView();
      case 12:
        return const NotificationsView();
      case 13:
        return const ProfileView();
      case 15:
        return const StudentProgressView();
      case 16:
        return const CoPoAttainmentView();
      case 17:
        return const StudentFeedbackView();
      case 18:
        return const ResearchPublicationsView();
      case 19:
        return const FacultyWorkloadView();
      case 20:
        return const FacultySettingsView();
      case 21:
        return const GrievancesView();
      default:
        return _buildPlaceholder(_pageTitle(repo.selectedMenuIndex));
    }
  }

  Widget _buildPlaceholder(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.construction_outlined,
            size: 64,
            color: Color(0xFF94A3B8),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This section is under development.',
            style: GoogleFonts.inter(color: const Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final showSidebar = sw >= 1024;

    if (_isLoggedOut) {
      return Scaffold(
        backgroundColor: _kNavyDark,
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 64, color: _kAccent),
                const SizedBox(height: 16),
                Text(
                  'Campus OS ERP',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _kNavyDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Session has been destroyed successfully.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoggedOut = false;
                      repo.selectedMenuIndex = 0;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kAccent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Login Back',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: _kSurface,
          drawer: !showSidebar ? Drawer(child: _buildSidebar(context)) : null,
          body: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showSidebar)
                  SizedBox(width: 220, child: _buildSidebar(context)),
                Expanded(
                  child: Column(
                    children: [
                      _buildTopBar(context, showSidebar),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(
                            sw < 600 ? 12 : (sw < 1024 ? 16 : 24),
                          ),
                          child: _buildMainContent(sw),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SIDEBAR
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildSidebar(BuildContext context) {
    return Container(
      color: _kNavyDark,
      child: Column(
        children: [
          // Logo area
          Container(
            color: _kNavyMid,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.network(
                    'logo.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Text(
                        'KSR',
                        style: GoogleFonts.inter(
                          color: _kNavyDark,
                          fontWeight: FontWeight.w900,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'KSR',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'COLLEGE OF ENGINEERING',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF93C5FD),
                        fontSize: 7,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Nav groups
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                for (final grp in _sidebarGroups) ...[
                  if (grp['label'] != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                      child: Text(
                        (grp['label'] ?? '').toString(),
                        style: GoogleFonts.inter(
                          color: const Color(0xFF60A5FA),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  for (final item in (grp['items'] as List? ?? []))
                    _navItem(
                      context,
                      (item['title'] ?? '').toString(),
                      item['icon'] as IconData?,
                      (item['idx'] as num? ?? 0).toInt(),
                    ),
                ],
              ],
            ),
          ),
          // Footer — Need Help
          const Divider(color: Color(0xFF1E3766), height: 1),
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2F5A),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.headset_mic_outlined,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Need Help?',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Contact Support',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF93C5FD),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(BuildContext context, String title, IconData? icon, int idx) {
    final bool sel = repo.selectedMenuIndex == idx;
    final bool hasMyUploadsBadge = idx == 9;
    final bool hasNotifBadge = idx == 12;
    final bool isLogout = idx == 99;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 1),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: InkWell(
          borderRadius: BorderRadius.circular(0),
          onTap: () {
            if (isLogout) {
              _closeMobileDrawer(context);
              _showLogoutConfirmation();
              return;
            }
            repo.selectedMenuIndex = idx;
            _closeMobileDrawer(context);
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
            decoration: BoxDecoration(
              color: sel ? const Color(0xFF1A3666) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: sel
                  ? const Border(
                      left: BorderSide(color: Color(0xFF60A5FA), width: 3),
                    )
                  : null,
            ),
            child: Padding(
              padding: EdgeInsets.only(
                left: sel ? 9 : 12,
                right: 12,
                top: 9,
                bottom: 9,
              ),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      color: sel
                          ? const Color(0xFF60A5FA)
                          : (isLogout
                                ? const Color(0xFFF87171)
                                : const Color(0xFF7BA4D4)),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.inter(
                        color: sel
                            ? Colors.white
                            : (isLogout
                                  ? const Color(0xFFFCA5A5)
                                  : const Color(0xFFCBDBEE)),
                        fontSize: 14,
                        fontWeight: sel ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (hasMyUploadsBadge)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF97316),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${repo.totalUploadsCount}',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (hasNotifBadge && repo.unreadNotificationsCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${repo.unreadNotificationsCount}',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmation({VoidCallback? onLogout}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          'Confirm Logout',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to logout from the Faculty ERP Portal?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (widget.onLogout != null) {
                widget.onLogout!();
                return;
              }
              context.go('/');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: Text(
              'Logout',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TOP BAR
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildTopBar(BuildContext context, bool showSidebar) {
    final sw = MediaQuery.of(context).size.width;
    final isMobile = sw < 600;

    return Container(
      color: _kNavyDark,
      height: 60,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 16),
      child: Row(
        children: [
          if (!showSidebar)
            Builder(
              builder: (scaffoldCtx) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => Scaffold.of(scaffoldCtx).openDrawer(),
              ),
            ),
          Expanded(
            child: CompositedTransformTarget(
              link: _searchLayerLink,
              child: Container(
                height: 36,
                constraints: BoxConstraints(maxWidth: isMobile ? 160 : 420),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B3260),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _searchBarCtrl,
                  focusNode: _searchFocusNode,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: isMobile
                        ? 'Search...'
                        : 'Search students, faculty, assignments...',
                    hintStyle: GoogleFonts.inter(
                      color: const Color(0xFF7BA4D4),
                      fontSize: 12,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF7BA4D4),
                      size: 16,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 9),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: isMobile ? 4 : 12),
          // Notification bell with orange badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: 22,
                ),
                onPressed: () => repo.selectedMenuIndex = 12,
              ),
              if (repo.unreadNotificationsCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    width: 17,
                    height: 17,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF97316),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${repo.unreadNotificationsCount}',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 8),
          // Profile chip
          PopupMenuButton<String>(
            offset: const Offset(0, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: Colors.white,
            elevation: 8,
            onSelected: (val) {
              if (val == 'logout') {
                _showLogoutConfirmation();
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(
                      Icons.logout_rounded,
                      size: 16,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Logout',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Row(
                children: [
                  _profileImage(34, iconSize: 16),
                  if (MediaQuery.of(context).size.width > 600) ...[
                    const SizedBox(width: 8),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (repo.profile['name'] ?? 'Dr. S. Malliga').toString(),
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          (repo.profile['role'] ?? 'Faculty').toString(),
                          style: GoogleFonts.inter(
                            color: const Color(0xFF93C5FD),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white60,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DASHBOARD CONTENT
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildDashboard(double sw) {
    if (repo.isLoadingData && repo.timetable.isEmpty && repo.profile.isEmpty) {
      return const FacultyLoadingWidget();
    }

    final bool wide = sw > 1100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Faculty Profile Card + Quick Actions ────────────────────────────
        _buildFacultyProfileCard(wide),
        const SizedBox(height: 20),

        // ── Main Dashboard Cards Grid (Horizontally Equal Cards via IntrinsicHeight) ──
        wide
            ? Column(
                children: [
                  // Row 1: My Timetable - Today (Left) | Campus Events (Right)
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _buildTimetableCard()),
                        const SizedBox(width: 20),
                        Expanded(child: _buildCampusEventsCard()),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Row 2: Lesson Progress Submission Status (Left) | Attendance Pending Today (Right)
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _buildLessonPlanCard()),
                        const SizedBox(width: 15),
                        Expanded(child: _buildAttendancePendingCard()),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  _buildTimetableCard(),
                  const SizedBox(height: 16),
                  _buildLessonPlanCard(),
                  const SizedBox(height: 16),
                  _buildCampusEventsCard(),
                  const SizedBox(height: 14),
                  _buildAttendancePendingCard(),
                ],
              ),
        const SizedBox(height: 32),
      ],
    );
  }

  // ── Helpers for Live Dashboard Calculations ───────────────────────────────
  String _getWeekdayName(int w) {
    const d = [
      '',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return d[w.clamp(0, 7)];
  }

  String _getMonthName(int m) {
    const months = [
      '',
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
    return months[m.clamp(0, 12)];
  }

  String? _getCurrentPeriod() {
    final m = _now.hour * 60 + _now.minute;
    if (m >= 9 * 60 && m < 9 * 60 + 50) return 'P1';
    if (m >= 9 * 60 + 50 && m < 10 * 60 + 40) return 'P2';
    if (m >= 10 * 60 + 55 && m < 11 * 60 + 40) return 'P3';
    if (m >= 11 * 60 + 40 && m < 12 * 60 + 30) return 'P4';
    if (m >= 13 * 60 + 30 && m < 14 * 60 + 20) return 'P5';
    if (m >= 14 * 60 + 20 && m < 15 * 60 + 10) return 'P6';
    if (m >= 15 * 60 + 10 && m < 16 * 60) return 'P7';
    if (m >= 16 * 60 && m < 16 * 60 + 50) return 'P8';
    return null;
  }

  int _getTodayClassesCount(String facultyId) {
    final todayName = _getWeekdayName(_now.weekday);
    final dayData =
        repo.timetable.where((t) => t['day'] == todayName).firstOrNull ??
        <String, dynamic>{};
    if (dayData.isEmpty || dayData['schedule'] == null) return 0;
    return (dayData['schedule'] as List)
        .where((s) => s['facultyId'] == facultyId)
        .length;
  }

  List<Map<String, String>> _getPendingAttendanceToday(String facultyId) {
    final todayName = _getWeekdayName(_now.weekday);
    final todayStr = _now.toString().substring(0, 10);
    final periodOrder = ['P1', 'P2', 'P3', 'P4', 'P5', 'P6', 'P7', 'P8'];

    final pending = <Map<String, String>>[];

    final dayData =
        repo.timetable.where((t) => t['day'] == todayName).firstOrNull ??
        <String, dynamic>{};
    if (dayData.isEmpty || dayData['schedule'] == null) return pending;

    final scheduleList = (dayData['schedule'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    scheduleList.sort((a, b) {
      final idxA = periodOrder.indexOf(a['period']?.toString() ?? '');
      final idxB = periodOrder.indexOf(b['period']?.toString() ?? '');
      return idxA.compareTo(idxB);
    });

    for (final slot in scheduleList) {
      if (slot['facultyId'] == facultyId) {
        final period = slot['period']?.toString() ?? '';
        final classSec = slot['classSec']?.toString() ?? '';
        final subject = slot['subject']?.toString() ?? '';

        final hasSession = repo.attendanceSessions.any(
          (s) =>
              s['date'] == todayStr &&
              s['period'] == period &&
              s['classSec'] == classSec &&
              s['subject'] == subject,
        );

        if (!hasSession) {
          pending.add({
            'period': period,
            'subject': subject,
            'section': classSec,
          });
        }
      }
    }
    return pending;
  }

  int _getPendingMarksCount(String facultyId) {
    final List<String> classes = TimetableService.getClassesForFaculty(
      facultyId,
    );
    final extraClasses = <String>{};
    for (var day in repo.timetable) {
      for (var s in (day['schedule'] as List? ?? [])) {
        if (s['facultyId'] == facultyId) {
          final cls = s['classSec']?.toString();
          if (cls != null && !classes.contains(cls)) extraClasses.add(cls);
        }
      }
    }
    final List<String> allClasses = <String>{
      ...classes,
      ...extraClasses,
    }.toList();

    int pendingCount = 0;
    final exams = ['CIA I', 'CIA II'];
    for (final cls in allClasses) {
      final subjects = TimetableService.getSubjectsForClass(facultyId, cls);
      final extraSubj = <String>{};
      for (var day in repo.timetable) {
        for (var s in (day['schedule'] as List? ?? [])) {
          if (s['facultyId'] == facultyId && s['classSec'] == cls) {
            final subj = s['subject']?.toString();
            if (subj != null && !subjects.contains(subj)) extraSubj.add(subj);
          }
        }
      }
      final allSubj = {...subjects, ...extraSubj}.toList();

      for (final subj in allSubj) {
        for (final exam in exams) {
          final key = '${exam}_${cls}_$subj';
          final status = repo.markSheetStatuses[key];
          if (status != 'Submitted' &&
              status != 'Submitted for Verification' &&
              status != 'Approved') {
            pendingCount++;
          }
        }
      }
    }
    return pendingCount;
  }

  List<Map<String, String>> _getTodayTimetableClasses(String facultyId) {
    final todayName = _getWeekdayName(_now.weekday);
    final periodOrder = ['P1', 'P2', 'P3', 'P4', 'P5', 'P6', 'P7', 'P8'];

    final list = <Map<String, String>>[];

    final dayData =
        repo.timetable.where((t) => t['day'] == todayName).firstOrNull ??
        <String, dynamic>{};
    if (dayData.isEmpty || dayData['schedule'] == null) return list;

    final scheduleList = (dayData['schedule'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    scheduleList.sort((a, b) {
      final idxA = periodOrder.indexOf(a['period']?.toString() ?? '');
      final idxB = periodOrder.indexOf(b['period']?.toString() ?? '');
      return idxA.compareTo(idxB);
    });

    for (final slot in scheduleList) {
      if (slot['facultyId'] == facultyId) {
        list.add({
          'p': slot['period']?.toString() ?? '',
          'time': slot['time']?.toString() ?? '',
          'subject': slot['subject']?.toString() ?? '',
          'section': slot['classSec']?.toString() ?? '',
          'room': slot['room']?.toString() ?? '',
        });
      }
    }
    return list;
  }

  String _getAttendanceAvg(String facultyId) {
    final sessions = repo.attendanceSessions
        .where((s) => s['facultyId'] == facultyId)
        .toList();
    if (sessions.isEmpty) return '100.0%';
    int totalP = 0;
    int totalTotal = 0;
    for (final s in sessions) {
      final p = (s['present'] as num? ?? 0).toInt();
      final a = (s['absent'] as num? ?? 0).toInt();
      final od = (s['od'] as num? ?? 0).toInt();
      final ml = (s['ml'] as num? ?? 0).toInt();
      totalP += p + od + ml;
      totalTotal += p + a + od + ml;
    }
    if (totalTotal == 0) return '100.0%';
    return '${(totalP / totalTotal * 100).toStringAsFixed(1)}%';
  }

  // New Faculty Profile Card — matches Image 4 design
  Widget _buildFacultyProfileCard(bool wide) {
    final facultyId = repo.profile['employeeId'] ?? 'FAC73124';
    final todayClasses = _getTodayClassesCount(facultyId);
    final pendingAttendanceCount = _getPendingAttendanceToday(facultyId).length;
    final pendingMarksCount = _getPendingMarksCount(facultyId);
    final statPills = [
      {
        'label': 'Today\'s Classes',
        'value': '$todayClasses',
        'color': const Color(0xFF2563EB),
        'icon': Icons.school_outlined,
      },
      {
        'label': 'Attendance Pending',
        'value': '$pendingAttendanceCount',
        'color': const Color(0xFFF97316),
        'icon': Icons.people_outline,
      },
      {
        'label': 'CIA Marks Pending',
        'value': '$pendingMarksCount',
        'color': const Color(0xFF10B981),
        'icon': Icons.assignment_outlined,
      },
    ];

    final quickActions = [
      {
        'label': 'Mark\nAttendance',
        'icon': Icons.how_to_reg_outlined,
        'color': const Color(0xFF2563EB),
        'idx': 3,
      },
      {
        'label': 'Enter\nMarks',
        'icon': Icons.edit_note_outlined,
        'color': const Color(0xFF10B981),
        'idx': 4,
      },
      {
        'label': 'View\nTimetable',
        'icon': Icons.access_time_outlined,
        'color': const Color(0xFF0F172A),
        'idx': 2,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
                _profileImage(68, iconSize: 28),
                const SizedBox(width: 16),
                // Name + ID + Dept
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 240),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              (repo.profile['name'] as String? ??
                                  'Dr. S. Malliga'),
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7ED),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              (repo.profile['role'] as String? ?? 'Faculty'),
                              style: GoogleFonts.inter(
                                color: const Color(0xFFEA580C),
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Employee ID: ${repo.profile['employeeId'] ?? 'EMP_CSE_002'}',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF64748B),
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        (repo.profile['department'] as String? ??
                            'Computer Science & Engineering'),
                        style: GoogleFonts.inter(
                          color: const Color(0xFF64748B),
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Vertical divider
                Container(width: 1, height: 60, color: const Color(0xFFE2E8F0)),
                const SizedBox(width: 24),
                // Stat pills
                Expanded(
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: statPills
                        .map(
                          (s) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    s['icon'] as IconData,
                                    size: 14,
                                    color: s['color'] as Color,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    s['value'] as String,
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: s['color'] as Color,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                s['label'] as String,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(width: 16),
                // Quick Action buttons
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Actions',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: quickActions
                          .map(
                            (a) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () => repo.selectedMenuIndex =
                                    (a['idx'] as num).toInt(),
                                child: Container(
                                  width: 80,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: a['color'] as Color,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        a['icon'] as IconData,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        a['label'] as String,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _profileImage(52, iconSize: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            repo.profile['name'] as String,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF0F172A),
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            'Employee ID: ${repo.profile['employeeId']}',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF64748B),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7ED),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              repo.profile['role'] as String,
                              style: GoogleFonts.inter(
                                color: const Color(0xFFEA580C),
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cardWidth = (constraints.maxWidth - 20) / 3;
                    final effectiveWidth = cardWidth < 90
                        ? (constraints.maxWidth - 10) / 2
                        : cardWidth;

                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: statPills
                          .map(
                            (s) => SizedBox(
                              width: effectiveWidth,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: (s['color'] as Color).withValues(
                                    alpha: 0.05,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: (s['color'] as Color).withValues(
                                      alpha: 0.15,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          s['icon'] as IconData,
                                          size: 14,
                                          color: s['color'] as Color,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          s['value'] as String,
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: s['color'] as Color,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      s['label'] as String,
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: const Color(0xFF64748B),
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: quickActions
                      .map(
                        (a) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () => repo.selectedMenuIndex =
                                  (a['idx'] as num).toInt(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: a['color'] as Color,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      a['icon'] as IconData,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      a['label'] as String,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
    );
  }

  Widget _buildStatRow(bool wide) {
    final facultyId = repo.profile['employeeId'] ?? 'FAC73124';
    final todayStr = DateTime.now().toString().substring(0, 10);

    final todayClasses = _getTodayClassesCount(facultyId);
    final pendingAttendanceCount = _getPendingAttendanceToday(facultyId).length;
    final pendingMarksCount = _getPendingMarksCount(facultyId);
    final pendingSyllabusCount = repo.lessonPlans
        .where(
          (lp) => lp['facultyId'] == facultyId && lp['status'] != 'Completed',
        )
        .length;
    final eventsToday = AcademicCalendarService.getAll()
        .where((e) => e['date'] == todayStr)
        .length;

    final stats = [
      {
        'icon': Icons.today_outlined,
        'color': const Color(0xFF3B82F6),
        'bg': const Color(0xFFEFF6FF),
        'title': "Today's Classes",
        'value': '$todayClasses',
        'action': 'View Schedule →',
        'idx': 2,
      },
      {
        'icon': Icons.people_outline,
        'color': const Color(0xFFF97316),
        'bg': const Color(0xFFFFF7ED),
        'title': 'Attendance Pending',
        'value': '$pendingAttendanceCount',
        'action': 'Mark Now →',
        'idx': 3,
      },
      {
        'icon': Icons.assignment_outlined,
        'color': const Color(0xFF10B981),
        'bg': const Color(0xFFF0FDF4),
        'title': 'CIA Marks Pending',
        'value': pendingMarksCount == 0 ? 'None' : '$pendingMarksCount Sheets',
        'action': 'Check Now →',
        'idx': 4,
      },
      {
        'icon': Icons.book_outlined,
        'color': const Color(0xFF8B5CF6),
        'bg': const Color(0xFFF5F3FF),
        'title': 'Syllabus Pending',
        'value': '$pendingSyllabusCount Topics',
        'action': 'Update Now →',
        'idx': 5,
      },
      {
        'icon': Icons.event_outlined,
        'color': const Color(0xFF0EA5E9),
        'bg': const Color(0xFFF0F9FF),
        'title': 'Events Today',
        'value': '$eventsToday',
        'action': 'View Calendar →',
        'idx': 1,
      },
    ];

    final cards = stats
        .map(
          (s) => InkWell(
            onTap: () =>
                repo.selectedMenuIndex = (s['idx'] as num? ?? 0).toInt(),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: s['bg'] as Color,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          s['icon'] as IconData,
                          color: s['color'] as Color,
                          size: 18,
                        ),
                      ),
                      Text(
                        s['action'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: s['color'] as Color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s['value'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: s['color'] as Color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s['title'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        )
        .toList();

    return wide
        ? Row(
            children: [
              for (int i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(child: cards[i]),
              ],
            ],
          )
        : Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (int i = 0; i < stats.length; i++)
                SizedBox(
                  width: MediaQuery.of(context).size.width < 500
                      ? (MediaQuery.of(context).size.width - 36)
                      : (MediaQuery.of(context).size.width - 48) / 2,
                  child: cards[i],
                ),
            ],
          );
  }

  // My Timetable – Today
  Widget _buildTimetableCard() {
    final facultyId = repo.profile['employeeId'] ?? 'FAC73124';
    final schedule = _getTodayTimetableClasses(facultyId);
    final dayName = _getWeekdayName(_now.weekday);
    final dateStr =
        '$dayName, ${_now.day} ${_getMonthName(_now.month)} ${_now.year}';

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                color: Color(0xFF2563EB),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'My Timetable - Today',
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                dateStr,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF2563EB),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (schedule.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No classes scheduled for today ✓',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
            )
          else
            Table(
              columnWidths: const {
                0: FixedColumnWidth(64),
                1: FlexColumnWidth(4.5),
                2: FlexColumnWidth(2.5),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  children: ['Period', 'Subject', 'Section']
                      .map(
                        (h) => Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 6,
                          ),
                          child: Text(
                            h,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF64748B),
                            ),
                            textAlign: h == 'Section'
                                ? TextAlign.center
                                : TextAlign.left,
                          ),
                        ),
                      )
                      .toList(),
                ),
                for (final r in schedule)
                  TableRow(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFF1F5F9)),
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 6,
                        ),
                        child: Text(
                          r['p']!,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: const Color(0xFF334155),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 6,
                        ),
                        child: Text(
                          r['subject']!,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 4,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            r['section']!,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1D4ED8),
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => repo.selectedMenuIndex = 2,
              icon: const Icon(
                Icons.arrow_forward,
                size: 14,
                color: Color(0xFF2563EB),
              ),
              label: Text(
                'View Full Timetable',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: const Color(0xFF2563EB),
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Attendance Pending
  Widget _buildAttendancePendingCard() {
    final facultyId = repo.profile['employeeId'] ?? 'FAC73124';
    final items = _getPendingAttendanceToday(facultyId);

    return _card(
      leftBorder: const Color(0xFFF97316),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.people_outline,
                    color: Color(0xFFF97316),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Attendance Pending Today',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Text(
                      'All attendance marked for today ✓',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF16A34A),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              else
                for (final item in items.take(2)) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFFFEDD5)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF97316),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item['period']!,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['subject']!,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF431407),
                                  fontSize: 11,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              Text(
                                item['section']!,
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF9A3412),
                                  fontSize: 9.5,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => repo.selectedMenuIndex = 3,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEA580C),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: Text(
                            'Mark',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: InkWell(
              onTap: () => repo.selectedMenuIndex = 3,
              child: Text(
                'View All Pending →',
                style: GoogleFonts.inter(
                  color: const Color(0xFFEA580C),
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Lesson Plan Status
  Widget _buildLessonPlanCard() {
    final facultyId = repo.profile['employeeId'] ?? 'FAC73124';
    final List<String> classes = TimetableService.getClassesForFaculty(
      facultyId,
    );
    final subjects = <String>{};
    for (final cls in classes) {
      subjects.addAll(TimetableService.getSubjectsForClass(facultyId, cls));
    }

    final items = subjects.map((subj) {
      final totalTopics = repo.lessonPlans
          .where((lp) => lp['subject'] == subj)
          .length;
      final completedTopics = repo.lessonPlans
          .where((lp) => lp['subject'] == subj && lp['status'] == 'Completed')
          .length;
      final pct = totalTopics > 0
          ? (completedTopics / totalTopics * 100).toStringAsFixed(0)
          : '0';
      return {
        'subject': subj,
        'status': '$pct% Completed',
        'ok': totalTopics > 0 && completedTopics == totalTopics,
      };
    }).toList();

    return _card(
      leftBorder: const Color(0xFF6366F1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.description_outlined,
                    color: Color(0xFF6366F1),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lesson Progress Submission Status',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No assigned subjects found',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                )
              else
                for (final item in items.take(2)) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item['subject'] as String,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF334155),
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: (item['ok'] as bool)
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            item['status'] as String,
                            style: GoogleFonts.inter(
                              color: (item['ok'] as bool)
                                  ? const Color(0xFF15803D)
                                  : const Color(0xFFB91C1C),
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: InkWell(
              onTap: () => repo.selectedMenuIndex = 5,
              child: Text(
                'View All Subjects →',
                style: GoogleFonts.inter(
                  color: const Color(0xFF6366F1),
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Academic Overview
  Widget _buildAcademicOverviewCard() {
    final facultyId = repo.profile['employeeId'] ?? 'EMP_CSE_002';

    final todayClasses = _getTodayClassesCount(facultyId);
    final attAvg = _getAttendanceAvg(facultyId);
    final assignmentsCount = repo.assignments
        .where((a) => a['facultyId'] == facultyId)
        .length;
    final examsPlannedCount = AcademicCalendarService.getAll()
        .where((e) => e['type'] == 'Exam')
        .length;

    final stats2 = [
      {
        'icon': Icons.menu_book_outlined,
        'color': const Color(0xFF4F46E5),
        'val': '$todayClasses',
        'label': 'Classes Today',
        'action': 'View Details →',
        'idx': 2,
      },
      {
        'icon': Icons.people_outline,
        'color': const Color(0xFF10B981),
        'val': attAvg,
        'label': 'Attendance Avg.',
        'action': 'View Report →',
        'idx': 3,
      },
      {
        'icon': Icons.bar_chart_rounded,
        'color': const Color(0xFFF97316),
        'val': '$assignmentsCount',
        'label': 'Assignments',
        'action': 'View All →',
        'idx': 8,
      },
      {
        'icon': Icons.assignment_outlined,
        'color': const Color(0xFF8B5CF6),
        'val': '$examsPlannedCount',
        'label': 'Exams Planned',
        'action': 'View Calendar →',
        'idx': 1,
      },
    ];

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFF0F172A),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.school_outlined,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Academic Overview',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.3,
            children: stats2
                .map(
                  (s) => InkWell(
                    onTap: () => repo.selectedMenuIndex =
                        (s['idx'] as num? ?? 0).toInt(),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: (s['color'] as Color).withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              s['icon'] as IconData,
                              color: s['color'] as Color,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  s['val'] as String,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: s['color'] as Color,
                                  ),
                                ),
                                Text(
                                  s['label'] as String,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: const Color(0xFF64748B),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  s['action'] as String,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: s['color'] as Color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  // Campus Events
  Widget _buildCampusEventsCard() {
    final rawEvents = AcademicCalendarService.getAll();
    final events = rawEvents.map((e) {
      final title = e['title']?.toString() ?? 'Academic Event';
      final place = e['venue']?.toString() ?? 'Campus';
      final time =
          '${e['startTime'] ?? "10:00 AM"} – ${e['endTime'] ?? "12:00 PM"}';
      return {
        'month': 'EVENT',
        'day': '',
        'title': title,
        'place': place,
        'time': time,
        'color': const Color(0xFF2563EB),
      };
    }).toList();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_month_outlined,
                color: Color(0xFF2563EB),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Campus Events',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => repo.selectedMenuIndex = 1,
                child: Text(
                  'View All',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF2563EB),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (events.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No upcoming campus events scheduled',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            )
          else
            for (final e in events) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 3.5,
                      height: 38,
                      decoration: BoxDecoration(
                        color: e['color'] as Color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 30,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            e['month'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                          Text(
                            e['day'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e['title'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 13,
                                color: Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                e['place'] as String,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.access_time_outlined,
                                size: 13,
                                color: Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  e['time'] as String,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF64748B),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
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
    );
  }

  // Quick Links
  Widget _buildQuickLinksCard() {
    final links = [
      {
        'icon': Icons.people_alt_outlined,
        'label': 'Student List',
        'color': const Color(0xFF4F46E5),
        'bg': const Color(0xFFF5F3FF),
        'idx': 3,
      },
      {
        'icon': Icons.how_to_reg_outlined,
        'label': 'Class Attendance',
        'color': const Color(0xFF2563EB),
        'bg': const Color(0xFFEFF6FF),
        'idx': 3,
      },
      {
        'icon': Icons.edit_note_outlined,
        'label': 'Marks Entry',
        'color': const Color(0xFF0EA5E9),
        'bg': const Color(0xFFF0F9FF),
        'idx': 4,
      },
      {
        'icon': Icons.menu_book_outlined,
        'label': 'Lesson Progress',
        'color': const Color(0xFF10B981),
        'bg': const Color(0xFFF0FDF4),
        'idx': 5,
      },
      {
        'icon': Icons.campaign_outlined,
        'label': 'Notice Board',
        'color': const Color(0xFFF97316),
        'bg': const Color(0xFFFFF7ED),
        'idx': 9,
      },
      {
        'icon': Icons.help_outline_rounded,
        'label': 'Question Bank',
        'color': const Color(0xFF8B5CF6),
        'bg': const Color(0xFFF5F3FF),
        'idx': 7,
      },
    ];

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.link_rounded,
                color: Color(0xFF2563EB),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Quick Links',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.8,
            children: links
                .map(
                  (l) => MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => repo.selectedMenuIndex =
                          (l['idx'] as num? ?? 0).toInt(),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: l['bg'] as Color,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              l['icon'] as IconData,
                              color: l['color'] as Color,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              l['label'] as String,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SHARED HELPERS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _card({required Widget child, Color? leftBorder}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: leftBorder != null
            ? Border(left: BorderSide(color: leftBorder, width: 3.5))
            : Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _badgePill(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: fg,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _profileImage(double size, {double iconSize = 24}) {
    final rawUrl = repo.profile['photoUrl'] as String? ?? '';
    // Only load URLs that are base64 data URIs or direct HTTPS URLs (not Google search pages)
    final photoUrl =
        (rawUrl.startsWith('data:image/') ||
            (rawUrl.startsWith('https://') &&
                !rawUrl.contains('google.com') &&
                !rawUrl.contains('ksrce.ac.in')))
        ? rawUrl
        : '';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      child: ClipOval(
        child: photoUrl.isNotEmpty
            ? Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) =>
                    Icon(Icons.person, size: iconSize, color: Colors.white),
              )
            : Icon(Icons.person, size: iconSize, color: Colors.white),
      ),
    );
  }
}
