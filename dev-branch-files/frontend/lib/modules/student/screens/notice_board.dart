// ignore_for_file: deprecated_member_use, unused_element, unused_field, prefer_final_fields
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:html' as html;
import 'dart:convert';
import '../models/app_state.dart';

class NoticeItem {
  final String id;
  final String title;
  final String category;
  final String content;
  final String date;
  final String time;
  final String author;
  final bool hasAttachment;
  final String attachmentName;
  bool isPinned;

  NoticeItem({
    required this.id,
    required this.title,
    required this.category,
    required this.content,
    required this.date,
    required this.time,
    required this.author,
    this.hasAttachment = false,
    this.attachmentName = '',
    this.isPinned = false,
  });
}

class NoticeBoardScreen extends StatefulWidget {
  final Function(int)? onNavigate;
  const NoticeBoardScreen({super.key, this.onNavigate});

  @override
  State<NoticeBoardScreen> createState() => _NoticeBoardScreenState();
}

class _NoticeBoardScreenState extends State<NoticeBoardScreen> {
  String _searchQuery = '';
  String _activeChip = 'All';
  String _activeCategoryList = 'All Categories';
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  // Notices Database matching mockup grid exactly
  late List<NoticeItem> _allNotices;

  final Map<String, GlobalKey> _feedCardKeys = {};
  String? _highlightedNoticeId;

  @override
  void initState() {
    super.initState();
    _allNotices = [
      NoticeItem(
        id: '1',
        title: 'End Semester Examination Timetable - May 2024',
        category: 'Exam',
        content: 'The end semester examination schedule for all B.E / B.Tech programs has been published. Exams commence on May 20, 2024.',
        date: '2026-08-10',
        time: '10:30 AM',
        author: 'Controller of Exams',
        hasAttachment: true,
        attachmentName: 'EndSem_Schedule_2024.pdf',
        isPinned: true,
      ),
      NoticeItem(
        id: '2',
        title: 'Campus Recruitment Drive - Tata Consultancy Services',
        category: 'Placement',
        content: 'TCS is conducting campus interviews for final year students on May 25. Eligible students must register before May 22.',
        date: '2026-08-10',
        time: '02:15 PM',
        author: 'Placement Cell',
        hasAttachment: true,
        attachmentName: 'TCS_Eligibility_Criteria.pdf',
        isPinned: false,
      ),
      NoticeItem(
        id: '3',
        title: 'National Conference on AI & Robotics 2024',
        category: 'Events',
        content: 'Department of CSE is organizing a 2-day national conference. Paper submissions open till June 1, 2024.',
        date: '2026-08-09',
        time: '11:00 AM',
        author: 'HOD CSE',
        hasAttachment: false,
        attachmentName: '',
        isPinned: false,
      ),
      NoticeItem(
        id: '4',
        title: 'Tuition & Special Fee Payment Deadline Extension',
        category: 'General',
        content: 'The last date for paying odd semester fees has been extended to May 30, 2024 without late charges.',
        date: '2026-08-08',
        time: '04:45 PM',
        author: 'Finance Office',
        hasAttachment: false,
        attachmentName: '',
        isPinned: false,
      ),
      NoticeItem(
        id: '5',
        title: 'Library Working Hours During Exam Period',
        category: 'Library',
        content: 'Central library will remain open till 11:00 PM on all working days and Sundays starting May 15.',
        date: '2026-08-07',
        time: '09:00 AM',
        author: 'Chief Librarian',
        hasAttachment: false,
        attachmentName: '',
        isPinned: false,
      ),
      NoticeItem(
        id: '6',
        title: 'Merit-cum-Means Scholarship 2024 Applications',
        category: 'Scholarship',
        content: 'Applications are invited from eligible undergraduate students for government & alumni scholarships.',
        date: '2026-08-06',
        time: '03:30 PM',
        author: 'Student Welfare',
        hasAttachment: true,
        attachmentName: 'Scholarship_Form_2024.pdf',
        isPinned: false,
      ),
      NoticeItem(
        id: '7',
        title: 'Summer Internship Opportunity - ISRO & DRDO',
        category: 'Academic',
        content: 'Third year students interested in summer research internships at premier R&D labs must submit resumes.',
        date: '2026-08-05',
        time: '01:20 PM',
        author: 'Dean Academics',
        hasAttachment: true,
        attachmentName: 'Internship_Guidelines.pdf',
        isPinned: false,
      ),
      NoticeItem(
        id: '8',
        title: 'Annual Sports Day Selection Trials',
        category: 'Events',
        content: 'Selection trials for track and field events will be held at college grounds tomorrow from 6:00 AM.',
        date: '2026-08-04',
        time: '05:00 PM',
        author: 'Physical Director',
        hasAttachment: false,
        attachmentName: '',
        isPinned: false,
      ),
      NoticeItem(
        id: '9',
        title: 'Circular: Anti-Ragging Awareness & Undertaking',
        category: 'Circular',
        content: 'All students are required to submit their online anti-ragging affidavit on the national portal.',
        date: '2026-08-03',
        time: '10:00 AM',
        author: 'Principal Office',
        hasAttachment: false,
        attachmentName: '',
        isPinned: false,
      ),
      NoticeItem(
        id: '10',
        title: 'NPTEL Online Course Certification Registration',
        category: 'Academic',
        content: 'Enrollment for July-Dec 2024 NPTEL SWAYAM courses is now active. Credit transfer available.',
        date: '2026-08-02',
        time: '02:00 PM',
        author: 'NPTEL Coordinator',
        hasAttachment: false,
        attachmentName: '',
        isPinned: false,
      ),
    ];
  }

  final Set<String> _pinnedNoticeIds = {'1'};

  void _togglePin(NoticeItem notice) {
    setState(() {
      if (_pinnedNoticeIds.contains(notice.id)) {
        _pinnedNoticeIds.remove(notice.id);
        notice.isPinned = false;
      } else {
        _pinnedNoticeIds.add(notice.id);
        notice.isPinned = true;
      }
    });
  }

  List<NoticeItem> _getNoticesFromDb() {
    List<NoticeItem> baseList = _allNotices;
    try {
      final dynamic appState = AppStateProvider.of(context);
      final dynamic dbNotices = appState.notices;
      if (dbNotices != null && dbNotices.isNotEmpty) {
        final List<NoticeItem> list = [];
        for (var n in dbNotices) {
          list.add(NoticeItem(
            id: n.id,
            title: n.title,
            category: n.category,
            content: n.content,
            date: n.date,
            time: n.time,
            author: n.author,
            hasAttachment: n.hasAttachment,
            attachmentName: n.attachmentName,
            isPinned: false,
          ));
        }
        baseList = list;
      }
    } catch (_) {}

    for (var item in baseList) {
      item.isPinned = _pinnedNoticeIds.contains(item.id);
    }
    return baseList;
  }

  List<NoticeItem> get _noticesList {
    return _getNoticesFromDb();
  }

  // Categories Sidebar counts
  Map<String, int> get _categoryCounts {
    final Map<String, int> counts = {
      'All Categories': _noticesList.length,
      'General': _noticesList.where((n) => n.category == 'General').length,
      'Academic': _noticesList.where((n) => n.category == 'Academic').length,
      'Exam': _noticesList.where((n) => n.category == 'Exam').length,
      'Placement': _noticesList.where((n) => n.category == 'Placement').length,
      'Scholarship': _noticesList.where((n) => n.category == 'Scholarship').length,
      'Events': _noticesList.where((n) => n.category == 'Events').length,
      'Library': _noticesList.where((n) => n.category == 'Library').length,
      'Circular': _noticesList.where((n) => n.category == 'Circular').length,
    };
    return counts;
  }

  // Filter notices list
  List<NoticeItem> get _filteredNotices {
    return _noticesList.where((notice) {
      // 1. Search Query filter
      final matchesSearch = notice.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          notice.content.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          notice.category.toLowerCase().contains(_searchQuery.toLowerCase());

      // 2. Chip / Sidebar Categories filter
      bool matchesChip = true;
      if (_activeChip != 'All') {
        matchesChip = notice.category == _activeChip;
      }

      bool matchesSidebar = true;
      if (_activeCategoryList != 'All Categories') {
        matchesSidebar = notice.category == _activeCategoryList;
      }

      return matchesSearch && matchesChip && matchesSidebar;
    }).toList();
  }

  void _openNoticeFromImportant(NoticeItem item) {
    setState(() {
      _searchQuery = '';
      _activeChip = 'All';
      _activeCategoryList = 'All Categories';
      _highlightedNoticeId = item.id;
      _currentPage = 1;
    });

    final idx = _noticesList.indexWhere((n) => n.id == item.id);
    if (idx >= 0) {
      final targetPage = (idx ~/ _itemsPerPage) + 1;
      if (targetPage != _currentPage) {
        setState(() => _currentPage = targetPage);
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final key = _feedCardKeys[item.id];
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          alignment: 0.3,
        );
      }
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _highlightedNoticeId == item.id) {
        setState(() => _highlightedNoticeId = null);
      }
    });
  }

  void _triggerDownloadFile(String filename) {
    final csv = 'Mock PDF Document: $filename';
    final bytes = utf8.encode(csv);
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", filename)
      ..click();
    html.Url.revokeObjectUrl(url);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Downloading file: $filename'), backgroundColor: const Color(0xFF16A34A)),
    );
  }

  void _shareContent(String title, String content) {
    final textToCopy = "$title\n\n$content";
    Clipboard.setData(ClipboardData(text: textToCopy)).then((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Content copied to clipboard in text format!'),
          backgroundColor: Color(0xFF16A34A),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    final list = _noticesList;
    final important = list.where((n) => n.category == 'Exam' || n.category == 'Academic' || n.title.toLowerCase().contains('important')).toList();
    final pinned = list.where((n) => n.isPinned).toList();

    if (isDesktop) {
      // Desktop: original two-column layout with sidebar
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderRow(),
            const SizedBox(height: 20),
            _buildStatsRow(),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 9,
                  child: _buildMiddleNoticeContent(),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 3,
                  child: _buildRightSidebar(),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Mobile: stats + important mini-cards + pinned mini-cards + feed
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderRow(),
          const SizedBox(height: 20),
          _buildStatsRow(),
          const SizedBox(height: 16),
          _buildTopImportantSection(important),
          const SizedBox(height: 12),
          _buildTopPinnedSection(pinned),
          const SizedBox(height: 24),
          _buildMiddleNoticeContent(),
        ],
      ),
    );
  }

  // --- 1. HEADER ROW (Search Bar + Category Dropdown Box) ---
  Widget _buildHeaderRow() {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final searchInput = TextField(
      onChanged: (val) => setState(() => _searchQuery = val),
      decoration: InputDecoration(
        hintText: 'Search notifications...',
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
        prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF94A3B8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
      ),
    );

    final dropdown = _buildCategoriesDropdown();

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          searchInput,
          const SizedBox(height: 12),
          dropdown,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: searchInput),
        const SizedBox(width: 16),
        dropdown,
      ],
    );
  }

  Widget _buildCategoriesDropdown() {
    final categories = [
      'All Categories',
      'General',
      'Academic',
      'Exam',
      'Placement',
      'Scholarship',
      'Events',
      'Library',
      'Circular',
    ];

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
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
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _activeCategoryList,
          icon: const Padding(
            padding: EdgeInsets.only(left: 6.0),
            child: Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF2563EB), size: 18),
          ),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _activeCategoryList = newValue;
              });
            }
          },
          selectedItemBuilder: (BuildContext context) {
            return categories.map<Widget>((String cat) {
              final count = _categoryCounts[cat] ?? 0;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.tune_outlined, size: 16, color: Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  Text(cat, style: const TextStyle(fontSize: 13, color: Color(0xFF334155), fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2563EB),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              );
            }).toList();
          },
          items: categories.map<DropdownMenuItem<String>>((String cat) {
            final count = _categoryCounts[cat] ?? 0;
            final isSel = cat == _activeCategoryList;
            return DropdownMenuItem<String>(
              value: cat,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.folder_outlined, size: 16, color: isSel ? const Color(0xFF2563EB) : const Color(0xFF64748B)),
                  const SizedBox(width: 8),
                  Text(
                    cat,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                      color: isSel ? const Color(0xFF2563EB) : const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSel ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSel ? Colors.white : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // --- 2. STATS CARDS ROW (6 horizontal cards showing dynamic counts) ---
  Widget _buildStatsRow() {
    return LayoutBuilder(builder: (context, constraints) {
      final list = _noticesList;
      final total = list.length;
      final unread = list.where((n) => !n.isPinned).length;
      final academic = list.where((n) => n.category == 'Academic').length;
      final placement = list.where((n) => n.category == 'Placement').length;
      final exam = list.where((n) => n.category == 'Exam').length;
      final events = list.where((n) => n.category == 'Events' || n.category == 'General' || n.category == 'Circular').length;

      final double cardWidth = (constraints.maxWidth - 5 * 12) / 6;
      final showScroll = constraints.maxWidth < 900;

      final List<Widget> cards = [
        _buildStatCard('Total\nNotifications', '$total', Icons.notifications_none, const Color(0xFF2563EB), const Color(0xFFEFF6FF)),
        _buildStatCard('Unread\nNotifications', '$unread', Icons.error_outline, const Color(0xFF8B5CF6), const Color(0xFFF3E8FF)),
        _buildStatCard('Academic\nUpdates', '$academic', Icons.folder_open_outlined, const Color(0xFF3B82F6), const Color(0xFFEFF6FF)),
        _buildStatCard('Placement\nUpdates', '$placement', Icons.work_outline, const Color(0xFF10B981), const Color(0xFFF0FDF4)),
        _buildStatCard('Exam\nUpdates', '$exam', Icons.assignment_outlined, const Color(0xFFEA580C), const Color(0xFFFFF7ED)),
        _buildStatCard('Events\n& Others', '$events', Icons.calendar_today_outlined, const Color(0xFFEC4899), const Color(0xFFFDF2F8)),
      ];

      if (showScroll) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: cards.map((c) => Padding(padding: const EdgeInsets.only(right: 12.0), child: SizedBox(width: 150, child: c))).toList(),
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

  Widget _buildStatCard(String label, String value, IconData icon, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500, height: 1.2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- SECTION 2: MIDDLE RECENT NOTICES CONTENT ---
  Widget _buildMiddleNoticeContent() {
    final list = _filteredNotices;
    final totalCount = list.length;
    final totalPages = (totalCount / _itemsPerPage).ceil();

    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage > totalCount) ? totalCount : startIndex + _itemsPerPage;
    final displayedList = list.isEmpty ? <NoticeItem>[] : list.sublist(startIndex, endIndex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildNoticesCardsGrid(displayedList),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;

            final textWidget = Text(
              totalCount == 0
                  ? 'Showing 0 to 0 of 0 notifications'
                  : 'Showing ${startIndex + 1} to $endIndex of $totalCount notifications',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            );

            final pageButtonsWidget = SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 18),
                    color: _currentPage > 1 ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                    onPressed: _currentPage > 1
                        ? () => setState(() => _currentPage--)
                        : null,
                  ),
                  ...List.generate(totalPages > 0 ? totalPages : 1, (index) {
                    final pageNum = index + 1;
                    final isSelected = _currentPage == pageNum;
                    return InkWell(
                      onTap: () => setState(() => _currentPage = pageNum),
                      child: Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$pageNum',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    );
                  }),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 18),
                    color: _currentPage < totalPages ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                    onPressed: _currentPage < totalPages
                        ? () => setState(() => _currentPage++)
                        : null,
                  ),
                ],
              ),
            );

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        textWidget,
                        const SizedBox(height: 10),
                        pageButtonsWidget,
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        textWidget,
                        pageButtonsWidget,
                      ],
                    ),
            );
          },
        ),
      ],
    );
  }

  void _showNoticeDetailModal(NoticeItem notice) {
    showDialog(
      context: context,
      builder: (context) {
        Color badgeBg = const Color(0xFFEFF6FF);
        Color badgeText = const Color(0xFF2563EB);
        if (notice.category == 'Academic') {
          badgeBg = const Color(0xFFEFF6FF);
          badgeText = const Color(0xFF2563EB);
        } else if (notice.category == 'Placement') {
          badgeBg = const Color(0xFFF0FDF4);
          badgeText = const Color(0xFF16A34A);
        } else if (notice.category == 'Exam' || notice.category == 'Exams') {
          badgeBg = const Color(0xFFF3E8FF);
          badgeText = const Color(0xFF9333EA);
        } else if (notice.category == 'Fees' || notice.category == 'Finance') {
          badgeBg = const Color(0xFFFFF7ED);
          badgeText = const Color(0xFFEA580C);
        } else {
          badgeBg = const Color(0xFFFDF2F8);
          badgeText = const Color(0xFFEC4899);
        }

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(notice.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(4)),
                child: Text(notice.category, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeText)),
              ),
              const SizedBox(height: 12),
              Text(notice.content, style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF1E293B))),
              const SizedBox(height: 12),
              Text('Date: ${notice.date} • ${notice.time}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              const SizedBox(height: 4),
              Text('By: ${notice.author}', style: const TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.bold)),
              if (notice.hasAttachment) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _triggerDownloadFile(notice.attachmentName),
                  icon: const Icon(Icons.download, size: 14),
                  label: Text('Download Attachment (${notice.attachmentName})'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNoticesCardsGrid(List<NoticeItem> list) {
    if (list.isEmpty) {
      return Container(
        height: 180,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Text(
          'No matching notifications found.',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
        ),
      );
    }

    return Column(
      children: list.map((notice) {
        Color badgeBg = const Color(0xFFEFF6FF);
        Color badgeText = const Color(0xFF2563EB);
        if (notice.category == 'Academic') {
          badgeBg = const Color(0xFFEFF6FF);
          badgeText = const Color(0xFF2563EB);
        } else if (notice.category == 'Placement') {
          badgeBg = const Color(0xFFF0FDF4);
          badgeText = const Color(0xFF16A34A);
        } else if (notice.category == 'Exam' || notice.category == 'Exams') {
          badgeBg = const Color(0xFFF3E8FF);
          badgeText = const Color(0xFF9333EA);
        } else if (notice.category == 'Fees' || notice.category == 'Finance') {
          badgeBg = const Color(0xFFFFF7ED);
          badgeText = const Color(0xFFEA580C);
        } else {
          badgeBg = const Color(0xFFFDF2F8);
          badgeText = const Color(0xFFEC4899);
        }

        final isHighlighted = _highlightedNoticeId == notice.id;
        _feedCardKeys[notice.id] ??= GlobalKey();

        return Container(
          key: _feedCardKeys[notice.id],
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isHighlighted ? const Color(0xFFEFF6FF) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isHighlighted ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
              width: isHighlighted ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          notice.category,
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: badgeText),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: notice.isPinned ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          notice.isPinned ? 'HIGH PRIORITY' : 'MEDIUM',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: notice.isPinned ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text('${notice.date} • ${notice.time}', style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
                ],
              ),
              const SizedBox(height: 10),
              Text(notice.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              const SizedBox(height: 4),
              Text(
                notice.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (notice.hasAttachment) ...[
                    InkWell(
                      onTap: () => _triggerDownloadFile(notice.attachmentName),
                      child: const Icon(Icons.link, size: 14, color: Color(0xFF2563EB)),
                    ),
                    const SizedBox(width: 12),
                  ],
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _togglePin(notice),
                    icon: Icon(
                      notice.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                      size: 14,
                      color: notice.isPinned ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _shareContent(notice.title, notice.content),
                    icon: const Icon(Icons.share_outlined, size: 14, color: Color(0xFF64748B)),
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () => _showNoticeDetailModal(notice),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      side: const BorderSide(color: Color(0xFF2563EB)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text('View Details', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // --- SECTION: RIGHT SIDEBAR LAYOUT (desktop only) ---
  Widget _buildRightSidebar() {
    final list = _noticesList;
    final important = list.where((n) => n.category == 'Exam' || n.category == 'Academic' || n.title.toLowerCase().contains('important')).toList();
    final pinned = list.where((n) => n.isPinned).toList();

    return Column(
      children: [
        _buildImportantNotificationsCard(important),
        const SizedBox(height: 20),
        _buildPinnedNoticesCard(pinned),
      ],
    );
  }

  // --- SECTION 3: TOP IMPORTANT SECTION (mini horizontal cards) ---
  Widget _buildTopImportantSection(List<NoticeItem> important) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDBA74).withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.notification_important_rounded, size: 15, color: Color(0xFFEA580C)),
                  SizedBox(width: 6),
                  Text('Important Notifications', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFEA580C))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFDBA74))),
                child: Text('${important.length}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFEA580C))),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (important.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text('No critical announcements at this time.', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: important.take(6).map((n) {
                  return InkWell(
                    onTap: () => _openNoticeFromImportant(n),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 200,
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFEA580C).withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(color: const Color(0xFFFFEDD5), borderRadius: BorderRadius.circular(6)),
                            child: const Icon(Icons.notification_important_outlined, size: 12, color: Color(0xFFEA580C)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(n.title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)), maxLines: 2, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Text('${n.category} • ${n.date}', style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  // --- SECTION 4: TOP PINNED SECTION (mini horizontal cards) ---
  Widget _buildTopPinnedSection(List<NoticeItem> pinned) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCA5A5).withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.push_pin, size: 14, color: Color(0xFFDC2626)),
                  SizedBox(width: 6),
                  Text('Pinned Notices', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFCA5A5))),
                child: Text('${pinned.length}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (pinned.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text('No pinned notices. Pin any notice to see it here.', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: pinned.take(6).map((n) {
                  return InkWell(
                    onTap: () => _openNoticeFromImportant(n),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 200,
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(6)),
                            child: const Icon(Icons.push_pin, size: 12, color: Color(0xFFDC2626)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(n.title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)), maxLines: 2, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Text('${n.category} • ${n.date}', style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImportantNotificationsCard(List<NoticeItem> important) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.notification_important_rounded, size: 16, color: Color(0xFFEA580C)),
                  SizedBox(width: 6),
                  Text('Important Notifications', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFEA580C))),
                ],
              ),
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFDBA74)),
                ),
                child: Text(
                  '${important.length}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFEA580C)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (important.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              width: double.infinity,
              alignment: Alignment.center,
              child: Column(
                children: const [
                  Icon(Icons.check_circle_outline, size: 24, color: Color(0xFF94A3B8)),
                  SizedBox(height: 6),
                  Text(
                    'No Critical Announcements',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            )
          else
            ...important.take(4).map((item) {
              return InkWell(
                onTap: () => _openNoticeFromImportant(item),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFEA580C).withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: const Color(0xFFFFEDD5), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.assignment_outlined, size: 14, color: Color(0xFFEA580C)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text('${item.category} • ${item.date}', style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFFEA580C)),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildPinnedNoticesCard(List<NoticeItem> pinned) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.push_pin, size: 14, color: Color(0xFFDC2626)),
              SizedBox(width: 6),
              Text('Pinned Notices', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
            ],
          ),
          const SizedBox(height: 12),
          if (pinned.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              width: double.infinity,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.push_pin_outlined, size: 24, color: Color(0xFF94A3B8)),
                  SizedBox(height: 8),
                  Text(
                    'No Pinned Notices',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Pin notices to view them here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            )
          else
            ...pinned.map((n) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.15)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.push_pin, size: 14, color: Color(0xFFDC2626)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(n.title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(n.category, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _togglePin(n),
                      child: const Icon(Icons.close, size: 14, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }


  Widget _buildQuickLinksCard() {
    final links = [
      {'title': 'Academic\nCalendar', 'icon': Icons.calendar_month, 'color': const Color(0xFFEFF6FF), 'iconCol': const Color(0xFF2563EB), 'targetIndex': 1},
      {'title': 'Exam Cell', 'icon': Icons.badge_outlined, 'color': const Color(0xFFF0FDF4), 'iconCol': const Color(0xFF10B981), 'targetIndex': 6},
      {'title': 'Placement\nPortal', 'icon': Icons.work_outline, 'color': const Color(0xFFF5F3FF), 'iconCol': const Color(0xFF8B5CF6), 'targetIndex': 17},
      {'title': 'Student\nHandbook', 'icon': Icons.book_outlined, 'color': const Color(0xFFFFF7ED), 'iconCol': const Color(0xFFEA580C), 'targetIndex': 2},
      {'title': 'Time Table', 'icon': Icons.schedule, 'color': const Color(0xFFFDF2F8), 'iconCol': const Color(0xFFEC4899), 'targetIndex': 3},
      {'title': 'Fee Structure', 'icon': Icons.currency_rupee, 'color': const Color(0xFFF0FDFA), 'iconCol': const Color(0xFF0D9488), 'targetIndex': 9},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Links', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 6,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.9,
            ),
            itemBuilder: (context, idx) {
              final q = links[idx];
              return InkWell(
                onTap: () {
                  if (widget.onNavigate != null) {
                    widget.onNavigate!(q['targetIndex'] as int);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  decoration: BoxDecoration(color: q['color'] as Color, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(q['icon'] as IconData, size: 18, color: q['iconCol'] as Color),
                      const SizedBox(height: 4),
                      Text(
                        q['title'] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 7.5,
                          height: 1.1,
                          fontWeight: FontWeight.bold,
                          color: (q['iconCol'] as Color).withOpacity(0.9),
                        ),
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
