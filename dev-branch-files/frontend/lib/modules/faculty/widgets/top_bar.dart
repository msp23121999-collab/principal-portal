// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import '../models/app_state.dart';

class TopBar extends StatelessWidget {
  final bool isDesktop;
  final Function(int)? onNavigate;
  final String role;

  const TopBar({super.key, required this.isDesktop, this.onNavigate, this.role = 'student'});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    final unreadCount = appState.unreadCount;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFF1F5F9),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (!isDesktop)
            IconButton(
              icon: const Icon(Icons.menu, color: Color(0xFF1E293B)),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Student Portal',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    'Welcome back, ',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                    ),
                  ),
                  Text(
                    '${appState.studentName.split(' ').first}!',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF1D4ED8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          // Notification Bell
          InkWell(
            onTap: () => _showNotificationsMenu(context),
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.notifications_none, color: Color(0xFF475569), size: 28),
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Profile User Info
          InkWell(
            onTap: () {
              if (onNavigate != null) {
                onNavigate!(2); // My Profile index
              }
            },
            borderRadius: BorderRadius.circular(24),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1D4ED8),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      appState.studentName.isNotEmpty ? appState.studentName[0] : 'S',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                if (isDesktop) ...[
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appState.studentName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        role.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[500],
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.keyboard_arrow_down, color: Color(0xFF475569), size: 20),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showNotificationsMenu(BuildContext context) {
    final appState = AppStateProvider.of(context);

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        return Stack(
          children: [
            Positioned(
              top: 70,
              right: 24,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 380,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Notifications',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '${appState.unreadCount} unread',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                InkWell(
                                  onTap: () {
                                    appState.markAllNotificationsAsRead();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('All notifications marked as read!')),
                                    );
                                  },
                                  child: Row(
                                    children: const [
                                      Icon(Icons.check, size: 16, color: Color(0xFF0284C7)),
                                      SizedBox(width: 4),
                                      Text(
                                        'Mark all read',
                                        style: TextStyle(
                                          color: Color(0xFF0284C7),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                InkWell(
                                  onTap: () => Navigator.pop(context),
                                  child: const Icon(Icons.close, size: 16, color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      // List items
                      ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height - 200),
                        child: SingleChildScrollView(
                          child: Column(
                            children: appState.notifications.map((notif) {
                              return InkWell(
                                onTap: () {
                                  appState.markNotificationAsRead(notif.id);
                                  Navigator.pop(context);
                                  if (onNavigate != null) {
                                    onNavigate!(19); // Notifications module
                                  }
                                },
                                child: _buildNotificationDropdownItem(
                                  icon: notif.icon,
                                  iconColor: notif.iconColor,
                                  title: notif.title,
                                  desc: notif.desc,
                                  time: notif.time,
                                  isNew: !notif.isRead,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      // View All
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          if (onNavigate != null) {
                            onNavigate!(19); // 19 is Notifications
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: const Center(
                            child: Text(
                              'View All Notifications >',
                              style: TextStyle(
                                color: Color(0xFF0284C7),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNotificationDropdownItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String desc,
    required String time,
    required bool isNew,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: isNew ? FontWeight.bold : FontWeight.w600,
                        fontSize: 14,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    if (isNew) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF3B82F6),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
