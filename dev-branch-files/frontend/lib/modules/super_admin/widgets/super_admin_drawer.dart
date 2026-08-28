import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../admin/app/router/route_names.dart';
import '../../admin/app/theme/app_typography.dart';

class SuperAdminDrawer extends StatelessWidget {
  final String currentLocation;

  const SuperAdminDrawer({
    super.key,
    required this.currentLocation,
  });

  bool _isActive(String path) => currentLocation == path;

  void _navigate(BuildContext context, String path) {
    final scaffold = Scaffold.maybeOf(context);
    if (scaffold != null && scaffold.isDrawerOpen) {
      Navigator.of(context).pop();
    }
    context.go(path);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: Color(0xFF00102B),
        border: Border(
          right: BorderSide(color: Color(0xFF000511), width: 1),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB800),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.shield_rounded,
                      color: Color(0xFF00102B),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SUPER ADMIN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            fontFamily: AppTypography.fontFamily,
                          ),
                        ),
                        Text(
                          'KSRCE ERP SYSTEM CONTROL',
                          style: TextStyle(
                            color: Color(0xFFFFB800),
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            fontFamily: AppTypography.fontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(color: Color(0xFF0C244A), height: 1, thickness: 1),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                children: [
                  _buildSectionHeader('SYSTEM OVERVIEW'),
                  _buildNavItem(
                    context: context,
                    title: 'System Dashboard',
                    icon: Icons.dashboard_rounded,
                    routePath: RouteNames.superAdminDashboard,
                  ),
                  _buildNavItem(
                    context: context,
                    title: 'System Health Monitor',
                    icon: Icons.monitor_heart_outlined,
                    routePath: RouteNames.superAdminSystemHealth,
                  ),

                  _buildSectionHeader('DATABASE & STORAGE'),
                  _buildNavItem(
                    context: context,
                    title: 'Database Manager',
                    icon: Icons.dns_rounded,
                    routePath: RouteNames.superAdminDatabaseManager,
                  ),
                  _buildNavItem(
                    context: context,
                    title: 'Backup & System Restore',
                    icon: Icons.backup_outlined,
                    routePath: RouteNames.superAdminBackupRestore,
                  ),

                  _buildSectionHeader('USER & SECURITY ACCESS'),
                  _buildNavItem(
                    context: context,
                    title: 'User Management Console',
                    icon: Icons.people_outline_rounded,
                    routePath: RouteNames.superAdminUserConsole,
                  ),
                  _buildNavItem(
                    context: context,
                    title: 'Role & Permissions Matrix',
                    icon: Icons.security_outlined,
                    routePath: RouteNames.superAdminRolesPermissions,
                  ),
                  _buildNavItem(
                    context: context,
                    title: 'Security & Audit Center',
                    icon: Icons.shield_rounded,
                    routePath: RouteNames.superAdminSecurityAudit,
                  ),

                  _buildSectionHeader('COMMUNICATION & INTEGRATION'),
                  _buildNavItem(
                    context: context,
                    title: 'API & Gateway Manager',
                    icon: Icons.alt_route_rounded,
                    routePath: RouteNames.superAdminApiGateway,
                  ),
                  _buildNavItem(
                    context: context,
                    title: 'Communication Gateway',
                    icon: Icons.notifications_active_rounded,
                    routePath: RouteNames.superAdminCommunicationGateway,
                  ),
                  _buildNavItem(
                    context: context,
                    title: 'SMS & Email Gateway',
                    icon: Icons.email_outlined,
                    routePath: RouteNames.superAdminSmsEmailConfig,
                  ),
                  _buildNavItem(
                    context: context,
                    title: 'Notification Push Engine',
                    icon: Icons.notifications_none_rounded,
                    routePath: RouteNames.superAdminNotificationConfig,
                  ),

                  _buildSectionHeader('SYSTEM CONFIGURATION'),
                  _buildNavItem(
                    context: context,
                    title: 'Academic Year Config',
                    icon: Icons.date_range_outlined,
                    routePath: RouteNames.superAdminAcademicConfig,
                  ),
                  _buildNavItem(
                    context: context,
                    title: 'System Settings & Policies',
                    icon: Icons.settings_outlined,
                    routePath: RouteNames.superAdminSystemSettings,
                  ),
                  _buildNavItem(
                    context: context,
                    title: 'Scheduled Jobs & Automation',
                    icon: Icons.schedule_rounded,
                    routePath: RouteNames.superAdminScheduledJobs,
                  ),

                  _buildSectionHeader('MONITORING & AUDIT'),
                  _buildNavItem(
                    context: context,
                    title: 'Audit Logs & Login History',
                    icon: Icons.history_outlined,
                    routePath: RouteNames.superAdminAuditLogs,
                  ),
                ],
              ),
            ),

            const Divider(color: Color(0xFF0C244A), height: 1, thickness: 1),

            InkWell(
              onTap: () => context.go(RouteNames.dashboard),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0052CC),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ERP Admin Portal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text('Switch to Operations', style: TextStyle(fontSize: 9, color: Color(0xFF8DA4CE))),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF8DA4CE), size: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, top: 14, bottom: 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          color: Color(0xFF5E7AA8),
          letterSpacing: 0.9,
          fontFamily: AppTypography.fontFamily,
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String routePath,
  }) {
    final isSelected = _isActive(routePath);

    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: InkWell(
        onTap: () => _navigate(context, routePath),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFB800) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? const Color(0xFF00102B) : const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? const Color(0xFF00102B) : const Color(0xFFE2E8F0),
                    fontFamily: AppTypography.fontFamily,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
