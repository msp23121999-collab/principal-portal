import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../widgets/faculty_loading.dart';
import '../erp_repository.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  final repo = ErpRepository();
  String _activeTab = 'All';
  String _priorityFilter = 'All Priorities';
  String _sortOrder = 'Latest First';
  String _searchQuery = '';
  bool _isFetching = false;
  final _searchCtrl = TextEditingController();

  Future<void> _refreshNotifications() async {
    if (!mounted) return;
    setState(() => _isFetching = true);
    try {
      await repo.reloadNotifications();
    } catch (_) {}
    if (mounted) {
      setState(() => _isFetching = false);
    }
  }

  DateTime _parseNotificationDate(Map<String, dynamic> n) {
    final raw =
        n['created_at'] ??
        n['createdAt'] ??
        n['timestamp'] ??
        n['time'] ??
        n['date'];
    if (raw == null) return DateTime.now();
    final str = raw.toString().trim();
    if (str.isEmpty ||
        str.toLowerCase() == 'just now' ||
        str.toLowerCase() == 'today') {
      return DateTime.now();
    }

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
        int? year = int.tryParse(parts[0]);
        int? month = months[parts[1].toLowerCase()] ?? int.tryParse(parts[1]);
        int? day = int.tryParse(parts[2]);

        if (year == null || year < 1000) {
          day = int.tryParse(parts[0]);
          month = months[parts[1].toLowerCase()] ?? int.tryParse(parts[1]);
          year = int.tryParse(parts[2]);
        }

        if (day != null && month != null && year != null) {
          return DateTime(year, month, day);
        }
      }
    } catch (_) {}

    return DateTime.now();
  }

  List<Map<String, dynamic>> get _filtered {
    final list = repo.notifications;
    final query = _searchQuery.toLowerCase();

    final result = list.where((n) {
      final isUnread = (n['read'] != true);
      final matchesTab =
          _activeTab == 'All' ||
          (_activeTab == 'Unread' && isUnread) ||
          (_activeTab == 'Announcements' && n['tag'] == 'Announcement') ||
          (_activeTab == 'Approvals' && n['tag'] == 'Approval') ||
          (_activeTab == 'System Alerts' &&
              (n['tag'] == 'System Alert' || n['tag'] == 'Alert'));

      final matchesPriority =
          _priorityFilter == 'All Priorities' ||
          (n['priority']?.toString().toUpperCase() ==
              _priorityFilter.toUpperCase());

      final matchesSearch =
          query.isEmpty ||
          (n['title'] as String? ?? '').toLowerCase().contains(query) ||
          (n['body'] as String? ?? '').toLowerCase().contains(query);

      return matchesTab && matchesPriority && matchesSearch;
    }).toList();

    result.sort((a, b) {
      final dateA = _parseNotificationDate(a);
      final dateB = _parseNotificationDate(b);
      if (_sortOrder == 'Oldest First') {
        return dateA.compareTo(dateB);
      } else {
        // Newest First (default)
        return dateB.compareTo(dateA);
      }
    });

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        if (repo.isLoadingData && repo.notifications.isEmpty) {
          return const FacultyLoadingWidget();
        }
        final list = _filtered;
        final unreadCount = repo.unreadNotificationsCount;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _pageHeader(),
            const SizedBox(height: 20),
            _filterBar(unreadCount),
            const SizedBox(height: 20),
            _notificationsList(list),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }

  Widget _pageHeader() {
    return Row(
      children: [
        Text(
          'Notifications',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        const Spacer(),
        _badge('Academic Year ${repo.selectedAcademicYear}'),
      ],
    );
  }

  Widget _heroBanner(int unreadCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: _cardDecor(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: Color(0xFF2563EB),
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  'Stay updated with system alerts, announcements, and approvals.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterBar(int unreadCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecor(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 768;

          // ── TAB BUTTONS (Unified filter group) ──────────────────────
          final tabsList = [
            'All',
            'Unread',
            'Announcements',
            'Approvals',
            'Alerts',
          ];
          final tabsGroup = Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: tabsList.map((tab) {
              final internalTab = tab == 'Alerts' ? 'System Alerts' : tab;
              final sel =
                  _activeTab == internalTab ||
                  (_activeTab == 'Alerts' && internalTab == 'System Alerts');
              final isUnreadCount = tab == 'Unread';
              return InkWell(
                onTap: () => setState(() => _activeTab = internalTab),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: sel
                        ? const Color(0xFFEFF6FF)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: sel
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFE2E8F0),
                      width: sel ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tab,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: sel ? FontWeight.bold : FontWeight.w500,
                          color: sel
                              ? const Color(0xFF1E3A8A)
                              : const Color(0xFF475569),
                        ),
                      ),
                      if (isUnreadCount && unreadCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$unreadCount',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          );

          // ── ACTION BUTTONS ──────────────────────────────────────────
          final markAllBtn = ElevatedButton.icon(
            onPressed: () async {
              await repo.markAllNotificationsRead();
              if (mounted) {
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All notifications marked as read.'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            icon: const Icon(Icons.done_all, size: 15),
            label: Text(
              'Mark All Read',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              minimumSize: const Size(0, 38),
              fixedSize: const Size.fromHeight(38),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );

          final refreshBtn = Tooltip(
            message: 'Refresh Notifications',
            child: InkWell(
              onTap: _isFetching ? null : () => _refreshNotifications(),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 38,
                width: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: _isFetching
                    ? LoadingAnimationWidget.hexagonDots(
                        color: const Color(0xFF2563EB),
                        size: 18,
                      )
                    : const Icon(
                        Icons.refresh_outlined,
                        size: 18,
                        color: Color(0xFF2563EB),
                      ),
              ),
            ),
          );

          final searchWidget = Container(
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: GoogleFonts.inter(fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Search notifications...',
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
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          );

          final priorityDropdown = SizedBox(
            width: 175,
            child: _dropdown(
              ['All Priorities', 'High', 'Medium', 'Low'],
              _priorityFilter,
              (v) => setState(() => _priorityFilter = v!),
            ),
          );

          final sortDropdown = SizedBox(
            width: 175,
            child: _dropdown(
              ['Latest First', 'Oldest First'],
              _sortOrder,
              (v) => setState(() => _sortOrder = v!),
            ),
          );

          if (isWide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Tabs
                tabsGroup,
                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 14),
                // Bottom Row: Integrated Compact Toolbar
                Row(
                  children: [
                    Expanded(child: searchWidget),
                    const SizedBox(width: 10),
                    priorityDropdown,
                    const SizedBox(width: 10),
                    sortDropdown,
                    const SizedBox(width: 10),
                    markAllBtn,
                    const SizedBox(width: 8),
                    refreshBtn,
                  ],
                ),
              ],
            );
          }

          // Mobile / Small Screen Layout
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              tabsGroup,
              const SizedBox(height: 12),
              searchWidget,
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: (constraints.maxWidth - 12) / 2 > 130
                        ? (constraints.maxWidth - 12) / 2
                        : 130,
                    child: _dropdown(
                      ['All Priorities', 'High', 'Medium', 'Low'],
                      _priorityFilter,
                      (v) => setState(() => _priorityFilter = v!),
                    ),
                  ),
                  SizedBox(
                    width: (constraints.maxWidth - 12) / 2 > 130
                        ? (constraints.maxWidth - 12) / 2
                        : 130,
                    child: _dropdown(
                      ['Latest First', 'Oldest First'],
                      _sortOrder,
                      (v) => setState(() => _sortOrder = v!),
                    ),
                  ),
                  markAllBtn,
                  refreshBtn,
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _notificationsList(List<Map<String, dynamic>> list) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecor(),
      child: Column(
        children: [
          if (_isFetching && list.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: FacultyLoadingWidget(),
            )
          else if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Text(
                  'No notifications found matching your selection.',
                  style: GoogleFonts.inter(color: Colors.grey),
                ),
              ),
            )
          else
            ...list.map((n) => _notificationItem(n)),
        ],
      ),
    );
  }

  Widget _notificationItem(Map<String, dynamic> n) {
    final unread = n['read'] != true;
    final tag = n['tag'] as String? ?? 'Announcement';
    final id = (n['notificationId'] ?? n['id'])?.toString() ?? '';

    Color tagBg = const Color(0xFFDBEAFE);
    Color tagFg = const Color(0xFF2563EB);
    IconData icon = Icons.notifications;

    final titleStr = (n['title'] as String? ?? '').toLowerCase();
    final bodyStr = (n['body'] as String? ?? '').toLowerCase();
    final isAttendance =
        titleStr.contains('attendance') ||
        bodyStr.contains('attendance') ||
        tag.toLowerCase().contains('attendance');

    if (tag == 'Approval') {
      tagBg = const Color(0xFFD1FAE5);
      tagFg = const Color(0xFF10B981);
      icon = Icons.check_circle_outline;
    } else if (isAttendance) {
      tagBg = const Color(0xFFEFF6FF);
      tagFg = const Color(0xFF2563EB);
      icon = Icons.how_to_reg_outlined;
    } else if (tag == 'Alert' || tag == 'System Alert') {
      tagBg = const Color(0xFFFEE2E2);
      tagFg = const Color(0xFFEF4444);
      icon = Icons.error_outline;
    } else {
      icon = Icons.campaign_outlined;
    }

    return InkWell(
      onTap: () async {
        if (unread && id.isNotEmpty) {
          await repo.markNotificationAsRead(id, read: true);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 14, right: 12),
              decoration: BoxDecoration(
                color: unread ? const Color(0xFF2563EB) : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: tagBg.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: tagFg, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n['title'] as String? ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    n['body'] as String? ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: tagBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          tag,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: tagFg,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _smallBadge(
                        '${n['priority'] ?? 'MEDIUM'}',
                        Colors.grey[100]!,
                        Colors.grey[700]!,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  n['time'] as String? ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (unread)
                      Tooltip(
                        message: 'Mark as read',
                        child: InkWell(
                          onTap: () async {
                            await repo.markNotificationAsRead(id, read: true);
                            if (mounted) setState(() {});
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFBBF7D0),
                              ),
                            ),
                            child: const Icon(
                              Icons.check_circle_outline,
                              size: 16,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ),
                      )
                    else
                      const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Color(0xFF16A34A),
                      ),
                    const SizedBox(width: 4),
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert,
                        size: 18,
                        color: Color(0xFF94A3B8),
                      ),
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'toggle',
                          child: Text(
                            unread ? 'Mark as Read' : 'Mark as Unread',
                            style: GoogleFonts.inter(),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            'Delete Notification',
                            style: GoogleFonts.inter(color: Colors.red),
                          ),
                        ),
                      ],
                      onSelected: (v) async {
                        if (v == 'toggle') {
                          await repo.markNotificationAsRead(id, read: unread);
                        } else if (v == 'delete') {
                          await repo.deleteNotification(id);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Notification removed.'),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdown(
    List<String> items,
    String val,
    ValueChanged<String?> onChange,
  ) {
    final uniqueItems = items.toSet().toList();
    final validVal = uniqueItems.contains(val)
        ? val
        : (uniqueItems.isNotEmpty ? uniqueItems.first : val);

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
      onSelected: onChange,
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
              Icons.keyboard_arrow_down,
              size: 16,
              color: Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDecor() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
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

  Widget _bc(String t, {bool active = false}) => Text(
    t,
    style: GoogleFonts.inter(
      fontSize: 12,
      color: active ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
      fontWeight: active ? FontWeight.w600 : FontWeight.normal,
    ),
  );

  Widget _smallBadge(String text, Color bg, Color fg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: fg,
      ),
    ),
  );
}
