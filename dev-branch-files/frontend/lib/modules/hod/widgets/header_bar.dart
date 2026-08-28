import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';
import '../../faculty/services/profile_service.dart';

import '../hod_toast.dart';

class HeaderBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onToggleSidebar;
  final bool isSidebarOpen;

  const HeaderBar({
    super.key,
    required this.onToggleSidebar,
    required this.isSidebarOpen,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 992;
    final isSmallMobile = screenWidth < 480;

    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A), // Dark Navy Background matching screenshot
        border: Border(
          bottom: BorderSide(color: Color(0xFF1E293B), width: 1),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: isSmallMobile ? 8 : 16),
      child: Row(
        children: [


          // ── 2. Responsive Search Bar ──
          Expanded(
            child: Container(
              height: 38,
              margin: EdgeInsets.only(right: isSmallMobile ? 4 : 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B), // Darker Navy Pill
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF334155), width: 1),
              ),
              child: TextField(
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: InputDecoration(
                  hintText: isSmallMobile ? 'Search...' : 'Search students, faculty, assignments...',
                  hintStyle: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF94A3B8),
                    size: 16,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ),

          // ── 3. Right Action Icons (Notification & Mail Inbox) ──
          // Notification Bell
          IconButton(
            constraints: const BoxConstraints(maxWidth: 36),
            padding: EdgeInsets.zero,
            onPressed: () {
              HodToast.show(
                context,
                message: 'No new notifications',
                isSuccess: true,
              );
            },
            icon: const Icon(
              Icons.notifications_none_outlined,
              color: Color(0xFFCBD5E1),
              size: 20,
            ),
            tooltip: 'Notifications',
          ),

          // Mail Inbox Badge Icon
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                constraints: const BoxConstraints(maxWidth: 36),
                padding: EdgeInsets.zero,
                onPressed: () {
                  HodToast.show(
                    context,
                    message: '1 unread message in inbox',
                  );
                },
                icon: const Icon(
                  Icons.mail_outline_rounded,
                  color: Color(0xFFCBD5E1),
                  size: 20,
                ),
                tooltip: 'Inbox',
              ),
              Positioned(
                right: 2,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2563EB),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 14,
                    minHeight: 14,
                  ),
                  child: const Center(
                    child: Text(
                      '1',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(width: isSmallMobile ? 4 : 8),

          // ── 4. User Profile Dropdown ──
          PopupMenuButton<String>(
            offset: const Offset(0, 48),
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) {
              if (value == 'logout') {
                HodToast.show(
                  context,
                  message: 'Logging out of HOD Portal...',
                  isError: true,
                );
                Future.delayed(const Duration(milliseconds: 600), () {
                  if (context.mounted) {
                    context.go('/');
                  }
                });
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      color: Color(0xFFEF4444),
                      size: 18,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Logout',
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            child: Row(
              children: [
                // Profile Circle Avatar
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2563EB),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 18,
                  ),
                ),

                if (!isMobile) ...[
                  const SizedBox(width: 8),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ProfileService.get()['name'] ?? 'Dr. K. Ravichandran',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'HOD - ${ProfileService.get()['departmentId'] ?? 'CSE'}',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF94A3B8),
                    size: 16,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
