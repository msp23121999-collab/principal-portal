// ignore_for_file: deprecated_member_use, unused_element, unused_field, prefer_final_fields, unused_import
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:html' as html;
import 'dart:convert';
import '../models/app_state.dart';
import '../services/supabase_service.dart';

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String time;
  final String date;
  final String category;
  final String badge;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final List<String> tags;
  final String actionLabel;
  final VoidCallback? onAction;
  bool isRead;
  bool isPinned;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.date,
    required this.category,
    this.badge = '',
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.tags,
    required this.actionLabel,
    this.onAction,
    this.isRead = false,
    this.isPinned = false,
  });
}

class NotificationsScreen extends StatefulWidget {
  final Function(int)? onNavigate;
  const NotificationsScreen({super.key, this.onNavigate});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _searchQuery = '';
  String _activeCategoryList = 'All Categories';
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  // Supabase fetched list of notifications
  late List<NotificationItem> _allNotifications;
  bool _isLoading = true;

  final Map<String, GlobalKey> _feedCardKeys = {};
  String? _highlightedNotificationId;

  @override
  void initState() {
    super.initState();
    _allNotifications = [];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadFromAppStateOrFetch();
  }

  void _loadFromAppStateOrFetch() {
    final appState = AppStateProvider.of(context);
    if (appState.notifications.isNotEmpty) {
      _allNotifications = appState.notifications.map((n) {
        final catRaw = n.category.trim().toUpperCase();
        String cat = 'Events';
        IconData icon = Icons.notifications_none;
        Color iconColor = const Color(0xFF2563EB);
        Color iconBgColor = const Color(0xFFEFF6FF);

        if (catRaw.contains('EXAM')) {
          cat = 'Exams';
          icon = Icons.assignment_outlined;
          iconColor = const Color(0xFFDC2626);
          iconBgColor = const Color(0xFFFEE2E2);
        } else if (catRaw.contains('FINANCE') || catRaw.contains('FEE')) {
          cat = 'Fees';
          icon = Icons.account_balance_wallet_outlined;
          iconColor = const Color(0xFFD97706);
          iconBgColor = const Color(0xFFFEF3C7);
        } else if (catRaw.contains('PLACE')) {
          cat = 'Placement';
          icon = Icons.business_center_outlined;
          iconColor = const Color(0xFF059669);
          iconBgColor = const Color(0xFFD1FAE5);
        } else if (catRaw.contains('ACADEMIC')) {
          cat = 'Academic';
          icon = Icons.school_outlined;
          iconColor = const Color(0xFF7C3AED);
          iconBgColor = const Color(0xFFEDE9FE);
        }

        return NotificationItem(
          id: n.id,
          title: n.title,
          message: n.desc,
          time: n.time.isNotEmpty ? n.time : 'Just now',
          date: n.date.isNotEmpty ? n.date : 'Today',
          category: cat,
          badge: n.isNew ? 'NEW' : '',
          icon: icon,
          iconColor: iconColor,
          iconBgColor: iconBgColor,
          tags: [cat.toUpperCase()],
          actionLabel: 'View Details',
          isRead: n.isRead,
        );
      }).toList();
      _isLoading = false;
    } else {
      _fetchSupabaseNotifications();
    }
  }

  Future<void> _fetchSupabaseNotifications() async {
    try {
      final appState = AppStateProvider.of(context);
      final studentIdCode = appState.getProfileField('student_id').isNotEmpty
          ? appState.getProfileField('student_id')
          : (appState.studentId.isNotEmpty ? appState.studentId : appState.getProfileField('register_no'));

      final raw = await SupabaseService.instance.getNotifications(studentIdCode.isNotEmpty ? studentIdCode : '119519');

      if (mounted) {
        setState(() {
          _allNotifications = raw.map((n) {
            final catRaw = (n['category'] ?? 'General').toString().trim().toUpperCase();
            String cat = 'Events';
            IconData icon = Icons.notifications_none;
            Color iconColor = const Color(0xFF2563EB);
            Color iconBgColor = const Color(0xFFEFF6FF);

            if (catRaw.contains('EXAM')) {
              cat = 'Exams';
              icon = Icons.assignment_outlined;
              iconColor = const Color(0xFFDC2626);
              iconBgColor = const Color(0xFFFEE2E2);
            } else if (catRaw.contains('FINANCE') || catRaw.contains('FEE')) {
              cat = 'Fees';
              icon = Icons.account_balance_wallet_outlined;
              iconColor = const Color(0xFFD97706);
              iconBgColor = const Color(0xFFFEF3C7);
            } else if (catRaw.contains('PLACE')) {
              cat = 'Placement';
              icon = Icons.business_center_outlined;
              iconColor = const Color(0xFF059669);
              iconBgColor = const Color(0xFFD1FAE5);
            } else if (catRaw.contains('ACADEMIC')) {
              cat = 'Academic';
              icon = Icons.school_outlined;
              iconColor = const Color(0xFF7C3AED);
              iconBgColor = const Color(0xFFEDE9FE);
            }

            final dateStr = (n['created_at'] ?? '').toString();
            String dateFormatted = 'Today';
            if (dateStr.length >= 10) {
              dateFormatted = dateStr.substring(0, 10);
            }

            return NotificationItem(
              id: n['id'].toString(),
              title: n['title'] ?? 'Notification',
              message: n['description'] ?? n['message'] ?? n['content'] ?? '',
              time: 'Just now',
              date: dateFormatted,
              category: cat,
              badge: n['priority'] ?? 'NEW',
              icon: icon,
              iconColor: iconColor,
              iconBgColor: iconBgColor,
              tags: [cat.toUpperCase()],
              actionLabel: 'View Details',
              isRead: n['is_read'] == true,
            );
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading notifications in screen: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, int> get _categoryCounts {
    final Map<String, int> counts = {
      'All Categories': _allNotifications.length,
      'Academic': _allNotifications.where((n) => n.category == 'Academic').length,
      'Placement': _allNotifications.where((n) => n.category == 'Placement').length,
      'Exams': _allNotifications.where((n) => n.category == 'Exams').length,
      'Fees': _allNotifications.where((n) => n.category == 'Fees').length,
      'Events': _allNotifications.where((n) => n.category == 'Events' || n.category == 'General').length,
      'Others': _allNotifications.where((n) => n.category == 'Others').length,
    };
    return counts;
  }

  // Filter list of notifications based on active category and search query
  List<NotificationItem> get _filteredNotifications {
    return _allNotifications.where((item) {
      // 1. Search Query filter
      final matchesSearch = item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.message.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.category.toLowerCase().contains(_searchQuery.toLowerCase());

      // 2. Active Category filter
      bool matchesCategory = true;
      if (_activeCategoryList != 'All Categories') {
        if (_activeCategoryList == 'Events') {
          matchesCategory = item.category == 'Events' || item.category == 'General';
        } else {
          matchesCategory = item.category == _activeCategoryList;
        }
      }

      return matchesSearch && matchesCategory;
    }).toList();
  }

  void _openNotificationFromImportant(NotificationItem item) {
    setState(() {
      _searchQuery = '';
      _activeCategoryList = 'All Categories';
      _highlightedNotificationId = item.id;
      _currentPage = 1;
    });

    final idx = _allNotifications.indexWhere((n) => n.id == item.id);
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
      if (mounted && _highlightedNotificationId == item.id) {
        setState(() => _highlightedNotificationId = null);
      }
    });
  }

  void _triggerDownloadFile(String filename) {
    final csv = 'Mock PDF File Content: $filename';
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
    final isDesktop = screenWidth >= 1024;

    final important = _allNotifications.where((n) => n.category == 'Exams' || n.category == 'Placement' || n.badge == 'URGENT' || n.tags.contains('Important')).toList();
    final pinned = _allNotifications.where((n) => n.isPinned).toList();

    if (isDesktop) {
      // Desktop: original two-column layout with sidebar
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderRow(),
            const SizedBox(height: 20),
            _buildStatCardsRow(),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 8,
                  child: _buildNotificationsFeedList(),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 4,
                  child: _buildRightSidebarLayout(),
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
          _buildStatCardsRow(),
          const SizedBox(height: 16),
          _buildTopImportantSection(important),
          const SizedBox(height: 12),
          _buildTopPinnedSection(pinned),
          const SizedBox(height: 24),
          _buildNotificationsFeedList(),
        ],
      ),
    );
  }

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
      'Academic',
      'Placement',
      'Exams',
      'Fees',
      'Events',
      'Others',
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
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF2563EB), size: 20),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _activeCategoryList = newValue;
              });
            }
          },
          items: categories.map<DropdownMenuItem<String>>((String cat) {
            final count = _categoryCounts[cat] ?? 0;
            return DropdownMenuItem<String>(
              value: cat,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.category_outlined, size: 16, color: Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  Text(cat, style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w500)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: cat == _activeCategoryList ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: cat == _activeCategoryList ? Colors.white : const Color(0xFF64748B),
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

  // --- 2. STAT CARDS ROW (6 horizontal cards showing dynamic counts) ---
  Widget _buildStatCardsRow() {
    return LayoutBuilder(builder: (context, constraints) {
      final total = _allNotifications.length;
      final unread = _allNotifications.where((n) => !n.isRead).length;
      final academic = _allNotifications.where((n) => n.category == 'Academic').length;
      final placement = _allNotifications.where((n) => n.category == 'Placement').length;
      final exam = _allNotifications.where((n) => n.category == 'Exams').length;
      final events = _allNotifications.where((n) => n.category == 'Events' || n.category == 'Others').length;

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
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B), height: 1.2)),
              ],
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildCategoriesSidebar() {
    final list = ['All Categories', 'Academic', 'Placement', 'Exams', 'Fees', 'Events', 'Others'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Categories', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 12),
          ...list.map((cat) {
            final count = _categoryCounts[cat] ?? 0;
            final isSelected = _activeCategoryList == cat;
            return InkWell(
              onTap: () => setState(() => _activeCategoryList = cat),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.folder_open, size: 14, color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // --- 4. LEFT FEED LIST ---
  Widget _buildNotificationsFeedList() {
    final filtered = _filteredNotifications;
    final totalCount = filtered.length;
    final totalPages = (totalCount / _itemsPerPage).ceil();

    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage > totalCount) ? totalCount : startIndex + _itemsPerPage;
    final displayedList = filtered.isEmpty ? <NotificationItem>[] : filtered.sublist(startIndex, endIndex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (displayedList.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: const Center(child: Text('No matching notifications found.', style: TextStyle(color: Color(0xFF64748B)))),
          )
        else
          ...displayedList.map((item) => _buildNotificationCard(item)),
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

  Widget _buildNotificationCard(NotificationItem item) {
    final isHighlighted = _highlightedNotificationId == item.id;
    _feedCardKeys[item.id] ??= GlobalKey();

    Color badgeBg = const Color(0xFFEFF6FF);
    Color badgeText = const Color(0xFF2563EB);
    if (item.category == 'Academic') {
      badgeBg = const Color(0xFFEFF6FF);
      badgeText = const Color(0xFF2563EB);
    } else if (item.category == 'Placement') {
      badgeBg = const Color(0xFFF0FDF4);
      badgeText = const Color(0xFF16A34A);
    } else if (item.category == 'Exams') {
      badgeBg = const Color(0xFFF3E8FF);
      badgeText = const Color(0xFF9333EA);
    } else if (item.category == 'Fees') {
      badgeBg = const Color(0xFFFFF7ED);
      badgeText = const Color(0xFFEA580C);
    } else if (item.category == 'Others') {
      badgeBg = const Color(0xFFFDF2F8);
      badgeText = const Color(0xFFEC4899);
    }

    return Container(
      key: _feedCardKeys[item.id],
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
                      item.category,
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: badgeText),
                    ),
                  ),
                  if (item.badge.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: item.badge == 'High Priority' ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.badge,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: item.badge == 'High Priority' ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Text('${item.date} • ${item.time}', style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
            ],
          ),
          const SizedBox(height: 10),
          Text(item.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 4),
          Text(
            item.message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                item.isRead ? Icons.done_all : Icons.done,
                size: 14,
                color: item.isRead ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 12),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  setState(() {
                    item.isPinned = !item.isPinned;
                  });
                },
                icon: Icon(
                  item.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  size: 14,
                  color: item.isPinned ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _shareContent(item.title, item.message),
                icon: const Icon(Icons.share_outlined, size: 14, color: Color(0xFF64748B)),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    item.isRead = true;
                  });
                  _showNotificationDetailModal(item);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  side: const BorderSide(color: Color(0xFF2563EB)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: Text(item.actionLabel, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showNotificationDetailModal(NotificationItem item) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Category: ${item.category}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: item.iconColor)),
              const SizedBox(height: 8),
              Text(item.message, style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF1E293B))),
              const SizedBox(height: 12),
              Text('Date: ${item.date} • ${item.time}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // --- RIGHT SIDEBAR LAYOUT (desktop only) ---
  Widget _buildRightSidebarLayout() {
    final important = _allNotifications.where((n) => n.category == 'Exams' || n.category == 'Placement' || n.badge == 'URGENT' || n.tags.contains('Important')).toList();
    final pinned = _allNotifications.where((n) => n.isPinned).toList();

    return Column(
      children: [
        _buildImportantNotificationsCard(important),
        const SizedBox(height: 20),
        _buildPinnedNotificationsCard(pinned),
      ],
    );
  }

  // --- TOP IMPORTANT SECTION (mini horizontal cards) ---
  Widget _buildTopImportantSection(List<NotificationItem> important) {
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
                children: important.take(6).map((item) {
                  return InkWell(
                    onTap: () => _openNotificationFromImportant(item),
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
                            child: Icon(item.icon, size: 12, color: const Color(0xFFEA580C)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)), maxLines: 2, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Text('${item.category} • ${item.date}', style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
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

  // --- TOP PINNED SECTION (mini horizontal cards) ---
  Widget _buildTopPinnedSection(List<NotificationItem> pinned) {
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
                  Text('Pinned Notifications', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
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
              child: Text('No pinned notifications. Pin any notification to see it here.', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: pinned.take(6).map((item) {
                  return InkWell(
                    onTap: () => _openNotificationFromImportant(item),
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
                                Text(item.title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)), maxLines: 2, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Text('${item.category} • ${item.date}', style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
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

  Widget _buildImportantNotificationsCard(List<NotificationItem> important) {
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFDBA74))),
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
                onTap: () => _openNotificationFromImportant(item),
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
                        child: Icon(item.icon, size: 14, color: const Color(0xFFEA580C)),
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

  Widget _buildPinnedNotificationsCard(List<NotificationItem> pinned) {
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
            ...pinned.map((item) {
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
                      decoration: BoxDecoration(color: item.iconBgColor, borderRadius: BorderRadius.circular(8)),
                      child: Icon(item.icon, size: 14, color: item.iconColor),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(item.category, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => item.isPinned = false),
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

  Widget _buildQuickActionsCard() {
    final actions = [
      {'title': 'Download\nHall Ticket', 'icon': Icons.download, 'color': const Color(0xFFEFF6FF), 'iconCol': const Color(0xFF2563EB), 'targetIndex': 8},
      {'title': 'View\nAttendance', 'icon': Icons.analytics_outlined, 'color': const Color(0xFFF0FDF4), 'iconCol': const Color(0xFF10B981), 'targetIndex': 4},
      {'title': 'Academic\nCalendar', 'icon': Icons.calendar_month, 'color': const Color(0xFFF5F3FF), 'iconCol': const Color(0xFF8B5CF6), 'targetIndex': 1},
      {'title': 'Fee\nPayment', 'icon': Icons.currency_rupee, 'color': const Color(0xFFFFF7ED), 'iconCol': const Color(0xFFEA580C), 'targetIndex': 9},
      {'title': 'Exam\nTimetable', 'icon': Icons.schedule, 'color': const Color(0xFFFDF2F8), 'iconCol': const Color(0xFFEC4899), 'targetIndex': 6},
      {'title': 'Results', 'icon': Icons.emoji_events_outlined, 'color': const Color(0xFFF0FDFA), 'iconCol': const Color(0xFF0D9488), 'targetIndex': 5},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Actions', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
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
              final a = actions[idx];
              return InkWell(
                onTap: () {
                  if (widget.onNavigate != null) {
                    widget.onNavigate!(a['targetIndex'] as int);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  decoration: BoxDecoration(color: a['color'] as Color, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(a['icon'] as IconData, size: 18, color: a['iconCol'] as Color),
                      const SizedBox(height: 4),
                      Text(
                        a['title'] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 7.5,
                          height: 1.1,
                          fontWeight: FontWeight.bold,
                          color: (a['iconCol'] as Color).withOpacity(0.9),
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

  Widget _buildRecentDownloadsCard() {
    final files = [
      {'name': 'Hall Ticket_AprMay2024.pdf', 'date': 'May 16, 2024'},
      {'name': 'Semester_Timetable.pdf', 'date': 'May 14, 2024'},
      {'name': 'Fee_Receipt_May2024.pdf', 'date': 'May 10, 2024'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Recent Downloads', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              Text('View All', style: TextStyle(fontSize: 10, color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          ...files.map((f) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.picture_as_pdf, color: Color(0xFFEF4444), size: 22),
              title: Text(f['name']!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              subtitle: Text(f['date']!, style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
              trailing: IconButton(
                onPressed: () => _triggerDownloadFile(f['name']!),
                icon: const Icon(Icons.download, size: 16, color: Color(0xFF2563EB)),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildImportantDatesCard() {
    final dates = [
      {'title': 'End Semester Exams', 'range': 'May 20 - Jun 05, 2024', 'bg': const Color(0xFFEFF6FF), 'col': const Color(0xFF2563EB)},
      {'title': 'Last Date for Fee Payment', 'range': 'May 25, 2024', 'bg': const Color(0xFFFFF7ED), 'col': const Color(0xFFEA580C)},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Important Dates', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              Text('View All', style: TextStyle(fontSize: 10, color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          ...dates.map((d) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: d['bg'] as Color, borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    Icon(Icons.event_note, size: 16, color: d['col'] as Color),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d['title'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                          Text(d['range'] as String, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
