import 'package:flutter/material.dart';
import '../models/app_state.dart';
import '../../../app/home_page.dart';

class TopBar extends StatelessWidget {
  final bool isDesktop;
  final Function(int)? onNavigate;
  final String role;
  final String title;

  const TopBar({
    super.key, 
    required this.isDesktop, 
    this.onNavigate, 
    this.role = 'student',
    this.title = 'Student Portal',
  });

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    final unreadCount = appState.unreadCount;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24.0 : 12.0, vertical: 12.0),
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
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          if (!isDesktop) const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isDesktop ? 22 : 17,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Notification Bell
          InkWell(
            onTap: () => _showNotificationsMenu(context),
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                const Padding(
                  padding: EdgeInsets.all(6.0),
                  child: Icon(Icons.notifications_none, color: Color(0xFF475569), size: 24),
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
              ],
            ),
          ),
          SizedBox(width: isDesktop ? 20 : 8),
          // Profile User Info Dropdown
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'profile') {
                if (onNavigate != null) {
                  onNavigate!(2); // My Profile index
                }
              } else if (value == 'logout') {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const ErpHomePage()),
                  (route) => false,
                );
              }
            },
            offset: const Offset(0, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: const [
                    Icon(Icons.logout, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(fontSize: 13, color: Colors.red)),
                  ],
                ),
              ),
            ],
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Row(
                children: [
                  Builder(builder: (ctx) {
                    final photoUrl = appState.getProfileField('photo_url');
                    final name = appState.studentName;
                    final isValid = photoUrl.isNotEmpty &&
                        (photoUrl.startsWith('https://') || photoUrl.startsWith('http://')) &&
                        !photoUrl.contains('google.com/imgres') &&
                        !photoUrl.contains('google.com/search') &&
                        (photoUrl.contains('.jpg') || photoUrl.contains('.jpeg') ||
                            photoUrl.contains('.png') || photoUrl.contains('.webp') ||
                            photoUrl.contains('unsplash.com') || photoUrl.contains('supabase') ||
                            photoUrl.contains('cloudinary.com'));
                    final effectiveUrl = isValid
                        ? photoUrl
                        : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&auto=format&fit=crop&q=80';
                    return ClipOval(
                      child: Image.network(
                        effectiveUrl,
                        width: 42,
                        height: 42,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) {
                          final initials = name.trim().split(' ')
                              .where((p) => p.isNotEmpty).take(2)
                              .map((p) => p[0].toUpperCase()).join();
                          return Container(
                            width: 42,
                            height: 42,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1D4ED8),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(initials,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                          );
                        },
                      ),
                    );
                  }),
                  if (isDesktop) ...[
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
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
