// ignore_for_file: deprecated_member_use, unused_element, unused_local_variable, prefer_interpolation_to_compose_strings, avoid_web_libraries_in_flutter
import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:math' as math;
import '../models/app_state.dart';
import '../services/supabase_service.dart';

class AssignmentItem {
  final String id;
  final String title;
  final String description;
  final String badge;
  final String subject;
  final String subjectCode;
  final String dueDate;
  final String dueTime;
  final String status;
  final String subtext;
  final bool isOverdue;
  final dynamic score;
  final int totalMarks;
  final String? attachmentUrl;
  final String? attachmentName;
  final String? submittedFileUrl;
  final String? feedback;
  final bool allowLateSubmission;
  final double lateDeductionPct;
  final String? submittedAt;
  final bool isLate;

  AssignmentItem({
    required this.id,
    required this.title,
    required this.description,
    required this.badge,
    required this.subject,
    required this.subjectCode,
    required this.dueDate,
    required this.dueTime,
    required this.status,
    required this.subtext,
    this.isOverdue = false,
    this.score,
    this.totalMarks = 100,
    this.attachmentUrl,
    this.attachmentName,
    this.submittedFileUrl,
    this.feedback,
    this.allowLateSubmission = true,
    this.lateDeductionPct = 0.0,
    this.submittedAt,
    this.isLate = false,
  });
}

class AssignmentsScreen extends StatefulWidget {
  final Function(int)? onNavigate;
  const AssignmentsScreen({super.key, this.onNavigate});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  String _activeTab = 'All'; // All, Pending, Submitted, Graded, Overdue
  String _searchQuery = '';
  int _currentPage = 1;
  final int _itemsPerPage = 5;

  // Calendar selected month and year, defaults to today's date
  int _selectedCalendarYear = DateTime.now().year;
  int _selectedCalendarMonth = DateTime.now().month;
  DateTime? _clickedCalendarDate;

  List<AssignmentItem> _getAssignmentsFromDb() {
    try {
      final appState = AppStateProvider.of(context);
      final dbAssignments = appState.assignmentsList;
      final dbMarks = appState.assignmentMarks;

      if (dbAssignments.isEmpty) {
        return [];
      }

      final studentRegNo = appState.getProfileField('register_no', defaultValue: appState.studentId);
      final studentIdVal = appState.dbStudentUuid ?? appState.studentId;

      final List<AssignmentItem> list = [];
      for (var a in dbAssignments) {
        final id = a['id']?.toString() ?? '';
        final title = a['title'] ?? a['assignment_title'] ?? 'Assignment';
        final desc = a['description'] ?? '';
        final code = a['course_code'] ?? a['subject_code'] ?? '24CST57';
        final subjectName = a['subject_name'] ?? 'Theory of Computation';
        final totalMarks = int.tryParse(a['total_marks']?.toString() ?? a['max_marks']?.toString() ?? '100') ?? 100;
        final dueDateStr = a['due_date']?.toString() ?? '';
        final attachmentUrl = a['attachment_url']?.toString();
        final attachmentName = a['attachment_name']?.toString();
        final allowLate = a['allow_late_submission'] == true || a['allow_late_submission'] == null;
        final lateDeduction = double.tryParse(a['late_deduction_pct']?.toString() ?? '0.0') ?? 0.0;

        // Match student submission in faculty.assignment_marks
        final submitted = dbMarks.where((m) {
          final mId = m['assignment_id']?.toString() ?? '';
          final mReg = m['reg_no']?.toString() ?? '';
          final mStud = m['student_id']?.toString() ?? '';
          return mId == id && (mReg == studentRegNo || mStud == studentIdVal || mReg == studentIdVal);
        }).toList();

        String status = 'Pending';
        dynamic scoreVal;
        String subtext = 'Due by $dueDateStr';
        bool isOver = false;
        String? feedbackText;
        String? submittedFile;
        String? submittedTime;
        bool isLateVal = false;

        if (submitted.isNotEmpty) {
          final m = submitted.first;
          final dbStatus = m['status']?.toString() ?? 'Submitted';
          submittedFile = m['assignment_file']?.toString();
          submittedTime = m['submitted_at']?.toString() ?? m['submitted_date']?.toString();
          isLateVal = m['is_late'] == true;
          feedbackText = m['feedback']?.toString();
          
          final marksObtained = m['marks'] ?? m['marks_obtained'];
          if (dbStatus.toLowerCase() == 'graded' || marksObtained != null) {
            status = 'Graded';
            scoreVal = marksObtained;
            subtext = 'Graded: $scoreVal / $totalMarks';
          } else {
            status = 'Submitted';
            final dateDisplay = (submittedTime != null && submittedTime.contains('T'))
                ? submittedTime.split('T')[0]
                : (submittedTime ?? '');
            subtext = 'Submitted on $dateDisplay';
          }
        } else {
          try {
            if (dueDateStr.isNotEmpty) {
              final due = DateTime.parse(dueDateStr);
              if (due.isBefore(DateTime.now())) {
                status = 'Overdue';
                isOver = true;
                final days = DateTime.now().difference(due).inDays;
                subtext = 'Overdue by ${days == 0 ? 1 : days} Days';
              }
            }
          } catch (_) {}
        }

        list.add(AssignmentItem(
          id: id,
          title: title,
          description: desc,
          badge: status,
          subject: subjectName,
          subjectCode: code,
          dueDate: dueDateStr,
          dueTime: '11:59 PM',
          status: status,
          subtext: subtext,
          isOverdue: isOver,
          score: scoreVal,
          totalMarks: totalMarks,
          attachmentUrl: (attachmentUrl != null && attachmentUrl.isNotEmpty) ? attachmentUrl : null,
          attachmentName: (attachmentName != null && attachmentName.isNotEmpty) ? attachmentName : null,
          submittedFileUrl: (submittedFile != null && submittedFile.isNotEmpty) ? submittedFile : null,
          feedback: feedbackText,
          allowLateSubmission: allowLate,
          lateDeductionPct: lateDeduction,
          submittedAt: submittedTime,
          isLate: isLateVal,
        ));
      }
      return list;
    } catch (e) {
      debugPrint('Error loading assignments from DB: $e');
      return [];
    }
  }

  List<AssignmentItem> get _assignments {
    return _getAssignmentsFromDb();
  }

  DateTime? _parseDate(String dateStr) {
    final s = dateStr.trim();
    if (s.isEmpty) return null;
    try {
      if (s.contains('-')) {
        return DateTime.parse(s.replaceFirst(' ', 'T'));
      }
      final parts = dateStr.split(' ');
      if (parts.length >= 3) {
        final day = int.tryParse(parts[0]) ?? 1;
        final year = int.tryParse(parts[2]) ?? 2026;
        int month = 8;
        switch (parts[1].toLowerCase()) {
          case 'jan': case 'january': month = 1; break;
          case 'feb': case 'february': month = 2; break;
          case 'mar': case 'march': month = 3; break;
          case 'apr': case 'april': month = 4; break;
          case 'may': month = 5; break;
          case 'jun': case 'june': month = 6; break;
          case 'jul': case 'july': month = 7; break;
          case 'aug': case 'august': month = 8; break;
          case 'sep': case 'september': month = 9; break;
          case 'oct': case 'october': month = 10; break;
          case 'nov': case 'november': month = 11; break;
          case 'dec': case 'december': month = 12; break;
        }
        return DateTime(year, month, day);
      }
    } catch (_) {}
    return null;
  }

  void _showUploadModal(AssignmentItem item) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _UploadAssignmentDialog(
          item: item,
          onSubmitted: () async {
            final appState = AppStateProvider.of(context);
            await appState.refreshAssignments();
          },
        );
      },
    );
  }

  void _showViewSubmissionDialog(AssignmentItem item) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.assignment_turned_in_outlined, color: Color(0xFF2563EB)),
              const SizedBox(width: 8),
              Expanded(child: Text('Submission Details: ${item.subjectCode}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                const SizedBox(height: 4),
                Text(item.subject, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Status: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: item.status == 'Graded' ? const Color(0xFFEFF6FF) : const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.status,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: item.status == 'Graded' ? const Color(0xFF2563EB) : const Color(0xFF16A34A),
                        ),
                      ),
                    ),
                    if (item.isLate) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(6)),
                        child: const Text('Late', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                      ),
                    ],
                  ],
                ),
                if (item.status == 'Graded' && item.score != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.stars_rounded, color: Color(0xFF2563EB), size: 22),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Graded Score', style: TextStyle(fontSize: 11, color: Color(0xFF1D4ED8), fontWeight: FontWeight.w600)),
                            Text(
                              '${item.score} / ${item.totalMarks}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                if (item.feedback != null && item.feedback!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Faculty Feedback:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E293B))),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
                    child: Text(item.feedback!, style: const TextStyle(fontSize: 12, color: Color(0xFF334155))),
                  ),
                ],
                const SizedBox(height: 14),
                const Text('Submitted Answer File:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E293B))),
                const SizedBox(height: 6),
                if (item.submittedFileUrl != null && item.submittedFileUrl!.isNotEmpty)
                  InkWell(
                    onTap: () {
                      html.window.open(item.submittedFileUrl!, '_blank');
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.file_present_rounded, color: Color(0xFF16A34A), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.submittedFileUrl!.split('/').last,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF15803D), decoration: TextDecoration.underline),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.open_in_new, size: 16, color: Color(0xFF15803D)),
                        ],
                      ),
                    ),
                  )
                else
                  const Text('No file record attached.', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Close')),
            if (item.status != 'Graded' || item.allowLateSubmission)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  _showUploadModal(item);
                },
                icon: const Icon(Icons.upload_file, size: 14),
                label: const Text('Re-submit File'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
              ),
          ],
        );
      },
    );
  }

  List<AssignmentItem> get _filteredAssignments {
    return _assignments.where((item) {
      final matchesSearch = item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.subject.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.subjectCode.toLowerCase().contains(_searchQuery.toLowerCase());

      if (!matchesSearch) return false;

      // Filter by calendar date
      if (_clickedCalendarDate != null) {
        final due = _parseDate(item.dueDate);
        final matchesDate = due != null &&
            due.year == _clickedCalendarDate!.year &&
            due.month == _clickedCalendarDate!.month &&
            due.day == _clickedCalendarDate!.day;
        return matchesDate;
      }

      // Filter by tab
      bool matchesTab = true;
      switch (_activeTab) {
        case 'Pending':
          matchesTab = item.status == 'Pending' || item.status == 'Not Started';
          break;
        case 'Submitted':
          matchesTab = item.status == 'Submitted';
          break;
        case 'Graded':
          matchesTab = item.status == 'Graded';
          break;
        case 'Overdue':
          matchesTab = item.isOverdue;
          break;
        default:
          matchesTab = true;
      }
      return matchesTab;
    }).toList();
  }

  void _switchTab(String tab) {
    setState(() {
      _activeTab = tab;
      _currentPage = 1;
      _clickedCalendarDate = null;
    });
  }

  Widget _buildTopSearchBar() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
            _currentPage = 1;
          });
        },
        decoration: const InputDecoration(
          hintText: 'Search assignments by title, subject, code or description...',
          hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          prefixIcon: Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1200;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopSearchBar(),
          const SizedBox(height: 24),
          _buildStatsBannerRow(isDesktop),
          const SizedBox(height: 24),
          isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 8, child: _buildLeftAssignmentFeed()),
                    const SizedBox(width: 24),
                    Expanded(flex: 3, child: _buildRightSidebar()),
                  ],
                )
              : Column(
                  children: [
                    _buildLeftAssignmentFeed(),
                    const SizedBox(height: 24),
                    _buildRightSidebar(),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildStatsBannerRow(bool isDesktop) {
    return LayoutBuilder(builder: (context, constraints) {
      final double cardWidth = (constraints.maxWidth - 3 * 12) / 4;
      final showScroll = constraints.maxWidth < 950;

      final total = _assignments.length;
      final submitted = _assignments.where((a) => a.status == 'Submitted').length;
      final pending = _assignments.where((a) => a.status == 'Pending' || a.status == 'Not Started').length;
      final graded = _assignments.where((a) => a.status == 'Graded').length;

      final List<Widget> cards = [
        _buildStatCard('Total Assignments', '$total', 'This Semester', Icons.assignment_outlined, const Color(0xFF2563EB), const Color(0xFFEFF6FF)),
        _buildStatCard('Submitted', '$submitted', 'Awaiting Grade', Icons.cloud_done_outlined, const Color(0xFF10B981), const Color(0xFFF0FDF4)),
        _buildStatCard('Graded', '$graded', 'Completed', Icons.stars_outlined, const Color(0xFF8B5CF6), const Color(0xFFF3E8FF)),
        _buildStatCard('Pending', '$pending', 'Action Required', Icons.hourglass_empty, const Color(0xFFEA580C), const Color(0xFFFFF7ED)),
      ];

      if (showScroll) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: cards.map((c) => Padding(padding: const EdgeInsets.only(right: 12.0), child: SizedBox(width: 170, child: c))).toList(),
          ),
        );
      } else {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: cards.map((c) => SizedBox(width: cardWidth, child: c)).toList(),
        );
      }
    });
  }

  Widget _buildStatCard(String label, String value, String sub, IconData icon, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
                const SizedBox(height: 2),
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                Text(sub, style: const TextStyle(fontSize: 8, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftAssignmentFeed() {
    final list = _filteredAssignments;
    final totalCount = list.length;
    final totalPages = (totalCount / _itemsPerPage).ceil();

    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    final displayedList = list.sublist(startIndex, endIndex > totalCount ? totalCount : endIndex);

    final List<String> monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    final allCount = _assignments.length;
    final pendingCount = _assignments.where((a) => a.status == 'Pending' || a.status == 'Not Started').length;
    final submittedCount = _assignments.where((a) => a.status == 'Submitted').length;
    final gradedCount = _assignments.where((a) => a.status == 'Graded').length;
    final overdueCount = _assignments.where((a) => a.isOverdue).length;

    String getTabLabel(String tab) {
      if (tab == 'All') return 'All Assignments ($allCount)';
      if (tab == 'Pending') return 'Pending ($pendingCount)';
      if (tab == 'Submitted') return 'Submitted ($submittedCount)';
      if (tab == 'Graded') return 'Graded ($gradedCount)';
      if (tab == 'Overdue') return 'Overdue ($overdueCount)';
      return '$tab (0)';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(builder: (context, constraints) {
            final tabs = ['All', 'Pending', 'Submitted', 'Graded', 'Overdue'];

            if (constraints.maxWidth < 750) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: tabs.map((tab) {
                    final isSel = _activeTab == tab;
                    final labelText = getTabLabel(tab);

                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: InkWell(
                        onTap: () => _switchTab(tab),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSel ? const Color(0xFF2563EB) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSel ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Text(
                            labelText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSel ? Colors.white : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            } else {
              final double spacing = 8.0;
              final List<Widget> tabWidgets = tabs.map((tab) {
                final isSel = _activeTab == tab;
                final labelText = getTabLabel(tab);

                return Expanded(
                  child: InkWell(
                    onTap: () => _switchTab(tab),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSel ? const Color(0xFF2563EB) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSel ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Text(
                        labelText,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSel ? Colors.white : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList();

              final List<Widget> childrenWithSpacing = [];
              for (int i = 0; i < tabWidgets.length; i++) {
                childrenWithSpacing.add(tabWidgets[i]);
                if (i < tabWidgets.length - 1) {
                  childrenWithSpacing.add(SizedBox(width: spacing));
                }
              }

              return Row(
                children: childrenWithSpacing,
              );
            }
          }),
          const SizedBox(height: 20),
          if (_clickedCalendarDate != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFDBEAFE)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.filter_list, size: 14, color: Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Filtered by Due Date: ${_clickedCalendarDate!.day} ${monthNames[_clickedCalendarDate!.month - 1]} ${_clickedCalendarDate!.year}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _clickedCalendarDate = null;
                      });
                    },
                    child: const Icon(Icons.cancel, size: 16, color: Color(0xFF2563EB)),
                  ),
                ],
              ),
            ),
          ],
          LayoutBuilder(builder: (context, constraints) {
            final double minWidth = math.max(constraints.maxWidth, 800.0);
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: minWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
                      ),
                      child: Row(
                        children: const [
                          Expanded(flex: 4, child: Text('Assignment', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                          Expanded(flex: 3, child: Text('Subject', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                          Expanded(flex: 3, child: Text('Question Paper', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                          Expanded(flex: 3, child: Text('Due Date', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                          Expanded(flex: 3, child: Text('Status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                          Expanded(flex: 3, child: Text('Action', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        ...displayedList.map((item) => _buildAssignmentRow(item)),
                        if (displayedList.isEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            alignment: Alignment.center,
                            child: const Text('No assignments published for your section yet.', style: TextStyle(color: Color(0xFF94A3B8))),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
          LayoutBuilder(builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            final textWidget = Text(
              'Showing ${startIndex + 1} to ${endIndex > totalCount ? totalCount : endIndex} of $totalCount assignments',
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            );

            final pageButtonsWidget = SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 16),
                    onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                  ),
                  ...List.generate(totalPages > 0 ? totalPages : 1, (index) {
                    final p = index + 1;
                    final isSel = _currentPage == p;
                    return InkWell(
                      onTap: () => setState(() => _currentPage = p),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFF2563EB) : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '$p',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSel ? Colors.white : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    );
                  }),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 16),
                    onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
                  ),
                ],
              ),
            );

            return isMobile
                ? Column(
                    children: [
                      textWidget,
                      const SizedBox(height: 8),
                      pageButtonsWidget,
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      textWidget,
                      pageButtonsWidget,
                    ],
                  );
          }),
        ],
      ),
    );
  }

  Widget _buildAssignmentRow(AssignmentItem item) {
    Color iconColor = const Color(0xFF2563EB);
    Color iconBg = const Color(0xFFEFF6FF);
    Color statusBg;
    Color statusText;

    final statLower = item.status.toLowerCase();
    if (statLower == 'submitted') {
      statusBg = const Color(0xFFF0FDF4);
      statusText = const Color(0xFF16A34A);
    } else if (statLower == 'pending') {
      statusBg = const Color(0xFFFFF7ED);
      statusText = const Color(0xFFEA580C);
    } else if (statLower == 'graded') {
      statusBg = const Color(0xFFEFF6FF);
      statusText = const Color(0xFF2563EB);
    } else if (item.isOverdue) {
      statusBg = const Color(0xFFFEF2F2);
      statusText = const Color(0xFFDC2626);
    } else {
      statusBg = const Color(0xFFF8FAFC);
      statusText = const Color(0xFF64748B);
    }

    Color dueDateColor = const Color(0xFF1E293B);
    if (item.isOverdue || statLower == 'pending') {
      dueDateColor = const Color(0xFFDC2626);
    } else if (statLower == 'submitted' || statLower == 'graded') {
      dueDateColor = const Color(0xFF16A34A);
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
      child: Row(
        children: [
          // Column 1: Assignment Details
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.description_outlined, color: iconColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(item.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      const SizedBox(height: 2),
                      Text(item.description.isNotEmpty ? item.description : 'No description provided', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(4)),
                        child: Text('Max: ${item.totalMarks} Marks', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: iconColor)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Column 2: Subject
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(item.subject, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(height: 2),
                Text(item.subjectCode, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
              ],
            ),
          ),
          // Column 3: Question Paper / Attachment
          Expanded(
            flex: 3,
            child: item.attachmentUrl != null
                ? InkWell(
                    onTap: () {
                      html.window.open(item.attachmentUrl!, '_blank');
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.picture_as_pdf, size: 14, color: Color(0xFFEF4444)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.attachmentName ?? 'Question_Paper.pdf',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF2563EB),
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )
                : const Text('No question file', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
          ),
          // Column 4: Due Date
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 10, color: dueDateColor),
                    const SizedBox(width: 4),
                    Text(item.dueDate, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: dueDateColor)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(item.dueTime, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
                if (item.isOverdue) ...[
                  const SizedBox(height: 2),
                  const Text('Overdue', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                ],
              ],
            ),
          ),
          // Column 5: Status
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    item.status,
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusText),
                  ),
                ),
                const SizedBox(height: 4),
                Text(item.subtext, style: TextStyle(fontSize: 9, color: statusText, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          // Column 6: Action Button
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 28,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        if (item.status == 'Submitted' || item.status == 'Graded') {
                          _showViewSubmissionDialog(item);
                        } else {
                          _showUploadModal(item);
                        }
                      },
                      icon: Icon(
                        item.status == 'Submitted' || item.status == 'Graded'
                            ? Icons.visibility_outlined
                            : Icons.file_upload_outlined,
                        size: 11,
                        color: const Color(0xFF2563EB),
                      ),
                      label: Text(
                        item.status == 'Submitted' || item.status == 'Graded'
                            ? 'View'
                            : 'Upload',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        side: const BorderSide(color: Color(0xFF2563EB)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
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

  Widget _buildRightSidebar() {
    return Column(
      children: [
        _buildCalendarCard(),
      ],
    );
  }

  Widget _buildCalendarCard() {
    final firstDay = DateTime(_selectedCalendarYear, _selectedCalendarMonth, 1);
    final totalDays = DateTime(_selectedCalendarYear, _selectedCalendarMonth + 1, 0).day;
    final offset = firstDay.weekday % 7;

    final List<String> monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 16, color: Color(0xFF64748B)),
                onPressed: () {
                  setState(() {
                    if (_selectedCalendarMonth == 1) {
                      _selectedCalendarMonth = 12;
                      _selectedCalendarYear--;
                    } else {
                      _selectedCalendarMonth--;
                    }
                  });
                },
              ),
              Row(
                children: [
                  DropdownButton<int>(
                    value: _selectedCalendarMonth,
                    isDense: true,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    underline: const SizedBox(),
                    items: List.generate(12, (index) => DropdownMenuItem(value: index + 1, child: Text(monthNames[index]))),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedCalendarMonth = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(width: 6),
                  DropdownButton<int>(
                    value: _selectedCalendarYear,
                    isDense: true,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    underline: const SizedBox(),
                    items: [2023, 2024, 2025, 2026, 2027].map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedCalendarYear = val;
                        });
                      }
                    },
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 16, color: Color(0xFF64748B)),
                onPressed: () {
                  setState(() {
                    if (_selectedCalendarMonth == 12) {
                      _selectedCalendarMonth = 1;
                      _selectedCalendarYear++;
                    } else {
                      _selectedCalendarMonth++;
                    }
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'].map((d) {
              return Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 42,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (context, idx) {
              final cellIndex = idx - offset;
              if (cellIndex < 0 || cellIndex >= totalDays) {
                return const SizedBox();
              }
              final dayNum = cellIndex + 1;
              final cellDate = DateTime(_selectedCalendarYear, _selectedCalendarMonth, dayNum);

              final dayAssignments = _assignments.where((a) {
                final due = _parseDate(a.dueDate);
                return due != null &&
                    due.year == cellDate.year &&
                    due.month == cellDate.month &&
                    due.day == cellDate.day;
              }).toList();

              final hasAssignments = dayAssignments.isNotEmpty;
              final hasPending = dayAssignments.any((a) => a.status == 'Pending' || a.isOverdue);
              final isSelected = _clickedCalendarDate != null &&
                  _clickedCalendarDate!.year == cellDate.year &&
                  _clickedCalendarDate!.month == cellDate.month &&
                  _clickedCalendarDate!.day == cellDate.day;

              Color bgColor = Colors.transparent;
              Color textColor = const Color(0xFF334155);

              if (isSelected) {
                bgColor = const Color(0xFF2563EB);
                textColor = Colors.white;
              } else if (hasPending) {
                bgColor = const Color(0xFFFEF2F2);
                textColor = const Color(0xFFDC2626);
              } else if (hasAssignments) {
                bgColor = const Color(0xFFF0FDF4);
                textColor = const Color(0xFF16A34A);
              }

              return InkWell(
                onTap: hasAssignments
                    ? () {
                        setState(() {
                          if (isSelected) {
                            _clickedCalendarDate = null;
                          } else {
                            _clickedCalendarDate = cellDate;
                          }
                          _currentPage = 1;
                        });
                      }
                    : null,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(6),
                    border: isSelected ? Border.all(color: const Color(0xFF1D4ED8), width: 1.5) : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$dayNum', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor)),
                      if (hasAssignments && !isSelected)
                        Container(
                          width: 4, height: 4,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(color: hasPending ? const Color(0xFFDC2626) : const Color(0xFF16A34A), shape: BoxShape.circle),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _UploadAssignmentDialog extends StatefulWidget {
  final AssignmentItem item;
  final VoidCallback onSubmitted;

  const _UploadAssignmentDialog({
    required this.item,
    required this.onSubmitted,
  });

  @override
  State<_UploadAssignmentDialog> createState() => _UploadAssignmentDialogState();
}

class _UploadAssignmentDialogState extends State<_UploadAssignmentDialog> {
  String? _stagedFileName;
  List<int>? _stagedBytes;
  bool _isSubmitting = false;

  void _pickDocument() {
    final uploadInput = html.FileUploadInputElement()..accept = '.pdf,.doc,.docx,.zip,.png,.jpg,.jpeg';
    uploadInput.click();

    uploadInput.onChange.listen((event) {
      final files = uploadInput.files;
      if (files != null && files.isNotEmpty) {
        final file = files[0];
        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);
        reader.onLoadEnd.listen((e) {
          if (mounted) {
            setState(() {
              _stagedFileName = file.name;
              _stagedBytes = reader.result as List<int>;
            });
          }
        });
      }
    });
  }

  Future<void> _submitDocument() async {
    if (_stagedBytes == null || _stagedFileName == null) return;

    setState(() => _isSubmitting = true);

    final messenger = ScaffoldMessenger.of(context);
    final appState = AppStateProvider.of(context);
    final studentId = appState.getProfileField('student_id').isNotEmpty ? appState.getProfileField('student_id') : appState.studentId;
    final regNo = appState.getProfileField('register_no', defaultValue: appState.studentId);
    final studentName = appState.getProfileField('full_name').isNotEmpty ? appState.getProfileField('full_name') : appState.studentName;
    final dept = appState.getProfileField('department', defaultValue: 'CSE');
    final sec = appState.getProfileField('section', defaultValue: 'A');

    messenger.showSnackBar(
      SnackBar(
        content: Text('Uploading "$_stagedFileName" to Supabase storage...'),
        backgroundColor: const Color(0xFF2563EB),
      ),
    );

    final publicUrl = await SupabaseService.instance.uploadAssignmentFile(studentId, _stagedFileName!, _stagedBytes!);

    if (publicUrl != null) {
      bool isLate = false;
      try {
        if (widget.item.dueDate.isNotEmpty) {
          final due = DateTime.parse(widget.item.dueDate);
          if (DateTime.now().isAfter(due)) {
            isLate = true;
          }
        }
      } catch (_) {}

      final ok = await SupabaseService.instance.submitAssignment(
        assignmentId: widget.item.id,
        regNo: regNo,
        studentId: studentId,
        studentName: studentName,
        department: dept,
        section: sec,
        subjectCode: widget.item.subjectCode,
        fileUrl: publicUrl,
        isLate: isLate,
      );

      if (mounted) {
        setState(() => _isSubmitting = false);
        if (ok) {
          widget.onSubmitted();
          Navigator.pop(context);
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Assignment submitted successfully! Linked with Faculty module.'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        } else {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Error saving submission to database. Please try again.'),
              backgroundColor: Color(0xFFDC2626),
            ),
          );
        }
      }
    } else if (mounted) {
      setState(() => _isSubmitting = false);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Error uploading file to storage bucket.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.file_upload_outlined, color: Color(0xFF2563EB)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Upload Assignment: ${widget.item.subjectCode}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.item.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 4),
              Text(
                widget.item.subject,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.event_outlined, size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Text('Due Date: ${widget.item.dueDate}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(4)),
                    child: Text('Max: ${widget.item.totalMarks} Marks', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                  ),
                ],
              ),
              if (widget.item.attachmentUrl != null) ...[
                const SizedBox(height: 12),
                InkWell(
                  onTap: () {
                    html.window.open(widget.item.attachmentUrl!, '_blank');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.picture_as_pdf, color: Color(0xFFDC2626), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.item.attachmentName ?? 'Download Question Paper.pdf',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.download, size: 14, color: Color(0xFFDC2626)),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Text('Select Answer Document:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E293B))),
              const SizedBox(height: 8),
              if (_stagedBytes == null)
                InkWell(
                  onTap: _pickDocument,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
                    ),
                    child: Column(
                      children: const [
                        Icon(Icons.cloud_upload_outlined, color: Color(0xFF2563EB), size: 36),
                        SizedBox(height: 8),
                        Text(
                          'Click to select document',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Supports PDF, DOCX, PNG, ZIP (Max 10MB)',
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.insert_drive_file, color: Color(0xFF16A34A), size: 28),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _stagedFileName!,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF14532D)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Size: ${(_stagedBytes!.length / 1024).toStringAsFixed(1)} KB • Ready to submit',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF166534)),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 20),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isSubmitting ? null : _pickDocument,
                              icon: const Icon(Icons.refresh, size: 14, color: Color(0xFF2563EB)),
                              label: const Text('Reupload', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF2563EB)),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isSubmitting ? null : _submitDocument,
                              icon: _isSubmitting
                                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.send, size: 14, color: Colors.white),
                              label: Text(_isSubmitting ? 'Submitting...' : 'Submit', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
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
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}